@echo off
echo Complete EKS Deployment - Step by Step...

cd /d "%~dp0\..\terraform"

echo Step 1: Refreshing Terraform state...
terraform refresh

echo Step 2: Planning EKS module only...
terraform plan -target=module.eks

echo Step 3: Applying EKS module (creates general-v2 node group)...
terraform apply -auto-approve -target=module.eks

echo Step 4: Waiting for node group to be ready...
echo Waiting 2 minutes for node group to be fully ready...
timeout /t 120 /nobreak

echo Step 5: Testing cluster access...
aws eks update-kubeconfig --region us-east-1 --name swimlane-eks
kubectl get nodes

echo Step 6: Planning the complete infrastructure...
terraform plan

echo Step 7: Applying the complete infrastructure...
terraform apply -auto-approve

echo Complete EKS deployment finished successfully!
pause
