-- =============================================================================
-- SisGESC — Data Warehouse & OLAP — VERSÃO CORRIGIDA
-- Arquivo: SisGESC_Data_Warehouse_OLAP_corrigido.sql
-- Chamado por run_all.sql (SOURCE) após o OLTP. Inclui dim_unidade (Star Schema).
-- =============================================================================

CREATE DATABASE IF NOT EXISTS dw_sisgesc 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE dw_sisgesc;

-- ==============================================================================
-- TABELA DE DIMENSÃO: TEMPO
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_tempo (
    sk_tempo        INT PRIMARY KEY,
    data_completa   DATE NOT NULL UNIQUE,
    ano             INT NOT NULL,
    mes             INT NOT NULL,
    trimestre       INT NOT NULL,
    semestre        INT NOT NULL,
    dia_mes         INT NOT NULL,
    dia_semana      INT NOT NULL,
    nome_mes        VARCHAR(20) NOT NULL,
    nome_mes_abrev  CHAR(3) NOT NULL,
    nome_dia        VARCHAR(20) NOT NULL,
    nome_dia_abrev  CHAR(3) NOT NULL,
    eh_fim_semana   BOOLEAN DEFAULT FALSE,
    eh_feriado      BOOLEAN DEFAULT FALSE,
    semana_ano      INT,
    INDEX idx_data      (data_completa),
    INDEX idx_ano_mes   (ano, mes),
    INDEX idx_trimestre (ano, trimestre),
    INDEX idx_semestre  (ano, semestre)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE DIMENSÃO: ALUNO
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_aluno (
    sk_aluno             INT PRIMARY KEY AUTO_INCREMENT,
    cpf_aluno            VARCHAR(11) UNIQUE NOT NULL,
    rgm_aluno            VARCHAR(10),
    nome_completo        VARCHAR(200) NOT NULL,
    nome_primeiro        VARCHAR(100),
    nome_sobrenome       VARCHAR(100),
    data_nascimento      DATE,
    genero               CHAR(1),
    nacionalidade        VARCHAR(50),
    curso_atual          VARCHAR(150),
    tipo_bolsa           VARCHAR(50),
    percentual_bolsa     INT,
    data_matricula       DATE,
    data_desligamento    DATE,
    status_aluno         VARCHAR(50),
    eh_ativo             BOOLEAN DEFAULT TRUE,
    data_insercao_dw     DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao_dw  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cpf    (cpf_aluno),
    INDEX idx_nome   (nome_completo),
    INDEX idx_rgm    (rgm_aluno),
    INDEX idx_status (status_aluno),
    INDEX idx_curso  (curso_atual)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE DIMENSÃO: CURSO
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_curso (
    sk_curso            INT PRIMARY KEY AUTO_INCREMENT,
    codigo_curso        INT UNIQUE NOT NULL,
    nome_curso          VARCHAR(200) NOT NULL,
    sigla_curso         VARCHAR(20),
    departamento        VARCHAR(100),
    coordenador_nome    VARCHAR(100),
    nivel_academico     VARCHAR(50),
    duracao_semestres   INT,
    carga_horaria_total INT,
    turno               VARCHAR(20),
    eh_ativo            BOOLEAN DEFAULT TRUE,
    data_criacao        DATE,
    INDEX idx_codigo       (codigo_curso),
    INDEX idx_departamento (departamento),
    INDEX idx_nivel        (nivel_academico)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE DIMENSÃO: UNIDADE (campus / polo — requisito Star Schema da entrega)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_unidade (
    sk_unidade        INT PRIMARY KEY AUTO_INCREMENT,
    codigo_unidade    VARCHAR(30) NOT NULL UNIQUE,
    nome_unidade      VARCHAR(150) NOT NULL,
    municipio         VARCHAR(100),
    estado            CHAR(2),
    tipo_unidade      VARCHAR(50),
    INDEX idx_codigo (codigo_unidade)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE DIMENSÃO: PROFESSOR
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_professor (
    sk_professor        INT PRIMARY KEY AUTO_INCREMENT,
    cpf_professor       VARCHAR(11) UNIQUE NOT NULL,
    nome_completo       VARCHAR(200) NOT NULL,
    email               VARCHAR(100),
    telefone            VARCHAR(20),
    cargo               VARCHAR(100),
    departamento        VARCHAR(100),
    titulacao           VARCHAR(50),
    regime_trabalho     VARCHAR(50),
    data_admissao       DATE,
    data_desligamento   DATE,
    eh_ativo            BOOLEAN DEFAULT TRUE,
    INDEX idx_cpf          (cpf_professor),
    INDEX idx_nome         (nome_completo),
    INDEX idx_departamento (departamento),
    INDEX idx_titulacao    (titulacao)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE DIMENSÃO: DISCIPLINA
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dim_disciplina (
    sk_disciplina         INT PRIMARY KEY AUTO_INCREMENT,
    codigo_disciplina     VARCHAR(20) UNIQUE NOT NULL,
    nome_disciplina       VARCHAR(150) NOT NULL,
    ementa                TEXT,
    carga_horaria_total   INT,
    carga_horaria_teorica INT,
    carga_horaria_pratica INT,
    numero_creditos       INT,
    semestre_ideal        INT,
    eh_obrigatoria        BOOLEAN DEFAULT TRUE,
    eh_ativa              BOOLEAN DEFAULT TRUE,
    INDEX idx_codigo   (codigo_disciplina),
    INDEX idx_nome     (nome_disciplina),
    INDEX idx_semestre (semestre_ideal)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE FATOS: RECEITA FINANCEIRA
-- ==============================================================================
CREATE TABLE IF NOT EXISTS fato_receita (
    sk_aluno                  INT,
    sk_curso                  INT,
    sk_unidade                INT NOT NULL,
    sk_tempo_vencimento       INT,
    sk_tempo_pagamento        INT,
    numero_contrato           INT,
    numero_mensalidade        INT,
    valor_mensalidade_liquido DECIMAL(10,2),
    valor_desconto_bolsa      DECIMAL(10,2),
    valor_desconto_outro      DECIMAL(10,2),
    valor_multa               DECIMAL(10,2),
    valor_juros               DECIMAL(10,2),
    valor_total_devido        DECIMAL(10,2),
    valor_pago                DECIMAL(10,2),
    valor_em_aberto           DECIMAL(10,2),
    dias_em_atraso            INT DEFAULT 0,
    status_pagamento          VARCHAR(50),
    vezes_renegociado         INT DEFAULT 0,
    eh_em_atraso              BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_fato_receita_aluno      FOREIGN KEY (sk_aluno)            REFERENCES dim_aluno(sk_aluno),
    CONSTRAINT fk_fato_receita_curso      FOREIGN KEY (sk_curso)            REFERENCES dim_curso(sk_curso),
    CONSTRAINT fk_fato_receita_unidade    FOREIGN KEY (sk_unidade)          REFERENCES dim_unidade(sk_unidade),
    CONSTRAINT fk_fato_receita_tempo_venc FOREIGN KEY (sk_tempo_vencimento) REFERENCES dim_tempo(sk_tempo),
    CONSTRAINT fk_fato_receita_tempo_pag  FOREIGN KEY (sk_tempo_pagamento)  REFERENCES dim_tempo(sk_tempo),
    PRIMARY KEY (sk_aluno, sk_curso, sk_unidade, sk_tempo_vencimento, numero_mensalidade),
    INDEX idx_status      (status_pagamento, sk_tempo_vencimento),
    INDEX idx_atraso      (eh_em_atraso, sk_curso),
    INDEX idx_curso_tempo (sk_curso, sk_tempo_vencimento),
    INDEX idx_aluno_tempo (sk_aluno, sk_tempo_vencimento)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE FATOS: DESEMPENHO ACADÊMICO
-- ==============================================================================
CREATE TABLE IF NOT EXISTS fato_desempenho (
    sk_aluno           INT,
    sk_professor       INT,
    sk_disciplina      INT,
    sk_curso           INT,
    sk_tempo_conclusao INT,
    numero_turma       INT,
    numero_matricula   INT,
    nota_obtida        DECIMAL(4,2),
    nota_maxima        DECIMAL(4,2) DEFAULT 10.00,
    frequencia_percentual INT,
    presencas          INT,
    faltas             INT,
    total_aulas        INT,
    status_disciplina  VARCHAR(50),
    eh_aprovado        BOOLEAN,
    eh_reprovado       BOOLEAN,
    eh_trancado        BOOLEAN,
    semestre_cursado   INT,
    ano_cursado        INT,
    CONSTRAINT fk_fato_desemp_aluno      FOREIGN KEY (sk_aluno)           REFERENCES dim_aluno(sk_aluno),
    CONSTRAINT fk_fato_desemp_professor  FOREIGN KEY (sk_professor)       REFERENCES dim_professor(sk_professor),
    CONSTRAINT fk_fato_desemp_disciplina FOREIGN KEY (sk_disciplina)      REFERENCES dim_disciplina(sk_disciplina),
    CONSTRAINT fk_fato_desemp_curso      FOREIGN KEY (sk_curso)           REFERENCES dim_curso(sk_curso),
    CONSTRAINT fk_fato_desemp_tempo      FOREIGN KEY (sk_tempo_conclusao) REFERENCES dim_tempo(sk_tempo),
    PRIMARY KEY (sk_aluno, sk_disciplina, sk_tempo_conclusao, numero_turma),
    INDEX idx_status      (status_disciplina, sk_curso),
    INDEX idx_aprovado    (eh_aprovado, sk_tempo_conclusao),
    INDEX idx_professor   (sk_professor, sk_tempo_conclusao),
    INDEX idx_curso_tempo (sk_curso, sk_tempo_conclusao)
) ENGINE=InnoDB;

-- ==============================================================================
-- TABELA DE FATOS: FOLHA DE PAGAMENTO
-- ==============================================================================
CREATE TABLE IF NOT EXISTS fato_folha_pagamento (
    sk_professor              INT,
    sk_tempo                  INT,
    numero_folha              INT,
    mes_referencia            INT,
    ano_referencia            INT,
    salario_base              DECIMAL(10,2),
    adicional_noturno         DECIMAL(10,2) DEFAULT 0,
    adicional_insalubridade   DECIMAL(10,2) DEFAULT 0,
    hora_extra                DECIMAL(10,2) DEFAULT 0,
    gratificacao              DECIMAL(10,2) DEFAULT 0,
    bonus_desempenho          DECIMAL(10,2) DEFAULT 0,
    desconto_inss             DECIMAL(10,2) DEFAULT 0,
    desconto_irrf             DECIMAL(10,2) DEFAULT 0,
    desconto_sindicato        DECIMAL(10,2) DEFAULT 0,
    desconto_vale_refeicao    DECIMAL(10,2) DEFAULT 0,
    desconto_vale_transporte  DECIMAL(10,2) DEFAULT 0,
    desconto_outro            DECIMAL(10,2) DEFAULT 0,
    salario_bruto             DECIMAL(10,2),
    total_deducoes            DECIMAL(10,2),
    salario_liquido           DECIMAL(10,2),
    CONSTRAINT fk_fato_folha_prof  FOREIGN KEY (sk_professor) REFERENCES dim_professor(sk_professor),
    CONSTRAINT fk_fato_folha_tempo FOREIGN KEY (sk_tempo)     REFERENCES dim_tempo(sk_tempo),
    PRIMARY KEY (sk_professor, sk_tempo),
    INDEX idx_periodo (ano_referencia, mes_referencia),
    INDEX idx_tempo   (sk_tempo)
) ENGINE=InnoDB;

-- ==============================================================================
-- VIEWS ANALÍTICAS
-- ==============================================================================

CREATE OR REPLACE VIEW v_receita_por_curso_mes AS
SELECT
    dc.sk_curso, dc.nome_curso, dc.departamento,
    dt.ano, dt.mes, dt.nome_mes,
    COUNT(DISTINCT fr.numero_contrato)   AS qtd_contratos,
    COUNT(DISTINCT fr.sk_aluno)          AS qtd_alunos,
    SUM(fr.valor_mensalidade_liquido)    AS receita_esperada,
    SUM(fr.valor_pago)                   AS receita_realizada,
    SUM(fr.valor_em_aberto)              AS receita_pendente,
    ROUND(100.0 * SUM(fr.valor_pago) / SUM(fr.valor_mensalidade_liquido), 2) AS taxa_recebimento,
    COUNT(CASE WHEN fr.eh_em_atraso THEN 1 END)                              AS qtd_atrasadas,
    SUM(CASE WHEN fr.eh_em_atraso THEN fr.valor_total_devido ELSE 0 END)     AS valor_em_atraso,
    SUM(fr.valor_desconto_bolsa)         AS total_bolsas
FROM fato_receita fr
JOIN dim_curso dc ON dc.sk_curso = fr.sk_curso
JOIN dim_tempo dt ON dt.sk_tempo = fr.sk_tempo_vencimento
GROUP BY dc.sk_curso, dc.nome_curso, dc.departamento, dt.ano, dt.mes, dt.nome_mes;

CREATE OR REPLACE VIEW v_desempenho_por_curso_semestre AS
SELECT
    dc.sk_curso, dc.nome_curso,
    dt.ano, fd.semestre_cursado,
    COUNT(DISTINCT fd.sk_aluno)             AS qtd_alunos,
    COUNT(DISTINCT fd.numero_matricula)     AS qtd_matriculas,
    ROUND(AVG(fd.nota_obtida), 2)           AS nota_media,
    ROUND(AVG(fd.frequencia_percentual), 2) AS frequencia_media,
    SUM(CASE WHEN fd.eh_aprovado  THEN 1 ELSE 0 END) AS aprovados,
    SUM(CASE WHEN fd.eh_reprovado THEN 1 ELSE 0 END) AS reprovados,
    SUM(CASE WHEN fd.eh_trancado  THEN 1 ELSE 0 END) AS trancados,
    ROUND(100.0 * SUM(CASE WHEN fd.eh_aprovado  THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_aprovacao,
    ROUND(100.0 * SUM(CASE WHEN fd.eh_reprovado THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_reprovacao
FROM fato_desempenho fd
JOIN dim_curso dc ON dc.sk_curso = fd.sk_curso
JOIN dim_tempo dt ON dt.sk_tempo = fd.sk_tempo_conclusao
GROUP BY dc.sk_curso, dc.nome_curso, dt.ano, fd.semestre_cursado;

CREATE OR REPLACE VIEW v_inadimplencia_por_curso AS
SELECT
    dc.sk_curso, dc.nome_curso, dc.departamento,
    COUNT(DISTINCT fr.sk_aluno)                                                    AS qtd_alunos_total,
    COUNT(DISTINCT CASE WHEN fr.eh_em_atraso THEN fr.sk_aluno END)                AS qtd_inadimplentes,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN fr.eh_em_atraso THEN fr.sk_aluno END)
          / NULLIF(COUNT(DISTINCT fr.sk_aluno), 0), 2)                            AS taxa_inadimplencia_pct,
    SUM(CASE WHEN fr.eh_em_atraso THEN fr.valor_total_devido ELSE 0 END)          AS total_em_atraso,
    SUM(CASE WHEN fr.eh_em_atraso THEN fr.dias_em_atraso     ELSE 0 END)          AS dias_atraso_total
FROM fato_receita fr
JOIN dim_curso dc ON dc.sk_curso = fr.sk_curso
GROUP BY dc.sk_curso, dc.nome_curso, dc.departamento;

CREATE OR REPLACE VIEW v_custo_operacional_departamento AS
SELECT
    dp.departamento,
    dt.ano, dt.mes, dt.nome_mes,
    COUNT(DISTINCT ffp.sk_professor)   AS qtd_funcionarios,
    SUM(ffp.salario_bruto)             AS custo_bruto,
    SUM(ffp.total_deducoes)            AS total_deducoes,
    SUM(ffp.salario_liquido)           AS custo_liquido,
    ROUND(AVG(ffp.salario_liquido), 2) AS salario_medio
FROM fato_folha_pagamento ffp
JOIN dim_professor dp ON dp.sk_professor = ffp.sk_professor
JOIN dim_tempo     dt ON dt.sk_tempo     = ffp.sk_tempo
WHERE dp.eh_ativo = TRUE
GROUP BY dp.departamento, dt.ano, dt.mes, dt.nome_mes;

-- ==============================================================================
-- PROCEDURES ETL
-- ==============================================================================

DELIMITER $$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_tempo()
BEGIN
    DECLARE v_data     DATE;
    DECLARE v_sk_tempo INT;
    DECLARE v_inicio   DATE;
    DECLARE v_fim      DATE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar dimensão tempo' AS resultado;
    END;

    SET v_inicio = DATE('2015-01-01');
    SET v_fim    = DATE_ADD(CURDATE(), INTERVAL 5 YEAR);
    SET v_data   = v_inicio;

    START TRANSACTION;
        WHILE v_data <= v_fim DO
            SET v_sk_tempo = CAST(DATE_FORMAT(v_data, '%Y%m%d') AS UNSIGNED);
            INSERT IGNORE INTO dim_tempo (
                sk_tempo, data_completa, ano, mes, trimestre, semestre,
                dia_mes, dia_semana, nome_mes, nome_mes_abrev,
                nome_dia, nome_dia_abrev, eh_fim_semana, semana_ano
            ) VALUES (
                v_sk_tempo, v_data,
                YEAR(v_data), MONTH(v_data), QUARTER(v_data), CEILING(MONTH(v_data)/6),
                DAY(v_data), DAYOFWEEK(v_data),
                MONTHNAME(v_data), LEFT(MONTHNAME(v_data),3),
                DAYNAME(v_data),   LEFT(DAYNAME(v_data),3),
                (DAYOFWEEK(v_data) IN (1,7)),
                WEEK(v_data)
            );
            SET v_data = DATE_ADD(v_data, INTERVAL 1 DAY);
        END WHILE;
    COMMIT;
    SELECT '✓ Dimensão TEMPO carregada com sucesso' AS resultado;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_unidades()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar dimensão unidade' AS resultado;
    END;
    START TRANSACTION;
        INSERT IGNORE INTO dim_unidade (codigo_unidade, nome_unidade, municipio, estado, tipo_unidade) VALUES
            ('POLO-SP-01', 'Campus São Paulo — Sede', 'São Paulo', 'SP', 'Sede'),
            ('POLO-MG-01', 'Campus Belo Horizonte', 'Belo Horizonte', 'MG', 'Polo'),
            ('POLO-PR-01', 'Campus Curitiba', 'Curitiba', 'PR', 'Polo');
    COMMIT;
    SELECT '✓ Dimensão UNIDADE carregada (idempotente via INSERT IGNORE)' AS resultado;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_alunos()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar alunos' AS resultado;
    END;
    START TRANSACTION;
        DELETE FROM dim_aluno;
        INSERT INTO dim_aluno (
            cpf_aluno, rgm_aluno, nome_completo, nome_primeiro, nome_sobrenome,
            data_nascimento, genero, nacionalidade, curso_atual, tipo_bolsa,
            data_matricula, data_desligamento, status_aluno, eh_ativo
        )
        SELECT
            p.pk_cpf,
            a.rgm,
            CONCAT(p.primeiro_nome, ' ', p.sobrenome),
            p.primeiro_nome,
            p.sobrenome,
            p.data_nascimento,
            p.genero,
            p.nacionalidade,
            c.nome,
            COALESCE(dbol.tipo_bolsa, 'Sem Bolsa'),
            a.data_matricula_inicial,
            NULL,
            sa.descricao,
            (a.fk_status = 1)
        FROM sisgesc.tb_alunos a
        JOIN sisgesc.tb_pessoas p       ON p.pk_cpf = a.pk_fk_cpf
        JOIN sisgesc.tb_status_aluno sa ON sa.pk_status_aluno = a.fk_status
        JOIN sisgesc.tb_aluno_curso ac  ON ac.fk_cpf_aluno = a.pk_fk_cpf
        JOIN sisgesc.tb_cursos c        ON c.pk_curso = ac.fk_curso
        LEFT JOIN sisgesc.tb_contratos_educacionais ce
            ON ce.fk_cpf_aluno = a.pk_fk_cpf AND ce.is_ativo = TRUE
        LEFT JOIN (
            SELECT cd.fk_contrato, MAX(db.tipo_bolsa) AS tipo_bolsa
            FROM sisgesc.tb_contrato_desconto cd
            JOIN sisgesc.tb_descontos_bolsas db ON db.pk_desconto = cd.fk_desconto
            GROUP BY cd.fk_contrato
        ) dbol ON dbol.fk_contrato = ce.pk_contrato
        WHERE p.pk_cpf IS NOT NULL;
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' alunos carregados') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_cursos()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar cursos' AS resultado;
    END;
    START TRANSACTION;
        DELETE FROM dim_curso;
        INSERT INTO dim_curso (
            codigo_curso, nome_curso, sigla_curso, departamento,
            nivel_academico, duracao_semestres, carga_horaria_total, eh_ativo
        )
        SELECT pk_curso, nome, NULL AS sigla, 'Sem Departamento',
               tc.descricao, NULL AS duracao_semestres, NULL AS carga_horaria, TRUE AS is_ativo
        FROM sisgesc.tb_cursos c
        JOIN sisgesc.tb_tipo_curso tc ON tc.pk_tipo_curso = c.fk_tipo_curso;
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' cursos carregados') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_professores()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar professores' AS resultado;
    END;
    START TRANSACTION;
        DELETE FROM dim_professor;
        INSERT INTO dim_professor (
            cpf_professor, nome_completo, cargo, departamento,
            titulacao, data_admissao, eh_ativo
        )
        SELECT
            p.pk_cpf,
            CONCAT(p.primeiro_nome, ' ', p.sobrenome),
            'Professor',
            dep.nome,
            ti.nome,
            f.data_admissao,
            (f.data_demissao IS NULL)
        FROM sisgesc.tb_funcionarios f
        JOIN sisgesc.tb_pessoas p       ON p.pk_cpf = f.pk_fk_cpf
        JOIN sisgesc.tb_professores pr  ON pr.pk_fk_cpf = f.pk_fk_cpf
        JOIN sisgesc.tb_departamentos dep ON dep.pk_departamento = f.fk_departamento
        JOIN sisgesc.tb_titulacoes ti   ON ti.pk_titulacao = pr.fk_titulacao
        WHERE f.data_demissao IS NULL;
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' professores carregados') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_disciplinas()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar disciplinas' AS resultado;
    END;
    START TRANSACTION;
        DELETE FROM dim_disciplina;
        INSERT INTO dim_disciplina (
            codigo_disciplina, nome_disciplina, carga_horaria_total,
            numero_creditos, eh_obrigatoria, eh_ativa
        )
        SELECT pk_disciplina, nome, carga_horaria,
               CEIL(carga_horaria/15), TRUE, TRUE AS is_ativa
        FROM sisgesc.tb_disciplinas;
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' disciplinas carregadas') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_fato_receita()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar fato receita' AS resultado;
    END;
    START TRANSACTION;
        INSERT INTO fato_receita (
            sk_aluno, sk_curso, sk_unidade, sk_tempo_vencimento, sk_tempo_pagamento,
            numero_contrato, numero_mensalidade,
            valor_mensalidade_liquido, valor_desconto_bolsa,
            valor_multa, valor_juros,
            valor_total_devido, valor_pago, valor_em_aberto,
            dias_em_atraso, status_pagamento, eh_em_atraso
        )
        SELECT
            da.sk_aluno,
            dc.sk_curso,
            du.sk_unidade,
            CAST(DATE_FORMAT(m.data_vencimento, '%Y%m%d') AS UNSIGNED),
            CASE WHEN pg.data_pagamento IS NOT NULL
                 THEN CAST(DATE_FORMAT(pg.data_pagamento, '%Y%m%d') AS UNSIGNED)
                 ELSE NULL END,
            m.fk_contrato,
            m.pk_mensalidade,
            m.valor_liquido,
            COALESCE((
                SELECT SUM(
                    COALESCE(cd.valor_fixo_desconto, 0)
                    + (m.valor_liquido * COALESCE(cd.percentual_desconto, 0) / 100.0)
                )
                FROM sisgesc.tb_contrato_desconto cd
                WHERE cd.fk_contrato = ce.pk_contrato
            ), 0),
            m.valor_multa,
            m.valor_juros,
            m.valor_liquido + COALESCE(m.valor_multa,0) + COALESCE(m.valor_juros,0),
            COALESCE(pg.valor_pago, 0),
            (m.valor_liquido + COALESCE(m.valor_multa,0) + COALESCE(m.valor_juros,0))
                - COALESCE(pg.valor_pago, 0),
            GREATEST(DATEDIFF(CURDATE(), m.data_vencimento), 0),
            sp.descricao,
            (m.data_vencimento < CURDATE() AND sp.descricao IN ('Pendente','Atrasado'))
        FROM sisgesc.tb_mensalidades m
        JOIN sisgesc.tb_contratos_educacionais ce ON ce.pk_contrato = m.fk_contrato
        JOIN sisgesc.tb_alunos a                  ON a.pk_fk_cpf = ce.fk_cpf_aluno
        JOIN sisgesc.tb_pessoas p                 ON p.pk_cpf = a.pk_fk_cpf
        JOIN dim_aluno da                         ON da.cpf_aluno = p.pk_cpf
        JOIN sisgesc.tb_aluno_curso ac            ON ac.fk_cpf_aluno = a.pk_fk_cpf
        JOIN dim_curso dc                         ON dc.codigo_curso = ac.fk_curso
        JOIN dim_unidade du                       ON du.codigo_unidade = 'POLO-SP-01'
        LEFT JOIN sisgesc.tb_pagamentos pg        ON pg.fk_mensalidade = m.pk_mensalidade
        LEFT JOIN sisgesc.tb_status_pagamento sp  ON sp.pk_status_pagamento = m.fk_status
        WHERE m.pk_mensalidade IS NOT NULL
        ON DUPLICATE KEY UPDATE
            valor_pago       = VALUES(valor_pago),
            valor_em_aberto  = VALUES(valor_em_aberto),
            dias_em_atraso   = VALUES(dias_em_atraso),
            eh_em_atraso     = VALUES(eh_em_atraso),
            status_pagamento = VALUES(status_pagamento);
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' registros de receita carregados') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_fato_desempenho()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar fato desempenho' AS resultado;
    END;
    START TRANSACTION;
        INSERT INTO fato_desempenho (
            sk_aluno, sk_professor, sk_disciplina, sk_curso,
            sk_tempo_conclusao, numero_turma, numero_matricula,
            nota_obtida, frequencia_percentual,
            presencas, faltas, total_aulas,
            status_disciplina, eh_aprovado, eh_reprovado, eh_trancado,
            semestre_cursado, ano_cursado
        )
        SELECT
            da.sk_aluno,
            dp.sk_professor,
            dd.sk_disciplina,
            dc.sk_curso,
            CAST(DATE_FORMAT(rm.data_fechamento, '%Y%m%d') AS UNSIGNED),
            m.fk_turma,
            m.pk_matricula,
            rm.media_final,
            ROUND(100.0 * (1 - (COALESCE(rm.total_faltas,0) / d.carga_horaria)), 0),
            d.carga_horaria - COALESCE(rm.total_faltas, 0),
            COALESCE(rm.total_faltas, 0),
            d.carga_horaria,
            rm.situacao,
            (rm.situacao = 'aprovado'),
            (rm.situacao = 'reprovado'),
            (rm.situacao = 'trancado'),
            per.semestre,
            YEAR(rm.data_fechamento)
        FROM sisgesc.tb_resultado_matricula rm
        JOIN sisgesc.tb_matriculas m    ON m.pk_matricula = rm.fk_matricula
        JOIN sisgesc.tb_disciplinas d   ON d.pk_disciplina = m.fk_disciplina
        JOIN sisgesc.tb_turmas t        ON t.pk_turma = m.fk_turma
        JOIN sisgesc.tb_periodos per    ON per.pk_periodo = m.fk_periodo
        JOIN sisgesc.tb_alunos a        ON a.pk_fk_cpf = m.fk_cpf_aluno
        JOIN sisgesc.tb_aulas au        ON au.fk_turma = m.fk_turma AND au.fk_disciplina = m.fk_disciplina
        JOIN sisgesc.tb_professores pr  ON pr.pk_fk_cpf = au.fk_cpf_professor
        JOIN dim_aluno da               ON da.cpf_aluno = a.pk_fk_cpf
        JOIN dim_professor dp           ON dp.cpf_professor = pr.pk_fk_cpf
        JOIN dim_disciplina dd          ON dd.codigo_disciplina = d.pk_disciplina
        JOIN dim_curso dc               ON dc.codigo_curso = t.fk_curso
        WHERE rm.data_fechamento IS NOT NULL
        ON DUPLICATE KEY UPDATE
            nota_obtida           = VALUES(nota_obtida),
            frequencia_percentual = VALUES(frequencia_percentual),
            status_disciplina     = VALUES(status_disciplina),
            eh_aprovado           = VALUES(eh_aprovado),
            eh_reprovado          = VALUES(eh_reprovado);
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' registros de desempenho carregados') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carregar_fato_folha()
BEGIN
    DECLARE v_registros INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'ERRO ao carregar fato folha' AS resultado;
    END;
    START TRANSACTION;
        INSERT INTO fato_folha_pagamento (
            sk_professor, sk_tempo,
            numero_folha, mes_referencia, ano_referencia,
            salario_bruto, total_deducoes, salario_liquido
        )
        SELECT
            dp.sk_professor,
            CAST(CONCAT(fp.ano, LPAD(fp.mes, 2, '0'), '01') AS UNSIGNED),
            fp.pk_folha,
            fp.mes,
            fp.ano,
            fp.salario_bruto,
            fp.total_descontos,
            fp.salario_liquido
        FROM sisgesc.tb_folha_pagamento fp
        JOIN sisgesc.tb_funcionarios f ON f.pk_fk_cpf = fp.fk_cpf_funcionario
        JOIN dim_professor dp          ON dp.cpf_professor = f.pk_fk_cpf
        ON DUPLICATE KEY UPDATE
            salario_bruto   = VALUES(salario_bruto),
            total_deducoes  = VALUES(total_deducoes),
            salario_liquido = VALUES(salario_liquido);
        SELECT ROW_COUNT() INTO v_registros;
        SELECT CONCAT('✓ ', v_registros, ' registros de folha carregados') AS resultado;
    COMMIT;
END$$

CREATE PROCEDURE IF NOT EXISTS sp_etl_carga_completa_dw()
BEGIN
    DECLARE v_inicio DATETIME;
    DECLARE v_fim    DATETIME;
    SET v_inicio = NOW();
    SELECT '🚀 INICIANDO CARGA DO DATA WAREHOUSE...' AS log;
    CALL sp_etl_carregar_tempo();
    CALL sp_etl_carregar_unidades();
    CALL sp_etl_carregar_cursos();
    CALL sp_etl_carregar_alunos();
    CALL sp_etl_carregar_professores();
    CALL sp_etl_carregar_disciplinas();
    CALL sp_etl_carregar_fato_receita();
    CALL sp_etl_carregar_fato_desempenho();
    CALL sp_etl_carregar_fato_folha();
    SET v_fim = NOW();
    SELECT CONCAT('✅ CARGA COMPLETA FINALIZADA | Duração: ', TIMEDIFF(v_fim, v_inicio)) AS resultado;
END$$

DELIMITER ;

-- ==============================================================================
-- VALIDAÇÃO OBRIGATÓRIA: OLTP = OLAP
-- Execute após o ETL para confirmar que a carga foi correta.
-- ==============================================================================
SELECT '=== VALIDAÇÃO OLTP × OLAP ===' AS etapa;
SELECT SUM(valor_liquido)             AS total_oltp FROM sisgesc.tb_mensalidades;
SELECT SUM(valor_mensalidade_liquido) AS total_olap FROM dw_sisgesc.fato_receita;
-- Os dois valores DEVEM ser iguais. Diferença = erro no ETL.
