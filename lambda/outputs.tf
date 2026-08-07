output "function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "function_arn" {
  value = aws_lambda_function.lambda.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.lambda.invoke_arn
}
