SET search_path TO loja, public;

-- 50 mil clientes
INSERT INTO clientes (nome, email, cidade, estado, criado_em)
SELECT
    'Cliente ' || g,
    'cliente' || g || '@exemplo.com',
    (ARRAY['Vitoria','Vila Velha','Serra','Cariacica','Sao Paulo','Rio de Janeiro'])[((g - 1) % 6) + 1],
    (ARRAY['ES','ES','ES','ES','SP','RJ'])[((g - 1) % 6) + 1],
    TIMESTAMP '2020-01-01' + ((g % 2000) * INTERVAL '1 hour')
FROM generate_series(1, 50000) AS g;

-- 10 mil produtos
INSERT INTO produtos (nome, categoria, preco, ativo)
SELECT
    'Produto ' || g,
    (ARRAY['Informatica','Escritorio','Eletronicos','Limpeza','Alimentos'])[((g - 1) % 5) + 1],
    (10 + ((g * 13) % 9900) / 100.0)::NUMERIC(12,2),
    (g % 20 <> 0)
FROM generate_series(1, 10000) AS g;

-- 200 mil pedidos, distribuídos em aproximadamente 3 anos
INSERT INTO pedidos (cliente_id, data_pedido, status, valor_total)
SELECT
    ((g - 1) % 50000) + 1,
    TIMESTAMP '2023-01-01' + ((g % 1095) * INTERVAL '1 day') + ((g % 86400) * INTERVAL '1 second'),
    (ARRAY['PAGO','ENVIADO','CANCELADO','PENDENTE'])[((g - 1) % 4) + 1],
    0
FROM generate_series(1, 200000) AS g;

-- Exatamente 1 milhão de itens de pedido
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario)
SELECT
    ((g - 1) % 200000) + 1,
    ((g * 17 - 1) % 10000) + 1,
    ((g % 5) + 1)::INTEGER,
    (10 + ((g * 13) % 9900) / 100.0)::NUMERIC(12,2)
FROM generate_series(1, 1000000) AS g;

-- Atualiza o total de cada pedido a partir dos itens
UPDATE pedidos p
SET valor_total = x.total
FROM (
    SELECT pedido_id, SUM(quantidade * preco_unitario) AS total
    FROM itens_pedido
    GROUP BY pedido_id
) x
WHERE x.pedido_id = p.id;

-- Atualiza estatísticas para que o otimizador conheça a distribuição dos dados.
ANALYZE clientes;
ANALYZE produtos;
ANALYZE pedidos;
ANALYZE itens_pedido;

-- Conferência da carga
SELECT 'clientes' AS tabela, COUNT(*) AS registros FROM clientes
UNION ALL SELECT 'produtos', COUNT(*) FROM produtos
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'itens_pedido', COUNT(*) FROM itens_pedido;
