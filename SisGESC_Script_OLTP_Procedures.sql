-- ========================================================================
--  SisGESC — Stored Procedures OLTP (MySQL)
--  Sistema de Gestão Escolar — Universidade Privada
-- ========================================================================
--  DESCRIÇÃO
--  
--  16 stored procedures que cobrem os principais casos de uso do sistema:
--    • Cadastro de pessoas, alunos e funcionários
--    • Matrícula inicial e em disciplinas
--    • Trancamento, notas, faltas e fechamento de período
--    • Admissão, folha de pagamento e férias
--    • Mensalidades, pagamentos e relatório financeiro
--
--  GARANTIAS ACID
--  --------------
--    Atomicidade  — tudo ou nada dentro de START TRANSACTION / COMMIT
--    Consistência — constraints + SIGNAL SQLSTATE '45000' para regras de negócio
--    Isolamento   — cada procedure opera em sua própria transação
--    Durabilidade — após COMMIT os dados persistem em disc

USE sisgesc;

DELIMITER $$

-- ──────────────────────────
-- T01 — CADASTRO PESSOA
-- ──────────────────────────

DROP PROCEDURE IF EXISTS sp_T01_cadastrar_pessoa $$

CREATE PROCEDURE sp_T01_cadastrar_pessoa(
    IN p_cpf CHAR(11),
    IN p_primeiro_nome VARCHAR(60),
    IN p_sobrenome VARCHAR(80)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao cadastrar pessoa';
    END;

    START TRANSACTION;

        -- Validação: CPF obrigatório
    IF p_cpf IS NULL OR p_cpf = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF é obrigatório';
    END IF;
 
    -- Validação: formato do CPF
    IF LENGTH(p_cpf) <> 11 OR p_cpf REGEXP '[^0-9]' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF inválido: deve conter 11 dígitos numéricos';
    END IF;
 
    SELECT COUNT(*) INTO v_existe
    FROM tb_pessoas
    WHERE pk_cpf = p_cpf;
 
    IF v_existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa já cadastrada';
    END IF;
 
    INSERT INTO tb_pessoas (pk_cpf, primeiro_nome, sobrenome)
    VALUES (p_cpf, p_primeiro_nome, p_sobrenome);
 
    COMMIT;
END $$

-- =====================================
-- T02 - TELEFONE
-- =====================================

DROP PROCEDURE IF EXISTS sp_T02_cadastrar_telefone $$

CREATE PROCEDURE sp_T02_cadastrar_telefone(
    IN p_cpf CHAR(11),
    IN p_telefone VARCHAR(11)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao cadastrar telefone';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_existe FROM tb_pessoas WHERE pk_cpf = p_cpf;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não encontrada';
    END IF;

    IF p_telefone IS NULL OR p_telefone = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Telefone é obrigatório';
    END IF;
 
    IF LENGTH(p_telefone) NOT IN (10, 11) OR p_telefone REGEXP '[^0-9]' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Telefone inválido: deve conter 10 ou 11 dígitos numéricos';
    END IF;
 
    INSERT INTO tb_telefones(fk_cpf, telefone)
    VALUES(p_cpf, p_telefone);
 
    COMMIT;
END $$
 
-- ───────────────────────────────────
-- T03 — MATRÍCULA INICIAL DE ALUNO EM CURSO
-- ───────────────────────────────────

DROP PROCEDURE IF EXISTS sp_T03_matricular_aluno $$

CREATE PROCEDURE sp_T03_matricular_aluno(
    IN p_cpf CHAR(11),
    IN p_codigo_curso INT,
    OUT p_codigo_matricula INT
)
BEGIN
    DECLARE v_pessoa INT DEFAULT 0;
    DECLARE v_curso_existe INT DEFAULT 0;
    DECLARE v_ja_matriculado INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro ao matricular aluno';
    END;

    START TRANSACTION;

     SELECT COUNT(*) INTO v_pessoa
    FROM tb_pessoas
    WHERE pk_cpf = p_cpf;

    IF v_pessoa = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não encontrada';
    END IF;
    
    SELECT COUNT(*) INTO v_curso_existe
    FROM tb_cursos
    WHERE pk_codigo_curso = p_codigo_curso;
 
    IF v_curso_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Curso não encontrado';
    END IF;

    SELECT COUNT(*) INTO v_ja_matriculado
    FROM tb_matriculas
    WHERE fk_cpf = p_cpf
      AND fk_codigo_curso = p_codigo_curso
      AND status_matricula NOT IN ('CONCLUIDA', 'CANCELADA');
 
    IF v_ja_matriculado > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aluno já possui matrícula ativa neste curso';
    END IF;
    
    INSERT INTO tb_matriculas (fk_cpf, fk_codigo_curso, data_matricula, status_matricula)
    VALUES (p_cpf, p_codigo_curso, NOW(), 'ATIVA');
 
    SET p_codigo_matricula = LAST_INSERT_ID();
 
    COMMIT;
END $$

-- ────────────────────────────────────
-- T04 — TRANCAMENTO DE MATRÍCULA
-- ────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_T04_trancar_matricula $$

CREATE PROCEDURE sp_T04_trancar_matricula(
    IN p_matricula INT
)
BEGIN
     DECLARE v_existe INT DEFAULT 0;
     DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao trancar matrícula';
    END;

    START TRANSACTION;

    SELECT COUNT(*), status_matricula
      INTO v_existe, v_status
    FROM tb_matriculas
    WHERE pk_codigo_matricula = p_matricula;
 
    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula não encontrada';
    END IF;
 
        IF v_status <> 'ATIVA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Somente matrículas com status ATIVA podem ser trancadas';
    END IF;
 
    UPDATE tb_matriculas
    SET status_matricula = 'TRANCADA',
        data_trancamento = NOW()
    WHERE pk_codigo_matricula = p_matricula;
 
    COMMIT;
END $$
    
-- ────────────────────────────────
-- T05 — LANÇAMENTO DE NOTA COM (AUDITORIA)
-- ────────────────────────────────

DROP PROCEDURE IF EXISTS sp_T05_lancar_nota $$

CREATE PROCEDURE sp_T05_lancar_nota(
    IN p_matricula INT,
    IN p_disciplina INT,
    IN p_nota DECIMAL(5,2)
)
BEGIN
    DECLARE v_matricula_existe  INT DEFAULT 0;
    DECLARE v_disciplina_existe INT DEFAULT 0;
    DECLARE v_nota_existente    INT DEFAULT 0; 

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao lançar nota (verifique nota ou registro de auditoria)';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_matricula_existe
    FROM tb_matriculas
    WHERE pk_codigo_matricula = p_matricula;

    IF v_matricula_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula não encontrada';
    END IF;
 
    SELECT COUNT(*) INTO v_disciplina_existe
    FROM tb_disciplinas
    WHERE pk_codigo_disciplina = p_disciplina;
 
    IF v_disciplina_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Disciplina não encontrada';
    END IF;
 
    SELECT COUNT(*) INTO v_nota_existente
    FROM tb_notas
    WHERE fk_matricula = p_matricula
      AND fk_disciplina = p_disciplina;
 
    IF v_nota_existente > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nota já lançada para esta matrícula e disciplina. Use UPDATE para alterar.';
    END IF;
 
    INSERT INTO tb_notas(fk_matricula, fk_disciplina, nota)
    VALUES(p_matricula, p_disciplina, p_nota);
 
   -- Registro de auditoria — se falhar, a transação inteira é revertida
    INSERT INTO tb_auditoria_notas(fk_matricula, fk_disciplina, nota, data_registro)
    VALUES(p_matricula, p_disciplina, p_nota, NOW());
 
    COMMIT;
END $$

-- ─────────────────────────────────
-- T06 — REGISTRO DE FALTAS
-- ─────────────────────────────────

DROP PROCEDURE IF EXISTS sp_T06_registrar_falta $$
 
CREATE PROCEDURE sp_T06_registrar_falta(
    IN p_matricula INT,
    IN p_disciplina INT,
    IN p_qtd_faltas INT
)
BEGIN
    DECLARE v_matricula_existe  INT DEFAULT 0;
    DECLARE v_disciplina_existe INT DEFAULT 0;  
    DECLARE v_vinculo_existe    INT DEFAULT 0; -- vínculo matrícula/disciplina
 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao registrar faltas';
    END;
 
    START TRANSACTION;
 
    SELECT COUNT(*) INTO v_matricula_existe
    FROM tb_matriculas
    WHERE pk_codigo_matricula = p_matricula;
 
    IF v_matricula_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula não encontrada';
    END IF;
 
    SELECT COUNT(*) INTO v_disciplina_existe
    FROM tb_disciplinas
    WHERE pk_codigo_disciplina = p_disciplina;
 
    IF v_disciplina_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Disciplina não encontrada';
    END IF;
 
     SELECT COUNT(*) INTO v_vinculo_existe
    FROM tb_matricula_disciplinas
    WHERE fk_matricula = p_matricula
      AND fk_disciplina = p_disciplina;
 
    IF v_vinculo_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Aluno não está matriculado nesta disciplina';
    END IF;
 
    INSERT INTO tb_faltas(fk_matricula, fk_disciplina, quantidade_faltas)
    VALUES(p_matricula, p_disciplina, p_qtd_faltas);
 
    COMMIT;
END $$

-- ──────────────────────────────────────
-- T07 — FECHAMENTO DE PERÍODO (APROVAÇÃO / REPROVAÇÃO)
-- ──────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_T07_fechamento_periodo $$
 
CREATE PROCEDURE sp_T07_fechamento_periodo(
    IN p_semestre VARCHAR(10),
    IN p_nota_minima DECIMAL(5,2),   
    IN p_faltas_maximas INT          
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao fechar período';
    END;
 
    START TRANSACTION;
 
    -- Valida se existem matrículas ativas no semestre informado
    IF NOT EXISTS (
        SELECT 1 FROM tb_matriculas
        WHERE semestre = p_semestre
          AND status_matricula = 'ATIVA'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nenhuma matrícula ativa encontrada para o semestre informado';
    END IF;
 
    -- APROVAÇÃO: média >= nota_minima E faltas <= limite em todas as disciplinas
    UPDATE tb_matriculas m
    SET status_matricula = 'CONCLUIDA',
        resultado_final  = 'APROVADO'
    WHERE m.semestre = p_semestre
      AND m.status_matricula = 'ATIVA'
      -- todas as disciplinas com nota suficiente
      AND NOT EXISTS (
          SELECT 1
          FROM tb_matricula_disciplinas md
          LEFT JOIN tb_notas n
              ON n.fk_matricula  = md.fk_matricula
             AND n.fk_disciplina = md.fk_disciplina
          LEFT JOIN tb_faltas f
              ON f.fk_matricula  = md.fk_matricula
             AND f.fk_disciplina = md.fk_disciplina
          WHERE md.fk_matricula = m.pk_codigo_matricula
            AND (
                n.nota IS NULL                          
                OR n.nota < p_nota_minima               
                OR COALESCE(f.quantidade_faltas, 0) > p_faltas_maximas 
            )
      );
 
    -- REPROVAÇÃO: restante das matrículas ativas do semestre
    UPDATE tb_matriculas m
    SET status_matricula = 'CONCLUIDA',
        resultado_final  = 'REPROVADO'
    WHERE m.semestre = p_semestre
      AND m.status_matricula = 'ATIVA';
 
    COMMIT;
END $$

-- =====================================
-- T08 - MATRÍCULA EM DISCIPLINAS DO SEMESTRE
-- =====================================

DROP PROCEDURE IF EXISTS sp_T08_matricular_disciplina $$

CREATE PROCEDURE sp_T08_matricular_disciplina(
    IN p_matricula INT,
    IN p_disciplina INT
)
BEGIN
    DECLARE v_matricula_existe  INT DEFAULT 0;
    DECLARE v_disciplina_existe INT DEFAULT 0;  
    DECLARE v_ja_vinculada      INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao matricular em disciplina';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_matricula_existe
    FROM tb_matriculas
    WHERE pk_codigo_matricula = p_matricula;

    IF v_matricula_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula não encontrada';
    END IF;

    SELECT COUNT(*) INTO v_disciplina_existe
    FROM tb_disciplinas
    WHERE pk_codigo_disciplina = p_disciplina;

    IF v_disciplina_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Disciplina não encontrada';
    END IF;


    SELECT COUNT(*) INTO v_ja_vinculada
    FROM tb_matricula_disciplinas
    WHERE fk_matricula = p_matricula
      AND fk_disciplina = p_disciplina;
 
    IF v_ja_vinculada > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Aluno já está matriculado nesta disciplina';
    END IF;
 
    INSERT INTO tb_matricula_disciplinas(fk_matricula, fk_disciplina)
    VALUES(p_matricula, p_disciplina);
 
    COMMIT;
END $$

-- =====================================
-- T09 - CONSULTA ACADÊMICA (BOLETIM COMPLETO)
-- =====================================

DROP PROCEDURE IF EXISTS sp_T09_boletim_aluno $$

CREATE PROCEDURE sp_T09_boletim_aluno(
    IN p_cpf CHAR(11)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao consultar boletim';
    END;
 
    START TRANSACTION;
 
    SELECT COUNT(*) INTO v_existe FROM tb_pessoas WHERE pk_cpf = p_cpf;
 
    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não encontrada';
    END IF;
 
     SELECT
        p.pk_cpf,
        p.primeiro_nome,
        p.sobrenome,
        c.nome AS curso,
        d.nome AS disciplina,
        n.nota,
        f.quantidade_faltas
    FROM tb_pessoas p
    JOIN tb_matriculas m
        ON m.fk_cpf = p.pk_cpf
    JOIN tb_cursos c
        ON c.pk_codigo_curso = m.fk_codigo_curso
    LEFT JOIN tb_matricula_disciplinas md
        ON md.fk_matricula = m.pk_codigo_matricula
    LEFT JOIN tb_disciplinas d
        ON d.pk_codigo_disciplina = md.fk_disciplina
    LEFT JOIN tb_notas n
        ON n.fk_matricula  = m.pk_codigo_matricula
       AND n.fk_disciplina = d.pk_codigo_disciplina
    LEFT JOIN tb_faltas f
        ON f.fk_matricula  = m.pk_codigo_matricula
       AND f.fk_disciplina = d.pk_codigo_disciplina
    WHERE p.pk_cpf = p_cpf;
 
    COMMIT;
END $$

-- =====================================
-- T10 - ADMISSÃO DE FUNCIONÁRIO
-- =====================================

DROP PROCEDURE IF EXISTS sp_T10_admitir_funcionario $$
 
CREATE PROCEDURE sp_T10_admitir_funcionario(
    IN p_cpf CHAR(11),
    IN p_cargo INT,
    IN p_beneficio INT,
    OUT p_funcionario INT
)
BEGIN
    DECLARE v_pessoa          INT DEFAULT 0;
    DECLARE v_cargo_existe    INT DEFAULT 0;    
    DECLARE v_beneficio_existe INT DEFAULT 0; 
 
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro na admissão do funcionário';
    END;
 
    START TRANSACTION;
 
    SELECT COUNT(*) INTO v_pessoa FROM tb_pessoas WHERE pk_cpf = p_cpf;
 
    IF v_pessoa = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não encontrada';
    END IF;
 
    SELECT COUNT(*) INTO v_cargo_existe
    FROM tb_cargos
    WHERE pk_cargo = p_cargo;
 
    IF v_cargo_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cargo não encontrado';
    END IF;
 
    SELECT COUNT(*) INTO v_beneficio_existe
    FROM tb_beneficios
    WHERE pk_beneficio = p_beneficio;
 
    IF v_beneficio_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Benefício não encontrado';
    END IF;
 
    INSERT INTO tb_funcionarios(fk_cpf, fk_cargo)
    VALUES(p_cpf, p_cargo);
 
    SET p_funcionario = LAST_INSERT_ID();  
 
    INSERT INTO tb_funcionario_beneficios(fk_cpf, fk_beneficio)
    VALUES(p_cpf, p_beneficio);
 
    COMMIT;
END $$

-- =====================================
-- T11 - GERAÇÃO DE FOLHA DE PAGAMENTO MENSAL
-- =====================================

DROP PROCEDURE IF EXISTS sp_T11_gerar_folha_pagamento $$

CREATE PROCEDURE sp_T11_gerar_folha_pagamento(
    IN p_mes INT,
    IN p_ano INT
)
BEGIN
    DECLARE v_ja_gerada INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao gerar folha de pagamento';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_ja_gerada
    FROM tb_folha_pagamento
    WHERE mes_referencia = p_mes
      AND ano_referencia = p_ano;
 
    IF v_ja_gerada > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Folha de pagamento já gerada para este mês/ano';
    END IF;
 
    INSERT INTO tb_folha_pagamento(
        fk_funcionario,
        mes_referencia,
        ano_referencia,
        salario_base,
        data_geracao
    )
    SELECT
        f.pk_funcionario,
        p_mes,
        p_ano,
        c.salario,
        NOW()
    FROM tb_funcionarios f
    JOIN tb_cargos c ON c.pk_cargo = f.fk_cargo;
 
    COMMIT;
END $$

-- =====================================
-- T12 - AGENDAMENTO DE FÉRIAS
-- =====================================

DROP PROCEDURE IF EXISTS sp_T12_agendar_ferias $$

CREATE PROCEDURE sp_T12_agendar_ferias(
    IN p_funcionario INT,
    IN p_data_inicio DATE,
    IN p_data_fim DATE
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao agendar férias';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_existe
    FROM tb_funcionarios
    WHERE pk_funcionario = p_funcionario;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado';
    END IF;

    IF p_data_fim <= p_data_inicio THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Data de fim deve ser posterior à data de início';
    END IF;
 
    INSERT INTO tb_ferias(fk_funcionario, data_inicio, data_fim)
    VALUES(p_funcionario, p_data_inicio, p_data_fim);
 
    COMMIT;
END $$

-- =====================================
-- T13 - GERAÇÃO DE MENSALIDADES DO CONTRATO
-- =====================================

DROP PROCEDURE IF EXISTS sp_T13_gerar_mensalidades $$

CREATE PROCEDURE sp_T13_gerar_mensalidades(
    IN p_contrato INT,
    IN p_valor DECIMAL(10,2),
    IN p_vencimento DATE,
    OUT p_mensalidade INT
)
BEGIN
    DECLARE v_contrato_existe INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao gerar mensalidade';
    END;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_contrato_existe
    FROM tb_contratos
    WHERE pk_contrato = p_contrato;
 
    IF v_contrato_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contrato não encontrado';
    END IF;
 
    INSERT INTO tb_mensalidades(fk_contrato, valor, data_vencimento, status_pagamento)
    VALUES(p_contrato, p_valor, p_vencimento, 'PENDENTE');
 
    SET p_mensalidade = LAST_INSERT_ID(); 
 
    COMMIT;
END $$

-- =====================================
-- T14 - REGISTRO DE PAGAMENTO DE MENSALIDADE
-- =====================================

DROP PROCEDURE IF EXISTS sp_T14_registrar_pagamento $$

CREATE PROCEDURE sp_T14_registrar_pagamento(
    IN p_mensalidade INT,
    IN p_data_pagamento DATE
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao registrar pagamento';
    END;

    START TRANSACTION;

    SELECT COUNT(*), status_pagamento
    INTO v_existe, v_status
    FROM tb_mensalidades
    WHERE pk_mensalidade = p_mensalidade;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mensalidade não encontrada';
    END IF;

    IF v_status = 'PAGO' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Mensalidade já foi paga anteriormente';
    END IF;
 
    UPDATE tb_mensalidades
    SET status_pagamento = 'PAGO',
        data_pagamento   = p_data_pagamento
    WHERE pk_mensalidade = p_mensalidade;
 
    COMMIT;
END $$

-- =====================================
-- T15 - ATUALIZAÇÃO DE INADIMPLÊNCIA (BATCH)
-- =====================================

DROP PROCEDURE IF EXISTS sp_T15_atualizar_inadimplencia $$

CREATE PROCEDURE sp_T15_atualizar_inadimplencia()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao atualizar inadimplência';
    END;

    START TRANSACTION;

    UPDATE tb_mensalidades
    SET status_pagamento = 'INADIMPLENTE'
    WHERE data_vencimento < CURDATE()
      AND status_pagamento = 'PENDENTE';
 
    COMMIT;
END $$

-- =====================================
-- T16 - RELATÓRIO FINANCEIRO CONSOLIDADO
-- =====================================

DROP PROCEDURE IF EXISTS sp_T16_relatorio_financeiro $$
 
CREATE PROCEDURE sp_T16_relatorio_financeiro()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao gerar relatório financeiro';
    END;
 
    SELECT status_pagamento,
    COUNT(*) AS total_mensalidades,
    SUM(valor) AS valor_total
    FROM tb_mensalidades
    GROUP BY status_pagamento;
END $$
 
DELIMITER ;

-- ========================================================================
-- SEÇÃO COMPLEMENTAR — VALIDAÇÃO DE PERFORMANCE E EXPLAIN
-- ========================================================================
-- Critério rubrica: EXPLAIN obrigatório com comparação antes/depois de índice
-- e SELECTs standalone com subselect correlacionado.
-- ========================================================================
 
-- ───────────────────────────────────────────────────────────────
-- A) SELECTS STANDALONE COM SUBSELECT CORRELACIONADO
-- ───────────────────────────────────────────────────────────────
 
-- A1) Alunos que possuem NOTA em TODAS as disciplinas matriculadas
--     (subselect correlacionado com NOT EXISTS)
SELECT
    p.pk_cpf,
    p.primeiro_nome,
    p.sobrenome,
    m.pk_codigo_matricula
FROM tb_pessoas p
JOIN tb_matriculas m ON m.fk_cpf = p.pk_cpf
WHERE NOT EXISTS (
    SELECT 1
    FROM tb_matricula_disciplinas md
    LEFT JOIN tb_notas n
        ON n.fk_matricula  = md.fk_matricula
       AND n.fk_disciplina = md.fk_disciplina
    WHERE md.fk_matricula = m.pk_codigo_matricula
      AND n.nota IS NULL
);
 
-- A2) Funcionários cujo salário está acima da média do seu próprio cargo
--     (subselect correlacionado referenciando a tabela externa)
SELECT
    f.pk_funcionario,
    p.primeiro_nome,
    p.sobrenome,
    c.nome_cargo,
    c.salario
FROM tb_funcionarios f
JOIN tb_pessoas  p ON p.pk_cpf   = f.fk_cpf
JOIN tb_cargos   c ON c.pk_cargo = f.fk_cargo
WHERE c.salario > (
    SELECT AVG(c2.salario)
    FROM tb_funcionarios f2
    JOIN tb_cargos c2 ON c2.pk_cargo = f2.fk_cargo
    WHERE c2.pk_cargo = c.pk_cargo   -- correlação com a linha externa
);
 
-- A3) Mensalidades pendentes de alunos que já possuem ao menos um pagamento PAGO
--     (subselect correlacionado com EXISTS)
SELECT
    mn.pk_mensalidade,
    p.primeiro_nome,
    p.sobrenome,
    mn.valor,
    mn.data_vencimento
FROM tb_mensalidades mn
JOIN tb_contratos   ct ON ct.pk_contrato = mn.fk_contrato
JOIN tb_matriculas  m  ON m.pk_codigo_matricula = ct.fk_matricula
JOIN tb_pessoas     p  ON p.pk_cpf = m.fk_cpf
WHERE mn.status_pagamento = 'PENDENTE'
  AND EXISTS (
      SELECT 1
      FROM tb_mensalidades mn2
      WHERE mn2.fk_contrato      = mn.fk_contrato   -- correlação
        AND mn2.status_pagamento = 'PAGO'
  );
-- ───────────────────────────────────────────────────────────────
-- B) EXPLAIN — SEM ÍNDICE  (baseline)
-- ───────────────────────────────────────────────────────────────
-- Consulta: boletim completo de um aluno filtrando por CPF.
-- Sem índice em tb_matriculas.fk_cpf, o MySQL faz FULL TABLE SCAN.
 
EXPLAIN SELECT
    p.pk_cpf,
    p.primeiro_nome,
    p.sobrenome,
    c.nome          AS curso,
    d.nome          AS disciplina,
    n.nota,
    f.quantidade_faltas
FROM tb_pessoas p
JOIN tb_matriculas m
    ON m.fk_cpf = p.pk_cpf
JOIN tb_cursos c
    ON c.pk_codigo_curso = m.fk_codigo_curso
LEFT JOIN tb_matricula_disciplinas md
    ON md.fk_matricula = m.pk_codigo_matricula
LEFT JOIN tb_disciplinas d
    ON d.pk_codigo_disciplina = md.fk_disciplina
LEFT JOIN tb_notas n
    ON n.fk_matricula  = m.pk_codigo_matricula
   AND n.fk_disciplina = d.pk_codigo_disciplina
LEFT JOIN tb_faltas f
    ON f.fk_matricula  = m.pk_codigo_matricula
   AND f.fk_disciplina = d.pk_codigo_disciplina
WHERE p.pk_cpf = '12345678901';
-- RESULTADO ESPERADO SEM ÍNDICE:
-- tb_matriculas → type: ALL (full table scan), rows: ~N, Extra: Using where
-- tb_notas / tb_faltas → type: ALL (sem índice em fk_matricula)
 
-- ───────────────────────────────────────────────────────────────
-- C) CRIAÇÃO DOS ÍNDICES DE OTIMIZAÇÃO
-- ───────────────────────────────────────────────────────────────
 
-- Índice em tb_matriculas para buscas por CPF do aluno
CREATE INDEX IF NOT EXISTS idx_matriculas_fk_cpf
    ON tb_matriculas (fk_cpf);
 
-- Índice em tb_notas para joins por matrícula e disciplina
CREATE INDEX IF NOT EXISTS idx_notas_matricula_disciplina
    ON tb_notas (fk_matricula, fk_disciplina);
 
-- Índice em tb_faltas para joins por matrícula e disciplina
CREATE INDEX IF NOT EXISTS idx_faltas_matricula_disciplina
    ON tb_faltas (fk_matricula, fk_disciplina);
 
-- Índice em tb_matricula_disciplinas para joins
CREATE INDEX IF NOT EXISTS idx_mat_disc_matricula
    ON tb_matricula_disciplinas (fk_matricula);
 
-- Índice em tb_mensalidades para consultas de inadimplência (T15)
CREATE INDEX IF NOT EXISTS idx_mensalidades_status_vencimento
    ON tb_mensalidades (status_pagamento, data_vencimento);
 
-- ───────────────────────────────────────────────────────────────
-- D) EXPLAIN — COM ÍNDICE  (após otimização)
-- ---------------------------------------------------------------------------------------
-- Mesma consulta do boletim; agora os índices devem ser usados.
 
EXPLAIN SELECT
    p.pk_cpf,
    p.primeiro_nome,
    p.sobrenome,
    c.nome          AS curso,
    d.nome          AS disciplina,
    n.nota,
    f.quantidade_faltas
FROM tb_pessoas p
JOIN tb_matriculas m
    ON m.fk_cpf = p.pk_cpf
JOIN tb_cursos c
    ON c.pk_codigo_curso = m.fk_codigo_curso
LEFT JOIN tb_matricula_disciplinas md
    ON md.fk_matricula = m.pk_codigo_matricula
LEFT JOIN tb_disciplinas d
    ON d.pk_codigo_disciplina = md.fk_disciplina
LEFT JOIN tb_notas n
    ON n.fk_matricula  = m.pk_codigo_matricula
   AND n.fk_disciplina = d.pk_codigo_disciplina
LEFT JOIN tb_faltas f
    ON f.fk_matricula  = m.pk_codigo_matricula
   AND f.fk_disciplina = d.pk_codigo_disciplina
WHERE p.pk_cpf = '12345678901';
-- RESULTADO ESPERADO COM ÍNDICE:
-- tb_matriculas → type: ref, key: idx_matriculas_fk_cpf, rows: ~1-2
-- tb_notas      → type: ref, key: idx_notas_matricula_disciplina
-- tb_faltas     → type: ref, key: idx_faltas_matricula_disciplina
-- Ganho: eliminação do full table scan; custo cai de O(N) para O(log N)
 
-- ───────────────────────────────────────────────────────────────
-- E) EXPLAIN — consulta de inadimplência (sp_T15) sem vs. com índice
-- ───────────────────────────────────────────────────────────────
 
-- E1) Sem índice (antes da criação acima — apenas para documentação):
-- EXPLAIN UPDATE tb_mensalidades
--     SET status_pagamento = 'INADIMPLENTE'
--     WHERE data_vencimento < CURDATE()
--       AND status_pagamento = 'PENDENTE';
-- type: ALL, rows: ~N (full scan em toda a tabela)
 
-- E2) Com índice idx_mensalidades_status_vencimento:
EXPLAIN SELECT pk_mensalidade, fk_contrato, valor, data_vencimento
FROM tb_mensalidades
WHERE status_pagamento = 'PENDENTE'
  AND data_vencimento  < CURDATE();
-- RESULTADO ESPERADO COM ÍNDICE:
-- type: range, key: idx_mensalidades_status_vencimento
-- Apenas as linhas pendentes e vencidas são lidas — ganho expressivo
-- em bases com milhares de mensalidades.
