#!/bin/bash
# =============================================================================
# JENKINS SERVER INITIALIZATION SCRIPT
# =============================================================================
# This script is executed on first boot to configure the EC2 instance with:
# - Jenkins CI/CD server
# - Docker for containerized builds
# - Pre-installed Jenkins plugins (from plugins.txt)
#
# Logs: /var/log/user-data.log
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
# Redirect all output to both console and log file for debugging

exec > >(tee -a /var/log/user-data.log) 2>&1

log_step() {
    echo ""
    echo "=============================================="
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "=============================================="
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

log_step "Starting Jenkins server initialization"

# -----------------------------------------------------------------------------
# Step 1: System Update
# -----------------------------------------------------------------------------

log_step "Step 1/9: Updating system packages"
apt-get update -y
log_info "System packages updated successfully"

# -----------------------------------------------------------------------------
# Step 2: Install Java
# -----------------------------------------------------------------------------

log_step "Step 2/9: Installing Java 17 (OpenJDK headless)"
apt-get install -y openjdk-17-jre-headless
log_info "Java version: $(java -version 2>&1 | head -n 1)"

# -----------------------------------------------------------------------------
# Step 3: Add Jenkins Repository
# -----------------------------------------------------------------------------

log_step "Step 3/9: Configuring Jenkins repository"

# Add Jenkins GPG key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
log_info "Jenkins GPG key added"

# Add Jenkins apt repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
    tee /etc/apt/sources.list.d/jenkins.list > /dev/null
log_info "Jenkins repository configured"

apt-get update -y

# -----------------------------------------------------------------------------
# Step 4: Install Jenkins
# -----------------------------------------------------------------------------

log_step "Step 4/9: Installing Jenkins"
apt-get install -y jenkins

# Stop Jenkins to configure before first real start
systemctl stop jenkins || true
systemctl disable jenkins
log_info "Jenkins installed and stopped for pre-configuration"

# -----------------------------------------------------------------------------
# Step 5: Prepare Jenkins Directories
# -----------------------------------------------------------------------------

log_step "Step 5/9: Preparing Jenkins directories"
mkdir -p /var/lib/jenkins/plugins
mkdir -p /var/lib/jenkins/ref
mkdir -p /var/lib/jenkins/init.groovy.d
chown -R jenkins:jenkins /var/lib/jenkins
log_info "Jenkins directories created"

# -----------------------------------------------------------------------------
# Step 6: Install Jenkins Plugins
# -----------------------------------------------------------------------------

log_step "Step 6/9: Installing Jenkins plugins"

# Write plugins list (injected by Terraform from plugins.txt)
cat > /var/lib/jenkins/ref/plugins.txt << 'EOF'
${jenkins_plugins}
EOF
chown jenkins:jenkins /var/lib/jenkins/ref/plugins.txt

# Count plugins to install
PLUGIN_COUNT=$(grep -c -v '^$' /var/lib/jenkins/ref/plugins.txt || echo "0")
log_info "Plugins to install: $PLUGIN_COUNT"

# Download Jenkins Plugin Installation Manager
PLUGIN_CLI_VERSION="2.12.13"
log_info "Downloading jenkins-plugin-manager v$${PLUGIN_CLI_VERSION}"

wget -q -O /tmp/jenkins-plugin-cli.jar \
    "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-$${PLUGIN_CLI_VERSION}.jar" || \
    curl -sL -o /tmp/jenkins-plugin-cli.jar \
    "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-$${PLUGIN_CLI_VERSION}.jar"

# Get Jenkins version for plugin compatibility
JENKINS_VERSION=$(dpkg -s jenkins | grep Version | awk '{print $2}' | cut -d'-' -f1)
log_info "Jenkins version detected: $JENKINS_VERSION"

# Install plugins
log_info "Installing plugins (this may take a few minutes)..."
java -jar /tmp/jenkins-plugin-cli.jar \
    --plugin-download-directory /var/lib/jenkins/plugins \
    --plugin-file /var/lib/jenkins/ref/plugins.txt \
    --jenkins-version "$JENKINS_VERSION"

chown -R jenkins:jenkins /var/lib/jenkins/plugins
log_info "Plugins installed successfully"

# -----------------------------------------------------------------------------
# Step 7: Start Jenkins
# -----------------------------------------------------------------------------

log_step "Step 7/9: Starting Jenkins service"
systemctl enable jenkins
systemctl start jenkins
log_info "Jenkins service started"

# -----------------------------------------------------------------------------
# Step 8: Install Docker
# -----------------------------------------------------------------------------

log_step "Step 8/9: Installing Docker"
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Add Jenkins user to docker group for containerized builds
usermod -aG docker jenkins
log_info "Docker installed and Jenkins user added to docker group"
log_info "Docker version: $(docker --version)"

# -----------------------------------------------------------------------------
# Step 9: Apply Docker Permissions
# -----------------------------------------------------------------------------

log_step "Step 9/9: Restarting Jenkins to apply Docker permissions"
systemctl restart jenkins
log_info "Jenkins restarted with Docker permissions"

# -----------------------------------------------------------------------------
# Initialization Complete
# -----------------------------------------------------------------------------

log_step "INITIALIZATION COMPLETE"
echo ""
echo "  Jenkins Status: $(systemctl is-active jenkins)"
echo "  Docker Status:  $(systemctl is-active docker)"
echo ""
echo "  Next steps:"
echo "  1. Access Jenkins at http://<public-ip>:8080"
echo "  2. Get initial admin password:"
echo "     sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "  Logs:"
echo "  - This script: /var/log/user-data.log"
echo "  - Jenkins:     journalctl -u jenkins -f"
echo ""
