# vpc/README.md

# VPC Module

Terraform module for an AWS VPC with public and private subnets, internet and NAT
gateways, route tables, gateway endpoints, and flow logs.

Subnets are declared as maps keyed by a short name, not as lists. A map key is stable,
so adding or removing a subnet never renumbers and destroys the others.

## Features

- Public and private subnets in any number of availability zones
- NAT gateways: none, one shared, or one per availability zone
- Isolated private subnets with no route to the internet, for a database tier
- S3 and DynamoDB gateway endpoints, attached to every route table
- Flow logs to CloudWatch Logs (log group and role created for you) or to S3
- Default security group emptied of all rules

## Usage

### Public and private subnets with one NAT gateway

The common layout. One NAT gateway is the cheapest option that still gives private
subnets outbound internet access.

```terraform
module "vpc" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//vpc?ref=v1.1.0"

  name       = "app-prod"
  cidr_block = "10.0.0.0/16"

  public_subnets = {
    a = { cidr_block = "10.0.0.0/24", availability_zone = "us-east-1a" }
    b = { cidr_block = "10.0.1.0/24", availability_zone = "us-east-1b" }
  }

  private_subnets = {
    a = { cidr_block = "10.0.10.0/24", availability_zone = "us-east-1a" }
    b = { cidr_block = "10.0.11.0/24", availability_zone = "us-east-1b" }
  }

  nat_gateway_mode  = "single"
  gateway_endpoints = ["s3"]

  tags = local.tags
}
```

### Three tiers with an isolated database subnet

`route_to_nat = false` removes the default route from that subnet. The subnet still
reaches S3 and DynamoDB through the gateway endpoints.

```terraform
module "vpc" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//vpc?ref=v1.1.0"

  name       = "app-prod"
  cidr_block = "10.0.0.0/16"

  public_subnets = {
    a = { cidr_block = "10.0.0.0/24", availability_zone = "us-east-1a" }
    b = { cidr_block = "10.0.1.0/24", availability_zone = "us-east-1b" }
  }

  private_subnets = {
    app-a = { cidr_block = "10.0.10.0/24", availability_zone = "us-east-1a" }
    app-b = { cidr_block = "10.0.11.0/24", availability_zone = "us-east-1b" }
    db-a  = { cidr_block = "10.0.20.0/24", availability_zone = "us-east-1a", route_to_nat = false }
    db-b  = { cidr_block = "10.0.21.0/24", availability_zone = "us-east-1b", route_to_nat = false }
  }

  # One NAT per AZ. Costs more, but an AZ failure does not take out the other AZ.
  nat_gateway_mode  = "per_az"
  gateway_endpoints = ["s3", "dynamodb"]

  tags = local.tags
}
```

### Public subnets only

Leave `nat_gateway_mode` at its default of `none` when nothing private needs outbound
access. No NAT gateway and no elastic IP are created.

```terraform
module "vpc" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//vpc?ref=v1.1.0"

  name       = "sandbox"
  cidr_block = "10.20.0.0/16"

  public_subnets = {
    a = { cidr_block = "10.20.0.0/24", availability_zone = "us-east-1a" }
  }

  tags = local.tags
}
```

### Flow logs

To CloudWatch Logs. The module creates the log group `/aws/vpc/<name>` and the
delivery role.

```terraform
  flow_log = {
    retention_in_days = 14
    traffic_type      = "REJECT"
  }
```

To an existing S3 bucket. No role is created; S3 delivery uses a service principal.

```terraform
  flow_log = {
    destination_type = "s3"
    s3_bucket_arn    = module.log_bucket.bucket_arn
  }
```

### Feeding other modules

```terraform
module "db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds-aurora?ref=v1.1.0"

  cluster_identifier = "app-prod"
  subnet_ids         = [module.vpc.private_subnet_ids_by_key["db-a"], module.vpc.private_subnet_ids_by_key["db-b"]]
  # ...
}

resource "aws_security_group" "app" {
  vpc_id = module.vpc.vpc_id
  # ...
}
```

## Inputs

| Name                             | Description                                           | Type           | Default     | Required |
| -------------------------------- | ----------------------------------------------------- | -------------- | ----------- | :------: |
| name                             | VPC name. Also the prefix for every created resource. | `string`       | n/a         |   yes    |
| cidr_block                       | IPv4 CIDR block for the VPC                           | `string`       | n/a         |   yes    |
| instance_tenancy                 | `default` or `dedicated`                              | `string`       | `"default"` |    no    |
| enable_dns_support               | Enable DNS resolution                                 | `bool`         | `true`      |    no    |
| enable_dns_hostnames             | Assign DNS hostnames. RDS requires this.              | `bool`         | `true`      |    no    |
| assign_generated_ipv6_cidr_block | Request an Amazon-provided IPv6 /56                   | `bool`         | `false`     |    no    |
| manage_default_security_group    | Remove all rules from the default security group      | `bool`         | `true`      |    no    |
| public_subnets                   | Public subnets keyed by short name                    | `map(object)`  | `{}`        |    no    |
| private_subnets                  | Private subnets keyed by short name                   | `map(object)`  | `{}`        |    no    |
| nat_gateway_mode                 | `none`, `single`, or `per_az`                         | `string`       | `"none"`    |    no    |
| gateway_endpoints                | Gateway endpoints to create: `s3`, `dynamodb`         | `list(string)` | `[]`        |    no    |
| flow_log                         | Flow log configuration, or null                       | `object`       | `null`      |    no    |
| tags                             | Tags applied to every resource                        | `map(string)`  | `{}`        |    no    |

### Public subnet object

| Field                   | Type          | Default                   | Description                     |
| ----------------------- | ------------- | ------------------------- | ------------------------------- |
| cidr_block              | `string`      | required                  | CIDR block of the subnet        |
| availability_zone       | `string`      | required                  | Full AZ name, e.g. `us-east-1a` |
| map_public_ip_on_launch | `bool`        | `true`                    | Give instances a public IP      |
| name                    | `string`      | `<vpc name>-public-<key>` | Name tag override               |
| tags                    | `map(string)` | `{}`                      | Extra tags for this subnet      |

### Private subnet object

| Field             | Type          | Default                    | Description                          |
| ----------------- | ------------- | -------------------------- | ------------------------------------ |
| cidr_block        | `string`      | required                   | CIDR block of the subnet             |
| availability_zone | `string`      | required                   | Full AZ name, e.g. `us-east-1a`      |
| route_to_nat      | `bool`        | `true`                     | Add a default route to a NAT gateway |
| name              | `string`      | `<vpc name>-private-<key>` | Name tag override                    |
| tags              | `map(string)` | `{}`                       | Extra tags for this subnet           |

### Flow log object

| Field                    | Type     | Default              | Description                            |
| ------------------------ | -------- | -------------------- | -------------------------------------- |
| destination_type         | `string` | `"cloud-watch-logs"` | `cloud-watch-logs` or `s3`             |
| s3_bucket_arn            | `string` | `null`               | Required when destination_type is `s3` |
| retention_in_days        | `number` | `30`                 | Log group retention                    |
| kms_key_arn              | `string` | `null`               | KMS key for the log group              |
| traffic_type             | `string` | `"ALL"`              | `ACCEPT`, `REJECT`, or `ALL`           |
| max_aggregation_interval | `number` | `600`                | Seconds per aggregation window         |

## Outputs

| Name                           | Description                                |
| ------------------------------ | ------------------------------------------ |
| vpc_id                         | ID of the VPC                              |
| vpc_arn                        | ARN of the VPC                             |
| vpc_cidr_block                 | IPv4 CIDR block                            |
| vpc_ipv6_cidr_block            | IPv6 CIDR block, when requested            |
| default_security_group_id      | ID of the default security group           |
| internet_gateway_id            | ID of the internet gateway, or null        |
| public_subnet_ids              | List of public subnet IDs, ordered by key  |
| private_subnet_ids             | List of private subnet IDs, ordered by key |
| public_subnet_ids_by_key       | Map of key to public subnet ID             |
| private_subnet_ids_by_key      | Map of key to private subnet ID            |
| public_route_table_id          | ID of the shared public route table        |
| private_route_table_ids_by_key | Map of key to private route table ID       |
| nat_gateway_ids                | Map of public subnet key to NAT gateway ID |
| nat_public_ips                 | Public IPs of the NAT gateways             |
| gateway_endpoint_ids           | Map of service name to endpoint ID         |
| flow_log_group_name            | Name of the created flow log group         |

## Notes

### NAT gateway cost

A NAT gateway costs about $32 per month plus a per-GB data charge, per gateway.
`single` is the right default for most environments. Use `per_az` when an AZ outage
must not remove outbound access for the other AZs.

Private traffic is routed to a NAT gateway in the same AZ when one exists. Cross-AZ
NAT traffic is billed for the transfer and for the NAT processing, so keeping it in
one AZ matters. If a private subnet is in an AZ with no NAT gateway, it uses the
first NAT gateway.

### Route tables

Public subnets share one route table. Each private subnet gets its own, so subnets in
the same VPC can point at different NAT gateways or at none. Add extra routes, such
as a VPC peering or transit gateway route, outside the module using
`private_route_table_ids_by_key` and `public_route_table_id`.

### Gateway endpoints

Gateway endpoints are free and cut NAT data charges for S3 and DynamoDB traffic. They
are attached to every route table in the VPC, including isolated private subnets.
Only S3 and DynamoDB are available as gateway endpoints.

### Interface endpoints

Not included. An interface endpoint needs its own security group, which this module
does not create. Declare `aws_vpc_endpoint` resources alongside the module and pass
`module.vpc.private_subnet_ids`.

### Default security group

`manage_default_security_group = true` puts the default security group under
Terraform control and removes every rule from it. AWS does not allow the group to be
deleted. Set this to `false` if existing resources depend on its default rules.
