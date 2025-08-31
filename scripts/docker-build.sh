#!/bin/bash

# Docker Build Script with proper Buildx cache handling
# This script resolves the "Cache export is not supported for the docker driver" error

set -e

# Configuration
ECR_REGISTRY="052958000889.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY="devops-practical"
DOCKERFILE_PATH="./docker/devops-practical.Dockerfile"
BUILD_CONTEXT="."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Docker build process...${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Create a new builder instance if it doesn't exist
BUILDER_NAME="devops-practical-builder"
if ! docker buildx inspect $BUILDER_NAME > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating new Docker Buildx builder: $BUILDER_NAME${NC}"
    docker buildx create --name $BUILDER_NAME --use
else
    echo -e "${GREEN}Using existing Docker Buildx builder: $BUILDER_NAME${NC}"
    docker buildx use $BUILDER_NAME
fi

# Build the image with proper cache handling
echo -e "${GREEN}Building Docker image...${NC}"

# Get current git commit hash for tagging
GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Build with cache support
docker buildx build \
    --platform linux/amd64 \
    --file $DOCKERFILE_PATH \
    --tag $ECR_REGISTRY/$ECR_REPOSITORY:latest \
    --tag $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH \
    --tag $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH-$GIT_COMMIT \
    --cache-from type=gha \
    --cache-to type=gha,mode=max \
    --push \
    $BUILD_CONTEXT

echo -e "${GREEN}Docker build completed successfully!${NC}"
echo -e "${GREEN}Image tags:${NC}"
echo -e "  - $ECR_REGISTRY/$ECR_REPOSITORY:latest"
echo -e "  - $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH"
echo -e "  - $ECR_REGISTRY/$ECR_REPOSITORY:$GIT_BRANCH-$GIT_COMMIT"
