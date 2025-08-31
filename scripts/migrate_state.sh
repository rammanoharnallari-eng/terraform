#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (the dir that contains bootstrap/ and terraform/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BOOT_DIR="$ROOT_DIR/bootstrap"
TF_DIR="$ROOT_DIR/terraform"

REGION="${1:-${AWS_REGION:-us-east-1}}"

echo "==> Bootstrapping backend in region: $REGION"
pushd "$BOOT_DIR" >/dev/null
  terraform init -upgrade
  terraform apply -auto-approve -var="region=$REGION"
  BUCKET="$(terraform output -raw state_bucket)"
  TABLE="$(terraform output -raw dynamodb_table)"
popd >/dev/null

echo "==> Writing $TF_DIR/backend.hcl"
cat > "$TF_DIR/backend.hcl" <<EOF
bucket         = "$BUCKET"
key            = "state/eks/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$TABLE"
encrypt        = true
EOF

echo "==> Initializing Terraform with S3 backend (will migrate state if present)"
pushd "$TF_DIR" >/dev/null
  terraform init -migrate-state -backend-config="backend.hcl"
  echo "==> Done. Backend is now S3 with DynamoDB locking."
popd >/dev/null
