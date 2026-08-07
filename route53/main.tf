# modules/route53/main.tf
resource "aws_route53_zone" "zone" {
  name          = var.domain_name
  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = var.vpc_id != null ? [1] : []
    content {
      vpc_id = var.vpc_id
    }
  }

  tags = var.tags
}

resource "aws_route53_record" "records" {
  for_each = var.records

  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", null)
  records = lookup(each.value, "records", null)

  dynamic "alias" {
    for_each = lookup(each.value, "alias", null) != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = lookup(alias.value, "evaluate_target_health", false)
    }
  }

  set_identifier = lookup(each.value, "set_identifier", null)

  dynamic "weighted_routing_policy" {
    for_each = lookup(each.value, "weighted_routing_policy", null) != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = lookup(each.value, "latency_routing_policy", null) != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = lookup(each.value, "geolocation_routing_policy", null) != null ? [each.value.geolocation_routing_policy] : []
    content {
      continent   = lookup(geolocation_routing_policy.value, "continent", null)
      country     = lookup(geolocation_routing_policy.value, "country", null)
      subdivision = lookup(geolocation_routing_policy.value, "subdivision", null)
    }
  }

  dynamic "failover_routing_policy" {
    for_each = lookup(each.value, "failover_routing_policy", null) != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  health_check_id = lookup(each.value, "health_check_id", null)
}
