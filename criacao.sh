# =============================================================
# VetFlow – Script Azure CLI Completo
# Challenge FIAP 2026 – DevOps Tools & Cloud Computing
# =============================================================

# Variáveis principais
# chmod +x criacao.sh
# sed -i 's/\r$//' criacao.sh
# ./criacao.sh

GRUPO=vetflow
LOCATION=brazilsouth
USER=azureuser
PASSWORD='Fiap@Cloud2026'

RG=rg-$GRUPO
VNET=vnet-$GRUPO
SUBNET=subnet-$GRUPO
NSG=nsg-$GRUPO
VM=vm-$GRUPO

REPO_URL="https://github.com/Challange-Vetflow/vetflow-java"   

# 1. Resource Group
az group create \
  --name "$RG" \
  --location "$LOCATION" \
  --tags owner=$GRUPO environment=dev cost-center=fiap

# 2. VNet e Subnet
az network vnet create \
  --resource-group "$RG" \
  --name "$VNET" \
  --address-prefix 10.10.0.0/16 \
  --subnet-name "$SUBNET" \
  --subnet-prefix 10.10.1.0/24 \
  --tags owner=$GRUPO environment=dev cost-center=fiap

# 3. NSG
az network nsg create \
  --resource-group "$RG" \
  --name "$NSG" \
  --tags owner=$GRUPO environment=dev cost-center=fiap

# 4. Regras do NSG
az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name "$NSG" \
  --name allow-ssh \
  --protocol Tcp \
  --priority 1000 \
  --destination-port-range 22 \
  --access Allow

az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name "$NSG" \
  --name allow-http \
  --protocol Tcp \
  --priority 1001 \
  --destination-port-range 80 \
  --access Allow

az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name "$NSG" \
  --name allow-api-8080 \
  --protocol Tcp \
  --priority 1002 \
  --destination-port-range 8080 \
  --access Allow

az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name "$NSG" \
  --name allow-h2-console \
  --protocol Tcp \
  --priority 1003 \
  --destination-port-range 8181 \
  --access Allow

az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name "$NSG" \
  --name allow-h2-tcp \
  --protocol Tcp \
  --priority 1004 \
  --destination-port-range 9090 \
  --access Allow

az network vnet subnet update \
  --resource-group "$RG" \
  --vnet-name "$VNET" \
  --name "$SUBNET" \
  --network-security-group "$NSG"

# 5. Criar VM Ubuntu
az vm create \
  --resource-group "$RG" \
  --name "$VM" \
  --image Ubuntu2204 \
  --admin-username "$USER" \
  --admin-password "$PASSWORD" \
  --authentication-type password \
  --size Standard_D2s_v3 \
  --vnet-name "$VNET" \
  --subnet "$SUBNET" \
  --nsg "$NSG" \
  --public-ip-sku Standard \
  --tags owner=$GRUPO environment=dev cost-center=fiap

VM_IP=$(az vm show \
  --resource-group "$RG" \
  --name "$VM" \
  --show-details \
  --query publicIps \
  --output tsv)

# 6. Instalar Docker, Git e Nano
az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM" \
  --command-id RunShellScript \
  --scripts '
    export DEBIAN_FRONTEND=noninteractive
    echo ">>> Atualizando pacotes..."
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl git nano

    echo ">>> Instalando Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
         -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt-get update -y
    sudo apt-get install -y \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    # Remove necessidade de sudo no docker (padrão do professor)
    sudo usermod -aG docker azureuser && newgrp docker

    echo ">>> Docker instalado!"
    docker --version
    docker compose version
  '

# 7. Clonar repositório, fazer build e subir
az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM" \
  --command-id RunShellScript \
  --scripts "
    sudo -u azureuser bash -c '
      echo \">>> Clonando VetFlow...\"
      cd /home/azureuser
      git clone $REPO_URL vetflow || (cd vetflow && git pull)
      cd /home/azureuser/vetflow

      echo \">>> Criando volume nomeado para persistência do H2...\"
      docker volume create vetflow-h2-data

      echo \">>> Criando rede interna dos containers...\"
      docker network create vetflow-network || echo \"Rede já existe, continuando...\"

      echo \">>> Build da imagem do banco H2 (docker build)...\"
      docker build -t vetflow-h2-image -f Dockerfile.h2 .

      echo \">>> Build da imagem da API Spring Boot (docker build)...\"
      docker build -t vetflow-api-image -f Dockerfile .

      echo \">>> Subindo containers em background via Docker Compose...\"
      docker compose up -d

      echo \">>> Status dos containers:\"
      docker compose ps
    '
  "

# Resumo final
echo ""
echo "============================================="
echo " DEPLOY CONCLUÍDO COM SUCESSO!"
echo "============================================="
echo " IP Público da VM : $VM_IP"
echo ""
echo " Endpoints disponíveis:"
echo "   API VetFlow   -> http://$VM_IP:8080/api/pets"
echo "   Swagger UI    -> http://$VM_IP:8080/swagger-ui.html"
echo "   H2 Console    -> http://$VM_IP:8181"
echo "     JDBC URL    -> jdbc:h2:tcp://$VM_IP:9090/h2/opt/h2-data/vetflowdb"
echo ""
echo " Para acessar a VM:"
echo "   ssh $USER@$VM_IP"
echo ""
echo " Para verificar logs:"
echo "   docker logs -f vetflow-app"
echo "   docker logs -f vetflow-h2"
echo ""
echo " ATENÇÃO: Ao concluir a avaliação, DELETE os recursos:"
echo "   az group delete --name $RG --yes --no-wait"
echo "============================================="
