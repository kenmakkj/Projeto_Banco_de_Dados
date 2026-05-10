<<<<<<< HEAD
-- =============================================================================
-- SisGESC — Stored Procedures OLTP (MySQL 8+)
-- Alinhado ao schema de SisGESC_Script_DDL_otimizado.sql / SisGESC_Script_DML.sql
-- =============================================================================
=======
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
>>>>>>> 24d4a75c507c4d78d906313fc99809df8bd6b6e8

USE sisgesc;

DELIMITER $$

<<<<<<< HEAD
-- -----------------------------------------------------------------------------
-- T01 — Cadastro de pessoa (tb_pessoas)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T01_cadastrar_pessoa $$
CREATE PROCEDURE sp_T01_cadastrar_pessoa(
  IN p_cpf CHAR(11),
  IN p_primeiro_nome VARCHAR(40),
  IN p_sobrenome VARCHAR(50),
  IN p_data_nascimento DATE,
  IN p_genero CHAR(1),
  IN p_nacionalidade VARCHAR(20)
)
BEGIN
  DECLARE v_existe INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  IF p_cpf IS NULL OR LENGTH(p_cpf) <> 11 OR p_cpf REGEXP '[^0-9]' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF inválido';
  END IF;
  SELECT COUNT(*) INTO v_existe FROM tb_pessoas WHERE pk_cpf = p_cpf;
  IF v_existe > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa já cadastrada';
  END IF;
  INSERT INTO tb_pessoas (pk_cpf, primeiro_nome, sobrenome, data_nascimento, genero, nacionalidade)
  VALUES (p_cpf, p_primeiro_nome, p_sobrenome, p_data_nascimento, p_genero, COALESCE(p_nacionalidade, 'brasileira'));
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T02 — Telefone (ddd + número)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T02_cadastrar_telefone $$
CREATE PROCEDURE sp_T02_cadastrar_telefone(
  IN p_cpf CHAR(11),
  IN p_ddd CHAR(2),
  IN p_numero VARCHAR(9),
  IN p_tipo VARCHAR(20)
)
BEGIN
  DECLARE v_existe INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_existe FROM tb_pessoas WHERE pk_cpf = p_cpf;
  IF v_existe = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não encontrada';
  END IF;
  INSERT INTO tb_telefones (fk_cpf, ddd, numero, tipo) VALUES (p_cpf, p_ddd, p_numero, p_tipo);
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T03 — Vínculo aluno ↔ curso (tb_aluno_curso)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T03_vincular_aluno_curso $$
CREATE PROCEDURE sp_T03_vincular_aluno_curso(
  IN p_cpf_aluno CHAR(11),
  IN p_fk_curso INT,
  IN p_data_inicio DATE
)
BEGIN
  DECLARE v_aluno INT DEFAULT 0;
  DECLARE v_curso INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_aluno FROM tb_alunos WHERE pk_fk_cpf = p_cpf_aluno;
  SELECT COUNT(*) INTO v_curso FROM tb_cursos WHERE pk_curso = p_fk_curso;
  IF v_aluno = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aluno não encontrado'; END IF;
  IF v_curso = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Curso não encontrado'; END IF;
  INSERT INTO tb_aluno_curso (fk_cpf_aluno, fk_curso, data_inicio, data_fim)
  VALUES (p_cpf_aluno, p_fk_curso, p_data_inicio, NULL);
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T04 — Matrícula em disciplina (tb_matriculas)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T04_matricular_disciplina $$
CREATE PROCEDURE sp_T04_matricular_disciplina(
  IN p_cpf_aluno CHAR(11),
  IN p_fk_disciplina INT,
  IN p_fk_periodo INT,
  IN p_fk_turma INT,
  OUT p_pk_matricula INT
)
BEGIN
  DECLARE v_dup INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_dup FROM tb_matriculas
  WHERE fk_cpf_aluno = p_cpf_aluno AND fk_disciplina = p_fk_disciplina AND fk_periodo = p_fk_periodo;
  IF v_dup > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula já existente para o período';
  END IF;
  INSERT INTO tb_matriculas (fk_cpf_aluno, fk_disciplina, fk_periodo, fk_turma)
  VALUES (p_cpf_aluno, p_fk_disciplina, p_fk_periodo, p_fk_turma);
  SET p_pk_matricula = LAST_INSERT_ID();
  INSERT INTO tb_resultado_matricula (fk_matricula, situacao, media_final, total_faltas, data_fechamento)
  VALUES (p_pk_matricula, 'cursando', NULL, NULL, NULL);
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T05 — Lançamento de nota
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T05_lancar_nota $$
CREATE PROCEDURE sp_T05_lancar_nota(
  IN p_fk_matricula INT,
  IN p_fk_avaliacao INT,
  IN p_fk_cpf_professor CHAR(11),
  IN p_valor DECIMAL(4,2)
)
BEGIN
  DECLARE v_mat INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_mat FROM tb_matriculas WHERE pk_matricula = p_fk_matricula;
  IF v_mat = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula inválida'; END IF;
  INSERT INTO tb_notas (fk_matricula, fk_avaliacao, fk_cpf_professor, valor_nota)
  VALUES (p_fk_matricula, p_fk_avaliacao, p_fk_cpf_professor, p_valor)
  ON DUPLICATE KEY UPDATE valor_nota = p_valor;
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T06 — Registrar falta
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T06_registrar_falta $$
CREATE PROCEDURE sp_T06_registrar_falta(
  IN p_fk_matricula INT,
  IN p_data_falta DATE,
  IN p_quantidade INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO tb_faltas (fk_matricula, data_falta, quantidade)
  VALUES (p_fk_matricula, p_data_falta, p_quantidade)
  ON DUPLICATE KEY UPDATE quantidade = p_quantidade;
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T07 — Fechar resultado da matrícula (média / situação)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T07_fechar_resultado_matricula $$
CREATE PROCEDURE sp_T07_fechar_resultado_matricula(
  IN p_fk_matricula INT,
  IN p_media DECIMAL(4,2),
  IN p_total_faltas INT,
  IN p_situacao VARCHAR(20)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  UPDATE tb_resultado_matricula
  SET media_final = p_media, total_faltas = p_total_faltas, situacao = p_situacao, data_fechamento = CURDATE()
  WHERE fk_matricula = p_fk_matricula;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resultado não encontrado para a matrícula';
  END IF;
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T08 — Registrar pagamento de mensalidade
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T08_registrar_pagamento $$
CREATE PROCEDURE sp_T08_registrar_pagamento(
  IN p_fk_mensalidade INT,
  IN p_valor_pago DECIMAL(10,2),
  IN p_meio VARCHAR(20)
)
BEGIN
  DECLARE v_m INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_m FROM tb_mensalidades WHERE pk_mensalidade = p_fk_mensalidade;
  IF v_m = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mensalidade inválida'; END IF;
  INSERT INTO tb_pagamentos (fk_mensalidade, valor_pago, meio_pagamento) VALUES (p_fk_mensalidade, p_valor_pago, p_meio);
  UPDATE tb_mensalidades SET fk_status = 2 WHERE pk_mensalidade = p_fk_mensalidade;
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T09 — Atualizar status de mensalidade atrasada (simples)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T09_marcar_mensalidade_atrasada $$
CREATE PROCEDURE sp_T09_marcar_mensalidade_atrasada(IN p_pk_mensalidade INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  UPDATE tb_mensalidades
  SET fk_status = 3
  WHERE pk_mensalidade = p_pk_mensalidade AND data_vencimento < CURDATE() AND fk_status = 1;
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T10 — Admitir funcionário + cargo inicial
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T10_admitir_funcionario $$
CREATE PROCEDURE sp_T10_admitir_funcionario(
  IN p_cpf CHAR(11),
  IN p_matricula INT,
  IN p_fk_departamento INT,
  IN p_data_admissao DATE,
  IN p_salario DECIMAL(10,2),
  IN p_fk_cargo INT
)
BEGIN
  DECLARE v_p INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_p FROM tb_pessoas WHERE pk_cpf = p_cpf;
  IF v_p = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não cadastrada'; END IF;
  INSERT INTO tb_funcionarios (pk_fk_cpf, matricula_funcional, fk_departamento, data_admissao, salario_base)
  VALUES (p_cpf, p_matricula, p_fk_departamento, p_data_admissao, p_salario);
  INSERT INTO tb_historico_cargos (fk_cpf_funcionario, fk_cargo, data_inicio, data_fim)
  VALUES (p_cpf, p_fk_cargo, p_data_admissao, NULL);
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T11 — Promover a professor (requer já ser funcionário)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T11_promover_a_professor $$
CREATE PROCEDURE sp_T11_promover_a_professor(IN p_cpf CHAR(11), IN p_fk_titulacao INT)
BEGIN
  DECLARE v_f INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_f FROM tb_funcionarios WHERE pk_fk_cpf = p_cpf;
  IF v_f = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado'; END IF;
  INSERT INTO tb_professores (pk_fk_cpf, fk_titulacao) VALUES (p_cpf, p_fk_titulacao);
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T12 — Agendar férias
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T12_agendar_ferias $$
CREATE PROCEDURE sp_T12_agendar_ferias(
  IN p_cpf CHAR(11),
  IN p_inicio DATE,
  IN p_fim DATE,
  IN p_tipo VARCHAR(20)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO tb_ferias (fk_cpf_funcionario, data_inicio, data_fim, data_retorno, tipo, status)
  VALUES (p_cpf, p_inicio, p_fim, NULL, p_tipo, 'agendada');
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T13 — Boletim (resultado em conjunto) — somente leitura
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T13_boletim_aluno $$
CREATE PROCEDURE sp_T13_boletim_aluno(IN p_cpf CHAR(11))
BEGIN
  SELECT m.pk_matricula, d.nome AS disciplina, rm.situacao, rm.media_final, rm.total_faltas
  FROM tb_matriculas m
  JOIN tb_disciplinas d ON d.pk_disciplina = m.fk_disciplina
  LEFT JOIN tb_resultado_matricula rm ON rm.fk_matricula = m.pk_matricula
  WHERE m.fk_cpf_aluno = p_cpf;
END $$

-- -----------------------------------------------------------------------------
-- T14 — Resumo financeiro por status de mensalidade
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T14_resumo_mensalidades_por_status $$
CREATE PROCEDURE sp_T14_resumo_mensalidades_por_status()
BEGIN
  SELECT sp.descricao AS status, COUNT(*) AS qtd, SUM(m.valor_liquido) AS soma_valor_liquido
  FROM tb_mensalidades m
  JOIN tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
  GROUP BY sp.descricao;
END $$

-- -----------------------------------------------------------------------------
-- T15 — Atualizar e-mail institucional
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T15_atualizar_email_institucional $$
CREATE PROCEDURE sp_T15_atualizar_email_institucional(
  IN p_cpf CHAR(11),
  IN p_email_novo VARCHAR(70)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  UPDATE tb_emails SET email = p_email_novo WHERE fk_cpf = p_cpf AND tipo = 'Institucional';
  IF ROW_COUNT() = 0 THEN
    INSERT INTO tb_emails (fk_cpf, email, tipo) VALUES (p_cpf, p_email_novo, 'Institucional');
  END IF;
  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T16 — Vincular professor a área de atuação
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T16_vincular_professor_area $$
CREATE PROCEDURE sp_T16_vincular_professor_area(IN p_cpf CHAR(11), IN p_fk_area INT)
BEGIN
  DECLARE v_pr INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT COUNT(*) INTO v_pr FROM tb_professores WHERE pk_fk_cpf = p_cpf;
  IF v_pr = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Professor não encontrado'; END IF;
  INSERT IGNORE INTO tb_professor_area (fk_cpf_professor, fk_area) VALUES (p_cpf, p_fk_area);
  COMMIT;
END $$

DELIMITER ;

-- =============================================================================
-- Fase 3 — Consultas com subconsultas (agregação / correlação)
-- =============================================================================

-- S1 — Alunos com média final acima da média geral dos resultados fechados (subselect agregado)
SELECT DISTINCT a.pk_fk_cpf,
                p.primeiro_nome,
                p.sobrenome,
                rm.media_final
FROM tb_alunos a
JOIN tb_pessoas p ON p.pk_cpf = a.pk_fk_cpf
JOIN tb_matriculas m ON m.fk_cpf_aluno = a.pk_fk_cpf
JOIN tb_resultado_matricula rm ON rm.fk_matricula = m.pk_matricula
WHERE rm.media_final IS NOT NULL
  AND rm.media_final > (
        SELECT AVG(rm2.media_final)
        FROM tb_resultado_matricula rm2
        WHERE rm2.media_final IS NOT NULL
      );

-- S2 — Mensalidades em aberto de alunos que já pagaram alguma mensalidade (EXISTS correlacionado)
SELECT m.pk_mensalidade,
       m.fk_contrato,
       m.valor_liquido,
       m.data_vencimento,
       sp.descricao AS status
FROM tb_mensalidades m
JOIN tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
JOIN tb_contratos_educacionais c ON c.pk_contrato = m.fk_contrato
WHERE m.fk_status = 1
  AND EXISTS (
    SELECT 1
    FROM tb_mensalidades m2
    WHERE m2.fk_contrato = m.fk_contrato
      AND m2.fk_status = 2
  );

-- S3 — Funcionários com salário-base acima da média do mesmo departamento (subselect correlacionado)
SELECT f.pk_fk_cpf,
       p.primeiro_nome,
       d.nome AS departamento,
       f.salario_base
FROM tb_funcionarios f
JOIN tb_pessoas p ON p.pk_cpf = f.pk_fk_cpf
JOIN tb_departamentos d ON d.pk_departamento = f.fk_departamento
WHERE f.salario_base > (
  SELECT AVG(f2.salario_base)
  FROM tb_funcionarios f2
  WHERE f2.fk_departamento = f.fk_departamento
);
=======
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
>>>>>>> 24d4a75c507c4d78d906313fc99809df8bd6b6e8
