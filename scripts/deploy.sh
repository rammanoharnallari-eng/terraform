#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGION="us-east-1"
BUILD_AMI=false
DEPLOY_MONITORING=true
SKIP_BOOTSTRAP=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --region REGION        AWS region (default: us-east-1)"
    echo "  -a, --build-ami           Build custom AMI with Packer"
    echo "  -m, --no-monitoring       Skip monitoring stack deployment"
    echo "  -s, --skip-bootstrap      Skip bootstrap step"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Deploy with defaults"
    echo "  $0 -r us-west-2          # Deploy to us-west-2"
    echo "  $0 -a                    # Build custom AMI and deploy"
    echo "  $0 -m                    # Deploy without monitoring"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -a|--build-ami)
            BUILD_AMI=true
            shift
            ;;
        -m|--no-monitoring)
            DEPLOY_MONITORING=false
            shift
            ;;
        -s|--skip-bootstrap)
            SKIP_BOOTSTRAP=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_status "Starting deployment to region: $REGION"

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    if [[ "$BUILD_AMI" == true ]]; then
        if ! command -v packer &> /dev/null; then
            missing_tools+=("packer")
        fi
        
        if ! command -v ansible &> /dev/null; then
            missing_tools+=("ansible")
        fi
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install the missing tools and try again."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Bootstrap remote state
bootstrap_state() {
    if [[ "$SKIP_BOOTSTRAP" == true ]]; then
        print_warning "Skipping bootstrap step"
        return
    fi
    
    print_status "Bootstrapping remote state..."
    
    cd bootstrap
    terraform init
    terraform apply -auto-approve -var "region=$REGION"
    
    # Capture outputs
    STATE_BUCKET=$(terraform output -raw state_bucket)
    LOCK_TABLE=$(terraform output -raw lock_table)
    
    print_success "Bootstrap completed"
    print_status "State bucket: $STATE_BUCKET"
    print_status "Lock table: $LOCK_TABLE"
    
    cd ..
}

# Build custom AMI
build_ami() {
    if [[ "$BUILD_AMI" != true ]]; then
        print_warning "Skipping custom AMI build"
        return
    fi
    
    print_status "Building custom AMI with Packer..."
    
    cd packer
    packer init worker-node.pkr.hcl
    packer build -var "aws_region=$REGION" worker-node.pkr.hcl
    
    # Extract AMI ID from output
    AMI_ID=$(packer build -var "aws_region=$REGION" worker-node.pkr.hcl 2>&1 | grep -o 'ami-[a-z0-9]*' | tail -1)
    
    if [[ -z "$AMI_ID" ]]; then
        print_error "Failed to extract AMI ID from Packer output"
        exit 1
    fi
    
    print_success "Custom AMI built: $AMI_ID"
    cd ..
}

# Build and push Docker image
build_docker_image() {
    print_status "Building and pushing Docker image..."
    
    # Get AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Create ECR repository if it doesn't exist
    aws ecr create-repository --repository-name devops-practical --region $REGION 2>/dev/null || true
    
    # Login to ECR
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    
    # Clone application source
    if [[ ! -d "src" ]]; then
        print_status "Cloning application source..."
        git clone https://github.com/swimlane/devops-practical.git ./src
    fi
    
    # Build and push image
    IMAGE_TAG="manual-$(date +%Y%m%d-%H%M%S)"
    IMAGE_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/devops-practical"
    
    docker build -f docker/devops-practical.Dockerfile -t $IMAGE_REPO:$IMAGE_TAG ./src
    docker push $IMAGE_REPO:$IMAGE_TAG
    
    # Also tag as latest
    docker tag $IMAGE_REPO:$IMAGE_TAG $IMAGE_REPO:latest
    docker push $IMAGE_REPO:latest
    
    print_success "Docker image built and pushed: $IMAGE_REPO:$IMAGE_TAG"
    
    # Export for Terraform
    export IMAGE_REPOSITORY=$IMAGE_REPO
    export IMAGE_TAG=$IMAGE_TAG
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init \
        -backend-config="bucket=$STATE_BUCKET" \
        -backend-config="key=envs/dev/terraform.tfstate" \
        -backend-config="region=$REGION" \
        -backend-config="dynamodb_table=$LOCK_TABLE" \
        -backend-config="encrypt=true"
    
    # Create terraform.tfvars if it doesn't exist
    if [[ ! -f "terraform.tfvars" ]]; then
        print_status "Creating terraform.tfvars..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Update with actual values
        sed -i "s/region = \".*\"/region = \"$REGION\"/" terraform.tfvars
        sed -i "s|image_repository = \".*\"|image_repository = \"$IMAGE_REPOSITORY\"|" terraform.tfvars
        sed -i "s/image_tag = \".*\"/image_tag = \"$IMAGE_TAG\"/" terraform.tfvars
        
        if [[ "$BUILD_AMI" == true ]]; then
            echo "custom_ami_id = \"$AMI_ID\"" >> terraform.tfvars
        fi
        
        if [[ "$DEPLOY_MONITORING" == false ]]; then
            echo "enable_monitoring_ingress = false" >> terraform.tfvars
        fi
        
        print_warning "Please edit terraform.tfvars to set your passwords and other sensitive values"
        print_warning "Press Enter to continue after editing..."
        read
    fi
    
    # Plan and apply
    terraform plan
    terraform apply -auto-approve
    
    print_success "Infrastructure deployed successfully"
    cd ..
}

# Get application URL
get_app_url() {
    print_status "Getting application URL..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --region $REGION --name swimlane-eks
    
    # Get LoadBalancer URL
    APP_URL=$(kubectl get svc -n apps swimlane-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [[ -n "$APP_URL" ]]; then
        print_success "Application URL: http://$APP_URL"
    else
        print_warning "Application URL not available yet. Check with: kubectl get svc -n apps"
    fi
    
    # Get Grafana URL if monitoring is enabled
    if [[ "$DEPLOY_MONITORING" == true ]]; then
        GRAFANA_URL=$(kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        
        if [[ -n "$GRAFANA_URL" ]]; then
            print_success "Grafana URL: http://$GRAFANA_URL"
            print_status "Grafana username: admin"
            print_status "Grafana password: (check terraform.tfvars)"
        fi
    fi
}

# Main execution
main() {
    print_status "Starting DevOps Practical deployment..."
    
    check_prerequisites
    bootstrap_state
    build_ami
    build_docker_image
    deploy_infrastructure
    get_app_url
    
    print_success "Deployment completed successfully!"
    print_status "You can now access the application and test it by:"
    print_status "1. Opening the application URL in your browser"
    print_status "2. Registering a new account"
    print_status "3. Adding a record to verify database connectivity"
    
    if [[ "$DEPLOY_MONITORING" == true ]]; then
        print_status "4. Checking monitoring in Grafana"
    fi
}

# Run main function
main "$@"
