@echo off
echo Applying EKS Fix Step by Step...

cd /d "%~dp0\..\terraform"

echo Step 1: Refreshing Terraform state...
terraform refresh

echo Step 2: Planning the EKS module changes...
terraform plan -target=module.eks

echo Step 3: Applying EKS module (this will create general-v2 node group)...
terraform apply -auto-approve -target=module.eks

echo Step 4: Waiting for node group to be ready...
timeout /t 60 /nobreak

echo Step 5: Planning the rest of the infrastructure...
terraform plan

echo Step 6: Applying the complete infrastructure...
terraform apply -auto-approve

echo EKS fix completed successfully!
pause
