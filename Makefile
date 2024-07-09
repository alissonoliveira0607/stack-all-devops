DEFAULT_GOAL := create_kind_cluster # Definindo o comando default caso não seja passado nenhum parametro

KIND_MANIFEST=config.yaml
KIND_CLUSTER=kind

up_vagrant:
	vagrant up
destroy_vagrant:
	vagrant destroy -f

create_kind_cluster:
	@kind create cluster --config ${KIND_MANIFEST}
delete_cluster:
	@kind delete cluster --name ${KIND_CLUSTER}
stop_cluster:
	@docker stop $$(docker ps | grep -i kind | awk '{print $$1}')
start_cluster:
	@docker start $$(docker ps -a | grep -i kind | awk '{print $$1}')
venv:
	@python3 -m venv  ./venv
	@source venv/bin/activate
install_metallb:
	#@kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
	@kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
	@kubectl wait --namespace metallb-system \
		--for=condition=ready pod \
		--selector=app=metallb \
		--timeout=900s  
	@kubectl apply -f manifests/

install_ingress:
	@kubectl create namespace ingress-nginx
	@helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	@helm repo update
	@helm upgrade --install --namespace ingress-nginx --create-namespace -f values/ingress-nginx/values.yaml ingress-nginx ingress-nginx/ingress-nginx
helm:
	@helmfile apply
passwd:
	@echo "JENKINS: "
	@kubectl get secret -n jenkins jenkins -o json | jq -r '.data."jenkins-admin-password"' | base64 -d
config_hosts:
	@if ! grep -q 'jenkins.localhost.com' /etc/hosts; then \
		for container in $$(docker ps --filter "label=io.x-k8s.kind.role=worker" -q); do \
			docker exec -ti $$container bash -c "grep -q 'jenkins.localhost.com' /etc/hosts || echo '172.18s.0.50 argocd.localhost.com jenkins.localhost.com gitea.localhost.com sonarqube.localhost.com harbor.localhost.com' >> /etc/hosts"; \
		done; \
	fi
validate_hosts:
	@for container in $$(docker ps --filter "label=io.x-k8s.kind.role=worker" -q); do \
		docker exec -ti $$container bash -c 'cat /etc/hosts'; \
	done

# Cria o cluster e instala os pré requisitos
up_cluster: create_kind_cluster install_metallb helm

.PHONY: venv create_kind_cluster delete_cluster stop_cluster start_cluster config_hosts validate_hosts

 