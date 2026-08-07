# Route53 DNS Module

Creates and manages Route53 hosted zones and DNS records.

## Features

- Create hosted zones
- Public and private (VPC) hosted zones
- A, AAAA, CNAME, MX, TXT, SRV, and other record types
- Alias records for AWS resources
- Advanced routing policies (weighted, latency, geolocation, failover)
- Health check integration

## Usage

### Basic Domain with Common Records

```
module "example_com" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "example.com"

  records = {
    root = {
      name = "example.com"
      type = "A"
      ttl  = 300
      records = ["192.0.2.1"]
    }
    www = {
      name = "www.example.com"
      type = "CNAME"
      ttl  = 300
      records = ["example.com"]
    }
    mx = {
      name = "example.com"
      type = "MX"
      ttl  = 3600
      records = [
        "1 aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
        "5 alt2.aspmx.l.google.com"
      ]
    }
    txt = {
      name = "example.com"
      type = "TXT"
      ttl  = 300
      records = [
        "v=spf1 include:_spf.google.com ~all"
      ]
    }
  }
}

output "name_servers" {
  value = module.example_com.name_servers
}
```

### CloudFront Distribution with Alias Record

```
module "myapp_com" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "myapp.com"

  records = {
    root = {
      name = "myapp.com"
      type = "A"
      alias = {
        name                   = "d1234567890.cloudfront.net"
        zone_id                = "Z2FDTNDATAQYW2"  # CloudFront zone ID
        evaluate_target_health = false
      }
    }
    www = {
      name = "www.myapp.com"
      type = "A"
      alias = {
        name                   = "d1234567890.cloudfront.net"
        zone_id                = "Z2FDTNDATAQYW2"
        evaluate_target_health = false
      }
    }
  }
}
```

### Application Load Balancer Alias

```
module "api_example_com" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "api.example.com"

  records = {
    root = {
      name = "api.example.com"
      type = "A"
      alias = {
        name                   = "my-alb-1234567890.us-east-1.elb.amazonaws.com"
        zone_id                = "Z35SXDOTRQ7X7K"  # us-east-1 ALB zone ID
        evaluate_target_health = true
      }
    }
  }
}
```

### Weighted Routing (A/B Testing)

```
module "weighted_routing" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "example.com"

  records = {
    www_80_percent = {
      name           = "www.example.com"
      type           = "A"
      ttl            = 60
      records        = ["192.0.2.1"]
      set_identifier = "80-percent-traffic"
      weighted_routing_policy = {
        weight = 80
      }
    }
    www_20_percent = {
      name           = "www.example.com"
      type           = "A"
      ttl            = 60
      records        = ["192.0.2.2"]
      set_identifier = "20-percent-traffic"
      weighted_routing_policy = {
        weight = 20
      }
    }
  }
}
```

### Latency-Based Routing

```
module "latency_routing" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "example.com"

  records = {
    app_us_east = {
      name           = "app.example.com"
      type           = "A"
      ttl            = 60
      records        = ["192.0.2.1"]
      set_identifier = "us-east-1"
      latency_routing_policy = {
        region = "us-east-1"
      }
    }
    app_eu_west = {
      name           = "app.example.com"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.10"]
      set_identifier = "eu-west-1"
      latency_routing_policy = {
        region = "eu-west-1"
      }
    }
  }
}
```

### Failover Routing (Active-Passive)

```
module "failover_routing" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "example.com"

  records = {
    primary = {
      name            = "app.example.com"
      type            = "A"
      ttl             = 60
      records         = ["192.0.2.1"]
      set_identifier  = "primary"
      health_check_id = aws_route53_health_check.primary.id
      failover_routing_policy = {
        type = "PRIMARY"
      }
    }
    secondary = {
      name           = "app.example.com"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.10"]
      set_identifier = "secondary"
      failover_routing_policy = {
        type = "SECONDARY"
      }
    }
  }
}

resource "aws_route53_health_check" "primary" {
  ip_address        = "192.0.2.1"
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
}
```

### SES Email Domain Setup

```
module "email_domain" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "example.com"

  records = {
    mx = {
      name = "example.com"
      type = "MX"
      ttl  = 300
      records = [
        "10 inbound-smtp.us-east-1.amazonaws.com"
      ]
    }
    dkim1 = {
      name = "abc123._domainkey.example.com"
      type = "CNAME"
      ttl  = 1800
      records = ["abc123.dkim.amazonses.com"]
    }
    dkim2 = {
      name = "def456._domainkey.example.com"
      type = "CNAME"
      ttl  = 1800
      records = ["def456.dkim.amazonses.com"]
    }
    dkim3 = {
      name = "ghi789._domainkey.example.com"
      type = "CNAME"
      ttl  = 1800
      records = ["ghi789.dkim.amazonses.com"]
    }
    spf = {
      name = "example.com"
      type = "TXT"
      ttl  = 300
      records = ["v=spf1 include:amazonses.com ~all"]
    }
    dmarc = {
      name = "_dmarc.example.com"
      type = "TXT"
      ttl  = 300
      records = ["v=DMARC1; p=none;"]
    }
  }
}
```

### Private Hosted Zone (VPC)

```
module "internal_domain" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "internal.example.com"
  vpc_id      = "vpc-12345678"

  records = {
    db = {
      name = "db.internal.example.com"
      type = "A"
      ttl  = 300
      records = ["10.0.1.100"]
    }
    cache = {
      name = "cache.internal.example.com"
      type = "CNAME"
      ttl  = 300
      records = ["redis.internal.example.com"]
    }
  }
}
```

### Subdomain Delegation

```
module "subdomain_delegation" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//route53?ref=v1.3.0"

  domain_name = "example.com"

  records = {
    subdomain_ns = {
      name = "subdomain.example.com"
      type = "NS"
      ttl  = 172800
      records = [
        "ns-1.awsdns-00.com",
        "ns-2.awsdns-00.org",
        "ns-3.awsdns-00.net",
        "ns-4.awsdns-00.co.uk"
      ]
    }
  }
}
```

## Common AWS Service Zone IDs

| Service              | Zone ID        | Description           |
| -------------------- | -------------- | --------------------- |
| CloudFront           | Z2FDTNDATAQYW2 | Global                |
| S3 Website us-east-1 | Z3AQBSTGFYJSTF | US East (N. Virginia) |
| ALB us-east-1        | Z35SXDOTRQ7X7K | US East (N. Virginia) |
| ALB us-west-2        | Z1H1FL5HABSF5  | US West (Oregon)      |
| API Gateway          | -              | Use regional endpoint |

Find zone IDs:

```bash
aws elb describe-load-balancers --query 'LoadBalancerDescriptions[0].CanonicalHostedZoneNameID'
```

## Inputs

| Name          | Description                                               | Type        | Default | Required |
| ------------- | --------------------------------------------------------- | ----------- | ------- | -------- |
| domain_name   | Domain name for the hosted zone                           | string      | -       | yes      |
| force_destroy | Allow deletion of hosted zone even if it contains records | bool        | false   | no       |
| vpc_id        | VPC ID for private hosted zone (null for public)          | string      | null    | no       |
| records       | Map of DNS records to create                              | map(object) | {}      | no       |

## Outputs

| Name         | Description                       |
| ------------ | --------------------------------- |
| zone_id      | ID of the Route53 hosted zone     |
| zone_arn     | ARN of the Route53 hosted zone    |
| name_servers | Name servers for the hosted zone  |
| record_names | Map of record keys to their FQDNs |

## Notes

- When creating a new zone, update your domain registrar's name servers to the ones in the `name_servers` output
- Alias records don't support TTL (it's determined by the target resource)
- Private hosted zones require VPC association
- Health checks incur additional costs ($0.50/month per health check)
- Maximum 10,000 records per hosted zone
- DNS propagation can take up to 48 hours (usually much faster)

## Updating Name Servers

After creating a hosted zone, update your domain registrar:

```bash
# Get name servers
terraform output name_servers

# Update at your registrar (e.g., GoDaddy, Namecheap, etc.)
```

## Importing Existing Resources

```bash
# Import existing hosted zone
terraform import 'module.example_com.aws_route53_zone.zone' Z1234567890ABC

# Import existing record
terraform import 'module.example_com.aws_route53_record.records["www"]' Z1234567890ABC_www.example.com_A
```
