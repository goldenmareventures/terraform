output "template_names" {
  description = "List of created template names"
  value       = [for template in aws_ses_template.templates : template.name]
}

output "template_arns" {
  description = "Map of template names to ARNs"
  value       = { for k, template in aws_ses_template.templates : k => template.arn }
}

output "configuration_set_names" {
  description = "Map of configuration set keys to names"
  value       = { for k, cs in aws_sesv2_configuration_set.config_sets : k => cs.configuration_set_name }
}

output "configuration_set_arns" {
  description = "Map of configuration set keys to ARNs"
  value       = { for k, cs in aws_sesv2_configuration_set.config_sets : k => cs.arn }
}
