#!/usr/bin/env bash
set -eux  # Exit on error, exit on undefined variable and print commands being executed (for debugging)

# Update and install basic tools
sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https gnupg lsb-release

# Install kubectl (official binary)
KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Generate server SSH keypair if not existing
sudo -u vagrant mkdir -p /home/vagrant/.ssh
HOSTNAME=$(hostname)
if [ ! -f "/home/vagrant/.ssh/id_rsa_${HOSTNAME}" ]; then
	sudo -u vagrant ssh-keygen -t rsa -b 4096 -N "" -f "/home/vagrant/.ssh/id_rsa_${HOSTNAME}"
	# -u vagrant: run command as user vagrant
	# -type rsa -b (bits) -N "" (no passphrase) -f (output file)
	ln -sf "/home/vagrant/.ssh/id_rsa_${HOSTNAME}" /home/vagrant/.ssh/id_rsa
	ln -sf "/home/vagrant/.ssh/id_rsa_${HOSTNAME}.pub" /home/vagrant/.ssh/id_rsa.pub
fi

# Authorize public key access for server
sudo chmod 700 /home/vagrant/.ssh
sudo chmod 600 /home/vagrant/.ssh/id_rsa*
sudo chown -R vagrant:vagrant /home/vagrant/.ssh