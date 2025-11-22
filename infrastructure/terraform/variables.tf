# =============================================================================
# TERRAFORM VARIABLES
# =============================================================================
# Input variables for the Jenkins infrastructure deployment
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-north-1"
}

# -----------------------------------------------------------------------------
# EC2 Instance Configuration
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair for EC2 access"
  type        = string
  default     = "jenkins-key"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# -----------------------------------------------------------------------------
# Jenkins Configuration
# -----------------------------------------------------------------------------

variable "jenkins_admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password (use TF_VAR_jenkins_admin_password env var)"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL for the pipeline"
  type        = string
  default     = "https://github.com/YoannDmg/cloud-devops-demo.git"
}

variable "git_branch" {
  description = "Git branch to build"
  type        = string
  default     = "main"
}

# -----------------------------------------------------------------------------
# Docker Registry Configuration
# -----------------------------------------------------------------------------

variable "docker_registry_user" {
  description = "Docker registry username (use TF_VAR_docker_registry_user env var)"
  type        = string
  sensitive   = true
}

variable "docker_registry_password" {
  description = "Docker registry password (use TF_VAR_docker_registry_password env var)"
  type        = string
  sensitive   = true
}
