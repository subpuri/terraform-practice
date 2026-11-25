provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

/*
resource "aws_instance" "my-first-instance" {
  ami                         = "ami-0d00ab3a044f7f788"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.instance.id]
  user_data                   = <<-EOF
                                #!/bin/bash
                                echo "Hello world from Terraform AWS!" >> index.html
                                nohup python3 -m http.server "${var.server_port}" &
                                EOF
  user_data_replace_on_change = true
  tags = {
    Name = "Example-Terraform"

  }
}
*/

resource "aws_lb" "example_lb" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default_subnets.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-exapmle-alb"

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

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
resource "aws_launch_template" "example" {
  name_prefix            = "terraform-asg-example-"
  image_id               = "ami-0d00ab3a044f7f788"
  instance_type          = "t2.micro"
  #vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello world from Terraform AWS!" > index.html
              nohup python3 -m http.server ${var.server_port} &
              EOF
  )
}

resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default_subnets.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"
  min_size            = 2
  max_size            = 10

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip_of_webserver" {
  description = "The domain name of aws lb"
  value       = aws_lb.example_lb.dns_name

}