# =============================================================================
# TERRAFORM OUTPUTS
# =============================================================================
# Output values displayed after infrastructure deployment
# =============================================================================

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to the Jenkins instance"
  value       = "ssh -i id_rsa ubuntu@${aws_instance.jenkins.public_ip}"
}

output "initial_admin_password_command" {
  description = "Command to retrieve Jenkins initial admin password"
  value       = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}
