variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  default     = "jenkins-key"
}
