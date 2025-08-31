@echo off
REM Complete Deployment Script for DevOps Practical Application (Windows)
REM This script builds the Docker image and deploys to Kubernetes

setlocal enabledelayedexpansion

REM Configuration
set ECR_REGISTRY=052958000889.dkr.ecr.us-east-1.amazonaws.com
set ECR_REPOSITORY=devops-practical
set DOCKERFILE_PATH=./docker/devops-practical.Dockerfile
set BUILD_CONTEXT=.
set NAMESPACE=devops-practical

echo ========================================
echo   DevOps Practical Deployment Script  
echo ========================================

REM Check prerequisites
echo Checking prerequisites...

where docker >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed or not in PATH
    exit /b 1
)

where kubectl >nul 2>&1
if errorlevel 1 (
    echo Error: kubectl is not installed or not in PATH
    exit /b 1
)

where aws >nul 2>&1
if errorlevel 1 (
    echo Error: AWS CLI is not installed or not in PATH
    exit /b 1
)

echo ✓ All prerequisites found

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running. Please start Docker and try again.
    exit /b 1
)

REM Check kubectl connection
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig.
    exit /b 1
)

echo ✓ Docker and Kubernetes connections verified

REM Create Docker Buildx builder if it doesn't exist
set BUILDER_NAME=devops-practical-builder
docker buildx inspect %BUILDER_NAME% >nul 2>&1
if errorlevel 1 (
    echo Creating new Docker Buildx builder: %BUILDER_NAME%
    docker buildx create --name %BUILDER_NAME% --use
) else (
    echo Using existing Docker Buildx builder: %BUILDER_NAME%
    docker buildx use %BUILDER_NAME%
)

REM Get current git commit hash for tagging
for /f "tokens=*" %%i in ('git rev-parse --short HEAD 2^>nul') do set GIT_COMMIT=%%i
if "%GIT_COMMIT%"=="" set GIT_COMMIT=unknown

for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set GIT_BRANCH=%%i
if "%GIT_BRANCH%"=="" set GIT_BRANCH=main

echo Building Docker image...
echo   Branch: %GIT_BRANCH%
echo   Commit: %GIT_COMMIT%

REM Build with cache support
docker buildx build ^
    --platform linux/amd64 ^
    --file %DOCKERFILE_PATH% ^
    --tag %ECR_REGISTRY%/%ECR_REPOSITORY%:latest ^
    --tag %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH% ^
    --tag %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH%-%GIT_COMMIT% ^
    --cache-from type=gha ^
    --push ^
    %BUILD_CONTEXT%

if errorlevel 1 (
    echo ✗ Docker build failed
    exit /b 1
)

echo ✓ Docker build completed successfully!
echo Image tags:
echo   - %ECR_REGISTRY%/%ECR_REPOSITORY%:latest
echo   - %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH%
echo   - %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH%-%GIT_COMMIT%

REM Deploy to Kubernetes
echo Deploying to Kubernetes...

REM Apply the deployment
kubectl apply -f deploy.yaml

if errorlevel 1 (
    echo ✗ Kubernetes deployment failed
    exit /b 1
)

echo ✓ Kubernetes deployment applied successfully!

REM Wait for deployment to be ready
echo Waiting for deployment to be ready...
kubectl wait --for=condition=available --timeout=300s deployment/devops-practical -n %NAMESPACE%

if errorlevel 1 (
    echo ⚠ Deployment may still be starting. Check with: kubectl get pods -n %NAMESPACE%
) else (
    echo ✓ Deployment is ready!
)

REM Show deployment status
echo Deployment Status:
kubectl get pods -n %NAMESPACE%
echo.
kubectl get services -n %NAMESPACE%
echo.
kubectl get hpa -n %NAMESPACE%

echo ========================================
echo   Deployment completed successfully!  
echo ========================================

echo Useful commands:
echo   View pods: kubectl get pods -n %NAMESPACE%
echo   View logs: kubectl logs -f deployment/devops-practical -n %NAMESPACE%
echo   Port forward: kubectl port-forward service/devops-practical-service 3000:80 -n %NAMESPACE%
echo   Delete deployment: kubectl delete -f deploy.yaml
