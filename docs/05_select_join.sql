-- =====================================================================
-- Maximo das Tintas - 05 SELECT com JOIN
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 3. CONSULTAS COM JOIN (cruzam varias tabelas)
-- =====================================================================

-- S01 - Ultimas 20 vendas com cliente e vendedor (view com JOIN venda-cliente-funcionario)
SELECT * FROM vw_vendas_detalhado ORDER BY data_venda DESC LIMIT 20;

-- S02 - Itens de uma venda com produto, categoria e fornecedor (4 tabelas)
SELECT MAX(id_venda) INTO @venda_exemplo
FROM venda WHERE status_venda = 'CONCLUIDA';
SELECT * FROM vw_itens_venda_detalhado WHERE id_venda = @venda_exemplo;

-- S03 - Situacao de estoque por produto, categoria e fornecedor
SELECT * FROM vw_estoque_situacao ORDER BY nome_categoria, descricao;

-- S04 - Pagamentos de junho/2026 com a venda, o cliente e o vendedor (JOIN explicito, 4 tabelas)
SELECT pg.id_pagamento, v.id_venda, DATE(v.data_venda) AS data_venda,
       c.nome AS cliente, f.nome AS vendedor,
       pg.forma_pagamento, pg.parcelas, pg.valor_pago
FROM pagamento pg
JOIN venda v       ON v.id_venda = pg.id_venda
JOIN cliente c     ON c.id_cliente = v.id_cliente
JOIN funcionario f ON f.id_funcionario = v.id_funcionario
WHERE v.data_venda >= '2026-06-01' AND v.data_venda < '2026-07-01'
ORDER BY v.data_venda, pg.id_pagamento
LIMIT 30;

-- S05 - Clientes cadastrados que nunca compraram (LEFT JOIN)
SELECT c.id_cliente, c.nome, c.tipo_pessoa, c.data_cadastro
FROM cliente c
LEFT JOIN venda v ON v.id_cliente = c.id_cliente
WHERE v.id_venda IS NULL
ORDER BY c.nome;
