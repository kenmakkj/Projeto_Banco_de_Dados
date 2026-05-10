-- =============================================================================
-- SisGESC — Stored Procedures OLTP (MySQL 8+) — VERSÃO CORRIGIDA
-- Alinhado ao Dicionário de Dados (Dicionario_Sisgesc.pdf)
-- =============================================================================

USE sisgesc;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- T01 — Cadastro de pessoa (tb_pessoas)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T01_cadastrar_pessoa $$
CREATE PROCEDURE sp_T01_cadastrar_pessoa(
  IN p_cpf           CHAR(11),
  IN p_primeiro_nome VARCHAR(40),
  IN p_sobrenome     VARCHAR(50),
  IN p_data_nasc     DATE,
  IN p_genero        CHAR(1),
  IN p_nacionalidade VARCHAR(20)
)
BEGIN
  DECLARE v_existe INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  IF p_cpf IS NULL OR LENGTH(p_cpf) <> 11 OR p_cpf REGEXP '[^0-9]' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CPF inválido: deve conter exatamente 11 dígitos numéricos';
  END IF;

  IF p_genero NOT IN ('M','F','O') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gênero inválido: deve ser M, F ou O';
  END IF;

  SELECT COUNT(*) INTO v_existe FROM tb_pessoas WHERE pk_cpf = p_cpf;
  IF v_existe > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa já cadastrada com este CPF';
  END IF;

  INSERT INTO tb_pessoas (pk_cpf, primeiro_nome, sobrenome, data_nascimento, genero, nacionalidade)
  VALUES (p_cpf, p_primeiro_nome, p_sobrenome, p_data_nasc, p_genero,
          COALESCE(p_nacionalidade, 'brasileira'));

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T02 — Telefone (ddd + número)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T02_cadastrar_telefone $$
CREATE PROCEDURE sp_T02_cadastrar_telefone(
  IN p_cpf    CHAR(11),
  IN p_ddd    CHAR(2),
  IN p_numero VARCHAR(9),
  IN p_tipo   VARCHAR(20)
)
BEGIN
  DECLARE v_existe INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_existe FROM tb_pessoas WHERE pk_cpf = p_cpf;
  IF v_existe = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não encontrada';
  END IF;

  IF p_ddd IS NULL OR LENGTH(p_ddd) <> 2 OR p_ddd REGEXP '[^0-9]' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DDD inválido: deve conter 2 dígitos numéricos';
  END IF;

  INSERT INTO tb_telefones (fk_cpf, ddd, numero, tipo)
  VALUES (p_cpf, p_ddd, p_numero, p_tipo);

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T03 — Vínculo aluno ↔ curso (tb_aluno_curso)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T03_vincular_aluno_curso $$
CREATE PROCEDURE sp_T03_vincular_aluno_curso(
  IN p_cpf_aluno  CHAR(11),
  IN p_fk_curso   INT,
  IN p_data_inicio DATE
)
BEGIN
  DECLARE v_aluno INT DEFAULT 0;
  DECLARE v_curso INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_aluno FROM tb_alunos    WHERE pk_fk_cpf = p_cpf_aluno;
  SELECT COUNT(*) INTO v_curso FROM tb_cursos    WHERE pk_curso  = p_fk_curso;

  IF v_aluno = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aluno não encontrado'; END IF;
  IF v_curso = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Curso não encontrado'; END IF;

  INSERT INTO tb_aluno_curso (fk_cpf_aluno, fk_curso, data_inicio, data_fim)
  VALUES (p_cpf_aluno, p_fk_curso, p_data_inicio, NULL);

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T04 — Matrícula em disciplina (tb_matriculas + tb_resultado_matricula)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T04_matricular_disciplina $$
CREATE PROCEDURE sp_T04_matricular_disciplina(
  IN  p_cpf_aluno    CHAR(11),
  IN  p_fk_disciplina INT,
  IN  p_fk_periodo   INT,
  IN  p_fk_turma     INT,
  OUT p_pk_matricula INT
)
BEGIN
  DECLARE v_dup INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_dup
  FROM tb_matriculas
  WHERE fk_cpf_aluno   = p_cpf_aluno
    AND fk_disciplina  = p_fk_disciplina
    AND fk_periodo     = p_fk_periodo;

  IF v_dup > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula já existente para este período';
  END IF;

  INSERT INTO tb_matriculas (fk_cpf_aluno, fk_disciplina, fk_periodo, fk_turma)
  VALUES (p_cpf_aluno, p_fk_disciplina, p_fk_periodo, p_fk_turma);

  SET p_pk_matricula = LAST_INSERT_ID();

  -- Cria snapshot de resultado para esta matrícula (situação inicial: cursando)
  INSERT INTO tb_resultado_matricula (fk_matricula, situacao, media_final, total_faltas, data_fechamento)
  VALUES (p_pk_matricula, 'cursando', NULL, NULL, NULL);

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T05 — Lançamento de nota (com ON DUPLICATE KEY UPDATE para reenvio)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T05_lancar_nota $$
CREATE PROCEDURE sp_T05_lancar_nota(
  IN p_fk_matricula    INT,
  IN p_fk_avaliacao    INT,
  IN p_fk_cpf_professor CHAR(11),
  IN p_valor           DECIMAL(4,2)
)
BEGIN
  DECLARE v_mat INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_mat FROM tb_matriculas WHERE pk_matricula = p_fk_matricula;
  IF v_mat = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Matrícula inválida';
  END IF;

  IF p_valor < 0 OR p_valor > 10 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor de nota inválido: deve ser entre 0.00 e 10.00';
  END IF;

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
  IN p_data_falta   DATE,
  IN p_quantidade   INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  IF p_quantidade < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantidade de faltas deve ser >= 1';
  END IF;

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
  IN p_media        DECIMAL(4,2),
  IN p_total_faltas INT,
  IN p_situacao     VARCHAR(20)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  IF p_situacao NOT IN ('aprovado','reprovado','trancado') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Situação inválida: aprovado | reprovado | trancado';
  END IF;

  UPDATE tb_resultado_matricula
  SET media_final     = p_media,
      total_faltas    = p_total_faltas,
      situacao        = p_situacao,
      data_fechamento = CURDATE()
  WHERE fk_matricula  = p_fk_matricula;

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
  IN p_valor_pago     DECIMAL(10,2),
  IN p_meio           VARCHAR(20)
)
BEGIN
  DECLARE v_m      INT DEFAULT 0;
  DECLARE v_status INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*), fk_status INTO v_m, v_status
  FROM tb_mensalidades WHERE pk_mensalidade = p_fk_mensalidade;

  IF v_m = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mensalidade não encontrada';
  END IF;

  -- fk_status = 2 corresponde a "Pago" em tb_status_pagamento
  IF v_status = 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mensalidade já paga anteriormente';
  END IF;

  INSERT INTO tb_pagamentos (fk_mensalidade, valor_pago, meio_pagamento)
  VALUES (p_fk_mensalidade, p_valor_pago, p_meio);

  UPDATE tb_mensalidades SET fk_status = 2 WHERE pk_mensalidade = p_fk_mensalidade;

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T09 — Marcar mensalidade como atrasada (batch/job noturno)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T09_marcar_mensalidade_atrasada $$
CREATE PROCEDURE sp_T09_marcar_mensalidade_atrasada(IN p_pk_mensalidade INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  -- fk_status = 3 corresponde a "Atrasado"; aplica só se ainda estiver Pendente (1)
  UPDATE tb_mensalidades
  SET fk_status = 3
  WHERE pk_mensalidade  = p_pk_mensalidade
    AND data_vencimento < CURDATE()
    AND fk_status       = 1;

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T10 — Admitir funcionário + cargo inicial (tb_funcionarios + tb_historico_cargos)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T10_admitir_funcionario $$
CREATE PROCEDURE sp_T10_admitir_funcionario(
  IN p_cpf            CHAR(11),
  IN p_matricula      INT,
  IN p_fk_departamento INT,
  IN p_data_admissao  DATE,
  IN p_salario        DECIMAL(10,2),
  IN p_fk_cargo       INT
)
BEGIN
  DECLARE v_p INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_p FROM tb_pessoas WHERE pk_cpf = p_cpf;
  IF v_p = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pessoa não cadastrada em tb_pessoas';
  END IF;

  INSERT INTO tb_funcionarios
    (pk_fk_cpf, matricula_funcional, fk_departamento, data_admissao, salario_base)
  VALUES (p_cpf, p_matricula, p_fk_departamento, p_data_admissao, p_salario);

  INSERT INTO tb_historico_cargos (fk_cpf_funcionario, fk_cargo, data_inicio, data_fim)
  VALUES (p_cpf, p_fk_cargo, p_data_admissao, NULL);

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T11 — Promover a professor
-- [FIX-02] Adicionado parâmetro p_area_atuacao (campo NOT NULL em tb_professores, Dict. p.11)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T11_promover_a_professor $$
CREATE PROCEDURE sp_T11_promover_a_professor(
  IN p_cpf          CHAR(11),
  IN p_fk_titulacao INT,
  IN p_area_atuacao VARCHAR(50)   -- CORRIGIDO: obrigatório pelo Dicionário (NOT NULL)
)
BEGIN
  DECLARE v_f  INT DEFAULT 0;
  DECLARE v_pr INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_f FROM tb_funcionarios WHERE pk_fk_cpf = p_cpf;
  IF v_f = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não encontrado em tb_funcionarios';
  END IF;

  -- Evita duplicidade na tabela de professores
  SELECT COUNT(*) INTO v_pr FROM tb_professores WHERE pk_fk_cpf = p_cpf;
  IF v_pr > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário já possui vínculo como professor';
  END IF;

  IF p_area_atuacao IS NULL OR p_area_atuacao = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Área de atuação é obrigatória';
  END IF;

  INSERT INTO tb_professores (pk_fk_cpf, fk_titulacao, area_atuacao)
  VALUES (p_cpf, p_fk_titulacao, p_area_atuacao);

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T12 — Agendar férias
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T12_agendar_ferias $$
CREATE PROCEDURE sp_T12_agendar_ferias(
  IN p_cpf    CHAR(11),
  IN p_inicio DATE,
  IN p_fim    DATE,
  IN p_tipo   VARCHAR(20)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  IF p_fim <= p_inicio THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Data de fim deve ser posterior à data de início';
  END IF;

  INSERT INTO tb_ferias (fk_cpf_funcionario, data_inicio, data_fim, data_retorno, tipo, status)
  VALUES (p_cpf, p_inicio, p_fim, NULL, p_tipo, 'agendada');

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T13 — Boletim do aluno (somente leitura)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T13_boletim_aluno $$
CREATE PROCEDURE sp_T13_boletim_aluno(IN p_cpf CHAR(11))
BEGIN
  SELECT
    m.pk_matricula,
    d.nome           AS disciplina,
    rm.situacao,
    rm.media_final,
    rm.total_faltas
  FROM tb_matriculas m
  JOIN tb_disciplinas         d  ON d.pk_disciplina = m.fk_disciplina
  LEFT JOIN tb_resultado_matricula rm ON rm.fk_matricula = m.pk_matricula
  WHERE m.fk_cpf_aluno = p_cpf;
END $$

-- -----------------------------------------------------------------------------
-- T14 — Resumo financeiro por status de mensalidade
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T14_resumo_mensalidades_por_status $$
CREATE PROCEDURE sp_T14_resumo_mensalidades_por_status()
BEGIN
  SELECT
    sp.descricao           AS status,
    COUNT(*)               AS qtd,
    SUM(m.valor_liquido)   AS soma_valor_liquido
  FROM tb_mensalidades m
  JOIN tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
  GROUP BY sp.descricao;
END $$

-- -----------------------------------------------------------------------------
-- T15 — Atualizar / inserir e-mail institucional (UPSERT)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T15_atualizar_email_institucional $$
CREATE PROCEDURE sp_T15_atualizar_email_institucional(
  IN p_cpf       CHAR(11),
  IN p_email_novo VARCHAR(70)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  UPDATE tb_emails
  SET email = p_email_novo
  WHERE fk_cpf = p_cpf
    AND tipo   = 'Institucional';

  IF ROW_COUNT() = 0 THEN
    INSERT INTO tb_emails (fk_cpf, email, tipo)
    VALUES (p_cpf, p_email_novo, 'Institucional');
  END IF;

  COMMIT;
END $$

-- -----------------------------------------------------------------------------
-- T16 — Atualizar área de atuação do professor
-- [FIX-03] tb_professor_area NÃO existe no Dicionário.
--          area_atuacao é campo VARCHAR(50) NOT NULL direto em tb_professores (Dict. p.11).
--          Procedure reescrita como UPDATE em tb_professores.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_T16_atualizar_area_professor $$
CREATE PROCEDURE sp_T16_atualizar_area_professor(
  IN p_cpf      CHAR(11),
  IN p_area     VARCHAR(50)
)
BEGIN
  DECLARE v_pr INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; RESIGNAL; END;

  START TRANSACTION;

  SELECT COUNT(*) INTO v_pr FROM tb_professores WHERE pk_fk_cpf = p_cpf;
  IF v_pr = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Professor não encontrado em tb_professores';
  END IF;

  IF p_area IS NULL OR p_area = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Área de atuação não pode ser vazia';
  END IF;

  UPDATE tb_professores
  SET area_atuacao = p_area
  WHERE pk_fk_cpf = p_cpf;

  COMMIT;
END $$

DELIMITER ;

-- =============================================================================
-- CONSULTAS COM SUBCONSULTAS — Fase 3
-- =============================================================================

-- S1 — Alunos com média final acima da média geral dos resultados fechados
SELECT DISTINCT
  a.pk_fk_cpf,
  p.primeiro_nome,
  p.sobrenome,
  rm.media_final
FROM tb_alunos a
JOIN tb_pessoas              p  ON p.pk_cpf      = a.pk_fk_cpf
JOIN tb_matriculas           m  ON m.fk_cpf_aluno = a.pk_fk_cpf
JOIN tb_resultado_matricula  rm ON rm.fk_matricula = m.pk_matricula
WHERE rm.media_final IS NOT NULL
  AND rm.media_final > (
      SELECT AVG(rm2.media_final)
      FROM tb_resultado_matricula rm2
      WHERE rm2.media_final IS NOT NULL
  );

-- S2 — Mensalidades em aberto de alunos que já possuem ao menos um pagamento realizado
SELECT
  m.pk_mensalidade,
  m.fk_contrato,
  m.valor_liquido,
  m.data_vencimento,
  sp.descricao AS status
FROM tb_mensalidades         m
JOIN tb_status_pagamento     sp ON sp.pk_status_pagamento = m.fk_status
JOIN tb_contratos_educacionais c ON c.pk_contrato         = m.fk_contrato
WHERE m.fk_status = 1   -- Pendente
  AND EXISTS (
      SELECT 1
      FROM tb_mensalidades m2
      WHERE m2.fk_contrato = m.fk_contrato
        AND m2.fk_status   = 2  -- Pago
  );

-- S3 — Funcionários com salário-base acima da média do mesmo departamento
SELECT
  f.pk_fk_cpf,
  p.primeiro_nome,
  d.nome       AS departamento,
  f.salario_base
FROM tb_funcionarios         f
JOIN tb_pessoas              p ON p.pk_cpf          = f.pk_fk_cpf
JOIN tb_departamentos        d ON d.pk_departamento  = f.fk_departamento
WHERE f.salario_base > (
    SELECT AVG(f2.salario_base)
    FROM tb_funcionarios f2
    WHERE f2.fk_departamento = f.fk_departamento
);
