# vpc/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.vpc.arn
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR block of the VPC, when one was requested"
  value       = aws_vpc.vpc.ipv6_cidr_block
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.vpc.default_security_group_id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway, or null when there are no public subnets"
  value       = one(aws_internet_gateway.igw[*].id)
}

output "public_subnet_ids" {
  description = "List of public subnet IDs, ordered by key"
  value       = [for k in local.public_subnet_keys : aws_subnet.public[k].id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs, ordered by key"
  value       = [for k in sort(keys(var.private_subnets)) : aws_subnet.private[k].id]
}

output "public_subnet_ids_by_key" {
  description = "Map of public subnet key to subnet ID"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids_by_key" {
  description = "Map of private subnet key to subnet ID"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "public_route_table_id" {
  description = "ID of the shared public route table, or null when there are no public subnets"
  value       = one(aws_route_table.public[*].id)
}

output "private_route_table_ids_by_key" {
  description = "Map of private subnet key to the ID of that subnet's route table"
  value       = { for k, v in aws_route_table.private : k => v.id }
}

output "nat_gateway_ids" {
  description = "Map of public subnet key to NAT gateway ID"
  value       = { for k, v in aws_nat_gateway.nat : k => v.id }
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways. Use these when a third party must allow-list outbound traffic."
  value       = [for k in local.nat_subnet_keys : aws_eip.nat[k].public_ip]
}

output "gateway_endpoint_ids" {
  description = "Map of gateway endpoint service name to endpoint ID"
  value       = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
}

output "flow_log_group_name" {
  description = "Name of the flow log CloudWatch log group, when the module created one"
  value       = one(aws_cloudwatch_log_group.flow_log[*].name)
}
