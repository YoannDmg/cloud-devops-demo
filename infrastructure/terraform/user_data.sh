#!/bin/bash

set -e

# Update
apt-get update -y

# Install Java (required for Jenkins)
apt-get install -y openjdk-17-jre

# Add Jenkins GPG key (NEW ENDPOINT - 2025)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository (NEW FORMAT)
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update with Jenkins repo enabled
apt-get update -y

# Install Jenkins
apt-get install -y jenkins

# Enable & start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Install Docker
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Add Jenkins to Docker group
usermod -aG docker jenkins

# Restart Jenkins to apply permissions
systemctl restart jenkins
