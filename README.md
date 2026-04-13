# Introdução: Sistema de Gestão Escolar (SisGESC)
O presente trabalho tem como objetivo apresentar o desenvolvimento do sistema SisGESC, concebido a partir da aplicação de conceitos fundamentais de modelagem de dados, organização de sistemas e boas práticas de desenvolvimento.
Este projeto foi elaborado como parte das atividades acadêmicas propostas ao longo do curso, buscando integrar teoria e prática na construção de uma solução estruturada e eficiente.
Todo o desenvolvimento contou com supervisão docente, cuja orientação foi essencial para a validação das decisões técnicas, garantindo a consistência, organização e qualidade do sistema apresentado.
No cenário educacional atual, é necessário que as instituições de ensino superior possuam um sistema com precisão pedagógica e níveis elevados de eficiência na busca de dados. O SisGESC é uma solução desenvolvida para universidades privadas que ainda não dispõem desses recursos, projetado sobre os três pilares centrais de qualquer universidade: Módulo Acadêmico, Módulo Financeiro e Módulo de Recursos Humanos (RH).

O sistema adota uma política de integridade referencial híbrida. Aplica-se o modelo Restrito (RESTRICT) em entidades nucleares dos módulos Financeiro e RH, garantindo a consistência de dados históricos exigida pelas camadas de BI e IA. Já o modelo em cascata (CASCADE) é utilizado em tabelas operacionais dependentes, otimizando a manutenção do banco e eliminando registros órfãos automaticamente. Essas políticas são declaradas explicitamente nas cláusulas ON DELETE das chaves estrangeiras no script SQL de criação.

Diferente de sistemas de gestão mais simples, o SisGESC foi arquitetado na Terceira Forma Normal (3FN), garantindo que não haja redundâncias nem dependências transitivas entre atributos, preservando a integridade referencial de matrículas, carga horária docente e controle financeiro. O sistema não apenas armazena informações — organiza-as estrategicamente para suportar camadas de Business Intelligence (BI) e Inteligência Artificial (IA).
Através do uso de rastreabilidade temporal (vigências de contrato e histórico de status) e entidades associativas, o sistema permite tanto a consulta de registros históricos quanto a previsão de situações de risco, como evasão escolar e inadimplência. O documento a seguir apresenta o diagrama DER, o dicionário de dados e as regras de negócio que sustentam essa inteligência educacional.

# BI — Business Intelligence
O SisGESC utiliza as estruturas de rastreabilidade temporal (vigências via data_inicio e data_fim) e os diversos campos de status distribuídos pelo schema para transformar dados brutos em indicadores e percentuais apresentados à gestão da instituição.
Dashboards financeiros
Dashboards automáticos cruzam dados de tb_pagamentos com tb_mensalidades e tb_contratos_educacionais por curso e período letivo, permitindo visualizar a receita real por turma e identificar gaps entre o valor contratado e o efetivamente recebido. Os campos valor_multa e valor_juros em tb_mensalidades permitem mensurar o impacto financeiro da inadimplência de forma granular.

Monitoramento de inadimplência
O sistema monitora a inadimplência através do campo fk_status em tb_mensalidades (Pendente, Pago, Atrasado, Cancelado), cruzado com tb_contratos_educacionais.is_ativo. Isso permite identificar o nível de criticidade de cada aluno e acionar intervenções preventivas antes que a situação comprometa a renovação de matrícula — conforme definido nas regras de negócio RN02 e RN15.
Relatórios acadêmicos
Relatórios de médias e faltas são gerados em tempo real a partir de tb_notas, tb_avaliacoes e tb_faltas, permitindo identificar padrões de aprovação e reprovação por disciplina, turma e período letivo. O campo media_final em tb_resultado_matricula consolida esses dados para consultas rápidas sem necessidade de recálculo.

# IA — Inteligência Artificial
A camada de IA utiliza os dados históricos e a integridade referencial do schema para realizar análises preventivas em duas frentes principais:
Previsão de evasão escolar.

Algoritmos analisam padrões em tb_faltas (frequência e quantidade de faltas ao longo do tempo) cruzados com atrasos em tb_mensalidades (fk_status = 'Atrasado'). Caso um aluno apresente comportamento de risco simultâneo nos dois indicadores — alta frequência de faltas e inadimplência recorrente — o sistema alerta a instituição para uma intervenção preventiva, auxiliando o aluno antes que a situação evolua para desistência ou jubilamento.
Otimização de alocação docente
A IA analisa a distribuição de aulas em tb_aulas (campos horario_inicio, horario_fim e dia_semana por fk_cpf_professor) para identificar padrões de sobrecarga que podem impactar a qualidade do ensino ou levar ao desligamento de professores. Com base nesses padrões, o sistema sugere ajustes estratégicos na alocação de disciplinas, equilibrando a carga entre os docentes disponíveis e reduzindo o risco de turnover.
