# modules/alb/target_groups.tf
locals {
  target_attachments = {
    for a in flatten([
      for tgk, tg in var.target_groups : [
        for tk, t in tg.targets : {
          key = "${tgk}-${tk}", target_group = tgk, id = t.id, port = t.port
        }
      ]
    ]) : a.key => a
  }
}

resource "aws_lb_target_group" "tg" {
  for_each = var.target_groups

  name        = coalesce(each.value.name, "${var.name}-${each.key}")
  target_type = each.value.target_type

  # A lambda target group has no port, protocol, VPC, or draining period.
  # AWS rejects the request when any of them is set.
  vpc_id               = each.value.target_type == "lambda" ? null : var.vpc_id
  port                 = each.value.target_type == "lambda" ? null : each.value.port
  protocol             = each.value.target_type == "lambda" ? null : each.value.protocol
  protocol_version     = each.value.target_type == "lambda" ? null : each.value.protocol_version
  deregistration_delay = each.value.target_type == "lambda" ? null : each.value.deregistration_delay

  slow_start                    = each.value.slow_start
  load_balancing_algorithm_type = each.value.load_balancing_algorithm_type

  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    matcher             = each.value.health_check.matcher
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold

    # Same rule as above: a lambda health check has no port or protocol.
    port     = each.value.target_type == "lambda" ? null : each.value.health_check.port
    protocol = each.value.target_type == "lambda" ? null : each.value.health_check.protocol
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []

    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      # cookie_name belongs to app_cookie only. AWS rejects it for lb_cookie.
      cookie_name = stickiness.value.type == "app_cookie" ? stickiness.value.cookie_name : null
      enabled     = stickiness.value.enabled
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.name, "${var.name}-${each.key}")
  })
}

resource "aws_lb_target_group_attachment" "target" {
  for_each = local.target_attachments

  target_group_arn = aws_lb_target_group.tg[each.value.target_group].arn
  target_id        = each.value.id
  port             = each.value.port
}
