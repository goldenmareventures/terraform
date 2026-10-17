# ACM Module

Terraform module for requesting a public AWS Certificate Manager certificate with DNS validation. The module writes the validation records into a Route 53 hosted zone and waits until ACM issues the certificate.

## Features

- One certificate for a primary domain and optional subject alternative names
- DNS validation records written directly into the caller's hosted zone
- Waits for validation, so the ARN output is always an issued certificate
- Certificate transparency logging enabled
- Replacement with `create_before_destroy`

## Usage

### Apex and Wildcard

```terraform
module "certificate" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//acm?ref=v1.7.0"

  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  zone_id                   = module.example_com.zone_id

  tags = var.default_tags
}
```

Pass the ARN to a listener or a distribution:

```terraform
certificate_arn = module.certificate.certificate_arn
```

### CloudFront Certificate

CloudFront only accepts a certificate in `us-east-1`. Pass a provider for that region:

```terraform
module "cdn_certificate" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//acm?ref=v1.7.0"

  providers = {
    aws = aws.us_east_1
  }

  domain_name = "cdn.example.com"
  zone_id     = module.example_com.zone_id
}
```

## Inputs

| Name                      | Description                                         | Type         | Default | Required |
| ------------------------- | --------------------------------------------------- | ------------ | ------- | -------- |
| domain_name               | Primary domain on the certificate                   | string       | -       | yes      |
| subject_alternative_names | Additional names on the certificate                 | list(string) | []      | no       |
| zone_id                   | Hosted zone ID that receives the validation records | string       | -       | yes      |
| tags                      | Tags to apply to the resources                      | map(string)  | {}      | no       |

## Outputs

| Name            | Description                                       |
| --------------- | ------------------------------------------------- |
| certificate_arn | Certificate ARN, available after ACM validates it |
| domain_name     | Primary domain on the certificate                 |

## Notes

### Region

The module declares no provider. The certificate is created in the region of the caller's provider. A certificate for an ALB must be in the ALB's region. A certificate for CloudFront must be in `us-east-1`.

### Shared Validation Records

An apex and its wildcard, such as `example.com` and `*.example.com`, use the same validation CNAME. The records set `allow_overwrite = true`, so the second record does not fail with "already exists".

### Inputs Must Be Known at Plan

The validation records use the domain names as `for_each` keys. Set `domain_name` and `subject_alternative_names` from literals or variables. A value that is known only after apply fails the plan with "for_each value depends on resource attributes that cannot be determined until apply".

### Validation Time

The first apply waits until ACM issues the certificate. This can take several minutes.

### Name Servers

The hosted zone's name servers must already be live at the domain registrar. If they are not, validation never completes and the apply fails after the 45 minute timeout.

### Replacement

A change to a domain name replaces the certificate. `create_before_destroy` issues the new certificate before it removes the old one, so a listener that uses the ARN has no outage.
