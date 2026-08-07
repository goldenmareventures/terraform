# modules/alb/outputs.tf
output "arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.alb.arn
}

output "arn_suffix" {
  description = "ARN suffix of the load balancer, for CloudWatch metric dimensions"
  value       = aws_lb.alb.arn_suffix
}

output "id" {
  description = "ID of the load balancer"
  value       = aws_lb.alb.id
}

output "dns_name" {
  description = "DNS name of the load balancer. Use it as the target of a Route 53 alias record."
  value       = aws_lb.alb.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the load balancer, needed by a Route 53 alias record"
  value       = aws_lb.alb.zone_id
}

output "security_group_id" {
  description = "ID of the managed security group, or null when the module did not create one"
  value       = one(aws_security_group.alb[*].id)
}

output "target_group_arns" {
  description = "Map of target group key to ARN"
  value       = { for k, v in aws_lb_target_group.tg : k => v.arn }
}

output "target_group_arn_suffixes" {
  description = "Map of target group key to ARN suffix, for CloudWatch metric dimensions"
  value       = { for k, v in aws_lb_target_group.tg : k => v.arn_suffix }
}

output "target_group_names" {
  description = "Map of target group key to name"
  value       = { for k, v in aws_lb_target_group.tg : k => v.name }
}

output "listener_arns" {
  description = "Map of listener key to ARN"
  value       = { for k, v in aws_lb_listener.listener : k => v.arn }
}
