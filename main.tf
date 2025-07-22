provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "web1" {
  ami                    = "ami-0a1235697f4afa8a4"
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.lb_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              curl -o /var/www/html/index.html https://raw.githubusercontent.com/UtkarshPrakash19/AWSxLBxTERRA/main/webpage101.html
              EOF

  tags = {
    Name = "WebServer1"
  }
}

resource "aws_instance" "web2" {
  ami                    = "ami-0a1235697f4afa8a4"
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.lb_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              curl -o /var/www/html/index.html https://raw.githubusercontent.com/UtkarshPrakash19/AWSxLBxTERRA/main/webpage102.html
              EOF

  tags = {
    Name = "WebServer2"
  }
}

resource "aws_lb" "my_lb" {
  name               = "my-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-simple"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "web1_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}
