# Lambda Function Module

Creates an AWS Lambda function with optional EventBridge trigger integration.

## Features

- Deploy Lambda functions from local ZIP files
- Automatic source code change detection
- Environment variable configuration, with optional KMS customer managed key
- EventBridge (CloudWatch Events) trigger integration
- Configurable runtime, timeout, and handler
- Dead letter queue for failed asynchronous invocations
- X-Ray tracing
- Function level concurrency limit
- Optional VPC attachment
- Environment-based tagging

## Usage

### Basic Lambda Function

```
module "hello_world" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "hello-world"
  lambda_path     = "../lambda/hello-world"
  lambda_role_arn = aws_iam_role.lambda_execution.arn
}
```

### Lambda with Environment Variables

```
module "api_handler" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "api-handler"
  lambda_path     = "../lambda/api-handler"
  lambda_role_arn = aws_iam_role.lambda_execution.arn

  env_vars = {
    API_URL       = "https://api.example.com"
    DATABASE_NAME = "production"
    LOG_LEVEL     = "info"
  }

  timeout = 30
}
```

### Lambda with EventBridge Trigger

```
module "amplify_pr_approver" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "approvePR-${var.jira_key}"
  lambda_path     = "../lambda/approvePR"
  lambda_role_arn = data.terraform_remote_state.global.outputs.lambda_basic_execution_role_arn

  notification_rule_arn = module.eventbridge.notification_rule_arn

  env_vars = {
    AUTH_STRING = var.bitbucket_auth_token
    JIRA_KEY    = var.jira_key
  }
}
```

### Python Lambda

```
module "data_processor" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "data-processor"
  lambda_path     = "../lambda/data-processor"
  lambda_role_arn = aws_iam_role.lambda_execution.arn

  runtime = "python3.12"
  handler = "main.handler"
  timeout = 60

  env_vars = {
    S3_BUCKET = "my-data-bucket"
  }
}
```

### Lambda with Multiple Environment Tags

```
module "staging_function" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "my-function"
  lambda_path     = "../lambda/my-function"
  lambda_role_arn = aws_iam_role.lambda_execution.arn
  environment     = "staging"

  env_vars = {
    DATABASE_URL = "postgresql://staging.db.example.com"
  }
}
```

### Lambda for DynamoDB Stream Processing

```
module "stream_processor" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "dynamodb-stream-processor"
  lambda_path     = "../lambda/stream-processor"
  lambda_role_arn = aws_iam_role.lambda_dynamodb.arn

  timeout = 300  # 5 minutes for batch processing

  env_vars = {
    TARGET_TABLE = "processed-data"
    BATCH_SIZE   = "100"
  }
}

# Attach to DynamoDB stream
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = aws_dynamodb_table.source.stream_arn
  function_name     = module.stream_processor.function_arn
  starting_position = "LATEST"
}
```

### Lambda with API Gateway Integration

```
module "api_endpoint" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "api-endpoint"
  lambda_path     = "../lambda/api"
  lambda_role_arn = aws_iam_role.lambda_api.arn

  timeout = 10

  env_vars = {
    CORS_ORIGIN = "https://example.com"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = module.api_endpoint.invoke_arn
}
```

### Asynchronous Function with a Dead Letter Queue

Use this for any function invoked by S3, SNS, or EventBridge. Without a DLQ, an
event that fails every retry is dropped silently.

```
resource "aws_sqs_queue" "dlq" {
  name = "image-processor-dlq"
}

module "image_processor" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "image-processor"
  lambda_path     = "../lambda/image-processor"
  lambda_role_arn = aws_iam_role.lambda_execution.arn

  dead_letter_target_arn         = aws_sqs_queue.dlq.arn
  reserved_concurrent_executions = 10
  tracing_mode                   = "Active"
}
```

### Function Inside a VPC

Only for functions that reach Aurora or another private resource.

```
module "db_worker" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "db-worker"
  lambda_path     = "../lambda/db-worker"
  lambda_role_arn = aws_iam_role.lambda_vpc.arn

  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.lambda.id]
}
```

### Environment Variables with a Customer Managed Key

```
module "secure_handler" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "secure-handler"
  lambda_path     = "../lambda/secure-handler"
  lambda_role_arn = aws_iam_role.lambda_execution.arn

  kms_key_arn = aws_kms_key.lambda.arn

  env_vars = {
    TENANT_ID = var.tenant_id
  }
}
```

### Using with Global IAM Role

```
# Reference role from global Terraform state
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket  = "my-terraform-state"
    key     = "global/terraform.tfstate"
    region  = "us-east-1"
  }
}

module "my_lambda" {
  source = "git::ssh://git@github.com/goldenmareventures/terraform.git//lambda?ref=v1.0.0"

  lambda_name     = "my-function"
  lambda_path     = "../lambda/my-function"
  lambda_role_arn = data.terraform_remote_state.global.outputs.lambda_basic_execution_role_arn
}
```

## Directory Structure

Your Lambda code should be organized with the ZIP file in a `dist` folder:

```
project/
├── terraform/
│   └── main.tf
└── lambda/
    └── my-function/
        ├── src/
        │   └── index.js
        ├── package.json
        └── dist/
            └── index.zip  # Required location
```

The module expects the ZIP file at: `{lambda_path}/dist/index.zip`

## Building Lambda ZIP Files

### Node.js

```bash
cd lambda/my-function
npm install
zip -r dist/index.zip . -x "dist/*" "node_modules/aws-sdk/*"
```

### Python

```bash
cd lambda/my-function
pip install -r requirements.txt -t .
zip -r dist/index.zip .
```

### Using Build Scripts

```bash
# package.json
{
  "scripts": {
    "build": "rm -rf dist && mkdir -p dist && zip -r dist/index.zip . -x 'dist/*' 'node_modules/aws-sdk/*'"
  }
}

npm run build
```

## Common Runtimes

| Runtime      | Value        |
| ------------ | ------------ |
| Node.js 24.x | `nodejs24.x` |
| Node.js 22.x | `nodejs22.x` |
| Python 3.13  | `python3.13` |
| Python 3.12  | `python3.12` |
| Python 3.11  | `python3.11` |
| Java 21      | `java21`     |
| .NET 8       | `dotnet8`    |

## Inputs

| Name                           | Description                                              | Type         | Default           | Required |
| ------------------------------ | -------------------------------------------------------- | ------------ | ----------------- | -------- |
| lambda_name                    | Lambda function name                                     | string       | -                 | yes      |
| lambda_path                    | Path to Lambda directory relative to terraform directory | string       | -                 | yes      |
| lambda_role_arn                | ARN of the IAM role for the Lambda function              | string       | -                 | yes      |
| runtime                        | Runtime environment for the Lambda function              | string       | `"nodejs24.x"`    | no       |
| handler                        | Lambda handler                                           | string       | `"index.handler"` | no       |
| timeout                        | Lambda function timeout in seconds                       | number       | `3`               | no       |
| memory_size                    | Memory in MB for the function                            | number       | `128`             | no       |
| layers                         | List of Lambda layer ARNs                                | list(string) | `[]`              | no       |
| env_vars                       | Environment variables                                    | map(string)  | `{}`              | no       |
| kms_key_arn                    | KMS CMK ARN for environment variable encryption          | string       | `null`            | no       |
| dead_letter_target_arn         | SQS or SNS ARN for failed async invocations              | string       | `null`            | no       |
| tracing_mode                   | X-Ray mode: `Active`, `PassThrough`, or null             | string       | `null`            | no       |
| reserved_concurrent_executions | Function level concurrency limit                         | number       | `null`            | no       |
| vpc_subnet_ids                 | Subnet IDs for VPC attachment                            | list(string) | `[]`              | no       |
| vpc_security_group_ids         | Security group IDs for VPC attachment                    | list(string) | `[]`              | no       |
| notification_rule_arn          | ARN of EventBridge rule to add as trigger                | string       | `null`            | no       |
| environment                    | Deployment environment                                   | string       | `"prod"`          | no       |
| tags                           | Tags to apply to the function                            | map(string)  | `{}`              | no       |

## Outputs

| Name          | Description                              |
| ------------- | ---------------------------------------- |
| function_name | Name of the Lambda function              |
| function_arn  | ARN of the Lambda function               |
| invoke_arn    | Invoke ARN (for API Gateway integration) |

## Notes

- The ZIP file must be located at `{lambda_path}/dist/index.zip`
- Source code changes are automatically detected via hash
- Lambda will redeploy when ZIP contents change
- Environment variables are optional - omit empty maps
- EventBridge permission is only created if `notification_rule_arn` is provided
- Maximum deployment package size: 50 MB (zipped), 250 MB (unzipped)
- Maximum timeout: 900 seconds (15 minutes)
- `kms_key_arn` is applied only when `env_vars` is not empty. AWS rejects the key otherwise.
- `dead_letter_config` applies to asynchronous invocations only. Synchronous callers get the error directly.
- The execution role needs `sqs:SendMessage` or `sns:Publish` on the DLQ target.
- The execution role needs `xray:PutTraceSegments` and `xray:PutTelemetryRecords` when `tracing_mode` is set.
- `reserved_concurrent_executions = 0` stops all invocations. Use null for the unreserved account pool.
- A VPC function needs a NAT gateway to reach the internet. The execution role needs `AWSLambdaVPCAccessExecutionRole`.

## IAM Role Requirements

Your Lambda execution role needs at minimum:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

This is provided by the AWS managed policy: `arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole`

## Triggering Redeployment

To force Lambda to redeploy without code changes:

```bash
# Update the ZIP file timestamp
touch lambda/my-function/dist/index.zip

# Or recreate the function
terraform apply -replace="module.my_lambda.aws_lambda_function.lambda"
```

## Viewing Logs

```bash
# Get log group name
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/my-function

# Tail logs
aws logs tail /aws/lambda/my-function --follow
```

## Testing Lambda

```bash
# Invoke via AWS CLI
aws lambda invoke \
  --function-name my-function \
  --payload '{"key": "value"}' \
  response.json

cat response.json
```

## Common Issues

**Issue**: Lambda doesn't update after code changes

- **Solution**: Ensure ZIP file contents actually changed and are in `dist/index.zip`

**Issue**: Environment variables not available

- **Solution**: Access via `process.env.VAR_NAME` (Node.js) or `os.environ['VAR_NAME']` (Python)

**Issue**: Function timeout

- **Solution**: Increase `timeout` parameter (max 900 seconds)

**Issue**: Permission denied errors

- **Solution**: Check IAM role has necessary permissions for resources your function accesses
