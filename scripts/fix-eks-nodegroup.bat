@echo off
echo Fixing EKS Node Group Configuration...

cd /d "%~dp0\..\terraform"

echo Applying simplified EKS node group configuration...
terraform apply -auto-approve -target=module.eks

echo EKS node group fix completed!
pause
