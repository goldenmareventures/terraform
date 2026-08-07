# modules/ecs/service/autoscaling.tf
locals {
  enable_autoscaling = var.create_service && var.autoscaling != null

  # The cluster ARN ends with the cluster name. A bare name works too.
  cluster_name = reverse(split("/", var.cluster_arn))[0]

  autoscaling_cpu_target    = try(var.autoscaling.cpu_target, null)
  autoscaling_memory_target = try(var.autoscaling.memory_target, null)
  autoscaling_request_count = try(var.autoscaling.request_count, null)
}

resource "aws_appautoscaling_target" "service" {
  count = local.enable_autoscaling ? 1 : 0

  service_namespace  = "ecs"
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.service[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscaling.min_capacity
  max_capacity       = var.autoscaling.max_capacity

  tags = var.tags
}

resource "aws_appautoscaling_policy" "cpu" {
  count = local.enable_autoscaling && local.autoscaling_cpu_target != null ? 1 : 0

  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = local.autoscaling_cpu_target
    scale_in_cooldown  = var.autoscaling.scale_in_cooldown
    scale_out_cooldown = var.autoscaling.scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = local.enable_autoscaling && local.autoscaling_memory_target != null ? 1 : 0

  name               = "${var.name}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = local.autoscaling_memory_target
    scale_in_cooldown  = var.autoscaling.scale_in_cooldown
    scale_out_cooldown = var.autoscaling.scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "request_count" {
  count = local.enable_autoscaling && local.autoscaling_request_count != null ? 1 : 0

  name               = "${var.name}-request-count"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service[0].resource_id
  scalable_dimension = aws_appautoscaling_target.service[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.service[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = local.autoscaling_request_count.target
    scale_in_cooldown  = var.autoscaling.scale_in_cooldown
    scale_out_cooldown = var.autoscaling.scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = local.autoscaling_request_count.resource_label
    }
  }
}
