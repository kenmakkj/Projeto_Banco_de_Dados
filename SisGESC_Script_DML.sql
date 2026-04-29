-- =============================================================================
-- SisGESC — Script DML (MySQL)
-- Sistema de Gestão Escolar — Universidade Privada
--
-- Módulos:
--   1. Base / Pessoas       — identidade, endereços, contatos
--   2. Módulo Acadêmico     — cursos, alunos, matrículas, notas, faltas
--   3. Módulo RH            — funcionários, folha, férias, afastamentos
--   4. Módulo Financeiro    — contratos, mensalidades, pagamentos, bolsas
--
-- IDEMPOTÊNCIA: Todos os INSERTs usam INSERT IGNORE.
-- Ao reexecutar o script, nenhum dado será duplicado.
-- Valide com: SELECT COUNT(*) FROM <tabela>; antes e depois.
-- =============================================================================

USE sisgesc;

-- =============================================================================
-- BASE / PESSOAS
-- =============================================================================

-- Tabela de domínio: CEPs
INSERT IGNORE INTO tb_cep (pk_cep, logradouro, bairro, cidade, estado) VALUES
('01310100', 'Avenida Paulista',        'Bela Vista',    'São Paulo',       'SP'),
('01001000', 'Praça da Sé',             'Sé',            'São Paulo',       'SP'),
('20040020', 'Avenida Rio Branco',      'Centro',        'Rio de Janeiro',  'RJ'),
('30112000', 'Rua dos Caetés',          'Centro',        'Belo Horizonte',  'MG'),
('80010010', 'Rua XV de Novembro',      'Centro',        'Curitiba',        'PR'),
('69005010', 'Avenida Getúlio Vargas',  'Centro',        'Manaus',          'AM'),
('40020010', 'Avenida Sete de Setembro','Centro',        'Salvador',        'BA'),
('01310200', 'Rua Augusta',             'Consolação',    'São Paulo',       'SP'),
('04547130', 'Avenida Brigadeiro Faria Lima', 'Itaim Bibi', 'São Paulo',   'SP'),
('05508010', 'Rua do Matão',            'Cidade Universitária', 'São Paulo','SP');

-- Pessoas (alunos, professores e funcionários)
INSERT IGNORE INTO tb_pessoas (pk_cpf, primeiro_nome, sobrenome, data_nascimento, genero, nacionalidade) VALUES
-- Alunos
('11122233344', 'Lucas',    'Oliveira',     '2001-03-15', 'M', 'brasileira'),
('22233344455', 'Fernanda', 'Santos',       '2000-07-22', 'F', 'brasileira'),
('33344455566', 'Rafael',   'Costa',        '2002-01-08', 'M', 'brasileira'),
('44455566677', 'Juliana',  'Pereira',      '2001-11-30', 'F', 'brasileira'),
('55566677788', 'Bruno',    'Almeida',      '2003-05-17', 'M', 'brasileira'),
('66677788899', 'Carla',    'Ferreira',     '2000-09-04', 'F', 'brasileira'),
('77788899900', 'Diego',    'Lima',         '2002-12-21', 'M', 'brasileira'),
('88899900011', 'Amanda',   'Souza',        '2001-06-10', 'F', 'brasileira'),
-- Professores/Funcionários
('99900011122', 'Marcos',   'Rodrigues',    '1978-04-25', 'M', 'brasileira'),
('10011122233', 'Patricia', 'Mendes',       '1982-08-14', 'F', 'brasileira'),
('11122233355', 'Carlos',   'Nascimento',   '1975-02-28', 'M', 'brasileira'),
('22233344466', 'Beatriz',  'Cardoso',      '1985-10-05', 'F', 'brasileira'),
-- Funcionários administrativos
('33344455577', 'Roberto',  'Teixeira',     '1980-06-18', 'M', 'brasileira'),
('44455566688', 'Simone',   'Barbosa',      '1990-03-09', 'F', 'brasileira'),
('55566677799', 'Andre',    'Gomes',        '1988-11-22', 'M', 'brasileira');

-- Endereços
INSERT IGNORE INTO tb_enderecos (fk_cpf, tipo_endereco, fk_cep, complemento, numero) VALUES
('11122233344', 'Residencial', '01310100', 'Apto 42',   '1500'),
('22233344455', 'Residencial', '01001000', NULL,        '200'),
('33344455566', 'Residencial', '20040020', 'Bloco B',   '350'),
('44455566677', 'Residencial', '30112000', 'Apto 10',   '820'),
('55566677788', 'Residencial', '80010010', NULL,        '55'),
('66677788899', 'Residencial', '69005010', 'Casa',      '101'),
('77788899900', 'Residencial', '40020010', 'Apto 302',  '777'),
('88899900011', 'Residencial', '01310200', NULL,        '430'),
('99900011122', 'Residencial', '04547130', 'Apto 81',   '2000'),
('10011122233', 'Residencial', '05508010', NULL,        '300'),
('11122233355', 'Residencial', '01310100', 'Sala 5',    '1600'),
('22233344466', 'Residencial', '01001000', NULL,        '90'),
('33344455577', 'Residencial', '01310200', 'Apto 15',   '320'),
('44455566688', 'Residencial', '04547130', NULL,        '750'),
('55566677799', 'Residencial', '05508010', 'Bloco C',   '210');

-- Telefones
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

-- E-mails
INSERT IGNORE INTO tb_emails (fk_cpf, email, tipo) VALUES
('11122233344', 'lucas.oliveira@aluno.sisgesc.edu.br',    'Institucional'),
('22233344455', 'fernanda.santos@aluno.sisgesc.edu.br',   'Institucional'),
('33344455566', 'rafael.costa@aluno.sisgesc.edu.br',      'Institucional'),
('44455566677', 'juliana.pereira@aluno.sisgesc.edu.br',   'Institucional'),
('55566677788', 'bruno.almeida@aluno.sisgesc.edu.br',     'Institucional'),
('66677788899', 'carla.ferreira@aluno.sisgesc.edu.br',    'Institucional'),
('77788899900', 'diego.lima@aluno.sisgesc.edu.br',        'Institucional'),
('88899900011', 'amanda.souza@aluno.sisgesc.edu.br',      'Institucional'),
('99900011122', 'marcos.rodrigues@prof.sisgesc.edu.br',   'Institucional'),
('10011122233', 'patricia.mendes@prof.sisgesc.edu.br',    'Institucional'),
('11122233355', 'carlos.nascimento@prof.sisgesc.edu.br',  'Institucional'),
('22233344466', 'beatriz.cardoso@prof.sisgesc.edu.br',    'Institucional'),
('33344455577', 'roberto.teixeira@sisgesc.edu.br',        'Institucional'),
('44455566688', 'simone.barbosa@sisgesc.edu.br',          'Institucional'),
('55566677799', 'andre.gomes@sisgesc.edu.br',             'Institucional');

-- =============================================================================
-- MÓDULO ACADÊMICO
-- =============================================================================

-- Tipos de curso
INSERT IGNORE INTO tb_tipo_curso (pk_tipo_curso, descricao) VALUES
(1, 'Graduação'),
(2, 'Pós-Graduação'),
(3, 'Extensão');

-- Cursos
INSERT IGNORE INTO tb_cursos (pk_curso, nome, fk_tipo_curso) VALUES
(1, 'Análise e Desenvolvimento de Sistemas', 1),
(2, 'Administração de Empresas',             1),
(3, 'Ciência da Computação',                 1),
(4, 'Gestão de Recursos Humanos',            2);

-- Status do aluno
INSERT IGNORE INTO tb_status_aluno (pk_status_aluno, descricao) VALUES
(1, 'ativo'),
(2, 'trancado'),
(3, 'desistente'),
(4, 'formado');

-- Alunos
INSERT IGNORE INTO tb_alunos (pk_fk_cpf, rgm, data_matricula_inicial, fk_status) VALUES
('11122233344', 100001, '2023-02-01', 1),
('22233344455', 100002, '2023-02-01', 1),
('33344455566', 100003, '2022-02-01', 1),
('44455566677', 100004, '2023-02-01', 1),
('55566677788', 100005, '2024-02-01', 1),
('66677788899', 100006, '2022-02-01', 4),
('77788899900', 100007, '2023-08-01', 2),
('88899900011', 100008, '2024-02-01', 1);

-- Vínculo aluno x curso
INSERT IGNORE INTO tb_aluno_curso (fk_cpf_aluno, fk_curso, data_inicio, data_fim) VALUES
('11122233344', 1, '2023-02-01', NULL),
('22233344455', 2, '2023-02-01', NULL),
('33344455566', 1, '2022-02-01', NULL),
('44455566677', 3, '2023-02-01', NULL),
('55566677788', 1, '2024-02-01', NULL),
('66677788899', 2, '2022-02-01', '2024-12-15'),
('77788899900', 3, '2023-08-01', NULL),
('88899900011', 4, '2024-02-01', NULL);

-- Histórico de status dos alunos
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

-- Disciplinas
INSERT IGNORE INTO tb_disciplinas (pk_disciplina, nome, carga_horaria) VALUES
(1,  'Lógica de Programação',          80),
(2,  'Banco de Dados I',               80),
(3,  'Banco de Dados II',              60),
(4,  'Engenharia de Software',         80),
(5,  'Estrutura de Dados',             80),
(6,  'Redes de Computadores',          60),
(7,  'Administração Geral',            80),
(8,  'Contabilidade Básica',           60),
(9,  'Gestão de Pessoas',              60),
(10, 'Cálculo I',                      80),
(11, 'Algoritmos e Programação',       80),
(12, 'Sistemas Operacionais',          60);

-- Pré-requisitos
INSERT IGNORE INTO tb_pre_requisitos (fk_disciplina, fk_requisito) VALUES
(3,  2),   -- Banco de Dados II requer Banco de Dados I
(5,  1),   -- Estrutura de Dados requer Lógica de Programação
(11, 1);   -- Algoritmos e Programação requer Lógica de Programação

-- Grade curricular
INSERT IGNORE INTO tb_grade_curricular (fk_curso, fk_disciplina, semestre_sugerido) VALUES
-- ADS
(1, 1,  1), (1, 2,  2), (1, 3,  3), (1, 4,  4), (1, 5,  2), (1, 6,  3),
-- Administração
(2, 7,  1), (2, 8,  1), (2, 9,  2),
-- Ciência da Computação
(3, 1,  1), (3, 10, 1), (3, 11, 2), (3, 12, 3),
-- Gestão de RH
(4, 7,  1), (4, 9,  1);

-- Períodos letivos
INSERT IGNORE INTO tb_periodos (pk_periodo, ano, semestre) VALUES
(1, 2023, 1),
(2, 2023, 2),
(3, 2024, 1),
(4, 2024, 2),
(5, 2025, 1);

-- Salas
INSERT IGNORE INTO tb_salas (pk_sala, nome, capacidade, tipo) VALUES
(1, 'A101', 40, 'Sala de Aula'),
(2, 'A102', 40, 'Sala de Aula'),
(3, 'A103', 40, 'Sala de Aula'),
(4, 'Lab-01', 30, 'Laboratório'),
(5, 'Lab-02', 30, 'Laboratório'),
(6, 'Aud-01', 100, 'Auditório');

-- Turmas
INSERT IGNORE INTO tb_turmas (pk_turma, fk_curso, nome_turma, periodo, ano_ingresso) VALUES
(1, 1, 'ADS-2023-N',  'Noturno',     2023),
(2, 2, 'ADM-2023-N',  'Noturno',     2023),
(3, 3, 'CC-2023-M',   'Matutino',    2023),
(4, 1, 'ADS-2024-N',  'Noturno',     2024),
(5, 4, 'GRH-2024-N',  'Noturno',     2024);

-- =============================================================================
-- MÓDULO RH
-- =============================================================================

-- Departamentos
INSERT IGNORE INTO tb_departamentos (pk_departamento, nome) VALUES
(1, 'Acadêmico'),
(2, 'Financeiro'),
(3, 'Recursos Humanos'),
(4, 'Tecnologia da Informação');

-- Cargos
INSERT IGNORE INTO tb_cargos (pk_cargo, nome) VALUES
(1, 'Professor'),
(2, 'Coordenador de Curso'),
(3, 'Assistente Administrativo'),
(4, 'Analista Financeiro'),
(5, 'Analista de RH');

-- Titulações
INSERT IGNORE INTO tb_titulacoes (pk_titulacao, nome) VALUES
(1, 'Especialista'),
(2, 'Mestre'),
(3, 'Doutor');

-- Funcionários (professores e administrativos)
INSERT IGNORE INTO tb_funcionarios (pk_fk_cpf, matricula_funcional, fk_departamento, data_admissao, salario_base) VALUES
('99900011122', 200001, 1, '2015-03-01', 6500.00),
('10011122233', 200002, 1, '2018-07-01', 5800.00),
('11122233355', 200003, 1, '2010-02-01', 8200.00),
('22233344466', 200004, 1, '2020-08-01', 5500.00),
('33344455577', 200005, 3, '2019-01-15', 3800.00),
('44455566688', 200006, 2, '2021-05-10', 4200.00),
('55566677799', 200007, 4, '2017-09-01', 5000.00);

-- Histórico de cargos
INSERT IGNORE INTO tb_historico_cargos (fk_cpf_funcionario, fk_cargo, data_inicio, data_fim) VALUES
('99900011122', 1, '2015-03-01', NULL),
('10011122233', 1, '2018-07-01', NULL),
('11122233355', 1, '2010-02-01', '2022-12-31'),
('11122233355', 2, '2023-01-01', NULL),
('22233344466', 1, '2020-08-01', NULL),
('33344455577', 3, '2019-01-15', NULL),
('44455566688', 4, '2021-05-10', NULL),
('55566677799', 3, '2017-09-01', '2022-06-30'),
('55566677799', 5, '2022-07-01', NULL);

-- Professores
INSERT IGNORE INTO tb_professores (pk_fk_cpf, area_atuacao, fk_titulacao) VALUES
('99900011122', 'Banco de Dados',          3),
('10011122233', 'Engenharia de Software',  2),
('11122233355', 'Ciência da Computação',   3),
('22233344466', 'Administração',           1);

-- Benefícios
INSERT IGNORE INTO tb_beneficios (pk_beneficio, nome, descricao) VALUES
(1, 'Plano de Saúde',    'Cobertura médica e hospitalar'),
(2, 'Vale Refeição',     'Cartão alimentação R$600/mês'),
(3, 'Vale Transporte',   'Crédito transporte conforme deslocamento'),
(4, 'Plano Odontológico','Cobertura odontológica básica');

-- Vínculo funcionário x benefício
INSERT IGNORE INTO tb_funcionario_beneficio (fk_cpf_funcionario, fk_beneficio, data_inicio, data_fim) VALUES
('99900011122', 1, '2015-03-01', NULL),
('99900011122', 2, '2015-03-01', NULL),
('99900011122', 3, '2015-03-01', NULL),
('10011122233', 1, '2018-07-01', NULL),
('10011122233', 2, '2018-07-01', NULL),
('11122233355', 1, '2010-02-01', NULL),
('11122233355', 2, '2010-02-01', NULL),
('11122233355', 4, '2010-02-01', NULL),
('22233344466', 1, '2020-08-01', NULL),
('22233344466', 2, '2020-08-01', NULL),
('33344455577', 2, '2019-01-15', NULL),
('33344455577', 3, '2019-01-15', NULL),
('44455566688', 1, '2021-05-10', NULL),
('44455566688', 2, '2021-05-10', NULL),
('55566677799', 2, '2017-09-01', NULL),
('55566677799', 3, '2017-09-01', NULL);

-- Verbas de folha
INSERT IGNORE INTO tb_verbas (pk_verba, nome, tipo) VALUES
(1, 'Salário Base',      'P'),
(2, 'Hora Extra',        'P'),
(3, 'Adicional Noturno', 'P'),
(4, 'INSS',              'D'),
(5, 'IRRF',              'D'),
(6, 'Vale Transporte',   'D');

-- Folha de pagamento (março/2025)
INSERT IGNORE INTO tb_folha_pagamento (fk_cpf_funcionario, mes, ano, salario_bruto, total_descontos, salario_liquido, data_pagamento, status) VALUES
('99900011122', 3, 2025, 6500.00,  975.00, 5525.00, '2025-03-05', 'pago'),
('10011122233', 3, 2025, 5800.00,  870.00, 4930.00, '2025-03-05', 'pago'),
('11122233355', 3, 2025, 8200.00, 1230.00, 6970.00, '2025-03-05', 'pago'),
('22233344466', 3, 2025, 5500.00,  825.00, 4675.00, '2025-03-05', 'pago'),
('33344455577', 3, 2025, 3800.00,  570.00, 3230.00, '2025-03-05', 'pago'),
('44455566688', 3, 2025, 4200.00,  630.00, 3570.00, '2025-03-05', 'pago'),
('55566677799', 3, 2025, 5000.00,  750.00, 4250.00, '2025-03-05', 'pago');

-- Detalhamento das verbas por folha
INSERT IGNORE INTO tb_folha_verbas (fk_folha, fk_verba, valor) VALUES
(1, 1, 6500.00), (1, 4, 715.00),  (1, 5, 260.00),
(2, 1, 5800.00), (2, 4, 638.00),  (2, 5, 232.00),
(3, 1, 8200.00), (3, 4, 902.00),  (3, 5, 328.00),
(4, 1, 5500.00), (4, 4, 605.00),  (4, 5, 220.00),
(5, 1, 3800.00), (5, 4, 418.00),  (5, 5, 152.00),
(6, 1, 4200.00), (6, 4, 462.00),  (6, 5, 168.00),
(7, 1, 5000.00), (7, 4, 550.00),  (7, 5, 200.00);

-- Férias
INSERT IGNORE INTO tb_ferias (fk_cpf_funcionario, data_inicio, data_fim, data_retorno, tipo, status) VALUES
('99900011122', '2025-01-06', '2025-01-25', '2025-01-27', 'integral',   'concluída'),
('10011122233', '2025-07-07', '2025-07-26', NULL,          'integral',   'agendada'),
('11122233355', '2024-12-16', '2025-01-04', '2025-01-06', 'fracionada', 'concluída');

-- Tipos de afastamento
INSERT IGNORE INTO tb_tipo_afastamento (pk_tipo, descricao) VALUES
(1, 'Licença Médica'),
(2, 'Licença Maternidade'),
(3, 'Licença Paternidade'),
(4, 'Acidente de Trabalho');

-- Afastamentos
INSERT IGNORE INTO tb_afastamentos (fk_cpf_funcionario, fk_tipo, data_inicio, data_fim, observacao) VALUES
('22233344466', 1, '2024-09-10', '2024-09-20', 'Cirurgia eletiva — atestado médico anexado'),
('33344455577', 3, '2025-02-17', '2025-02-22', 'Licença paternidade legal de 5 dias');

-- =============================================================================
-- MÓDULO ACADÊMICO — continuação (depende de professores e turmas)
-- =============================================================================

-- Aulas (grade de horários)
INSERT IGNORE INTO tb_aulas (fk_turma, fk_disciplina, fk_cpf_professor, fk_sala, fk_periodo, dia_semana, horario_inicio, horario_fim) VALUES
(1, 1, '99900011122', 4, 3, 2, '19:00:00', '21:00:00'),
(1, 2, '99900011122', 4, 3, 4, '19:00:00', '21:00:00'),
(1, 4, '10011122233', 1, 3, 3, '19:00:00', '21:00:00'),
(2, 7, '22233344466', 2, 3, 2, '19:00:00', '21:00:00'),
(2, 8, '22233344466', 2, 3, 4, '19:00:00', '21:00:00'),
(3, 1, '11122233355', 3, 3, 2, '08:00:00', '10:00:00'),
(3, 10,'11122233355', 3, 3, 4, '08:00:00', '10:00:00'),
(4, 1, '99900011122', 5, 5, 3, '19:00:00', '21:00:00'),
(4, 2, '99900011122', 5, 5, 5, '19:00:00', '21:00:00'),
(5, 9, '22233344466', 1, 5, 2, '19:00:00', '21:00:00');

-- Matrículas
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

-- Resultados das matrículas (períodos encerrados)
INSERT IGNORE INTO tb_resultado_matricula (fk_matricula, situacao, media_final, total_faltas, data_fechamento) VALUES
(5, 'aprovado',  8.50, 4,  '2023-07-10'),
(6, 'aprovado',  7.20, 6,  '2023-12-10'),
(7, 'reprovado', 4.80, 20, '2024-07-10'),
(3, 'aprovado',  9.00, 2,  '2024-07-10'),
(4, 'aprovado',  6.50, 8,  '2024-07-10'),
-- Matrículas em andamento
(1,  'cursando', NULL, NULL, NULL),
(2,  'cursando', NULL, NULL, NULL),
(8,  'cursando', NULL, NULL, NULL),
(9,  'cursando', NULL, NULL, NULL),
(10, 'cursando', NULL, NULL, NULL),
(11, 'cursando', NULL, NULL, NULL),
(12, 'cursando', NULL, NULL, NULL);

-- Avaliações por disciplina
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

-- Notas lançadas (matrículas em andamento — período 2025/1)
INSERT IGNORE INTO tb_notas (fk_matricula, fk_avaliacao, fk_cpf_professor, valor_nota) VALUES
(1,  1,  '99900011122', 7.50),
(2,  4,  '99900011122', 8.00),
(8,  1,  '11122233355', 6.50),
(9,  11, '11122233355', 9.00),
(10, 1,  '99900011122', 7.00),
(11, 4,  '99900011122', 8.50),
(12, 9,  '22233344466', 7.80);

-- Log de alteração de nota (auditoria)
INSERT IGNORE INTO tb_log_notas (fk_nota, valor_antigo, valor_novo, fk_cpf_professor, descricao) VALUES
(1, 6.50, 7.50, '99900011122', 'Correção de erro de digitação na P1 de Lógica de Programação');

-- Faltas registradas
INSERT IGNORE INTO tb_faltas (fk_matricula, data_falta, quantidade) VALUES
(1,  '2025-03-05', 1),
(1,  '2025-03-12', 1),
(2,  '2025-03-07', 1),
(8,  '2025-03-10', 2),
(10, '2025-03-04', 1),
(10, '2025-03-18', 1),
(12, '2025-03-06', 1);

-- =============================================================================
-- MÓDULO FINANCEIRO
-- =============================================================================

-- Status de pagamento
INSERT IGNORE INTO tb_status_pagamento (pk_status_pagamento, descricao) VALUES
(1, 'Pendente'),
(2, 'Pago'),
(3, 'Atrasado'),
(4, 'Cancelado');

-- Contratos educacionais
INSERT IGNORE INTO tb_contratos_educacionais (pk_contrato, fk_cpf_aluno, data_inicio, data_fim, valor_total_anual, is_ativo) VALUES
(1, '11122233344', '2023-02-01', '2025-12-31', 14400.00, TRUE),
(2, '22233344455', '2023-02-01', '2025-12-31', 13200.00, TRUE),
(3, '33344455566', '2022-02-01', '2025-12-31', 14400.00, TRUE),
(4, '44455566677', '2023-02-01', '2025-12-31', 15600.00, TRUE),
(5, '55566677788', '2024-02-01', '2026-12-31', 14400.00, TRUE),
(6, '66677788899', '2022-02-01', '2024-12-31', 13200.00, FALSE),
(7, '77788899900', '2023-08-01', '2025-07-31', 15600.00, TRUE),
(8, '88899900011', '2024-02-01', '2026-12-31', 12000.00, TRUE);

-- Descontos e bolsas
INSERT IGNORE INTO tb_descontos_bolsas (fk_contrato, tipo_bolsa, percentual_desconto, valor_fixo_desconto) VALUES
(3, 'Desempenho',    15.00, NULL),
(5, 'FIES',          50.00, NULL),
(6, 'ProUni',       100.00, NULL),
(8, 'Funcionário',   20.00, NULL),
(1, 'Desempenho',   NULL,  100.00);

-- Mensalidades (contratos 1, 2 e 5 — 2025)
INSERT IGNORE INTO tb_mensalidades (pk_mensalidade, fk_contrato, fk_status, data_vencimento, valor_liquido, valor_multa, valor_juros) VALUES
-- Contrato 1 — Lucas (sem bolsa / desconto fixo de R$100)
(1,  1, 2, '2025-01-10', 1100.00, 0.00,  0.00),
(2,  1, 2, '2025-02-10', 1100.00, 0.00,  0.00),
(3,  1, 2, '2025-03-10', 1100.00, 0.00,  0.00),
(4,  1, 1, '2025-04-10', 1100.00, 0.00,  0.00),
-- Contrato 2 — Fernanda
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

-- Pagamentos realizados
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

-- =============================================================================
-- VALIDAÇÃO DE IDEMPOTÊNCIA
-- Execute os SELECTs abaixo ANTES e DEPOIS de reexecutar o script.
-- Os valores devem ser IGUAIS nas duas execuções.
-- =============================================================================
/*
SELECT 'tb_pessoas'                AS tabela, COUNT(*) AS total FROM tb_pessoas
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
SELECT 'tb_folha_pagamento',                  COUNT(*) FROM tb_folha_pagamento;
*/
