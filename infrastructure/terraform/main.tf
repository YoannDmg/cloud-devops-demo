# =============================================================================
# MAIN INFRASTRUCTURE
# =============================================================================
# Core AWS resources for Jenkins CI/CD server deployment
# =============================================================================

# -----------------------------------------------------------------------------
# AMI Data Source
# -----------------------------------------------------------------------------
# Automatically fetches the latest Ubuntu 22.04 LTS AMI from Canonical

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical official AWS account
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
# Virtual Private Cloud for network isolation

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jenkins-vpc"
  }
}

# -----------------------------------------------------------------------------
# Public Subnet
# -----------------------------------------------------------------------------
# Subnet with public IP assignment for internet-facing resources

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "jenkins-public-subnet"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
# Enables internet connectivity for the VPC

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "jenkins-igw"
  }
}

# -----------------------------------------------------------------------------
# Route Table
# -----------------------------------------------------------------------------
# Routes traffic to the internet via the Internet Gateway

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "jenkins-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# SSH Key Pair
# -----------------------------------------------------------------------------
# Key pair for secure SSH access to the EC2 instance

resource "aws_key_pair" "jenkins" {
  key_name   = var.key_name
  public_key = file("id_rsa.pub")
}

# -----------------------------------------------------------------------------
# EC2 Instance
# -----------------------------------------------------------------------------
# Jenkins server with Docker support

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.jenkins.key_name

  # User data script with Jenkins plugins injected from plugins.txt
  user_data = templatefile("user_data.sh", {
    jenkins_plugins = file("plugins.txt")
  })

  tags = {
    Name = "jenkins-server"
  }
}
