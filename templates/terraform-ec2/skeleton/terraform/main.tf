terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Terraform State를 S3에 저장하려면 아래 주석을 해제하고 설정하세요
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "${{ values.name }}/terraform.tfstate"
  #   region         = "${{ values.region }}"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC (간단한 데모용)
data "aws_vpc" "default" {
  default = true
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "${{ values.name }}-sg"
  description = "Security group for ${{ values.name }} EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH 접근 (필요한 경우 소스 IP를 제한하세요)
  ingress {
    description = "SSH from anywhere (보안을 위해 특정 IP로 제한하는 것을 권장합니다)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP 접근
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS 접근
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${{ values.name }}-sg"
    ManagedBy   = "Terraform"
    Project     = "${{ values.name }}"
    Owner       = "${{ values.owner }}"
    Environment = "production"
  }
}

# EC2 Instance
resource "aws_instance" "main" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = var.enable_public_ip

  # User data script for initial setup
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from ${{ values.name }}</h1>" > /var/www/html/index.html
              echo "<p>Instance managed by Terraform and Backstage</p>" >> /var/www/html/index.html
              EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${{ values.name }}-root-volume"
    }
  }

  tags = {
    Name        = var.instance_name
    ManagedBy   = "Terraform"
    Project     = "${{ values.name }}"
    Owner       = "${{ values.owner }}"
    Environment = "production"
    CreatedBy   = "Backstage"
  }

  lifecycle {
    create_before_destroy = true
  }
}
