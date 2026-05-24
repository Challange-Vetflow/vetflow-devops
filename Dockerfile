# VetFlow – Dockerfile da API (Spring Boot)

FROM maven:3.9-eclipse-temurin-17

# Cria usuário sem privilégios administrativos com home directory
RUN groupadd -r vetflow && useradd -r -g vetflow -d /home/vetflow -m vetflow

# Cria a pasta /app, o diretório home e o cache do Maven
# ANTES de copiar os arquivos — garante permissão de escrita no mvn build
RUN mkdir -p /app && mkdir -p /home/vetflow/.m2 && chown -R vetflow:vetflow /app /home/vetflow

WORKDIR /app

# Copia o projeto já com o dono correto (--chown garante permissão ao vetflow)
COPY --chown=vetflow:vetflow . /app

# Variáveis de ambiente para conexão com o banco H2 em modo TCP
# O hostname "h2server" é o nome do container H2 na rede Docker
ENV SPRING_DATASOURCE_URL=jdbc:h2:tcp://h2server:9090/h2/opt/h2-data/vetflowdb
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.h2.Driver
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=
ENV SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.H2Dialect
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update
ENV SPRING_H2_CONSOLE_ENABLED=true
ENV SPRING_H2_CONSOLE_SETTINGS_WEB_ALLOW_OTHERS=true
ENV SPRING_CACHE_TYPE=simple

# Porta exposta pela aplicação Spring Boot
EXPOSE 8080

# Troca para o usuário sem privilégios — a partir daqui nada roda como root
USER vetflow

# Build Maven + execução do JAR 
CMD ["bash", "-c", "mvn clean package -DskipTests && java -jar target/*.jar"]
