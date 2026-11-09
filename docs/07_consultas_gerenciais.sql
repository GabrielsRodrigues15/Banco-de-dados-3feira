-- =====================================================================
-- Maximo das Tintas - 07 Consultas gerenciais (G01 a G16)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- Cada consulta traz: codigo, pergunta, problema (P1..P6) ou KPI que atende.
-- KPIs (formula, periodo e meta) estao na secao 1.6 do README.
-- =====================================================================
USE loja_tintas_materiais;

-- G01 — Qual o faturamento de cada mes (vendas concluidas)?
-- Atende: KPI1 Faturamento mensal (meta: R$ 20.000/mes) · P3
SELECT mes, qtd_vendas, faturamento,
       ROUND(faturamento / 20000 * 100, 1) AS pct_da_meta
FROM vw_faturamento_mensal
ORDER BY mes;

-- G02 — Qual o ticket medio por mes?
-- Atende: KPI2 Ticket medio = faturamento / no de vendas concluidas (meta: >= R$ 130)
SELECT DATE_FORMAT(data_venda, '%Y-%m') AS mes,
       COUNT(*) AS vendas,
       ROUND(AVG(valor_total), 2) AS ticket_medio
FROM venda
WHERE status_venda = 'CONCLUIDA'
GROUP BY DATE_FORMAT(data_venda, '%Y-%m')
ORDER BY mes;

-- G03 — Quantas unidades saem do estoque por mes?
-- Atende: KPI3 Unidades vendidas por mes (referencia da loja: ~500/mes) · P4
SELECT DATE_FORMAT(v.data_venda, '%Y-%m') AS mes,
       SUM(iv.quantidade) AS unidades_vendidas,
       COUNT(DISTINCT iv.id_produto) AS produtos_distintos
FROM item_venda iv
JOIN venda v ON v.id_venda = iv.id_venda
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY DATE_FORMAT(v.data_venda, '%Y-%m')
ORDER BY mes;

-- G04 — Qual a taxa de cancelamento (troca/desistencia) por mes?
-- Atende: KPI4 Taxa de cancelamento = canceladas / (concluidas + canceladas) (meta: <= 5%) · P6
SELECT DATE_FORMAT(data_venda, '%Y-%m') AS mes,
       SUM(status_venda = 'CANCELADA') AS canceladas,
       SUM(status_venda IN ('CONCLUIDA', 'CANCELADA')) AS base,
       ROUND(100 * SUM(status_venda = 'CANCELADA') /
             NULLIF(SUM(status_venda IN ('CONCLUIDA', 'CANCELADA')), 0), 1) AS taxa_cancelamento_pct
FROM venda
GROUP BY DATE_FORMAT(data_venda, '%Y-%m')
ORDER BY mes;

-- G05 — Quais produtos estao no ponto de reposicao agora?
-- Atende: KPI5 Produtos abaixo do minimo (meta: 0) · P2
SELECT codigo_interno, descricao, nome_fornecedor,
       quantidade_atual, quantidade_minima,
       quantidade_minima - quantidade_atual AS falta_para_o_minimo
FROM vw_produtos_abaixo_minimo
ORDER BY quantidade_atual, descricao;

-- G06 — Para quantos dias o estoque atual de cada produto da (cobertura)?
-- Atende: KPI6 Cobertura de estoque = saldo / media diaria vendida nos ultimos 90 dias · P2, P4
SELECT p.codigo_interno, p.descricao, e.quantidade_atual,
       ROUND(COALESCE(SUM(iv.quantidade), 0) / 90, 2) AS media_diaria_90d,
       CASE WHEN COALESCE(SUM(iv.quantidade), 0) = 0 THEN NULL
            ELSE ROUND(e.quantidade_atual / (SUM(iv.quantidade) / 90), 0) END AS dias_de_cobertura
FROM produto p
JOIN estoque e ON e.id_produto = p.id_produto
LEFT JOIN item_venda iv ON iv.id_produto = p.id_produto
     AND iv.id_venda IN (SELECT id_venda FROM venda
                         WHERE status_venda = 'CONCLUIDA'
                           AND data_venda >= (SELECT MAX(data_venda) FROM venda) - INTERVAL 90 DAY)
WHERE p.ativo = 1
GROUP BY p.id_produto, p.codigo_interno, p.descricao, e.quantidade_atual
ORDER BY dias_de_cobertura IS NULL, dias_de_cobertura
LIMIT 15;

-- G07 — Quanto cada categoria fatura e qual a participacao no total?
-- Atende: P3 (relatorio por categoria sem planilha)
SELECT nome_categoria, receita_categoria,
       ROUND(100 * receita_categoria / SUM(receita_categoria) OVER (), 1) AS participacao_pct
FROM vw_faturamento_categoria
ORDER BY receita_categoria DESC;

-- G08 — Quanto cada fornecedor (marca) representa nas vendas?
-- Atende: P3 (relatorio por fornecedor; apoia a negociacao de compras)
SELECT f.nome_fornecedor,
       SUM(iv.quantidade) AS unidades,
       SUM(iv.subtotal) AS receita,
       ROUND(100 * SUM(iv.subtotal) / SUM(SUM(iv.subtotal)) OVER (), 1) AS participacao_pct
FROM item_venda iv
JOIN venda v      ON v.id_venda = iv.id_venda
JOIN produto p    ON p.id_produto = iv.id_produto
JOIN fornecedor f ON f.id_fornecedor = p.id_fornecedor
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY f.id_fornecedor, f.nome_fornecedor
ORDER BY receita DESC;

-- G09 — Como foi o desempenho de cada vendedor por mes?
-- Atende: KPI7 Faturamento e ticket medio por vendedor · P3
SELECT f.nome AS vendedor,
       DATE_FORMAT(v.data_venda, '%Y-%m') AS mes,
       COUNT(*) AS vendas,
       SUM(v.valor_total) AS faturamento,
       ROUND(AVG(v.valor_total), 2) AS ticket_medio
FROM venda v
JOIN funcionario f ON f.id_funcionario = v.id_funcionario
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY f.id_funcionario, f.nome, DATE_FORMAT(v.data_venda, '%Y-%m')
ORDER BY mes, faturamento DESC;

-- G10 — Curva ABC: quais produtos formam 80% da receita (A), os 15% seguintes (B) e o resto (C)?
-- Atende: KPI8 Concentracao da receita por produto · P3, P2 (priorizar reposicao)
SELECT descricao, receita_total, total_unidades_vendidas,
       ROUND(pct_acumulado, 1) AS pct_acumulado,
       CASE WHEN pct_acumulado <= 80 THEN 'A'
            WHEN pct_acumulado <= 95 THEN 'B' ELSE 'C' END AS classe_abc
FROM (
    SELECT descricao, receita_total, total_unidades_vendidas,
           100 * SUM(receita_total) OVER (ORDER BY receita_total DESC
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
               / SUM(receita_total) OVER () AS pct_acumulado
    FROM vw_ranking_produtos
) r
ORDER BY receita_total DESC;

-- G11 — Como os clientes pagam? Participacao de cada forma de pagamento por mes
-- Atende: KPI9 Participacao por forma de pagamento · P5 (conferencia do caixa)
SELECT DATE_FORMAT(pg.data_pagamento, '%Y-%m') AS mes,
       pg.forma_pagamento,
       COUNT(*) AS pagamentos,
       SUM(pg.valor_pago) AS valor,
       ROUND(100 * SUM(pg.valor_pago) /
             SUM(SUM(pg.valor_pago)) OVER (PARTITION BY DATE_FORMAT(pg.data_pagamento, '%Y-%m')), 1) AS participacao_pct
FROM pagamento pg
GROUP BY DATE_FORMAT(pg.data_pagamento, '%Y-%m'), pg.forma_pagamento
ORDER BY mes, valor DESC;

-- G12 — Fechamento de caixa: quanto entrou por forma de pagamento em cada dia da ultima semana?
-- Atende: P5 (conferencia diaria do caixa sem planilha)
SELECT DATE(pg.data_pagamento) AS dia, pg.forma_pagamento,
       COUNT(*) AS pagamentos, SUM(pg.valor_pago) AS valor
FROM pagamento pg
WHERE pg.data_pagamento >= (SELECT MAX(data_venda) FROM venda) - INTERVAL 7 DAY
GROUP BY DATE(pg.data_pagamento), pg.forma_pagamento
ORDER BY dia, pg.forma_pagamento;

-- G13 — Quais orcamentos estao em aberto, de quem e ha quantos dias?
-- Atende: P1 (vendas a recuperar que hoje se perdem em papel)
SELECT v.id_venda, DATE(v.data_venda) AS data_orcamento, c.nome AS cliente,
       f.nome AS vendedor, v.valor_total,
       DATEDIFF((SELECT MAX(data_venda) FROM venda), v.data_venda) AS dias_em_aberto
FROM venda v
JOIN cliente c     ON c.id_cliente = v.id_cliente
JOIN funcionario f ON f.id_funcionario = v.id_funcionario
WHERE v.status_venda = 'ORCAMENTO'
ORDER BY dias_em_aberto DESC;

-- G14 — Quem compra: consumidor final sem cadastro, pessoa fisica ou empresa (PJ)?
-- Atende: KPI10 Participacao por perfil de cliente · P1
SELECT CASE WHEN c.id_cliente = 1 THEN 'Consumidor final (sem cadastro)'
            WHEN c.tipo_pessoa = 'PF' THEN 'Pessoa fisica cadastrada'
            ELSE 'Empresa (PJ)' END AS perfil,
       COUNT(*) AS vendas,
       SUM(v.valor_total) AS faturamento,
       ROUND(AVG(v.valor_total), 2) AS ticket_medio,
       ROUND(100 * SUM(v.valor_total) / SUM(SUM(v.valor_total)) OVER (), 1) AS participacao_pct
FROM venda v
JOIN cliente c ON c.id_cliente = v.id_cliente
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY perfil
ORDER BY faturamento DESC;

-- G15 — Em que dias e horarios a loja vende mais (apoia a escala dos 2 funcionarios)?
-- Atende: P3 · KPI11 Vendas por dia da semana e faixa horaria
SELECT ELT(DAYOFWEEK(data_venda), 'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab') AS dia_semana,
       CASE WHEN HOUR(data_venda) < 12 THEN 'Manha' ELSE 'Tarde' END AS periodo,
       COUNT(*) AS vendas,
       ROUND(AVG(valor_total), 2) AS ticket_medio
FROM venda
WHERE status_venda = 'CONCLUIDA'
GROUP BY DAYOFWEEK(data_venda), dia_semana, periodo
ORDER BY DAYOFWEEK(data_venda), periodo;

-- G16 — Quanto vale o estoque parado, a preco de venda, por categoria?
-- Atende: P1 (visao unica de catalogo e estoque) · KPI12 Valor do estoque
SELECT cat.nome_categoria,
       SUM(e.quantidade_atual) AS unidades_em_estoque,
       SUM(e.quantidade_atual * p.preco_unitario) AS valor_a_preco_de_venda
FROM estoque e
JOIN produto p     ON p.id_produto = e.id_produto
JOIN categoria cat ON cat.id_categoria = p.id_categoria
GROUP BY cat.nome_categoria
ORDER BY valor_a_preco_de_venda DESC;
