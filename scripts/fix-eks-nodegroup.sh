#!/bin/bash
set -e

echo "Fixing EKS Node Group Configuration..."

cd "$(dirname "$0")/../terraform"

echo "Applying simplified EKS node group configuration..."
terraform apply -auto-approve -target=module.eks

echo "EKS node group fix completed!"
