#!/bin/bash
# =============================================================================
# JENKINS SERVER INITIALIZATION SCRIPT
# =============================================================================
# This script is executed on first boot to configure the EC2 instance with:
# - Jenkins CI/CD server (fully configured, no manual setup)
# - Docker for containerized builds
# - Pre-installed Jenkins plugins
# - Auto-created admin user and pipeline job
#
# Logs: /var/log/user-data.log
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------

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

log_step "Step 1/11: Updating system packages"
apt-get update -y
log_info "System packages updated successfully"

# -----------------------------------------------------------------------------
# Step 2: Install Java
# -----------------------------------------------------------------------------

log_step "Step 2/11: Installing Java 17 (OpenJDK headless)"
apt-get install -y openjdk-17-jre-headless
log_info "Java version: $(java -version 2>&1 | head -n 1)"

# -----------------------------------------------------------------------------
# Step 3: Add Jenkins Repository
# -----------------------------------------------------------------------------

log_step "Step 3/11: Configuring Jenkins repository"

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
log_info "Jenkins GPG key added"

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
    tee /etc/apt/sources.list.d/jenkins.list > /dev/null
log_info "Jenkins repository configured"

apt-get update -y

# -----------------------------------------------------------------------------
# Step 4: Install Jenkins
# -----------------------------------------------------------------------------

log_step "Step 4/11: Installing Jenkins"
apt-get install -y jenkins

systemctl stop jenkins || true
systemctl disable jenkins
log_info "Jenkins installed and stopped for pre-configuration"

# -----------------------------------------------------------------------------
# Step 5: Prepare Jenkins Directories
# -----------------------------------------------------------------------------

log_step "Step 5/11: Preparing Jenkins directories"
mkdir -p /var/lib/jenkins/plugins
mkdir -p /var/lib/jenkins/ref
mkdir -p /var/lib/jenkins/init.groovy.d
mkdir -p /var/lib/jenkins/jobs/cloud-devops-demo
chown -R jenkins:jenkins /var/lib/jenkins
log_info "Jenkins directories created"

# -----------------------------------------------------------------------------
# Step 6: Install Jenkins Plugins
# -----------------------------------------------------------------------------

log_step "Step 6/11: Installing Jenkins plugins"

cat > /var/lib/jenkins/ref/plugins.txt << 'EOF'
${jenkins_plugins}
EOF
chown jenkins:jenkins /var/lib/jenkins/ref/plugins.txt

PLUGIN_COUNT=$(grep -c -v '^$' /var/lib/jenkins/ref/plugins.txt || echo "0")
log_info "Plugins to install: $PLUGIN_COUNT"

PLUGIN_CLI_VERSION="2.12.13"
log_info "Downloading jenkins-plugin-manager v$${PLUGIN_CLI_VERSION}"

wget -q -O /tmp/jenkins-plugin-cli.jar \
    "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-$${PLUGIN_CLI_VERSION}.jar" || \
    curl -sL -o /tmp/jenkins-plugin-cli.jar \
    "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$${PLUGIN_CLI_VERSION}/jenkins-plugin-manager-$${PLUGIN_CLI_VERSION}.jar"

JENKINS_VERSION=$(dpkg -s jenkins | grep Version | awk '{print $2}' | cut -d'-' -f1)
log_info "Jenkins version detected: $JENKINS_VERSION"

log_info "Installing plugins (this may take a few minutes)..."
java -jar /tmp/jenkins-plugin-cli.jar \
    --plugin-download-directory /var/lib/jenkins/plugins \
    --plugin-file /var/lib/jenkins/ref/plugins.txt \
    --jenkins-version "$JENKINS_VERSION"

chown -R jenkins:jenkins /var/lib/jenkins/plugins
log_info "Plugins installed successfully"

# -----------------------------------------------------------------------------
# Step 7: Configure Jenkins (Skip Setup Wizard + Create Admin)
# -----------------------------------------------------------------------------

log_step "Step 7/11: Configuring Jenkins automatically"

# Disable setup wizard
cat > /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion << EOF
$JENKINS_VERSION
EOF

cat > /var/lib/jenkins/jenkins.install.UpgradeWizard.state << EOF
$JENKINS_VERSION
EOF

# Create initial admin user via Groovy script
cat > /var/lib/jenkins/init.groovy.d/01-create-admin.groovy << 'GROOVY'
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${jenkins_admin_user}", "${jenkins_admin_password}")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy (logged-in users can do anything)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Mark setup as complete
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

instance.save()
println("Admin user '${jenkins_admin_user}' created successfully")
GROOVY

chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/01-create-admin.groovy
log_info "Admin user configuration script created"

# -----------------------------------------------------------------------------
# Step 8: Configure Docker Registry Credentials
# -----------------------------------------------------------------------------

log_step "Step 8/11: Configuring Docker registry credentials"

cat > /var/lib/jenkins/init.groovy.d/02-docker-credentials.groovy << 'GROOVY'
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

def dockerCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "docker-registry",
    "Docker Hub Registry Credentials",
    "${docker_registry_user}",
    "${docker_registry_password}"
)

store.addCredentials(domain, dockerCredentials)
instance.save()
println("Docker registry credentials configured successfully")
GROOVY

chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/02-docker-credentials.groovy
log_info "Docker credentials configuration script created"

# -----------------------------------------------------------------------------
# Step 9: Create Pipeline Job
# -----------------------------------------------------------------------------

log_step "Step 9/11: Creating pipeline job"

cat > /var/lib/jenkins/jobs/cloud-devops-demo/config.xml << 'JOBXML'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>Cloud DevOps Demo - Full CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${git_repo_url}</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${git_branch}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
JOBXML

chown -R jenkins:jenkins /var/lib/jenkins/jobs/cloud-devops-demo
log_info "Pipeline job 'cloud-devops-demo' created"

# -----------------------------------------------------------------------------
# Step 10: Install Docker
# -----------------------------------------------------------------------------

log_step "Step 10/13: Installing Docker"
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

usermod -aG docker jenkins
log_info "Docker installed and Jenkins user added to docker group"
log_info "Docker version: $(docker --version)"

# -----------------------------------------------------------------------------
# Step 11: Install AWS CLI
# -----------------------------------------------------------------------------

log_step "Step 11/13: Installing AWS CLI"
apt-get install -y unzip curl
curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip
log_info "AWS CLI version: $(aws --version)"

# -----------------------------------------------------------------------------
# Step 12: Install kubectl
# -----------------------------------------------------------------------------

log_step "Step 12/13: Installing kubectl"
curl -sLO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
log_info "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# -----------------------------------------------------------------------------
# Step 13: Start Jenkins
# -----------------------------------------------------------------------------

log_step "Step 13/13: Starting Jenkins service"
chown -R jenkins:jenkins /var/lib/jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait for Jenkins to be ready
log_info "Waiting for Jenkins to start..."
sleep 30

# Cleanup init scripts after first run (security: remove passwords from disk)
rm -f /var/lib/jenkins/init.groovy.d/01-create-admin.groovy
rm -f /var/lib/jenkins/init.groovy.d/02-docker-credentials.groovy
log_info "Init scripts cleaned up for security"

systemctl restart jenkins
log_info "Jenkins restarted"

# -----------------------------------------------------------------------------
# Initialization Complete
# -----------------------------------------------------------------------------

log_step "INITIALIZATION COMPLETE"
echo ""
echo "  Services:"
echo "    - Jenkins:  $(systemctl is-active jenkins)"
echo "    - Docker:   $(systemctl is-active docker)"
echo ""
echo "  Tools installed:"
echo "    - Java:     $(java -version 2>&1 | head -1 | cut -d'"' -f2)"
echo "    - Docker:   $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "    - kubectl:  $(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion": "[^"]*"' | cut -d'"' -f4 || echo 'installed')"
echo "    - AWS CLI:  $(aws --version 2>/dev/null | cut -d' ' -f1 | cut -d'/' -f2)"
echo ""
echo "  Jenkins is ready at port 8080"
echo ""
log_step "END OF INITIALIZATION LOG"
