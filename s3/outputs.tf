# modules/s3/outputs.tf
output "bucket_id" {
  description = "Name of the bucket"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "website_endpoint" {
  description = "Website endpoint (if website hosting enabled)"
  value       = var.website_config != null ? aws_s3_bucket_website_configuration.website[0].website_endpoint : null
}

output "website_domain" {
  description = "Website domain (if website hosting enabled)"
  value       = var.website_config != null ? aws_s3_bucket_website_configuration.website[0].website_domain : null
}
