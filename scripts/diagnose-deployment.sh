#!/bin/bash
set -e

echo "Diagnosing EKS Deployment Issues..."

cd "$(dirname "$0")/../terraform"

echo "Step 1: Updating kubeconfig..."
aws eks update-kubeconfig --region us-east-1 --name swimlane-eks

echo "Step 2: Checking cluster status..."
kubectl get nodes
kubectl get pods --all-namespaces

echo "Step 3: Checking application deployment..."
kubectl get deployments -n apps
kubectl get pods -n apps
kubectl describe deployment swimlane-app-v2 -n apps

echo "Step 4: Checking MongoDB status..."
kubectl get pods -n data
kubectl describe pod -l app=mongodb-simple -n data

echo "Step 5: Checking application logs..."
kubectl logs -l app=swimlane-app-v2 -n apps --tail=50

echo "Step 6: Checking MongoDB logs..."
kubectl logs -l app=mongodb-simple -n data --tail=20

echo "Step 7: Checking services..."
kubectl get services --all-namespaces

echo "Diagnosis completed!"
