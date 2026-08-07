# Usage Example

## Simple table (current use case):

```
module "archive_table" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//dynamodb?ref=v1.0.0"

  table_name  = "archived-data"
  table_class = "STANDARD_INFREQUENT_ACCESS"
  hash_key    = "archiveId"

  attributes = [
    { name = "archiveId", type = "S" }
  ]

  ttl_enabled = true
}
```

## Table with GSI:

```
module "users_table" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//dynamodb?ref=v1.0.0"

  table_name = "users"
  hash_key   = "userId"

  attributes = [
    { name = "userId", type = "S" },
    { name = "email", type = "S" },
    { name = "status", type = "S" },
    { name = "createdAt", type = "N" }
  ]

  global_secondary_indexes = [
    {
      name            = "email-index"
      hash_key        = "email"
      projection_type = "ALL"
    },
    {
      name            = "status-created-index"
      hash_key        = "status"
      range_key       = "createdAt"
      projection_type = "KEYS_ONLY"
    }
  ]
}
```

## Table with sort key and TTL:

```
module "sessions_table" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//dynamodb?ref=v1.0.0"

  table_name = "sessions"
  hash_key   = "userId"
  range_key  = "sessionId"

  attributes = [
    { name = "userId", type = "S" },
    { name = "sessionId", type = "S" }
  ]

  ttl_enabled        = true
  ttl_attribute_name = "expiresAt"
}
```

## Table with streams (for Lambda triggers):

```
module "orders_table" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//dynamodb?ref=v1.0.0"

  table_name = "orders"
  hash_key   = "orderId"

  attributes = [
    { name = "orderId", type = "S" }
  ]

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

# Use the stream ARN for Lambda trigger
resource "aws_lambda_event_source_mapping" "orders_stream" {
  event_source_arn  = module.orders_table.stream_arn
  function_name     = module.order_processor_lambda.function_arn
  starting_position = "LATEST"
}
```

## Provisioned capacity table:

```
module "high_traffic_table" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//dynamodb?ref=v1.0.0"

  table_name    = "high-traffic"
  billing_mode  = "PROVISIONED"
  hash_key      = "id"

  read_capacity  = 100
  write_capacity = 50

  attributes = [
    { name = "id", type = "S" }
  ]
}
```

## Infrequent access table (cost savings):

```
module "archive_table" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//dynamodb?ref=v1.0.0"

  table_name  = "archived-data"
  table_class = "STANDARD_INFREQUENT_ACCESS"
  hash_key    = "archiveId"

  attributes = [
    { name = "archiveId", type = "S" }
  ]

  ttl_enabled = true
}
```
