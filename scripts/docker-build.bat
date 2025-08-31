@echo off
REM Docker Build Script for Windows with proper Buildx cache handling
REM This script resolves the "Cache export is not supported for the docker driver" error

setlocal enabledelayedexpansion

REM Configuration
set ECR_REGISTRY=052958000889.dkr.ecr.us-east-1.amazonaws.com
set ECR_REPOSITORY=devops-practical
set DOCKERFILE_PATH=./docker/devops-practical.Dockerfile
set BUILD_CONTEXT=.

echo Starting Docker build process...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running. Please start Docker and try again.
    exit /b 1
)

REM Create a new builder instance if it doesn't exist
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
for /f "tokens=*" %%i in ('git rev-parse --short HEAD') do set GIT_COMMIT=%%i
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set GIT_BRANCH=%%i

echo Building Docker image...

REM Build with cache support
docker buildx build ^
    --platform linux/amd64 ^
    --file %DOCKERFILE_PATH% ^
    --tag %ECR_REGISTRY%/%ECR_REPOSITORY%:latest ^
    --tag %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH% ^
    --tag %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH%-%GIT_COMMIT% ^
    --cache-from type=gha ^
    --cache-to type=gha,mode=max ^
    --push ^
    %BUILD_CONTEXT%

if errorlevel 1 (
    echo Error: Docker build failed.
    exit /b 1
)

echo Docker build completed successfully!
echo Image tags:
echo   - %ECR_REGISTRY%/%ECR_REPOSITORY%:latest
echo   - %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH%
echo   - %ECR_REGISTRY%/%ECR_REPOSITORY%:%GIT_BRANCH%-%GIT_COMMIT%
