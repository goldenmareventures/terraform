# modules/alb/listeners.tf
locals {
  # TLS 1.3 policy. Falls back to the caller's ssl_policy when one is given.
  default_ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  listener_certificates = {
    for c in flatten([
      for lk, l in var.listeners : [
        for arn in l.additional_certificate_arns : { key = "${lk}-${arn}", listener = lk, arn = arn }
      ]
    ]) : c.key => c
  }
}

resource "aws_lb_listener" "listener" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.alb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  # Both arguments are rejected on an HTTP listener.
  ssl_policy      = each.value.protocol == "HTTPS" ? coalesce(each.value.ssl_policy, local.default_ssl_policy) : null
  certificate_arn = each.value.protocol == "HTTPS" ? each.value.certificate_arn : null

  default_action {
    type = each.value.default_action.type

    # A single forward uses target_group_arn. A weighted forward uses the
    # forward block instead, and AWS rejects both at once.
    target_group_arn = (
      each.value.default_action.type == "forward" && each.value.default_action.target_group_weights == null
      ? aws_lb_target_group.tg[each.value.default_action.target_group_key].arn
      : null
    )

    dynamic "forward" {
      for_each = each.value.default_action.target_group_weights != null ? [each.value.default_action.target_group_weights] : []

      content {
        dynamic "target_group" {
          for_each = forward.value

          content {
            arn    = aws_lb_target_group.tg[target_group.key].arn
            weight = target_group.value
          }
        }
      }
    }

    dynamic "redirect" {
      for_each = each.value.default_action.redirect != null ? [each.value.default_action.redirect] : []

      content {
        host        = redirect.value.host
        path        = redirect.value.path
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.default_action.fixed_response != null ? [each.value.default_action.fixed_response] : []

      content {
        status_code  = fixed_response.value.status_code
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
      }
    }
  }

  tags = merge(var.tags, each.value.tags, { Name = "${var.name}-${each.key}" })
}

# Extra certificates for SNI. The first certificate stays on the listener.
resource "aws_lb_listener_certificate" "certificate" {
  for_each = local.listener_certificates

  listener_arn    = aws_lb_listener.listener[each.value.listener].arn
  certificate_arn = each.value.arn
}

resource "aws_lb_listener_rule" "rule" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.listener[each.value.listener_key].arn
  priority     = each.value.priority

  action {
    type = each.value.action.type

    target_group_arn = (
      each.value.action.type == "forward" && each.value.action.target_group_weights == null
      ? aws_lb_target_group.tg[each.value.action.target_group_key].arn
      : null
    )

    dynamic "forward" {
      for_each = each.value.action.target_group_weights != null ? [each.value.action.target_group_weights] : []

      content {
        dynamic "target_group" {
          for_each = forward.value

          content {
            arn    = aws_lb_target_group.tg[target_group.key].arn
            weight = target_group.value
          }
        }
      }
    }

    dynamic "redirect" {
      for_each = each.value.action.redirect != null ? [each.value.action.redirect] : []

      content {
        host        = redirect.value.host
        path        = redirect.value.path
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        query       = redirect.value.query
        status_code = redirect.value.status_code
      }
    }

    dynamic "fixed_response" {
      for_each = each.value.action.fixed_response != null ? [each.value.action.fixed_response] : []

      content {
        status_code  = fixed_response.value.status_code
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.path_patterns != null ? [each.value.conditions.path_patterns] : []

    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.host_headers != null ? [each.value.conditions.host_headers] : []

    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.http_request_methods != null ? [each.value.conditions.http_request_methods] : []

    content {
      http_request_method {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.source_ips != null ? [each.value.conditions.source_ips] : []

    content {
      source_ip {
        values = condition.value
      }
    }
  }

  # One condition block for each header name.
  dynamic "condition" {
    for_each = coalesce(each.value.conditions.http_headers, {})

    content {
      http_header {
        http_header_name = condition.key
        values           = condition.value
      }
    }
  }

  # All query string pairs live in one condition block.
  dynamic "condition" {
    for_each = each.value.conditions.query_strings != null ? [each.value.conditions.query_strings] : []

    content {
      dynamic "query_string" {
        for_each = condition.value

        content {
          key   = query_string.key
          value = query_string.value
        }
      }
    }
  }

  tags = var.tags
}
