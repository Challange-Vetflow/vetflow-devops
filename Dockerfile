# =============================================================
# VetFlow API — imagem multi-stage (build + runtime)
# O repositório vetflow-java NÃO é alterado em nenhum momento.
# Este Dockerfile: 1) compila o jar original, 2) injeta o driver
# JDBC do PostgreSQL (que não está no pom.xml do Java), 3) troca
# os 2 arquivos de migration do Flyway pela versão compatível com
# Postgres (ver db-patches/, mesmo conteúdo, só sintaxe SQL trocada).
# Nenhuma classe, dependência do pom.xml ou dado é alterado além disso.
# =============================================================

# ---------- Stage 1: build ----------
FROM maven:3.9-eclipse-temurin-17 AS builder

ARG POSTGRES_DRIVER_VERSION=42.7.4

RUN apt-get update && apt-get install -y --no-install-recommends unzip zip curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
# Contexto de build = pasta com o código-fonte do vetflow-java clonado
# (ver README / criacao.sh: git clone vetflow-java build-app)
COPY . /build

RUN mvn -q clean package -DskipTests

# Reempacota o jar: injeta o driver Postgres e troca os 2 SQLs do Flyway
COPY db-patches/V1__base_schema.sql db-patches/V2__create_users_table.sql /tmp/db-patches/
RUN mkdir -p /tmp/repack \
    && cd /tmp/repack \
    && unzip -q /build/target/vetflow-0.0.1-SNAPSHOT.jar \
    && curl -sL -o BOOT-INF/lib/postgresql-${POSTGRES_DRIVER_VERSION}.jar \
       "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_DRIVER_VERSION}/postgresql-${POSTGRES_DRIVER_VERSION}.jar" \
    && cp /tmp/db-patches/V1__base_schema.sql BOOT-INF/classes/db/migration/V1__base_schema.sql \
    && cp /tmp/db-patches/V2__create_users_table.sql BOOT-INF/classes/db/migration/V2__create_users_table.sql \
    && zip -qr /build/target/vetflow-patched.jar .

# ---------- Stage 2: runtime (imagem final, sem Maven/JDK completo) ----------
FROM eclipse-temurin:17-jre-jammy

# Usuário sem privilégios administrativos
RUN groupadd -r vetflow && useradd -r -g vetflow -m vetflow

WORKDIR /app
COPY --from=builder --chown=vetflow:vetflow /build/target/vetflow-patched.jar /app/vetflow.jar

# Configuração fixa (não sensível) do datasource Postgres.
# Usuário/senha/host do banco SEMPRE vêm de variáveis de ambiente
# passadas em runtime (docker-compose.yml / --env-file / ACI
# environmentVariables com secureValue) — nunca com valor default aqui.
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver
ENV SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect
ENV SPRING_H2_CONSOLE_ENABLED=false
ENV SPRING_CACHE_TYPE=simple

EXPOSE 8080
USER vetflow

CMD ["java", "-jar", "/app/vetflow.jar"]
