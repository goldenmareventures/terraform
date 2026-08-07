# vpc/endpoints.tf
# Gateway endpoints keep S3 and DynamoDB traffic off the NAT gateway. Per-GB NAT
# processing is where most of a NAT bill comes from, and these endpoints are free.

# The data source builds the service name for the current region and partition.
data "aws_vpc_endpoint_service" "gateway" {
  for_each = toset(var.gateway_endpoints)

  service      = each.value
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(var.gateway_endpoints)

  vpc_id            = aws_vpc.vpc.id
  service_name      = data.aws_vpc_endpoint_service.gateway[each.key].service_name
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.public[*].id,
    [for rt in aws_route_table.private : rt.id],
  )

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}
