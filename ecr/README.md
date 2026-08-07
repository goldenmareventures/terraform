# ECR Module

Terraform module for creating Amazon ECR repositories with support for image scanning, lifecycle policies, encryption, and repository policies.

## Features

- Image vulnerability scanning on push
- Tag immutability
- Lifecycle policies for automatic image cleanup
- AES256 or KMS encryption
- Repository policies for cross-account access

## Usage

### Basic Repository

```terraform
module "api_repo" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecr?ref=v1.0.0"

  repository_name = "my-api"
  tags            = local.tags
}
```

### With Lifecycle Policy (cleanup old images)

```terraform
module "api_repo" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecr?ref=v1.0.0"

  repository_name      = "my-api"
  image_tag_mutability = "IMMUTABLE"

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.tags
}
```

### With KMS Encryption

```terraform
module "secure_repo" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecr?ref=v1.0.0"

  repository_name = "sensitive-app"
  kms_key_arn     = aws_kms_key.ecr.arn

  tags = local.tags
}
```

### With Cross-Account Pull Access

```terraform
module "shared_repo" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecr?ref=v1.0.0"

  repository_name = "shared-base-image"

  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })

  tags = local.tags
}
```

## Inputs

| Name                 | Description                           | Type        | Default | Required |
| -------------------- | ------------------------------------- | ----------- | ------- | -------- |
| repository_name      | Name of the ECR repository            | string      | -       | yes      |
| image_tag_mutability | Tag mutability (MUTABLE or IMMUTABLE) | string      | MUTABLE | no       |
| force_delete         | Delete repository even with images    | bool        | false   | no       |
| scan_on_push         | Scan images on push                   | bool        | true    | no       |
| encryption_type      | Encryption type (AES256 or KMS)       | string      | AES256  | no       |
| kms_key_arn          | KMS key ARN (forces KMS encryption)   | string      | null    | no       |
| lifecycle_policy     | JSON lifecycle policy document        | string      | null    | no       |
| repository_policy    | JSON repository policy document       | string      | null    | no       |
| tags                 | Tags to apply                         | map(string) | {}      | no       |

## Outputs

| Name            | Description              |
| --------------- | ------------------------ |
| repository_arn  | ARN of the repository    |
| repository_url  | URL for docker push/pull |
| repository_name | Name of the repository   |
| registry_id     | Registry ID              |

## Notes

### Tag Immutability

Setting `image_tag_mutability = "IMMUTABLE"` prevents tags from being overwritten. This is recommended for production to ensure a given tag always references the same image. Use it with a CI pipeline that tags by commit SHA or semantic version.

### Lifecycle Policies

Lifecycle rules are evaluated by `rulePriority` (lowest first). A common pattern is to keep the last N tagged releases and expire untagged images after a few days. Note that tagged and untagged rules should target distinct `tagStatus` values to avoid one rule shadowing another.

### Encryption

AES256 is the default. Providing a `kms_key_arn` switches to KMS encryption automatically. KMS gives you audit logging and key rotation control but adds per-request KMS costs on image layers.

### Pushing Images

After creating the repository, authenticate Docker and push:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <registry_id>.dkr.ecr.us-east-1.amazonaws.com
docker tag my-api:latest <repository_url>:latest
docker push <repository_url>:latest
```
