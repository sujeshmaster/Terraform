
# Create security groups for load balancer
resource "aws_security_group" "lb_sg" {
  name        = "${var.LB_security_group}"
  description = "Security group for load balancer"

  vpc_id = aws_vpc.dev_vpc.id

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
}

# Create security groups for public subnets
resource "aws_security_group" "dev_public_sg" {
  name        = "${var.public_SG}"
  description = "Security group for public instances"

  vpc_id = aws_vpc.dev_vpc.id

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
}

# Create security groups for private subnets
resource "aws_security_group" "dev_private_sg" {
  name        = "${var.private_SG}"
  description = "Security group for private instances"

  vpc_id = aws_vpc.dev_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.dev_public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create load balancer
resource "aws_lb" "my_lb" {
  name               = "${var.Load_Balancer_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public_subnets.*.id

  enable_deletion_protection = false

  tags = {
    Name = "my-dev-lb"
  }
}

# Create public target group for load balancer
resource "aws_lb_target_group" "public_target_group" {
  name     = "${var.target_group_name[0]}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dev_vpc.id

  health_check {
    path = "/"
  }
}

# Create private target group for load balancer
resource "aws_lb_target_group" "private_target_group" {
  name     = "${var.target_group_name[1]}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.dev_vpc.id


  health_check {
    path = "/"
  }
}

# Create listeners for default
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.public_target_group.arn
    type             = "forward"
  }
}

# Create listeners rules
resource "aws_lb_listener_rule" "app1" {
  listener_arn = aws_lb_listener.listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_target_group.arn
  }

  condition {
    path_pattern {
      values = ["${var.listener_path[1]}"]
    }
  }
}

resource "aws_lb_listener_rule" "app2" {
  listener_arn = aws_lb_listener.listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_target_group.arn
  }

  condition {
    path_pattern {
      values = ["${var.listener_path[1]}"]
    }
  }
}



# Create launch template
resource "aws_launch_template" "public_launch_template" {
  name                   = "public-launch-template"
  image_id               = "${var.ami_id}" # Replace with the desired AMI ID
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_pair}" # Replace with your key pair name
  user_data              = file("${var.Front_user_data}")
  vpc_security_group_ids = [aws_security_group.dev_public_sg.id]

  tags = {
    key   = "${var.environment}-public_instance"
    tier  = "front-end"
    value = "app1"
  }
}


resource "aws_launch_template" "private_launch_template" {
  name                   = "private-launch-template"
  image_id               = "${var.ami_id}" # Replace with the desired AMI ID
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_pair}" # Replace with your key pair name
  user_data              = file("${var.Back_user_data}")
  vpc_security_group_ids = [aws_security_group.dev_private_sg.id]

  tags = {
    Name = "${var.environment}-private_instance"
    tier = "back-end"
    value = "app1"
  }
}

# Create auto scaling group for public instances
resource "aws_autoscaling_group" "dev_public_asg" {
  name                      = "public-dev-sg"
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  health_check_type         = "ELB"
  health_check_grace_period = 200
  lifecycle {
    create_before_destroy = true
  }
  launch_template {
    id      = aws_launch_template.public_launch_template.id
    version = "$Latest"
  }
  target_group_arns   = [aws_lb_target_group.public_target_group.arn]
  vpc_zone_identifier = aws_subnet.public_subnets.*.id
}

# Create auto scaling group for private instances
resource "aws_autoscaling_group" "dev_private_asg" {
  name                      = "private-dev-sg"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 200
  lifecycle {
    create_before_destroy = true
  }
  launch_template {
    id      = aws_launch_template.private_launch_template.id
    version = aws_launch_template.private_launch_template.latest_version
  }
  target_group_arns   = [aws_lb_target_group.private_target_group.arn]
  vpc_zone_identifier = aws_subnet.private_subnets.*.id

  depends_on = [
    aws_iam_role.sns_role,
    aws_sns_topic.my_topic
    ]
}


# Autoscaling Group Scaling Policy
resource "aws_autoscaling_policy" "public_scaling_policy" {
  name                      = "my-scaling-policy"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60
  autoscaling_group_name    = aws_autoscaling_group.dev_public_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}

resource "aws_autoscaling_policy" "private_scaling_policy" {
  name                      = "my-scaling-policy"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60
  autoscaling_group_name    = aws_autoscaling_group.dev_private_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}

# Create autoscalling notification using SNS
resource "aws_autoscaling_notification" "notifications" {
  group_names = [
    aws_autoscaling_group.dev_public_asg.name,
    aws_autoscaling_group.dev_private_asg.name,
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.my_topic.arn
}
