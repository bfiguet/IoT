VAGRANT = vagrant
SERVER  = bfiguetS
WORKER  = bfiguetSW

up:
	$(VAGRANT) up

down:
	$(VAGRANT) halt

clean:
	$(VAGRANT) destroy -f
	rm -rf .vagrant
	rm -f k3s_token

re: clean up

status:
	$(VAGRANT) ssh $(SERVER) -c "sudo systemctl status k3s --no-pager"

nodes:
	$(VAGRANT) ssh $(SERVER) -c "kubectl get nodes"

pods:
	$(VAGRANT) ssh $(SERVER) -c "kubectl get pods -A"

ssh-server:
	$(VAGRANT) ssh $(SERVER)

ssh-worker:
	$(VAGRANT) ssh $(WORKER)

help:
	@echo "Available commands:"
	@echo "  make up           - Start the VMs and the K3s cluster"
	@echo "  make status       - Check K3s service status"
	@echo "  make re           - Recreate the VMs"
	@echo "  make clean        - Destroy VMs and remove local state files"
	@echo "  make nodes        - List Kubernetes nodes"
	@echo "  make pods         - List all Kubernetes pods"
	@echo "  make ssh-server   - SSH into the server node"
	@echo "  make ssh-worker   - SSH into the worker node"
	@echo "  make down         - Stop the VMs"

.PHONY: help up down clean status nodes pods ssh-server ssh-worker
