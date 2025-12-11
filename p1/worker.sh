#!/usr/bin/env bash
set -eux

source /home/vagrant/common.sh

SERVER_IP="192.168.56.110"
WORKER_IP="192.168.56.111"

cat /home/vagrant/.ssh/id_rsa.pub | sudo tee -a /home/vagrant/.ssh/authorized_keys
sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
sudo chmod 600 /home/vagrant/.ssh/authorized_keys

# Retrieve the k3s token from the server
K3S_TOKEN=$(ssh -o StrictHostKeyChecking=no vagrant@${SERVER_IP} 'cat /home/vagrant/k3s_token')

# Installing k3s in agent (node) mode
export K3S_URL="https://${SERVER_IP}:6443"
export K3S_TOKEN="${K3S_TOKEN}"
export INSTALL_K3S_EXEC="agent --node-ip=${WORKER_IP}"
curl -sfL https://get.k3s.io | sh -