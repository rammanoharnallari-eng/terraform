#!/bin/bash

# Test Deployment Script for DevOps Practical Application
# This script tests the deployed application

set -e

NAMESPACE="devops-practical"
SERVICE_NAME="devops-practical-service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing DevOps Practical Deployment  ${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    echo -e "${RED}Error: Namespace '$NAMESPACE' does not exist${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Namespace '$NAMESPACE' exists${NC}"

# Check if deployment is ready
echo -e "${YELLOW}Checking deployment status...${NC}"
kubectl get deployment devops-practical -n $NAMESPACE

# Check if pods are running
echo -e "${YELLOW}Checking pod status...${NC}"
kubectl get pods -n $NAMESPACE -l app=devops-practical

# Check if service exists
if ! kubectl get service $SERVICE_NAME -n $NAMESPACE > /dev/null 2>&1; then
    echo -e "${RED}Error: Service '$SERVICE_NAME' does not exist${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Service '$SERVICE_NAME' exists${NC}"

# Port forward to test the application
echo -e "${YELLOW}Setting up port forwarding...${NC}"
echo -e "Port forwarding from localhost:3000 to service:80"

# Start port forwarding in background
kubectl port-forward service/$SERVICE_NAME 3000:80 -n $NAMESPACE &
PORT_FORWARD_PID=$!

# Wait a moment for port forwarding to establish
sleep 5

# Test the application endpoints
echo -e "${YELLOW}Testing application endpoints...${NC}"

# Test health endpoint
echo -e "${BLUE}Testing /health endpoint...${NC}"
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health endpoint is working${NC}"
    curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health
else
    echo -e "${RED}✗ Health endpoint failed${NC}"
fi

echo ""

# Test root endpoint
echo -e "${BLUE}Testing / endpoint...${NC}"
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Root endpoint is working${NC}"
    curl -s http://localhost:3000/ | jq . 2>/dev/null || curl -s http://localhost:3000/
else
    echo -e "${RED}✗ Root endpoint failed${NC}"
fi

echo ""

# Test API status endpoint
echo -e "${BLUE}Testing /api/status endpoint...${NC}"
if curl -f http://localhost:3000/api/status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API status endpoint is working${NC}"
    curl -s http://localhost:3000/api/status | jq . 2>/dev/null || curl -s http://localhost:3000/api/status
else
    echo -e "${RED}✗ API status endpoint failed${NC}"
fi

# Clean up port forwarding
echo -e "${YELLOW}Cleaning up port forwarding...${NC}"
kill $PORT_FORWARD_PID 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Testing completed!                   ${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "${BLUE}To manually test the application:${NC}"
echo -e "  kubectl port-forward service/$SERVICE_NAME 3000:80 -n $NAMESPACE"
echo -e "  Then visit: http://localhost:3000"
