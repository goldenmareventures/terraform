# Usage examples

## Create standalone policy

```
module "ses_send_policy" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//iam/policy?ref=v1.0.0"

  policy_name = "SESSendEmails"
  description = "Allow sending emails via SES"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail",
        "ses:SendTemplatedEmail"
      ]
      Resource = "*"
    }]
  })
}
```

## Attach to role

```
module "lambda_role" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//iam/role?ref=v1.0.0"

  role_name = "my-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    module.ses_send_policy.policy_arn,
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}
```
