output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.table.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.table.id
}

output "stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = var.stream_enabled ? aws_dynamodb_table.table.stream_arn : null
}

output "stream_label" {
  description = "Label of the DynamoDB stream"
  value       = var.stream_enabled ? aws_dynamodb_table.table.stream_label : null
}
