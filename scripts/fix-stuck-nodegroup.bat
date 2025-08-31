@echo off
echo Fixing Stuck EKS Node Group...

cd /d "%~dp0\..\terraform"

echo Step 1: Destroying the stuck node group...
terraform destroy -auto-approve -target=module.eks.module.eks.module.eks_managed_node_group

echo Step 2: Waiting 30 seconds for cleanup...
timeout /t 30 /nobreak

echo Step 3: Recreating the node group...
terraform apply -auto-approve -target=module.eks

echo Node group fix completed!
pause
