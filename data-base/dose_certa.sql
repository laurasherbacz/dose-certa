
DROP DATABASE IF EXISTS dose_certa;
CREATE DATABASE dose_certa
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE dose_certa;

-- ---------------------------------------------------------------------
-- 1. USUARIO
--    Pessoa que acessa o sistema (usuário comum, cuidador ou administrador).
--    Telas: cadastro.html, login.html, app/perfil.html, admin/perfil.html
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
  id_usuario      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome            VARCHAR(120) NOT NULL,
  email           VARCHAR(150) NOT NULL,
  senha_hash      VARCHAR(255) NOT NULL,              -- nunca guardar senha pura
  endereco        VARCHAR(255) NULL,
  foto_perfil     VARCHAR(255) NULL,                  -- caminho/URL da imagem
  perfil          ENUM('USUARIO','ADMIN') NOT NULL DEFAULT 'USUARIO',
  aceitou_termos  TINYINT(1) NOT NULL DEFAULT 0,
  ativo           TINYINT(1) NOT NULL DEFAULT 1,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uk_usuario_email (email)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. CATEGORIA_MEDICAMENTO
--    Classificação terapêutica (ex.: Anti-hipertensivo).
-- ---------------------------------------------------------------------
CREATE TABLE categoria_medicamento (
  id_categoria INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(80) NOT NULL,
  PRIMARY KEY (id_categoria),
  UNIQUE KEY uk_categoria_nome (nome)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. CATALOGO_MEDICAMENTO
--    Catálogo mantido pelo administrador; serve de base para o usuário
--    escolher o medicamento ao cadastrar. Tela: admin/medicamentos.html
-- ---------------------------------------------------------------------
CREATE TABLE catalogo_medicamento (
  id_catalogo     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_categoria    INT UNSIGNED NOT NULL,
  nome            VARCHAR(120) NOT NULL,
  dosagem_padrao  VARCHAR(40) NOT NULL,
  ativo           TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_catalogo),
  UNIQUE KEY uk_catalogo_nome_dosagem (nome, dosagem_padrao),
  CONSTRAINT fk_catalogo_categoria FOREIGN KEY (id_categoria)
    REFERENCES categoria_medicamento (id_categoria)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. MEDICAMENTO
--    Medicamento em uso por um usuário (tratamento): dosagem, duração,
--    estoque, valor e exigência de receita. Tela: app/medicamentos.html
-- ---------------------------------------------------------------------
CREATE TABLE medicamento (
  id_medicamento     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario         INT UNSIGNED NOT NULL,
  id_catalogo        INT UNSIGNED NULL,               -- opcional: item do catálogo
  nome               VARCHAR(120) NOT NULL,
  dosagem            VARCHAR(40) NOT NULL,            -- ex.: 50 mg
  unidade            VARCHAR(20) NOT NULL DEFAULT 'comprimido',
  quantidade_por_dose INT UNSIGNED NOT NULL DEFAULT 1,
  data_inicio        DATE NOT NULL,
  duracao_dias       INT UNSIGNED NULL,               -- NULL = uso contínuo
  estoque_atual      INT UNSIGNED NOT NULL DEFAULT 0,
  estoque_minimo     INT UNSIGNED NOT NULL DEFAULT 5, -- abaixo disso: alerta
  valor_pago         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  exige_receita      TINYINT(1) NOT NULL DEFAULT 1,
  ativo              TINYINT(1) NOT NULL DEFAULT 1,
  criado_em          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_medicamento),
  KEY idx_medicamento_usuario (id_usuario),
  CONSTRAINT fk_medicamento_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_medicamento_catalogo FOREIGN KEY (id_catalogo)
    REFERENCES catalogo_medicamento (id_catalogo)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT ck_medicamento_valor CHECK (valor_pago >= 0),
  CONSTRAINT ck_medicamento_qtd_dose CHECK (quantidade_por_dose > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. HORARIO_MEDICAMENTO
--    Horários diários em que o medicamento deve ser tomado. Cada horário
--    gera o lembrete automático (lembrete_ativo = 1).
-- ---------------------------------------------------------------------
CREATE TABLE horario_medicamento (
  id_horario      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_medicamento  INT UNSIGNED NOT NULL,
  hora            TIME NOT NULL,
  lembrete_ativo  TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id_horario),
  UNIQUE KEY uk_horario_med_hora (id_medicamento, hora),
  CONSTRAINT fk_horario_medicamento FOREIGN KEY (id_medicamento)
    REFERENCES medicamento (id_medicamento)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. REGISTRO_DOSE
--    Histórico: cada dose prevista (horário + data) e se foi tomada.
--    Pode ser marcada pelo próprio usuário ou por um cuidador.
--    Tela: app/painel.html ("Marcar como tomado")
-- ---------------------------------------------------------------------
CREATE TABLE registro_dose (
  id_registro          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_horario           INT UNSIGNED NOT NULL,
  data_prevista        DATE NOT NULL,
  status               ENUM('PENDENTE','TOMADO','NAO_TOMADO') NOT NULL DEFAULT 'PENDENTE',
  data_hora_tomada     DATETIME NULL,
  id_usuario_registro  INT UNSIGNED NULL,             -- quem marcou (usuário/cuidador)
  PRIMARY KEY (id_registro),
  UNIQUE KEY uk_registro_horario_data (id_horario, data_prevista),
  KEY idx_registro_data (data_prevista),
  CONSTRAINT fk_registro_horario FOREIGN KEY (id_horario)
    REFERENCES horario_medicamento (id_horario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_registro_usuario FOREIGN KEY (id_usuario_registro)
    REFERENCES usuario (id_usuario)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT ck_registro_tomado CHECK (
    (status = 'TOMADO' AND data_hora_tomada IS NOT NULL) OR status <> 'TOMADO')
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. RECEITA
--    Receita médica do usuário, com validade para controlar renovação.
--    Tela: app/receitas.html
-- ---------------------------------------------------------------------
CREATE TABLE receita (
  id_receita    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario    INT UNSIGNED NOT NULL,
  medico        VARCHAR(120) NOT NULL,
  data_emissao  DATE NULL,
  validade      DATE NOT NULL,
  observacao    VARCHAR(255) NULL,
  PRIMARY KEY (id_receita),
  KEY idx_receita_usuario (id_usuario),
  CONSTRAINT fk_receita_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT ck_receita_datas CHECK (data_emissao IS NULL OR validade >= data_emissao)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. RECEITA_MEDICAMENTO  (associativa N:N)
--    Uma receita pode prescrever vários medicamentos e um medicamento
--    pode ser coberto por receitas sucessivas (renovações).
-- ---------------------------------------------------------------------
CREATE TABLE receita_medicamento (
  id_receita      INT UNSIGNED NOT NULL,
  id_medicamento  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_receita, id_medicamento),
  CONSTRAINT fk_recmed_receita FOREIGN KEY (id_receita)
    REFERENCES receita (id_receita)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_recmed_medicamento FOREIGN KEY (id_medicamento)
    REFERENCES medicamento (id_medicamento)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. GASTO
--    Compra de medicamento. Mantém a descrição (snapshot) para não
--    perder o histórico financeiro se o medicamento for excluído.
--    Tela: app/gastos.html
-- ---------------------------------------------------------------------
CREATE TABLE gasto (
  id_gasto        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario      INT UNSIGNED NOT NULL,
  id_medicamento  INT UNSIGNED NULL,
  descricao       VARCHAR(150) NOT NULL,              -- ex.: Losartana 50 mg
  data_compra     DATE NOT NULL,
  quantidade      INT UNSIGNED NOT NULL DEFAULT 1,
  valor           DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_gasto),
  KEY idx_gasto_usuario_data (id_usuario, data_compra),
  CONSTRAINT fk_gasto_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_gasto_medicamento FOREIGN KEY (id_medicamento)
    REFERENCES medicamento (id_medicamento)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT ck_gasto_valor CHECK (valor >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. COMPARTILHAMENTO_ACESSO
--     Autoriza um familiar/cuidador a acompanhar os dados de um titular
--     (relacionamento N:N autorreferente em USUARIO).
-- ---------------------------------------------------------------------
CREATE TABLE compartilhamento_acesso (
  id_compartilhamento INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_titular          INT UNSIGNED NOT NULL,          -- dono dos medicamentos
  id_cuidador         INT UNSIGNED NOT NULL,          -- quem acompanha
  status              ENUM('PENDENTE','ATIVO','REVOGADO') NOT NULL DEFAULT 'PENDENTE',
  pode_registrar_dose TINYINT(1) NOT NULL DEFAULT 0,
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_compartilhamento),
  UNIQUE KEY uk_compart_titular_cuidador (id_titular, id_cuidador),
    CONSTRAINT fk_compart_titular FOREIGN KEY (id_titular)
    REFERENCES usuario (id_usuario)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_compart_cuidador FOREIGN KEY (id_cuidador)
    REFERENCES usuario (id_usuario)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT ck_compart_diferentes CHECK (id_titular <> id_cuidador)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 11. FAQ
--     Perguntas frequentes gerenciadas pelo administrador.
--     Telas: faq.html, admin/faqs.html
-- ---------------------------------------------------------------------
CREATE TABLE faq (
  id_faq      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_admin    INT UNSIGNED NULL,                      -- administrador que criou
  pergunta    VARCHAR(255) NOT NULL,
  resposta    TEXT NOT NULL,
  publicada   TINYINT(1) NOT NULL DEFAULT 0,          -- 0 = rascunho
  ordem       INT UNSIGNED NOT NULL DEFAULT 0,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_faq),
  CONSTRAINT fk_faq_admin FOREIGN KEY (id_admin)
    REFERENCES usuario (id_usuario)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 12. MENSAGEM_CONTATO
--     Mensagens enviadas pelo formulário público. Tela: contato.html
--     (visitante não precisa estar cadastrado)
-- ---------------------------------------------------------------------
CREATE TABLE mensagem_contato (
  id_mensagem  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(120) NOT NULL,
  email        VARCHAR(150) NOT NULL,
  assunto      VARCHAR(150) NOT NULL,
  mensagem     TEXT NOT NULL,
  lida         TINYINT(1) NOT NULL DEFAULT 0,
  enviada_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_mensagem)
) ENGINE=InnoDB;

-- =====================================================================
-- TRIGGERS: baixa automática de estoque ao registrar dose tomada
-- =====================================================================
DELIMITER $$

CREATE TRIGGER trg_dose_tomada_insert
AFTER INSERT ON registro_dose
FOR EACH ROW
BEGIN
  IF NEW.status = 'TOMADO' THEN
    UPDATE medicamento m
      JOIN horario_medicamento h ON h.id_medicamento = m.id_medicamento
       SET m.estoque_atual = GREATEST(CAST(m.estoque_atual AS SIGNED) - m.quantidade_por_dose, 0)
     WHERE h.id_horario = NEW.id_horario;
  END IF;
END$$

CREATE TRIGGER trg_dose_tomada_update
AFTER UPDATE ON registro_dose
FOR EACH ROW
BEGIN
  IF NEW.status = 'TOMADO' AND OLD.status <> 'TOMADO' THEN
    UPDATE medicamento m
      JOIN horario_medicamento h ON h.id_medicamento = m.id_medicamento
       SET m.estoque_atual = GREATEST(CAST(m.estoque_atual AS SIGNED) - m.quantidade_por_dose, 0)
     WHERE h.id_horario = NEW.id_horario;
  END IF;
END$$

DELIMITER ;

-- =====================================================================
-- VIEWS: consultas que alimentam o painel do usuário e do administrador
-- =====================================================================

-- Doses do dia (painel do usuário)
CREATE VIEW vw_doses_hoje AS
SELECT m.id_usuario, r.id_registro, h.hora,
       CONCAT(m.nome, ' ', m.dosagem) AS medicamento, r.status
  FROM registro_dose r
  JOIN horario_medicamento h ON h.id_horario = r.id_horario
  JOIN medicamento m         ON m.id_medicamento = h.id_medicamento
 WHERE r.data_prevista = CURRENT_DATE();

-- Alerta de estoque baixo, com dias restantes estimados
CREATE VIEW vw_estoque_baixo AS
SELECT m.id_usuario, m.id_medicamento, m.nome, m.dosagem, m.estoque_atual,
       m.estoque_minimo,
       FLOOR(m.estoque_atual /
             (COUNT(h.id_horario) * m.quantidade_por_dose)) AS dias_restantes
  FROM medicamento m
  JOIN horario_medicamento h ON h.id_medicamento = m.id_medicamento
 WHERE m.ativo = 1
 GROUP BY m.id_medicamento
HAVING m.estoque_atual <= m.estoque_minimo;

-- Situação das receitas (válida / vence em breve / vencida)
CREATE VIEW vw_receitas_situacao AS
SELECT r.id_usuario, r.id_receita, r.medico,
       GROUP_CONCAT(m.nome ORDER BY m.nome SEPARATOR ', ') AS medicamentos,
       r.validade,
       DATEDIFF(r.validade, CURRENT_DATE()) AS dias_para_vencer,
       CASE WHEN r.validade < CURRENT_DATE() THEN 'Vencida'
            WHEN DATEDIFF(r.validade, CURRENT_DATE()) <= 30 THEN 'Renovar'
            ELSE 'Válida' END AS situacao
  FROM receita r
  LEFT JOIN receita_medicamento rm ON rm.id_receita = r.id_receita
  LEFT JOIN medicamento m          ON m.id_medicamento = rm.id_medicamento
 GROUP BY r.id_receita;

-- Total de gastos por mês
CREATE VIEW vw_gasto_mensal AS
SELECT id_usuario, DATE_FORMAT(data_compra, '%Y-%m') AS mes,
       COUNT(*) AS compras, SUM(valor) AS total
  FROM gasto
 GROUP BY id_usuario, DATE_FORMAT(data_compra, '%Y-%m');

-- =====================================================================
-- DADOS DE EXEMPLO (mesmos valores das telas do front-end)
-- Obs.: senha_hash abaixo é fictício; a aplicação deve gravar hash real
--       (ex.: bcrypt) gerado no back-end.
-- =====================================================================
INSERT INTO usuario (nome, email, senha_hash, endereco, perfil, aceitou_termos, criado_em) VALUES
 ('Administrador', 'admin@dosecerta.com', '$2b$10$EXEMPLO_HASH_ADMIN_000000000000000000000000000000', NULL, 'ADMIN', 1, '2026-11-01 09:00:00'),
 ('Maria Helena',  'maria@email.com', '$2b$10$EXEMPLO_HASH_MARIA_000000000000000000000000000000', 'Rua Exemplo, 123 - Porto Alegre/RS', 'USUARIO', 1, '2026-11-12 10:00:00'),
 ('João Pereira',  'joao@email.com',  '$2b$10$EXEMPLO_HASH_JOAO_0000000000000000000000000000000', NULL, 'USUARIO', 1, '2026-11-11 10:00:00'),
 ('Ana Lima',      'ana@email.com',   '$2b$10$EXEMPLO_HASH_ANA_00000000000000000000000000000000', NULL, 'USUARIO', 1, '2026-11-09 10:00:00');

INSERT INTO categoria_medicamento (nome) VALUES
 ('Anti-hipertensivo'), ('Antidiabético'), ('Protetor gástrico');

INSERT INTO catalogo_medicamento (id_categoria, nome, dosagem_padrao, ativo) VALUES
 (1, 'Losartana', '50 mg', 1),
 (2, 'Metformina', '850 mg', 1),
 (3, 'Omeprazol', '20 mg', 0);

-- Medicamentos da Maria Helena (id_usuario = 2)
INSERT INTO medicamento
 (id_usuario, id_catalogo, nome, dosagem, unidade, quantidade_por_dose, data_inicio,
  duracao_dias, estoque_atual, estoque_minimo, valor_pago, exige_receita) VALUES
 (2, 1, 'Losartana',  '50 mg',  'comprimido', 1, '2026-01-10', NULL, 18, 10, 18.90, 1),
 (2, 2, 'Metformina', '850 mg', 'comprimido', 1, '2026-02-05', NULL,  5, 10, 32.40, 1),
 (2, 3, 'Omeprazol',  '20 mg',  'cápsula',    1, '2026-03-01', 90,   24, 10, 24.00, 1);

INSERT INTO horario_medicamento (id_medicamento, hora) VALUES
 (1, '08:00:00'), (1, '20:00:00'),   -- Losartana
 (2, '14:00:00'),                    -- Metformina
 (3, '07:00:00');                    -- Omeprazol

-- Receitas
INSERT INTO receita (id_usuario, medico, data_emissao, validade) VALUES
 (2, 'Dra. Souza', '2026-06-30', '2026-12-31'),
 (2, 'Dr. Lima',   '2026-05-24', '2026-11-24');
INSERT INTO receita_medicamento (id_receita, id_medicamento) VALUES (1, 1), (2, 3);

-- Gastos de novembro/2026 (total R$ 75,30 nesta amostra) e mês anterior
INSERT INTO gasto (id_usuario, id_medicamento, descricao, data_compra, quantidade, valor) VALUES
 (2, 1, 'Losartana 50 mg',  '2026-11-05', 30, 18.90),
 (2, 2, 'Metformina 850 mg','2026-11-03', 30, 32.40),
 (2, 3, 'Omeprazol 20 mg',  '2026-11-01', 28, 24.00),
 (2, 1, 'Losartana 50 mg',  '2026-10-05', 30, 18.90),
 (2, 2, 'Metformina 850 mg','2026-10-03', 30, 32.40);

-- Cuidador: João acompanha a Maria
INSERT INTO compartilhamento_acesso (id_titular, id_cuidador, status, pode_registrar_dose) VALUES
 (2, 3, 'ATIVO', 1);

-- Doses de hoje (19/11/2026): a manhã já foi tomada, o restante está pendente
INSERT INTO registro_dose (id_horario, data_prevista, status, data_hora_tomada, id_usuario_registro) VALUES
 (1, CURRENT_DATE(), 'TOMADO',   NOW(), 2),
 (3, CURRENT_DATE(), 'PENDENTE', NULL,  NULL),
 (2, CURRENT_DATE(), 'PENDENTE', NULL,  NULL);

INSERT INTO faq (id_admin, pergunta, resposta, publicada, ordem) VALUES
 (1, 'Como funcionam os lembretes?', 'Você define os horários ao cadastrar o medicamento e o sistema avisa na hora certa.', 1, 1),
 (1, 'Posso compartilhar com um familiar ou cuidador?', 'Sim. Você escolhe quem pode acompanhar seus medicamentos e registros.', 1, 2),
 (1, 'O Dose Certa substitui a orientação médica?', 'Não. Ele organiza sua rotina, mas dosagens e horários devem seguir a prescrição médica.', 1, 3),
 (1, 'Quanto custa usar?', '[Informar plano ou valor]', 0, 4),
 (1, 'Posso usar no celular?', 'Sim. A interface se adapta a telas de diferentes tamanhos.', 1, 5);

INSERT INTO mensagem_contato (nome, email, assunto, mensagem, lida, enviada_em) VALUES
 ('Carlos', 'carlos@email.com', 'Dúvida sobre lembretes', 'Como altero o horário de um lembrete?', 0, '2026-11-12 14:00:00'),
 ('Paula',  'paula@email.com',  'Sugestão de melhoria',   'Seria bom poder exportar o histórico.', 0, '2026-11-10 09:30:00');