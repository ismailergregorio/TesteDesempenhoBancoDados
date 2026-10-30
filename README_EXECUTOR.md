# Executor automatizado — Tuning PostgreSQL

Este executor usa os arquivos SQL fornecidos no projeto. As consultas não ficam duplicadas no Python: o script lê `03_medicao_antes.sql` e `05_medicao_depois.sql` para executar e medir os EXPLAIN ANALYZE.

## Requisitos
- Python 3.10+
- PostgreSQL acessível
- Usuário com permissão para executar os SQLs e criar índices
- Banco `tuning_vendas` já criado

## Instalação (PowerShell)
```powershell
py -m pip install -r requirements.txt
```

## Execução normal
Com as tabelas e dados já preparados:
```powershell
py executar_tuning.py --host localhost --port 5432 --database tuning_vendas --user postgres
```
O programa pede a senha. Por padrão executa 5 repetições das consultas antes e depois, aplica os índices e roda a validação.

## Criar estrutura e popular dados
**Atenção:** `00_criar_banco.sql` contém `DROP TABLE`. Isso apaga as tabelas existentes no schema `loja`.
Para recriar a estrutura e carregar os dados:
```powershell
py executar_tuning.py --host localhost --port 5432 --database tuning_vendas --user postgres --setup --confirm-reset --load-data
```
O banco `tuning_vendas` precisa existir previamente. O arquivo `00_criar_banco.sql` cria o schema e as tabelas, mas não cria o database.

## Opções
- `--repeats 7`: quantidade de repetições por consulta.
- `--skip-before`: pula a medição antes dos índices.
- `--skip-after`: pula a medição depois dos índices.
- `--password SUA_SENHA`: opcional; mais seguro deixar o programa solicitar a senha.

## Arquivos SQL utilizados
1. `00_criar_banco.sql` — estrutura (somente com `--setup --confirm-reset`).
2. `01_popular_dados.sql` — carga (somente com `--load-data`).
3. `03_medicao_antes.sql` — baseline.
4. `04_aplicar_tuning.sql` — índices e ANALYZE.
5. `05_medicao_depois.sql` — medição após tuning.
6. `06_validacao_e_manutencao.sql` — validação final.

`02_consultas.sql` é um arquivo de referência das consultas; as medições oficiais são executadas pelos EXPLAIN dos arquivos 03 e 05.

## Relatórios
São gerados na mesma pasta:
- `relatorio_tuning_DATA_HORA.html` — resumo, medianas e SQL executado.
- `resultado_tuning_DATA_HORA.json` — planos completos, buffers, tempos e histórico de comandos.

## Observações
- O executor ignora metacomandos exclusivos do `psql`, como `\timing` e `\o`, pois não são SQL e não funcionam via psycopg2.
- Não rode `--setup` em banco com dados que deseja preservar.
- Para comparação válida, mantenha os mesmos dados e parâmetros antes/depois.

## Correção para índices já existentes
O arquivo `03_medicao_antes.sql` agora remove, antes do baseline, somente os quatro índices secundários avaliados. As PKs e os dados são preservados. O arquivo `04_aplicar_tuning.sql` usa `CREATE INDEX IF NOT EXISTS`, evitando erro de duplicidade em execuções repetidas.
Atenção: se houver índices com os mesmos nomes mas definições diferentes, `IF NOT EXISTS` não altera a definição existente; confira o inventário de índices no PostgreSQL.
