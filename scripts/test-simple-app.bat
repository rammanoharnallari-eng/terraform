@echo off
echo Testing Simple Application Deployment...

cd /d "%~dp0\..\terraform"

echo Step 1: Updating kubeconfig...
aws eks update-kubeconfig --region us-east-1 --name swimlane-eks

echo Step 2: Creating a simple test deployment...
kubectl run test-app --image=nginx:alpine --port=80 -n apps

echo Step 3: Waiting for test deployment...
kubectl wait --for=condition=ready pod -l run=test-app -n apps --timeout=60s

echo Step 4: Checking test deployment status...
kubectl get pods -n apps

echo Step 5: Cleaning up test deployment...
kubectl delete deployment test-app -n apps

echo Test completed!
pause
