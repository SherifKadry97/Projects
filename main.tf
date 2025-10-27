# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Terraform-VPC"
  }
}

# Create a public subnet within the vpc for the NAT GW
resource "aws_subnet" "public_subnet_a" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_cidrs["public_a"]
  availability_zone = var.azs["public_a"]
  map_public_ip_on_launch = true
  tags = {
    Name = "Terraform Public Subnet a"
  }
}


 
resource "aws_subnet" "public_subnet_b" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_cidrs["public_b"]
  availability_zone = var.azs["public_b"]
  map_public_ip_on_launch = true
  tags = {
    Name = "Terraform Public Subnet b"
  }
}
 
# Create a private subnets within the vpc for the ASG EC2 instances
resource "aws_subnet" "private_subnet_a" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = var.private_subnet_cidrs["private_a"]
  availability_zone = var.azs["private_a"]
  tags = {
    Name = " Terraform Private Subnet a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = var.private_subnet_cidrs["private_b"]
  availability_zone = var.azs["private_b"]
  tags = {
    Name = " Terraform Private Subnet b"
  }
}

# Allocate EIP for the NAT GW in both subnets
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-a"
  }
}

resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  tags = {
    Name = "nat-eip-b"
  }
}

# Create Two NAT GW per Public subnet for HA
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id = aws_subnet.public_subnet_a.id 
  tags = {
    Name = "nat-gateway-a"
  }
}

resource "aws_nat_gateway" "nat_gw_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id = aws_subnet.public_subnet_b.id
  tags = {
    Name = "nat-gateway-b"
  }
}

# Create a Private route table that routes to the NAT GW for both subnets
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }
  tags = {
    Name = "private-rt-a"
  }
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_b.id
  }
  tags = {
    Name = "private-rt-b"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

# Associate the public subnets with the public Route Table
resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate the private subnets with the private Route Table
resource "aws_route_table_association" "private_assoc_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_assoc_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

# Create an IGW to attach it to the VPC for internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "Terraform IGW"
  }
}

# Security group allowing HTTP + SSH
resource "aws_security_group" "web_sg" {
  name = "web-sg"
  description = "Allow web and SSH"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web Security Group"
  }
}

resource "aws_security_group" "asg_sg" {
    name = "asg-sg"
    vpc_id = aws_vpc.main_vpc.id
    
    # Allow any traffic from the ALB
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.web_alb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "ASG SG" }
}

# Launch Template
resource "aws_launch_template" "web_lt" {
  name_prefix = "private-web-lt-terraform"
  image_id = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF
            )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-server-terraform"
    }
  }
}

resource "aws_alb_target_group" "alb-target-group" {
  name = "web-tg-terraform"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main_vpc.id
  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.web-alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-target-group.arn
  }
}


resource "aws_autoscaling_group" "web_asg" {
  name = "web-asg-terraform"
  launch_template {
    id = aws_launch_template.web_lt.id
    version = "$Latest"
  }
  min_size = var.asg_min_size
  max_size = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  vpc_zone_identifier = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
  target_group_arns = [aws_alb_target_group.alb-target-group.arn]
  health_check_type = "EC2"
  health_check_grace_period = 300
  tag {
    key = "Name"
    value = "web-server-asg-terraform"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "web_alb_sg" {
  name = "alb_sg-terraform"
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "web-alb" {
    name = "web-alb-terraform"
    load_balancer_type = "application"
    subnets = [
        aws_subnet.public_subnet_a.id,
        aws_subnet.public_subnet_b.id
        ]
    security_groups = [aws_security_group.web_alb_sg.id]
}