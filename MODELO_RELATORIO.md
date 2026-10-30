# Relatório de Tuning de Banco de Dados PostgreSQL

## Capa
Instituição:
Disciplina:
Professor:
Integrantes:
Data:

## 1. Introdução
Apresentar o contexto do problema e a importância do tuning de banco de dados.

## 2. Objetivos
### 2.1 Objetivo geral
Analisar e otimizar consultas em uma base PostgreSQL de vendas e estoque.
### 2.2 Objetivos específicos
Descrever os objetivos específicos e as hipóteses avaliadas.

## 3. Caracterização do ambiente
- PostgreSQL / versão:
- Sistema operacional:
- CPU:
- Memória RAM:
- Armazenamento:
- Configurações relevantes:
- Modelo relacional:
- Quantidade de registros por tabela:

Inserir o diagrama e as contagens reais.

## 4. Carga de trabalho e linha de base
Descrever as três consultas, parâmetros, frequência simulada e método de medição.
Apresentar os planos EXPLAIN ANALYZE originais.

## 5. Diagnóstico
Para cada consulta, explicar:
- plano escolhido;
- scans e joins;
- linhas estimadas versus linhas reais;
- buffers lidos e encontrados em cache;
- tempo de planejamento e execução;
- gargalo observado e evidência.

## 6. Ações de tuning
Para cada índice ou alteração:
- problema que motivou a ação;
- script aplicado;
- justificativa técnica;
- efeito observado;
- custo potencial em armazenamento e escrita.

## 7. Resultados
Preencher com valores medidos, usando medianas de pelo menos cinco execuções.

| Consulta | Mediana antes (ms) | Mediana depois (ms) | Redução (%) |
|---|---:|---:|---:|
| A - Pedidos por período | | | |
| B - Histórico do cliente | | | |
| C - Vendas por categoria | | | |

Fórmula: ((antes - depois) / antes) * 100.

Inserir gráficos e planos posteriores.

## 8. Discussão
Explicar quais índices foram efetivos, quais não foram utilizados, limitações, impacto no tamanho do banco e possíveis efeitos em operações de escrita.

## 9. Conclusão
Retomar os objetivos e apresentar somente ganhos comprovados pelas medições.

## 10. Referências
Documentação oficial do PostgreSQL:
https://www.postgresql.org/docs/

## Apêndices
Anexar todos os scripts SQL, saídas EXPLAIN ANALYZE e evidências das medições.
