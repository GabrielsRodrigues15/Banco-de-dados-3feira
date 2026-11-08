-- =====================================================================
-- Maximo das Tintas - 08 Consultas de auditoria
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 7. CONSULTAS DE AUDITORIA
-- (mantidas como consultas avulsas, e nao como views: sao checagens de
--  integridade rodadas sob demanda, nao dados de uso corrente da aplicacao)
-- =====================================================================

-- 7.1 Vendas cujo valor_total nao bate com a soma dos itens
SELECT
    v.id_venda,
    v.valor_total AS valor_total_registrado,
    COALESCE(SUM(iv.subtotal), 0) AS valor_total_calculado
FROM venda v
LEFT JOIN item_venda iv ON iv.id_venda = v.id_venda
GROUP BY v.id_venda, v.valor_total
HAVING v.valor_total <> COALESCE(SUM(iv.subtotal), 0);

-- 7.2 Vendas concluidas sem nenhum pagamento registrado
SELECT v.id_venda, v.data_venda, v.valor_total
FROM venda v
LEFT JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA' AND pg.id_pagamento IS NULL;

-- 7.3 Produtos sem registro de estoque (violaria a regra de 1:1 produto-estoque)
SELECT p.id_produto, p.descricao
FROM produto p
LEFT JOIN estoque e ON e.id_produto = p.id_produto
WHERE e.id_estoque IS NULL;

-- 7.4 Estoque com quantidade negativa (nao deveria existir; a CHECK ja impede
-- fisicamente, mas a consulta serve para auditar ambientes sem suporte a CHECK)
SELECT * FROM estoque WHERE quantidade_atual < 0;

-- 7.5 Clientes com CPF/CNPJ duplicado (checagem de integridade)
SELECT cpf_cnpj, COUNT(*) AS ocorrencias
FROM cliente
GROUP BY cpf_cnpj
HAVING COUNT(*) > 1;
