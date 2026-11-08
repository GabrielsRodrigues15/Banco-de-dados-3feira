-- =====================================================================
-- Maximo das Tintas - 06 UPDATE e DELETE
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 4. UPDATE
-- =====================================================================

-- 4.1 Reajuste de 5% no preco de todos os produtos da categoria "Tintas e Vernizes"
UPDATE produto p
JOIN categoria c ON c.id_categoria = p.id_categoria
SET p.preco_unitario = ROUND(p.preco_unitario * 1.05, 2)
WHERE c.nome_categoria = 'Tintas e Vernizes';

-- 4.2 Conversao de um ORCAMENTO em venda CONCLUIDA
-- O trigger trg_venda_after_update_status detecta a mudanca de status e debita
-- o estoque de TODOS os itens dessa venda de uma so vez - nao e preciso nenhum
-- UPDATE manual em "estoque" aqui.
UPDATE venda
SET status_venda = 'CONCLUIDA'
WHERE id_venda = 4 AND status_venda = 'ORCAMENTO';

-- Conferindo o efeito automatico do trigger:
SELECT * FROM vw_itens_venda_detalhado WHERE id_venda = 4;
SELECT * FROM vw_estoque_situacao
WHERE descricao IN (SELECT produto FROM vw_itens_venda_detalhado WHERE id_venda = 4);

-- 4.3 Atualizacao cadastral de um cliente
UPDATE cliente
SET telefone = '(11) 90000-0000', email = 'contato.atualizado@email.com'
WHERE id_cliente = 1;

-- =====================================================================
-- 5. DELETE
-- =====================================================================

-- 5.1 Cancelamento de uma venda concluida.
-- Pratica recomendada para preservar o historico da venda para auditoria:
-- cancelar (nao apagar) - isso aciona trg_venda_after_update_status, que
-- DEVOLVE automaticamente ao estoque a quantidade de todos os itens dessa venda.
UPDATE venda SET status_venda = 'CANCELADA' WHERE id_venda = 1;

-- Conferindo a devolucao automatica de estoque:
SELECT * FROM vw_estoque_situacao
WHERE descricao IN (SELECT produto FROM vw_itens_venda_detalhado WHERE id_venda = 1);

-- 5.1b Exclusao fisica de uma venda concluida (sem cancelar antes).
-- trg_venda_before_delete devolve o estoque de todos os itens ANTES do
-- ON DELETE CASCADE remover as linhas de item_venda, entao nenhuma quantidade
-- fica "perdida" mesmo apagando a venda diretamente. A tabela temporaria abaixo
-- so existe para guardar quais produtos comparar no antes/depois deste teste.
DROP TEMPORARY TABLE IF EXISTS tmp_produtos_venda_2;
CREATE TEMPORARY TABLE tmp_produtos_venda_2 AS
SELECT id_produto FROM item_venda WHERE id_venda = 2;

SELECT p.descricao, e.quantidade_atual AS estoque_antes_do_delete
FROM tmp_produtos_venda_2 t
JOIN produto p ON p.id_produto = t.id_produto
JOIN estoque e ON e.id_produto = t.id_produto;

-- pagamento nao tem ON DELETE CASCADE de proposito (registro financeiro nao
-- deve sumir sozinho por tabela-mae); para apagar a venda de fato, remova
-- primeiro o(s) pagamento(s) associados:
DELETE FROM pagamento WHERE id_venda = 2;
DELETE FROM venda WHERE id_venda = 2;

SELECT p.descricao, e.quantidade_atual AS estoque_depois_do_delete
FROM tmp_produtos_venda_2 t
JOIN produto p ON p.id_produto = t.id_produto
JOIN estoque e ON e.id_produto = t.id_produto;

DROP TEMPORARY TABLE tmp_produtos_venda_2;

-- 5.2 Remocao de um item de venda lancado por engano (a venda permanece).
-- id_item_venda = 12 pertence a venda 5 (CONCLUIDA, ainda intacta neste ponto
-- do script). trg_item_venda_after_delete devolve ao estoque a quantidade do
-- item removido. Repare que valor_total da venda NAO e recalculado
-- automaticamente (nao existe trigger para isso de proposito) - e exatamente
-- essa inconsistencia que a consulta de auditoria 7.1 mais abaixo foi
-- desenhada para detectar.
DELETE FROM item_venda WHERE id_item_venda = 12;

-- 5.3 Remocao de um funcionario que nunca teve vendas associadas
DELETE FROM funcionario
WHERE id_funcionario = 5
  AND NOT EXISTS (SELECT 1 FROM venda WHERE venda.id_funcionario = funcionario.id_funcionario);

