#!/bin/bash
set -euo pipefail

echo "=== Updating the system ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== Installing required dependencies ==="
sudo apt-get install -y \
  curl wget git apt-transport-https ca-certificates gnupg lsb-release

echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

echo "=== Adding current user to docker group ==="
if ! id -nG "$USER" | grep -q '\bdocker\b'; then
  sudo usermod -aG docker "$USER"
  echo "You have been added to the docker group. Please log out/in (or exit/reconnect) for it to take effect."
fi

echo "=== Installing k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "=== Installing kubectl ==="
KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client || echo "kubectl installed."

echo "=== Creating k3d cluster bfiguet-p3 ==="
# Supprime un cluster existant du même nom si besoin
if k3d cluster list 2>/dev/null | grep -q '^bfiguet-p3'; then
  k3d cluster delete bfiguet-p3
fi

k3d cluster create bfiguet-p3 --agents 1

echo "=== Configuring kubeconfig for bfiguet-p3 ==="
mkdir -p ~/.kube
k3d kubeconfig merge bfiguet-p3 \
  --kubeconfig-merge-default \
  --kubeconfig-switch-context

echo "=== Cluster nodes ==="
kubectl get nodes

echo "=== Creating Argo CD namespace ==="
kubectl create namespace argocd || true

echo "=== Installing Argo CD ==="
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Waiting for Argo CD pods to be ready ==="
kubectl wait --for=condition=ready pod -n argocd --all --timeout=300s

echo "=== Argo CD installed ==="

echo "=== Creating dev namespace ==="
kubectl create namespace dev || true

echo "=== Deploying application from app.yaml ==="
kubectl apply -f app.yaml

echo "=== Application deployed. Resources in dev: ==="
kubectl get all -n dev

echo "✅ setup.sh finished successfully."
