provider "aws" {
  region = "ap-southeast-2"  # Replace with your desired AWS region
}

# security group
resource "aws_security_group" "master" {
  vpc_id = "vpc-037bb0f818ac28dd4"

# port 22 for ssh conection
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# port 3306 for db connection
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# open to all
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # "-1" represents all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "master-key-gen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair of kali linux didnt have software
resource "aws_key_pair" "master-key-pair" {
  key_name   = var.keypair_name 
  public_key = tls_private_key.master-key-gen.public_key_openssh
}

# Kali rdp
resource "aws_instance" "ubuntu" {
  ami           = "ami-0a709bebf4fa9246f"  # Replace with your desired AMI ID
  instance_type = "t3a.2xlarge"  # Replace with your desired instance type
  key_name      = aws_key_pair.master-key-pair.key_name
  subnet_id = "subnet-0efcd69ffcb1943d8"
  availability_zone = "ap-south-1b"
  
  security_groups = [aws_security_group.master.id]
  
  tags = {
    Name = var.instance_name1
  }
  user_data = <<-EOF
    #!/bin/bash
    cd /home/kali
    sudo chmod +x xfce.sh
    sudo ./xfce.sh
    sudo apt install -y dbus-x11
    sudo systemctl enable xrdp --now
    echo 'kali:kali' | sudo chpasswd
  EOF
}

# amazonlinux
resource "aws_instance" "amazonlinux" {
  ami           = "ami-0a709bebf4fa9246f"  # Replace with your desired AMI ID
  instance_type = "t3a.small"  # Replace with your desired instance type
  key_name      = aws_key_pair.master-key-pair.key_name
  subnet_id = "subnet-0efcd69ffcb1943d8"
  availability_zone = "ap-south-1b"

  security_groups = [aws_security_group.master.id]
  
  tags = {
    Name = var.instance_name2
  }
}

# Basic Pentesting (marlinspike)
resource "aws_instance" "redhat" {
  ami           = "ami-0d5c8edc10c17ec35"  # Replace with your desired AMI ID
  instance_type = "t3a.small"  # Replace with your desired instance type
  key_name      = aws_key_pair.master-key-pair.key_name
  subnet_id = "subnet-0efcd69ffcb1943d8"
  availability_zone = "ap-south-1b"

  security_groups = [aws_security_group.master.id]
  
  tags = {
    Name = var.instance_name4
  }
}

resource "local_file" "local_key_pair" {
  filename = "${var.keypair_name}.pem"
  file_permission = "0400"
  content = tls_private_key.master-key-gen.private_key_pem
}

output "pem_file_for_ssh" {
  value = tls_private_key.master-key-gen.private_key_pem
  sensitive = true
}

output "ubuntu" {
  value = aws_instance.ubuntu.private_ip
}

output "amazonlinux" {
  value = aws_instance.amazonlinux.private_ip
}

output "redhat" {
  value = aws_instance.redhat.private_ip
}

output "note" {
  value = "If unable to perform ssh please wait for sometime \n and try again. \nssh -i path-of-pemfile.pem -N -L 3390:127.0.0.1:3390 kali@[kali_server ip] \n Now connect rdp with 127.0.0.1:3390"
}


