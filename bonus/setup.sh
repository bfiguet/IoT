#!/bin/bash
set -e

# STEP 1: System Update and Required Tools Installation (from p3/setup.sh)
echo "Updating the system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing required dependencies..."
sudo apt-get install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

# STEP 2: Docker Installation (from p3/setup.sh)
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Add the user to the docker group
sudo usermod -aG docker $USER
newgrp docker  # Apply group change immediately (only affects this script session)

# STEP 3: K3D Installation (from p3/setup.sh)
echo "Installing k3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# STEP 4: kubectl Installation (from p3/setup.sh)
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# STEP 5: Create a Kubernetes Cluster using K3D (from p3/setup.sh)
echo "Creating the K3D cluster..."
k3d cluster create moncluster --agents 1 --port "8888:8888@agent[0]"

echo "Cluster successfully created. Nodes :"
kubectl get nodes

# STEP 6: Install ArgoCD (from p3/setup.sh)
echo "Creating the Argo CD namespace (ignore error if it already exists)"
kubectl create namespace argocd || true

echo "Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD pods to become ready..."
kubectl wait --for=condition=ready pod -n argocd --all --timeout=180s

echo "Argo CD has been successfully installed!"

# STEP 7: GitLab Installation (from bonus/setup-gitlab.sh)
echo "Installing GitLab using Helm..."

# Add the GitLab Helm chart repository
helm repo add gitlab https://charts.gitlab.io
helm repo update

# Create the gitlab namespace if it doesn't exist
kubectl create namespace gitlab || true

# Install GitLab with Helm in the 'gitlab' namespace
helm install gitlab gitlab/gitlab --namespace gitlab --set global.hosts.domain=localhost --set global.hosts.externalIP=127.0.0.1

echo "GitLab installation completed!"

# STEP 8: Deploy the Application (from app.yaml and argocd-application.yaml)
echo "Deploying the application (deployment.yaml)..."
kubectl apply -f deployment.yaml

echo "Deploying the ArgoCD application configuration (argocd-application.yaml)..."
kubectl apply -f argocd-application.yaml

echo "Application and ArgoCD configuration deployed successfully!"
