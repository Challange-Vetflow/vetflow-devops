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
| Banco | PostgreSQL 16 (containerizado — imagem `Dockerfile.postgres`) |
| Documentação | Swagger / OpenAPI (springdoc) |
| Container | Docker + Docker Compose (local) / Azure Container Registry + Azure Container Instances (nuvem) |
| Cloud | Microsoft Azure — ACR + ACI (`brazilsouth`) |
| Infra como código | Azure CLI (`az acr build`, `az container create`) |

> **Nota de migração (Sprint 3):** o banco foi migrado de H2 para PostgreSQL
> sem nenhuma alteração no repositório Java (pom.xml/entidades). O driver
> JDBC do Postgres é injetado no `.jar` já compilado como um passo extra do
> `Dockerfile` (ver seção "Como Executar"), e a conexão é configurada
> inteiramente por variáveis de ambiente — mantendo a mudança 100% no
> escopo de DevOps.

---

## Arquitetura Macro na Nuvem

![Arquitetura VetFlow](vetflow.png)

| Componente | Descrição |
|-----------|-----------|
| Azure Container Registry (ACR) | Registry das imagens `vetflow-api` e `vetflow-db`, geradas via `az acr build` (build ocorre na nuvem) |
| Container Group (ACI) — `aci-vetflow` | Grupo com 2 containers na mesma rede interna (localhost) — IP público com DNS label na porta 8080 |
| vetflow-app | Container Spring Boot — porta 8080 — usuário `vetflow` (não root) |
| vetflow-db | Container PostgreSQL 16 — porta 5432 (interna, acessível via `localhost` pelo container da API) |
| Azure File Share (`vetflow-db-data`) | Volume nomeado — persiste `/var/lib/postgresql/data` fora do ciclo de vida do container |
| Storage Account | Hospeda o Azure File Share usado como volume persistente |

---

## Estrutura do Repositório

```
vetflow-devops/
├── Dockerfile           ← Imagem da API Spring Boot (com patch do driver Postgres)
├── Dockerfile.postgres  ← Imagem do banco PostgreSQL (com script_bd.sql pré-carregado)
├── script_bd.sql        ← DDL das tabelas core (cv_tutors, cv_pets)
├── docker-compose.yml   ← Orquestra os dois containers (teste local)
├── criacao.sh           ← Script Azure CLI completo (ACR + ACI)
├── remocao.sh           ← Remove recursos Azure após avaliação
├── comandos.sh          ← Roteiro de comandos usado na gravação do vídeo
└── docs/
    └── VetFlow API.postman_collection.json

vetflow-java/            ← Repositório separado com o código-fonte (não alterado)
├── pom.xml
└── src/
    └── main/java/fiap/com/br/vetflow/
        ├── config/       SwaggerConfig
        ├── controller/   PetController, TutorController, ...
        ├── dto/
        ├── entity/
        ├── repository/
        └── service/
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

> **Importante:** o repositório do código Java (`vetflow-java`) não é alterado
> em nenhum momento. A migração de banco (H2 → PostgreSQL) acontece
> inteiramente neste repositório de DevOps: o `Dockerfile` clona o código
> Java original, compila com o `pom.xml` original (`mvn clean package`) e,
> **depois** de compilado, injeta o driver JDBC do PostgreSQL diretamente
> no `.jar` (um jar Spring Boot é só um `.zip` com `BOOT-INF/lib/*.jar`, e o
> loader inclui automaticamente tudo que está lá no classpath). A conexão
> com o banco é configurada só por variáveis de ambiente.

### Opção 1 — Docker Compose local (validar antes de subir pra nuvem)

```bash
git clone https://github.com/Challange-Vetflow/vetflow-devops.git
cd vetflow-devops

# Clonar o código Java para dentro da pasta (contexto de build precisa dele)
git clone https://github.com/Challange-Vetflow/vetflow-java.git build-app
cp Dockerfile build-app/Dockerfile

# Criar a rede externa usada pelo compose
docker network create vetflow-network

# Subir banco + API com um único comando
docker compose up --build -d

# Verificar containers em background
docker compose ps

# Testar
curl http://localhost:8080/api/pets
# Swagger: http://localhost:8080/swagger-ui.html
```

Confirmar dados direto no banco:

```bash
docker exec -it vetflow-db psql -U vetflow -d vetflowdb -c "SELECT * FROM cv_pets;"
```

Parar tudo:

```bash
docker compose down
```

---

### Opção 2 — Azure CLI: ACR + ACI (provisionamento completo em nuvem)

Todos os recursos (imagens da API e do banco, registry, storage e os
containers em execução) são criados via Azure CLI — nada é criado
manualmente pelo Portal.

```bash
# 1. Autenticar no Azure
az login

# 2. Converter quebras de linha (se necessário — Windows)
sed -i 's/\r$//' criacao.sh

# 3. Dar permissão de execução
chmod +x criacao.sh

# 4. Executar o provisionamento
./criacao.sh
```

O script `criacao.sh` executa, em sequência:

1. Cria o Resource Group
2. Cria o Azure Container Registry (ACR)
3. Builda a imagem da API via `az acr build` (clona o `vetflow-java`,
   copia o `Dockerfile` deste repositório, build ocorre na nuvem)
4. Builda a imagem do banco via `az acr build` (usa `Dockerfile.postgres`
   + `script_bd.sql`)
5. Cria a Storage Account + Azure File Share (volume nomeado do Postgres)
6. Cria o Container Group no ACI com os dois containers (`vetflow-app` e
   `vetflow-db`), expõe a porta 8080 publicamente com DNS label, e monta
   o File Share em `/var/lib/postgresql/data`

Ao final, o script imprime o endereço público (FQDN) e os endpoints.

**Após a avaliação — remover todos os recursos:**

```bash
chmod +x remocao.sh && ./remocao.sh
# ou diretamente:
az group delete --name rg-vetflow --yes --no-wait
```

---

## Troubleshooting

```bash
# Local (Docker Compose)
docker compose ps
docker logs -f vetflow-app
docker logs -f vetflow-db
docker exec -it vetflow-app bash
docker compose down -v   # remove tudo, inclusive o volume

# Nuvem (ACI)
az container show --resource-group rg-vetflow --name aci-vetflow -o table
az container logs --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-app
az container logs --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-app --exec-command "bash"
```

---

## Scripts de Infraestrutura

| Arquivo | Descrição |
|---------|-----------|
| `Dockerfile` | Imagem da API Spring Boot (Maven + Java 17, usuário não-root, com patch do driver JDBC do Postgres) |
| `Dockerfile.postgres` | Imagem do banco PostgreSQL 16, com `script_bd.sql` pré-carregado |
| `script_bd.sql` | DDL das tabelas core (`cv_tutors`, `cv_pets`) + massa de dados inicial |
| `docker-compose.yml` | Orquestra API + Postgres com rede e volume nomeado (uso local) |
| `criacao.sh` | Script Azure CLI completo: ACR, build das imagens, Storage/File Share, Container Group (ACI) |
| `remocao.sh` | Remove todos os recursos Azure após a avaliação |
| `comandos.sh` | Roteiro de comandos passo a passo usado na gravação do vídeo demonstrativo |

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