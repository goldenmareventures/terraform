# modules/route53/outputs.tf
output "zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = aws_route53_zone.zone.zone_id
}

output "zone_arn" {
  description = "ARN of the Route53 hosted zone"
  value       = aws_route53_zone.zone.arn
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.zone.name_servers
}

output "record_names" {
  description = "Map of record keys to their FQDNs"
  value       = { for k, v in aws_route53_record.records : k => v.fqdn }
}
