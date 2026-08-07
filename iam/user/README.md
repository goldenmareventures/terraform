# IAM User Module

Creates an IAM user with optional access keys and policy attachments.

## Features

- Create IAM user with programmatic access
- Attach AWS managed policies
- Add inline policies
- Optional access key creation
- Secure outputs for credentials

## Usage

### Basic User with Access Key

```
module "basic_user" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//iam/user?ref=v1.1.0"

  user_name = "my-app-user"
}

output "access_key_id" {
  value = module.basic_user.access_key_id
}

output "secret_access_key" {
  value     = module.basic_user.secret_access_key
  sensitive = true
}
```

### S3 Access User

```
module "s3_backup_user" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//iam/user?ref=v1.1.0"

  user_name = "s3-backup-user"

  inline_policies = {
    "s3-backup-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::my-backup-bucket/*"
      }]
    })
  }
}
```

### User with Managed Policies

```
module "readonly_user" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//iam/user?ref=v1.1.0"

  user_name = "readonly-user"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}
```

### User with Multiple Policies

```
module "app_user" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//iam/user?ref=v1.1.0"

  user_name = "app-deploy-user"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  inline_policies = {
    "deploy-permissions" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "lambda:UpdateFunctionCode",
            "lambda:PublishVersion"
          ]
          Resource = "arn:aws:lambda:*:*:function:myapp-*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = "arn:aws:s3:::myapp-deploy/*"
        }
      ]
    })
  }

  tags = {
    Purpose = "Application Deployment"
    Team    = "DevOps"
  }
}
```

### User Without Access Key

For users that only need console access or temporary credentials:

```
module "console_user" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//iam/user?ref=v1.1.0"

  user_name         = "console-user"
  create_access_key = false

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
}
```

### Store Credentials in SSM Parameter Store

```
module "api_user" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//iam/user?ref=v1.1.0"

  user_name = "api-user"

  inline_policies = {
    "api-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = "dynamodb:*"
        Resource = "arn:aws:dynamodb:*:*:table/myapp-*"
      }]
    })
  }
}

resource "aws_ssm_parameter" "api_access_key" {
  name  = "/myapp/api/access-key-id"
  type  = "String"
  value = module.api_user.access_key_id
}

resource "aws_ssm_parameter" "api_secret_key" {
  name  = "/myapp/api/secret-access-key"
  type  = "SecureString"
  value = module.api_user.secret_access_key
}
```

## Retrieving Secret Access Key

After applying, retrieve the secret access key:

```bash
terraform output -raw secret_access_key
```

Or if stored in SSM:

```bash
aws ssm get-parameter --name /myapp/api/secret-access-key --with-decryption --query 'Parameter.Value' --output text
```

## Inputs

| Name                | Description                                    | Type         | Default | Required |
| ------------------- | ---------------------------------------------- | ------------ | ------- | -------- |
| user_name           | Name of the IAM user                           | string       | -       | yes      |
| path                | Path for the IAM user                          | string       | "/"     | no       |
| create_access_key   | Create access key for the user                 | bool         | true    | no       |
| managed_policy_arns | List of managed policy ARNs to attach          | list(string) | []      | no       |
| inline_policies     | Map of inline policy names to policy documents | map(string)  | {}      | no       |
| tags                | Tags to apply to the user                      | map(string)  | {}      | no       |

## Outputs

| Name              | Description                    | Sensitive |
| ----------------- | ------------------------------ | --------- |
| user_name         | Name of the IAM user           | no        |
| user_arn          | ARN of the IAM user            | no        |
| access_key_id     | Access key ID (if created)     | no        |
| secret_access_key | Secret access key (if created) | yes       |

## Security Considerations

- **Never commit credentials to git** - Use outputs, SSM Parameter Store, or Secrets Manager
- **Rotate access keys regularly** - Consider using temporary credentials where possible
- **Apply least privilege** - Only grant necessary permissions
- **Use inline policies for specific resources** - More maintainable than broad managed policies
- **Enable MFA** for sensitive operations (done outside Terraform via AWS Console)

## Notes

- Access keys are created automatically unless `create_access_key = false`
- Secret access key is only available in Terraform output immediately after creation
- To rotate keys, taint the access key resource: `terraform taint 'module.user_name.aws_iam_access_key.user_key[0]'`
- Users can have up to 2 access keys (useful for rotation without downtime)
