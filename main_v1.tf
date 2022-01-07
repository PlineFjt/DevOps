provider "aws" {
  region = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  }

resource "aws_key_pair" "admin" {
  key_name = "admin"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDM6MZw9Nvc+tlE55klRkQHGBtTqv8M0Bd1dvqyyy2Dnly+MEMWv372/wozwZtFxvEOhLYI77I2lCAxxsUuC+8crwLZHlE/BCAgXWkghr3qGOEhYskOX2Ey70TmDfXnzVSrzwEekTLt4RBqDCPeWytvXX6fzu9qkPBqSxZH0TJcyb49bfdbjeEutrGsaFNjG78U4V5Fqq1+85ZJqnFS6gzdrTqMoD1io0MAOZ54A9lK/pjVTO68UV8RmbX6lRGU4VL0zozmIQ3nUdOdv8Ax+d09/LENCK+s2eFchmGZkAKFdxgzFLE7AFQsP4hrf5U6SVFBgDSloOQHOlOBSv6gIJxmx9n8tfuLquWRg2PS9jMT0ABwnRWRT1JrJKsj3jdT1cCy/2l3uaPCsORkY1aG0RbWbOz5vcVVrpR2X9PGf0vGyTzk5Fp/OHcKcuTl2HAjOYSgiMIkZrQpHDZCkijhBHGmcVWw/K5DOWnz4ucZrJSrB/AMViFhFkviaa24MW2fpeU= root@ip-172-31-29-92"
}

resource "aws_security_group" "monSGPline"{
  name = "ssh"
  description = " accepte connexion entrante SSH"
  vpc_id = "vpc-6fc66804"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
}
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
 }
}

resource "aws_instance" "ec2_terrapline" {
  ami = "ami-002068ed284fb165b"
  instance_type = "t2.micro"
  key_name = "id_rsa"
  provisioner "local-exec" {
    command = "echo ${aws_instance.ec2_terrapline.public_ip} > /root/ip_adress.txt"
    }
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("/root/.ssh/id_rsa")
      host = self.public_ip
    }

    provisioner "remote-exec" {
      inline =[
        "sudo yum update -y",
        "sudo yum install mariadb-server -y",
        "sudo systemctl start mariadb",
        " sudo systemctl enable mariadb",
    ]
    }

    provisioner "file" {
      source = "test.pline"
      destination = "/tmp/test.pline"
    }

      vpc_security_group_ids = [aws_security_group.monSGPline.id]
      user_data = <<-EOF
      #!/bin/bash
      echo "*** Installing apache2"
      sudo yum update -y
      sudo yum install httpd -y
      echo "*** Completed Installing apache2"
      EOF
      tags = {
        Name = "pline_terraF7"
     }
    }

    terraform {
    backend "s3" {
        bucket = "my-bucket-pline"
        key = "states/terraform.state"
        region = "us-east-2"
    }
    }
    output "public_ip" {
      value = aws_instance.ec2_terrapline.public_ip
    }
