# =============================================================================
# JENKINS - Outputs
# =============================================================================

output "info" {
  description = "Jenkins deployment information"
  value       = <<-EOT

    ============================================
    JENKINS DEPLOYED SUCCESSFULLY
    ============================================

    URL:      http://${aws_instance.jenkins.public_ip}:8080
    User:     admin
    Password: (from terraform.tfvars)

    ============================================
    USEFUL COMMANDS
    ============================================

    SSH:        ssh -i id_rsa ubuntu@${aws_instance.jenkins.public_ip}
    Full logs:  ssh -i id_rsa ubuntu@${aws_instance.jenkins.public_ip} 'sudo cat /var/log/user-data.log'
    Live logs:  ssh -i id_rsa ubuntu@${aws_instance.jenkins.public_ip} 'sudo tail -f /var/log/user-data.log'

    ============================================
    FOR EKS DEPLOYMENT (next step)
    ============================================

    VPC ID:   ${module.vpc.vpc_id}

    Run:
      cd ../eks
      echo 'vpc_id = "${module.vpc.vpc_id}"' > terraform.tfvars
      terraform init && terraform apply

  EOT
}

# Individual outputs for programmatic use
output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
