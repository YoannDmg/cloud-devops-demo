FROM jenkins/inbound-agent:latest

USER root

# Installer Docker CLI + créer le groupe docker + ajouter jenkins dedans
RUN apt-get update && \
    apt-get install -y docker.io && \
    groupadd -f docker && \
    usermod -aG docker jenkins && \
    chmod 666 /var/run/docker.sock

USER jenkins
