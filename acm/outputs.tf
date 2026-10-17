output "certificate_arn" {
  description = "Certificate ARN, available only after ACM validates the certificate"
  value       = aws_acm_certificate_validation.certificate.certificate_arn
}

output "domain_name" {
  description = "Primary domain on the certificate"
  value       = aws_acm_certificate.certificate.domain_name
}
