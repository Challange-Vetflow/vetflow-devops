# ============================================================
# FIAP DevOps Sprint 1 — 2026
# ============================================================

# ── AZURE CLOUD SHELL — Criar infraestrutura ──────────────
chmod +x criacao.sh
sed -i 's/\r$//' criacao.sh
./criacao.sh

# ── AZURE CLOUD SHELL — Conectar na VM ────────────────────
ssh azureuser@<IP>

# ── DENTRO DA VM ──────────────────────────────────────────
cd /home/azureuser/vetflow

# ── STEP 5 — Verificar containers em background ───────────
docker compose ps

# ── STEP 6 — Provar que não roda como root ────────────────
docker exec vetflow-app whoami
# Esperado: vetflow

# ── STEP 7 — Volume nomeado ───────────────────────────────
docker volume ls
docker volume inspect vetflow-h2-data

# ── PRÉ-REQUISITO — Criar banco H2 (necessário 1x) ───────
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT 1;"

# ============================================================
# CRUD via Postman + confirmação no banco após cada operação
# ============================================================

# ── STEP 9 — POST Tutor ───────────────────────────────────
# No Postman:
#   Método : POST
#   URL    : http://<IP>:8080/api/tutors
#   Body (raw JSON):
# {
#   "name": "Carlos Silva",
#   "email": "carlos@email.com",
#   "phone": "11911111111"
# }
# Esperado: 201 Created

# Confirmar no banco:
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_tutors;"

# ── STEP 10 — POST Pet 1 (Rex) ────────────────────────────
# No Postman:
#   Método : POST
#   URL    : http://<IP>:8080/api/pets
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
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets;"

# ── STEP 11 — POST Pet 2 (Mia) ────────────────────────────
# No Postman:
#   Método : POST
#   URL    : http://<IP>:8080/api/pets
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
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets;"

# ── STEP 12 — GET Pets ────────────────────────────────────
# No Postman:
#   Método : GET
#   URL    : http://<IP>:8080/api/pets
#   Sem body
# Esperado: 200 OK com Rex e Mia no array

# ── STEP 13 — PUT Pet (atualizar Rex) ─────────────────────
# No Postman:
#   Método : PUT
#   URL    : http://<IP>:8080/api/pets/1
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
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets WHERE ID = 1;"

# ── STEP 14 — DELETE Pet (remover Rex) ────────────────────
# No Postman:
#   Método : DELETE
#   URL    : http://<IP>:8080/api/pets/1
#   Sem body
# Esperado: 204 No Content

# Confirmar no banco:
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets;"

# ── STEP 15 — JOIN final ──────────────────────────────────
docker exec vetflow-h2 java -cp /opt/h2/bin/h2-2.1.214.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:1521//opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;"

# ── SAIR DA VM ────────────────────────────────────────────
exit

# ── AZURE CLOUD SHELL — Remoção ───────────────────────────
chmod +x remocao.sh
./remocao.sh
# Quando perguntar "Tem certeza? (s/N):" — digite s e Enter

# Confirmar remoção:
az group show --name rg-vetflow
# Esperado: erro informando que o resource group não existe
