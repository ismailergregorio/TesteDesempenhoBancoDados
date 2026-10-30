-- Preparação do baseline: remove somente os índices secundários deste experimento.
-- As chaves primárias e os dados das tabelas são preservados.
DROP INDEX IF EXISTS loja.idx_pedidos_data_status;
DROP INDEX IF EXISTS loja.idx_pedidos_cliente_data;
DROP INDEX IF EXISTS loja.idx_itens_pedido_pedido;
DROP INDEX IF EXISTS loja.idx_produtos_categoria;

-- Execute conectado ao banco tuning_vendas.
-- Salve a saída completa em arquivo para documentar a linha de base.
-- No psql: \o resultado_antes.txt
\timing on
SET search_path TO loja, public;

-- Aquecimento inicial: execute uma vez e não use esta rodada como medição principal.
SELECT COUNT(*) FROM itens_pedido;

-- Plano e medição da consulta A
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT id, cliente_id, data_pedido, status, valor_total
FROM pedidos
WHERE data_pedido >= TIMESTAMP '2024-01-01'
  AND data_pedido <  TIMESTAMP '2024-04-01'
  AND status = 'PAGO'
ORDER BY data_pedido DESC
LIMIT 100;

-- Consulta B
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, SETTINGS)
SELECT p.id, p.data_pedido, p.status,
       SUM(ip.quantidade * ip.preco_unitario) AS total_itens
FROM pedidos p
JOIN itens_pedido ip ON ip.pedido_id = p.id
WHERE p.cliente_id = 1234
GROUP BY p.id, p.data_pedido, p.status
ORDER BY p.data_pedido DESC
LIMIT 100;

-- Consulta C
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

-- Repita as três consultas pelo menos 5 vezes.
-- Registre Execution Time, Planning Time, shared hit/read blocks e tipo de scan.
-- \o
