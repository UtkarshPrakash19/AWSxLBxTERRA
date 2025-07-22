provider "aws" {
  region = "ap-south-1" # Mumbai
}

resource "aws_instance" "web1" {
  ami           = "ami-0a1235697f4afa8a4"
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y git httpd
              git clone https://github.com/UtkarshPrakash19/StaticSite1.git /var/www/html
              sudo systemctl start httpd
              sudo systemctl enable httpd
            EOF
  tags = {
    Name = "web1"
  }
}

resource "aws_instance" "web2" {
  ami           = "ami-0a1235697f4afa8a4"
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y git httpd
              git clone https://github.com/UtkarshPrakash19/StaticSite2.git /var/www/html
              sudo systemctl start httpd
              sudo systemctl enable httpd
            EOF
  tags = {
    Name = "web2"
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "my_tg" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web1_attach" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2_attach" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}

# Networking Resources:
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "load_balancer_url" {
  description = "URL to access your application via ALB"
  value       = aws_lb.my_alb.dns_name
}
