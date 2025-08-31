#!/bin/bash

# Complete Deployment Script for DevOps Practical Application
# This script builds the Docker image and deploys to Kubernetes

set -e

# Configuration
ECR_REGISTRY="052958000889.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY="devops-practical"
DOCKERFILE_PATH="./docker/devops-practical.Dockerfile"
BUILD_CONTEXT="."
NAMESPACE="devops-practical"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  DevOps Practical Deployment Script  ${NC}"
echo -e "${BLUE}========================================${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

if ! command_exists kubectl; then
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
    exit 1
fi

if ! command_exists aws; then
    echo -e "${RED}Error: AWS CLI is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites found${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check kubectl connection
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Kubernetes connections verified${NC}"

# Create Docker Buildx builder if it doesn't exist
BUILDER_NAME="devops-practical-builder"
if ! docker buildx inspect $BUILDER_NAME > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating new Docker Buildx builder: $BUILDER_NAME${NC}"
    docker buildx create --name $BUILDER_NAME --use
else
    echo -e "${GREEN}Using existing Docker Buildx builder: $BUILDER_NAME${NC}"
    docker buildx use $BUILDER_NAME
fi

# Get current git commit hash for tagging
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

echo -e "${YELLOW}Building Docker image...${NC}"
echo -e "  Branch: $GIT_BRANCH"
echo -e "  Commit: $GIT_COMMIT"

# Build with cache support
docker buildx build \
    --platform linux/amd64 \
    --file $DOCKERFILE_PATH \
    --tag $ECR_REGISTRY/$ECR_REPOSITORY:latest \
    --tag $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH \
    --tag $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH-$GIT_COMMIT \
    --cache-from type=gha \
    --push \
    $BUILD_CONTEXT

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker build completed successfully!${NC}"
else
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}Image tags:${NC}"
echo -e "  - $ECR_REGISTRY/$ECR_REPOSITORY:latest"
echo -e "  - $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH"
echo -e "  - $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH-$GIT_COMMIT"

# Deploy to Kubernetes
echo -e "${YELLOW}Deploying to Kubernetes...${NC}"

# Apply the deployment
kubectl apply -f deploy.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Kubernetes deployment applied successfully!${NC}"
else
    echo -e "${RED}✗ Kubernetes deployment failed${NC}"
    exit 1
fi

# Wait for deployment to be ready
echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/devops-practical -n $NAMESPACE

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment is ready!${NC}"
else
    echo -e "${YELLOW}⚠ Deployment may still be starting. Check with: kubectl get pods -n $NAMESPACE${NC}"
fi

# Show deployment status
echo -e "${BLUE}Deployment Status:${NC}"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get hpa -n $NAMESPACE

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment completed successfully!  ${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "${BLUE}Useful commands:${NC}"
echo -e "  View pods: kubectl get pods -n $NAMESPACE"
echo -e "  View logs: kubectl logs -f deployment/devops-practical -n $NAMESPACE"
echo -e "  Port forward: kubectl port-forward service/devops-practical-service 3000:80 -n $NAMESPACE"
echo -e "  Delete deployment: kubectl delete -f deploy.yaml"
