-- Execute conectado ao banco postgres:
-- CREATE DATABASE tuning_vendas;
-- Depois conecte-se ao banco tuning_vendas e execute os demais arquivos.

CREATE SCHEMA IF NOT EXISTS loja;
SET search_path TO loja, public;

DROP TABLE IF EXISTS itens_pedido CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

CREATE TABLE clientes (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    email           VARCHAR(160) NOT NULL,
    cidade          VARCHAR(80) NOT NULL,
    estado          CHAR(2) NOT NULL,
    criado_em       TIMESTAMP NOT NULL
);

CREATE TABLE produtos (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome            VARCHAR(150) NOT NULL,
    categoria       VARCHAR(60) NOT NULL,
    preco           NUMERIC(12,2) NOT NULL CHECK (preco >= 0),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE pedidos (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id      BIGINT NOT NULL REFERENCES clientes(id),
    data_pedido     TIMESTAMP NOT NULL,
    status          VARCHAR(20) NOT NULL,
    valor_total     NUMERIC(14,2) NOT NULL DEFAULT 0
);

CREATE TABLE itens_pedido (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id       BIGINT NOT NULL REFERENCES pedidos(id),
    produto_id      BIGINT NOT NULL REFERENCES produtos(id),
    quantidade      INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario  NUMERIC(12,2) NOT NULL CHECK (preco_unitario >= 0)
);

-- Importante: não crie índices secundários antes da medição inicial.
-- As PKs criam seus próprios índices automaticamente.
