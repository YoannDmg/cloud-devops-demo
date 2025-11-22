############################################
#  FIND UBUNTU AMI AUTOMATICALLY (22.04)
############################################

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

############################################
#  VPC
############################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devops-vpc"
  }
}

############################################
#  PUBLIC SUBNET
############################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-subnet"
  }
}

############################################
#  INTERNET GATEWAY
############################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-igw"
  }
}

############################################
#  PUBLIC ROUTE TABLE
############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "devops-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

############################################
#  SSH KEY PAIR
############################################

resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = file("id_rsa.pub")
}

############################################
#  EC2 INSTANCE FOR JENKINS
############################################

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.jenkins_key.key_name

  user_data = templatefile("user_data.sh", {
    jenkins_plugins = file("plugins.txt")
  })

  tags = {
    Name = "Jenkins-Server"
  }
}
