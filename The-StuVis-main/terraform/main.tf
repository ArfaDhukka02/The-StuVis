terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}


# VPC & Networking------------------------------


resource "aws_vpc" "stuvis_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "stuvis-vpc"
    Project = "StuVis"
  }
}

resource "aws_internet_gateway" "stuvis_igw" {
  vpc_id = aws_vpc.stuvis_vpc.id

  tags = {
    Name    = "stuvis-igw"
    Project = "StuVis"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.stuvis_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "stuvis-public-subnet"
    Project = "StuVis"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.stuvis_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name    = "stuvis-private-subnet-a"
    Project = "StuVis"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.stuvis_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name    = "stuvis-private-subnet-b"
    Project = "StuVis"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.stuvis_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.stuvis_igw.id
  }

  tags = {
    Name    = "stuvis-public-rt"
    Project = "StuVis"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# Security Groups---------------------------------


resource "aws_security_group" "ec2_sg" {
  name        = "stuvis-ec2-sg"
  description = "Allow HTTP, HTTPS, and SSH inbound traffic to EC2"
  vpc_id      = aws_vpc.stuvis_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port (NGINX)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }

  egress {
    from_port   = 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "stuvis-ec2-sg"
    Project = "StuVis"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "stuvis-rds-sg"
  description = "Allow MySQL access from EC2 only"
  vpc_id      = aws_vpc.stuvis_vpc.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "stuvis-rds-sg"
    Project = "StuVis"
  }
}

# EC2 Instance---------------------------------------


resource "aws_key_pair" "stuvis_key" {
  key_name   = "stuvis-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "stuvis_ec2" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.stuvis_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose-plugin git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu
  EOF

  tags = {
    Name    = "stuvis-ec2"
    Project = "StuVis"
  }
}


# RDS (MySQL) — -----------------------------replaces containerized DB


resource "aws_db_subnet_group" "stuvis_db_subnet" {
  name       = "stuvis-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "stuvis-db-subnet-group"
    Project = "StuVis"
  }
}

resource "aws_db_instance" "stuvis_rds" {
  identifier             = "stuvis-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.stuvis_db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name    = "stuvis-rds"
    Project = "StuVis"
  }
}
