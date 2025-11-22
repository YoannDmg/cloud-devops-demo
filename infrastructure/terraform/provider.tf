# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
# Provider configuration for AWS infrastructure deployment
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
# Uses the "terraform" AWS CLI profile for authentication
# Region: eu-north-1 (Stockholm)
# -----------------------------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  profile = "terraform"
}
