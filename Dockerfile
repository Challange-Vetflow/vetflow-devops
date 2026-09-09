FROM maven:3.9-eclipse-temurin-17

# Driver JDBC do Postgres a injetar no jar (pode ser sobrescrito com --build-arg)
ARG POSTGRES_DRIVER_VERSION=42.7.4

# Ferramentas para reempacotar o jar (precisa ser como root)
RUN apt-get update && apt-get install -y --no-install-recommends unzip zip curl \
    && rm -rf /var/lib/apt/lists/*

# Cria usuário sem privilégios administrativos com home directory
RUN groupadd -r vetflow && useradd -r -g vetflow -d /home/vetflow -m vetflow

# Cria a pasta /app, o diretório home e o cache do Maven
RUN mkdir -p /app && mkdir -p /home/vetflow/.m2 && chown -R vetflow:vetflow /app /home/vetflow

WORKDIR /app

COPY --chown=vetflow:vetflow . /app

# Variáveis de ambiente para conexão com o banco PostgreSQL
ENV SPRING_DATASOURCE_URL=jdbc:postgresql://dbserver:5432/vetflowdb
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver
ENV SPRING_DATASOURCE_USERNAME=vetflow
ENV SPRING_DATASOURCE_PASSWORD=Fiap@Cloud2026
ENV SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update
ENV SPRING_H2_CONSOLE_ENABLED=false
ENV SPRING_CACHE_TYPE=simple

# Porta exposta pela aplicação Spring Boot
EXPOSE 8080

USER vetflow

RUN mvn clean package -DskipTests

RUN mkdir -p /tmp/repack \
    && unzip -q target/vetflow-0.0.1-SNAPSHOT.jar -d /tmp/repack \
    && curl -sL -o /tmp/repack/BOOT-INF/lib/postgresql-${POSTGRES_DRIVER_VERSION}.jar \
       "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_DRIVER_VERSION}/postgresql-${POSTGRES_DRIVER_VERSION}.jar" \
    && cd /tmp/repack && zip -qr /app/target/vetflow-0.0.1-SNAPSHOT.jar . \
    && rm -rf /tmp/repack

CMD ["java", "-jar", "target/vetflow-0.0.1-SNAPSHOT.jar"]