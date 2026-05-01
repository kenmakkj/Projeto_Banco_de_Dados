-- =============================================================================
--  SisGESC — Stored Procedures OLTP (MySQL)
--  Sistema de Gestão Escolar — Universidade Privada
-- =============================================================================
--
--  DESCRIÇÃO
--  ---------
--  15 stored procedures que cobrem os principais casos de uso do sistema:
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
--    Durabilidade — após COMMIT os dados persistem em disco

--  COMO EXECUTAR
--  -------------
--    CALL sp_T01_cadastrar_pessoa();
--    CALL sp_T02_matricula_inicial();
--    CALL sp_T03_trancamento_matricula();
--    CALL sp_T04_lancamento_nota();
--    CALL sp_T05_registrar_falta();
--    CALL sp_T06_fechar_periodo();
--    CALL sp_T07_matricula_disciplina();
--    CALL sp_T08_boletim_aluno();
--    CALL sp_T09_admissao_funcionario();
--    CALL sp_T10_gerar_folha_pagamento();
--    CALL sp_T11_agendar_ferias();
--    CALL sp_T12_gerar_mensalidades();
--    CALL sp_T13_registrar_pagamento();
--    CALL sp_T14_atualizar_inadimplencia();
--    CALL sp_T15_relatorio_financeiro();
-- =============================================================================

USE sisgesc;

DELIMITER $$

-- ─────────────────────────────────────────────────────────────────────────────
-- T01 — CADASTRO DE NOVA PESSOA + ENDEREÇO + CONTATOS
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : secretaria registra novo aluno no sistema.
--  Pré-condição: CPF não pode existir em tb_pessoas; CEP deve existir.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T01_cadastrar_pessoa()
BEGIN
    DECLARE v_cpf_existente INT DEFAULT 0;
    DECLARE v_cep_existente INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] CPF já cadastrado?
        SELECT COUNT(*) INTO v_cpf_existente
        FROM   tb_pessoas
        WHERE  pk_cpf = '98765432100';

        IF v_cpf_existente > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T01 ERRO: CPF já cadastrado em tb_pessoas.';
        END IF;

        -- [VALIDAÇÃO] CEP existe na base?
        SELECT COUNT(*) INTO v_cep_existente
        FROM   tb_cep
        WHERE  pk_cep = '01310100';

        IF v_cep_existente = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T01 ERRO: CEP não encontrado em tb_cep.';
        END IF;

        -- Insere pessoa
        INSERT INTO tb_pessoas (pk_cpf, primeiro_nome, sobrenome, data_nascimento, genero, nacionalidade)
        VALUES ('98765432100', 'Marina', 'Duarte', '2003-09-12', 'F', 'brasileira');

        -- Insere endereço (subselect garante existência do CEP)
        INSERT INTO tb_enderecos (fk_cpf, tipo_endereco, fk_cep, complemento, numero)
        SELECT '98765432100', 'Residencial', pk_cep, 'Apto 33', '980'
        FROM   tb_cep
        WHERE  pk_cep = '01310100';

        -- Insere telefone
        INSERT INTO tb_telefones (fk_cpf, ddd, numero, tipo)
        VALUES ('98765432100', '11', '994112233', 'Celular');

        -- Insere e-mail institucional
        INSERT INTO tb_emails (fk_cpf, email, tipo)
        VALUES ('98765432100', 'marina.duarte@aluno.sisgesc.edu.br', 'Institucional');

        -- [CONFIRMAÇÃO] Dados recém-inseridos
        SELECT p.pk_cpf,
               CONCAT(p.primeiro_nome, ' ', p.sobrenome)                       AS nome_completo,
               p.data_nascimento,
               e.tipo_endereco,
               CONCAT(c.logradouro, ', ', e.numero, ' - ', c.cidade, '/', c.estado) AS endereco_completo,
               t.ddd,
               t.numero  AS telefone,
               em.email
        FROM   tb_pessoas    p
        JOIN   tb_enderecos  e  ON e.fk_cpf  = p.pk_cpf
        JOIN   tb_cep        c  ON c.pk_cep  = e.fk_cep
        JOIN   tb_telefones  t  ON t.fk_cpf  = p.pk_cpf
        JOIN   tb_emails     em ON em.fk_cpf = p.pk_cpf
        WHERE  p.pk_cpf = '98765432100';

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T02 — MATRÍCULA INICIAL DE ALUNO EM CURSO
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : aluno aprovado no vestibular é vinculado a curso e turma.
--  Pré-condição: pessoa cadastrada, ainda não é aluno, curso ativo, turma com vagas.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T02_matricula_inicial()
BEGIN
    DECLARE v_pessoa_existe INT DEFAULT 0;
    DECLARE v_ja_e_aluno    INT DEFAULT 0;
    DECLARE v_curso_existe  INT DEFAULT 0;
    DECLARE v_turma_ativa   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Pessoa existe?
        SELECT COUNT(*) INTO v_pessoa_existe
        FROM   tb_pessoas
        WHERE  pk_cpf = '98765432100';

        IF v_pessoa_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T02 ERRO: Pessoa não encontrada em tb_pessoas.';
        END IF;

        -- [VALIDAÇÃO] Já é aluno?
        SELECT COUNT(*) INTO v_ja_e_aluno
        FROM   tb_alunos
        WHERE  pk_fk_cpf = '98765432100';

        IF v_ja_e_aluno > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T02 ERRO: CPF já possui registro como aluno.';
        END IF;

        -- [VALIDAÇÃO] Curso existe?
        SELECT COUNT(*) INTO v_curso_existe
        FROM   tb_cursos
        WHERE  pk_curso = 1;

        IF v_curso_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T02 ERRO: Curso não encontrado em tb_cursos.';
        END IF;

        -- [VALIDAÇÃO] Turma ativa para o curso?
        SELECT COUNT(*) INTO v_turma_ativa
        FROM   tb_turmas
        WHERE  fk_curso = 1
          AND  is_ativo = TRUE;

        IF v_turma_ativa = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T02 ERRO: Nenhuma turma ativa encontrada para o curso.';
        END IF;

        -- Cria registro de aluno (status 1 = ativo)
        INSERT INTO tb_alunos (pk_fk_cpf, rgm, data_matricula_inicial, fk_status)
        VALUES ('98765432100', 100009, CURDATE(), 1);

        -- Vincula ao curso
        INSERT INTO tb_aluno_curso (fk_cpf_aluno, fk_curso, data_inicio)
        VALUES ('98765432100', 1, CURDATE());

        -- Registra status inicial no histórico
        INSERT INTO tb_historico_status_aluno (fk_cpf_aluno, fk_status, data_inicio)
        VALUES ('98765432100', 1, CURDATE());

        -- Cria contrato educacional (subselect garante que aluno foi inserido)
        INSERT INTO tb_contratos_educacionais (fk_cpf_aluno, data_inicio, data_fim, valor_total_anual, is_ativo)
        SELECT '98765432100',
               CURDATE(),
               DATE_ADD(CURDATE(), INTERVAL 3 YEAR),
               14400.00,
               TRUE
        FROM   tb_alunos
        WHERE  pk_fk_cpf = '98765432100';

        -- [CONFIRMAÇÃO] Situação do novo aluno
        SELECT a.rgm,
               CONCAT(p.primeiro_nome, ' ', p.sobrenome) AS aluno,
               sa.descricao                               AS status,
               ac.data_inicio                             AS inicio_curso,
               cu.nome                                    AS curso,
               ce.valor_total_anual,
               ce.is_ativo                                AS contrato_ativo
        FROM   tb_alunos                  a
        JOIN   tb_pessoas                 p  ON p.pk_cpf            = a.pk_fk_cpf
        JOIN   tb_status_aluno            sa ON sa.pk_status_aluno  = a.fk_status
        JOIN   tb_aluno_curso             ac ON ac.fk_cpf_aluno     = a.pk_fk_cpf
        JOIN   tb_cursos                  cu ON cu.pk_curso         = ac.fk_curso
        JOIN   tb_contratos_educacionais  ce ON ce.fk_cpf_aluno     = a.pk_fk_cpf
        WHERE  a.pk_fk_cpf = '98765432100';

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T03 — TRANCAMENTO DE MATRÍCULA
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : aluno solicita trancamento do semestre corrente.
--  Pré-condição: aluno com status 1 (ativo); atualiza status e histórico.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T03_trancamento_matricula()
BEGIN
    DECLARE v_aluno_ativo  INT DEFAULT 0;
    DECLARE v_tem_cursando INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Aluno está ativo?
        SELECT COUNT(*) INTO v_aluno_ativo
        FROM   tb_alunos
        WHERE  pk_fk_cpf = '77788899900'
          AND  fk_status = 1;

        IF v_aluno_ativo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T03 ERRO: Aluno não encontrado ou não está ativo.';
        END IF;

        -- [VALIDAÇÃO] Possui matrícula em andamento?
        SELECT COUNT(*) INTO v_tem_cursando
        FROM   tb_resultado_matricula rm
        JOIN   tb_matriculas          m ON m.pk_matricula = rm.fk_matricula
        WHERE  m.fk_cpf_aluno = '77788899900'
          AND  rm.situacao    = 'cursando';

        IF v_tem_cursando = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T03 ERRO: Nenhuma disciplina em andamento para trancar.';
        END IF;

        -- Fecha período ativo no histórico
        UPDATE tb_historico_status_aluno
        SET    data_fim = CURDATE()
        WHERE  fk_cpf_aluno = '77788899900'
          AND  data_fim IS NULL;

        -- Insere novo status (2 = trancado)
        INSERT INTO tb_historico_status_aluno (fk_cpf_aluno, fk_status, data_inicio)
        VALUES ('77788899900', 2, CURDATE());

        -- Atualiza status na tabela principal (somente se ainda ativo)
        UPDATE tb_alunos
        SET    fk_status          = 2,
               ultima_atualizacao = NOW()
        WHERE  pk_fk_cpf = '77788899900'
          AND  fk_status  = 1;

        -- Tranca resultados em andamento
        UPDATE tb_resultado_matricula
        SET    situacao = 'trancado'
        WHERE  fk_matricula IN (
                   SELECT pk_matricula
                   FROM   tb_matriculas
                   WHERE  fk_cpf_aluno = '77788899900'
               )
          AND  situacao = 'cursando';

        -- [CONFIRMAÇÃO]
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome) AS aluno,
               sa.descricao                              AS novo_status,
               h.data_inicio                             AS data_trancamento,
               COUNT(rm.pk_resultado)                    AS disciplinas_trancadas
        FROM   tb_alunos                 a
        JOIN   tb_pessoas                p  ON p.pk_cpf           = a.pk_fk_cpf
        JOIN   tb_status_aluno           sa ON sa.pk_status_aluno = a.fk_status
        JOIN   tb_historico_status_aluno h  ON h.fk_cpf_aluno     = a.pk_fk_cpf
                                           AND h.data_fim IS NULL
        JOIN   tb_matriculas             m  ON m.fk_cpf_aluno     = a.pk_fk_cpf
        JOIN   tb_resultado_matricula    rm ON rm.fk_matricula     = m.pk_matricula
        WHERE  a.pk_fk_cpf = '77788899900'
          AND  rm.situacao = 'trancado'
        GROUP  BY a.pk_fk_cpf, sa.descricao, h.data_inicio;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T04 — LANÇAMENTO DE NOTA COM AUDITORIA
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : professor lança ou corrige nota de avaliação.
--  Pré-condição: matrícula existe, avaliação dentro do prazo.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T04_lancamento_nota()
BEGIN
    DECLARE v_dentro_prazo INT DEFAULT 0;
    DECLARE v_nota_existe  INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Avaliação dentro do prazo?
        SELECT COUNT(*) INTO v_dentro_prazo
        FROM   tb_avaliacoes
        WHERE  pk_avaliacao          = 1
          AND  data_limite_alteracao >= CURDATE();

        IF v_dentro_prazo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T04 ERRO: Avaliação fora do prazo de alteração.';
        END IF;

        -- [VALIDAÇÃO] Nota já existe para este par (matrícula × avaliação)?
        SELECT COUNT(*) INTO v_nota_existe
        FROM   tb_notas
        WHERE  fk_matricula = 1
          AND  fk_avaliacao = 1;

        IF v_nota_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T04 ERRO: Nota original não encontrada para auditoria.';
        END IF;

        -- Salva valor antigo no log antes de atualizar
        INSERT INTO tb_log_notas (fk_nota, valor_antigo, valor_novo, fk_cpf_professor, descricao)
        SELECT pk_nota,
               valor_nota,
               8.00,
               '99900011122',
               'Correção após revisão de prova - P1 Lógica de Programação'
        FROM   tb_notas
        WHERE  fk_matricula = 1
          AND  fk_avaliacao = 1;

        -- Atualiza nota (revalida prazo via subquery)
        UPDATE tb_notas
        SET    valor_nota        = 8.00,
               fk_cpf_professor = '99900011122',
               data_lancamento  = NOW()
        WHERE  fk_matricula = 1
          AND  fk_avaliacao  = 1
          AND  (
                   SELECT data_limite_alteracao
                   FROM   tb_avaliacoes
                   WHERE  pk_avaliacao = 1
               ) >= CURDATE();

        -- [CONFIRMAÇÃO]
        SELECT n.pk_nota,
               CONCAT(p.primeiro_nome, ' ', p.sobrenome) AS aluno,
               d.nome                                    AS disciplina,
               av.descricao                              AS avaliacao,
               n.valor_nota                              AS nota_atual,
               lg.valor_antigo,
               lg.valor_novo,
               lg.descricao                              AS motivo_alteracao,
               lg.data_alteracao
        FROM   tb_notas       n
        JOIN   tb_matriculas  m  ON m.pk_matricula = n.fk_matricula
        JOIN   tb_alunos      a  ON a.pk_fk_cpf    = m.fk_cpf_aluno
        JOIN   tb_pessoas     p  ON p.pk_cpf        = a.pk_fk_cpf
        JOIN   tb_disciplinas d  ON d.pk_disciplina = m.fk_disciplina
        JOIN   tb_avaliacoes  av ON av.pk_avaliacao = n.fk_avaliacao
        JOIN   tb_log_notas   lg ON lg.fk_nota      = n.pk_nota
        WHERE  n.fk_matricula = 1
          AND  n.fk_avaliacao = 1
        ORDER  BY lg.data_alteracao DESC;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T05 — REGISTRO DE FALTAS
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : professor registra frequência de uma aula.
--  Pré-condição: matrícula cursando, não duplicar data.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T05_registrar_falta()
BEGIN
    DECLARE v_matricula_ok    INT DEFAULT 0;
    DECLARE v_falta_duplicada INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Matrícula está em andamento?
        SELECT COUNT(*) INTO v_matricula_ok
        FROM   tb_matriculas          m
        JOIN   tb_resultado_matricula rm ON rm.fk_matricula = m.pk_matricula
        WHERE  m.pk_matricula = 1
          AND  rm.situacao    = 'cursando';

        IF v_matricula_ok = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T05 ERRO: Matrícula não encontrada ou não está em andamento.';
        END IF;

        -- [VALIDAÇÃO] Falta nessa data já registrada?
        SELECT COUNT(*) INTO v_falta_duplicada
        FROM   tb_faltas
        WHERE  fk_matricula = 1
          AND  data_falta   = '2025-04-02';

        IF v_falta_duplicada > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T05 ERRO: Falta para esta data já registrada.';
        END IF;

        -- Registra falta
        INSERT INTO tb_faltas (fk_matricula, data_falta, quantidade)
        VALUES (1, '2025-04-02', 1);

        -- Recalcula total de faltas
        -- NOTA: subquery usa alias para evitar erro MySQL de self-reference em UPDATE
        UPDATE tb_resultado_matricula
        SET    total_faltas = (
                   SELECT SUM(f.quantidade)
                   FROM   tb_faltas f
                   WHERE  f.fk_matricula = 1
               )
        WHERE  fk_matricula = 1;

        -- [CONFIRMAÇÃO]
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome)               AS aluno,
               d.nome                                                  AS disciplina,
               d.carga_horaria,
               rm.total_faltas,
               ROUND((rm.total_faltas * 100.0) / d.carga_horaria, 2)  AS pct_faltas,
               CASE
                   WHEN (rm.total_faltas * 100.0 / d.carga_horaria) > 25
                   THEN 'REPROVADO POR FALTA'
                   ELSE 'Frequência regular'
               END AS situacao_frequencia
        FROM   tb_resultado_matricula rm
        JOIN   tb_matriculas          m  ON m.pk_matricula  = rm.fk_matricula
        JOIN   tb_alunos              a  ON a.pk_fk_cpf     = m.fk_cpf_aluno
        JOIN   tb_pessoas             p  ON p.pk_cpf         = a.pk_fk_cpf
        JOIN   tb_disciplinas         d  ON d.pk_disciplina  = m.fk_disciplina
        WHERE  rm.fk_matricula = 1;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T06 — FECHAMENTO DE PERÍODO (APROVAÇÃO / REPROVAÇÃO)
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : coordenação encerra semestre e consolida resultados.
--  Pré-condição: período encerrado, todas as notas lançadas.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T06_fechar_periodo()
BEGIN
    DECLARE v_periodo_existe INT DEFAULT 0;
    DECLARE v_matr_cursando  INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Período existe?
        SELECT COUNT(*) INTO v_periodo_existe
        FROM   tb_periodos
        WHERE  pk_periodo = 3;

        IF v_periodo_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T06 ERRO: Período não encontrado.';
        END IF;

        -- [VALIDAÇÃO] Existem matrículas cursando no período?
        SELECT COUNT(*) INTO v_matr_cursando
        FROM   tb_matriculas          m
        JOIN   tb_resultado_matricula rm ON rm.fk_matricula = m.pk_matricula
        WHERE  m.fk_periodo = 3
          AND  rm.situacao  = 'cursando';

        IF v_matr_cursando = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T06 ERRO: Nenhuma matrícula em andamento para fechar no período 3.';
        END IF;

        -- Calcula média final e define situação
        -- NOTA: subqueries correlacionadas em UPDATE referenciam rm via alias externo
        UPDATE tb_resultado_matricula rm
        JOIN   tb_matriculas  mi ON mi.pk_matricula  = rm.fk_matricula
        JOIN   tb_disciplinas di ON di.pk_disciplina = mi.fk_disciplina
        SET    rm.media_final = (
                   SELECT ROUND(SUM(n.valor_nota * av.peso), 2)
                   FROM   tb_notas      n
                   JOIN   tb_avaliacoes av ON av.pk_avaliacao = n.fk_avaliacao
                   WHERE  n.fk_matricula = rm.fk_matricula
               ),
               rm.situacao = (
                   CASE
                       WHEN rm.total_faltas > (di.carga_horaria * 0.25)
                       THEN 'reprovado'
                       WHEN (
                               SELECT ROUND(SUM(n2.valor_nota * av2.peso), 2)
                               FROM   tb_notas      n2
                               JOIN   tb_avaliacoes av2 ON av2.pk_avaliacao = n2.fk_avaliacao
                               WHERE  n2.fk_matricula = rm.fk_matricula
                            ) < 5.00
                       THEN 'reprovado'
                       ELSE 'aprovado'
                   END
               ),
               rm.data_fechamento = CURDATE()
        WHERE  mi.fk_periodo = 3
          AND  rm.situacao   = 'cursando';

        -- [CONFIRMAÇÃO]
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome) AS aluno,
               d.nome                                    AS disciplina,
               rm.media_final,
               rm.total_faltas,
               rm.situacao,
               rm.data_fechamento
        FROM   tb_resultado_matricula rm
        JOIN   tb_matriculas          m  ON m.pk_matricula  = rm.fk_matricula
        JOIN   tb_alunos              a  ON a.pk_fk_cpf     = m.fk_cpf_aluno
        JOIN   tb_pessoas             p  ON p.pk_cpf         = a.pk_fk_cpf
        JOIN   tb_disciplinas         d  ON d.pk_disciplina  = m.fk_disciplina
        WHERE  m.fk_periodo = 3
        ORDER  BY aluno, disciplina;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T07 — MATRÍCULA EM DISCIPLINAS DO SEMESTRE
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : aluno ativo se matricula em disciplinas do período 5.
--  Pré-condição: aluno ativo, pré-requisitos cumpridos, sem duplicidade.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T07_matricula_disciplina()
BEGIN
    DECLARE v_aluno_ativo    INT DEFAULT 0;
    DECLARE v_prereq_ok      INT DEFAULT 0;
    DECLARE v_ja_matriculado INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Aluno está ativo?
        SELECT COUNT(*) INTO v_aluno_ativo
        FROM   tb_alunos       a
        JOIN   tb_status_aluno sa ON sa.pk_status_aluno = a.fk_status
        WHERE  a.pk_fk_cpf  = '98765432100'
          AND  sa.descricao  = 'ativo';

        IF v_aluno_ativo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T07 ERRO: Aluno não encontrado ou não está ativo.';
        END IF;

        -- [VALIDAÇÃO] Pré-requisito já aprovado?
        SELECT COUNT(*) INTO v_prereq_ok
        FROM   tb_resultado_matricula rm
        JOIN   tb_matriculas          m  ON m.pk_matricula = rm.fk_matricula
        WHERE  m.fk_cpf_aluno  = '98765432100'
          AND  m.fk_disciplina = (
                   SELECT fk_requisito
                   FROM   tb_pre_requisitos
                   WHERE  fk_disciplina = 3
               )
          AND  rm.situacao = 'aprovado';

        IF v_prereq_ok = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T07 ERRO: Pré-requisito não cumprido para a disciplina.';
        END IF;

        -- [VALIDAÇÃO] Disciplina já matriculada no período?
        SELECT COUNT(*) INTO v_ja_matriculado
        FROM   tb_matriculas
        WHERE  fk_cpf_aluno  = '98765432100'
          AND  fk_disciplina = 1
          AND  fk_periodo    = 5;

        IF v_ja_matriculado > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T07 ERRO: Aluno já matriculado nesta disciplina no período.';
        END IF;

        -- Insere matrícula
        INSERT INTO tb_matriculas (fk_cpf_aluno, fk_disciplina, fk_periodo, fk_turma)
        VALUES ('98765432100', 1, 5, 4);

        -- Cria resultado inicial como "cursando"
        INSERT INTO tb_resultado_matricula (fk_matricula, situacao)
        SELECT pk_matricula, 'cursando'
        FROM   tb_matriculas
        WHERE  fk_cpf_aluno  = '98765432100'
          AND  fk_disciplina = 1
          AND  fk_periodo    = 5;

        -- [CONFIRMAÇÃO] Grade horária do aluno no período 5
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome)   AS aluno,
               d.nome                                       AS disciplina,
               d.carga_horaria,
               t.nome_turma,
               au.dia_semana,
               au.horario_inicio,
               au.horario_fim,
               s.nome                                       AS sala,
               CONCAT(pp.primeiro_nome, ' ', pp.sobrenome) AS professor,
               rm.situacao
        FROM   tb_matriculas          m
        JOIN   tb_alunos              a    ON a.pk_fk_cpf       = m.fk_cpf_aluno
        JOIN   tb_pessoas             p    ON p.pk_cpf           = a.pk_fk_cpf
        JOIN   tb_disciplinas         d    ON d.pk_disciplina    = m.fk_disciplina
        JOIN   tb_resultado_matricula rm   ON rm.fk_matricula    = m.pk_matricula
        JOIN   tb_turmas              t    ON t.pk_turma         = m.fk_turma
        JOIN   tb_aulas               au   ON au.fk_turma        = m.fk_turma
                                          AND au.fk_disciplina   = m.fk_disciplina
                                          AND au.fk_periodo      = m.fk_periodo
        JOIN   tb_salas               s    ON s.pk_sala          = au.fk_sala
        JOIN   tb_professores         prof ON prof.pk_fk_cpf     = au.fk_cpf_professor
        JOIN   tb_pessoas             pp   ON pp.pk_cpf          = prof.pk_fk_cpf
        WHERE  m.fk_cpf_aluno = '98765432100'
          AND  m.fk_periodo   = 5
        ORDER  BY au.dia_semana, au.horario_inicio;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T08 — CONSULTA ACADÊMICA: BOLETIM COMPLETO DO ALUNO  (somente leitura)
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : aluno consulta histórico de desempenho por período.
--  Sem DML — READ ONLY garante snapshot consistente durante todos os SELECTs.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T08_boletim_aluno()
BEGIN
    START TRANSACTION READ ONLY;

        -- Histórico de notas consolidado
        SELECT per.ano,
               per.semestre,
               d.nome                                                              AS disciplina,
               d.carga_horaria,
               av.descricao                                                        AS avaliacao,
               av.peso,
               n.valor_nota,
               ROUND(n.valor_nota * av.peso, 2)                                   AS contribuicao,
               rm.media_final,
               rm.total_faltas,
               ROUND((COALESCE(rm.total_faltas, 0) * 100.0) / d.carga_horaria, 1) AS pct_faltas,
               rm.situacao
        FROM   tb_matriculas          m
        JOIN   tb_periodos            per ON per.pk_periodo  = m.fk_periodo
        JOIN   tb_disciplinas         d   ON d.pk_disciplina = m.fk_disciplina
        JOIN   tb_resultado_matricula rm  ON rm.fk_matricula = m.pk_matricula
        LEFT  JOIN tb_notas           n   ON n.fk_matricula  = m.pk_matricula
        LEFT  JOIN tb_avaliacoes      av  ON av.pk_avaliacao = n.fk_avaliacao
        WHERE  m.fk_cpf_aluno = '33344455566'
        ORDER  BY per.ano, per.semestre, d.nome, av.descricao;

        -- Resumo por período
        SELECT per.ano,
               per.semestre,
               COUNT(DISTINCT m.pk_matricula)                               AS disciplinas_cursadas,
               SUM(CASE WHEN rm.situacao = 'aprovado'  THEN 1 ELSE 0 END) AS aprovacoes,
               SUM(CASE WHEN rm.situacao = 'reprovado' THEN 1 ELSE 0 END) AS reprovacoes,
               ROUND(AVG(rm.media_final), 2)                                AS media_geral_periodo
        FROM   tb_matriculas          m
        JOIN   tb_periodos            per ON per.pk_periodo  = m.fk_periodo
        JOIN   tb_resultado_matricula rm  ON rm.fk_matricula = m.pk_matricula
        WHERE  m.fk_cpf_aluno = '33344455566'
        GROUP  BY per.ano, per.semestre
        ORDER  BY per.ano, per.semestre;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T09 — ADMISSÃO DE FUNCIONÁRIO + CARGO + BENEFÍCIOS
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : RH registra novo professor contratado.
--  Pré-condição: pessoa cadastrada, departamento e titulação existem.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T09_admissao_funcionario()
BEGIN
    DECLARE v_pessoa_existe    INT DEFAULT 0;
    DECLARE v_ja_funcionario   INT DEFAULT 0;
    DECLARE v_depto_existe     INT DEFAULT 0;
    DECLARE v_titulacao_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Pessoa existe?
        SELECT COUNT(*) INTO v_pessoa_existe
        FROM   tb_pessoas
        WHERE  pk_cpf = '98765432100';

        IF v_pessoa_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T09 ERRO: Pessoa não encontrada em tb_pessoas.';
        END IF;

        -- [VALIDAÇÃO] Já é funcionário?
        SELECT COUNT(*) INTO v_ja_funcionario
        FROM   tb_funcionarios
        WHERE  pk_fk_cpf = '98765432100';

        IF v_ja_funcionario > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T09 ERRO: CPF já registrado como funcionário.';
        END IF;

        -- [VALIDAÇÃO] Departamento existe?
        SELECT COUNT(*) INTO v_depto_existe
        FROM   tb_departamentos
        WHERE  pk_departamento = 1;

        IF v_depto_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T09 ERRO: Departamento não encontrado.';
        END IF;

        -- [VALIDAÇÃO] Titulação existe?
        SELECT COUNT(*) INTO v_titulacao_existe
        FROM   tb_titulacoes
        WHERE  pk_titulacao = 2;

        IF v_titulacao_existe = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T09 ERRO: Titulação não encontrada.';
        END IF;

        -- Insere funcionário
        INSERT INTO tb_funcionarios (pk_fk_cpf, matricula_funcional, fk_departamento, data_admissao, salario_base)
        VALUES ('98765432100', 200008, 1, CURDATE(), 5200.00);

        -- Insere professor (especialização)
        INSERT INTO tb_professores (pk_fk_cpf, area_atuacao, fk_titulacao)
        VALUES ('98765432100', 'Sistemas de Informação', 2);

        -- Registra cargo inicial (1 = Professor)
        INSERT INTO tb_historico_cargos (fk_cpf_funcionario, fk_cargo, data_inicio)
        VALUES ('98765432100', 1, CURDATE());

        -- Vincula benefícios padrão
        INSERT INTO tb_funcionario_beneficio (fk_cpf_funcionario, fk_beneficio, data_inicio)
        SELECT '98765432100', pk_beneficio, CURDATE()
        FROM   tb_beneficios
        WHERE  nome IN ('Plano de Saúde', 'Vale Refeição');

        -- [CONFIRMAÇÃO]
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome)   AS professor,
               f.matricula_funcional,
               dep.nome                                    AS departamento,
               ca.nome                                     AS cargo_atual,
               t.nome                                      AS titulacao,
               pr.area_atuacao,
               f.salario_base,
               GROUP_CONCAT(b.nome ORDER BY b.nome)        AS beneficios
        FROM   tb_funcionarios          f
        JOIN   tb_pessoas               p   ON p.pk_cpf             = f.pk_fk_cpf
        JOIN   tb_departamentos         dep ON dep.pk_departamento   = f.fk_departamento
        JOIN   tb_professores           pr  ON pr.pk_fk_cpf         = f.pk_fk_cpf
        JOIN   tb_titulacoes            t   ON t.pk_titulacao        = pr.fk_titulacao
        JOIN   tb_historico_cargos      hc  ON hc.fk_cpf_funcionario = f.pk_fk_cpf
                                           AND hc.data_fim IS NULL
        JOIN   tb_cargos                ca  ON ca.pk_cargo           = hc.fk_cargo
        JOIN   tb_funcionario_beneficio fb  ON fb.fk_cpf_funcionario = f.pk_fk_cpf
        JOIN   tb_beneficios            b   ON b.pk_beneficio        = fb.fk_beneficio
        WHERE  f.pk_fk_cpf = '98765432100'
        GROUP  BY f.pk_fk_cpf, p.primeiro_nome, p.sobrenome, f.matricula_funcional,
                  dep.nome, ca.nome, t.nome, pr.area_atuacao, f.salario_base;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T10 — GERAÇÃO DE FOLHA DE PAGAMENTO MENSAL
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : RH processa folha de março/2025.
--  Pré-condição: não existir folha para o mesmo (cpf, mês, ano).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T10_gerar_folha_pagamento()
BEGIN
    DECLARE v_folha_existente INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Já existe folha gerada para março/2025?
        SELECT COUNT(*) INTO v_folha_existente
        FROM   tb_folha_pagamento
        WHERE  mes = 3
          AND  ano = 2025;

        IF v_folha_existente > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T10 ERRO: Folha de pagamento para março/2025 já foi gerada.';
        END IF;

        -- Insere folha apenas para funcionários sem registro no período
        INSERT INTO tb_folha_pagamento
               (fk_cpf_funcionario, mes, ano, salario_bruto,
                total_descontos, salario_liquido, data_pagamento, status)
        SELECT f.pk_fk_cpf,
               3,
               2025,
               f.salario_base                   AS salario_bruto,
               ROUND(f.salario_base * 0.15, 2)  AS total_descontos,
               ROUND(f.salario_base * 0.85, 2)  AS salario_liquido,
               '2025-03-05'                     AS data_pagamento,
               'pago'
        FROM   tb_funcionarios f
        WHERE  NOT EXISTS (
                   SELECT 1
                   FROM   tb_folha_pagamento fp2
                   WHERE  fp2.fk_cpf_funcionario = f.pk_fk_cpf
                     AND  fp2.mes = 3
                     AND  fp2.ano = 2025
               );

        -- Detalha verbas de salário base nas novas folhas
        -- NOTA: subquery para pk_verba extraída para evitar reescrita desnecessária
        INSERT INTO tb_folha_verbas (fk_folha, fk_verba, valor)
        SELECT fp.pk_folha,
               (SELECT pk_verba FROM tb_verbas WHERE nome = 'Salário Base' LIMIT 1),
               fp.salario_bruto
        FROM   tb_folha_pagamento fp
        WHERE  fp.mes = 3
          AND  fp.ano = 2025
          AND  NOT EXISTS (
                   SELECT 1
                   FROM   tb_folha_verbas fv
                   WHERE  fv.fk_folha = fp.pk_folha
                     AND  fv.fk_verba = (SELECT pk_verba FROM tb_verbas WHERE nome = 'Salário Base' LIMIT 1)
               );

        -- [CONFIRMAÇÃO] Resumo da folha do mês
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome) AS funcionario,
               dep.nome                                  AS departamento,
               fp.salario_bruto,
               fp.total_descontos,
               fp.salario_liquido,
               fp.data_pagamento,
               fp.status
        FROM   tb_folha_pagamento fp
        JOIN   tb_funcionarios    f   ON f.pk_fk_cpf        = fp.fk_cpf_funcionario
        JOIN   tb_pessoas         p   ON p.pk_cpf            = f.pk_fk_cpf
        JOIN   tb_departamentos   dep ON dep.pk_departamento = f.fk_departamento
        WHERE  fp.mes = 3
          AND  fp.ano = 2025
        ORDER  BY dep.nome, funcionario;

        -- Totais da folha
        SELECT SUM(salario_bruto)   AS total_bruto,
               SUM(total_descontos) AS total_descontos,
               SUM(salario_liquido) AS total_liquido,
               COUNT(*)             AS qtd_funcionarios
        FROM   tb_folha_pagamento
        WHERE  mes = 3
          AND  ano = 2025;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T11 — AGENDAMENTO DE FÉRIAS
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : RH registra período de férias de funcionário.
--  Pré-condição: funcionário ativo, sem férias sobrepostas.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T11_agendar_ferias()
BEGIN
    DECLARE v_func_ativo   INT DEFAULT 0;
    DECLARE v_sobreposicao INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Funcionário existe e está ativo?
        SELECT COUNT(*) INTO v_func_ativo
        FROM   tb_funcionarios f
        WHERE  f.pk_fk_cpf      = '10011122233'
          AND  f.data_demissao IS NULL;

        IF v_func_ativo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T11 ERRO: Funcionário não encontrado ou já foi demitido.';
        END IF;

        -- [VALIDAÇÃO] Período sobrepõe férias existentes?
        SELECT COUNT(*) INTO v_sobreposicao
        FROM   tb_ferias
        WHERE  fk_cpf_funcionario = '10011122233'
          AND  status IN ('agendada', 'em andamento')
          AND  data_inicio        <= '2025-07-26'
          AND  data_fim           >= '2025-07-07';

        IF v_sobreposicao > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T11 ERRO: Período de férias sobrepõe agendamento existente.';
        END IF;

        -- Insere férias
        INSERT INTO tb_ferias (fk_cpf_funcionario, data_inicio, data_fim, tipo, status)
        VALUES ('10011122233', '2025-07-07', '2025-07-26', 'integral', 'agendada');

        -- [CONFIRMAÇÃO]
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome)        AS funcionario,
               fe.data_inicio,
               fe.data_fim,
               DATEDIFF(fe.data_fim, fe.data_inicio) + 1        AS dias_ferias,
               fe.tipo,
               fe.status
        FROM   tb_ferias       fe
        JOIN   tb_funcionarios f  ON f.pk_fk_cpf = fe.fk_cpf_funcionario
        JOIN   tb_pessoas      p  ON p.pk_cpf     = f.pk_fk_cpf
        WHERE  fe.fk_cpf_funcionario = '10011122233'
        ORDER  BY fe.data_inicio DESC;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T12 — GERAÇÃO DE MENSALIDADES DO CONTRATO
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : financeiro gera as 12 parcelas do contrato ao matricular aluno.
--  Pré-condição: contrato ativo, mensalidades ainda não geradas.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T12_gerar_mensalidades()
BEGIN
    DECLARE v_contrato_ativo INT DEFAULT 0;
    DECLARE v_ja_geradas     INT DEFAULT 0;
    DECLARE v_pk_contrato    INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Contrato ativo existe?
        SELECT COUNT(*), COALESCE(MAX(pk_contrato), 0)
        INTO   v_contrato_ativo, v_pk_contrato
        FROM   tb_contratos_educacionais
        WHERE  fk_cpf_aluno = '98765432100'
          AND  is_ativo     = TRUE;

        IF v_contrato_ativo = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T12 ERRO: Contrato ativo não encontrado para o aluno.';
        END IF;

        -- [VALIDAÇÃO] Mensalidades já foram geradas?
        SELECT COUNT(*) INTO v_ja_geradas
        FROM   tb_mensalidades
        WHERE  fk_contrato = v_pk_contrato;

        IF v_ja_geradas > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T12 ERRO: Mensalidades já foram geradas para este contrato.';
        END IF;

        -- Gera 12 mensalidades aplicando desconto quando existir
        -- NOTA: sequência 0-11 via UNION (compatível MySQL sem CTE recursiva)
        INSERT INTO tb_mensalidades (fk_contrato, fk_status, data_vencimento, valor_liquido)
        SELECT ce.pk_contrato,
               1,
               DATE_ADD(ce.data_inicio, INTERVAL n.num MONTH),
               ROUND(
                   (ce.valor_total_anual / 12) *
                   (1 - COALESCE(db.percentual_desconto, 0) / 100) -
                   COALESCE(db.valor_fixo_desconto, 0),
                   2
               ) AS valor_liquido
        FROM   tb_contratos_educacionais ce
        LEFT  JOIN tb_descontos_bolsas   db ON db.fk_contrato = ce.pk_contrato
        JOIN  (
                  SELECT 0 AS num UNION ALL SELECT 1  UNION ALL SELECT 2  UNION ALL
                  SELECT 3        UNION ALL SELECT 4  UNION ALL SELECT 5  UNION ALL
                  SELECT 6        UNION ALL SELECT 7  UNION ALL SELECT 8  UNION ALL
                  SELECT 9        UNION ALL SELECT 10 UNION ALL SELECT 11
              ) n ON TRUE
        WHERE  ce.fk_cpf_aluno = '98765432100'
          AND  ce.is_ativo     = TRUE
          AND  NOT EXISTS (
                   SELECT 1
                   FROM   tb_mensalidades mens
                   WHERE  mens.fk_contrato = ce.pk_contrato
               );

        -- [CONFIRMAÇÃO]
        SELECT m.pk_mensalidade,
               m.data_vencimento,
               m.valor_liquido,
               sp.descricao AS status
        FROM   tb_mensalidades             m
        JOIN   tb_status_pagamento         sp ON sp.pk_status_pagamento = m.fk_status
        JOIN   tb_contratos_educacionais   ce ON ce.pk_contrato         = m.fk_contrato
        WHERE  ce.fk_cpf_aluno = '98765432100'
        ORDER  BY m.data_vencimento;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T13 — REGISTRO DE PAGAMENTO DE MENSALIDADE
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : financeiro registra pagamento recebido via Pix.
--  Pré-condição: mensalidade pendente ou atrasada; valor coerente.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T13_registrar_pagamento()
BEGIN
    DECLARE v_mensalidade_ok INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Mensalidade está pendente ou atrasada?
        SELECT COUNT(*) INTO v_mensalidade_ok
        FROM   tb_mensalidades     m
        JOIN   tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
        WHERE  m.pk_mensalidade = 7
          AND  sp.descricao IN ('Pendente', 'Atrasado');

        IF v_mensalidade_ok = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T13 ERRO: Mensalidade não encontrada, já paga ou status inválido.';
        END IF;

        -- Registra o pagamento
        INSERT INTO tb_pagamentos (fk_mensalidade, valor_pago, meio_pagamento)
        VALUES (7, 1177.00, 'Pix');

        -- Atualiza status para "Pago"
        -- NOTA: JOIN duplo em tb_status_pagamento com aliases distintos evita erro MySQL
        UPDATE tb_mensalidades      m
        JOIN   tb_status_pagamento  sp_pago  ON sp_pago.descricao             = 'Pago'
        JOIN   tb_status_pagamento  sp_atual ON sp_atual.pk_status_pagamento  = m.fk_status
        SET    m.fk_status = sp_pago.pk_status_pagamento
        WHERE  m.pk_mensalidade = 7
          AND  sp_atual.descricao IN ('Pendente', 'Atrasado');

        -- [CONFIRMAÇÃO]
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome) AS aluno,
               m.pk_mensalidade,
               m.data_vencimento,
               m.valor_liquido,
               m.valor_multa,
               m.valor_juros,
               pg.valor_pago,
               pg.meio_pagamento,
               pg.data_pagamento,
               sp.descricao                              AS status_mensalidade
        FROM   tb_pagamentos               pg
        JOIN   tb_mensalidades             m   ON m.pk_mensalidade       = pg.fk_mensalidade
        JOIN   tb_status_pagamento         sp  ON sp.pk_status_pagamento = m.fk_status
        JOIN   tb_contratos_educacionais   ce  ON ce.pk_contrato         = m.fk_contrato
        JOIN   tb_alunos                   a   ON a.pk_fk_cpf            = ce.fk_cpf_aluno
        JOIN   tb_pessoas                  p   ON p.pk_cpf               = a.pk_fk_cpf
        WHERE  pg.fk_mensalidade = 7
        ORDER  BY pg.data_pagamento DESC
        LIMIT  1;

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T14 — ATUALIZAÇÃO DE INADIMPLÊNCIA (BATCH)
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : job noturno marca mensalidades vencidas como "Atrasado"
--               e aplica multa de 2% + juros de 1% ao mês.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T14_atualizar_inadimplencia()
BEGIN
    DECLARE v_pendentes INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        -- [VALIDAÇÃO] Existe alguma mensalidade vencida pendente?
        SELECT COUNT(*) INTO v_pendentes
        FROM   tb_mensalidades m
        JOIN   tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
        WHERE  m.data_vencimento < CURDATE()
          AND  sp.descricao = 'Pendente';

        IF v_pendentes = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'T14 AVISO: Nenhuma mensalidade vencida pendente encontrada.';
        END IF;

        -- Aplica multa (2%) e juros proporcional (1% ao mês)
        -- NOTA: JOIN direto em tb_status_pagamento com dois aliases para evitar subselect em UPDATE
        UPDATE tb_mensalidades     m
        JOIN   tb_status_pagamento sp_pend   ON sp_pend.pk_status_pagamento = m.fk_status
                                           AND  sp_pend.descricao = 'Pendente'
        JOIN   tb_status_pagamento sp_atraso ON sp_atraso.descricao = 'Atrasado'
        SET    m.valor_multa = ROUND(m.valor_liquido * 0.02, 2),
               m.valor_juros = ROUND(
                                   m.valor_liquido * 0.01 *
                                   CEIL(DATEDIFF(CURDATE(), m.data_vencimento) / 30.0),
                                   2
                               ),
               m.fk_status   = sp_atraso.pk_status_pagamento
        WHERE  m.data_vencimento < CURDATE();

        -- [CONFIRMAÇÃO]
        SELECT COUNT(*)                                        AS qtd_em_atraso,
               SUM(valor_liquido)                             AS principal_total,
               SUM(valor_multa)                               AS multas_total,
               SUM(valor_juros)                               AS juros_total,
               SUM(valor_liquido + valor_multa + valor_juros) AS total_a_receber
        FROM   tb_mensalidades m
        JOIN   tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
        WHERE  sp.descricao = 'Atrasado';

    COMMIT;
END$$


-- ─────────────────────────────────────────────────────────────────────────────
-- T15 — RELATÓRIO FINANCEIRO CONSOLIDADO  (somente leitura)
-- ─────────────────────────────────────────────────────────────────────────────
--  Caso de uso : gestor consulta receita × inadimplência × bolsas do mês.
--  READ ONLY garante snapshot consistente durante todos os SELECTs.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_T15_relatorio_financeiro()
BEGIN
    START TRANSACTION READ ONLY;

        -- Receita esperada vs realizada por status
        SELECT sp.descricao                                            AS status,
               COUNT(m.pk_mensalidade)                                AS qtd_mensalidades,
               SUM(m.valor_liquido)                                   AS valor_principal,
               SUM(m.valor_multa + m.valor_juros)                     AS encargos,
               SUM(m.valor_liquido + m.valor_multa + m.valor_juros)   AS total
        FROM   tb_mensalidades     m
        JOIN   tb_status_pagamento sp ON sp.pk_status_pagamento = m.fk_status
        WHERE  YEAR(m.data_vencimento)  = 2025
          AND  MONTH(m.data_vencimento) = 3
        GROUP  BY sp.descricao
        ORDER  BY sp.descricao;

        -- Impacto das bolsas por tipo
        SELECT db.tipo_bolsa,
               COUNT(DISTINCT db.fk_contrato)                                     AS contratos_beneficiados,
               AVG(COALESCE(db.percentual_desconto, 0))                           AS pct_medio_desconto,
               SUM(
                   COALESCE(db.valor_fixo_desconto, 0) +
                   COALESCE((ce.valor_total_anual / 12) * db.percentual_desconto / 100, 0)
               )                                                                  AS impacto_mensal_estimado
        FROM   tb_descontos_bolsas       db
        JOIN   tb_contratos_educacionais ce ON ce.pk_contrato = db.fk_contrato
        WHERE  ce.is_ativo = TRUE
        GROUP  BY db.tipo_bolsa
        ORDER  BY impacto_mensal_estimado DESC;

        -- Alunos inadimplentes (3+ mensalidades atrasadas)
        SELECT CONCAT(p.primeiro_nome, ' ', p.sobrenome)               AS aluno,
               COUNT(m.pk_mensalidade)                                 AS mensalidades_atrasadas,
               SUM(m.valor_liquido + m.valor_multa + m.valor_juros)    AS total_em_aberto,
               MIN(m.data_vencimento)                                  AS vencimento_mais_antigo
        FROM   tb_mensalidades             m
        JOIN   tb_status_pagamento         sp  ON sp.pk_status_pagamento = m.fk_status
        JOIN   tb_contratos_educacionais   ce  ON ce.pk_contrato         = m.fk_contrato
        JOIN   tb_alunos                   a   ON a.pk_fk_cpf            = ce.fk_cpf_aluno
        JOIN   tb_pessoas                  p   ON p.pk_cpf               = a.pk_fk_cpf
        WHERE  sp.descricao = 'Atrasado'
        GROUP  BY a.pk_fk_cpf, p.primeiro_nome, p.sobrenome
        HAVING COUNT(m.pk_mensalidade) >= 3
        ORDER  BY total_em_aberto DESC;

    COMMIT;
END$$

DELIMITER ;

-- =============================================================================
-- FIM DO SCRIPT — SisGESC OLTP Stored Procedures
-- =============================================================================
