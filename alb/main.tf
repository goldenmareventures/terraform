# modules/alb/main.tf
locals {
  create_security_group = var.security_group != null

  security_group_ids = concat(
    local.create_security_group ? [aws_security_group.alb[0].id] : [],
    var.security_group_ids,
  )

  # One ingress rule for each listener port and CIDR pair. Two listeners on the
  # same port would collide, but AWS rejects that anyway.
  sg_ingress_ipv4 = !local.create_security_group ? {} : {
    for r in flatten([
      for lk, l in var.listeners : [
        for cidr in var.security_group.ingress_cidr_blocks : {
          key = "${lk}-${cidr}", port = l.port, cidr = cidr
        }
      ]
    ]) : r.key => r
  }

  sg_ingress_ipv6 = !local.create_security_group ? {} : {
    for r in flatten([
      for lk, l in var.listeners : [
        for cidr in var.security_group.ingress_ipv6_cidr_blocks : {
          key = "${lk}-${cidr}", port = l.port, cidr = cidr
        }
      ]
    ]) : r.key => r
  }

  sg_egress = !local.create_security_group ? {} : {
    for cidr in var.security_group.egress_cidr_blocks : cidr => cidr
  }
}

resource "aws_lb" "alb" {
  name               = var.name
  load_balancer_type = "application"
  internal           = var.internal
  subnets            = var.subnet_ids
  security_groups    = local.security_group_ids
  ip_address_type    = var.ip_address_type

  idle_timeout               = var.idle_timeout
  enable_http2               = var.enable_http2
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields
  preserve_host_header       = var.preserve_host_header
  desync_mitigation_mode     = var.desync_mitigation_mode

  dynamic "access_logs" {
    for_each = var.access_logs != null ? [var.access_logs] : []

    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  dynamic "connection_logs" {
    for_each = var.connection_logs != null ? [var.connection_logs] : []

    content {
      bucket  = connection_logs.value.bucket
      prefix  = connection_logs.value.prefix
      enabled = connection_logs.value.enabled
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

# The security group is replaced, not updated, when its name changes. A load
# balancer cannot be left with no group, so the new one is created first.
resource "aws_security_group" "alb" {
  count = local.create_security_group ? 1 : 0

  name_prefix = "${var.name}-alb-"
  description = "Managed by the alb module for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ipv4" {
  for_each = local.sg_ingress_ipv4

  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = merge(var.tags, { Name = "${var.name}-alb-${each.key}" })
}

resource "aws_vpc_security_group_ingress_rule" "ipv6" {
  for_each = local.sg_ingress_ipv6

  security_group_id = aws_security_group.alb[0].id
  cidr_ipv6         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = merge(var.tags, { Name = "${var.name}-alb-${each.key}" })
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  for_each = local.sg_egress

  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "-1"

  tags = merge(var.tags, { Name = "${var.name}-alb-egress" })
}
