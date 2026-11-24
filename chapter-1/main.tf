provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "my-first-instance" {
    ami = "ami-0d00ab3a044f7f788"
    instance_type = "t2.micro"
    tags = {
        Name = "Example-Terraform"

    }
}