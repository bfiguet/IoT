#!/bin/bash
set -e

echo "Mise à jour du système..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installation des dépendances..."
sudo apt-get install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release

echo "Installation de Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

echo "Installation de k3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "Installation de kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "Tous les outils sont installés !"

echo "Création du cluster K3D..."
k3d cluster create moncluster --agents 1 --port "8888:8888@agent[0]"

echo "Cluster créé :"
kubectl get nodes

# Créer un namespace pour Argo CD
kubectl create namespace argocd || true

# Installer Argo CD dans ce namespace
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Attente que les pods Argo CD soient prêts..."
kubectl wait --for=condition=ready pod -n argocd --all --timeout=180s

echo "Argo CD installé !"

kubectl create namespace dev || true

kubectl apply -f deployment.yaml
echo "Application déployée !"