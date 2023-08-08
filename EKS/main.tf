
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.igw_name}"
  }
}

resource "aws_subnet" "subnets" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.subnet_cidr)
  cidr_block              = element(var.subnet_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name" = "EKS-Subnets-${count.index + 1}"
    "app"  = "EKS-Cluster-1"
  }
}

resource "aws_route_table" "EKS-RT" {
  count  = length(aws_subnet.subnets)
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "EKS-RT"
  }
}

resource "aws_route_table_association" "RT-subnets" {
  count          = length(aws_subnet.subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.EKS-RT[count.index].id
}

resource "aws_iam_role" "eks-role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}

resource "aws_security_group" "eks_sg" {
  name        = "EKS_SG"
  description = "Security group for EKS"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name     = "EKS-SG"
    Protocol = "All-TRAFFIC"
  }
}

resource "aws_eks_cluster" "Cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-role.arn

  vpc_config {
    subnet_ids         = aws_subnet.subnets.*.id
    security_group_ids = [aws_security_group.eks_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_security_group.eks_sg,
    aws_subnet.subnets
  ]
}

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_eks_node_group" "public-nodes" {
  cluster_name    = aws_eks_cluster.Cluster.name
  node_group_name = "Node-Group-1"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.subnets.*.id
  capacity_type   = "ON_DEMAND"
  instance_types  = [""]
  disk_size       = "30"

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  /*launch_template {
    name    = aws_launch_template.launch_template.name
    version = "$Latest"
  }*/

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly
  ]
}

/* Create launch template
resource "aws_launch_template" "launch_template" {
  name                   = "EKS-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.eks_sg.id]

  tags = {
    key   = "EKS_instance"
    value = "EKS"
  }
}
*/

# aws eks update-kubeconfig --name cluster-1

