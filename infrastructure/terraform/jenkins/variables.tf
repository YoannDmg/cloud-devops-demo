# =============================================================================
# JENKINS - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-devops"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# -----------------------------------------------------------------------------
# EC2 Configuration
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
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
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Docker Registry
# -----------------------------------------------------------------------------

variable "docker_registry_user" {
  description = "Docker Hub username"
  type        = string
}

variable "docker_registry_password" {
  description = "Docker Hub password or access token"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Git Configuration
# -----------------------------------------------------------------------------

variable "git_repo_url" {
  description = "Git repository URL for the pipeline"
  type        = string
  default     = "https://github.com/ydmusic/cloud-devops-demo.git"
}

variable "git_branch" {
  description = "Git branch to build"
  type        = string
  default     = "main"
}
