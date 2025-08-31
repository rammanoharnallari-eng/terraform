@echo off
setlocal enabledelayedexpansion

REM DevOps Practical Deployment Script for Windows
REM This script automates the deployment of the DevOps Practical application to EKS

set REGION=us-east-1
set BUILD_AMI=false
set DEPLOY_MONITORING=true
set SKIP_BOOTSTRAP=false

:parse_args
if "%~1"=="" goto :main
if "%~1"=="-r" (
    set REGION=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--region" (
    set REGION=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="-a" (
    set BUILD_AMI=true
    shift
    goto :parse_args
)
if "%~1"=="--build-ami" (
    set BUILD_AMI=true
    shift
    goto :parse_args
)
if "%~1"=="-m" (
    set DEPLOY_MONITORING=false
    shift
    goto :parse_args
)
if "%~1"=="--no-monitoring" (
    set DEPLOY_MONITORING=false
    shift
    goto :parse_args
)
if "%~1"=="-s" (
    set SKIP_BOOTSTRAP=true
    shift
    goto :parse_args
)
if "%~1"=="--skip-bootstrap" (
    set SKIP_BOOTSTRAP=true
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
echo Unknown option: %~1
goto :show_help

:show_help
echo Usage: %0 [OPTIONS]
echo.
echo Options:
echo   -r, --region REGION        AWS region (default: us-east-1)
echo   -a, --build-ami           Build custom AMI with Packer
echo   -m, --no-monitoring       Skip monitoring stack deployment
echo   -s, --skip-bootstrap      Skip bootstrap step
echo   -h, --help                Show this help message
echo.
echo Examples:
echo   %0                        # Deploy with defaults
echo   %0 -r us-west-2          # Deploy to us-west-2
echo   %0 -a                    # Build custom AMI and deploy
echo   %0 -m                    # Deploy without monitoring
exit /b 0

:main
echo [INFO] Starting deployment to region: %REGION%

REM Check prerequisites
echo [INFO] Checking prerequisites...
where aws >nul 2>nul
if errorlevel 1 (
    echo [ERROR] AWS CLI not found. Please install AWS CLI first.
    exit /b 1
)

where terraform >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Terraform not found. Please install Terraform first.
    exit /b 1
)

where kubectl >nul 2>nul
if errorlevel 1 (
    echo [ERROR] kubectl not found. Please install kubectl first.
    exit /b 1
)

where docker >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Docker not found. Please install Docker first.
    exit /b 1
)

if "%BUILD_AMI%"=="true" (
    where packer >nul 2>nul
    if errorlevel 1 (
        echo [ERROR] Packer not found. Please install Packer first.
        exit /b 1
    )
    
    where ansible >nul 2>nul
    if errorlevel 1 (
        echo [ERROR] Ansible not found. Please install Ansible first.
        exit /b 1
    )
)

REM Check AWS credentials
aws sts get-caller-identity >nul 2>nul
if errorlevel 1 (
    echo [ERROR] AWS credentials not configured. Please run 'aws configure' first.
    exit /b 1
)

echo [SUCCESS] All prerequisites met

REM Bootstrap remote state
if "%SKIP_BOOTSTRAP%"=="true" (
    echo [WARNING] Skipping bootstrap step
) else (
    echo [INFO] Bootstrapping remote state...
    cd bootstrap
    terraform init
    terraform apply -auto-approve -var "region=%REGION%"
    
    REM Capture outputs
    for /f "tokens=*" %%i in ('terraform output -raw state_bucket') do set STATE_BUCKET=%%i
    for /f "tokens=*" %%i in ('terraform output -raw lock_table') do set LOCK_TABLE=%%i
    
    echo [SUCCESS] Bootstrap completed
    echo [INFO] State bucket: !STATE_BUCKET!
    echo [INFO] Lock table: !LOCK_TABLE!
    cd ..
)

REM Build custom AMI
if "%BUILD_AMI%"=="true" (
    echo [INFO] Building custom AMI with Packer...
    cd packer
    packer init worker-node.pkr.hcl
    packer build -var "aws_region=%REGION%" worker-node.pkr.hcl
    echo [SUCCESS] Custom AMI built
    cd ..
) else (
    echo [WARNING] Skipping custom AMI build
)

REM Build and push Docker image
echo [INFO] Building and pushing Docker image...

REM Get AWS account ID
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%i

REM Create ECR repository if it doesn't exist
aws ecr create-repository --repository-name devops-practical --region %REGION% >nul 2>nul

REM Login to ECR
aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %ACCOUNT_ID%.dkr.ecr.%REGION%.amazonaws.com

REM Clone application source
if not exist "src" (
    echo [INFO] Cloning application source...
    git clone https://github.com/swimlane/devops-practical.git ./src
)

REM Build and push image
set IMAGE_TAG=manual-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set IMAGE_TAG=%IMAGE_TAG: =0%
set IMAGE_REPO=%ACCOUNT_ID%.dkr.ecr.%REGION%.amazonaws.com/devops-practical

docker build -f docker/devops-practical.Dockerfile -t %IMAGE_REPO%:%IMAGE_TAG% ./src
docker push %IMAGE_REPO%:%IMAGE_TAG%

REM Also tag as latest
docker tag %IMAGE_REPO%:%IMAGE_TAG% %IMAGE_REPO%:latest
docker push %IMAGE_REPO%:latest

echo [SUCCESS] Docker image built and pushed: %IMAGE_REPO%:%IMAGE_TAG%

REM Deploy infrastructure
echo [INFO] Deploying infrastructure with Terraform...
cd terraform

REM Initialize Terraform
terraform init ^
    -backend-config="bucket=%STATE_BUCKET%" ^
    -backend-config="key=envs/dev/terraform.tfstate" ^
    -backend-config="region=%REGION%" ^
    -backend-config="dynamodb_table=%LOCK_TABLE%" ^
    -backend-config="encrypt=true"

REM Create terraform.tfvars if it doesn't exist
if not exist "terraform.tfvars" (
    echo [INFO] Creating terraform.tfvars...
    copy terraform.tfvars.example terraform.tfvars
    echo [WARNING] Please edit terraform.tfvars to set your passwords and other sensitive values
    echo [WARNING] Press Enter to continue after editing...
    pause
)

REM Plan and apply
terraform plan
terraform apply -auto-approve

echo [SUCCESS] Infrastructure deployed successfully
cd ..

REM Get application URL
echo [INFO] Getting application URL...

REM Update kubeconfig
aws eks update-kubeconfig --region %REGION% --name swimlane-eks

REM Get LoadBalancer URL
for /f "tokens=*" %%i in ('kubectl get svc -n apps swimlane-app -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2^>nul') do set APP_URL=%%i

if not "%APP_URL%"=="" (
    echo [SUCCESS] Application URL: http://%APP_URL%
) else (
    echo [WARNING] Application URL not available yet. Check with: kubectl get svc -n apps
)

REM Get Grafana URL if monitoring is enabled
if "%DEPLOY_MONITORING%"=="true" (
    for /f "tokens=*" %%i in ('kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2^>nul') do set GRAFANA_URL=%%i
    
    if not "%GRAFANA_URL%"=="" (
        echo [SUCCESS] Grafana URL: http://%GRAFANA_URL%
        echo [INFO] Grafana username: admin
        echo [INFO] Grafana password: (check terraform.tfvars)
    )
)

echo [SUCCESS] Deployment completed successfully!
echo [INFO] You can now access the application and test it by:
echo [INFO] 1. Opening the application URL in your browser
echo [INFO] 2. Registering a new account
echo [INFO] 3. Adding a record to verify database connectivity

if "%DEPLOY_MONITORING%"=="true" (
    echo [INFO] 4. Checking monitoring in Grafana
)

endlocal
