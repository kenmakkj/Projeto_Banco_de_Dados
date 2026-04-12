
-- SisGESC — Script DDL (MySQL)

CREATE DATABASE IF NOT EXISTS sisgesc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sisgesc;

CREATE TABLE tb_pessoas (
  pk_cpf             CHAR(11)     NOT NULL,
  primeiro_nome      VARCHAR(40)  NOT NULL,
  sobrenome          VARCHAR(50)  NOT NULL,
  data_nascimento    DATE         NOT NULL,
  genero             CHAR(1)      NOT NULL,
  nacionalidade      VARCHAR(20)  NOT NULL DEFAULT 'brasileira',
  data_criacao       TIMESTAMP    NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP    NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_pessoas PRIMARY KEY (pk_cpf)
);

-- Resolve dependência transitiva de tb_enderecos (3FN).
-- CEP determina logradouro, bairro, cidade e estado.
CREATE TABLE tb_cep (
  pk_cep     CHAR(8)      NOT NULL,
  logradouro VARCHAR(100) NOT NULL,
  bairro     VARCHAR(50)  NOT NULL,
  cidade     VARCHAR(50)  NOT NULL,
  estado     CHAR(2)      NOT NULL,
  CONSTRAINT pk_cep PRIMARY KEY (pk_cep)
);

CREATE TABLE tb_enderecos (
  fk_cpf             CHAR(11)    NOT NULL,
  tipo_endereco      VARCHAR(20) NOT NULL COMMENT 'Residencial, Comercial',
  fk_cep             CHAR(8)     NOT NULL,
  complemento        VARCHAR(50) NULL     COMMENT 'Apto 42, Bloco B, Sala 301',
  numero             VARCHAR(10) NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_enderecos     PRIMARY KEY (fk_cpf, tipo_endereco),
  CONSTRAINT fk_end_cpf       FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_end_cep       FOREIGN KEY (fk_cep) REFERENCES tb_cep(pk_cep)
);

CREATE TABLE tb_telefones (
  pk_telefone INT         NOT NULL AUTO_INCREMENT,
  fk_cpf      CHAR(11)    NOT NULL,
  ddd         CHAR(2)     NOT NULL,
  numero      VARCHAR(9)  NOT NULL,
  tipo        VARCHAR(20) NULL     COMMENT 'Residencial, Celular, Comercial',
  CONSTRAINT pk_telefones     PRIMARY KEY (pk_telefone),
  CONSTRAINT fk_tel_cpf       FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf)
);

CREATE TABLE tb_emails (
  pk_email INT         NOT NULL AUTO_INCREMENT,
  fk_cpf   CHAR(11)    NOT NULL,
  email    VARCHAR(70) NOT NULL,
  tipo     VARCHAR(20) NULL     COMMENT 'Pessoal, Institucional',
  CONSTRAINT pk_emails        PRIMARY KEY (pk_email),
  CONSTRAINT uq_emails        UNIQUE      (email),
  CONSTRAINT fk_email_cpf     FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf)
);

CREATE TABLE tb_tipo_curso (
  pk_tipo_curso INT         NOT NULL AUTO_INCREMENT,
  descricao     VARCHAR(30) NOT NULL COMMENT 'Graduação, Pós, Extensão',
  CONSTRAINT pk_tipo_curso  PRIMARY KEY (pk_tipo_curso),
  CONSTRAINT uq_tipo_curso  UNIQUE      (descricao)
);

CREATE TABLE tb_cursos (
  pk_curso           INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(70) NOT NULL,
  fk_tipo_curso      INT         NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_cursos        PRIMARY KEY (pk_curso),
  CONSTRAINT uq_cursos_nome   UNIQUE      (nome),
  CONSTRAINT fk_curso_tipo    FOREIGN KEY (fk_tipo_curso) REFERENCES tb_tipo_curso(pk_tipo_curso)
);

CREATE TABLE tb_status_aluno (
  pk_status_aluno INT         NOT NULL,
  descricao       VARCHAR(20) NOT NULL COMMENT 'ativo, trancado, desistente, formado',
  CONSTRAINT pk_status_aluno PRIMARY KEY (pk_status_aluno)
);

CREATE TABLE tb_alunos (
  pk_fk_cpf              CHAR(11)  NOT NULL,
  rgm                    INT       NOT NULL,
  data_matricula_inicial DATE      NOT NULL,
  fk_status              INT       NOT NULL,
  data_criacao           TIMESTAMP NOT NULL DEFAULT NOW(),
  ultima_atualizacao     TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_alunos        PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT uq_alunos_rgm    UNIQUE      (rgm),
  CONSTRAINT fk_aluno_cpf     FOREIGN KEY (pk_fk_cpf) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_aluno_status  FOREIGN KEY (fk_status) REFERENCES tb_status_aluno(pk_status_aluno)
);

-- N:N entre Aluno e Curso
-- Um aluno pode cursar duas graduações simultaneamente
CREATE TABLE tb_aluno_curso (
  pk_aluno_curso INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno   CHAR(11) NOT NULL,
  fk_curso       INT      NOT NULL,
  data_inicio    DATE     NOT NULL,
  data_fim       DATE     NULL,
  CONSTRAINT pk_aluno_curso   PRIMARY KEY (pk_aluno_curso),
  CONSTRAINT uq_aluno_curso   UNIQUE      (fk_cpf_aluno, fk_curso, data_inicio),
  CONSTRAINT fk_ac_aluno      FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_ac_curso      FOREIGN KEY (fk_curso)     REFERENCES tb_cursos(pk_curso)
);

CREATE TABLE tb_historico_status_aluno (
  pk_hist      INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno CHAR(11) NOT NULL,
  fk_status    INT      NOT NULL,
  data_inicio  DATE     NOT NULL,
  data_fim     DATE     NULL,
  CONSTRAINT pk_hist_status_aluno  PRIMARY KEY (pk_hist),
  CONSTRAINT uq_hist_status_aluno  UNIQUE      (fk_cpf_aluno, data_inicio),
  CONSTRAINT fk_hsa_aluno          FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_hsa_status         FOREIGN KEY (fk_status)    REFERENCES tb_status_aluno(pk_status_aluno)
);

CREATE TABLE tb_disciplinas (
  pk_disciplina INT         NOT NULL AUTO_INCREMENT,
  nome          VARCHAR(60) NOT NULL,
  carga_horaria INT         NOT NULL,
  -- RN03: carga horária mínima de 40 horas
  CONSTRAINT pk_disciplinas      PRIMARY KEY (pk_disciplina),
  CONSTRAINT uq_disciplinas_nome UNIQUE      (nome),
  CONSTRAINT ck_carga_horaria    CHECK       (carga_horaria >= 40)
);

-- N:N entre Curso e Disciplina
CREATE TABLE tb_grade_curricular (
  fk_curso          INT NOT NULL,
  fk_disciplina     INT NOT NULL,
  semestre_sugerido INT NOT NULL,
  CONSTRAINT pk_grade_curricular PRIMARY KEY (fk_curso, fk_disciplina),
  CONSTRAINT fk_gc_curso         FOREIGN KEY (fk_curso)      REFERENCES tb_cursos(pk_curso),
  CONSTRAINT fk_gc_disciplina    FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

-- N:N de uma disciplina com ela mesma (pré-requisitos)
-- Ex: Cálculo II (fk_disciplina) requer Cálculo I (fk_requisito)
CREATE TABLE tb_pre_requisitos (
  fk_disciplina INT NOT NULL,
  fk_requisito  INT NOT NULL,
  CONSTRAINT pk_pre_requisitos PRIMARY KEY (fk_disciplina, fk_requisito),
  CONSTRAINT fk_pr_disciplina  FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_pr_requisito   FOREIGN KEY (fk_requisito)  REFERENCES tb_disciplinas(pk_disciplina)
);

-- Centraliza Ano e Semestre, eliminando dependência transitiva
CREATE TABLE tb_periodos (
  pk_periodo INT NOT NULL AUTO_INCREMENT,
  ano        INT NOT NULL,
  semestre   INT NOT NULL,
  CONSTRAINT pk_periodos    PRIMARY KEY (pk_periodo),
  CONSTRAINT uq_periodos    UNIQUE      (ano, semestre),
  CONSTRAINT ck_periodo_ano CHECK       (ano >= 2000),
  CONSTRAINT ck_semestre    CHECK       (semestre IN (1, 2))
);

CREATE TABLE tb_turmas (
  pk_turma      INT         NOT NULL AUTO_INCREMENT,
  fk_curso      INT         NOT NULL,
  nome_turma    VARCHAR(50) NOT NULL,
  periodo       VARCHAR(20) NOT NULL COMMENT 'Matutino, Vespertino, Noturno',
  ano_ingresso  INT         NOT NULL,
  is_ativo      BOOLEAN     NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_turmas       PRIMARY KEY (pk_turma),
  CONSTRAINT fk_turma_curso  FOREIGN KEY (fk_curso) REFERENCES tb_cursos(pk_curso)
);

-- Resolve N:N entre Aluno e Disciplina por período
CREATE TABLE tb_matriculas (
  pk_matricula  INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno  CHAR(11) NOT NULL,
  fk_disciplina INT      NOT NULL,
  fk_periodo    INT      NOT NULL,
  fk_turma      INT      NOT NULL,
  CONSTRAINT pk_matriculas      PRIMARY KEY (pk_matricula),
  CONSTRAINT uq_matriculas      UNIQUE      (fk_cpf_aluno, fk_disciplina, fk_periodo),
  CONSTRAINT fk_mat_aluno       FOREIGN KEY (fk_cpf_aluno)  REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_mat_disciplina  FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_mat_periodo     FOREIGN KEY (fk_periodo)    REFERENCES tb_periodos(pk_periodo),
  CONSTRAINT fk_mat_turma       FOREIGN KEY (fk_turma)      REFERENCES tb_turmas(pk_turma)
);

-- Fecha o ciclo de cada matrícula com o resultado final.
-- Evita recalcular aprovação/reprovação toda vez na aplicação.
CREATE TABLE tb_resultado_matricula (
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

CREATE TABLE tb_avaliacoes (
  pk_avaliacao  INT          NOT NULL AUTO_INCREMENT,
  fk_disciplina INT          NOT NULL,
  descricao     VARCHAR(50)  NOT NULL COMMENT 'P1, P2, Trabalho',
  peso          DECIMAL(3,2) NOT NULL,
  CONSTRAINT pk_avaliacoes       PRIMARY KEY (pk_avaliacao),
  CONSTRAINT fk_aval_disciplina  FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

CREATE TABLE tb_notas (
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

-- Permite alterar nota após lançamento com rastreabilidade
CREATE TABLE tb_log_notas (
  pk_log           INT          NOT NULL AUTO_INCREMENT,
  fk_nota          INT          NOT NULL,
  valor_antigo     DECIMAL(4,2) NOT NULL,
  valor_novo       DECIMAL(4,2) NOT NULL,
  fk_cpf_professor CHAR(11)     NOT NULL,
  data_alteracao   TIMESTAMP    NOT NULL DEFAULT NOW(),
  descricao        VARCHAR(100) NOT NULL,
  CONSTRAINT pk_log_notas      PRIMARY KEY (pk_log),
  CONSTRAINT fk_log_nota       FOREIGN KEY (fk_nota)          REFERENCES tb_notas(pk_nota),
  CONSTRAINT fk_log_professor  FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professores(pk_fk_cpf)
);

CREATE TABLE tb_faltas (
  pk_falta     INT  NOT NULL AUTO_INCREMENT,
  fk_matricula INT  NOT NULL,
  data_falta   DATE NOT NULL,
  quantidade   INT  NOT NULL DEFAULT 1,
  CONSTRAINT pk_faltas          PRIMARY KEY (pk_falta),
  CONSTRAINT uq_faltas          UNIQUE      (fk_matricula, data_falta),
  CONSTRAINT fk_falta_matricula FOREIGN KEY (fk_matricula) REFERENCES tb_matriculas(pk_matricula)
);

CREATE TABLE tb_salas (
  pk_sala    INT         NOT NULL AUTO_INCREMENT,
  nome       VARCHAR(20) NOT NULL,
  capacidade INT         NOT NULL,
  tipo       VARCHAR(30) NOT NULL COMMENT 'Sala de Aula, Laboratório, Auditório',
  is_ativo   BOOLEAN     NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_salas PRIMARY KEY (pk_sala)
);

CREATE TABLE tb_aulas (
  pk_aula          INT      NOT NULL AUTO_INCREMENT,
  fk_turma         INT      NOT NULL,
  fk_disciplina    INT      NOT NULL,
  fk_cpf_professor CHAR(11) NOT NULL,
  fk_sala          INT      NOT NULL,
  fk_periodo       INT      NOT NULL,
  dia_semana       INT      NOT NULL COMMENT '1=Segunda, 2=Terça...',
  horario_inicio   TIME     NOT NULL,
  horario_fim      TIME     NOT NULL,
  CONSTRAINT pk_aulas            PRIMARY KEY (pk_aula),
  -- RN09: impede conflito de sala no mesmo horário e período
  CONSTRAINT uq_aulas_sala       UNIQUE      (fk_sala, dia_semana, horario_inicio, fk_periodo),
  -- RN09: impede conflito de professor no mesmo horário e período
  CONSTRAINT uq_aulas_professor  UNIQUE      (fk_cpf_professor, dia_semana, horario_inicio, fk_periodo),
  CONSTRAINT fk_aula_turma       FOREIGN KEY (fk_turma)         REFERENCES tb_turmas(pk_turma),
  CONSTRAINT fk_aula_disciplina  FOREIGN KEY (fk_disciplina)    REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_aula_professor   FOREIGN KEY (fk_cpf_professor) REFERENCES tb_professores(pk_fk_cpf),
  CONSTRAINT fk_aula_sala        FOREIGN KEY (fk_sala)          REFERENCES tb_salas(pk_sala),
  CONSTRAINT fk_aula_periodo     FOREIGN KEY (fk_periodo)       REFERENCES tb_periodos(pk_periodo)
);

CREATE TABLE tb_departamentos (
  pk_departamento    INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(50) NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_departamentos PRIMARY KEY (pk_departamento)
);

CREATE TABLE tb_cargos (
  pk_cargo           INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(50) NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_cargos PRIMARY KEY (pk_cargo)
);

CREATE TABLE tb_funcionarios (
  pk_fk_cpf           CHAR(11)      NOT NULL,
  matricula_funcional  INT           NOT NULL,
  fk_departamento      INT           NOT NULL,
  data_admissao        DATE          NOT NULL,
  data_demissao        DATE          NULL,
  salario_base         DECIMAL(10,2) NOT NULL,
  data_criacao         TIMESTAMP     NOT NULL DEFAULT NOW(),
  ultima_atualizacao   TIMESTAMP     NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_funcionarios      PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT uq_func_matricula    UNIQUE      (matricula_funcional),
  CONSTRAINT fk_func_cpf          FOREIGN KEY (pk_fk_cpf)      REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_func_depto        FOREIGN KEY (fk_departamento) REFERENCES tb_departamentos(pk_departamento)
);

CREATE TABLE tb_historico_cargos (
  pk_hist              INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario   CHAR(11) NOT NULL,
  fk_cargo             INT      NOT NULL,
  data_inicio          DATE     NOT NULL,
  data_fim             DATE     NULL,
  CONSTRAINT pk_hist_cargos    PRIMARY KEY (pk_hist),
  CONSTRAINT uq_hist_cargos    UNIQUE      (fk_cpf_funcionario, data_inicio),
  CONSTRAINT fk_hc_funcionario FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_hc_cargo       FOREIGN KEY (fk_cargo)           REFERENCES tb_cargos(pk_cargo)
);

CREATE TABLE tb_titulacoes (
  pk_titulacao INT         NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(30) NOT NULL,
  CONSTRAINT pk_titulacoes PRIMARY KEY (pk_titulacao),
  CONSTRAINT uq_titulacoes UNIQUE      (nome)
);

-- Professor é uma especialização de Funcionário (herança 1:1)
CREATE TABLE tb_professores (
  pk_fk_cpf    CHAR(11)    NOT NULL,
  area_atuacao VARCHAR(50) NOT NULL,
  fk_titulacao INT         NOT NULL,
  CONSTRAINT pk_professores      PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT fk_prof_funcionario FOREIGN KEY (pk_fk_cpf)    REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_prof_titulacao   FOREIGN KEY (fk_titulacao) REFERENCES tb_titulacoes(pk_titulacao)
);

CREATE TABLE tb_beneficios (
  pk_beneficio INT          NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(50)  NOT NULL,
  descricao    VARCHAR(100) NOT NULL,
  CONSTRAINT pk_beneficios PRIMARY KEY (pk_beneficio)
);

-- Entidade associativa N:N entre Funcionário e Benefício
CREATE TABLE tb_funcionario_beneficio (
  fk_cpf_funcionario CHAR(11) NOT NULL,
  fk_beneficio       INT      NOT NULL,
  data_inicio        DATE     NOT NULL,
  data_fim           DATE     NULL,
  CONSTRAINT pk_func_beneficio  PRIMARY KEY (fk_cpf_funcionario, fk_beneficio),
  CONSTRAINT fk_fb_funcionario  FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_fb_beneficio    FOREIGN KEY (fk_beneficio)       REFERENCES tb_beneficios(pk_beneficio)
);

-- Folha mensal por funcionário — snapshot imutável do fechamento
CREATE TABLE tb_folha_pagamento (
  pk_folha           INT           NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  mes                INT           NOT NULL,
  ano                INT           NOT NULL,
  salario_bruto      DECIMAL(10,2) NOT NULL,
  total_descontos    DECIMAL(10,2) NOT NULL,
  salario_liquido    DECIMAL(10,2) NOT NULL,
  data_pagamento     DATE          NULL,
  status             VARCHAR(20)   NOT NULL COMMENT 'pendente, pago',
  CONSTRAINT pk_folha_pagamento PRIMARY KEY (pk_folha),
  CONSTRAINT uq_folha_pagamento UNIQUE      (fk_cpf_funcionario, mes, ano),
  CONSTRAINT fk_folha_func      FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf)
);

-- Detalha cada verba (provento ou desconto) da folha
CREATE TABLE tb_verbas (
  pk_verba INT         NOT NULL AUTO_INCREMENT,
  nome     VARCHAR(50) NOT NULL,
  tipo     CHAR(1)     NOT NULL COMMENT 'P = provento, D = desconto',
  CONSTRAINT pk_verbas PRIMARY KEY (pk_verba),
  CONSTRAINT uq_verbas UNIQUE      (nome)
);

-- PK composta — uma verba não pode aparecer duas vezes na mesma folha
CREATE TABLE tb_folha_verbas (
  fk_folha INT           NOT NULL,
  fk_verba INT           NOT NULL,
  valor    DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_folha_verbas PRIMARY KEY (fk_folha, fk_verba),
  CONSTRAINT fk_fv_folha     FOREIGN KEY (fk_folha) REFERENCES tb_folha_pagamento(pk_folha),
  CONSTRAINT fk_fv_verba     FOREIGN KEY (fk_verba) REFERENCES tb_verbas(pk_verba)
);

-- Férias — CLT permite fracionamento em até 3 períodos
CREATE TABLE tb_ferias (
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

CREATE TABLE tb_tipo_afastamento (
  pk_tipo   INT         NOT NULL AUTO_INCREMENT,
  descricao VARCHAR(50) NOT NULL,
  CONSTRAINT pk_tipo_afastamento PRIMARY KEY (pk_tipo)
);

CREATE TABLE tb_afastamentos (
  pk_afastamento     INT          NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)     NOT NULL,
  fk_tipo            INT          NOT NULL,
  data_inicio        DATE         NOT NULL,
  data_fim           DATE         NULL,
  observacao         VARCHAR(200) NULL,
  CONSTRAINT pk_afastamentos  PRIMARY KEY (pk_afastamento),
  CONSTRAINT fk_afas_func     FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_afas_tipo     FOREIGN KEY (fk_tipo)            REFERENCES tb_tipo_afastamento(pk_tipo)
);

CREATE TABLE tb_status_pagamento (
  pk_status_pagamento INT         NOT NULL,
  descricao           VARCHAR(20) NOT NULL COMMENT 'Pendente, Pago, Atrasado, Cancelado',
  CONSTRAINT pk_status_pagamento PRIMARY KEY (pk_status_pagamento)
);

CREATE TABLE tb_contratos_educacionais (
  pk_contrato       INT           NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno      CHAR(11)      NOT NULL,
  data_inicio       DATE          NOT NULL,
  data_fim          DATE          NOT NULL,
  valor_total_anual DECIMAL(10,2) NOT NULL,
  is_ativo          BOOLEAN       NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_contratos_educacionais PRIMARY KEY (pk_contrato),
  CONSTRAINT fk_cont_aluno             FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf)
);

-- RN14: pelo menos um dos campos de desconto deve estar preenchido
CREATE TABLE tb_descontos_bolsas (
  pk_desconto         INT           NOT NULL AUTO_INCREMENT,
  fk_contrato         INT           NOT NULL,
  tipo_bolsa          VARCHAR(50)   NOT NULL COMMENT 'ProUni, FIES, Funcionário, Desempenho',
  percentual_desconto DECIMAL(5,2)  NULL,
  valor_fixo_desconto DECIMAL(10,2) NULL,
  CONSTRAINT pk_descontos_bolsas  PRIMARY KEY (pk_desconto),
  CONSTRAINT fk_desc_contrato     FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
  CONSTRAINT ck_desconto_nao_nulo CHECK (
    percentual_desconto IS NOT NULL OR valor_fixo_desconto IS NOT NULL
  )
);

CREATE TABLE tb_mensalidades (
  pk_mensalidade  INT           NOT NULL AUTO_INCREMENT,
  fk_contrato     INT           NOT NULL,
  fk_status       INT           NOT NULL,
  data_vencimento DATE          NOT NULL,
  valor_liquido   DECIMAL(10,2) NOT NULL,
  valor_multa     DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_juros     DECIMAL(10,2) NOT NULL DEFAULT 0,
  CONSTRAINT pk_mensalidades    PRIMARY KEY (pk_mensalidade),
  CONSTRAINT fk_mens_contrato   FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
  CONSTRAINT fk_mens_status     FOREIGN KEY (fk_status)   REFERENCES tb_status_pagamento(pk_status_pagamento)
);

CREATE TABLE tb_pagamentos (
  pk_pagamento   INT           NOT NULL AUTO_INCREMENT,
  fk_mensalidade INT           NOT NULL,
  valor_pago     DECIMAL(10,2) NOT NULL,
  data_pagamento TIMESTAMP     NOT NULL DEFAULT NOW(),
  meio_pagamento VARCHAR(20)   NOT NULL COMMENT 'Boleto, Pix, Cartão',
  CONSTRAINT pk_pagamentos          PRIMARY KEY (pk_pagamento),
  CONSTRAINT fk_pag_mensalidade     FOREIGN KEY (fk_mensalidade) REFERENCES tb_mensalidades(pk_mensalidade)
);
