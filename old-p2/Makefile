VM_NAME  = bfiguetS
IP = 192.168.56.110

up:
	vagrant up

down:
	vagrant halt

fclean:
	vagrant destroy -f
	rm -rf k3s-apps
	rm -rf .vagrant

re: clean up

ssh:
	vagrant ssh $(VM_NAME)

# --- K3s / Kubernetes commands ---
pods:
	vagrant ssh $(VM_NAME) -- kubectl get pods -A

services:
	vagrant ssh $(VM_NAME) -- kubectl get svc -A

ingress:
	vagrant ssh $(VM_NAME) -- kubectl get ingress -A

# --- Test applications ---
tests:
	curl -H "Host: app1.com" http://$(IP)
	curl -H "Host: app2.com" http://$(IP)
	curl -H "Host: random.com" http://$(IP)

# --- Apply or delete apps in K3s ---
apply:
	vagrant ssh $(VM_NAME) -- kubectl apply -f /vagrant/k3s-apps/


.PHONY: help up down clean pods ssh services ingress tests apply re
