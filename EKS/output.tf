output "vpc" {
  value = aws_vpc.vpc.id
}

output "private_subnets" {
  value = aws_subnet.subnets.*.id
}

output "igw" {
  value = aws_internet_gateway.igw.id
}

output "Route_Tables" {
  value = aws_route_table.EKS-RT.*.id
}

output "EKS-role-cluster" {
  value = aws_iam_role.eks-role.arn
}

output "EKS-role-Node" {
  value = aws_iam_role.nodes.arn
}

output "cluster-name" {
  value = aws_eks_cluster.Cluster.name
}

output "Node-Group-name" {
  value = aws_eks_node_group.public-nodes.node_group_name
}

