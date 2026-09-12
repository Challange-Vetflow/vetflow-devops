# ============================================================
# FIAP DevOps Sprint 3 — 2026 (ACR + ACI + PostgreSQL)
# ============================================================

# ── LOCAL — Criar infraestrutura na Azure ─────────────────
chmod +x criacao.sh
sed -i 's/\r$//' criacao.sh
./criacao.sh
# Pede a senha do banco no terminal (ou usa DB_PASSWORD/.env, se existir)
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
# LOGIN — a API agora exige autenticação (Spring Security) em
# TODAS as rotas /api/**, exceto /api/auth/**. Sem isso, POST/PUT/
# DELETE/GET em /api/pets, /api/tutors etc. retornam 401/403.
# Usuário de teste já vem na carga inicial do Flyway (V3__seed_data):
#   email: vet@vetflow.com | senha: senha123 (perfil VET, acessa tudo)
# ============================================================

# ── STEP — Login (no Postman) ─────────────────────────────
# Método : POST
# URL    : http://<FQDN>:8080/api/auth/login
# Body (raw JSON):
# {
#   "email": "vet@vetflow.com",
#   "senha": "senha123"
# }
# Esperado: 200 OK + cookie de sessão (JSESSIONID) salvo automaticamente
# pelo Postman (cookie jar liga por padrão). Todas as chamadas seguintes
# no mesmo Postman reaproveitam esse cookie.

# ============================================================
# CRUD via Postman + confirmação no banco após cada operação
# (psql executado dentro do próprio container do banco)
# ============================================================

# ── STEP — POST Tutor ─────────────────────────────────────
# No Postman (com o cookie de login já ativo):
#   Método : POST
#   URL    : http://<FQDN>:8080/api/tutors
#   Body (raw JSON):
# {
#   "name": "Carlos Silva",
#   "email": "carlos.silva.novo@email.com",
#   "phone": "11911111111"
# }
# Esperado: 201 Created

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT id, name, email, phone, active FROM cv_tutors;\""

# ── STEP — POST Pet (associado ao tutor criado acima, ex.: id 3) ──
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
#   "tutorId": 3
# }
# Esperado: 201 Created

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT id, name, species, breed, tutor_id FROM cv_pets;\""

# ── STEP — GET Pets ────────────────────────────────────────
# No Postman:
#   Método : GET
#   URL    : http://<FQDN>:8080/api/pets
# Esperado: 200 OK, com o pet recém-criado no array

# ── STEP — PUT Pet (atualizar) ────────────────────────────
# No Postman:
#   Método : PUT
#   URL    : http://<FQDN>:8080/api/pets/{id do pet criado}
#   Body (raw JSON):
# {
#   "name": "Rex",
#   "species": "DOG",
#   "breed": "Golden Retriever",
#   "birthDate": "2022-03-15",
#   "weightKg": 13.0,
#   "tutorId": 3
# }
# Esperado: 200 OK com "breed": "Golden Retriever"

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT id, name, breed FROM cv_pets WHERE id = <id do pet>;\""

# ── STEP — DELETE Pet ─────────────────────────────────────
# No Postman:
#   Método : DELETE
#   URL    : http://<FQDN>:8080/api/pets/{id do pet criado}
# Esperado: 204 No Content

# Confirmar no banco:
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT id, name FROM cv_pets;\""

# ── STEP — JOIN final (evidência de integração total) ─────
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db \
  --exec-command "psql -U vetflow -d vetflowdb -c \"SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;\""

# ── LOCAL — Remoção ────────────────────────────────────────
chmod +x remocao.sh
./remocao.sh
# Quando perguntar "Tem certeza? (s/N):" — digite s e Enter

# Confirmar remoção:
az group show --name rg-vetflow
# Esperado: erro informando que o resource group não existe
