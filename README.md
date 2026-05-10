# SisGESC — Sistema de Gestão Escolar

Projeto acadêmico (MySQL 8+): OLTP (`sisgesc`) com módulos Acadêmico, Financeiro e RH, mais camada OLAP (`dw_sisgesc`) com Star Schema e ETL.

## Pré-requisitos

- MySQL **8.0+** (uso de `CREATE INDEX IF NOT EXISTS`, procedures, `CHECK`).
- Cliente: `mysql` na linha de comando, MySQL Workbench ou DBeaver.

## Estrutura do repositório (ficheiros SQL principais)

| Ficheiro | Função |
|----------|--------|
| `run_all.sql` | Orquestração: reset → DDL → DML → OLTP → OLAP (ETL) → governança/EXPLAIN → validação somas |
| `SisGESC_Script_DDL_otimizado.sql` | Fase 1 — DDL OLTP + views + índices base |
| `SisGESC_Script_DML.sql` | Fase 2 — carga idempotente (`INSERT IGNORE`) + `COUNT(*)` antes/depois |
| `SisGESC_Script_OLTP_Procedures.sql` | Fase 3 — procedures alinhadas ao schema + consultas com subselects |
| `SisGESC_Data_Warehouse_OLAP_corrigido.sql` | Fase 4 — DW, dimensões (incl. **Unidade**), fatos, ETL |
| `SisGESC_Script_Governanca.sql` | Fases 5–6 — EXPLAIN + índices + `tb_schema_version` (**não** apaga dados) |
| `SisGESC_Script_DDL.sql` | DDL alternativo / referência — **não** faz parte do `run_all.sql` |

Documentação em PDF: `Dicionario_Sisgesc.pdf`, `Diagrama Final .pdf`, `SisGESC_Regras_Negocio.pdf`, `SisGESC_Imagens.pdf`. Link externo ao DER: `Link_DbDiagram`.

## Como executar (instalação única)

Na pasta do projeto:

```bash
mysql -u root -p < run_all.sql
```

O `run_all.sql` usa `SOURCE` para encadear os outros `.sql` — **têm de estar no mesmo diretório** de onde invoca o cliente, ou execute os passos manualmente na ordem do ficheiro.

Após a carga OLAP, o script chama `CALL sp_etl_carga_completa_dw();` automaticamente.

## Idempotência (Fase 2)

O `SisGESC_Script_DML.sql` faz contagem inicial, `INSERT IGNORE` na carga e contagem final. Executar o DML duas vezes em sequência deve manter os mesmos `COUNT(*)` nas tabelas listadas (incluindo `tb_areas_atuacao`, `tb_professor_area`, `tb_contrato_desconto`).

## Validação OLTP × OLAP (receita)

Comparar:

```sql
SELECT SUM(valor_liquido) FROM sisgesc.tb_mensalidades;
SELECT SUM(valor_mensalidade_liquido) FROM dw_sisgesc.fato_receita;
```

Os totais devem coincidir após o ETL.

## Star Schema — dimensões principais

- `dim_tempo`, `dim_aluno`, `dim_curso`, **`dim_unidade`**, `dim_professor`, `dim_disciplina`
- Fatos: `fato_receita`, `fato_desempenho`, `fato_folha_pagamento`

---

*SisGESC — entrega académica de Banco de Dados.*
