# vpc/routing.tf
resource "aws_eip" "nat" {
  for_each = toset(local.nat_subnet_keys)

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each = toset(local.nat_subnet_keys)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })

  # The gateway cannot reach the internet until the gateway is attached.
  depends_on = [aws_internet_gateway.igw]
}

# One shared route table for every public subnet. They all need the same route.
resource "aws_route_table" "public" {
  count = local.create_igw ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_internet" {
  count = local.create_igw ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# One route table per private subnet, so a subnet can point at a NAT gateway in
# its own AZ, or at no NAT at all.
resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "${var.name}-private-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each = local.private_subnet_nat

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
