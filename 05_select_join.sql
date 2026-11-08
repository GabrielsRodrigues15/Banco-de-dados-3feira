-- =====================================================================
-- Maximo das Tintas - 05 SELECT com JOIN
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 3. CONSULTAS COM JOIN (agora encapsuladas como VIEWS - ver Secao 1.6)
-- =====================================================================

-- 3.1 Lista de vendas com cliente e vendedor
SELECT * FROM vw_vendas_detalhado ORDER BY data_venda;

-- 3.2 Detalhe de itens de cada venda com produto, categoria e fornecedor
SELECT * FROM vw_itens_venda_detalhado ORDER BY id_venda;

-- 3.3 Situacao de estoque por produto, categoria e fornecedor
SELECT * FROM vw_estoque_situacao ORDER BY nome_categoria, descricao;

