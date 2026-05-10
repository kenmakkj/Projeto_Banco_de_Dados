-- =============================================================================
-- SisGESC — Script DDL (MySQL)
-- Sistema de Gestão Escolar — Universidade Privada
-- Modelagem relacional em 3FN (Terceira Forma Normal)
--
--
-- Módulos:
--   1. Base / Pessoas
--   2. Módulo Acadêmico
--   3. Módulo RH
--   4. Módulo Financeiro
-- =============================================================================

CREATE DATABASE IF NOT EXISTS sisgesc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sisgesc;

-- =============================================================================
-- BASE / PESSOAS
-- =============================================================================

CREATE TABLE IF NOT EXISTS tb_pessoas (
  pk_cpf             CHAR(11)     NOT NULL,
  primeiro_nome      VARCHAR(40)  NOT NULL,
  sobrenome          VARCHAR(50)  NOT NULL,
  data_nascimento    DATE         NOT NULL,
  genero             CHAR(1)      NOT NULL,
  nacionalidade      VARCHAR(20)  NOT NULL DEFAULT 'brasileira',
  data_criacao       TIMESTAMP    NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP    NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_pessoas PRIMARY KEY (pk_cpf),
  CONSTRAINT ck_genero  CHECK (genero IN ('M', 'F', 'O'))
);

CREATE TABLE IF NOT EXISTS tb_cep (
  pk_cep     CHAR(8)      NOT NULL,
  logradouro VARCHAR(100) NOT NULL,
  bairro     VARCHAR(50)  NOT NULL,
  cidade     VARCHAR(50)  NOT NULL,
  estado     CHAR(2)      NOT NULL,
  CONSTRAINT pk_cep PRIMARY KEY (pk_cep)
);

CREATE TABLE IF NOT EXISTS tb_enderecos (
  fk_cpf             CHAR(11)    NOT NULL,
  tipo_endereco      VARCHAR(20) NOT NULL COMMENT 'Residencial, Comercial',
  fk_cep             CHAR(8)     NOT NULL,
  complemento        VARCHAR(50) NULL     COMMENT 'Apto 42, Bloco B, Sala 301',
  numero             VARCHAR(10) NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_enderecos PRIMARY KEY (fk_cpf, tipo_endereco),
  CONSTRAINT fk_end_cpf   FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_end_cep   FOREIGN KEY (fk_cep) REFERENCES tb_cep(pk_cep)
);

CREATE TABLE IF NOT EXISTS tb_telefones (
  pk_telefone INT         NOT NULL AUTO_INCREMENT,
  fk_cpf      CHAR(11)    NOT NULL,
  ddd         CHAR(2)     NOT NULL,
  numero      VARCHAR(9)  NOT NULL,
  tipo        VARCHAR(20) NULL     COMMENT 'Residencial, Celular, Comercial',
  CONSTRAINT pk_telefones PRIMARY KEY (pk_telefone),
  CONSTRAINT fk_tel_cpf   FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf)
);

CREATE TABLE IF NOT EXISTS tb_emails (
  pk_email INT         NOT NULL AUTO_INCREMENT,
  fk_cpf   CHAR(11)    NOT NULL,
  email    VARCHAR(70) NOT NULL,
  tipo     VARCHAR(20) NULL     COMMENT 'Pessoal, Institucional',
  CONSTRAINT pk_emails    PRIMARY KEY (pk_email),
  CONSTRAINT uq_emails    UNIQUE      (email),
  CONSTRAINT fk_email_cpf FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf)
);

-- =============================================================================
-- MÓDULO ACADÊMICO
-- =============================================================================

CREATE TABLE IF NOT EXISTS tb_tipo_curso (
  pk_tipo_curso INT         NOT NULL AUTO_INCREMENT,
  descricao     VARCHAR(30) NOT NULL COMMENT 'Graduação, Pós, Extensão',
  CONSTRAINT pk_tipo_curso PRIMARY KEY (pk_tipo_curso),
  CONSTRAINT uq_tipo_curso UNIQUE      (descricao)
);

CREATE TABLE IF NOT EXISTS tb_cursos (
  pk_curso           INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(70) NOT NULL,
  fk_tipo_curso      INT         NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_cursos      PRIMARY KEY (pk_curso),
  CONSTRAINT uq_cursos_nome UNIQUE      (nome),
  CONSTRAINT fk_curso_tipo  FOREIGN KEY (fk_tipo_curso) REFERENCES tb_tipo_curso(pk_tipo_curso)
);

CREATE TABLE IF NOT EXISTS tb_status_aluno (
  pk_status_aluno INT         NOT NULL,
  descricao       VARCHAR(20) NOT NULL COMMENT 'ativo, trancado, desistente, formado',
  CONSTRAINT pk_status_aluno PRIMARY KEY (pk_status_aluno),
  CONSTRAINT uq_status_aluno UNIQUE      (descricao)
);

CREATE TABLE IF NOT EXISTS tb_alunos (
  pk_fk_cpf              CHAR(11)  NOT NULL,
  rgm                    INT       NOT NULL,
  data_matricula_inicial DATE      NOT NULL,
  fk_status              INT       NOT NULL,
  data_criacao           TIMESTAMP NOT NULL DEFAULT NOW(),
  ultima_atualizacao     TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_alunos       PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT uq_alunos_rgm   UNIQUE      (rgm),
  CONSTRAINT fk_aluno_cpf    FOREIGN KEY (pk_fk_cpf) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_aluno_status FOREIGN KEY (fk_status) REFERENCES tb_status_aluno(pk_status_aluno)
);

CREATE TABLE IF NOT EXISTS tb_aluno_curso (
  pk_aluno_curso INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno   CHAR(11) NOT NULL,
  fk_curso       INT      NOT NULL,
  data_inicio    DATE     NOT NULL,
  data_fim       DATE     NULL,
  CONSTRAINT pk_aluno_curso PRIMARY KEY (pk_aluno_curso),
  CONSTRAINT uq_aluno_curso UNIQUE      (fk_cpf_aluno, fk_curso, data_inicio),
  CONSTRAINT fk_ac_aluno    FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_ac_curso    FOREIGN KEY (fk_curso)     REFERENCES tb_cursos(pk_curso)
);

CREATE TABLE IF NOT EXISTS tb_historico_status_aluno (
  pk_hist      INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno CHAR(11) NOT NULL,
  fk_status    INT      NOT NULL,
  data_inicio  DATE     NOT NULL,
  data_fim     DATE     NULL,
  CONSTRAINT pk_hist_status_aluno PRIMARY KEY (pk_hist),
  CONSTRAINT uq_hist_status_aluno UNIQUE      (fk_cpf_aluno, data_inicio),
  CONSTRAINT fk_hsa_aluno         FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_hsa_status        FOREIGN KEY (fk_status)    REFERENCES tb_status_aluno(pk_status_aluno)
);

CREATE TABLE IF NOT EXISTS tb_disciplinas (
  pk_disciplina INT         NOT NULL AUTO_INCREMENT,
  nome          VARCHAR(60) NOT NULL,
  carga_horaria INT         NOT NULL,
  CONSTRAINT pk_disciplinas      PRIMARY KEY (pk_disciplina),
  CONSTRAINT uq_disciplinas_nome UNIQUE      (nome),
  CONSTRAINT ck_carga_horaria    CHECK       (carga_horaria >= 40)
);

CREATE TABLE IF NOT EXISTS tb_grade_curricular (
  fk_curso          INT NOT NULL,
  fk_disciplina     INT NOT NULL,
  semestre_sugerido INT NOT NULL,
  CONSTRAINT pk_grade_curricular PRIMARY KEY (fk_curso, fk_disciplina),
  CONSTRAINT fk_gc_curso         FOREIGN KEY (fk_curso)      REFERENCES tb_cursos(pk_curso),
  CONSTRAINT fk_gc_disciplina    FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

CREATE TABLE IF NOT EXISTS tb_pre_requisitos (
  fk_disciplina INT NOT NULL,
  fk_requisito  INT NOT NULL,
  CONSTRAINT pk_pre_requisitos PRIMARY KEY (fk_disciplina, fk_requisito),
  CONSTRAINT fk_pr_disciplina  FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_pr_requisito   FOREIGN KEY (fk_requisito)  REFERENCES tb_disciplinas(pk_disciplina)
);

CREATE TABLE IF NOT EXISTS tb_periodos (
  pk_periodo INT NOT NULL AUTO_INCREMENT,
  ano        INT NOT NULL,
  semestre   INT NOT NULL,
  CONSTRAINT pk_periodos    PRIMARY KEY (pk_periodo),
  CONSTRAINT uq_periodos    UNIQUE      (ano, semestre),
  CONSTRAINT ck_periodo_ano CHECK       (ano >= 2000),
  CONSTRAINT ck_semestre    CHECK       (semestre IN (1, 2))
);

CREATE TABLE IF NOT EXISTS tb_turmas (
  pk_turma     INT         NOT NULL AUTO_INCREMENT,
  fk_curso     INT         NOT NULL,
  nome_turma   VARCHAR(50) NOT NULL,
  periodo      VARCHAR(20) NOT NULL COMMENT 'Matutino, Vespertino, Noturno',
  ano_ingresso INT         NOT NULL,
  is_ativo     BOOLEAN     NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_turmas      PRIMARY KEY (pk_turma),
  CONSTRAINT fk_turma_curso FOREIGN KEY (fk_curso) REFERENCES tb_cursos(pk_curso)
);

-- [C3] GOV — adicionados data_criacao e ultima_atualizacao (rastreabilidade)
CREATE TABLE IF NOT EXISTS tb_matriculas (
  pk_matricula       INT       NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno       CHAR(11)  NOT NULL,
  fk_disciplina      INT       NOT NULL,
  fk_periodo         INT       NOT NULL,
  fk_turma           INT       NOT NULL,
  data_criacao       TIMESTAMP NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_matriculas     PRIMARY KEY (pk_matricula),
  CONSTRAINT uq_matriculas     UNIQUE      (fk_cpf_aluno, fk_disciplina, fk_periodo),
  CONSTRAINT fk_mat_aluno      FOREIGN KEY (fk_cpf_aluno)  REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_mat_disciplina FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_mat_periodo    FOREIGN KEY (fk_periodo)    REFERENCES tb_periodos(pk_periodo),
  CONSTRAINT fk_mat_turma      FOREIGN KEY (fk_turma)      REFERENCES tb_turmas(pk_turma)
);

CREATE TABLE IF NOT EXISTS tb_resultado_matricula (
  pk_resultado    INT          NOT NULL AUTO_INCREMENT,
  fk_matricula    INT          NOT NULL,
  situacao        VARCHAR(20)  NOT NULL COMMENT 'aprovado, reprovado, trancado, cursando',
  media_final     DECIMAL(4,2) NULL,
  total_faltas    INT          NULL,
  data_fechamento DATE         NULL,
  CONSTRAINT pk_resultado_matricula PRIMARY KEY (pk_resultado),
  CONSTRAINT uq_resultado_matricula UNIQUE      (fk_matricula),
  CONSTRAINT fk_res_matricula       FOREIGN KEY (fk_matricula) REFERENCES tb_matriculas(pk_matricula)
);

CREATE TABLE IF NOT EXISTS tb_avaliacoes (
  pk_avaliacao          INT          NOT NULL AUTO_INCREMENT,
  fk_disciplina         INT          NOT NULL,
  descricao             VARCHAR(50)  NOT NULL COMMENT 'P1, P2, Trabalho',
  peso                  DECIMAL(3,2) NOT NULL,
  data_limite_alteracao DATE         NULL,
  CONSTRAINT pk_avaliacoes      PRIMARY KEY (pk_avaliacao),
  CONSTRAINT ck_peso_avaliacao  CHECK       (peso BETWEEN 0 AND 1),
  CONSTRAINT fk_aval_disciplina FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

CREATE TABLE IF NOT EXISTS tb_salas (
  pk_sala    INT         NOT NULL AUTO_INCREMENT,
  nome       VARCHAR(20) NOT NULL,
  capacidade INT         NOT NULL,
  tipo       VARCHAR(30) NOT NULL COMMENT 'Sala de Aula, Laboratório, Auditório',
  is_ativo   BOOLEAN     NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_salas PRIMARY KEY (pk_sala)
);

-- =============================================================================
-- MÓDULO RH
-- =============================================================================

CREATE TABLE IF NOT EXISTS tb_departamentos (
  pk_departamento    INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(50) NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_departamentos PRIMARY KEY (pk_departamento)
);

CREATE TABLE IF NOT EXISTS tb_cargos (
  pk_cargo           INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(50) NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_cargos PRIMARY KEY (pk_cargo)
);

CREATE TABLE IF NOT EXISTS tb_funcionarios (
  pk_fk_cpf          CHAR(11)      NOT NULL,
  matricula_funcional INT           NOT NULL,
  fk_departamento    INT           NOT NULL,
  data_admissao      DATE          NOT NULL,
  data_demissao      DATE          NULL,
  salario_base       DECIMAL(10,2) NOT NULL,
  data_criacao       TIMESTAMP     NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP     NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_funcionarios   PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT uq_func_matricula UNIQUE      (matricula_funcional),
  CONSTRAINT fk_func_cpf       FOREIGN KEY (pk_fk_cpf)       REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_func_depto     FOREIGN KEY (fk_departamento) REFERENCES tb_departamentos(pk_departamento)
);

CREATE TABLE IF NOT EXISTS tb_historico_cargos (
  pk_hist            INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11) NOT NULL,
  fk_cargo           INT      NOT NULL,
  data_inicio        DATE     NOT NULL,
  data_fim           DATE     NULL,
  CONSTRAINT pk_hist_cargos    PRIMARY KEY (pk_hist),
  CONSTRAINT uq_hist_cargos    UNIQUE      (fk_cpf_funcionario, data_inicio),
  CONSTRAINT fk_hc_funcionario FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_hc_cargo       FOREIGN KEY (fk_cargo)           REFERENCES tb_cargos(pk_cargo)
);

CREATE TABLE IF NOT EXISTS tb_titulacoes (
  pk_titulacao INT         NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(30) NOT NULL,
  CONSTRAINT pk_titulacoes PRIMARY KEY (pk_titulacao),
  CONSTRAINT uq_titulacoes UNIQUE      (nome)
);

-- [C1] 1FN — area_atuacao VARCHAR(50) removida.
--      Professor agora é limpo; áreas ficam em tb_professor_area.
CREATE TABLE IF NOT EXISTS tb_professores (
  pk_fk_cpf    CHAR(11) NOT NULL,
  fk_titulacao INT      NOT NULL,
  CONSTRAINT pk_professores      PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT fk_prof_funcionario FOREIGN KEY (pk_fk_cpf)    REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_prof_titulacao   FOREIGN KEY (fk_titulacao) REFERENCES tb_titulacoes(pk_titulacao)
);

-- [C1] 1FN — catalogo atomico de areas de atuacao
CREATE TABLE IF NOT EXISTS tb_areas_atuacao (
  pk_area INT         NOT NULL AUTO_INCREMENT,
  nome    VARCHAR(60) NOT NULL,
  CONSTRAINT pk_areas_atuacao PRIMARY KEY (pk_area),
  CONSTRAINT uq_areas_atuacao UNIQUE      (nome)
);

-- [C1] 1FN — tabela associativa N:N professor <-> area
CREATE TABLE IF NOT EXISTS tb_professor_area (
  fk_cpf_professor CHAR(11) NOT NULL,
  fk_area          INT      NOT NULL,
  CONSTRAINT pk_professor_area PRIMARY KEY (fk_cpf_professor, fk_area),
  CONSTRAINT fk_pa_professor   FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professores(pk_fk_cpf),
  CONSTRAINT fk_pa_area        FOREIGN KEY (fk_area)          REFERENCES tb_areas_atuacao(pk_area)
);

-- tb_notas e tb_aulas dependem de tb_professores — ficam aqui após sua criação
CREATE TABLE IF NOT EXISTS tb_notas (
  pk_nota          INT          NOT NULL AUTO_INCREMENT,
  fk_matricula     INT          NOT NULL,
  fk_avaliacao     INT          NOT NULL,
  fk_cpf_professor CHAR(11)     NOT NULL,
  valor_nota       DECIMAL(4,2) NOT NULL,
  data_lancamento  TIMESTAMP    NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_notas          PRIMARY KEY (pk_nota),
  CONSTRAINT uq_notas          UNIQUE      (fk_matricula, fk_avaliacao),
  CONSTRAINT ck_valor_nota     CHECK       (valor_nota BETWEEN 0 AND 10),
  CONSTRAINT fk_nota_matricula FOREIGN KEY (fk_matricula)     REFERENCES tb_matriculas(pk_matricula),
  CONSTRAINT fk_nota_avaliacao FOREIGN KEY (fk_avaliacao)     REFERENCES tb_avaliacoes(pk_avaliacao),
  CONSTRAINT fk_nota_professor FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professores(pk_fk_cpf)
);

CREATE TABLE IF NOT EXISTS tb_log_notas (
  pk_log           INT          NOT NULL AUTO_INCREMENT,
  fk_nota          INT          NOT NULL,
  valor_antigo     DECIMAL(4,2) NOT NULL,
  valor_novo       DECIMAL(4,2) NOT NULL,
  fk_cpf_professor CHAR(11)     NOT NULL,
  data_alteracao   TIMESTAMP    NOT NULL DEFAULT NOW(),
  descricao        VARCHAR(100) NOT NULL,
  CONSTRAINT pk_log_notas     PRIMARY KEY (pk_log),
  CONSTRAINT fk_log_nota      FOREIGN KEY (fk_nota)          REFERENCES tb_notas(pk_nota),
  CONSTRAINT fk_log_professor FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professores(pk_fk_cpf)
);

CREATE TABLE IF NOT EXISTS tb_faltas (
  pk_falta     INT  NOT NULL AUTO_INCREMENT,
  fk_matricula INT  NOT NULL,
  data_falta   DATE NOT NULL,
  quantidade   INT  NOT NULL DEFAULT 1,
  CONSTRAINT pk_faltas          PRIMARY KEY (pk_falta),
  CONSTRAINT uq_faltas          UNIQUE      (fk_matricula, data_falta),
  CONSTRAINT fk_falta_matricula FOREIGN KEY (fk_matricula) REFERENCES tb_matriculas(pk_matricula)
);

CREATE TABLE IF NOT EXISTS tb_aulas (
  pk_aula          INT      NOT NULL AUTO_INCREMENT,
  fk_turma         INT      NOT NULL,
  fk_disciplina    INT      NOT NULL,
  fk_cpf_professor CHAR(11) NOT NULL,
  fk_sala          INT      NOT NULL,
  fk_periodo       INT      NOT NULL,
  dia_semana       INT      NOT NULL COMMENT '1=Segunda, 2=Terça...',
  horario_inicio   TIME     NOT NULL,
  horario_fim      TIME     NOT NULL,
  CONSTRAINT pk_aulas           PRIMARY KEY (pk_aula),
  CONSTRAINT uq_aulas_sala      UNIQUE      (fk_sala, dia_semana, horario_inicio, fk_periodo),
  CONSTRAINT uq_aulas_professor UNIQUE      (fk_cpf_professor, dia_semana, horario_inicio, fk_periodo),
  CONSTRAINT fk_aula_turma      FOREIGN KEY (fk_turma)         REFERENCES tb_turmas(pk_turma),
  CONSTRAINT fk_aula_disciplina FOREIGN KEY (fk_disciplina)    REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_aula_professor  FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professores(pk_fk_cpf),
  CONSTRAINT fk_aula_sala       FOREIGN KEY (fk_sala)          REFERENCES tb_salas(pk_sala),
  CONSTRAINT fk_aula_periodo    FOREIGN KEY (fk_periodo)       REFERENCES tb_periodos(pk_periodo)
);

CREATE TABLE IF NOT EXISTS tb_beneficios (
  pk_beneficio INT          NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(50)  NOT NULL,
  descricao    VARCHAR(100) NOT NULL,
  CONSTRAINT pk_beneficios PRIMARY KEY (pk_beneficio)
);

CREATE TABLE IF NOT EXISTS tb_funcionario_beneficio (
  fk_cpf_funcionario CHAR(11) NOT NULL,
  fk_beneficio       INT      NOT NULL,
  data_inicio        DATE     NOT NULL,
  data_fim           DATE     NULL,
  CONSTRAINT pk_func_beneficio PRIMARY KEY (fk_cpf_funcionario, fk_beneficio),
  CONSTRAINT fk_fb_funcionario FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_fb_beneficio   FOREIGN KEY (fk_beneficio)       REFERENCES tb_beneficios(pk_beneficio)
);

-- [C4] GOV — adicionados data_criacao e ultima_atualizacao (rastreabilidade + RN13)
CREATE TABLE IF NOT EXISTS tb_folha_pagamento (
  pk_folha           INT           NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  mes                INT           NOT NULL,
  ano                INT           NOT NULL,
  salario_bruto      DECIMAL(10,2) NOT NULL,
  total_descontos    DECIMAL(10,2) NOT NULL,
  salario_liquido    DECIMAL(10,2) NOT NULL,
  data_pagamento     DATE          NULL,
  status             VARCHAR(20)   NOT NULL COMMENT 'pendente, pago',
  data_criacao       TIMESTAMP     NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP     NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_folha_pagamento PRIMARY KEY (pk_folha),
  CONSTRAINT uq_folha_pagamento UNIQUE      (fk_cpf_funcionario, mes, ano),
  CONSTRAINT fk_folha_func      FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf)
);

CREATE TABLE IF NOT EXISTS tb_verbas (
  pk_verba INT         NOT NULL AUTO_INCREMENT,
  nome     VARCHAR(50) NOT NULL,
  tipo     CHAR(1)     NOT NULL COMMENT 'P = provento, D = desconto',
  CONSTRAINT pk_verbas     PRIMARY KEY (pk_verba),
  CONSTRAINT uq_verbas     UNIQUE      (nome),
  CONSTRAINT ck_verba_tipo CHECK       (tipo IN ('P', 'D'))
);

CREATE TABLE IF NOT EXISTS tb_folha_verbas (
  fk_folha INT           NOT NULL,
  fk_verba INT           NOT NULL,
  valor    DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_folha_verbas PRIMARY KEY (fk_folha, fk_verba),
  CONSTRAINT fk_fv_folha     FOREIGN KEY (fk_folha) REFERENCES tb_folha_pagamento(pk_folha),
  CONSTRAINT fk_fv_verba     FOREIGN KEY (fk_verba) REFERENCES tb_verbas(pk_verba)
);

CREATE TABLE IF NOT EXISTS tb_ferias (
  pk_ferias          INT         NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)    NOT NULL,
  data_inicio        DATE        NOT NULL,
  data_fim           DATE        NOT NULL,
  data_retorno       DATE        NULL,
  tipo               VARCHAR(20) NOT NULL COMMENT 'integral, fracionada, abono',
  status             VARCHAR(20) NOT NULL COMMENT 'agendada, em andamento, concluída',
  CONSTRAINT pk_ferias      PRIMARY KEY (pk_ferias),
  CONSTRAINT fk_ferias_func FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf)
);

CREATE TABLE IF NOT EXISTS tb_tipo_afastamento (
  pk_tipo   INT         NOT NULL AUTO_INCREMENT,
  descricao VARCHAR(50) NOT NULL,
  CONSTRAINT pk_tipo_afastamento PRIMARY KEY (pk_tipo)
);

CREATE TABLE IF NOT EXISTS tb_afastamentos (
  pk_afastamento     INT          NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)     NOT NULL,
  fk_tipo            INT          NOT NULL,
  data_inicio        DATE         NOT NULL,
  data_fim           DATE         NULL,
  observacao         VARCHAR(200) NULL,
  CONSTRAINT pk_afastamentos PRIMARY KEY (pk_afastamento),
  CONSTRAINT fk_afas_func    FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_afas_tipo    FOREIGN KEY (fk_tipo)            REFERENCES tb_tipo_afastamento(pk_tipo)
);

-- =============================================================================
-- MÓDULO FINANCEIRO
-- =============================================================================

CREATE TABLE IF NOT EXISTS tb_status_pagamento (
  pk_status_pagamento INT         NOT NULL,
  descricao           VARCHAR(20) NOT NULL COMMENT 'Pendente, Pago, Atrasado, Cancelado',
  CONSTRAINT pk_status_pagamento PRIMARY KEY (pk_status_pagamento)
);

CREATE TABLE IF NOT EXISTS tb_contratos_educacionais (
  pk_contrato       INT           NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno      CHAR(11)      NOT NULL,
  data_inicio       DATE          NOT NULL,
  data_fim          DATE          NOT NULL,
  valor_total_anual DECIMAL(10,2) NOT NULL,
  is_ativo          BOOLEAN       NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_contratos_educacionais PRIMARY KEY (pk_contrato),
  CONSTRAINT fk_cont_aluno             FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf)
);

-- [C5] N:N — tb_descontos_bolsas agora é catalogo puro (sem fk_contrato)
CREATE TABLE IF NOT EXISTS tb_descontos_bolsas (
  pk_desconto INT          NOT NULL AUTO_INCREMENT,
  tipo_bolsa  VARCHAR(50)  NOT NULL COMMENT 'ProUni, FIES, Funcionário, Desempenho',
  descricao   VARCHAR(100) NULL,
  CONSTRAINT pk_descontos_bolsas PRIMARY KEY (pk_desconto),
  CONSTRAINT uq_descontos_bolsas UNIQUE      (tipo_bolsa)
);

-- [C5] N:N — entidade associativa contrato <-> desconto
--      Um contrato pode acumular varias bolsas; o mesmo tipo de bolsa vale para N contratos.
--      RN14 (pelo menos um dos campos de valor nao pode ser nulo) aplicada aqui.
CREATE TABLE IF NOT EXISTS tb_contrato_desconto (
  fk_contrato         INT           NOT NULL,
  fk_desconto         INT           NOT NULL,
  percentual_desconto DECIMAL(5,2)  NULL,
  valor_fixo_desconto DECIMAL(10,2) NULL,
  data_inicio         DATE          NOT NULL,
  data_fim            DATE          NULL,
  CONSTRAINT pk_contrato_desconto PRIMARY KEY (fk_contrato, fk_desconto),
  CONSTRAINT fk_cd_contrato       FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
  CONSTRAINT fk_cd_desconto       FOREIGN KEY (fk_desconto) REFERENCES tb_descontos_bolsas(pk_desconto),
  CONSTRAINT ck_desconto_nao_nulo CHECK (
    percentual_desconto IS NOT NULL OR valor_fixo_desconto IS NOT NULL
  )
);

CREATE TABLE IF NOT EXISTS tb_mensalidades (
  pk_mensalidade  INT           NOT NULL AUTO_INCREMENT,
  fk_contrato     INT           NOT NULL,
  fk_status       INT           NOT NULL,
  data_vencimento DATE          NOT NULL,
  valor_liquido   DECIMAL(10,2) NOT NULL,
  valor_multa     DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_juros     DECIMAL(10,2) NOT NULL DEFAULT 0,
  CONSTRAINT pk_mensalidades  PRIMARY KEY (pk_mensalidade),
  CONSTRAINT fk_mens_contrato FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
  CONSTRAINT fk_mens_status   FOREIGN KEY (fk_status)   REFERENCES tb_status_pagamento(pk_status_pagamento)
);

CREATE TABLE IF NOT EXISTS tb_pagamentos (
  pk_pagamento   INT           NOT NULL AUTO_INCREMENT,
  fk_mensalidade INT           NOT NULL,
  valor_pago     DECIMAL(10,2) NOT NULL,
  data_pagamento TIMESTAMP     NOT NULL DEFAULT NOW(),
  meio_pagamento VARCHAR(20)   NOT NULL COMMENT 'Boleto, Pix, Cartão',
  CONSTRAINT pk_pagamentos      PRIMARY KEY (pk_pagamento),
  CONSTRAINT fk_pag_mensalidade FOREIGN KEY (fk_mensalidade) REFERENCES tb_mensalidades(pk_mensalidade)
);

-- =============================================================================
-- VIEWS — Campos Calculados (3FN)
-- =============================================================================

CREATE OR REPLACE VIEW vw_mensalidades AS
SELECT
  m.pk_mensalidade,
  m.fk_contrato,
  m.fk_status,
  sp.descricao                                       AS status_descricao,
  m.data_vencimento,
  m.valor_liquido,
  m.valor_multa,
  m.valor_juros,
  (m.valor_liquido + m.valor_multa + m.valor_juros) AS valor_total_com_encargos
FROM tb_mensalidades m
INNER JOIN tb_status_pagamento sp
  ON sp.pk_status_pagamento = m.fk_status;

CREATE OR REPLACE VIEW vw_folha_pagamento AS
SELECT
  fp.pk_folha,
  fp.fk_cpf_funcionario,
  fp.mes,
  fp.ano,
  fp.status,
  fp.data_pagamento,
  fp.salario_bruto   AS salario_bruto_snapshot,
  fp.total_descontos AS total_descontos_snapshot,
  fp.salario_liquido AS salario_liquido_snapshot,
  COALESCE(SUM(CASE WHEN v.tipo = 'P' THEN fv.valor ELSE 0 END), 0) AS salario_bruto_calculado,
  COALESCE(SUM(CASE WHEN v.tipo = 'D' THEN fv.valor ELSE 0 END), 0) AS total_descontos_calculado,
  COALESCE(SUM(CASE WHEN v.tipo = 'P' THEN fv.valor ELSE 0 END), 0)
    - COALESCE(SUM(CASE WHEN v.tipo = 'D' THEN fv.valor ELSE 0 END), 0) AS salario_liquido_calculado
FROM tb_folha_pagamento fp
LEFT JOIN tb_folha_verbas fv ON fv.fk_folha = fp.pk_folha
LEFT JOIN tb_verbas v        ON v.pk_verba  = fv.fk_verba
GROUP BY
  fp.pk_folha, fp.fk_cpf_funcionario, fp.mes, fp.ano,
  fp.status, fp.data_pagamento,
  fp.salario_bruto, fp.total_descontos, fp.salario_liquido;

-- =============================================================================
-- OTIMIZAÇÃO DE DESEMPENHO (ÍNDICES)
-- =============================================================================

-- BASE / PESSOAS
CREATE INDEX IF NOT EXISTS idx_end_cpf            ON tb_enderecos (fk_cpf);
CREATE INDEX IF NOT EXISTS idx_end_cep            ON tb_enderecos (fk_cep);
CREATE INDEX IF NOT EXISTS idx_tel_cpf            ON tb_telefones (fk_cpf);
CREATE INDEX IF NOT EXISTS idx_email_cpf          ON tb_emails (fk_cpf);

-- ACADÊMICO
CREATE INDEX IF NOT EXISTS idx_curso_tipo         ON tb_cursos (fk_tipo_curso);
CREATE INDEX IF NOT EXISTS idx_aluno_status       ON tb_alunos (fk_status);
CREATE INDEX IF NOT EXISTS idx_ac_aluno_curso     ON tb_aluno_curso (fk_cpf_aluno, fk_curso);
CREATE INDEX IF NOT EXISTS idx_ac_curso_aluno     ON tb_aluno_curso (fk_curso, fk_cpf_aluno);
CREATE INDEX IF NOT EXISTS idx_hsa_aluno_status   ON tb_historico_status_aluno (fk_cpf_aluno, fk_status);
CREATE INDEX IF NOT EXISTS idx_gc_curso_disc      ON tb_grade_curricular (fk_curso, fk_disciplina);
CREATE INDEX IF NOT EXISTS idx_pr_disc_req        ON tb_pre_requisitos (fk_disciplina, fk_requisito);
CREATE INDEX IF NOT EXISTS idx_turma_curso        ON tb_turmas (fk_curso);
CREATE INDEX IF NOT EXISTS idx_mat_aluno_periodo  ON tb_matriculas (fk_cpf_aluno, fk_periodo);
CREATE INDEX IF NOT EXISTS idx_mat_disciplina     ON tb_matriculas (fk_disciplina);
CREATE INDEX IF NOT EXISTS idx_mat_turma          ON tb_matriculas (fk_turma);
CREATE INDEX IF NOT EXISTS idx_mat_turma_disc     ON tb_matriculas (fk_turma, fk_disciplina);
CREATE INDEX IF NOT EXISTS idx_res_matricula      ON tb_resultado_matricula (fk_matricula);
CREATE INDEX IF NOT EXISTS idx_aval_disciplina    ON tb_avaliacoes (fk_disciplina);
CREATE INDEX IF NOT EXISTS idx_nota_mat_aval      ON tb_notas (fk_matricula, fk_avaliacao);
CREATE INDEX IF NOT EXISTS idx_nota_professor     ON tb_notas (fk_cpf_professor);
CREATE INDEX IF NOT EXISTS idx_log_nota           ON tb_log_notas (fk_nota);
CREATE INDEX IF NOT EXISTS idx_log_professor      ON tb_log_notas (fk_cpf_professor);
CREATE INDEX IF NOT EXISTS idx_falta_matricula    ON tb_faltas (fk_matricula);
CREATE INDEX IF NOT EXISTS idx_aula_turma_periodo ON tb_aulas (fk_turma, fk_periodo);
CREATE INDEX IF NOT EXISTS idx_aula_disciplina    ON tb_aulas (fk_disciplina);
CREATE INDEX IF NOT EXISTS idx_aula_professor     ON tb_aulas (fk_cpf_professor);
CREATE INDEX IF NOT EXISTS idx_aula_sala          ON tb_aulas (fk_sala);
CREATE INDEX IF NOT EXISTS idx_aula_prof_periodo  ON tb_aulas (fk_cpf_professor, fk_periodo);

-- RH
CREATE INDEX IF NOT EXISTS idx_func_departamento  ON tb_funcionarios (fk_departamento);
CREATE INDEX IF NOT EXISTS idx_hc_func_cargo      ON tb_historico_cargos (fk_cpf_funcionario, fk_cargo);
CREATE INDEX IF NOT EXISTS idx_prof_titulacao     ON tb_professores (fk_titulacao);
CREATE INDEX IF NOT EXISTS idx_pa_professor_area  ON tb_professor_area (fk_cpf_professor, fk_area);
CREATE INDEX IF NOT EXISTS idx_pa_area_professor  ON tb_professor_area (fk_area, fk_cpf_professor);
CREATE INDEX IF NOT EXISTS idx_fb_func_benef      ON tb_funcionario_beneficio (fk_cpf_funcionario, fk_beneficio);
CREATE INDEX IF NOT EXISTS idx_folha_funcionario  ON tb_folha_pagamento (fk_cpf_funcionario);
CREATE INDEX IF NOT EXISTS idx_fv_folha_verba     ON tb_folha_verbas (fk_folha, fk_verba);
CREATE INDEX IF NOT EXISTS idx_ferias_func        ON tb_ferias (fk_cpf_funcionario);
CREATE INDEX IF NOT EXISTS idx_afas_func_tipo     ON tb_afastamentos (fk_cpf_funcionario, fk_tipo);

-- FINANCEIRO
CREATE INDEX IF NOT EXISTS idx_cont_aluno            ON tb_contratos_educacionais (fk_cpf_aluno);
CREATE INDEX IF NOT EXISTS idx_cd_contrato           ON tb_contrato_desconto (fk_contrato);
CREATE INDEX IF NOT EXISTS idx_cd_desconto           ON tb_contrato_desconto (fk_desconto);
CREATE INDEX IF NOT EXISTS idx_mens_contrato_status  ON tb_mensalidades (fk_contrato, fk_status);
CREATE INDEX IF NOT EXISTS idx_pag_mensalidade_data  ON tb_pagamentos (fk_mensalidade, data_pagamento);

-- =============================================================================
-- CONSULTA COMPLETA (JOIN GERAL)
-- =============================================================================

-- ACADÊMICO
SELECT
  pe.pk_cpf,
  pe.primeiro_nome,
  pe.sobrenome,
  cu.nome        AS curso,
  d.nome         AS disciplina,
  m.pk_matricula,
  n.valor_nota,
  av.descricao   AS avaliacao
FROM tb_pessoas pe
INNER JOIN tb_alunos a       ON a.pk_fk_cpf     = pe.pk_cpf
INNER JOIN tb_aluno_curso ac ON ac.fk_cpf_aluno  = a.pk_fk_cpf
INNER JOIN tb_cursos cu      ON cu.pk_curso       = ac.fk_curso
INNER JOIN tb_matriculas m   ON m.fk_cpf_aluno    = a.pk_fk_cpf
INNER JOIN tb_disciplinas d  ON d.pk_disciplina   = m.fk_disciplina
LEFT  JOIN tb_notas n        ON n.fk_matricula    = m.pk_matricula
LEFT  JOIN tb_avaliacoes av  ON av.pk_avaliacao   = n.fk_avaliacao;

-- RH
SELECT
  p.pk_cpf,
  p.primeiro_nome,
  p.sobrenome,
  f.pk_fk_cpf AS funcionario,
  dep.nome    AS departamento,
  c.nome      AS cargo
FROM tb_funcionarios f
INNER JOIN tb_pessoas p           ON p.pk_cpf              = f.pk_fk_cpf
LEFT  JOIN tb_departamentos dep   ON dep.pk_departamento   = f.fk_departamento
LEFT  JOIN tb_historico_cargos hc ON hc.fk_cpf_funcionario = f.pk_fk_cpf
LEFT  JOIN tb_cargos c            ON c.pk_cargo            = hc.fk_cargo;

-- [C6] FINANCEIRO — corrigido: me.valor -> me.valor_liquido
--                              JOIN status via me.fk_status (nao pa.fk_status)
SELECT
  pe.pk_cpf,
  pe.primeiro_nome,
  pe.sobrenome,
  c.pk_contrato,
  me.pk_mensalidade,
  me.valor_liquido,
  pa.valor_pago,
  sp.descricao AS status_pagamento
FROM tb_pessoas pe
INNER JOIN tb_alunos a                 ON a.pk_fk_cpf      = pe.pk_cpf
INNER JOIN tb_contratos_educacionais c ON c.fk_cpf_aluno   = a.pk_fk_cpf
INNER JOIN tb_mensalidades me          ON me.fk_contrato   = c.pk_contrato
LEFT  JOIN tb_status_pagamento sp      ON sp.pk_status_pagamento = me.fk_status
LEFT  JOIN tb_pagamentos pa            ON pa.fk_mensalidade = me.pk_mensalidade;
