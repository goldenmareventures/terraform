# ALB Module

Terraform module for an AWS Application Load Balancer with target groups, listeners,
listener rules, and a managed security group.

Target groups and listeners are declared as maps keyed by a short name, not as lists. A
map key is stable, so adding or removing one never renumbers and destroys the others.
Listeners and rules refer to a target group by its key, so no ARN is ever passed by hand.

## Features

- Internet-facing or internal, IPv4 or dual stack
- Managed security group that opens one ingress rule for each listener port
- Target groups for instance, IP, or lambda targets, with health checks and stickiness
- Listeners for HTTP and HTTPS, with extra SNI certificates
- Default actions and rule actions: forward, weighted forward, redirect, fixed response
- Listener rules matching on path, host, header, query string, method, or source IP
- Access logs and connection logs to S3

## Usage

### HTTPS with an HTTP redirect

The common layout. Port 80 redirects to port 443, and port 443 forwards to one target
group. ECS or an autoscaling group registers the targets.

```terraform
module "alb" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//alb?ref=v1.13.0"

  name       = "app-prod"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    app = {
      port         = 8080
      target_type  = "ip"
      health_check = { path = "/healthz", matcher = "200" }
    }
  }

  listeners = {
    http = {
      port = 80
      default_action = {
        type     = "redirect"
        redirect = { protocol = "HTTPS", port = "443", status_code = "HTTP_301" }
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.app.arn
      default_action  = { target_group_key = "app" }
    }
  }

  tags = local.tags
}
```

### Path based routing to several services

A rule with a lower priority number is evaluated first. Anything that matches no rule
falls through to the listener default action.

```terraform
module "alb" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//alb?ref=v1.13.0"

  name       = "app-prod"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    web = { port = 80, target_type = "ip" }
    api = { port = 3000, target_type = "ip", health_check = { path = "/api/health" } }
  }

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.app.arn

      # Extra certificates are served by SNI on the same listener.
      additional_certificate_arns = [aws_acm_certificate.api.arn]

      default_action = { target_group_key = "web" }
    }
  }

  listener_rules = {
    api = {
      listener_key = "https"
      priority     = 100
      action       = { target_group_key = "api" }
      conditions   = { path_patterns = ["/api/*"] }
    }

    maintenance = {
      listener_key = "https"
      priority     = 200

      action = {
        type = "fixed-response"
        fixed_response = {
          status_code  = "503"
          content_type = "text/html"
          message_body = "<h1>Down for maintenance</h1>"
        }
      }

      conditions = { host_headers = ["old.example.com"] }
    }
  }

  tags = local.tags
}
```

### Internal load balancer, closed security group

An internal load balancer must not accept traffic from the whole internet. Give the
security group the VPC CIDR instead.

```terraform
module "alb" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//alb?ref=v1.13.0"

  name       = "app-internal"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  internal   = true

  security_group = { ingress_cidr_blocks = [module.vpc.vpc_cidr_block] }

  target_groups = { app = { port = 8080, target_type = "ip" } }
  listeners     = { http = { port = 80, default_action = { target_group_key = "app" } } }

  tags = local.tags
}
```

### Weighted forward for a blue/green release

`target_group_weights` splits traffic across target groups. Change the numbers to shift
the release, and no listener is recreated.

```terraform
target_groups = {
  blue  = { port = 8080, target_type = "ip" }
  green = { port = 8080, target_type = "ip" }
}

listeners = {
  https = {
    port            = 443
    protocol        = "HTTPS"
    certificate_arn = aws_acm_certificate.app.arn

    default_action = {
      target_group_weights = { blue = 90, green = 10 }
    }
  }
}
```

### Access logs and hardened settings

```terraform
module "alb" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//alb?ref=v1.13.0"

  name       = "app-prod"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "strictest"
  idle_timeout               = 120

  access_logs = { bucket = aws_s3_bucket.logs.id, prefix = "alb" }

  # ... target_groups and listeners
}
```

## Inputs

| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| name | Name of the load balancer, and prefix for the security group and target groups | `string` | n/a | yes |
| vpc_id | VPC that holds the target groups and the managed security group | `string` | n/a | yes |
| subnet_ids | Subnets the load balancer runs in. At least two, in different AZs. | `list(string)` | n/a | yes |
| internal | Place the load balancer on private addresses only | `bool` | `false` | no |
| ip_address_type | `ipv4` or `dualstack` | `string` | `"ipv4"` | no |
| security_group | Managed security group. Null uses only `security_group_ids`. | `object` | `{}` | no |
| security_group_ids | Extra security groups to attach | `list(string)` | `[]` | no |
| idle_timeout | Seconds a connection can be idle | `number` | `60` | no |
| enable_http2 | Accept HTTP/2 connections | `bool` | `true` | no |
| enable_deletion_protection | Refuse to delete the load balancer | `bool` | `false` | no |
| drop_invalid_header_fields | Drop headers that do not match RFC 7230 | `bool` | `false` | no |
| preserve_host_header | Forward the client Host header unchanged | `bool` | `false` | no |
| desync_mitigation_mode | `monitor`, `defensive`, or `strictest` | `string` | `"defensive"` | no |
| access_logs | Access logs to S3 | `object` | `null` | no |
| connection_logs | Connection logs to S3 | `object` | `null` | no |
| target_groups | Target groups keyed by short name | `map(object)` | `{}` | no |
| listeners | Listeners keyed by short name | `map(object)` | `{}` | no |
| listener_rules | Listener rules keyed by short name | `map(object)` | `{}` | no |
| tags | Tags applied to every resource | `map(string)` | `{}` | no |

### security_group

| Field | Description | Default |
| --- | --- | --- |
| ingress_cidr_blocks | IPv4 CIDRs allowed to reach every listener port | `["0.0.0.0/0"]` |
| ingress_ipv6_cidr_blocks | IPv6 CIDRs allowed to reach every listener port | `[]` |
| egress_cidr_blocks | IPv4 CIDRs the load balancer may reach | `["0.0.0.0/0"]` |

### target_groups

| Field | Description | Default |
| --- | --- | --- |
| name | Target group name | `<name>-<key>` |
| port | Port the targets listen on | `80` |
| protocol | `HTTP` or `HTTPS` | `"HTTP"` |
| protocol_version | `HTTP1`, `HTTP2`, or `GRPC` | `"HTTP1"` |
| target_type | `instance`, `ip`, or `lambda` | `"instance"` |
| deregistration_delay | Seconds to drain a removed target | `300` |
| slow_start | Seconds to ramp traffic to a new target | `null` |
| load_balancing_algorithm_type | `round_robin`, `least_outstanding_requests`, or `weighted_random` | `null` |
| health_check | `enabled`, `path`, `port`, `protocol`, `matcher`, `interval`, `timeout`, `healthy_threshold`, `unhealthy_threshold` | `{}` |
| stickiness | `type`, `cookie_duration`, `cookie_name`, `enabled`. Null disables stickiness. | `null` |
| targets | Static targets keyed by short name: `id`, `port` | `{}` |
| tags | Extra tags for this target group | `{}` |

### listeners

| Field | Description | Default |
| --- | --- | --- |
| port | Listener port | n/a |
| protocol | `HTTP` or `HTTPS` | `"HTTP"` |
| certificate_arn | Certificate for an HTTPS listener. Required. | `null` |
| additional_certificate_arns | Extra certificates served by SNI | `[]` |
| ssl_policy | Security policy for an HTTPS listener | `ELBSecurityPolicy-TLS13-1-2-2021-06` |
| default_action | Action for a request that matches no rule | n/a |
| tags | Extra tags for this listener | `{}` |

### default_action and listener_rules action

| Field | Description | Default |
| --- | --- | --- |
| type | `forward`, `redirect`, or `fixed-response` | `"forward"` |
| target_group_key | Key of the target group to forward to | `null` |
| target_group_weights | Target group key to weight, for a split forward | `null` |
| redirect | `host`, `path`, `port`, `protocol`, `query`, `status_code` | `null` |
| fixed_response | `status_code`, `content_type`, `message_body` | `null` |

### listener_rules conditions

| Field | Description |
| --- | --- |
| path_patterns | Paths to match, for example `["/api/*"]` |
| host_headers | Host headers to match |
| http_request_methods | Methods to match, for example `["POST"]` |
| source_ips | Client CIDRs to match |
| http_headers | Header name to accepted values |
| query_strings | Query string key to accepted value |

## Outputs

| Name | Description |
| --- | --- |
| arn | ARN of the load balancer |
| arn_suffix | ARN suffix, for CloudWatch metric dimensions |
| id | ID of the load balancer |
| dns_name | DNS name, for a Route 53 alias record |
| zone_id | Hosted zone ID, for a Route 53 alias record |
| security_group_id | ID of the managed security group, or null |
| target_group_arns | Map of target group key to ARN |
| target_group_arn_suffixes | Map of target group key to ARN suffix |
| target_group_names | Map of target group key to name |
| listener_arns | Map of listener key to ARN |

## Notes

- The managed security group allows `0.0.0.0/0` by default. Set `ingress_cidr_blocks`
  for an internal load balancer.
- The security group opens only the listener ports. Traffic to the targets is controlled
  by the target security group, which must allow the load balancer group.
- Access logs need a bucket policy that lets the ELB log delivery account write to the
  bucket. The module does not create the bucket or the policy.
- A lambda target group needs an `aws_lambda_permission` with principal
  `elasticloadbalancing.amazonaws.com`. The module does not create it. Set
  `health_check = { enabled = false }` unless the function should be health checked.
- `targets` is for static registration only. ECS services, autoscaling groups, and
  EKS controllers register their own targets, so leave `targets` empty for them.
- Changing `port`, `protocol`, or `target_type` on a target group replaces it. Terraform
  may need two applies, because the listener must stop pointing at the old group first.
- The module creates no `terraform {}` block. Provider and version constraints come from
  the calling project.
