FROM jenkins/inbound-agent:latest

USER root

# Installer Docker CLI
RUN apt-get update && \
    apt-get install -y docker.io

# Créer le groupe docker si inexistant
RUN groupadd -f docker

# Ajouter l'utilisateur jenkins au groupe docker
RUN usermod -aG docker jenkins

USER jenkins
