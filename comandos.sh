# ============================================================
# FIAP DevOps Sprint 3 — 2026 (ACR + ACI + PostgreSQL)
# ROTEIRO COMPLETO DE GRAVAÇÃO DO VÍDEO — 100% via CMD.
#
# Marcações:
#   [FORA DO VÍDEO]  -> faça ANTES de apertar gravar
#   [GRAVANDO]        -> precisa aparecer na tela, com você narrando
#   [SEM CORTES]      -> do login até o SELECT final do CRUD,
#                        nenhuma edição/corte entre esses comandos
#                        (o enunciado pune isso explicitamente)
#
# NOTA: "bash" sozinho pode apontar pro bash.exe do WSL (que pode
# nao estar configurado direito). Por isso os comandos abaixo chamam
# o caminho COMPLETO do bash do Git for Windows em toda linha que
# precisa dele - nao depende de nenhuma linha anterior ter rodado.
# Se voce instalou o Git em outro local, ajuste TODAS as linhas que
# comecam com "C:\Program Files\Git\bin\bash.exe".
# ============================================================


# ============================================================
# [FORA DO VÍDEO] PREPARAÇÃO DO AMBIENTE
# ============================================================

cd C:\caminho\para\onde\voce\quer\gravar
if exist vetflow-devops (
    cd vetflow-devops
    docker compose down -v 2>nul
    cd ..
    rmdir /s /q build-app 2>nul
    del cookies.txt 2>nul
    cd ..
    rmdir /s /q vetflow-devops
)

az login
az account show


# ============================================================
# [GRAVANDO] PASSO 1 — Clone do repositório
# O enunciado exige que o vídeo COMECE assim.
# ============================================================
git clone https://github.com/Challange-Vetflow/vetflow-devops.git
cd vetflow-devops


# ============================================================
# [GRAVANDO] PASSO 2 — Confirmar a conta Azure ativa
# ============================================================
az account show --query "{subscription:name, user:user.name}" -o table


# ============================================================
# [GRAVANDO] PASSO 3 — Criar toda a infraestrutura na Azure
# ============================================================
"C:\Program Files\Git\bin\bash.exe" -c "sed -i 's/\r$//' criacao.sh remocao.sh"
"C:\Program Files\Git\bin\bash.exe" criacao.sh
# Pede a senha do banco no terminal (não aparece na tela ao digitar).
# >>> ANOTE o FQDN impresso no final <<<, você vai colar ele no Passo 5.


# ============================================================
# [GRAVANDO] PASSO 4 — Conferir os recursos criados
# ============================================================

az container show --resource-group rg-vetflow --name aci-vetflow --query "containers[].{name:name,state:instanceView.currentState.state}" -o table

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-app --exec-command "whoami"
# Esperado: vetflow (nunca root)

az storage share show --name vetflow-db-data --account-name <STORAGE_ACCOUNT>


# ============================================================
# [GRAVANDO — SEM CORTES A PARTIR DAQUI] PASSOS 5 e 6
# ============================================================

set FQDN=<cole aqui o FQDN impresso pelo criacao.sh>

curl -c cookies.txt -X POST http://%FQDN%:8080/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"vet@vetflow.com\",\"senha\":\"senha123\"}"

# 6.1 CREATE Tutor — anote o "id" retornado
curl -b cookies.txt -X POST http://%FQDN%:8080/api/tutors -H "Content-Type: application/json" -d "{\"name\":\"Carlos Silva\",\"email\":\"carlos.silva.novo@email.com\",\"phone\":\"11911111111\"}"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name, email, phone FROM cv_tutors;   (\q para sair)

# 6.2 CREATE Pet — troque tutorId pelo id anotado; anote o id do PET
curl -b cookies.txt -X POST http://%FQDN%:8080/api/pets -H "Content-Type: application/json" -d "{\"name\":\"Rex\",\"species\":\"DOG\",\"breed\":\"Labrador\",\"birthDate\":\"2022-03-15\",\"weightKg\":12.5,\"tutorId\":3}"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name, species, tutor_id FROM cv_pets;

# 6.3 READ
curl -b cookies.txt http://%FQDN%:8080/api/pets

# 6.4 UPDATE Pet — troque {id}
curl -b cookies.txt -X PUT http://%FQDN%:8080/api/pets/{id} -H "Content-Type: application/json" -d "{\"name\":\"Rex\",\"species\":\"DOG\",\"breed\":\"Golden Retriever\",\"birthDate\":\"2022-03-15\",\"weightKg\":13.0,\"tutorId\":3}"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name, breed FROM cv_pets WHERE id = <id do pet>;

# 6.5 DELETE Pet — troque {id}
curl -b cookies.txt -X DELETE http://%FQDN%:8080/api/pets/{id}

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT id, name FROM cv_pets;

# 6.6 Evidência final — JOIN
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
#   SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email
#   FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;


# ============================================================
# [GRAVANDO] PASSO 7 — Encerramento
# ============================================================
"C:\Program Files\Git\bin\bash.exe" remocao.sh
# "Tem certeza? (s/N):" -> digite s e Enter

az group show --name rg-vetflow
# Esperado: erro dizendo que o resource group não existe.
# PARE A GRAVAÇÃO só depois de mostrar esse erro na tela.
