-- =============================================================================
-- SisGESC - Governança e Organização
-- Sistema de Gestão Escolar — Universidade Privada

--  Script unificado de governança seguindo os requisitos da Fase 6:
--  1. Padronização de nomes em snake_case
--  2. Script comentado (este arquivo)
--  3. Script de reset com DROP + TRUNCATE (seção I)
--  4. Script único de execução — run_all.sql (seção IV)
--  5. Versionamento via tabela de controle
--
--
-- Seções deste arquivo:
-- Script de Reset      — DROP de objetos existentes (ordem segura)
-- DDL                  — Criação de todas as tabelas (snake_case)
-- DML                  — Dados iniciais / seed
-- run_all              — Chamada encadeada de todas as seções acima
-- Controle de Versão   — Tabela de versionamento do schema
-- =============================================================================

-- =============================================================================
-- SEÇÃO I — SCRIPT DE RESET
-- Objetivo: remover todos os objetos do banco antes de recriar do zero.
-- Estratégia: DROP das tabelas respeitando a ordem das FKs (dependentes
--             primeiro) para evitar erros de constraint.
-- Alternativa rápida (sem recriar estrutura): TRUNCATE (comentado ao final).
-- =============================================================================

-- Desativa temporariamente a checagem de FKs para permitir o DROP em qualquer ordem
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------
-- DROP — Módulo Financeiro (depende de Acadêmico e Pessoas)
-- -----------------------------------------------------------------------
DROP TABLE IF EXISTS tb_pagamentos;
DROP TABLE IF EXISTS tb_mensalidades;
DROP TABLE IF EXISTS tb_descontos_bolsas;
DROP TABLE IF EXISTS tb_contratos_educacionais;
DROP TABLE IF EXISTS tb_status_pagamento;

-- -----------------------------------------------------------------------
-- DROP — Módulo RH (depende de Pessoas)
-- -----------------------------------------------------------------------
DROP TABLE IF EXISTS tb_afastamentos;
DROP TABLE IF EXISTS tb_tipo_afastamento;
DROP TABLE IF EXISTS tb_ferias;
DROP TABLE IF EXISTS tb_folha_verbas;
DROP TABLE IF EXISTS tb_verbas;
DROP TABLE IF EXISTS tb_folha_pagamento;
DROP TABLE IF EXISTS tb_funcionario_beneficio;
DROP TABLE IF EXISTS tb_beneficios;
DROP TABLE IF EXISTS tb_professores;
DROP TABLE IF EXISTS tb_titulacoes;
DROP TABLE IF EXISTS tb_historico_cargos;
DROP TABLE IF EXISTS tb_funcionarios;
DROP TABLE IF EXISTS tb_cargos;
DROP TABLE IF EXISTS tb_departamentos;

-- -----------------------------------------------------------------------
-- DROP — Módulo Acadêmico (depende de Pessoas)
-- -----------------------------------------------------------------------
DROP TABLE IF EXISTS tb_faltas;
DROP TABLE IF EXISTS tb_notas;
DROP TABLE IF EXISTS tb_log_notas;
DROP TABLE IF EXISTS tb_avaliacoes;
DROP TABLE IF EXISTS tb_resultado_matricula;
DROP TABLE IF EXISTS tb_matriculas;
DROP TABLE IF EXISTS tb_aulas;
DROP TABLE IF EXISTS tb_salas;
DROP TABLE IF EXISTS tb_turmas;
DROP TABLE IF EXISTS tb_periodos;
DROP TABLE IF EXISTS tb_pre_requisitos;
DROP TABLE IF EXISTS tb_grade_curricular;
DROP TABLE IF EXISTS tb_disciplinas;
DROP TABLE IF EXISTS tb_historico_status_aluno;
DROP TABLE IF EXISTS tb_aluno_curso;
DROP TABLE IF EXISTS tb_alunos;
DROP TABLE IF EXISTS tb_status_aluno;
DROP TABLE IF EXISTS tb_cursos;
DROP TABLE IF EXISTS tb_tipo_curso;

-- -----------------------------------------------------------------------
-- DROP — Base / Pessoas
-- -----------------------------------------------------------------------
DROP TABLE IF EXISTS tb_emails;
DROP TABLE IF EXISTS tb_telefones;
DROP TABLE IF EXISTS tb_enderecos;
DROP TABLE IF EXISTS tb_cep;
DROP TABLE IF EXISTS tb_pessoas;

-- -----------------------------------------------------------------------
-- DROP — Controle de versão (Fase 6)
-- -----------------------------------------------------------------------
DROP TABLE IF EXISTS tb_schema_version;

-- Reativa a checagem de FKs
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------
-- Alternativa: TRUNCATE (limpa dados, mantém estrutura e FKs)
-- Descomente o bloco abaixo caso queira apenas limpar os dados sem
-- recriar as tabelas. Execute apenas um dos blocos (DROP ou TRUNCATE).
-- -----------------------------------------------------------------------
/*
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE tb_pagamentos;
TRUNCATE TABLE tb_mensalidades;
TRUNCATE TABLE tb_descontos_bolsas;
TRUNCATE TABLE tb_contratos_educacionais;
TRUNCATE TABLE tb_status_pagamento;
TRUNCATE TABLE tb_afastamentos;
TRUNCATE TABLE tb_tipo_afastamento;
TRUNCATE TABLE tb_ferias;
TRUNCATE TABLE tb_folha_verbas;
TRUNCATE TABLE tb_verbas;
TRUNCATE TABLE tb_folha_pagamento;
TRUNCATE TABLE tb_funcionario_beneficio;
TRUNCATE TABLE tb_beneficios;
TRUNCATE TABLE tb_professores;
TRUNCATE TABLE tb_titulacoes;
TRUNCATE TABLE tb_historico_cargos;
TRUNCATE TABLE tb_funcionarios;
TRUNCATE TABLE tb_cargos;
TRUNCATE TABLE tb_departamentos;
TRUNCATE TABLE tb_faltas;
TRUNCATE TABLE tb_notas;
TRUNCATE TABLE tb_log_notas;
TRUNCATE TABLE tb_avaliacoes;
TRUNCATE TABLE tb_resultado_matricula;
TRUNCATE TABLE tb_matriculas;
TRUNCATE TABLE tb_aulas;
TRUNCATE TABLE tb_salas;
TRUNCATE TABLE tb_turmas;
TRUNCATE TABLE tb_periodos;
TRUNCATE TABLE tb_pre_requisitos;
TRUNCATE TABLE tb_grade_curricular;
TRUNCATE TABLE tb_disciplinas;
TRUNCATE TABLE tb_historico_status_aluno;
TRUNCATE TABLE tb_aluno_curso;
TRUNCATE TABLE tb_alunos;
TRUNCATE TABLE tb_status_aluno;
TRUNCATE TABLE tb_cursos;
TRUNCATE TABLE tb_tipo_curso;
TRUNCATE TABLE tb_emails;
TRUNCATE TABLE tb_telefones;
TRUNCATE TABLE tb_enderecos;
TRUNCATE TABLE tb_cep;
TRUNCATE TABLE tb_pessoas;
TRUNCATE TABLE tb_schema_version;

SET FOREIGN_KEY_CHECKS = 1;
*/

-- =============================================================================
-- SEÇÃO II — DDL (Data Definition Language)
-- Criação de todas as tabelas, seguindo:
--   • Nomenclatura snake_case em todas as tabelas e colunas
--   • Prefixo tb_ para tabelas
--   • Prefixo pk_ para chaves primárias, fk_ para estrangeiras
--   • Prefixo uq_ para unique, ck_ para check
--   • Comentários explicativos em cada módulo e tabela relevante
-- =============================================================================

CREATE DATABASE IF NOT EXISTS sisgesc
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sisgesc;

-- =============================================================================
-- MÓDULO BASE / PESSOAS
-- Centraliza a identidade de alunos, professores e funcionários via CPF.
-- Resolve endereços em 3FN separando CEP em tabela própria.
-- =============================================================================

-- Armazena dados pessoais únicos de qualquer participante do sistema
CREATE TABLE tb_pessoas (
  pk_cpf             CHAR(11)     NOT NULL  COMMENT 'CPF sem formatação — chave natural',
  primeiro_nome      VARCHAR(40)  NOT NULL,
  sobrenome          VARCHAR(50)  NOT NULL,
  data_nascimento    DATE         NOT NULL,
  genero             CHAR(1)      NOT NULL  COMMENT 'M = Masculino, F = Feminino, O = Outro',
  nacionalidade      VARCHAR(20)  NOT NULL  DEFAULT 'brasileira',
  data_criacao       TIMESTAMP    NOT NULL  DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP    NOT NULL  DEFAULT NOW(),
  CONSTRAINT pk_pessoas PRIMARY KEY (pk_cpf)
);

-- Resolve endereços em 3FN: evita repetição de logradouro/bairro/cidade/estado
CREATE TABLE tb_cep (
  pk_cep     CHAR(8)      NOT NULL  COMMENT 'CEP sem hífen',
  logradouro VARCHAR(100) NOT NULL,
  bairro     VARCHAR(50)  NOT NULL,
  cidade     VARCHAR(50)  NOT NULL,
  estado     CHAR(2)      NOT NULL  COMMENT 'Sigla UF — ex: SP, RJ',
  CONSTRAINT pk_cep PRIMARY KEY (pk_cep)
);

-- Relaciona uma pessoa a um ou mais endereços (residencial, comercial etc.)
CREATE TABLE tb_enderecos (
  fk_cpf             CHAR(11)    NOT NULL,
  tipo_endereco      VARCHAR(20) NOT NULL  COMMENT 'Residencial, Comercial',
  fk_cep             CHAR(8)     NOT NULL,
  complemento        VARCHAR(50) NULL      COMMENT 'Apto 42, Bloco B, Sala 301',
  numero             VARCHAR(10) NULL,
  data_criacao       TIMESTAMP   NOT NULL  DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL  DEFAULT NOW(),
  CONSTRAINT pk_enderecos  PRIMARY KEY (fk_cpf, tipo_endereco),
  CONSTRAINT fk_end_cpf    FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_end_cep    FOREIGN KEY (fk_cep) REFERENCES tb_cep(pk_cep)
);

-- Permite múltiplos telefones por pessoa com indicação de tipo
CREATE TABLE tb_telefones (
  pk_telefone INT         NOT NULL AUTO_INCREMENT,
  fk_cpf      CHAR(11)    NOT NULL,
  ddd         CHAR(2)     NOT NULL,
  numero      VARCHAR(9)  NOT NULL,
  tipo        VARCHAR(20) NULL      COMMENT 'Residencial, Celular, Comercial',
  CONSTRAINT pk_telefones  PRIMARY KEY (pk_telefone),
  CONSTRAINT fk_tel_cpf    FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf)
);

-- Armazena e-mails pessoais e institucionais; unicidade garantida por constraint
CREATE TABLE tb_emails (
  pk_email INT         NOT NULL AUTO_INCREMENT,
  fk_cpf   CHAR(11)    NOT NULL,
  email    VARCHAR(70) NOT NULL,
  tipo     VARCHAR(20) NULL      COMMENT 'Pessoal, Institucional',
  CONSTRAINT pk_emails     PRIMARY KEY (pk_email),
  CONSTRAINT uq_emails     UNIQUE      (email),
  CONSTRAINT fk_email_cpf  FOREIGN KEY (fk_cpf) REFERENCES tb_pessoas(pk_cpf)
);

-- =============================================================================
-- MÓDULO ACADÊMICO
-- Gerencia cursos, alunos, matrículas, avaliações, notas, faltas e aulas.
-- Aplica regras de negócio RN01–RN10.
-- =============================================================================

-- Domínio: tipos de curso disponíveis na instituição
CREATE TABLE tb_tipo_curso (
  pk_tipo_curso INT         NOT NULL AUTO_INCREMENT,
  descricao     VARCHAR(30) NOT NULL  COMMENT 'Graduação, Pós, Extensão',
  CONSTRAINT pk_tipo_curso  PRIMARY KEY (pk_tipo_curso),
  CONSTRAINT uq_tipo_curso  UNIQUE      (descricao)
);

-- Catálogo de cursos; cada curso pertence a um tipo (graduação, pós etc.)
CREATE TABLE tb_cursos (
  pk_curso           INT         NOT NULL AUTO_INCREMENT,
  nome               VARCHAR(70) NOT NULL,
  fk_tipo_curso      INT         NOT NULL,
  data_criacao       TIMESTAMP   NOT NULL  DEFAULT NOW(),
  ultima_atualizacao TIMESTAMP   NOT NULL  DEFAULT NOW(),
  CONSTRAINT pk_cursos       PRIMARY KEY (pk_curso),
  CONSTRAINT uq_cursos_nome  UNIQUE      (nome),
  CONSTRAINT fk_curso_tipo   FOREIGN KEY (fk_tipo_curso) REFERENCES tb_tipo_curso(pk_tipo_curso)
);

-- Domínio: situação acadêmica do aluno (ativo, trancado, desistente, formado)
CREATE TABLE tb_status_aluno (
  pk_status_aluno INT         NOT NULL,
  descricao       VARCHAR(20) NOT NULL  COMMENT 'ativo, trancado, desistente, formado',
  CONSTRAINT pk_status_aluno  PRIMARY KEY (pk_status_aluno),
  CONSTRAINT uq_status_aluno  UNIQUE      (descricao)
);

-- Especialização de tb_pessoas para alunos; RGM é o registro acadêmico único
CREATE TABLE tb_alunos (
  pk_fk_cpf              CHAR(11)  NOT NULL,
  rgm                    INT       NOT NULL  COMMENT 'Registro Geral de Matrícula — único',
  data_matricula_inicial DATE      NOT NULL,
  fk_status              INT       NOT NULL,
  data_criacao           TIMESTAMP NOT NULL  DEFAULT NOW(),
  ultima_atualizacao     TIMESTAMP NOT NULL  DEFAULT NOW(),
  CONSTRAINT pk_alunos        PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT uq_alunos_rgm    UNIQUE      (rgm),
  CONSTRAINT fk_aluno_cpf     FOREIGN KEY (pk_fk_cpf) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_aluno_status  FOREIGN KEY (fk_status) REFERENCES tb_status_aluno(pk_status_aluno)
);

-- Relaciona um aluno a um ou mais cursos ao longo do tempo
CREATE TABLE tb_aluno_curso (
  pk_aluno_curso INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno   CHAR(11) NOT NULL,
  fk_curso       INT      NOT NULL,
  data_inicio    DATE     NOT NULL,
  data_fim       DATE     NULL      COMMENT 'NULL = vínculo ativo',
  CONSTRAINT pk_aluno_curso  PRIMARY KEY (pk_aluno_curso),
  CONSTRAINT uq_aluno_curso  UNIQUE      (fk_cpf_aluno, fk_curso, data_inicio),
  CONSTRAINT fk_ac_aluno     FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_ac_curso     FOREIGN KEY (fk_curso)     REFERENCES tb_cursos(pk_curso)
);

-- Auditoria de mudanças de status acadêmico (ex: ativo → trancado → ativo)
CREATE TABLE tb_historico_status_aluno (
  pk_hist      INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno CHAR(11) NOT NULL,
  fk_status    INT      NOT NULL,
  data_inicio  DATE     NOT NULL,
  data_fim     DATE     NULL      COMMENT 'NULL = status atual',
  CONSTRAINT pk_hist_status_aluno  PRIMARY KEY (pk_hist),
  CONSTRAINT uq_hist_status_aluno  UNIQUE      (fk_cpf_aluno, data_inicio),
  CONSTRAINT fk_hsa_aluno          FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_hsa_status         FOREIGN KEY (fk_status)    REFERENCES tb_status_aluno(pk_status_aluno)
);

-- Catálogo de disciplinas; carga horária mínima de 40h por RN05
CREATE TABLE tb_disciplinas (
  pk_disciplina INT         NOT NULL AUTO_INCREMENT,
  nome          VARCHAR(60) NOT NULL,
  carga_horaria INT         NOT NULL,
  CONSTRAINT pk_disciplinas       PRIMARY KEY (pk_disciplina),
  CONSTRAINT uq_disciplinas_nome  UNIQUE      (nome),
  CONSTRAINT ck_carga_horaria     CHECK       (carga_horaria >= 40)
);

-- Grade curricular: quais disciplinas compõem cada curso e em que semestre
CREATE TABLE tb_grade_curricular (
  fk_curso          INT NOT NULL,
  fk_disciplina     INT NOT NULL,
  semestre_sugerido INT NOT NULL,
  CONSTRAINT pk_grade_curricular  PRIMARY KEY (fk_curso, fk_disciplina),
  CONSTRAINT fk_gc_curso          FOREIGN KEY (fk_curso)      REFERENCES tb_cursos(pk_curso),
  CONSTRAINT fk_gc_disciplina     FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

-- Pré-requisitos entre disciplinas (RN07: não pode cursar sem ter cursado o requisito)
CREATE TABLE tb_pre_requisitos (
  fk_disciplina INT NOT NULL,
  fk_requisito  INT NOT NULL,
  CONSTRAINT pk_pre_requisitos  PRIMARY KEY (fk_disciplina, fk_requisito),
  CONSTRAINT fk_pr_disciplina   FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_pr_requisito    FOREIGN KEY (fk_requisito)  REFERENCES tb_disciplinas(pk_disciplina)
);

-- Semestres letivos; combinação ano+semestre é única
CREATE TABLE tb_periodos (
  pk_periodo INT NOT NULL AUTO_INCREMENT,
  ano        INT NOT NULL,
  semestre   INT NOT NULL,
  CONSTRAINT pk_periodos    PRIMARY KEY (pk_periodo),
  CONSTRAINT uq_periodos    UNIQUE      (ano, semestre),
  CONSTRAINT ck_periodo_ano CHECK       (ano >= 2000),
  CONSTRAINT ck_semestre    CHECK       (semestre IN (1, 2))
);

-- Turmas: instância de um curso em um período específico
CREATE TABLE tb_turmas (
  pk_turma   INT         NOT NULL AUTO_INCREMENT,
  fk_curso   INT         NOT NULL,
  fk_periodo INT         NOT NULL,
  codigo     VARCHAR(10) NOT NULL  COMMENT 'Ex: ADS2025A',
  turno      VARCHAR(10) NOT NULL  COMMENT 'Manhã, Tarde, Noite',
  CONSTRAINT pk_turmas    PRIMARY KEY (pk_turma),
  CONSTRAINT uq_turmas    UNIQUE      (fk_curso, fk_periodo, codigo),
  CONSTRAINT fk_turma_curso    FOREIGN KEY (fk_curso)   REFERENCES tb_cursos(pk_curso),
  CONSTRAINT fk_turma_periodo  FOREIGN KEY (fk_periodo) REFERENCES tb_periodos(pk_periodo)
);

-- Salas físicas disponíveis para alocação de aulas
CREATE TABLE tb_salas (
  pk_sala    INT         NOT NULL AUTO_INCREMENT,
  codigo     VARCHAR(10) NOT NULL  COMMENT 'Ex: LAB-01, B-202',
  capacidade INT         NOT NULL,
  tipo       VARCHAR(20) NOT NULL  COMMENT 'Laboratório, Sala de Aula, Auditório',
  CONSTRAINT pk_salas  PRIMARY KEY (pk_sala),
  CONSTRAINT uq_salas  UNIQUE      (codigo)
);

-- Agenda de aulas: relaciona turma, disciplina, professor, sala e período
CREATE TABLE tb_aulas (
  pk_aula          INT      NOT NULL AUTO_INCREMENT,
  fk_turma         INT      NOT NULL,
  fk_disciplina    INT      NOT NULL,
  fk_cpf_professor CHAR(11) NOT NULL,
  fk_sala          INT      NOT NULL,
  fk_periodo       INT      NOT NULL,
  dia_semana       INT      NOT NULL  COMMENT '1=Dom, 2=Seg, …, 7=Sáb',
  horario_inicio   TIME     NOT NULL,
  horario_fim      TIME     NOT NULL,
  CONSTRAINT pk_aulas         PRIMARY KEY (pk_aula),
  CONSTRAINT fk_aula_turma    FOREIGN KEY (fk_turma)         REFERENCES tb_turmas(pk_turma),
  CONSTRAINT fk_aula_disc     FOREIGN KEY (fk_disciplina)    REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_aula_prof     FOREIGN KEY (fk_cpf_professor) REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_aula_sala     FOREIGN KEY (fk_sala)          REFERENCES tb_salas(pk_sala),
  CONSTRAINT fk_aula_periodo  FOREIGN KEY (fk_periodo)       REFERENCES tb_periodos(pk_periodo)
);

-- Matrículas de alunos em disciplinas por período
CREATE TABLE tb_matriculas (
  pk_matricula  INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno  CHAR(11) NOT NULL,
  fk_disciplina INT      NOT NULL,
  fk_periodo    INT      NOT NULL,
  fk_turma      INT      NOT NULL,
  CONSTRAINT pk_matriculas     PRIMARY KEY (pk_matricula),
  CONSTRAINT uq_matriculas     UNIQUE      (fk_cpf_aluno, fk_disciplina, fk_periodo),
  CONSTRAINT fk_mat_aluno      FOREIGN KEY (fk_cpf_aluno)  REFERENCES tb_alunos(pk_fk_cpf),
  CONSTRAINT fk_mat_disciplina FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina),
  CONSTRAINT fk_mat_periodo    FOREIGN KEY (fk_periodo)    REFERENCES tb_periodos(pk_periodo),
  CONSTRAINT fk_mat_turma      FOREIGN KEY (fk_turma)      REFERENCES tb_turmas(pk_turma)
);

-- Resultado final de cada matrícula ao encerramento do período
CREATE TABLE tb_resultado_matricula (
  fk_matricula    INT          NOT NULL,
  situacao        VARCHAR(20)  NOT NULL  COMMENT 'aprovado, reprovado, cursando',
  media_final     DECIMAL(4,2) NULL,
  total_faltas    INT          NULL,
  data_fechamento DATE         NULL,
  CONSTRAINT pk_resultado_matricula  PRIMARY KEY (fk_matricula),
  CONSTRAINT fk_res_matricula        FOREIGN KEY (fk_matricula) REFERENCES tb_matriculas(pk_matricula)
);

-- Definição de avaliações por disciplina (provas, trabalhos, projetos)
CREATE TABLE tb_avaliacoes (
  pk_avaliacao          INT          NOT NULL AUTO_INCREMENT,
  fk_disciplina         INT          NOT NULL,
  descricao             VARCHAR(30)  NOT NULL  COMMENT 'P1, P2, Trabalho, Projeto',
  peso                  DECIMAL(4,2) NOT NULL,
  data_limite_alteracao DATE         NOT NULL  COMMENT 'Prazo máximo para correção de nota',
  CONSTRAINT pk_avaliacoes    PRIMARY KEY (pk_avaliacao),
  CONSTRAINT fk_aval_disc     FOREIGN KEY (fk_disciplina) REFERENCES tb_disciplinas(pk_disciplina)
);

-- Notas individuais por matrícula e avaliação
CREATE TABLE tb_notas (
  pk_nota          INT          NOT NULL AUTO_INCREMENT,
  fk_matricula     INT          NOT NULL,
  fk_avaliacao     INT          NOT NULL,
  fk_cpf_professor CHAR(11)     NOT NULL,
  valor_nota       DECIMAL(4,2) NOT NULL,
  data_lancamento  TIMESTAMP    NOT NULL  DEFAULT NOW(),
  CONSTRAINT pk_notas      PRIMARY KEY (pk_nota),
  CONSTRAINT uq_notas      UNIQUE      (fk_matricula, fk_avaliacao),
  CONSTRAINT fk_nota_mat   FOREIGN KEY (fk_matricula)     REFERENCES tb_matriculas(pk_matricula),
  CONSTRAINT fk_nota_aval  FOREIGN KEY (fk_avaliacao)     REFERENCES tb_avaliacoes(pk_avaliacao),
  CONSTRAINT fk_nota_prof  FOREIGN KEY (fk_cpf_professor) REFERENCES tb_pessoas(pk_cpf)
);

-- Log de auditoria: registra toda alteração de nota para rastreabilidade
CREATE TABLE tb_log_notas (
  pk_log           INT          NOT NULL AUTO_INCREMENT,
  fk_nota          INT          NOT NULL,
  valor_antigo     DECIMAL(4,2) NOT NULL,
  valor_novo       DECIMAL(4,2) NOT NULL,
  fk_cpf_professor CHAR(11)     NOT NULL,
  data_alteracao   TIMESTAMP    NOT NULL  DEFAULT NOW(),
  descricao        VARCHAR(200) NULL      COMMENT 'Justificativa da alteração',
  CONSTRAINT pk_log_notas  PRIMARY KEY (pk_log),
  CONSTRAINT fk_log_nota   FOREIGN KEY (fk_nota)          REFERENCES tb_notas(pk_nota),
  CONSTRAINT fk_log_prof   FOREIGN KEY (fk_cpf_professor) REFERENCES tb_pessoas(pk_cpf)
);

-- Registro de faltas por matrícula e data
CREATE TABLE tb_faltas (
  pk_falta     INT  NOT NULL AUTO_INCREMENT,
  fk_matricula INT  NOT NULL,
  data_falta   DATE NOT NULL,
  quantidade   INT  NOT NULL  DEFAULT 1  COMMENT 'Número de aulas faltadas no dia',
  CONSTRAINT pk_faltas   PRIMARY KEY (pk_falta),
  CONSTRAINT uq_faltas   UNIQUE      (fk_matricula, data_falta),
  CONSTRAINT fk_fal_mat  FOREIGN KEY (fk_matricula) REFERENCES tb_matriculas(pk_matricula)
);

-- =============================================================================
-- MÓDULO RH
-- Gerencia funcionários, cargos, departamentos, folha de pagamento,
-- férias e afastamentos.
-- =============================================================================

-- Estrutura organizacional: departamentos da universidade
CREATE TABLE tb_departamentos (
  pk_departamento INT         NOT NULL AUTO_INCREMENT,
  nome            VARCHAR(50) NOT NULL,
  sigla           VARCHAR(10) NOT NULL  COMMENT 'Ex: TI, RH, ACAD',
  CONSTRAINT pk_departamentos  PRIMARY KEY (pk_departamento),
  CONSTRAINT uq_depto_sigla    UNIQUE      (sigla)
);

-- Catálogo de cargos disponíveis na instituição
CREATE TABLE tb_cargos (
  pk_cargo INT         NOT NULL AUTO_INCREMENT,
  nome     VARCHAR(50) NOT NULL,
  nivel    VARCHAR(20) NOT NULL  COMMENT 'Operacional, Tático, Estratégico',
  CONSTRAINT pk_cargos  PRIMARY KEY (pk_cargo),
  CONSTRAINT uq_cargos  UNIQUE      (nome)
);

-- Especialização de tb_pessoas para funcionários; salário_base e vínculo com departamento
CREATE TABLE tb_funcionarios (
  pk_fk_cpf           CHAR(11)      NOT NULL,
  matricula_funcional  INT           NOT NULL  COMMENT 'Número de matrícula interno único',
  fk_departamento      INT           NOT NULL,
  data_admissao        DATE          NOT NULL,
  data_demissao        DATE          NULL       COMMENT 'NULL = funcionário ativo',
  salario_base         DECIMAL(10,2) NOT NULL,
  data_criacao         TIMESTAMP     NOT NULL   DEFAULT NOW(),
  ultima_atualizacao   TIMESTAMP     NOT NULL   DEFAULT NOW(),
  CONSTRAINT pk_funcionarios      PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT uq_func_matricula    UNIQUE      (matricula_funcional),
  CONSTRAINT fk_func_cpf          FOREIGN KEY (pk_fk_cpf)       REFERENCES tb_pessoas(pk_cpf),
  CONSTRAINT fk_func_depto        FOREIGN KEY (fk_departamento) REFERENCES tb_departamentos(pk_departamento)
);

-- Histórico de cargos por funcionário (permite rastrear promoções e transferências)
CREATE TABLE tb_historico_cargos (
  pk_hist              INT      NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario   CHAR(11) NOT NULL,
  fk_cargo             INT      NOT NULL,
  data_inicio          DATE     NOT NULL,
  data_fim             DATE     NULL       COMMENT 'NULL = cargo atual',
  CONSTRAINT pk_hist_cargos     PRIMARY KEY (pk_hist),
  CONSTRAINT uq_hist_cargos     UNIQUE      (fk_cpf_funcionario, data_inicio),
  CONSTRAINT fk_hc_funcionario  FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_hc_cargo        FOREIGN KEY (fk_cargo)           REFERENCES tb_cargos(pk_cargo)
);

-- Domínio de titulações acadêmicas dos professores
CREATE TABLE tb_titulacoes (
  pk_titulacao INT         NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(30) NOT NULL  COMMENT 'Graduação, Especialização, Mestrado, Doutorado',
  CONSTRAINT pk_titulacoes  PRIMARY KEY (pk_titulacao),
  CONSTRAINT uq_titulacoes  UNIQUE      (nome)
);

-- Especialização de tb_funcionarios para professores: área de atuação e titulação
CREATE TABLE tb_professores (
  pk_fk_cpf    CHAR(11)    NOT NULL,
  area_atuacao VARCHAR(50) NOT NULL,
  fk_titulacao INT         NOT NULL,
  CONSTRAINT pk_professores      PRIMARY KEY (pk_fk_cpf),
  CONSTRAINT fk_prof_funcionario FOREIGN KEY (pk_fk_cpf)    REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_prof_titulacao   FOREIGN KEY (fk_titulacao) REFERENCES tb_titulacoes(pk_titulacao)
);

-- Catálogo de benefícios oferecidos pela instituição
CREATE TABLE tb_beneficios (
  pk_beneficio INT          NOT NULL AUTO_INCREMENT,
  nome         VARCHAR(50)  NOT NULL,
  descricao    VARCHAR(100) NOT NULL,
  CONSTRAINT pk_beneficios  PRIMARY KEY (pk_beneficio)
);

-- Associação funcionário-benefício com período de vigência
CREATE TABLE tb_funcionario_beneficio (
  fk_cpf_funcionario CHAR(11) NOT NULL,
  fk_beneficio       INT      NOT NULL,
  data_inicio        DATE     NOT NULL,
  data_fim           DATE     NULL       COMMENT 'NULL = benefício ativo',
  CONSTRAINT pk_func_beneficio  PRIMARY KEY (fk_cpf_funcionario, fk_beneficio),
  CONSTRAINT fk_fb_funcionario  FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_fb_beneficio    FOREIGN KEY (fk_beneficio)       REFERENCES tb_beneficios(pk_beneficio)
);

-- Cabeçalho da folha de pagamento mensal por funcionário
CREATE TABLE tb_folha_pagamento (
  pk_folha           INT           NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)      NOT NULL,
  mes                INT           NOT NULL,
  ano                INT           NOT NULL,
  salario_bruto      DECIMAL(10,2) NOT NULL,
  total_descontos    DECIMAL(10,2) NOT NULL,
  salario_liquido    DECIMAL(10,2) NOT NULL,
  data_pagamento     DATE          NULL       COMMENT 'NULL = folha ainda não paga',
  status             VARCHAR(20)   NOT NULL   COMMENT 'pendente, pago',
  CONSTRAINT pk_folha_pagamento  PRIMARY KEY (pk_folha),
  CONSTRAINT uq_folha_pagamento  UNIQUE      (fk_cpf_funcionario, mes, ano),
  CONSTRAINT fk_folha_func       FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf)
);

-- Domínio de verbas trabalhistas (proventos e descontos)
CREATE TABLE tb_verbas (
  pk_verba INT         NOT NULL AUTO_INCREMENT,
  nome     VARCHAR(50) NOT NULL,
  tipo     CHAR(1)     NOT NULL  COMMENT 'P = Provento (crédito), D = Desconto (débito)',
  CONSTRAINT pk_verbas  PRIMARY KEY (pk_verba),
  CONSTRAINT uq_verbas  UNIQUE      (nome)
);

-- Detalhamento de cada verba dentro de uma folha de pagamento
CREATE TABLE tb_folha_verbas (
  fk_folha INT           NOT NULL,
  fk_verba INT           NOT NULL,
  valor    DECIMAL(10,2) NOT NULL,
  CONSTRAINT pk_folha_verbas  PRIMARY KEY (fk_folha, fk_verba),
  CONSTRAINT fk_fv_folha      FOREIGN KEY (fk_folha) REFERENCES tb_folha_pagamento(pk_folha),
  CONSTRAINT fk_fv_verba      FOREIGN KEY (fk_verba) REFERENCES tb_verbas(pk_verba)
);

-- Controle de férias dos funcionários (integral, fracionada ou abono)
CREATE TABLE tb_ferias (
  pk_ferias          INT         NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)    NOT NULL,
  data_inicio        DATE        NOT NULL,
  data_fim           DATE        NOT NULL,
  data_retorno       DATE        NULL,
  tipo               VARCHAR(20) NOT NULL  COMMENT 'integral, fracionada, abono',
  status             VARCHAR(20) NOT NULL  COMMENT 'agendada, em andamento, concluída',
  CONSTRAINT pk_ferias       PRIMARY KEY (pk_ferias),
  CONSTRAINT fk_ferias_func  FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf)
);

-- Domínio de tipos de afastamento (licença médica, maternidade etc.)
CREATE TABLE tb_tipo_afastamento (
  pk_tipo   INT         NOT NULL AUTO_INCREMENT,
  descricao VARCHAR(50) NOT NULL,
  CONSTRAINT pk_tipo_afastamento  PRIMARY KEY (pk_tipo)
);

-- Registro de afastamentos com período e justificativa
CREATE TABLE tb_afastamentos (
  pk_afastamento     INT          NOT NULL AUTO_INCREMENT,
  fk_cpf_funcionario CHAR(11)     NOT NULL,
  fk_tipo            INT          NOT NULL,
  data_inicio        DATE         NOT NULL,
  data_fim           DATE         NULL       COMMENT 'NULL = afastamento em aberto',
  observacao         VARCHAR(200) NULL,
  CONSTRAINT pk_afastamentos  PRIMARY KEY (pk_afastamento),
  CONSTRAINT fk_afas_func     FOREIGN KEY (fk_cpf_funcionario) REFERENCES tb_funcionarios(pk_fk_cpf),
  CONSTRAINT fk_afas_tipo     FOREIGN KEY (fk_tipo)            REFERENCES tb_tipo_afastamento(pk_tipo)
);

-- =============================================================================
-- MÓDULO FINANCEIRO
-- Gerencia contratos educacionais, bolsas/descontos, mensalidades e pagamentos.
-- Integra com o Módulo Acadêmico via RN02, RN04 e RN11.
-- Regras de negócio: RN14 e RN15 (bolsas e inadimplência).
-- =============================================================================

-- Domínio: situações de pagamento de uma mensalidade
CREATE TABLE tb_status_pagamento (
  pk_status_pagamento INT         NOT NULL,
  descricao           VARCHAR(20) NOT NULL  COMMENT 'Pendente, Pago, Atrasado, Cancelado',
  CONSTRAINT pk_status_pagamento  PRIMARY KEY (pk_status_pagamento)
);

-- Contrato anual entre aluno e instituição; base de geração das mensalidades
CREATE TABLE tb_contratos_educacionais (
  pk_contrato       INT           NOT NULL AUTO_INCREMENT,
  fk_cpf_aluno      CHAR(11)      NOT NULL,
  data_inicio       DATE          NOT NULL,
  data_fim          DATE          NOT NULL,
  valor_total_anual DECIMAL(10,2) NOT NULL,
  is_ativo          BOOLEAN       NOT NULL  DEFAULT TRUE,
  CONSTRAINT pk_contratos_educacionais  PRIMARY KEY (pk_contrato),
  CONSTRAINT fk_cont_aluno              FOREIGN KEY (fk_cpf_aluno) REFERENCES tb_alunos(pk_fk_cpf)
);

-- Bolsas e descontos vinculados a um contrato (RN14: ao menos um campo preenchido)
CREATE TABLE tb_descontos_bolsas (
  pk_desconto         INT           NOT NULL AUTO_INCREMENT,
  fk_contrato         INT           NOT NULL,
  tipo_bolsa          VARCHAR(50)   NOT NULL  COMMENT 'ProUni, FIES, Funcionário, Desempenho',
  percentual_desconto DECIMAL(5,2)  NULL,
  valor_fixo_desconto DECIMAL(10,2) NULL,
  CONSTRAINT pk_descontos_bolsas  PRIMARY KEY (pk_desconto),
  CONSTRAINT fk_desc_contrato     FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
  CONSTRAINT ck_desconto_nao_nulo CHECK (
    percentual_desconto IS NOT NULL OR valor_fixo_desconto IS NOT NULL
  )
);

-- Mensalidades geradas a partir de um contrato; multa e juros zerados por padrão
CREATE TABLE tb_mensalidades (
  pk_mensalidade  INT           NOT NULL AUTO_INCREMENT,
  fk_contrato     INT           NOT NULL,
  fk_status       INT           NOT NULL,
  data_vencimento DATE          NOT NULL,
  valor_liquido   DECIMAL(10,2) NOT NULL,
  valor_multa     DECIMAL(10,2) NOT NULL  DEFAULT 0,
  valor_juros     DECIMAL(10,2) NOT NULL  DEFAULT 0,
  CONSTRAINT pk_mensalidades   PRIMARY KEY (pk_mensalidade),
  CONSTRAINT fk_mens_contrato  FOREIGN KEY (fk_contrato) REFERENCES tb_contratos_educacionais(pk_contrato),
  CONSTRAINT fk_mens_status    FOREIGN KEY (fk_status)   REFERENCES tb_status_pagamento(pk_status_pagamento)
);

-- Comprovação de pagamentos; uma mensalidade pode ter mais de um registro (estorno etc.)
CREATE TABLE tb_pagamentos (
  pk_pagamento   INT           NOT NULL AUTO_INCREMENT,
  fk_mensalidade INT           NOT NULL,
  valor_pago     DECIMAL(10,2) NOT NULL,
  data_pagamento TIMESTAMP     NOT NULL  DEFAULT NOW(),
  meio_pagamento VARCHAR(20)   NOT NULL  COMMENT 'Boleto, Pix, Cartão',
  CONSTRAINT pk_pagamentos      PRIMARY KEY (pk_pagamento),
  CONSTRAINT fk_pag_mensalidade FOREIGN KEY (fk_mensalidade) REFERENCES tb_mensalidades(pk_mensalidade)
);

-- =============================================================================
-- SEÇÃO V — CONTROLE DE VERSÃO DO SCHEMA
-- Tabela de versionamento para rastrear migrações aplicadas ao banco.
-- Substitui controle manual; pode ser integrada a ferramentas como Flyway/Liquibase.
-- =============================================================================

CREATE TABLE tb_schema_version (
  pk_id         INT          NOT NULL AUTO_INCREMENT  COMMENT 'ID sequencial da migração',
  versao        VARCHAR(20)  NOT NULL                 COMMENT 'Ex: 6.0.0, 6.1.0',
  descricao     VARCHAR(200) NOT NULL                 COMMENT 'Descrição da mudança aplicada',
  script        VARCHAR(100) NOT NULL                 COMMENT 'Nome do arquivo SQL executado',
  aplicado_em   TIMESTAMP    NOT NULL  DEFAULT NOW()  COMMENT 'Data/hora de execução',
  aplicado_por  VARCHAR(50)  NOT NULL  DEFAULT 'admin' COMMENT 'Usuário que aplicou a migração',
  status        VARCHAR(20)  NOT NULL  DEFAULT 'sucesso' COMMENT 'sucesso, falha',
  CONSTRAINT pk_schema_version  PRIMARY KEY (pk_id),
  CONSTRAINT uq_schema_versao   UNIQUE      (versao, script)
);

-- =============================================================================
-- SEÇÃO III — DML (Data Manipulation Language)
-- Dados iniciais (seed) necessários para o funcionamento do sistema.
-- Todos os INSERTs usam INSERT IGNORE para garantir idempotência:
-- ao reexecutar o script, nenhum dado será duplicado.
-- =============================================================================

USE sisgesc;

-- -----------------------------------------------------------------------
-- Base / Pessoas
-- -----------------------------------------------------------------------

INSERT IGNORE INTO tb_cep (pk_cep, logradouro, bairro, cidade, estado) VALUES
('01310100', 'Avenida Paulista',              'Bela Vista',           'São Paulo',      'SP'),
('01001000', 'Praça da Sé',                   'Sé',                   'São Paulo',      'SP'),
('20040020', 'Avenida Rio Branco',            'Centro',               'Rio de Janeiro', 'RJ'),
('30112000', 'Rua dos Caetés',                'Centro',               'Belo Horizonte', 'MG'),
('80010010', 'Rua XV de Novembro',            'Centro',               'Curitiba',       'PR'),
('69005010', 'Avenida Getúlio Vargas',        'Centro',               'Manaus',         'AM'),
('40020010', 'Avenida Sete de Setembro',      'Centro',               'Salvador',       'BA'),
('01310200', 'Rua Augusta',                   'Consolação',           'São Paulo',      'SP'),
('04547130', 'Avenida Brigadeiro Faria Lima', 'Itaim Bibi',           'São Paulo',      'SP'),
('05508010', 'Rua do Matão',                  'Cidade Universitária', 'São Paulo',      'SP');

INSERT IGNORE INTO tb_pessoas (pk_cpf, primeiro_nome, sobrenome, data_nascimento, genero, nacionalidade) VALUES
-- Alunos
('11122233344', 'Lucas',    'Oliveira',   '2001-03-15', 'M', 'brasileira'),
('22233344455', 'Fernanda', 'Santos',     '2000-07-22', 'F', 'brasileira'),
('33344455566', 'Rafael',   'Costa',      '2002-01-08', 'M', 'brasileira'),
('44455566677', 'Juliana',  'Pereira',    '2001-11-30', 'F', 'brasileira'),
('55566677788', 'Bruno',    'Almeida',    '2003-05-17', 'M', 'brasileira'),
('66677788899', 'Carla',    'Ferreira',   '2000-09-04', 'F', 'brasileira'),
('77788899900', 'Diego',    'Lima',       '2002-12-21', 'M', 'brasileira'),
('88899900011', 'Amanda',   'Souza',      '2001-06-10', 'F', 'brasileira'),
-- Professores / funcionários
('99900011122', 'Marcos',   'Rodrigues',  '1978-04-25', 'M', 'brasileira'),
('10011122233', 'Patricia', 'Mendes',     '1982-08-14', 'F', 'brasileira'),
('11122233355', 'Carlos',   'Nascimento', '1975-02-28', 'M', 'brasileira'),
('22233344466', 'Beatriz',  'Cardoso',    '1985-10-05', 'F', 'brasileira'),
-- Funcionários administrativos
('33344455577', 'Roberto',  'Teixeira',   '1980-06-18', 'M', 'brasileira'),
('44455566688', 'Simone',   'Barbosa',    '1990-03-09', 'F', 'brasileira'),
('55566677799', 'Andre',    'Gomes',      '1988-11-22', 'M', 'brasileira');

INSERT IGNORE INTO tb_enderecos (fk_cpf, tipo_endereco, fk_cep, complemento, numero) VALUES
('11122233344', 'Residencial', '01310100', 'Apto 42',  '1500'),
('22233344455', 'Residencial', '01001000', NULL,        '200'),
('33344455566', 'Residencial', '20040020', 'Bloco B',  '350'),
('44455566677', 'Residencial', '30112000', 'Apto 10',  '820'),
('55566677788', 'Residencial', '80010010', NULL,        '55'),
('66677788899', 'Residencial', '69005010', 'Casa',     '101'),
('77788899900', 'Residencial', '40020010', 'Apto 302', '777'),
('88899900011', 'Residencial', '01310200', NULL,        '430'),
('99900011122', 'Residencial', '04547130', 'Apto 81',  '2000'),
('10011122233', 'Residencial', '05508010', NULL,        '300'),
('11122233355', 'Residencial', '01310100', 'Sala 5',   '1600'),
('22233344466', 'Residencial', '01001000', NULL,        '90'),
('33344455577', 'Residencial', '01310200', 'Apto 15',  '320'),
('44455566688', 'Residencial', '04547130', NULL,        '750'),
('55566677799', 'Residencial', '05508010', 'Bloco C',  '210');

INSERT IGNORE INTO tb_telefones (fk_cpf, ddd, numero, tipo) VALUES
('11122233344', '11', '991234567', 'Celular'),
('22233344455', '11', '987654321', 'Celular'),
('33344455566', '21', '993456789', 'Celular'),
('44455566677', '31', '994567890', 'Celular'),
('55566677788', '41', '995678901', 'Celular'),
('66677788899', '92', '996789012', 'Celular'),
('77788899900', '71', '997890123', 'Celular'),
('88899900011', '11', '998901234', 'Celular'),
('99900011122', '11', '992345678', 'Celular'),
('10011122233', '11', '981234567', 'Celular'),
('11122233355', '11', '983456789', 'Celular'),
('22233344466', '11', '984567890', 'Celular'),
('33344455577', '11', '985678901', 'Comercial'),
('44455566688', '11', '986789012', 'Comercial'),
('55566677799', '11', '987890123', 'Comercial');

INSERT IGNORE INTO tb_emails (fk_cpf, email, tipo) VALUES
('11122233344', 'lucas.oliveira@aluno.sisgesc.edu.br',   'Institucional'),
('22233344455', 'fernanda.santos@aluno.sisgesc.edu.br',  'Institucional'),
('33344455566', 'rafael.costa@aluno.sisgesc.edu.br',     'Institucional'),
('44455566677', 'juliana.pereira@aluno.sisgesc.edu.br',  'Institucional'),
('55566677788', 'bruno.almeida@aluno.sisgesc.edu.br',    'Institucional'),
('66677788899', 'carla.ferreira@aluno.sisgesc.edu.br',   'Institucional'),
('77788899900', 'diego.lima@aluno.sisgesc.edu.br',       'Institucional'),
('88899900011', 'amanda.souza@aluno.sisgesc.edu.br',     'Institucional'),
('99900011122', 'marcos.rodrigues@prof.sisgesc.edu.br',  'Institucional'),
('10011122233', 'patricia.mendes@prof.sisgesc.edu.br',   'Institucional'),
('11122233355', 'carlos.nascimento@prof.sisgesc.edu.br', 'Institucional'),
('22233344466', 'beatriz.cardoso@prof.sisgesc.edu.br',   'Institucional'),
('33344455577', 'roberto.teixeira@sisgesc.edu.br',       'Institucional'),
('44455566688', 'simone.barbosa@sisgesc.edu.br',         'Institucional'),
('55566677799', 'andre.gomes@sisgesc.edu.br',            'Institucional');

-- -----------------------------------------------------------------------
-- Módulo Acadêmico
-- -----------------------------------------------------------------------

INSERT IGNORE INTO tb_tipo_curso (pk_tipo_curso, descricao) VALUES
(1, 'Graduação'),
(2, 'Pós-Graduação'),
(3, 'Extensão');

INSERT IGNORE INTO tb_cursos (pk_curso, nome, fk_tipo_curso) VALUES
(1, 'Análise e Desenvolvimento de Sistemas', 1),
(2, 'Administração de Empresas',             1),
(3, 'Ciência da Computação',                 1),
(4, 'Gestão de Recursos Humanos',            2);

INSERT IGNORE INTO tb_status_aluno (pk_status_aluno, descricao) VALUES
(1, 'ativo'),
(2, 'trancado'),
(3, 'desistente'),
(4, 'formado');

INSERT IGNORE INTO tb_alunos (pk_fk_cpf, rgm, data_matricula_inicial, fk_status) VALUES
('11122233344', 100001, '2023-02-01', 1),
('22233344455', 100002, '2023-02-01', 1),
('33344455566', 100003, '2022-02-01', 1),
('44455566677', 100004, '2023-02-01', 1),
('55566677788', 100005, '2024-02-01', 1),
('66677788899', 100006, '2022-02-01', 4),
('77788899900', 100007, '2023-08-01', 2),
('88899900011', 100008, '2024-02-01', 1);

INSERT IGNORE INTO tb_aluno_curso (fk_cpf_aluno, fk_curso, data_inicio, data_fim) VALUES
('11122233344', 1, '2023-02-01', NULL),
('22233344455', 2, '2023-02-01', NULL),
('33344455566', 1, '2022-02-01', NULL),
('44455566677', 3, '2023-02-01', NULL),
('55566677788', 1, '2024-02-01', NULL),
('66677788899', 2, '2022-02-01', '2024-12-15'),
('77788899900', 3, '2023-08-01', NULL),
('88899900011', 4, '2024-02-01', NULL);

INSERT IGNORE INTO tb_historico_status_aluno (fk_cpf_aluno, fk_status, data_inicio, data_fim) VALUES
('11122233344', 1, '2023-02-01', NULL),
('22233344455', 1, '2023-02-01', NULL),
('33344455566', 1, '2022-02-01', NULL),
('44455566677', 1, '2023-02-01', NULL),
('55566677788', 1, '2024-02-01', NULL),
('66677788899', 1, '2022-02-01', '2024-12-01'),
('66677788899', 4, '2024-12-15', NULL),
('77788899900', 1, '2023-08-01', '2024-06-30'),
('77788899900', 2, '2024-07-01', NULL),
('88899900011', 1, '2024-02-01', NULL);

INSERT IGNORE INTO tb_disciplinas (pk_disciplina, nome, carga_horaria) VALUES
(1,  'Lógica de Programação',           80),
(2,  'Banco de Dados I',                80),
(3,  'Banco de Dados II',               60),
(4,  'Engenharia de Software',          80),
(5,  'Estrutura de Dados',              80),
(6,  'Sistemas Operacionais',           60),
(7,  'Gestão de Pessoas',               60),
(8,  'Marketing Digital',               60),
(9,  'Cálculo I',                       80),
(10, 'Álgebra Linear',                  80);

INSERT IGNORE INTO tb_grade_curricular (fk_curso, fk_disciplina, semestre_sugerido) VALUES
(1, 1, 1), (1, 2, 2), (1, 3, 3), (1, 4, 3), (1, 5, 2), (1, 6, 3),
(2, 7, 1), (2, 8, 2),
(3, 1, 1), (3, 9, 1), (3, 10, 2), (3, 5, 2), (3, 6, 3),
(4, 7, 1);

INSERT IGNORE INTO tb_pre_requisitos (fk_disciplina, fk_requisito) VALUES
(3, 2),  -- Banco de Dados II requer Banco de Dados I
(5, 1);  -- Estrutura de Dados requer Lógica de Programação

INSERT IGNORE INTO tb_periodos (pk_periodo, ano, semestre) VALUES
(1, 2022, 1),
(2, 2022, 2),
(3, 2023, 1),
(4, 2023, 2),
(5, 2024, 1),
(6, 2024, 2),
(7, 2025, 1);

INSERT IGNORE INTO tb_turmas (pk_turma, fk_curso, fk_periodo, codigo, turno) VALUES
(1, 1, 3, 'ADS2023A', 'Noite'),
(2, 2, 3, 'ADM2023A', 'Noite'),
(3, 3, 3, 'CC2023A',  'Manhã'),
(4, 1, 5, 'ADS2024A', 'Noite'),
(5, 4, 5, 'GRH2024A', 'Noite');

INSERT IGNORE INTO tb_salas (pk_sala, codigo, capacidade, tipo) VALUES
(1, 'B-101',  40, 'Sala de Aula'),
(2, 'B-102',  40, 'Sala de Aula'),
(3, 'B-201',  35, 'Sala de Aula'),
(4, 'LAB-01', 30, 'Laboratório'),
(5, 'LAB-02', 30, 'Laboratório');

INSERT IGNORE INTO tb_aulas (fk_turma, fk_disciplina, fk_cpf_professor, fk_sala, fk_periodo, dia_semana, horario_inicio, horario_fim) VALUES
(1, 1,  '99900011122', 4, 3, 2, '19:00:00', '21:00:00'),
(1, 2,  '99900011122', 4, 3, 4, '19:00:00', '21:00:00'),
(1, 4,  '10011122233', 1, 3, 3, '19:00:00', '21:00:00'),
(2, 7,  '22233344466', 2, 3, 2, '19:00:00', '21:00:00'),
(2, 8,  '22233344466', 2, 3, 4, '19:00:00', '21:00:00'),
(3, 1,  '11122233355', 3, 3, 2, '08:00:00', '10:00:00'),
(3, 10, '11122233355', 3, 3, 4, '08:00:00', '10:00:00'),
(4, 1,  '99900011122', 5, 5, 3, '19:00:00', '21:00:00'),
(4, 2,  '99900011122', 5, 5, 5, '19:00:00', '21:00:00'),
(5, 9,  '22233344466', 1, 5, 2, '19:00:00', '21:00:00');

INSERT IGNORE INTO tb_matriculas (pk_matricula, fk_cpf_aluno, fk_disciplina, fk_periodo, fk_turma) VALUES
(1,  '11122233344', 1,  3, 1),
(2,  '11122233344', 2,  3, 1),
(3,  '22233344455', 7,  3, 2),
(4,  '22233344455', 8,  3, 2),
(5,  '33344455566', 1,  1, 1),
(6,  '33344455566', 2,  2, 1),
(7,  '33344455566', 4,  3, 1),
(8,  '44455566677', 1,  3, 3),
(9,  '44455566677', 10, 3, 3),
(10, '55566677788', 1,  5, 4),
(11, '55566677788', 2,  5, 4),
(12, '88899900011', 9,  5, 5);

INSERT IGNORE INTO tb_resultado_matricula (fk_matricula, situacao, media_final, total_faltas, data_fechamento) VALUES
(5,  'aprovado',  8.50, 4,  '2023-07-10'),
(6,  'aprovado',  7.20, 6,  '2023-12-10'),
(7,  'reprovado', 4.80, 20, '2024-07-10'),
(3,  'aprovado',  9.00, 2,  '2024-07-10'),
(4,  'aprovado',  6.50, 8,  '2024-07-10'),
(1,  'cursando',  NULL, NULL, NULL),
(2,  'cursando',  NULL, NULL, NULL),
(8,  'cursando',  NULL, NULL, NULL),
(9,  'cursando',  NULL, NULL, NULL),
(10, 'cursando',  NULL, NULL, NULL),
(11, 'cursando',  NULL, NULL, NULL),
(12, 'cursando',  NULL, NULL, NULL);

INSERT IGNORE INTO tb_avaliacoes (pk_avaliacao, fk_disciplina, descricao, peso, data_limite_alteracao) VALUES
(1,  1,  'P1',       0.35, '2025-04-30'),
(2,  1,  'P2',       0.35, '2025-07-15'),
(3,  1,  'Trabalho', 0.30, '2025-06-30'),
(4,  2,  'P1',       0.40, '2025-04-30'),
(5,  2,  'P2',       0.40, '2025-07-15'),
(6,  2,  'Projeto',  0.20, '2025-06-30'),
(7,  7,  'P1',       0.50, '2025-04-30'),
(8,  7,  'P2',       0.50, '2025-07-15'),
(9,  9,  'P1',       0.40, '2025-04-30'),
(10, 9,  'Projeto',  0.60, '2025-06-30'),
(11, 10, 'P1',       0.50, '2025-04-30'),
(12, 10, 'P2',       0.50, '2025-07-15');

INSERT IGNORE INTO tb_notas (fk_matricula, fk_avaliacao, fk_cpf_professor, valor_nota) VALUES
(1,  1,  '99900011122', 7.50),
(2,  4,  '99900011122', 8.00),
(8,  1,  '11122233355', 6.50),
(9,  11, '11122233355', 9.00),
(10, 1,  '99900011122', 7.00),
(11, 4,  '99900011122', 8.50),
(12, 9,  '22233344466', 7.80);

INSERT IGNORE INTO tb_log_notas (fk_nota, valor_antigo, valor_novo, fk_cpf_professor, descricao) VALUES
(1, 6.50, 7.50, '99900011122', 'Correção de erro de digitação na P1 de Lógica de Programação');

INSERT IGNORE INTO tb_faltas (fk_matricula, data_falta, quantidade) VALUES
(1,  '2025-03-05', 1),
(1,  '2025-03-12', 1),
(2,  '2025-03-07', 1),
(8,  '2025-03-10', 2),
(10, '2025-03-04', 1),
(10, '2025-03-18', 1),
(12, '2025-03-06', 1);

-- -----------------------------------------------------------------------
-- Módulo RH
-- -----------------------------------------------------------------------

INSERT IGNORE INTO tb_departamentos (pk_departamento, nome, sigla) VALUES
(1, 'Tecnologia da Informação', 'TI'),
(2, 'Recursos Humanos',         'RH'),
(3, 'Acadêmico',                'ACAD'),
(4, 'Financeiro',               'FIN');

INSERT IGNORE INTO tb_cargos (pk_cargo, nome, nivel) VALUES
(1, 'Professor',              'Tático'),
(2, 'Coordenador Acadêmico',  'Tático'),
(3, 'Analista de RH',         'Operacional'),
(4, 'Analista Financeiro',    'Operacional'),
(5, 'Diretor Acadêmico',      'Estratégico');

INSERT IGNORE INTO tb_titulacoes (pk_titulacao, nome) VALUES
(1, 'Graduação'),
(2, 'Especialização'),
(3, 'Mestrado'),
(4, 'Doutorado');

INSERT IGNORE INTO tb_funcionarios (pk_fk_cpf, matricula_funcional, fk_departamento, data_admissao, data_demissao, salario_base) VALUES
('99900011122', 200001, 3, '2015-03-01', NULL, 8500.00),
('10011122233', 200002, 3, '2018-07-01', NULL, 7800.00),
('11122233355', 200003, 3, '2012-02-01', NULL, 9200.00),
('22233344466', 200004, 3, '2020-01-15', NULL, 7500.00),
('33344455577', 200005, 2, '2019-05-01', NULL, 5500.00),
('44455566688', 200006, 4, '2021-03-10', NULL, 5200.00),
('55566677799', 200007, 1, '2017-08-15', NULL, 6800.00);

INSERT IGNORE INTO tb_professores (pk_fk_cpf, area_atuacao, fk_titulacao) VALUES
('99900011122', 'Banco de Dados e Programação', 4),
('10011122233', 'Engenharia de Software',       3),
('11122233355', 'Computação Científica',        4),
('22233344466', 'Gestão e Marketing',           3);

INSERT IGNORE INTO tb_historico_cargos (fk_cpf_funcionario, fk_cargo, data_inicio, data_fim) VALUES
('99900011122', 1, '2015-03-01', NULL),
('10011122233', 1, '2018-07-01', NULL),
('11122233355', 1, '2012-02-01', NULL),
('22233344466', 1, '2020-01-15', NULL),
('33344455577', 3, '2019-05-01', NULL),
('44455566688', 4, '2021-03-10', NULL),
('55566677799', 3, '2017-08-15', NULL);

INSERT IGNORE INTO tb_beneficios (pk_beneficio, nome, descricao) VALUES
(1, 'Vale-Refeição',   'Benefício de alimentação — R$ 30,00/dia útil'),
(2, 'Vale-Transporte', 'Benefício de transporte conforme trajeto declarado'),
(3, 'Plano de Saúde',  'Cobertura médica e hospitalar — operadora SisSaúde');

INSERT IGNORE INTO tb_funcionario_beneficio (fk_cpf_funcionario, fk_beneficio, data_inicio, data_fim) VALUES
('99900011122', 1, '2015-03-01', NULL),
('99900011122', 3, '2015-03-01', NULL),
('10011122233', 1, '2018-07-01', NULL),
('10011122233', 2, '2018-07-01', NULL),
('33344455577', 1, '2019-05-01', NULL),
('33344455577', 2, '2019-05-01', NULL),
('33344455577', 3, '2019-05-01', NULL);

INSERT IGNORE INTO tb_verbas (pk_verba, nome, tipo) VALUES
(1, 'Salário Base',          'P'),
(2, 'Hora Extra',            'P'),
(3, 'INSS',                  'D'),
(4, 'IRRF',                  'D'),
(5, 'Vale-Transporte',       'D'),
(6, 'Plano de Saúde',        'D');

INSERT IGNORE INTO tb_folha_pagamento (pk_folha, fk_cpf_funcionario, mes, ano, salario_bruto, total_descontos, salario_liquido, data_pagamento, status) VALUES
(1, '99900011122', 3, 2025, 8500.00, 1870.00, 6630.00, '2025-03-05', 'pago'),
(2, '10011122233', 3, 2025, 7800.00, 1716.00, 6084.00, '2025-03-05', 'pago'),
(3, '33344455577', 3, 2025, 5500.00, 1210.00, 4290.00, '2025-03-05', 'pago');

INSERT IGNORE INTO tb_folha_verbas (fk_folha, fk_verba, valor) VALUES
(1, 1, 8500.00), (1, 3, 935.00),  (1, 4, 935.00),
(2, 1, 7800.00), (2, 3, 858.00),  (2, 4, 858.00),
(3, 1, 5500.00), (3, 3, 605.00),  (3, 4, 605.00);

INSERT IGNORE INTO tb_tipo_afastamento (pk_tipo, descricao) VALUES
(1, 'Licença Médica'),
(2, 'Licença Maternidade/Paternidade'),
(3, 'Afastamento por Acidente de Trabalho');

INSERT IGNORE INTO tb_ferias (pk_ferias, fk_cpf_funcionario, data_inicio, data_fim, data_retorno, tipo, status) VALUES
(1, '99900011122', '2025-01-06', '2025-01-31', '2025-02-03', 'integral',    'concluída'),
(2, '33344455577', '2025-07-07', '2025-07-21', NULL,         'fracionada',  'agendada');

-- -----------------------------------------------------------------------
-- Módulo Financeiro
-- -----------------------------------------------------------------------

INSERT IGNORE INTO tb_status_pagamento (pk_status_pagamento, descricao) VALUES
(1, 'Pendente'),
(2, 'Pago'),
(3, 'Atrasado'),
(4, 'Cancelado');

INSERT IGNORE INTO tb_contratos_educacionais (pk_contrato, fk_cpf_aluno, data_inicio, data_fim, valor_total_anual, is_ativo) VALUES
(1, '11122233344', '2023-02-01', '2025-12-31', 14400.00, TRUE),
(2, '22233344455', '2023-02-01', '2025-12-31', 13200.00, TRUE),
(3, '33344455566', '2022-02-01', '2025-12-31', 14400.00, TRUE),
(4, '44455566677', '2023-02-01', '2025-12-31', 15600.00, TRUE),
(5, '55566677788', '2024-02-01', '2026-12-31', 14400.00, TRUE),
(6, '66677788899', '2022-02-01', '2024-12-31', 13200.00, FALSE),
(7, '77788899900', '2023-08-01', '2025-07-31', 15600.00, TRUE),
(8, '88899900011', '2024-02-01', '2026-12-31', 12000.00, TRUE);

INSERT IGNORE INTO tb_descontos_bolsas (fk_contrato, tipo_bolsa, percentual_desconto, valor_fixo_desconto) VALUES
(3, 'Desempenho', 15.00, NULL),
(5, 'FIES',       50.00, NULL),
(6, 'ProUni',    100.00, NULL),
(8, 'Funcionário',20.00, NULL),
(1, 'Desempenho', NULL,  100.00);

INSERT IGNORE INTO tb_mensalidades (pk_mensalidade, fk_contrato, fk_status, data_vencimento, valor_liquido, valor_multa, valor_juros) VALUES
-- Contrato 1 — Lucas (desconto fixo R$100)
(1,  1, 2, '2025-01-10', 1100.00, 0.00,  0.00),
(2,  1, 2, '2025-02-10', 1100.00, 0.00,  0.00),
(3,  1, 2, '2025-03-10', 1100.00, 0.00,  0.00),
(4,  1, 1, '2025-04-10', 1100.00, 0.00,  0.00),
-- Contrato 2 — Fernanda (março em atraso)
(5,  2, 2, '2025-01-10', 1100.00, 0.00,  0.00),
(6,  2, 2, '2025-02-10', 1100.00, 0.00,  0.00),
(7,  2, 3, '2025-03-10', 1100.00, 55.00, 22.00),
(8,  2, 1, '2025-04-10', 1100.00, 0.00,  0.00),
-- Contrato 5 — Bruno (FIES 50%)
(9,  5, 2, '2025-01-10',  600.00, 0.00,  0.00),
(10, 5, 2, '2025-02-10',  600.00, 0.00,  0.00),
(11, 5, 2, '2025-03-10',  600.00, 0.00,  0.00),
(12, 5, 1, '2025-04-10',  600.00, 0.00,  0.00),
-- Contrato 8 — Amanda (Funcionário 20%)
(13, 8, 2, '2025-01-10',  800.00, 0.00,  0.00),
(14, 8, 2, '2025-02-10',  800.00, 0.00,  0.00),
(15, 8, 1, '2025-03-10',  800.00, 0.00,  0.00);

INSERT IGNORE INTO tb_pagamentos (fk_mensalidade, valor_pago, meio_pagamento) VALUES
(1,  1100.00, 'Pix'),
(2,  1100.00, 'Pix'),
(3,  1100.00, 'Boleto'),
(5,  1100.00, 'Cartão'),
(6,  1100.00, 'Pix'),
(9,   600.00, 'Pix'),
(10,  600.00, 'Boleto'),
(11,  600.00, 'Pix'),
(13,  800.00, 'Pix'),
(14,  800.00, 'Cartão');

-- -----------------------------------------------------------------------
-- Controle de versão — registro desta migração
-- -----------------------------------------------------------------------

INSERT IGNORE INTO tb_schema_version (versao, descricao, script, aplicado_por) VALUES
('6.0.0',
 'Fase 6 — Governança e Organização: padronização snake_case, comentários, reset, run_all e versionamento',
 'SisGESC_Fase6_Governanca.sql',
 'equipe_sisgesc');

-- =============================================================================
-- SEÇÃO IV — run_all
-- Ponto único de execução: ao rodar este arquivo completo, todas as seções
-- (reset → DDL → DML → versionamento) são aplicadas em sequência.
--
-- Para usar como script de referência run_all.sql, basta criar um arquivo
-- chamado run_all.sql com o conteúdo abaixo:
--
-- SOURCE SisGESC_Fase6_Governanca.sql;
--
-- Ou execute diretamente pela linha de comando:
--   mysql -u <usuario> -p < SisGESC_Fase6_Governanca.sql
--
-- Validação de idempotência — execute ANTES e DEPOIS de reexecutar:
-- Os contadores devem ser IGUAIS nas duas execuções.
-- =============================================================================

SELECT 'tb_pessoas'               AS tabela, COUNT(*) AS total FROM tb_pessoas
UNION ALL
SELECT 'tb_alunos',                           COUNT(*) FROM tb_alunos
UNION ALL
SELECT 'tb_funcionarios',                     COUNT(*) FROM tb_funcionarios
UNION ALL
SELECT 'tb_professores',                      COUNT(*) FROM tb_professores
UNION ALL
SELECT 'tb_matriculas',                       COUNT(*) FROM tb_matriculas
UNION ALL
SELECT 'tb_mensalidades',                     COUNT(*) FROM tb_mensalidades
UNION ALL
SELECT 'tb_pagamentos',                       COUNT(*) FROM tb_pagamentos
UNION ALL
SELECT 'tb_notas',                            COUNT(*) FROM tb_notas
UNION ALL
SELECT 'tb_folha_pagamento',                  COUNT(*) FROM tb_folha_pagamento
UNION ALL
SELECT 'tb_schema_version',                   COUNT(*) FROM tb_schema_version;
