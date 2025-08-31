@echo off
echo Force Node Group Replacement - Fixing Stuck EKS Node Group...

cd /d "%~dp0\..\terraform"

echo Step 1: Importing current state...
terraform refresh

echo Step 2: Planning the replacement...
terraform plan -target=module.eks

echo Step 3: Applying the replacement (this will create general-v2)...
terraform apply -auto-approve -target=module.eks

echo Step 4: Cleaning up old node group (if it exists)...
terraform destroy -auto-approve -target=module.eks.module.eks.module.eks_managed_node_group[\"general\"]

echo Node group replacement completed!
echo The new node group 'general-v2' should now be active.
pause
