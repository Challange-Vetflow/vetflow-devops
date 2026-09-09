-- =============================================================
-- VetFlow – DDL das tabelas CORE (Sprint 3 – DevOps Tools & Cloud Computing)
-- Banco: PostgreSQL
--
-- Tabelas usadas na demonstração do CRUD, refletindo o domínio
-- principal da aplicação (tutores e pets), relacionadas entre si
-- por tutor_id. Nomes de tabela/coluna conforme já utilizados
-- pelo Hibernate na aplicação original (ver comandos.sh das
-- Sprints 1/2 — cv_tutors, cv_pets).
--
-- OBS.: Em runtime, o Hibernate (spring.jpa.hibernate.ddl-auto=update)
-- também cria/ajusta essas tabelas automaticamente a partir das
-- entidades JPA. Este script documenta a estrutura para a entrega
-- em PDF/GitHub exigida pelo item 3.3 do enunciado. Caso os nomes
-- reais de alguma coluna nas entidades divirjam dos assumidos aqui,
-- ajuste este arquivo para refletir o schema efetivo antes da entrega.
-- =============================================================

-- Tabela de tutores (donos dos pets)
CREATE TABLE IF NOT EXISTS cv_tutors (
    id     BIGSERIAL PRIMARY KEY,        -- identificador único do tutor
    name   VARCHAR(150) NOT NULL,        -- nome completo do tutor
    email  VARCHAR(150),                 -- e-mail de contato
    phone  VARCHAR(20)                   -- telefone de contato
);

COMMENT ON TABLE cv_tutors IS 'Tutores (donos) dos pets cadastrados na clínica';
COMMENT ON COLUMN cv_tutors.id IS 'Identificador único do tutor';
COMMENT ON COLUMN cv_tutors.name IS 'Nome completo do tutor';
COMMENT ON COLUMN cv_tutors.email IS 'E-mail de contato do tutor';
COMMENT ON COLUMN cv_tutors.phone IS 'Telefone de contato do tutor';

-- Tabela de pets, relacionada a cv_tutors via tutor_id (N:1)
CREATE TABLE IF NOT EXISTS cv_pets (
    id          BIGSERIAL PRIMARY KEY,      -- identificador único do pet
    name        VARCHAR(100) NOT NULL,      -- nome do pet
    species     VARCHAR(30)  NOT NULL,      -- espécie (ex.: DOG, CAT)
    breed       VARCHAR(100),               -- raça do pet
    birth_date  DATE,                       -- data de nascimento
    weight_kg   NUMERIC(6,2),               -- peso em quilogramas
    tutor_id    BIGINT NOT NULL,            -- FK para cv_tutors.id
    CONSTRAINT fk_pet_tutor FOREIGN KEY (tutor_id)
        REFERENCES cv_tutors (id) ON DELETE CASCADE
);

COMMENT ON TABLE cv_pets IS 'Pets cadastrados, relacionados a um tutor (cv_tutors)';
COMMENT ON COLUMN cv_pets.id IS 'Identificador único do pet';
COMMENT ON COLUMN cv_pets.name IS 'Nome do pet';
COMMENT ON COLUMN cv_pets.species IS 'Espécie do pet (ex.: DOG, CAT)';
COMMENT ON COLUMN cv_pets.breed IS 'Raça do pet';
COMMENT ON COLUMN cv_pets.birth_date IS 'Data de nascimento do pet';
COMMENT ON COLUMN cv_pets.weight_kg IS 'Peso do pet em quilogramas';
COMMENT ON COLUMN cv_pets.tutor_id IS 'Referência ao tutor responsável (cv_tutors.id)';

-- Índice de apoio para buscas de pets por tutor (usado por /api/pets/by-tutor/{id})
CREATE INDEX IF NOT EXISTS idx_cv_pets_tutor_id ON cv_pets (tutor_id);

-- ── Massa de dados inicial (>= 2 linhas com conteúdo significativo) ──
INSERT INTO cv_tutors (name, email, phone) VALUES
    ('Carlos Silva', 'carlos@email.com', '11911111111'),
    ('Ana Souza',    'ana@email.com',    '11922222222')
ON CONFLICT DO NOTHING;

INSERT INTO cv_pets (name, species, breed, birth_date, weight_kg, tutor_id) VALUES
    ('Rex', 'DOG', 'Labrador', '2022-03-15', 12.5, 1),
    ('Mia', 'CAT', 'Siamês',   '2021-07-10', 4.2,  1)
ON CONFLICT DO NOTHING;
