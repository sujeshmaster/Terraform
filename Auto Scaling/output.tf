
output "vpc" {
  value = aws_vpc.dev_vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}

output "dev_igw" {
  value = aws_internet_gateway.dev_igw.id
}

output "public_RT" {
  value = aws_route_table.public_RT.*.id
}

output "private_RT" {
  value = aws_route_table.private_RT.*.id
}

output "nat_eip" {
  value = aws_eip.nat_eip.address
}

output "nat_gateway" {
  value = aws_nat_gateway.nat_gateway.id
}

output "SNS-role-ARN" {
  value = aws_iam_role.sns_role.arn
}

output "Load_Balancer_name" {
  value = aws_lb.my_lb.dns_name
}

output "Target_group" {
  value = aws_lb_target_group.public_target_group.arn
}

