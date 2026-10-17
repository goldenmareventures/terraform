# secrets-manager/tests/secrets.tftest.hcl

mock_provider "aws" {}

variables {
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

  secret_values = {
    database_url = "test-value"
  }
}

run "GMV_147_AC_2_readme_example_creates_two_secrets" {
  command = plan

  assert {
    condition     = length(aws_secretsmanager_secret.secret) == 2
    error_message = "The README example must create exactly two secrets."
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["database_url"].name == "/gmv/stage/backend/database_url"
    error_message = "The generated secret must carry the configured name."
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["anthropic_api_key"].name == "/gmv/stage/backend/anthropic_api_key"
    error_message = "The external secret must carry the configured name."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.generated) == 1
    error_message = "Exactly one secret version must exist, for the generated secret."
  }

  assert {
    condition     = keys(aws_secretsmanager_secret_version.generated) == ["database_url"]
    error_message = "The only secret version must be keyed database_url."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_policy.policy) == 0
    error_message = "No secret policy may exist when no secret sets a policy."
  }
}

run "GMV_147_AC_3_external_secret_has_no_version" {
  command = plan

  assert {
    condition     = !contains(keys(aws_secretsmanager_secret_version.generated), "anthropic_api_key")
    error_message = "An external secret must have no secret version, so Terraform never tracks or overwrites its value."
  }

  assert {
    condition     = contains(keys(aws_secretsmanager_secret.secret), "anthropic_api_key")
    error_message = "The external secret container must still be created."
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["anthropic_api_key"].name == "/gmv/stage/backend/anthropic_api_key"
    error_message = "The external secret container must carry the configured name."
  }
}

run "output_secret_arns_keyed_by_input_key" {
  command = plan

  assert {
    condition     = toset(keys(output.secret_arns)) == toset(["anthropic_api_key", "database_url"])
    error_message = "secret_arns must be keyed by the keys of the secrets map."
  }
}

run "defaults_pass_through" {
  command = plan

  assert {
    condition     = aws_secretsmanager_secret.secret["database_url"].recovery_window_in_days == 30
    error_message = "recovery_window_in_days must default to 30."
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["database_url"].kms_key_id == null
    error_message = "kms_key_id must default to null."
  }
}

run "zero_recovery_window_passes_through" {
  command = plan

  variables {
    recovery_window_in_days = 0
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["database_url"].recovery_window_in_days == 0
    error_message = "A recovery_window_in_days of 0 must reach the secret."
  }
}

run "bad_recovery_window_fails_validation" {
  command = plan

  variables {
    recovery_window_in_days = 3
  }

  expect_failures = [var.recovery_window_in_days]
}

run "recovery_window_above_range_fails_validation" {
  command = plan

  variables {
    recovery_window_in_days = 31
  }

  expect_failures = [var.recovery_window_in_days]
}

run "missing_generated_value_fails_validation" {
  command = plan

  variables {
    secrets = {
      database_url = { name = "/x" }
    }
    secret_values = {}
  }

  expect_failures = [var.secrets]
}

run "policy_creates_one_policy_resource" {
  command = plan

  variables {
    secrets = {
      database_url = {
        name   = "/gmv/stage/backend/database_url"
        policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
      }
      anthropic_api_key = {
        name     = "/gmv/stage/backend/anthropic_api_key"
        external = true
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret_policy.policy) == 1
    error_message = "Exactly one secret policy must exist, for the secret that sets a policy."
  }

  assert {
    condition     = aws_secretsmanager_secret_policy.policy["database_url"].block_public_policy == true
    error_message = "The secret policy must block public policies."
  }

  assert {
    condition     = aws_secretsmanager_secret_policy.policy["database_url"].policy == "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    error_message = "The secret policy must be the JSON the caller passed."
  }
}
