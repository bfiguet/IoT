#!/bin/bash
set -e

echo "Updating the system..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing required dependencies..."
sudo apt-get install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

sudo usermod -aG docker $USER
newgrp docker  # Apply group change immediately (only affects this script session)

echo "Installing k3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "All required tools have installed sucessfully!"

echo "Creating the K3D cluster..."
# Create a k3d cluster with one agent
# Expose port 8888 from the agent to localhost
k3d cluster create bfiguet --agents 1 --port "8888:8888@agent[0]"

echo "Cluster successfully created. Nodes :"
kubectl get nodes

# Create the Argo CD namespace (ignore error if it already exists)
kubectl create namespace argocd || true

# Install Argo CD in its dedicated namespace
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD pods to become ready..."
kubectl wait --for=condition=ready pod -n argocd --all --timeout=180s

echo "Argo CD has been successfully installed!"

# Create the development namespace for the application
kubectl create namespace dev || true

# Deploy the application (Deployment + Service)
kubectl apply -f deployment.yaml

echo "Application deployed successfully!"
