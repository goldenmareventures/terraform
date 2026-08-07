resource "aws_ses_template" "templates" {
  for_each = var.email_templates

  name    = each.value.name
  subject = each.value.subject
  html    = each.value.html
  text    = lookup(each.value, "text", null)
}

resource "aws_sesv2_configuration_set" "config_sets" {
  for_each = var.configuration_sets

  configuration_set_name = each.value.name

  reputation_options {
    reputation_metrics_enabled = lookup(each.value, "reputation_metrics_enabled", true)
  }

  sending_options {
    sending_enabled = lookup(each.value, "sending_enabled", true)
  }

  tags = var.tags
}

resource "aws_ses_event_destination" "cloudwatch_destinations" {
  for_each = var.cloudwatch_destinations

  name                   = each.value.name
  configuration_set_name = aws_sesv2_configuration_set.config_sets[each.value.configuration_set_key].configuration_set_name
  enabled                = lookup(each.value, "enabled", true)
  matching_types         = each.value.matching_types

  cloudwatch_destination {
    default_value  = each.value.cloudwatch.default_value
    dimension_name = each.value.cloudwatch.dimension_name
    value_source   = each.value.cloudwatch.value_source
  }
}

resource "aws_ses_event_destination" "sns_destinations" {
  for_each = var.sns_destinations

  name                   = each.value.name
  configuration_set_name = aws_sesv2_configuration_set.config_sets[each.value.configuration_set_key].configuration_set_name
  enabled                = lookup(each.value, "enabled", true)
  matching_types         = each.value.matching_types

  sns_destination {
    topic_arn = each.value.topic_arn
  }
}
