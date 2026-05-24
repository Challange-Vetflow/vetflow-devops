# Terminal local
az login
chmod +x criacao.sh
sed -i 's/\r$//' criacao.sh
./criacao.sh
#Terminal local — conectar na VM
ssh azureuser@<IP>
#Dentro da VM
cd /home/azureuser/vetflow
docker compose ps
docker exec vetflow-app whoami
docker volume ls
docker volume inspect vetflow-h2-data
#Dentro da VM — após cada operação no Postman
# Após POST Tutor
docker exec vetflow-h2 java -cp /opt/h2/bin/h2*.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:9090/h2/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_tutors;"

# Após POST Pet 1 (Rex)
docker exec vetflow-h2 java -cp /opt/h2/bin/h2*.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:9090/h2/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets;"

# Após POST Pet 2 (Mia)
docker exec vetflow-h2 java -cp /opt/h2/bin/h2*.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:9090/h2/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets;"

# Após PUT Pet (Rex → Golden Retriever)
docker exec vetflow-h2 java -cp /opt/h2/bin/h2*.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:9090/h2/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets WHERE ID = 1;"

# Após DELETE Pet (Rex)
docker exec vetflow-h2 java -cp /opt/h2/bin/h2*.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:9090/h2/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT * FROM cv_pets;"

# JOIN final
docker exec vetflow-h2 java -cp /opt/h2/bin/h2*.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://localhost:9090/h2/opt/h2-data/vetflowdb" \
  -user sa -password "" \
  -sql "SELECT p.id, p.name AS pet, p.species, p.breed, t.name AS tutor, t.email FROM cv_pets p JOIN cv_tutors t ON t.id = p.tutor_id;"
Dentro da VM — sair e remover

#Terminal local — remoção
bashchmod +x remocao.sh
./remocao.sh
az group show --name rg-vetflow