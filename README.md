# VetFlow API — Challenge FIAP 2026

Solução desenvolvida para o **Challenge FIAP 2026** em parceria com a **CLYVO VET**.  
Tema: **Continuidade do cuidado e engajamento na jornada de saúde do pet**.

---

## Integrantes do Grupo

| Nome | RM | Turma |
|------|----|-------|
| Andrei de Paiva Gibbini | 563061 | 2TDSPF |
| Pedro Sakai Silva Zambaca | 565956 | 2TDSPF |
| Pedro Santos Pequini | 561842 | 2TDSPF |
| Arthur Câmara | 562310 | 2TDSPG |
| Diogo Cunha | 563654 | 2TDSPF |

---

## Problema de Negócio

Tutores de pets só acionam clínicas veterinárias em situações reativas (urgência, vacina
vencida, sintoma agudo). Isso gera:

- **Baixa recorrência** e menor LTV para as clínicas
- **Histórico clínico fragmentado** sem continuidade entre consultas
- **Abandono de tratamentos** e vacinas vencidas sem alertas preventivos

## Benefícios da Solução para o Negócio

API REST que centraliza o histórico clínico do pet, organiza agendamentos, registra
vacinas e medicamentos, e serve de backend para app mobile e dashboard clínico.

- ✅ Aumento da recorrência de consultas preventivas
- ✅ Redução de abandono de tratamentos por falta de lembretes
- ✅ Histórico longitudinal estruturado por pet e clínica
- ✅ Base escalável para integração com mobile, WhatsApp e IA

---

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Backend | Spring Boot 3.4, Spring Data JPA, Spring Cache |
| Banco | H2 em modo servidor TCP (`oscarfonts/h2`) |
| Documentação | Swagger / OpenAPI (springdoc) |
| Container | Docker + Docker Compose |
| Cloud | Microsoft Azure (VM Linux — `brazilsouth`) |
| Infra como código | Azure CLI |

---

## Arquitetura Macro na Nuvem

![Arquitetura VetFlow](vetflow.png)

| Componente | Descrição |
|-----------|-----------|
| NSG | Firewall Azure — portas 22, 80, 8080, 8181, 9090 |
| VM Ubuntu 22.04 | Standard_D2s_v3 — região Brazil South |
| vetflow-app | Container Spring Boot — porta 8080 — usuário vetflow (não root) |
| vetflow-h2 | Container H2 — TCP interno :1521 (externo :9090) — Web Console :81 (externo :8181) |
| vetflow-h2-data | Volume nomeado — persiste dados em /opt/h2-data |
| vetflow-network | Rede bridge externa conectando os dois containers |

---

## Estrutura do Repositório

```
vetflow-java/
├── Dockerfile          ← Imagem da API Spring Boot
├── Dockerfile.h2       ← Imagem do banco H2
├── docker-compose.yml  ← Orquestra os dois containers
├── criacao.sh          ← Script Azure CLI completo
├── remocao.sh          ← Remove recursos Azure após avaliação
├── pom.xml
├── src/
│   └── main/java/fiap/com/br/vetflow/
│       ├── config/       SwaggerConfig
│       ├── controller/   PetController, TutorController, ...
│       ├── dto/
│       ├── entity/
│       ├── repository/
│       └── service/
└── docs/
    └── VetFlow API.postman_collection.json
```

---

## Rotas da API

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/pets` | Lista todos os pets (paginado) |
| GET | `/api/pets/{id}` | Busca pet por ID |
| GET | `/api/pets/by-tutor/{tutorId}` | Pets de um tutor |
| GET | `/api/pets/by-species?species=DOG` | Filtra por espécie |
| POST | `/api/pets` | Cadastra novo pet |
| PUT | `/api/pets/{id}` | Atualiza dados do pet |
| DELETE | `/api/pets/{id}` | Remove pet |
| GET | `/api/tutors` | Lista tutores (paginado + ordenado) |
| GET | `/api/tutors/search?name=` | Busca tutor por nome |
| POST | `/api/tutors` | Cadastra tutor |
| PUT | `/api/tutors/{id}` | Atualiza tutor |
| DELETE | `/api/tutors/{id}` | Remove tutor |
| GET | `/api/vaccines` | Lista vacinas (paginado) |
| GET | `/api/vaccines/expired` | Vacinas vencidas |
| GET | `/api/vaccines/due-soon` | Vacinas a vencer em breve |
| POST | `/api/vaccines` | Registra vacina |
| GET | `/api/appointments` | Lista consultas |
| GET | `/api/appointments/pending` | Consultas pendentes |
| POST | `/api/appointments` | Agenda consulta |
| GET | `/api/medications` | Lista medicamentos |
| GET | `/api/medications/active` | Medicamentos em uso |
| POST | `/api/medications` | Registra medicamento |
| GET | `/api/clinics` | Lista clínicas |
| POST | `/api/clinics` | Cadastra clínica |

**Documentação interativa:** `http://localhost:8080/swagger-ui.html`

---

## Como Executar (How To Install)

### Opção 1 — Local (desenvolvimento rápido)

```bash
git clone https://github.com/Challange-Vetflow/vetflow-java.git
cd vetflow-java

./mvnw spring-boot:run

# Swagger:    http://localhost:8080/swagger-ui.html
# H2 Console: http://localhost:8080/h2-console
#             JDBC URL: jdbc:h2:mem:vetflowdb
```

---

### Opção 2 — Docker (padrão do lab — build + run manual)

#### Passo 1 — Criar a rede e o volume

```bash
docker network create vetflow-network
docker volume create vetflow-h2-data
```

#### Passo 2 — Build e run do banco H2

```bash
# Build da imagem do banco
docker build -t vetflow-h2-image -f Dockerfile.h2 .

# Subir o container do banco em background
docker run --name vetflow-h2 -d \
  --network vetflow-network \
  -p 9090:1521 \
  -p 8181:81 \
  -v vetflow-h2-data:/opt/h2-data \
  vetflow-h2-image

# Verificar logs
docker logs -f vetflow-h2
```

#### Passo 2.1 — Pré-criar o banco H2 ⚠️

> **Atenção:** A imagem `oscarfonts/h2` não cria o banco automaticamente por razões de segurança.  
> É obrigatório executar este comando **uma única vez** após subir o container H2,  
> antes de iniciar a API.

```bash
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT 1;"
# Esperado: 1 (confirma que o banco foi criado com sucesso)
```

#### Passo 3 — Build e run da API

```bash
# Build da imagem da API
docker build -t vetflow-api-image -f Dockerfile .

# Subir o container da API em background
docker run --name vetflow-app -d \
  --network vetflow-network \
  -p 8080:8080 \
  vetflow-api-image

# Verificar logs
docker logs -f vetflow-app
```

#### Passo 4 — Testar

```bash
# Listar pets
curl http://localhost:8080/api/pets

# Swagger
# http://localhost:8080/swagger-ui.html

# H2 Console Web
# http://localhost:8181
# JDBC URL: jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb
```

---

### Opção 3 — Docker Compose (forma simplificada)

```bash
git clone https://github.com/Challange-Vetflow/vetflow-java.git
cd vetflow-java

# Sobe banco + API com um único comando
docker compose up --build -d

# Verificar containers
docker compose ps

# ⚠️ Pré-criar o banco H2 (necessário na primeira execução)
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT 1;"
# Reiniciar a API após criar o banco:
docker restart vetflow-app

# Parar tudo
docker compose down
```

---

### Opção 4 — Azure CLI (provisionamento completo em nuvem)

```bash
# 1. Autenticar no Azure
az login

# 2. Converter quebras de linha (se necessário — Windows)
sed -i 's/\r$//' criacao.sh

# 3. Dar permissão de execução
chmod +x criacao.sh

# 4. Executar o provisionamento
./criacao.sh

# O script exibe o IP público e todos os endpoints ao final
```

**Após a avaliação — remover todos os recursos:**

```bash
chmod +x remocao.sh && ./remocao.sh
# ou diretamente:
az group delete --name rg-Vetflow --yes --no-wait
```

---

## Troubleshooting

```bash
# Ver containers em execução
docker ps

# Logs da API
docker logs -f vetflow-app

# Logs do banco H2
docker logs -f vetflow-h2

# Entrar no container da API
docker exec -it vetflow-app bash

# Remover tudo e recomeçar
docker rm -f vetflow-app vetflow-h2
docker volume rm vetflow-h2-data
docker network rm vetflow-network
```

---

## Scripts de Infraestrutura

| Arquivo | Descrição |
|---------|-----------|
| `Dockerfile` | Imagem da API Spring Boot (Maven + Java 17, usuário não-root) |
| `Dockerfile.h2` | Imagem do banco H2 (oscarfonts/h2) |
| `docker-compose.yml` | Orquestra API + H2 com rede e volume nomeado |
| `criacao.sh` | Script Azure CLI completo: VM, NSG, VNet, Docker, build e deploy |
| `remocao.sh` | Remove todos os recursos Azure após a avaliação |

---

## Collection Postman

Importe o arquivo `docs/VetFlow API.postman_collection.json` no Postman.

> ⚠️ **Atenção:** O arquivo JSON original da collection contém URLs fixas apontando para `http://localhost:8080`. Antes de usar, é necessário:
>
> 1. No Postman, clique no ícone de **Environments** → **Add**
> 2. Nomeie o ambiente como **VetFlow Azure**
> 3. Adicione a variável:
>    - **Variable:** `baseUrl`
>    - **Initial Value:** `http://<IP_DA_VM>:8080`
> 4. Clique em **Save** e selecione o ambiente **VetFlow Azure**
> 5. Nas requisições da collection, substitua a URL fixa por `{{baseUrl}}/api/...`
>
> Para testes locais use `baseUrl = http://localhost:8080`.  
> Para testes em nuvem use `baseUrl = http://<VM_IP>:8080`.

> ⚠️ **Atenção — POST e PUT de Pet:** Os campos `birthDate` e `weightKg` são obrigatórios pela API mas não estão no JSON original da collection. Sempre inclua esses campos ao usar **Criar Pet** ou **Atualizar Pet**:
>
> ```json
> {
>   "name": "Rex",
>   "species": "DOG",
>   "breed": "Labrador",
>   "birthDate": "2022-03-15",
>   "weightKg": 12.5,
>   "tutorId": 1
> }
> ```