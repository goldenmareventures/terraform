# SSM Module

Terraform module for creating AWS Systems Manager Parameter Store parameters from a map.

## Features

- Many parameters from one module call
- `String`, `StringList`, and `SecureString` types
- `SecureString` by default
- Type validation on every parameter

## Usage

### Basic Secrets

```terraform
module "app_parameters" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ssm?ref=v1.0.0"

  ssm_variables = {
    db_password = {
      name        = "/myapp/prod/db_password"
      description = "Aurora master password"
      value       = random_password.db.result
    }
    api_key = {
      name  = "/myapp/prod/api_key"
      value = var.api_key
    }
  }

  tags = var.default_tags
}
```

### Plain String Parameters

```terraform
module "app_config" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//ssm?ref=v1.0.0"

  ssm_variables = {
    api_url = {
      name  = "/myapp/prod/api_url"
      type  = "String"
      value = "https://api.myapp.com"
    }
    allowed_origins = {
      name  = "/myapp/prod/allowed_origins"
      type  = "StringList"
      value = "https://myapp.com,https://www.myapp.com"
    }
  }

  tags = var.default_tags
}
```

## Inputs

| Name          | Description                     | Type        | Default | Required |
| ------------- | ------------------------------- | ----------- | ------- | -------- |
| ssm_variables | Map of SSM parameters to create | map(object) | -       | yes      |
| tags          | Tags to apply to the resources  | map(string) | {}      | no       |

### `ssm_variables` object

| Field       | Description                                    | Type   | Default        | Required |
| ----------- | ---------------------------------------------- | ------ | -------------- | -------- |
| name        | Full parameter path                            | string | -              | yes      |
| value       | Parameter value                                | string | -              | yes      |
| description | Parameter description                          | string | ""             | no       |
| type        | String, StringList, or SecureString            | string | "SecureString" | no       |

## Outputs

This module has no outputs. Read a parameter by its `name` with the `aws_ssm_parameter` data source.

## Notes

### Map Keys

The map key is the Terraform resource address only. The parameter path comes from the `name` field. Do not rename a key after apply, because Terraform destroys and recreates the parameter.

### Encryption

`SecureString` parameters use the default `aws/ssm` KMS key. This module does not accept a custom KMS key.

### State

Parameter values are stored in Terraform state in plain text. Protect the state backend.
