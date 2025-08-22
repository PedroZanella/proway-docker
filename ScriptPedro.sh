#!/bin/bash

# Directory where the repository will be cloned.
REPO_DIR="/home/aluno/proway-docker/proway-docker"

# URL of the Git repository.
REPO_URL="https://github.com/PedroZanella/proway-docker.git"

# Docker and necessary plugins installation
echo "Checking and installing Docker"
if ! command -v docker &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        docker-compose-plugin

    # Add the official Docker GPG key (ESSENTIAL)
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Add the current user to the "docker" group to avoid using sudo.
    sudo usermod -aG docker $USER
    echo "Docker installed successfully! The session needs to be restarted or 'newgrp docker' executed for changes to take effect."
else
    echo "Docker is already installed."
fi

# Git Pull or Clone the Repository
echo "Updating or cloning the Git repository..."
if [ -d "$REPO_DIR" ]; then
    echo "Repository directory already exists. Performing 'git pull'..."
    cd "$REPO_DIR"
    git pull
else
    echo "Directory not found. Cloning the repository..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Docker Compose Deploy
echo "Starting Docker Compose deployment"
# Navigate to the project folder (the path is now complete)
cd "$REPO_DIR/pizzaria-app"
# Use 'docker-compose' with a hyphen, which is more compatible
docker-compose up -d --build --force-recreate

# Crontab Configuration
echo "Configuring crontab to run the deploy every 5 minutes..."
# Complete path without syntax error
CRON_JOB="*/5 * * * * cd $REPO_DIR/pizzaria-app && /usr/local/bin/docker-compose up -d --build --force-recreate"
(crontab -l 2>/dev/null | grep -Fv "$CRON_JOB"; echo "$CRON_JOB") | crontab -

echo "Deployment finished. The system will be updated automatically every 5 minutes."
