-- Execute nas mesmas condições utilizadas em 03_medicao_antes.sql.
-- Use os mesmos comandos, parâmetros e número de repetições.
\timing on
SET search_path TO loja, public;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT id, cliente_id, data_pedido, status, valor_total
FROM pedidos
WHERE data_pedido >= TIMESTAMP '2024-01-01'
  AND data_pedido <  TIMESTAMP '2024-04-01'
  AND status = 'PAGO'
ORDER BY data_pedido DESC
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT p.id, p.data_pedido, p.status,
       SUM(ip.quantidade * ip.preco_unitario) AS total_itens
FROM pedidos p
JOIN itens_pedido ip ON ip.pedido_id = p.id
WHERE p.cliente_id = 1234
GROUP BY p.id, p.data_pedido, p.status
ORDER BY p.data_pedido DESC
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT pr.categoria,
       COUNT(DISTINCT ip.pedido_id) AS quantidade_pedidos,
       SUM(ip.quantidade) AS unidades_vendidas,
       SUM(ip.quantidade * ip.preco_unitario) AS faturamento
FROM itens_pedido ip
JOIN produtos pr ON pr.id = ip.produto_id
JOIN pedidos p ON p.id = ip.pedido_id
WHERE p.status IN ('PAGO', 'ENVIADO')
GROUP BY pr.categoria
ORDER BY faturamento DESC;

-- Repita cada consulta pelo menos 5 vezes e compare as medianas.
