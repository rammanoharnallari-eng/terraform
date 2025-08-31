# DevOps Practical - Complete Kubernetes Deployment on EKS

This project implements a complete DevOps solution for deploying the [Swimlane DevOps Practical](https://github.com/swimlane/devops-practical) application to Amazon EKS with enterprise-grade security, scalability, and monitoring.

## 🏗️ Architecture Overview

The solution includes:
- **Containerized Application**: Dockerized Node.js application
- **MongoDB**: Deployed as a highly available replica set
- **Kubernetes Cluster**: Amazon EKS with custom worker nodes
- **Security**: Pod Security Standards, RBAC, Network Policies
- **Monitoring**: Prometheus, Grafana, and ServiceMonitor
- **CI/CD**: GitHub Actions with automated testing and deployment
- **Infrastructure as Code**: Terraform with remote state management
- **Custom AMIs**: Packer-built worker node images with Ansible configuration

## 📋 Requirements Fulfilled

### ✅ Core Requirements
- [x] **Dockerized Application**: Complete Dockerfile for the Node.js app
- [x] **MongoDB Container**: Deployed as Kubernetes StatefulSet with replica set
- [x] **Kubernetes Cluster**: Amazon EKS with multi-AZ deployment
- [x] **Helm Chart**: Complete Helm v3 chart with templates
- [x] **Terraform Infrastructure**: Full infrastructure automation
- [x] **High Availability**: Multi-AZ deployment, PDB, HPA

### ✅ Security Features
- [x] **Pod Security Standards**: Restricted security context
- [x] **RBAC**: Service accounts with minimal permissions
- [x] **Network Policies**: Restrictive ingress/egress rules
- [x] **Non-root containers**: Security-hardened containers
- [x] **Encrypted storage**: EBS volumes with encryption

### ✅ Scalability Features
- [x] **Horizontal Pod Autoscaler**: CPU-based scaling (2-6 replicas)
- [x] **Multi-AZ deployment**: Spread across availability zones
- [x] **Node group scaling**: Auto-scaling worker nodes (3-10 instances)
- [x] **Resource limits**: Proper CPU/memory requests and limits

### ✅ Bonus Features
- [x] **Ansible NTP Configuration**: Automated time synchronization
- [x] **Packer Custom AMIs**: Pre-configured worker node images
- [x] **Monitoring Stack**: Prometheus + Grafana
- [x] **CI/CD Pipeline**: GitHub Actions with security scanning
- [x] **Infrastructure Monitoring**: CloudWatch integration

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.6.0
- kubectl
- Docker
- Packer (for custom AMI builds)
- Ansible (for worker node configuration)

### 1. Bootstrap Remote State (One-time)
```bash
cd bootstrap
terraform init
terraform apply -auto-approve -var 'region=us-east-1'
# Note the outputs: state_bucket and lock_table
```

### 2. Build Custom Worker Node AMI (Optional)
```bash
cd packer
packer init worker-node.pkr.hcl
packer build -var 'aws_region=us-east-1' worker-node.pkr.hcl
# Note the AMI ID from the output
```

### 3. Configure Terraform Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values:
# - image_repository: Your ECR repository
# - mongo_app_password: Strong password
# - custom_ami_id: AMI ID from Packer (optional)
# - grafana_admin_password: Grafana admin password
```

### 4. Initialize and Deploy
```bash
# Initialize Terraform backend
terraform init \
  -backend-config="bucket=<STATE_BUCKET>" \
  -backend-config="key=envs/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=<LOCK_TABLE>" \
  -backend-config="encrypt=true"

# Plan and apply
terraform plan
terraform apply
```

### 5. Access the Application
```bash
# Get the application URL
kubectl get svc -n apps swimlane-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get Grafana URL (if monitoring is enabled)
kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 🔧 Manual Docker Build (Alternative to CI/CD)

```bash
# Clone the application source
git clone https://github.com/swimlane/devops-practical.git ./src

# Build and push to ECR
export AWS_REGION=us-east-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr create-repository --repository-name devops-practical --region $AWS_REGION || true
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -f docker/devops-practical.Dockerfile -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical:manual ./src
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical:manual

# Deploy with manual image
terraform apply -var "image_repository=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-practical" -var "image_tag=manual"
```

## 🔄 CI/CD Pipeline

The GitHub Actions workflow automatically:
1. **Builds** Docker image from the application source
2. **Scans** for security vulnerabilities with Trivy
3. **Pushes** to Amazon ECR
4. **Deploys** infrastructure with Terraform
5. **Verifies** deployment status

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TF_STATE_BUCKET` (from bootstrap output)
- `TF_LOCK_TABLE` (from bootstrap output)
- `MONGO_APP_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`

## 📊 Monitoring and Observability

### Prometheus Metrics
- Application metrics via ServiceMonitor
- Kubernetes cluster metrics
- Node and pod resource utilization

### Grafana Dashboards
- Pre-configured dashboards for:
  - Kubernetes cluster overview
  - Application performance
  - MongoDB metrics
  - Node resource usage

### Access Monitoring
```bash
# Port-forward to Grafana (if not using LoadBalancer)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Access at http://localhost:3000
# Username: admin
# Password: (from grafana_admin_password variable)
```

## 🛡️ Security Features

### Pod Security
- **Restricted Security Context**: Non-root containers
- **Read-only Root Filesystem**: Enhanced container security
- **Capability Dropping**: Minimal container privileges
- **Seccomp Profiles**: Runtime security enforcement

### Network Security
- **Network Policies**: Restrictive ingress/egress rules
- **Namespace Isolation**: Separate namespaces for apps and data
- **Service Mesh Ready**: Compatible with Istio/Linkerd

### Infrastructure Security
- **Encrypted EBS Volumes**: All persistent storage encrypted
- **IMDSv2**: Instance metadata service v2 enforced
- **VPC Security**: Private subnets for worker nodes
- **RBAC**: Role-based access control for Kubernetes

## 📈 Scalability Features

### Horizontal Scaling
- **HPA**: CPU-based pod scaling (2-6 replicas)
- **VPA**: Vertical pod autoscaling (optional)
- **Cluster Autoscaler**: Node group scaling (3-10 nodes)

### High Availability
- **Multi-AZ**: Spread across 3 availability zones
- **Pod Disruption Budgets**: Ensure minimum availability
- **MongoDB Replica Set**: 3-node replica set for data durability

## 🧹 Cleanup

```bash
# Destroy application infrastructure
terraform -chdir=terraform destroy

# Destroy bootstrap infrastructure
terraform -chdir=bootstrap destroy

# Remove ECR repository (optional)
aws ecr delete-repository --repository-name devops-practical --force --region us-east-1
```

## 📁 Project Structure

```
├── ansible/                    # Ansible playbooks for worker nodes
│   ├── playbooks/
│   │   ├── ntp-setup.yml      # NTP configuration
│   │   └── kubernetes-deps.yml # K8s dependencies
│   └── templates/
├── bootstrap/                  # Terraform remote state setup
├── docker/                     # Dockerfile for the application
├── helm/                       # Helm chart for the application
│   └── swimlane-devops-practical/
│       ├── templates/          # K8s manifests
│       └── values.yaml         # Chart values
├── packer/                     # Packer configuration for custom AMIs
├── terraform/                  # Main infrastructure code
│   ├── modules/                # Terraform modules
│   │   ├── app/               # Application deployment
│   │   ├── eks/               # EKS cluster
│   │   ├── mongodb/           # MongoDB deployment
│   │   ├── monitoring/        # Monitoring stack
│   │   └── vpc/               # VPC and networking
│   └── main.tf                # Main configuration
└── .github/workflows/         # CI/CD pipeline
```

## 🎯 Testing the Application

1. **Access the application** using the LoadBalancer URL
2. **Register a new account** in the application
3. **Add a record** to verify database connectivity
4. **Check monitoring** in Grafana for metrics
5. **Test scaling** by generating load

## 📝 Notes

- The application source is automatically cloned from the official repository
- MongoDB is deployed as a 3-node replica set for high availability
- All persistent storage is encrypted at rest
- The solution is designed for production use with proper security controls
- Custom AMI builds are optional but recommended for production environments

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
