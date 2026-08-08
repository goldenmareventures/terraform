# modules/ecs/service/main.tf
locals {
  create_security_group = var.security_group != null

  security_group_ids = concat(
    local.create_security_group ? [aws_security_group.service[0].id] : [],
    var.security_group_ids,
  )

  container_ports = distinct(flatten([
    for c in var.containers : [for p in c.port_mappings : p.container_port]
  ]))

  ingress_ports = !local.create_security_group ? [] : (
    var.security_group.ingress_ports != null ? var.security_group.ingress_ports : local.container_ports
  )

  # One ingress rule for each port and source pair.
  sg_ingress_source_sg = !local.create_security_group ? {} : {
    for r in flatten([
      for port in local.ingress_ports : [
        for sg in var.security_group.ingress_security_group_ids : {
          key = "${port}-${sg}", port = port, source = sg
        }
      ]
    ]) : r.key => r
  }

  sg_ingress_ipv4 = !local.create_security_group ? {} : {
    for r in flatten([
      for port in local.ingress_ports : [
        for cidr in var.security_group.ingress_cidr_blocks : {
          key = "${port}-${cidr}", port = port, cidr = cidr
        }
      ]
    ]) : r.key => r
  }

  sg_egress = !local.create_security_group ? {} : {
    for cidr in var.security_group.egress_cidr_blocks : cidr => cidr
  }
}

resource "aws_ecs_service" "service" {
  count = var.create_service ? 1 : 0

  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count

  # launch_type and capacity_provider_strategy cannot both be set.
  launch_type      = length(var.capacity_provider_strategy) > 0 ? null : var.launch_type
  platform_version = var.platform_version

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  # AWS rejects a grace period on a service with no load balancer.
  health_check_grace_period_seconds = length(var.load_balancers) > 0 ? var.health_check_grace_period_seconds : null

  enable_execute_command        = var.enable_execute_command
  enable_ecs_managed_tags       = var.enable_ecs_managed_tags
  propagate_tags                = var.propagate_tags
  availability_zone_rebalancing = var.availability_zone_rebalancing
  wait_for_steady_state         = var.wait_for_steady_state
  force_new_deployment          = var.force_new_deployment

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = local.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy

    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries != null ? [var.service_registries] : []

    content {
      registry_arn   = service_registries.value.registry_arn
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
      port           = service_registries.value.port
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_circuit_breaker != null ? [var.deployment_circuit_breaker] : []

    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  tags = merge(var.tags, { Name = var.name })

  # The first tasks fail to start if the execution role cannot pull the image
  # yet, so the policy must be attached before the service is created.
  depends_on = [
    aws_iam_role_policy_attachment.execution_default,
    aws_iam_role_policy.execution_secrets,
  ]
}

# The security group is replaced, not updated, when its name changes. A running
# task cannot be left with no group, so the new one is created first.
resource "aws_security_group" "service" {
  count = local.create_security_group ? 1 : 0

  name_prefix = "${var.name}-ecs-"
  description = "Managed by the ecs/service module for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-ecs" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "source_sg" {
  for_each = local.sg_ingress_source_sg

  security_group_id            = aws_security_group.service[0].id
  description                  = "Container port ${each.value.port} from ${each.value.source}"
  referenced_security_group_id = each.value.source
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"

  tags = merge(var.tags, { Name = "${var.name}-ecs-${each.key}" })
}

resource "aws_vpc_security_group_ingress_rule" "ipv4" {
  for_each = local.sg_ingress_ipv4

  security_group_id = aws_security_group.service[0].id
  description       = "Container port ${each.value.port} from ${each.value.cidr}"
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"

  tags = merge(var.tags, { Name = "${var.name}-ecs-${each.key}" })
}

resource "aws_vpc_security_group_egress_rule" "service" {
  for_each = local.sg_egress

  security_group_id = aws_security_group.service[0].id
  description       = "All egress to ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "-1"

  tags = merge(var.tags, { Name = "${var.name}-ecs-egress" })
}
