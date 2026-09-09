# ============================================================
# FIAP DevOps Sprint 3 — 2026 (ACR + ACI + PostgreSQL)
# ============================================================

# ── LOCAL — Criar infraestrutura na Azure ─────────────────
chmod +x criacao.sh
sed -i 's/\r$//' criacao.sh
./criacao.sh
# Ao final, o script imprime o FQDN público e os endpoints

# ── Verificar containers do grupo (App + Banco) ───────────
az container show --resource-group rg-vetflow --name aci-vetflow --query "containers[].{name:name,state:instanceView.currentState.state}" -o table

# ── STEP — Provar que a API não roda como root ────────────
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-app --exec-command "whoami"
# Esperado: vetflow

# ── STEP — Volume nomeado (Azure File Share) ──────────────
az storage share show --name vetflow-db-data --account-name <STORAGE_ACCOUNT>
# Confirma que o Azure File Share existe e está montado em /var/lib/postgresql/data

# ============================================================
# CRUD via Postman + confirmação no banco após cada operação
# (psql executado dentro do próprio container do banco)
# ============================================================

# ── STEP — POST Tutor ─────────────────────────────────────
# No Postman:
#   Método : POST
#   URL    : http://<FQDN>:8080/api/tutors
#   Body (raw JSON):
# {
#   "name": "Carlos Silva",
#   "email": "carlos@email.com",
#   "phone": "11911111111"
# }
# Esperado: 201 Created

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT * FROM cv_tutors;\""

# ── STEP — POST Pet 1 (Rex) ───────────────────────────────
# No Postman:
#   Método : POST
#   URL    : http://<FQDN>:8080/api/pets
#   Body (raw JSON):
# {
#   "name": "Rex",
#   "species": "DOG",
#   "breed": "Labrador",
#   "birthDate": "2022-03-15",
#   "weightKg": 12.5,
#   "tutorId": 1
# }
# Esperado: 201 Created

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT * FROM cv_pets;\""

# ── STEP — POST Pet 2 (Mia) ───────────────────────────────
# No Postman:
#   Método : POST
#   URL    : http://<FQDN>:8080/api/pets
#   Body (raw JSON):
# {
#   "name": "Mia",
#   "species": "CAT",
#   "breed": "Siamês",
#   "birthDate": "2021-07-10",
#   "weightKg": 4.2,
#   "tutorId": 1
# }
# Esperado: 201 Created

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT * FROM cv_pets;\""

# ── STEP — GET Pets ────────────────────────────────────────
# No Postman:
#   Método : GET
#   URL    : http://<FQDN>:8080/api/pets
#   Sem body
# Esperado: 200 OK com Rex e Mia no array

# ── STEP — PUT Pet (atualizar Rex) ────────────────────────
# No Postman:
#   Método : PUT
#   URL    : http://<FQDN>:8080/api/pets/1
#   Body (raw JSON):
# {
#   "name": "Rex",
#   "species": "DOG",
#   "breed": "Golden Retriever",
#   "birthDate": "2022-03-15",
#   "weightKg": 13.0,
#   "tutorId": 1
# }
# Esperado: 200 OK com "breed": "Golden Retriever"

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT * FROM cv_pets WHERE id = 1;\""

# ── STEP — DELETE Pet (remover Rex) ───────────────────────
# No Postman:
#   Método : DELETE
#   URL    : http://<FQDN>:8080/api/pets/1
#   Sem body
# Esperado: 204 No Content

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT * FROM cv_pets;\""

# ── STEP — JOIN final ──────────────────────────────────────
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;\""

# ── LOCAL — Remoção ────────────────────────────────────────
chmod +x remocao.sh
./remocao.sh
# Quando perguntar "Tem certeza? (s/N):" — digite s e Enter

# Confirmar remoção:
az group show --name rg-vetflow
# Esperado: erro informando que o resource group não existe
