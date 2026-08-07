# vpc/main.tf
locals {
  # An internet gateway is only useful when something public exists.
  create_igw = length(var.public_subnets) > 0

  public_subnet_keys = sort(keys(var.public_subnets))

  # NAT gateways always live in a public subnet. "single" uses the first one.
  nat_subnet_keys = local.create_igw ? (
    var.nat_gateway_mode == "per_az" ? local.public_subnet_keys :
    var.nat_gateway_mode == "single" ? slice(local.public_subnet_keys, 0, 1) :
    []
  ) : []

  # AZ -> NAT gateway id. Grouped so two public subnets in one AZ do not collide.
  nat_by_az = {
    for az, ids in {
      for k in local.nat_subnet_keys :
      var.public_subnets[k].availability_zone => aws_nat_gateway.nat[k].id...
    } : az => ids[0]
  }

  first_nat_id = length(local.nat_subnet_keys) > 0 ? aws_nat_gateway.nat[local.nat_subnet_keys[0]].id : null

  # Private subnet key -> NAT gateway id. A NAT in the same AZ is preferred,
  # because cross-AZ NAT traffic is billed twice.
  private_subnet_nat = length(local.nat_subnet_keys) == 0 ? {} : {
    for k, v in var.private_subnets :
    k => lookup(local.nat_by_az, v.availability_zone, local.first_nat_id)
    if v.route_to_nat
  }
}

resource "aws_vpc" "vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = var.instance_tenancy

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "igw" {
  count = local.create_igw ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = var.name })
}

# The default security group allows everything inside it to talk to everything
# else inside it. Emptying the rules forces each resource onto a group that was
# written on purpose. The group itself cannot be deleted by AWS.
resource "aws_default_security_group" "default" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "${var.name}-default" })
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.name, "${var.name}-public-${each.key}")
  })
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(var.tags, each.value.tags, {
    Name = coalesce(each.value.name, "${var.name}-private-${each.key}")
  })
}
