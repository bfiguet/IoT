#!/usr/bin/env bash
set -eux

source /home/vagrant/common.sh
SERVER_IP="192.168.56.110"
WORKER_IP="192.168.56.111"

# Authorize your own key on the server
cat /home/vagrant/.ssh/id_rsa.pub | sudo tee -a /home/vagrant/.ssh/authorized_keys

sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
sudo chmod 600 /home/vagrant/.ssh/authorized_keys

# Installing k3s in server (controller) mode
# The network interface is forced to use the private IP address
export INSTALL_K3S_EXEC="server --tls-san ${SERVER_IP} --bind-address=${SERVER_IP} --node-ip ${SERVER_IP}"
curl -sfL https://get.k3s.io | sh -


# Wait k3s + token
for i in {1..120}; do
  if systemctl is-active --quiet k3s; then
    sudo cat /var/lib/rancher/k3s/server/token > /home/vagrant/k3s_token
    sudo chown vagrant:vagrant /home/vagrant/k3s_token
	echo "k3s server ready, token created"
    break
  fi
  echo "Waiting for k3s... ($i/120)"
  sleep 5
done

sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/kubeconfig
sudo chown vagrant:vagrant /home/vagrant/kubeconfig
echo 'export KUBECONFIG=$HOME/kubeconfig' | sudo tee -a /home/vagrant/.bashrc

# Import worker public key on the server so worker can SSH into server
echo "Importing worker SSH key automatically..."
for i in {1..60}; do
  WORKER_PUB=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    vagrant@${WORKER_IP} 'cat /home/vagrant/.ssh/id_rsa.pub' 2>/dev/null || true)
  if [ -n "${WORKER_PUB}" ]; then
    echo "${WORKER_PUB}" | sudo tee -a /home/vagrant/.ssh/authorized_keys >/dev/null
    sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
    sudo chmod 600 /home/vagrant/.ssh/authorized_keys
    echo "Worker SSH key imported on server"
    break
  fi
  echo "Worker not ready yet, retrying SSH key import... ($i/60)"
  sleep 5
done
