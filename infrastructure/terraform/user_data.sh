#!/bin/bash

# Force bash si exécuté avec sh
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

set -e

# Logging - rediriger tout vers le fichier log ET la console
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "========================================="
echo "Starting user-data script"
echo "========================================="

# Update
echo "Step 1: Updating packages..."
apt-get update -y

# Install Java (headless - no GUI dependencies)
echo "Step 2: Installing Java 17 (headless)..."
apt-get install -y openjdk-17-jre-headless

# Add Jenkins GPG key (NEW ENDPOINT - 2025)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository (NEW FORMAT)
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update with Jenkins repo enabled
apt-get update -y

# Install Jenkins (mais ne PAS démarrer encore)
echo "Step 3: Installing Jenkins..."
apt-get install -y jenkins

# IMPORTANT: Empêcher Jenkins de démarrer automatiquement
echo "Step 4: Stopping Jenkins temporarily..."
systemctl stop jenkins || true
systemctl disable jenkins

# Préparer les répertoires et fichiers AVANT le premier démarrage
mkdir -p /var/lib/jenkins/plugins /var/lib/jenkins/ref /var/lib/jenkins/init.groovy.d
chown -R jenkins:jenkins /var/lib/jenkins

# Créer le fichier plugins.txt (injecté depuis plugins.txt via Terraform)
cat > /var/lib/jenkins/ref/plugins.txt << 'EOF'
${jenkins_plugins}
EOF
chown jenkins:jenkins /var/lib/jenkins/ref/plugins.txt

# Télécharger jenkins-plugin-cli (outil officiel pour installer les plugins)
PLUGIN_CLI_VERSION="2.12.13"
wget -q -O /tmp/jenkins-plugin-cli.jar \
  https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-$${PLUGIN_CLI_VERSION}.jar || \
  curl -sL -o /tmp/jenkins-plugin-cli.jar \
  https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-$${PLUGIN_CLI_VERSION}.jar

# Installer les plugins AVANT le premier démarrage de Jenkins
# C'est possible car jenkins-plugin-cli télécharge directement les fichiers .jpi
JENKINS_VERSION=$(dpkg -s jenkins | grep Version | awk '{print $2}' | cut -d'-' -f1)
JENKINS_WAR="/usr/share/jenkins/jenkins.war"

echo "Step 5: Installing Jenkins plugins before first start..."
java -jar /tmp/jenkins-plugin-cli.jar \
  --war "$JENKINS_WAR" \
  --plugin-download-directory /var/lib/jenkins/plugins \
  --plugin-file /var/lib/jenkins/ref/plugins.txt \
  --jenkins-version "$JENKINS_VERSION"

chown -R jenkins:jenkins /var/lib/jenkins/plugins

# Maintenant on peut démarrer Jenkins (les plugins sont déjà installés)
echo "Step 6: Starting Jenkins service..."
systemctl enable jenkins
systemctl start jenkins

# Install Docker
echo "Step 7: Installing Docker..."
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Add Jenkins to Docker group
echo "Step 8: Adding Jenkins user to docker group..."
usermod -aG docker jenkins

# Restart Jenkins to apply permissions
echo "Step 9: Restarting Jenkins to apply Docker permissions..."
systemctl restart jenkins

echo "========================================="
echo "user-data script COMPLETED successfully!"
echo "Jenkins service status: $(systemctl is-active jenkins)"
echo "Docker service status: $(systemctl is-active docker)"
echo "Check logs: /var/log/user-data.log"
echo "Jenkins logs: journalctl -u jenkins -f"
echo "========================================="
