#!/usr/bin/env bash
set -euo pipefail
sudo apt install unzip
# Defaults (can override via env or flags)
KUBECTL_VERSION="${KUBECTL_VERSION:-latest}" # e.g., v1.30.4 or "latest"
ARGOCd_VERSION="${ARGOCd_VERSION:-latest}" # e.g., v2.12.3 or "latest"
NONINTERACTIVE="${NONINTERACTIVE:-1}"

# Parse flags (simple)
for arg in "$@"; do
 case "$arg" in
 --kubectl-version=*) KUBECTL_VERSION="${arg#*=}";;
 --argocd-version=*) ARGOCd_VERSION="${arg#*=}";;
 esac
done

# Require sudo for system-wide installs
if ! command -v sudo >/dev/null 2>&1; then
 echo "sudo is required. Please install or run as root."
 exit 1
fi

if [ "${NONINTERACTIVE}" = "1" ]; then
 export DEBIAN_FRONTEND=noninteractive
fi

echo "[1/8] Updating apt cache and prerequisites..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

echo "[2/8] Install Git (apt)..."
if ! command -v git >/dev/null 2>&1; then
 sudo apt-get install -y git
else
 echo "Git already installed: $(git --version)"
fi

echo "[3/8] Install Docker Engine (official repo)..."
if ! command -v docker >/dev/null 2>&1; then
 # Remove old
 sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

 # Docker repo key
 sudo install -m 0755 -d /etc/apt/keyrings
 if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
 sudo chmod a+r /etc/apt/keyrings/docker.gpg
 fi

 # Repo line
 . /etc/os-release
 echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 ${UBUNTU_CODENAME:-$(lsb_release -cs)} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

 sudo apt-get update -y
 sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

 # Enable and group add
 sudo systemctl enable docker
 sudo systemctl start docker
 if id -nG "$USER" | grep -qw docker; then
 echo "User already in docker group."
 else
 sudo usermod -aG docker "$USER"
 echo "Added $USER to docker group. Re-login or 'newgrp docker' to take effect."
 fi
else
 echo "Docker already installed: $(docker --version)"
fi

echo "[4/8] Install kubectl..."
ARCH="$(uname -m)"
case "$ARCH" in
 x86_64) K_ARCH="amd64";;
 aarch64|arm64) K_ARCH="arm64";;
 *) K_ARCH="amd64";;
esac

if [ "$KUBECTL_VERSION" = "latest" ]; then
 KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
fi

if command -v kubectl >/dev/null 2>&1; then
 echo "kubectl already installed: $(kubectl version --client --output=yaml 2>/dev/null | head -n1 || true)"
else
 curl -fsSLo kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K_ARCH}/kubectl"
 sudo install -m 0755 kubectl /usr/local/bin/kubectl
 rm -f kubectl
fi

echo "[5/8] Install Argo CD CLI..."
if command -v argocd >/dev/null 2>&1; then
 echo "argocd already installed: $(argocd version --client 2>/dev/null || true)"
else
 if [ "$ARGOCd_VERSION" = "latest" ]; then
 # Official recommended latest download
 curl -fsSLo argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
 else
 curl -fsSLo argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/${ARGOCd_VERSION}/argocd-linux-amd64"
 fi
 sudo install -m 0555 argocd-linux-amd64 /usr/local/bin/argocd
 rm -f argocd-linux-amd64
fi

echo "[6/8] Install AWS CLI v2..."
if command -v aws >/dev/null 2>&1 && aws --version 2>/dev/null | grep -q "aws-cli/2"; then
 echo "AWS CLI v2 already installed: $(aws --version)"
else
 TMPDIR="$(mktemp -d)"
 pushd "$TMPDIR" >/dev/null
 curl -fsSLO "https://awscli.amazonaws.com/awscli-exe-linux-$( [ "$K_ARCH" = "arm64" ] && echo "aarch64" || echo "x86_64").zip"
 unzip -q awscli-exe-linux-*.zip
 sudo ./aws/install --update
 popd >/dev/null
 rm -rf "$TMPDIR"
fi

echo "[7/8] Verify versions..."
echo "Git: $(git --version)"
echo "Docker: $(docker --version || echo 'not in current shell group yet')"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || true)"
echo "argocd: $(argocd version --client 2>/dev/null || true)"
echo "AWS: $(aws --version 2>&1 || true)"

Echo "[8/8] Done. If Docker says permission denied, run: newgrp docker"
