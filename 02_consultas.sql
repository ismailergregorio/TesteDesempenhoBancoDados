SET search_path TO loja, public;

-- CONSULTA A: pedidos por período e status
SELECT id, cliente_id, data_pedido, status, valor_total
FROM pedidos
WHERE data_pedido >= TIMESTAMP '2024-01-01'
  AND data_pedido <  TIMESTAMP '2024-04-01'
  AND status = 'PAGO'
ORDER BY data_pedido DESC
LIMIT 100;

-- CONSULTA B: histórico de compras de um cliente
SELECT p.id, p.data_pedido, p.status,
       SUM(ip.quantidade * ip.preco_unitario) AS total_itens
FROM pedidos p
JOIN itens_pedido ip ON ip.pedido_id = p.id
WHERE p.cliente_id = 1234
GROUP BY p.id, p.data_pedido, p.status
ORDER BY p.data_pedido DESC
LIMIT 100;

-- CONSULTA C: faturamento por categoria de produto
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
