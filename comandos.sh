:: ============================================================
:: FIAP DevOps Sprint 3 — 2026 (ACR + ACI + PostgreSQL)
:: ROTEIRO COMPLETO DE GRAVAÇÃO DO VÍDEO — 100% via CMD.
::
:: Marcações:
::   [FORA DO VÍDEO]  -> faça ANTES de apertar gravar
::   [GRAVANDO]        -> precisa aparecer na tela, com você narrando
::   [SEM CORTES]      -> do login até o SELECT final do CRUD,
::                        nenhuma edição/corte entre esses comandos
::                        (o enunciado pune isso explicitamente)
:: ============================================================


:: ============================================================
:: [FORA DO VÍDEO] PREPARAÇÃO DO AMBIENTE
:: ============================================================

:: Teste seu microfone e a resolução de gravação (mínimo 720p) antes de tudo.
:: Feche programas/abas que não sejam necessários na tela.

:: Limpe qualquer resíduo de testes locais anteriores (se existirem):
cd C:\caminho\para\onde\voce\quer\gravar
if exist vetflow-devops (
    cd vetflow-devops
    docker compose down -v 2>nul
    cd build-app 2>nul
    cd ..
    rmdir /s /q build-app 2>nul
    del cookies.txt 2>nul
    cd ..
    rmdir /s /q vetflow-devops
)

:: Autentique na Azure ANTES de gravar, pra não perder tempo de vídeo
:: com a tela do navegador abrindo/fechando (o enunciado não proíbe,
:: mas deixa a gravação mais limpa). Se preferir mostrar o login
:: ao vivo, pule esta linha e faça no Passo 2 em vez daqui.
az login

:: Confira se ainda está autenticado (evita descobrir isso já gravando):
az account show


:: ============================================================
:: [GRAVANDO] PASSO 1 — Clone do repositório
:: O enunciado exige que o vídeo COMECE assim.
:: ============================================================
git clone https://github.com/Challange-Vetflow/vetflow-devops.git
cd vetflow-devops

:: Não precisa clonar o vetflow-java manualmente — o criacao.sh
:: (Passo 3) já faz esse clone sozinho, numa pasta temporária.


:: ============================================================
:: [GRAVANDO] PASSO 2 — Conectar na Azure
:: Se você já rodou "az login" na preparação, pode só confirmar
:: a conta ativa na tela em vez de logar de novo:
:: ============================================================
az account show
:: Se preferir logar ao vivo em vez de reaproveitar a sessão:
:: az login


:: ============================================================
:: [GRAVANDO] PASSO 3 — Criar toda a infraestrutura na Azure
:: ============================================================
bash -c "sed -i 's/\r$//' criacao.sh remocao.sh"
bash criacao.sh
:: Pede a senha do banco no terminal (não aparece na tela ao digitar).
:: Deixe rodando até o final — cria Resource Group, ACR, builda as duas
:: imagens (clonando o vetflow-java por conta própria), Storage/File
:: Share, e sobe o Container Group no ACI.
::
:: >>> ANOTE o FQDN impresso no final <<<, você vai colar ele no Passo 6.


:: ============================================================
:: [GRAVANDO] PASSO 4 — Conferir os recursos criados
:: ============================================================

:: 4.1 Status dos containers (App e Banco)
az container show --resource-group rg-vetflow --name aci-vetflow --query "containers[].{name:name,state:instanceView.currentState.state}" -o table

:: 4.2 Provar que a API não roda como root (item 8.2 do enunciado)
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-app --exec-command "whoami"
:: Esperado: vetflow (nunca root)

:: 4.3 Volume nomeado (Azure File Share) — troque <STORAGE_ACCOUNT> pelo
::     nome real impresso pelo criacao.sh
az storage share show --name vetflow-db-data --account-name <STORAGE_ACCOUNT>


:: ============================================================
:: [GRAVANDO — SEM CORTES A PARTIR DAQUI] PASSOS 5 e 6
:: Login + CRUD completo, com evidência de cada operação no banco.
:: ============================================================

:: ------------------------------------------------------------
:: PASSO 5 — Guardar o FQDN e fazer LOGIN (obrigatório antes
:: de qualquer chamada em /api/**)
:: ------------------------------------------------------------

set FQDN=<cole aqui o FQDN impresso pelo criacao.sh>

curl -c cookies.txt -X POST http://%FQDN%:8080/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"vet@vetflow.com\",\"senha\":\"senha123\"}"
:: Esperado: 200 OK + cookie salvo em cookies.txt. As próximas chamadas
:: com "-b cookies.txt" reaproveitam essa sessão sozinhas.


:: ------------------------------------------------------------
:: PASSO 6 — CRUD completo, uma operação por vez, cada uma
:: seguida IMEDIATAMENTE do SELECT que prova ela no banco.
:: ------------------------------------------------------------

:: 6.1 CREATE Tutor
:: >>> Anote o "id" retornado na resposta JSON <<<
curl -b cookies.txt -X POST http://%FQDN%:8080/api/tutors -H "Content-Type: application/json" -d "{\"name\":\"Carlos Silva\",\"email\":\"carlos.silva.novo@email.com\",\"phone\":\"11911111111\"}"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
:: Dentro da sessão psql que abrir, digite:
::   SELECT id, name, email, phone FROM cv_tutors;
:: Para sair: \q

:: 6.2 CREATE Pet
:: >>> EDITE ANTES: troque tutorId pelo id anotado em 6.1 <<<
:: >>> Anote o "id" do PET retornado aqui <<<
curl -b cookies.txt -X POST http://%FQDN%:8080/api/pets -H "Content-Type: application/json" -d "{\"name\":\"Rex\",\"species\":\"DOG\",\"breed\":\"Labrador\",\"birthDate\":\"2022-03-15\",\"weightKg\":12.5,\"tutorId\":3}"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
::   SELECT id, name, species, tutor_id FROM cv_pets;

:: 6.3 READ — listar pets
curl -b cookies.txt http://%FQDN%:8080/api/pets

:: 6.4 UPDATE Pet
:: >>> EDITE ANTES: troque {id} pelo id do pet criado em 6.2 <<<
curl -b cookies.txt -X PUT http://%FQDN%:8080/api/pets/{id} -H "Content-Type: application/json" -d "{\"name\":\"Rex\",\"species\":\"DOG\",\"breed\":\"Golden Retriever\",\"birthDate\":\"2022-03-15\",\"weightKg\":13.0,\"tutorId\":3}"

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
::   SELECT id, name, breed FROM cv_pets WHERE id = <id do pet>;

:: 6.5 DELETE Pet
:: >>> EDITE ANTES: troque {id} pelo id do pet <<<
curl -b cookies.txt -X DELETE http://%FQDN%:8080/api/pets/{id}

az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
::   SELECT id, name FROM cv_pets;

:: 6.6 Evidência final de integração — JOIN tutor + pet
az container exec --resource-group rg-vetflow --name aci-vetflow --container-name vetflow-db --exec-command "psql -U vetflow -d vetflowdb"
::   SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email
::   FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;


:: ============================================================
:: [GRAVANDO] PASSO 7 — Encerramento: remover os recursos da Azure
:: (pode ter corte antes/depois deste passo, a exigência de "sem
:: corte" vale só para o bloco de CRUD acima)
:: ============================================================
bash remocao.sh
:: Quando perguntar "Tem certeza? (s/N):" — digite s e Enter

az group show --name rg-vetflow
:: Esperado: erro dizendo que o resource group não existe.
:: PARE A GRAVAÇÃO só depois de mostrar esse erro na tela.
