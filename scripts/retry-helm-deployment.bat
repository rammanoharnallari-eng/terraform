@echo off
echo Retrying Helm Deployment...

cd /d "%~dp0\..\terraform"

echo Step 1: Checking cluster status...
aws eks update-kubeconfig --region us-east-1 --name swimlane-eks
kubectl get nodes
kubectl get pods --all-namespaces

echo Step 2: Checking existing Helm releases...
helm list --all-namespaces

echo Step 3: Cleaning up failed releases...
helm uninstall mongodb -n data --ignore-not-found
helm uninstall kube-prometheus-stack -n monitoring --ignore-not-found

echo Step 4: Waiting for cleanup...
timeout /t 30 /nobreak

echo Step 5: Retrying deployment...
terraform apply -auto-approve

echo Helm deployment retry completed!
pause
