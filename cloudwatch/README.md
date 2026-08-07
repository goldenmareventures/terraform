# CloudWatch Module

Terraform module for creating an Amazon CloudWatch log group with a retention policy.

## Features

- Log group with a configurable retention period
- Optional KMS customer managed key
- Tagging

## Usage

### Basic Log Group

```terraform
module "app_logs" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//cloudwatch?ref=v1.0.0"

  log_group_name = "/aws/lambda/my-function"
  tags           = var.default_tags
}
```

### Long Retention

```terraform
module "audit_logs" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//cloudwatch?ref=v1.0.0"

  log_group_name    = "/application/audit"
  retention_in_days = 365

  tags = var.default_tags
}
```

## Inputs

| Name              | Description                              | Type        | Default | Required |
| ----------------- | ---------------------------------------- | ----------- | ------- | -------- |
| log_group_name    | CloudWatch log group name                | string      | -       | yes      |
| retention_in_days | Days to retain logs                      | number      | 14      | no       |
| kms_key_id        | KMS CMK ARN for log encryption           | string      | null    | no       |
| tags              | Tags to apply to the resources           | map(string) | {}      | no       |

## Outputs

| Name                      | Description                    |
| ------------------------- | ------------------------------ |
| cloudwatch_log_group_name | Name of the CloudWatch log group |

## Notes

### Retention

`retention_in_days` accepts only the values AWS allows: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, or 0 for never expire.

### Encryption

Log groups are always encrypted at rest with an AWS managed key. `kms_key_id` moves the group to a customer managed key, which adds key rotation control and audit separation. The key policy must allow the `logs.<region>.amazonaws.com` service principal, or the log group fails to create.

### Lambda Log Groups

Lambda creates its own log group on first invocation. Create the log group with this module before the function, and name it `/aws/lambda/<function_name>`, so Terraform owns retention instead of the default "never expire".
