# Projeto acadêmico: Database Performance Tuning com PostgreSQL

## Escopo
Banco sintético de vendas e estoque. A tabela `itens_pedido` contém exatamente 1.000.000 de linhas; o volume total é maior, pois existem tabelas auxiliares.

## Requisitos
- PostgreSQL 14 ou superior (recomendado PostgreSQL 16/17).
- pgAdmin ou `psql`.
- Espaço livre em disco suficiente para dados, índices e arquivos de saída.
- Registrar CPU, RAM, versão do PostgreSQL, sistema operacional e armazenamento.

## Execução
1. Crie o banco: `CREATE DATABASE tuning_vendas;`
2. Conecte-se ao banco `tuning_vendas`.
3. Execute `00_criar_banco.sql`.
4. Execute `01_popular_dados.sql`.
5. Confirme as contagens retornadas.
6. Execute `03_medicao_antes.sql` e salve os planos e tempos.
7. Execute `04_aplicar_tuning.sql`.
8. Execute `05_medicao_depois.sql` nas mesmas condições.
9. Execute `06_validacao_e_manutencao.sql`.

Com psql, por exemplo:
`psql -U postgres -d tuning_vendas -f 00_criar_banco.sql`

No Windows, use o caminho completo dos arquivos se necessário.

## Regras de medição
- Faça uma execução de aquecimento antes das medições válidas.
- Faça pelo menos cinco execuções por consulta antes e depois.
- Compare a mediana, não apenas a melhor execução.
- Mantenha os mesmos parâmetros, hardware, versão, configuração e concorrência.
- Não limpe caches entre as medições de um único grupo.
- Registre `Execution Time`, `Planning Time`, `Buffers`, `Seq Scan`, `Index Scan` e `Bitmap Heap Scan`.
- `EXPLAIN ANALYZE` executa de fato a consulta.
- O plano pode escolher `Seq Scan` mesmo com índice disponível; isso não significa necessariamente erro.

## Hipóteses a investigar
- Índice composto em `pedidos(data_pedido, status)` pode reduzir o custo da consulta A.
- Índice em `pedidos(cliente_id, data_pedido DESC)` pode ajudar a consulta B.
- Índice em `itens_pedido(pedido_id)` pode reduzir o custo da junção da consulta B.
- Índice em `produtos(categoria)` pode ou não ajudar a consulta C; como a consulta percorre grande parte dos dados, um scan sequencial pode continuar sendo a melhor escolha.

Não declare melhoria antes de medir. Se o índice não for utilizado ou não melhorar a mediana, registre o resultado e discuta a seletividade e o custo de manutenção.

## Fórmulas
Redução do tempo (%):
`((mediana_antes - mediana_depois) / mediana_antes) * 100`

Aceleração (vezes):
`mediana_antes / mediana_depois`

Redução positiva significa menor tempo depois. Valor negativo significa regressão.

## Cuidados metodológicos
- Não compare uma execução fria antes com uma execução aquecida depois.
- Não altere `shared_buffers`, paralelismo ou outras configurações no meio do experimento.
- Se mudar uma configuração, faça um experimento separado.
- Índices ocupam disco e elevam o custo de INSERT, UPDATE e DELETE.
- `ANALYZE` atualiza estatísticas; `VACUUM` e autovacuum devem ser considerados na discussão.
- Guarde os planos completos e os scripts usados como evidência.

## Limitações
A carga é sintética e determinística, portanto não representa perfeitamente uma aplicação real. Os resultados dependem de hardware, versão, cache, estatísticas e distribuição dos dados.
