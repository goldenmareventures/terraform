# Secrets Manager Module

Terraform module for creating AWS Secrets Manager secrets from a map. A secret is either generated, where Terraform writes the value, or external, where a human sets the value outside Terraform.

## Features

- Many secrets from one module call
- Generated secrets take their value from a separate sensitive map
- External secrets get no version, so Terraform never overwrites a value a human sets
- Optional customer managed KMS key
- Optional resource policy per secret, with public policies blocked
- ARN output shaped for `ecs/service`

## Usage

### Generated and External Secrets

```terraform
module "backend_secrets" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//secrets-manager?ref=v1.6.0"

  secrets = {
    database_url = {
      name        = "/gmv/stage/backend/database_url"
      description = "Postgres connection string for the portal API"
    }
    anthropic_api_key = {
      name        = "/gmv/stage/backend/anthropic_api_key"
      description = "Anthropic API key. Set by a human, never by Terraform."
      external    = true
    }
  }

  # Sensitive. Keyed by the same keys as secrets. Only generated secrets appear here.
  secret_values = {
    database_url = "postgresql://${module.rds.username}:${random_password.app.result}@${module.rds.address}:5432/gmv"
  }

  tags = var.default_tags
}
```

Pass the ARNs to `ecs/service`:

```terraform
containers = {
  api = {
    # ...
    secrets = {
      DATABASE_URL      = module.backend_secrets.secret_arns["database_url"]
      ANTHROPIC_API_KEY = module.backend_secrets.secret_arns["anthropic_api_key"]
    }
  }
}

execution_role_secret_arns = values(module.backend_secrets.secret_arns)
```

### Customer Managed Key and Resource Policy

```terraform
module "shared_secrets" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//secrets-manager?ref=v1.6.0"

  secrets = {
    engine_shared_secret = {
      name   = "/gmv/prod/engine/shared_secret"
      policy = data.aws_iam_policy_document.engine_secret.json
    }
  }

  secret_values = {
    engine_shared_secret = random_password.engine.result
  }

  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 30

  tags = var.default_tags
}
```

When you set `kms_key_id`, also add the KMS key ARN to `execution_role_secret_arns` on `ecs/service`.

## Inputs

| Name                    | Description                                               | Type        | Default | Required |
| ----------------------- | --------------------------------------------------------- | ----------- | ------- | -------- |
| secrets                 | Map of secrets to create                                  | map(object) | -       | yes      |
| secret_values           | Sensitive values for generated secrets, keyed as secrets  | map(string) | {}      | no       |
| kms_key_id              | KMS key ARN or ID. Null uses the `aws/secretsmanager` key | string      | null    | no       |
| recovery_window_in_days | Days before a deleted secret is removed. 0 or 7-30        | number      | 30      | no       |
| tags                    | Tags to apply to the resources                            | map(string) | {}      | no       |

### `secrets` object

| Field       | Description                                        | Type   | Default | Required |
| ----------- | -------------------------------------------------- | ------ | ------- | -------- |
| name        | Full secret name                                   | string | -       | yes      |
| description | Secret description                                 | string | ""      | no       |
| external    | true when a human sets the value outside Terraform | bool   | false   | no       |
| policy      | Resource policy JSON for this secret               | string | null    | no       |

## Outputs

| Name        | Description                                    |
| ----------- | ---------------------------------------------- |
| secret_arns | Map of secret ARNs, keyed by the `secrets` key |

## Notes

### Setting an External Value

Terraform creates an external secret with no value. Set the value with the AWS console or the CLI:

```bash
aws secretsmanager put-secret-value --secret-id <name> --secret-string '<value>'
```

Later applies show no change, because the module creates no version for an external secret.

### Empty Secrets Block ECS Tasks

An ECS task that references an external secret with no value fails to start with `ResourceInitializationError`. Apply this module, set the value, then deploy the service.

### State

Generated values are stored in Terraform state in plain text. Protect the state backend.

### Map Keys

The map key is the Terraform resource address and the output key. The secret name comes from the `name` field. Do not rename a key after apply, because Terraform destroys and recreates the secret. An external value is lost when that happens.

### Deleted Secret Names

A deleted secret name cannot be used again until the recovery window ends. Use `recovery_window_in_days = 0` only in a disposable environment.

### Terraform Version

The `secrets` validation reads `secret_values`, so this module needs Terraform 1.9 or later.
