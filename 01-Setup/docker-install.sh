#!/usr/bin/env bash
set -Eeuo pipefail

# Install Docker Engine on Ubuntu
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash install-docker.sh"
  exit 1
fi

echo "==> Updating packages..."
apt-get update
apt-get install -y ca-certificates curl gnupg

echo "==> Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Adding Docker repository..."
ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

echo "==> Updating package index..."
apt-get update

echo "==> Available Docker Engine versions..."
apt-cache policy docker-ce

echo "==> Installing Docker..."
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "==> Enabling and starting Docker..."
systemctl enable --now docker

echo "==> Docker service status..."
systemctl --no-pager --full status docker

echo "==> Docker version..."
docker --version

echo "==> Docker Compose version..."
docker compose version

echo "==> Docker runtime information..."
docker info

echo "==> Docker installation completed successfully."

