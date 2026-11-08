-- =====================================================================
-- Maximo das Tintas - 07 Consultas gerenciais
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 6. CONSULTAS GERENCIAIS (encapsuladas como VIEWS - ver Secao 1.6)
-- =====================================================================

-- 6.1 Faturamento por mes
SELECT * FROM vw_faturamento_mensal ORDER BY mes;

-- 6.2 Ranking de produtos mais vendidos
SELECT * FROM vw_ranking_produtos ORDER BY total_unidades_vendidas DESC LIMIT 10;

-- 6.3 Faturamento por categoria
SELECT * FROM vw_faturamento_categoria ORDER BY receita_categoria DESC;

-- 6.4 Desempenho de vendas por funcionario
SELECT * FROM vw_desempenho_vendedor ORDER BY total_vendido DESC;

-- 6.5 Produtos com estoque abaixo (ou igual) ao minimo, para reposicao
SELECT * FROM vw_produtos_abaixo_minimo ORDER BY quantidade_atual ASC;

