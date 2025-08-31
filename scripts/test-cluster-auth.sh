#!/bin/bash
set -e

echo "Testing EKS Cluster Authentication..."

cd "$(dirname "$0")/../terraform"

echo "Step 1: Updating kubeconfig..."
aws eks update-kubeconfig --region us-east-1 --name swimlane-eks

echo "Step 2: Testing cluster connectivity..."
kubectl cluster-info

echo "Step 3: Testing node access..."
kubectl get nodes

echo "Step 4: Testing namespace creation..."
kubectl create namespace test-namespace --dry-run=client

echo "Step 5: Cleaning up test namespace..."
kubectl delete namespace test-namespace --ignore-not-found=true

echo "Cluster authentication test completed!"
