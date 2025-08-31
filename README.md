# DevOps Practical on EKS (Terraform Modules + Remote State + CI/CD)

Tailored for:
- **App repo**: https://github.com/rammanoharnallari-eng/devops-practical-swimlane.git
- **Region (default)**: us-east-1 (N. Virginia)

Pipeline flow:
1) Build Docker image from your **app repo** source
2) Push to ECR `devops-practical` (account auto-detected)
3) Terraform `init` with **S3+DynamoDB** remote state
4) Terraform `apply` to provision EKS + MongoDB (replica set) + App (Helm)

## Quick start

### 0) (One-time) Bootstrap remote state
```bash
cd bootstrap
terraform init
terraform apply -auto-approve -var 'region=us-east-1'
# capture outputs: state_bucket, lock_table
```

### 1) Initialize Terraform backend (first time)
```bash
cd terraform
terraform init -reconfigure   -backend-config="bucket=<STATE_BUCKET>"   -backend-config="key=envs/dev/terraform.tfstate"   -backend-config="region=us-east-1"   -backend-config="dynamodb_table=<LOCK_TABLE>"   -backend-config="encrypt=true"
```

### 2) (Optional) Manual image build/push test
```bash
git clone https://github.com/rammanoharnallari-eng/devops-practical-swimlane.git ./src
export AWS_REGION=us-east-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr create-repository --repository-name devops-practical --region $AWS_REGION || true
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
docker build -f docker/devops-practical.Dockerfile -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical:manual ./src
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/devops-practical:manual
```

### 3) Apply Terraform (manual)
```bash
terraform -chdir=terraform apply -auto-approve   -var "image_repository=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devops-practical"   -var "image_tag=manual"   -var "mongo_app_password=$MONGO_APP_PASSWORD"
```

### 4) Access app
```bash
kubectl get svc -n apps swimlane-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
```

## GitHub Actions (CI/CD)

- Add these **Repository Secrets** in **Settings → Secrets and variables → Actions**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` → `us-east-1`
  - `TF_STATE_BUCKET` → from bootstrap output
  - `TF_LOCK_TABLE`  → from bootstrap output
  - `MONGO_APP_PASSWORD` → strong password

- Push to **main** → Workflow builds Docker from your **app repo**, pushes to ECR, then runs Terraform to deploy.

## Cleanup
```bash
terraform -chdir=terraform destroy
terraform -chdir=bootstrap destroy
```
