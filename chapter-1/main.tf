provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

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
  description = "The Public IP of Webserver"
  value       = aws_instance.my-first-instance.public_ip
}