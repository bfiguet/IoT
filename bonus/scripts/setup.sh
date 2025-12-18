#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Cleaning old containerd packages ==="
sudo apt remove -y containerd containerd.io || true
sudo apt autoremove -y
sudo apt update

echo "=== Installing Docker (Ubuntu package) ==="
sudo apt install -y docker.io curl
sudo apt-mark hold containerd.io
sudo systemctl enable --now docker

until sudo docker info >/dev/null 2>&1; do sleep 2; done

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "=== Installing k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "=== Creating k3d cluster ==="
if ! sudo k3d cluster list | grep -q "iot-cluster"; then
  sudo k3d cluster create iot-cluster \
    --servers 1 \
    --agents 1 \
    -p "8888:8888@loadbalancer" \
    --wait
else
  echo "k3d cluster 'iot-cluster' already exists, skipping"
fi

echo "=== Setting kubeconfig ==="
mkdir -p ~/.kube
sudo k3d kubeconfig get iot-cluster > ~/.kube/config
chmod 600 ~/.kube/config

echo "=== Waiting for Kubernetes API ==="
for i in {1..60}; do
  kubectl cluster-info >/dev/null 2>&1 && break
  sleep 2
done

echo "=== Creating namespaces ==="
for ns in argocd dev gitlab; do
  kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
done

echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Installing Argo CD ==="
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available \
  deployment/argocd-server -n argocd --timeout=180s

echo "=== Adding gitlab.local to /etc/hosts ==="
grep -q "gitlab.local" /etc/hosts || sudo sh -c 'echo "192.168.56.112 gitlab.local" >> /etc/hosts'

echo "=== Installing GitLab via Helm ==="
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f "$BASE_DIR/../confs/gitlab-values.yaml" \
  --wait --timeout 300s

echo
echo "===================================="
echo " BONUS setup finished successfully 🎉"
echo
echo " Argo CD:"
echo " kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo
echo " GitLab:"
echo " kubectl get pods -n gitlab"
echo
echo " Initial GitLab root password:"
echo " kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \\"
echo "   -o jsonpath='{.data.password}' | base64 -d"
echo "===================================="
