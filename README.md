# Modular Terraform: EKS + MongoDB + App

Modules:
- `modules/vpc` – VPC (3 AZs, public/private subnets, NATs)
- `modules/eks` – EKS cluster + managed node group
- `modules/mongodb` – Bitnami MongoDB (replica set) via Helm
- `modules/app` – App Secret (MONGODB_URL) + Helm chart deploy (local chart)

## Quick start

```bash
git clone https://github.com/swimlane/devops-practical ./src
export AWS_REGION=ap-south-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Build & push image
docker build -f docker/devops-practical.Dockerfile -t devops-practical:local ./src
aws ecr create-repository --repository-name devops-practical --region $AWS_REGION || true
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
docker tag devops-practical:local $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical:v1
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical:v1

# Terraform (modular)
cd terraform
cat > terraform.tfvars <<EOF
region             = "$AWS_REGION"
image_repository   = "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical"
image_tag          = "v1"
mongo_app_password = "CHANGEME-STRONG!"
EOF

terraform init
terraform apply -auto-approve
```

Get the external URL:
```bash
kubectl get svc -n apps swimlane-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
```

Open the URL, register, add a record, and screenshot it.

Cleanup:
```bash
terraform destroy
```
