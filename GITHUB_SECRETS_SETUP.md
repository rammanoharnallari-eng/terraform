# GitHub Secrets Setup

This document explains how to set up the required GitHub secrets for the CI/CD pipeline.

## Required Secrets

To run the GitHub Actions workflow successfully, you need to configure the following secrets in your GitHub repository:

### 1. AWS Credentials
- `AWS_ACCESS_KEY_ID` - Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret access key

### 2. Terraform Backend (Optional - now using hardcoded values)
- `TF_STATE_BUCKET` - S3 bucket for Terraform state (default: terraform-state220785)
- `TF_LOCK_TABLE` - DynamoDB table for state locking (default: terraform-state-locks)

### 3. Application Secrets (Optional - defaults provided)
- `MONGO_APP_PASSWORD` - MongoDB application password (default: defaultpassword123)
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password (default: admin123)

## How to Set Up Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click on **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with its corresponding value

## Minimum Required Setup

For the workflow to run, you only need to set:

```
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
```

The other secrets are optional and will use default values if not provided.

## Security Notes

- Never commit secrets to your repository
- Use strong passwords for production environments
- Rotate secrets regularly
- Consider using AWS IAM roles instead of access keys when possible

## Testing the Setup

After setting up the secrets, you can test the workflow by:

1. Pushing changes to the `main` branch
2. Creating a pull request
3. Checking the Actions tab for workflow execution

## Troubleshooting

If you encounter issues:

1. Check that all required secrets are set
2. Verify AWS credentials have the necessary permissions
3. Ensure the S3 bucket and DynamoDB table exist
4. Check the workflow logs for specific error messages
