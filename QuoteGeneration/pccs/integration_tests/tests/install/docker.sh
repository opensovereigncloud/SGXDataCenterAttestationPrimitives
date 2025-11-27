#!/usr/bin/env bash
set -euo pipefail

echo "Removing any old Docker versions..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "Installing prerequisites..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    echo "Adding Docker's official GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo "Setting up Docker repository..."
ARCH=$(dpkg --print-architecture)
RELEASE=$(lsb_release -cs)
echo \
  "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $RELEASE stable" > /etc/apt/sources.list.d/docker.list

echo "Installing Docker Engine, CLI, and related plugins..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

echo "Verifying Docker installation..."
if docker --version && docker compose version; then
    echo "✅ Docker installed successfully."
else
    echo "❌ Docker installation failed."
    exit 1
fi
