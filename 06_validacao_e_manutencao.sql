SET search_path TO loja, public;

-- Tamanho das tabelas e índices
SELECT
    relname AS tabela,
    pg_size_pretty(pg_table_size(relid)) AS tamanho_tabela,
    pg_size_pretty(pg_indexes_size(relid)) AS tamanho_indices,
    pg_size_pretty(pg_total_relation_size(relid)) AS tamanho_total
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname = 'loja'
ORDER BY pg_total_relation_size(relid) DESC;

-- Uso dos índices (reinicialização de estatísticas pode afetar contadores)
SELECT
    relname AS tabela,
    indexrelname AS indice,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'loja'
ORDER BY relname, indexrelname;

-- Atualização de estatísticas
ANALYZE clientes;
ANALYZE produtos;
ANALYZE pedidos;
ANALYZE itens_pedido;

-- Teste opcional de escrita: execute em ambiente de teste.
-- Compare tempo e tamanho antes/depois dos índices.
-- Não use em produção sem janela de manutenção.
