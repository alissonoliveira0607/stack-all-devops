DEFAULT_GOAL := create_kind_cluster # Definindo o comando default caso não seja passado nenhum parametro

KIND_MANIFEST=config.yaml
KIND_CLUSTER=kind

install_metallb:
	@kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
	@kubectl apply -f kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
	@kubectl wait --namespace metallb-system \
		--for=condition=ready pod \
		--selector=app=metallb \
		--timeout=300s  
	@kubectl apply -f manifests/

install_helm:
	@sudo snap install helm --classic
	@chmod go-rw /home/$USER/.kube/config
	@kubectl create namespace ingress-nginx

venv:
	@python3 -m venv  ./venv
	@source venv/bin/activate
create_kind_cluster:
	@kind create cluster --config ${KIND_MANIFEST}

delete_cluster:
	@kind delete cluster --name ${KIND_CLUSTER}

stop_cluster:
	@docker stop $$(docker ps | grep -i kind | awk '{print $$1}')

start_cluster:
	@docker start $$(docker ps -a | grep -i kind | awk '{print $$1}')
	
config_hosts:
	@if ! grep -q 'jenkins.localhost.com' /etc/hosts; then \
		for container in $$(docker ps --filter "label=io.x-k8s.kind.role=worker" -q); do \
			docker exec -ti $$container bash -c "grep -q 'jenkins.localhost.com' /etc/hosts || echo '172.21.0.50 argocd.localhost.com jenkins.localhost.com gitea.localhost.com sonarqube.localhost.com harbor.localhost.com' >> /etc/hosts"; \
		done; \
	fi

validate_hosts:
	@for container in $$(docker ps --filter "label=io.x-k8s.kind.role=worker" -q); do \
		docker exec -ti $$container bash -c 'cat /etc/hosts'; \
	done

up_cluster: create_kind_cluster install_metallb

.PHONY: venv create_kind_cluster delete_cluster stop_cluster start_cluster config_hosts validate_hosts

 