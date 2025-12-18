SERVER  = bfiguetS
WORKER  = bfiguetSW

up:
	vagrant up

down:
	vagrant halt

fclean:
	vagrant destroy -f
	rm -rf .vagrant
	rm -f k3s_token

re: clean up

status:
	vagrant ssh $(SERVER) -c "sudo systemctl status k3s --no-pager"

nodes:
	vagrant ssh $(SERVER) -c "kubectl get nodes"

pods:
	vagrant ssh $(SERVER) -c "kubectl get pods -A"

ssh-server:
	vagrant ssh $(SERVER)

ssh-worker:
	vagrant ssh $(WORKER)

.PHONY: help up down clean status nodes pods ssh-server ssh-worker
