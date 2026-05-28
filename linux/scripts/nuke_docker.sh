#!/usr/bin/env bash
set -euo pipefail

# Full Docker reset / cleanup
# Run with: sudo bash docker-reset.sh

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

echo "==> Attempting to clean Docker objects (if daemon is available)..."
if command -v docker >/dev/null 2>&1; then
  # Remove all containers
  docker ps -aq | xargs -r docker rm -f || true

  # Remove all images
  docker images -aq | xargs -r docker rmi -f || true

  # Remove all volumes
  docker volume ls -q | xargs -r docker volume rm || true

  # Remove unused networks/build cache if daemon still responds
  docker network prune -f || true
  docker builder prune -af || true
fi

echo "==> Stopping Docker services..."
systemctl stop docker.service 2>/dev/null || true
systemctl stop docker.socket 2>/dev/null || true
systemctl stop containerd.service 2>/dev/null || true

echo "==> Removing Docker data directories..."
rm -rf /var/lib/docker
rm -rf /var/lib/containerd

echo "==> Recreating base directories..."
mkdir -p /var/lib/docker
mkdir -p /var/lib/containerd
chown root:root /var/lib/docker /var/lib/containerd

echo "==> Starting services..."
systemctl start containerd.service 2>/dev/null || true
systemctl start docker.service

echo "==> Docker reset complete."
echo "==> Current Docker info:"
docker info || true
