# CloudFront Module

Terraform module for creating Amazon CloudFront distributions with support for multiple origins, cache behaviors, custom error responses, and Origin Access Controls.

## Features

- Multiple origins (S3, ALB, API Gateway, custom)
- Origin Access Controls for S3
- Origin groups for failover
- Cache policies and legacy TTL settings
- Ordered cache behaviors
- CloudFront Functions and Lambda@Edge
- Custom error responses
- Geo restrictions
- Access logging
- Custom SSL certificates

## Usage

### S3 Static Website with OAC (using module-created OAC)

```terraform
module "cdn" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//cloudfront?ref=v1.0.0"

  comment             = "Static website CDN"
  default_root_object = "index.html"
  aliases             = ["www.example.com"]

  origin_access_controls = {
    s3_oac = {
      name        = "s3-oac"
      description = "OAC for S3 bucket"
    }
  }

  origins = [
    {
      domain_name               = module.website_bucket.bucket_regional_domain_name
      origin_id                 = "s3-origin"
      origin_access_control_key = "s3_oac"
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  }

  custom_error_responses = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.cert.arn
  }

  tags = local.tags
}
```

### ALB Origin

```terraform
module "cdn" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//cloudfront?ref=v1.0.0"

  comment = "API CDN"
  aliases = ["api.example.com"]

  origins = [
    {
      domain_name = aws_lb.api.dns_name
      origin_id   = "alb-origin"
      custom_origin_config = {
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
  }

  viewer_certificate = {
    acm_certificate_arn = aws_acm_certificate.cert.arn
  }

  tags = local.tags
}
```

### S3 Origin with External OAC

```terraform
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cdn" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//cloudfront?ref=v1.0.0"

  comment             = "Static website CDN"
  default_root_object = "index.html"

  origins = [
    {
      domain_name              = module.website_bucket.bucket_regional_domain_name
      origin_id                = "s3-origin"
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  tags = local.tags
}
```

### Multiple Origins with Path-Based Routing

```terraform
module "cdn" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//cloudfront?ref=v1.0.0"

  comment             = "Multi-origin CDN"
  default_root_object = "index.html"

  origin_access_controls = {
    s3_oac = {
      name = "s3-static-oac"
    }
  }

  origins = [
    {
      domain_name               = module.static_bucket.bucket_regional_domain_name
      origin_id                 = "s3-static"
      origin_access_control_key = "s3_oac"
    },
    {
      domain_name = aws_lb.api.dns_name
      origin_id   = "alb-api"
      custom_origin_config = {
        origin_protocol_policy = "https-only"
      }
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behaviors = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "alb-api"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    }
  ]

  tags = local.tags
}
```

## Inputs

| Name                    | Description                         | Type         | Default                   | Required |
| ----------------------- | ----------------------------------- | ------------ | ------------------------- | -------- |
| enabled                 | Whether the distribution is enabled | bool         | true                      | no       |
| is_ipv6_enabled         | Enable IPv6                         | bool         | true                      | no       |
| comment                 | Comment for the distribution        | string       | null                      | no       |
| default_root_object     | Default root object                 | string       | null                      | no       |
| price_class             | Price class                         | string       | PriceClass_100            | no       |
| aliases                 | Alternate domain names              | list(string) | []                        | no       |
| web_acl_id              | WAF Web ACL ID                      | string       | null                      | no       |
| http_version            | HTTP version                        | string       | http2and3                 | no       |
| origins                 | List of origins                     | list(object) | -                         | yes      |
| origin_groups           | Origin groups for failover          | list(object) | []                        | no       |
| default_cache_behavior  | Default cache behavior              | object       | -                         | yes      |
| ordered_cache_behaviors | Ordered cache behaviors             | list(object) | []                        | no       |
| custom_error_responses  | Custom error responses              | list(object) | []                        | no       |
| geo_restriction         | Geo restriction config              | object       | {restriction_type="none"} | no       |
| viewer_certificate      | SSL certificate config              | object       | {}                        | no       |
| logging_config          | Access logging config               | object       | null                      | no       |
| origin_access_controls  | OACs to create                      | map(object)  | {}                        | no       |
| tags                    | Tags                                | map(string)  | {}                        | no       |

## Origins

Each origin object supports:

| Name                      | Description                                                | Type         | Required |
| ------------------------- | ---------------------------------------------------------- | ------------ | -------- |
| domain_name               | Origin domain name                                         | string       | yes      |
| origin_id                 | Unique identifier for the origin                           | string       | yes      |
| origin_path               | Path to request content from                               | string       | no       |
| origin_access_control_key | Key from `origin_access_controls` map (module-created OAC) | string       | no       |
| origin_access_control_id  | ID of externally-created OAC                               | string       | no       |
| custom_origin_config      | Custom origin settings (for non-S3)                        | object       | no       |
| s3_origin_config          | S3 origin settings (legacy OAI)                            | object       | no       |
| custom_headers            | Custom headers to send to origin                           | list(object) | no       |
| origin_shield             | Origin Shield config                                       | object       | no       |

Use `origin_access_control_key` to reference an OAC created by this module, or `origin_access_control_id` to pass an externally-created OAC ID.

## Outputs

| Name                        | Description                     |
| --------------------------- | ------------------------------- |
| distribution_id             | ID of the distribution          |
| distribution_arn            | ARN of the distribution         |
| distribution_domain_name    | Domain name (\*.cloudfront.net) |
| distribution_hosted_zone_id | Route 53 hosted zone ID         |
| distribution_status         | Status of the distribution      |
| origin_access_control_ids   | Map of OAC IDs                  |

## Notes

### Origin Access Controls

OAC is the recommended way to secure S3 origins (replaces Origin Access Identity). You can either:

1. **Create OAC within the module** using `origin_access_controls` and reference it via `origin_access_control_key`
2. **Create OAC externally** and pass the ID via `origin_access_control_id`

Remember to update your S3 bucket policy to allow CloudFront access:

```terraform
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.bucket.bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.distribution_arn]
    }
  }
}
```

### Cache Policies

Use AWS managed cache policies when possible:

- `658327ea-f89d-4fab-a63d-7e88639e58f6` - CachingOptimized
- `4135ea2d-6df8-44a3-9df3-4b5a84be39ad` - CachingDisabled
- `b2884449-e4de-46a7-ac36-70bc7f1ddd6d` - CachingOptimizedForUncompressedObjects

### Origin Access Controls

OAC is the recommended way to secure S3 origins (replaces Origin Access Identity). Remember to update your S3 bucket policy to allow CloudFront access.

### Price Classes

- `PriceClass_All` - All edge locations
- `PriceClass_200` - North America, Europe, Asia, Middle East, Africa
- `PriceClass_100` - North America, Europe (cheapest)
