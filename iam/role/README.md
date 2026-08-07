# Example invocations

## Lambda execution role

```
module "lambda_role" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//iam/role?ref=v1.0.0"

  role_name = "my-lambda-execution-role"
  description = "Lambda execution role"

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
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policies = {
    "ssm-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:*:*:parameter/myapp/*"
      }]
    })
  }
}
```

## EventBridge scheduler role

```
module "scheduler_role" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//iam/role?ref=v1.0.0"

  role_name = "eventbridge-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })

  inline_policies = {
    "invoke-lambda" = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = module.my_lambda.function_arn
      }]
    })
  }
}
```
