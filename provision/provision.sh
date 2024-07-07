#!/bin/bash

USER="devops"
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbC7fGQkGTjXERSAwLq7co5QXvahoXdG93m/Zx/+W1v+eme1ZohTCyi41MkcAJDr2KHSibwo6PE7WWjgYFAsZg/PNE6igI0D5VzC63T48tsK6ffxGFYy3rl0B/VyvHdfqe/vcw44zn6HRjF2q01DXV2NeSBZuJL+diclAcB+2jhrjha9iHWxxkJuxwFl76bAfhVdtNE6yC0It+aUtJLPT1ppcviGKpIyN1w6pGvWxk1pV+Pf6CdqU1FK05FeSPK+f34bSgIOin/DCNN6oBFgX2V5H/+Gf290bmlT9YGVSNZ0Y/HCK3Cetl3A+1j4YtbyANA3ju5mWeKeG8svzfphVRuOlKtwL+pVSrcnJuLIJqf4Nsq3PBAaPt9xzHk5vkmVfaMftQU0OXrgYhP2455SuuhpJe4LG3uyncRAXCK1AX7OoDI5jY6C4pZM00Vv+FOu5BYZLn28vr73B/rHBMzjnOCiouLbrYiCSL9VGtLcPTx4haoTWbm7fZSakyUhITI6M= alissonoliveira@ALISSON"
PACKAGES="curl gnupg2 gpg software-properties-common apt-transport-https ca-certificates jq net-tools make"

# Opcional interface
# sudo apt update
# sudo apt install -y xfce4 xfce4-goodies
# sudo apt install -yvirtualbox-guest-additions-iso


# Verifica se a chave SSH já existe no arquivo authorized_keys do usuário vagrant
if ! grep -q -i "$SSH_KEY" /home/vagrant/.ssh/authorized_keys; then
    echo "Escrevendo a chave ssh no arquivo authorized_keys"
    echo "$SSH_KEY" >> /home/vagrant/.ssh/authorized_keys
else
    echo "Chave ssh já existente no arquivo authorized_keys"
fi

# Verifica se o usuário especificado existe
if ! getent passwd "$USER" > /dev/null 2>&1; then
    echo "Usuário: $USER não encontrado. Criando usuário..."
    sleep 5
    sudo useradd -m -d /home/"$USER" -s /bin/bash "$USER"
else
    echo "Usuário: $USER encontrado"
fi

# Verifica se o arquivo sudoers para o usuário existe
if [ ! -f /etc/sudoers.d/$USER ]; then
    echo "Criando arquivo sudoers para o usuário $USER"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER > /dev/null
else
    echo "Arquivo sudoers já existente para o usuário $USER"
fi

# Verifica se o diretório .ssh do usuário existe
if [ ! -f /home/$USER/.ssh/authorized_keys ]; then
    echo "Copiando o diretório .ssh do usuário vagrant para o usuário: $USER"
    sudo cp -r /home/vagrant/.ssh /home/$USER/
    sudo chown -R "$USER:$USER" /home/$USER/.ssh
else
    echo "Diretório .ssh já existente para o usuário $USER"
fi

echo "Atualizando pacotes..."
sudo apt update -y

echo "Desabilitando a swap"
sudo sed -i 's/^\([^#]*\bswap\b\)/#\1/g' /etc/fstab
sudo swapoff -a


echo "Atualizando o kernel... Correção: control-plane node setup not starting · Issue #2744 · kubernetes-sigs/kind"
echo fs.inotify.max_user_watches=655360 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_user_instances=1280 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p



echo "Atualizando pacotes..."
sudo apt update -y
sudo apt install -y $PACKAGES


echo "Instalando o docker"
wget -O install_docker.sh https://get.docker.com
chmod +x install_docker.sh
sudo bash -c './install_docker.sh'

echo "Iniciando o serviço do Docker"
sudo systemctl restart docker
sleep 3

echo "Habilitando o Docker na inicialização do sistema"
sudo systemctl enable docker

echo "Desabilitando IPV6 do docker"
cat << EOF | sudo tee -a /etc/docker/daemon.json
{
  "ipv6": false
}
EOF

echo "Incluindo os usuários no grupo do Docker"
USERS=('vagrant' 'devops')
# Verifica se o grupo docker existe
if ! getent group docker > /dev/null 2>&1; then
    echo "O grupo 'docker' não existe no sistema"
    exit 1
fi

# Percorre a lista e adicina os usuários no grupo do Docker
for user in "${USERS[@]}"; do
    if getent passwd "$user" > /dev/null 2>&1; then
        if groups "$user" | grep -q "\bdocker\b"; then
            echo "Usuário $user já está no grupo do Docker"
        else
            echo "Adicionando o usuário $user ao grupo do Docker"
            sudo usermod -aG docker "$user" 2>/dev/null
        fi
    else
        echo "Usuário $user não encontrado no sistema"
    fi
done


echo "Atualizando pacotes..."
sudo apt update -y

echo "Instalando o Kind"
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "Instalando os Tools do K8s"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Instalando o helm"
# wget -O install_helm.sh https://git.io/get_helm.sh
# chmod +x install_helm.sh
# sudo bash -c './install_helm.sh'
#Versão 3 do helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash  


git clone https://github.com/alissonoliveira0607/stack-all-devops.git
cd stack-all-devops
git checkout dev
sleep 6

echo "Ajustando o pool de rede para o metalllb"
sed -i 's/172.21.0.*/172.18.0.50-172.18.0.70/g' manifests/metallb-pool.yaml
sed -i 's/172.21.0.*/172.18.0.50-172.18.0.70/g' manifests/setup-hosts.yaml

echo "Ajustando permissões do helm"
sudo chmod go-rw /home/$USER/.kube/config 2>/dev/null
