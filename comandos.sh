# ============================================================
# FIAP DevOps Sprint 3 — 2026 (ACR + ACI + PostgreSQL)
# ROTEIRO DE GRAVAÇÃO DO VÍDEO — siga esta ordem exata.
# Tudo marcado "[FORA DO VÍDEO]" acontece ANTES de apertar gravar.
# Tudo marcado "[GRAVANDO]" precisa aparecer na tela com você narrando.
# NADA entre o login (passo 6) e o SELECT final do CRUD (passo 7)
# pode ter corte de edição — o enunciado pune isso explicitamente.
# ============================================================


# ------------------------------------------------------------
# [FORA DO VÍDEO] Passo 0 — Preparação
# ------------------------------------------------------------
# - Teste o microfone e a resolução da gravação (mínimo 720p)
# - Feche programas/abas desnecessárias
# - Deixe o Postman aberto com o login e as requisições de CRUD
#   já montadas (só falta colar o FQDN, que ainda não existe)
# - Apague qualquer resíduo de teste local anterior:
docker compose down -v
rmdir /s /q build-app
del cookies.txt
# - Apague a pasta usada pra este roteiro se já existir (pra clonar
#   limpo na gravação, sem pasta antiga no meio do caminho)
# rmdir /s /q vetflow-devops    (rode isso UMA pasta acima, se necessário)


# ------------------------------------------------------------
# [GRAVANDO] Passo 1 — Clone do repositório (OBRIGATÓRIO começar assim)
# ------------------------------------------------------------
git clone https://github.com/Challange-Vetflow/vetflow-devops.git
cd vetflow-devops
# Não precisa clonar o vetflow-java manualmente aqui — o criacao.sh
# (passo 3) já faz esse clone sozinho, numa pasta temporária.


# ------------------------------------------------------------
# [GRAVANDO] Passo 2 — Autenticação na Azure
# ------------------------------------------------------------
az login


# ------------------------------------------------------------
# [GRAVANDO] Passo 3 — Criar toda a infraestrutura na Azure
# ------------------------------------------------------------
bash -c "sed -i 's/\r$//' criacao.sh remocao.sh"
bash criacao.sh
# Ele pede a senha do banco no terminal (não aparece na tela ao digitar).
# Deixe rodando até o final — cria Resource Group, ACR, builda as duas
# imagens (clonando o vetflow-java por conta própria), Storage/File Share,
# e sobe o Container Group no ACI.
# ANOTE o FQDN impresso no final — vai substituir <FQDN> daqui pra frente.


# ------------------------------------------------------------
# [GRAVANDO] Passo 4 — Verificar os containers e provar que a API
#                       não roda como root (item 8.2 do enunciado)
# ------------------------------------------------------------
az container show --resource-group rg-vetflow --name aci-vetflow --query "containers[].{name:name,state:instanceView.currentState.state}" -o table

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-app --exec-command "whoami"
# Esperado: vetflow (nunca root)


# ------------------------------------------------------------
# [GRAVANDO] Passo 5 — Volume nomeado (Azure File Share)
# ------------------------------------------------------------
az storage share show --name vetflow-db-data --account-name <STORAGE_ACCOUNT>
# Confirma que o Azure File Share existe e está montado em /var/lib/postgresql/data


# ============================================================
# [GRAVANDO — SEM CORTES A PARTIR DAQUI] Passos 6 e 7
# Login + CRUD completo com evidência de cada operação no banco.
# ============================================================

# ------------------------------------------------------------
# Passo 6 — LOGIN (obrigatório antes de qualquer /api/**)
# ------------------------------------------------------------
# No Postman:
#   Método : POST
#   URL    : http://<FQDN>:8080/api/auth/login
#   Body (raw JSON):
# {
#   "email": "vet@vetflow.com",
#   "senha": "senha123"
# }
# Esperado: 200 OK + cookie de sessão salvo automaticamente pelo Postman.
# Todas as chamadas seguintes reaproveitam esse cookie sozinhas.

# ------------------------------------------------------------
# Passo 7 — CRUD completo, uma operação por vez, cada uma
# seguida IMEDIATAMENTE do SELECT que prova ela no banco.
# ------------------------------------------------------------

# 7.1 CREATE Tutor
# Postman: POST http://<FQDN>:8080/api/tutors
# Body:
# {
#   "name": "Carlos Silva",
#   "email": "carlos.silva.novo@email.com",
#   "phone": "11911111111"
# }
# Esperado: 201 Created

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
# Dentro da sessão psql que abrir, digite:
#   SELECT id, name, email, phone FROM cv_tutors;
# Para sair: \q

# 7.2 CREATE Pet (troque tutorId pelo id retornado no passo 7.1)
# Postman: POST http://<FQDN>:8080/api/pets
# Body:
# {
#   "name": "Rex",
#   "species": "DOG",
#   "breed": "Labrador",
#   "birthDate": "2022-03-15",
#   "weightKg": 12.5,
#   "tutorId": 3
# }
# Esperado: 201 Created

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name, species, tutor_id FROM cv_pets;

# 7.3 READ — listar pets
# Postman: GET http://<FQDN>:8080/api/pets
# Esperado: 200 OK, com o pet recém-criado no array

# 7.4 UPDATE Pet (troque {id} pelo id do pet criado em 7.2)
# Postman: PUT http://<FQDN>:8080/api/pets/{id}
# Body:
# {
#   "name": "Rex",
#   "species": "DOG",
#   "breed": "Golden Retriever",
#   "birthDate": "2022-03-15",
#   "weightKg": 13.0,
#   "tutorId": 3
# }
# Esperado: 200 OK com "breed": "Golden Retriever"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name, breed FROM cv_pets WHERE id = <id do pet>;

# 7.5 DELETE Pet (troque {id})
# Postman: DELETE http://<FQDN>:8080/api/pets/{id}
# Esperado: 204 No Content

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name FROM cv_pets;

# 7.6 Evidência final de integração — JOIN tutor + pet
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email
#   FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;


# ------------------------------------------------------------
# [GRAVANDO] Passo 8 — Encerramento: remover os recursos da Azure
# ------------------------------------------------------------
bash remocao.sh
# Quando perguntar "Tem certeza? (s/N):" — digite s e Enter

az group show --name rg-vetflow
# Esperado: erro informando que o resource group não existe — PARE
# A GRAVAÇÃO só depois de mostrar esse erro na tela.
