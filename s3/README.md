# modules/s3/README.md

# S3 Module

Terraform module for creating Amazon S3 buckets with support for versioning, encryption, lifecycle rules, CORS, notifications, and access logging.

## Features

- Server-side encryption (AES256 or KMS)
- Public access blocking (enabled by default)
- Versioning
- Lifecycle rules with transitions and expiration
- CORS configuration
- Event notifications (Lambda, SQS, SNS)
- Access logging
- Bucket policies

## Usage

### Basic Bucket

```terraform
module "my_bucket" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name = "my-application-data"
  tags        = var.default_tags
}
```

### Versioned Bucket with Lifecycle Rules

```terraform
module "artifacts" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name        = "build-artifacts"
  versioning_enabled = true

  lifecycle_rules = [
    {
      id      = "expire-old-versions"
      enabled = true
      noncurrent_version_expiration_days = 90
      abort_incomplete_multipart_upload_days = 7
    },
    {
      id      = "archive-old-artifacts"
      enabled = true
      prefix  = "releases/"
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER" }
      ]
      expiration_days = 365
    }
  ]

  tags = var.default_tags
}
```

### S3 with Lambda Notification

```terraform
module "uploads" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name = "user-uploads"

  lambda_notifications = [
    {
      lambda_function_arn = aws_lambda_function.processor.arn
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = "incoming/"
      filter_suffix       = ".csv"
    }
  ]

  tags = var.default_tags
}
```

### KMS Encrypted Bucket with Logging

```terraform
module "sensitive_data" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name        = "sensitive-data"
  versioning_enabled = true
  kms_key_arn        = aws_kms_key.s3.arn

  logging_config = {
    target_bucket = module.logs_bucket.bucket_id
    target_prefix = "s3-access-logs/sensitive-data/"
  }

  tags = var.default_tags
}
```

### CORS for Web Application

```terraform
module "api_assets" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name = "api-assets"

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://myapp.com", "https://www.myapp.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]

  tags = var.default_tags
}
```

### Basic static site

```
module "website" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name = "my-static-site"

  website_config = {
    index_document = "index.html"
    error_document = "404.html"
  }

  # Disable public access blocking for website
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  tags = local.tags
}
```

### Redirect bucket

```
module "redirect" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//s3?ref=v1.0.0"

  bucket_name = "old-domain-redirect"

  website_config = {
    index_document = "index.html"  # Required but unused with redirect
    redirect_all_requests_to = {
      host_name = "www.newdomain.com"
      protocol  = "https"
    }
  }

  tags = local.tags
}
```

## Inputs

| Name                    | Description                               | Type         | Default | Required |
| ----------------------- | ----------------------------------------- | ------------ | ------- | -------- |
| bucket_name             | Name of the S3 bucket                     | string       | -       | yes      |
| force_destroy           | Allow bucket deletion even when not empty | bool         | false   | no       |
| versioning_enabled      | Enable versioning                         | bool         | false   | no       |
| encryption_enabled      | Enable server-side encryption             | bool         | true    | no       |
| kms_key_arn             | KMS key ARN for encryption                | string       | null    | no       |
| bucket_key_enabled      | Enable S3 Bucket Key for KMS              | bool         | true    | no       |
| block_public_acls       | Block public ACLs                         | bool         | true    | no       |
| block_public_policy     | Block public bucket policies              | bool         | true    | no       |
| ignore_public_acls      | Ignore public ACLs                        | bool         | true    | no       |
| restrict_public_buckets | Restrict public bucket policies           | bool         | true    | no       |
| lifecycle_rules         | List of lifecycle rules                   | list(object) | []      | no       |
| cors_rules              | List of CORS rules                        | list(object) | []      | no       |
| policy                  | JSON bucket policy document               | string       | null    | no       |
| lambda_notifications    | Lambda function notifications             | list(object) | []      | no       |
| sqs_notifications       | SQS queue notifications                   | list(object) | []      | no       |
| sns_notifications       | SNS topic notifications                   | list(object) | []      | no       |
| website_config          | Static website hosting configuration      | object       | null    | no       |
| logging_config          | Access logging configuration              | object       | null    | no       |
| tags                    | Tags to apply to the bucket               | map(string)  | {}      | no       |

## Outputs

| Name                        | Description                        |
| --------------------------- | ---------------------------------- |
| bucket_id                   | Name of the bucket                 |
| bucket_arn                  | ARN of the bucket                  |
| bucket_domain_name          | Domain name of the bucket          |
| bucket_regional_domain_name | Regional domain name of the bucket |
| website_endpoint            | Website endpoint (if enabled)      |
| website_domain              | Website domain (if enabled)        |

## Notes

### Public Access

By default, all public access is blocked. To enable public access, you must explicitly set all four public access block variables to `false` and provide an appropriate bucket policy.

### Encryption

AES256 encryption is enabled by default. To use KMS encryption, provide a `kms_key_arn`. The `bucket_key_enabled` option reduces KMS API costs by using S3 Bucket Keys.

### Lifecycle Rules

Storage class transitions must follow this order: STANDARD → STANDARD_IA → INTELLIGENT_TIERING → ONEZONE_IA → GLACIER_IR → GLACIER → DEEP_ARCHIVE.

### Notifications

When using notifications, ensure the target (Lambda, SQS, SNS) has the appropriate permissions to be invoked by S3. This typically requires a resource-based policy on the target.

### Static Website Hosting

To enable static website hosting, provide a `website_config` object with at least an `index_document`. For public websites, you must also disable public access blocking and add a bucket policy allowing `s3:GetObject`.
