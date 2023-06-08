#Terraform Local Variables
locals {
  vpc_id           = "vpc-0548d408bf3549ca0"
  subnet_id        = "subnet-060a1ae52cf0a73d6"
  ssh_user         = "ubuntu"
  key_name         = "bb-key"
 
}

provider "aws" {
  region = "eu-north-1"
}


#AWS Security Group with Terraform
resource "aws_security_group" "nginx" {
  name   = "nginx_access"
  vpc_id = local.vpc_id

#ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

##verify nginx is running
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# outbound rule
  egress {
    from_port   = 0  ## all ports
    to_port     = 0
    protocol    = "-1"  # all protpcols
    cidr_blocks = ["0.0.0.0/0"] ## all ip addresses
  }
}

#Terraform AWS Instance Resource

resource "aws_instance" "nginx" {
  ami                         = "ami-0989fb15ce71ba39e" #Ubuntu Server 22.04 LTS
  subnet_id                   = local.subnet_id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.nginx.id]
  key_name                    = local.key_name

  tags = {
    Name = "Frontend-Hoisin Duch Wrap Terraform "
  }

## TO make ssh ready to accept connections
  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      host        = aws_instance.nginx.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.nginx.public_ip}, playbook-nginx.yaml"
  }
}

#give the ip address where we can go
output "nginx_ip" {
  value = aws_instance.nginx.public_ip
}
