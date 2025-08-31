# Terraform Backend (S3 + DynamoDB)

## One-time bootstrap
```bash
cd bootstrap
terraform init -upgrade
terraform apply -auto-approve -var="region=<YOUR-REGION>"
```

## Migrate state
```bash
cd scripts
./migrate_state.sh <YOUR-REGION>
```

This writes `terraform/backend.hcl` and runs:
```
terraform init -migrate-state -backend-config=backend.hcl
```
