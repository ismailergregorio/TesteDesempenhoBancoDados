SET search_path TO loja, public;

-- Índices para filtros e junções identificados no diagnóstico.
CREATE INDEX IF NOT EXISTS idx_pedidos_data_status
    ON pedidos (data_pedido, status);

CREATE INDEX IF NOT EXISTS idx_pedidos_cliente_data
    ON pedidos (cliente_id, data_pedido DESC);

CREATE INDEX IF NOT EXISTS idx_itens_pedido_pedido
    ON itens_pedido (pedido_id);

-- Índice para a coluna de junção e agrupamento por categoria.
-- O PK de produtos já indexa produtos.id; este índice atende categoria.
CREATE INDEX IF NOT EXISTS idx_produtos_categoria
    ON produtos (categoria);

-- Atualiza estatísticas após criação dos índices.
ANALYZE pedidos;
ANALYZE itens_pedido;
ANALYZE produtos;

-- Inventário dos índices criados
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'loja'
ORDER BY tablename, indexname;
