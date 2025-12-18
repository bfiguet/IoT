#!/bin/bash
set -e

echo "=== Installing Docker ==="
sudo apt update
sudo apt install -y docker.io curl
sudo systemctl enable --now docker

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "=== Installing k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "=== Creating k3d cluster ==="
if ! sudo k3d cluster list | grep -q "iot-cluster"; then
  sudo k3d cluster create iot-cluster
else
  echo "k3d cluster 'iot-cluster' already exists, skipping creation"
fi

echo "=== Setting up kubeconfig for k3d cluster ==="
mkdir -p ~/.kube
sudo k3d kubeconfig get iot-cluster > ~/.kube/config
chmod 600 ~/.kube/config

echo "=== Waiting for k3d API (max 120s) ==="
ATTEMPTS=60
until kubectl cluster-info >/dev/null 2>&1 || [ "$ATTEMPTS" -eq 0 ]; do
  ATTEMPTS=$((ATTEMPTS-1))
  sleep 2
done
[ "$ATTEMPTS" -eq 0 ] && { echo "ERROR: k3d API timeout"; exit 1; }


echo "=== Creating namespaces ==="
kubectl create namespace argocd || true
kubectl create namespace dev || true

echo "=== Installing Argo CD ==="
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Waiting for Argo CD to be ready ==="
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=180s

echo "=== Argo CD admin password ==="
  kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
echo

echo "=== Deploying Argo CD application ==="
kubectl apply -f conf/app-argocd.yaml

echo
echo "======================================================"
echo " Setup finished successfully 🎉"
echo
echo " To access Argo CD UI, run the following command:"
echo " kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443 "
echo "  → https://localhost:8080 (admin / <password seen above>)"
echo
echo " To access the Wil Playground, run the following command:"
echo " kubectl port-forward deployment/wil-playground 8888:8888 -n dev "
echo " curl http://localhost:8888/ "
echo
echo "Check the pods"
echo " kubectl get pods -n argocd "
echo " kubectl get pods -n dev "
echo
echo "Check the services"
echo " kubectl get svc -n argocd "
echo " kubectl get svc -n dev "
echo
echo "Check the k3d cluster details"
echo " sudo k3d cluster list "
echo "======================================================"
