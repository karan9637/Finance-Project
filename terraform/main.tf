provider "aws" {
  region = "ap-south-1"  # Change this to your AWS region
}

resource "aws_instance" "test_server" {
  ami           = "ami-0e35ddab05955cf57"  # Amazon Linux 2 AMI ID
  instance_type = "t2.micro"
  key_name      = "mykey"  # Replace with your AWS key pair name
  tags = {
    Name = "FinanceMe-Test-Server"
  }
}

resource "aws_instance" "prod_server" {
  ami           = "ami-0e35ddab05955cf57"
  instance_type = "t2.micro"
  key_name      = "mykey"
  tags = {
    Name = "FinanceMe-Prod-Server"
  }
}

output "test_server_ip" {
  value = aws_instance.test_server.public_ip
}

output "prod_server_ip" {
  value = aws_instance.prod_server.public_ip
}

