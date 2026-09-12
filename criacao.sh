#!/bin/bash
# =============================================================
# VetFlow – Script Azure CLI Completo (Sprint 3)
# Challenge FIAP 2026 – DevOps Tools & Cloud Computing
# Opção escolhida: ACR + ACI (App e Banco 100% containerizados, todos os recursos criados via Azure CLI)
# =============================================================
# chmod +x criacao.sh
# sed -i 's/\r$//' criacao.sh
# ./criacao.sh
set -e

# ── Variáveis principais ─────────────────────────────────────
GRUPO=vetflow
LOCATION=eastus

RG=rg-$GRUPO
SUFFIX=$RANDOM                         
ACR=acr${GRUPO}${SUFFIX}               
STORAGE=st${GRUPO}${SUFFIX}            
SHARE=${GRUPO}-db-data                 
ACI=aci-${GRUPO}
DNS_LABEL=${GRUPO}-${SUFFIX}

DB_NAME=vetflowdb
DB_USER=vetflow

# Senha do banco NUNCA fica craveada no script.
# Prioridade: variável de ambiente DB_PASSWORD -> arquivo .env local -> pede no terminal.
if [ -z "$DB_PASSWORD" ] && [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi
if [ -z "$DB_PASSWORD" ]; then
  read -s -p "Senha do banco Postgres (não será exibida): " DB_PASSWORD
  echo ""
fi
if [ -z "$DB_PASSWORD" ]; then
  echo "ERRO: DB_PASSWORD não pode ser vazia."
  exit 1
fi

# Repositórios do projeto
REPO_JAVA_URL="https://github.com/Challange-Vetflow/vetflow-java.git"
REPO_DEVOPS_URL="https://github.com/Challange-Vetflow/vetflow-devops.git"

WORKDIR=$(mktemp -d)

echo " 1) Resource Group"
az group create \
  --name "$RG" \
  --location "$LOCATION" \
  --tags owner=$GRUPO environment=dev cost-center=fiap

echo " 2) Azure Container Registry (ACR)"
az acr create \
  --resource-group "$RG" \
  --name "$ACR" \
  --sku Basic \
  --admin-enabled true \
  --tags owner=$GRUPO environment=dev cost-center=fiap

ACR_LOGIN_SERVER=$(az acr show --name "$ACR" --query loginServer --output tsv)
ACR_USER=$(az acr credential show --name "$ACR" --query username --output tsv)
ACR_PASS=$(az acr credential show --name "$ACR" --query "passwords[0].value" --output tsv)

echo " 3) Montando contexto de build (repo Java + patches de DevOps)"
git clone "$REPO_JAVA_URL" "$WORKDIR/build-app"
cp Dockerfile "$WORKDIR/build-app/Dockerfile"
cp -r db-patches "$WORKDIR/build-app/db-patches"

echo " 4) Build da imagem da API (via ACR Tasks — build ocorre na nuvem)"
az acr build \
  --registry "$ACR" \
  --image vetflow-api:v1 \
  "$WORKDIR/build-app"

echo " 5) Build da imagem do banco PostgreSQL (via ACR Tasks)"
az acr build \
  --registry "$ACR" \
  --image vetflow-db:v1 \
  --file Dockerfile.postgres \
  .

echo " 6) Storage Account + Azure File Share (volume nomeado do banco)"
az storage account create \
  --resource-group "$RG" \
  --name "$STORAGE" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --tags owner=$GRUPO environment=dev cost-center=fiap

STORAGE_KEY=$(az storage account keys list \
  --resource-group "$RG" \
  --account-name "$STORAGE" \
  --query "[0].value" --output tsv)

az storage share create \
  --name "$SHARE" \
  --account-name "$STORAGE" \
  --account-key "$STORAGE_KEY"

echo " 7) Container Group no ACI (App + Banco, ambos via CLI)"
cat > "$WORKDIR/containergroup.yaml" << EOF
apiVersion: '2021-10-01'
location: $LOCATION
name: $ACI
properties:
  osType: Linux
  restartPolicy: Always
  ipAddress:
    type: Public
    dnsNameLabel: $DNS_LABEL
    ports:
    - protocol: tcp
      port: 8080
  containers:
  - name: vetflow-db
    properties:
      image: $ACR_LOGIN_SERVER/vetflow-db:v1
      resources:
        requests:
          cpu: 1
          memoryInGb: 1.5
      ports:
      - port: 5432
      environmentVariables:
      - name: POSTGRES_DB
        value: $DB_NAME
      - name: POSTGRES_USER
        value: $DB_USER
      - name: POSTGRES_PASSWORD
        secureValue: '$DB_PASSWORD'
      - name: PGDATA
        value: /var/lib/postgresql/data/pgdata
      volumeMounts:
      - name: dbdata
        mountPath: /var/lib/postgresql/data
  - name: vetflow-app
    properties:
      image: $ACR_LOGIN_SERVER/vetflow-api:v1
      resources:
        requests:
          cpu: 1
          memoryInGb: 1.5
      ports:
      - port: 8080
      environmentVariables:
      - name: SPRING_DATASOURCE_URL
        value: jdbc:postgresql://localhost:5432/$DB_NAME
      - name: SPRING_DATASOURCE_USERNAME
        value: $DB_USER
      - name: SPRING_DATASOURCE_PASSWORD
        secureValue: '$DB_PASSWORD'
  imageRegistryCredentials:
  - server: $ACR_LOGIN_SERVER
    username: $ACR_USER
    password: '$ACR_PASS'
  volumes:
  - name: dbdata
    azureFile:
      shareName: $SHARE
      storageAccountName: $STORAGE
      storageAccountKey: '$STORAGE_KEY'
tags:
  owner: $GRUPO
type: Microsoft.ContainerInstance/containerGroups
EOF

az container create \
  --resource-group "$RG" \
  --file "$WORKDIR/containergroup.yaml"

FQDN=$(az container show \
  --resource-group "$RG" \
  --name "$ACI" \
  --query ipAddress.fqdn --output tsv)

cat > .ultimo-deploy.env << EOF
RG=$RG
ACR=$ACR
STORAGE=$STORAGE
ACI=$ACI
FQDN=$FQDN
EOF

rm -rf "$WORKDIR"

echo "============================================="
echo " DEPLOY CONCLUÍDO COM SUCESSO!"
echo "============================================="
echo " Resource Group : $RG"
echo " ACR             : $ACR_LOGIN_SERVER"
echo " Container Group : $ACI"
echo " Endereço público: $FQDN"
echo ""
echo " Endpoints disponíveis:"
echo "   API VetFlow -> http://$FQDN:8080/api/pets"
echo "   Swagger UI  -> http://$FQDN:8080/swagger-ui.html"
echo ""
echo " Para verificar logs:"
echo "   az container logs --resource-group $RG --name $ACI --container-name vetflow-app"
echo "   az container logs --resource-group $RG --name $ACI --container-name vetflow-db"
echo ""
echo " ATENÇÃO: Ao concluir, DELETE os recursos:"
echo "   ./remocao.sh"
echo "============================================="