# Imagem multi-stage. Não altera o vetflow-java: compila o jar original,
# injeta o driver JDBC do Postgres e o modulo do Flyway p/ Postgres
# (ausentes no pom.xml, que so tem H2/Oracle), e troca 2 migrations do
# Flyway pela versao compativel com Postgres (ver db-patches/).

FROM maven:3.9-eclipse-temurin-17 AS builder

ARG POSTGRES_DRIVER_VERSION=42.7.4
# Flyway 10+ exige este modulo separado para suportar Postgres (H2 ja vem embutido)
ARG FLYWAY_POSTGRES_VERSION=10.20.1

RUN apt-get update && apt-get install -y --no-install-recommends unzip zip curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . /build

RUN mvn -q clean package -DskipTests

COPY db-patches/V1__base_schema.sql db-patches/V2__create_users_table.sql /tmp/db-patches/
# -0 no zip final: sem compressao. Spring Boot 3.2+ le BOOT-INF/lib/*.jar
# direto pelo offset do zip; jar recomprimido quebra o loader (NoClassDefFoundError).
RUN mkdir -p /tmp/repack \
    && cd /tmp/repack \
    && unzip -q /build/target/vetflow-0.0.1-SNAPSHOT.jar \
    && curl -sL -o BOOT-INF/lib/postgresql-${POSTGRES_DRIVER_VERSION}.jar \
       "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_DRIVER_VERSION}/postgresql-${POSTGRES_DRIVER_VERSION}.jar" \
    && curl -sL -o BOOT-INF/lib/flyway-database-postgresql-${FLYWAY_POSTGRES_VERSION}.jar \
       "https://repo1.maven.org/maven2/org/flywaydb/flyway-database-postgresql/${FLYWAY_POSTGRES_VERSION}/flyway-database-postgresql-${FLYWAY_POSTGRES_VERSION}.jar" \
    && cp /tmp/db-patches/V1__base_schema.sql BOOT-INF/classes/db/migration/V1__base_schema.sql \
    && cp /tmp/db-patches/V2__create_users_table.sql BOOT-INF/classes/db/migration/V2__create_users_table.sql \
    && zip -qr -X -0 /build/target/vetflow-patched.jar .

FROM eclipse-temurin:17-jre-jammy

RUN groupadd -r vetflow && useradd -r -g vetflow -m vetflow

WORKDIR /app
COPY --from=builder --chown=vetflow:vetflow /build/target/vetflow-patched.jar /app/vetflow.jar

# Usuario/senha/host do banco vem de variaveis de ambiente em runtime,
# nunca com valor default aqui (docker-compose.yml / ACI secureValue).
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver
ENV SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect
ENV SPRING_H2_CONSOLE_ENABLED=false
ENV SPRING_CACHE_TYPE=simple

EXPOSE 8080
USER vetflow

CMD ["sh", "-c", "echo 'Container rodando como usuario:' $(whoami) && exec java -jar /app/vetflow.jar"]
