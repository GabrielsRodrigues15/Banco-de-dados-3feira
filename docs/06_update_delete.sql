-- =====================================================================
-- Maximo das Tintas - 06 UPDATE e DELETE
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- Os exemplos localizam os registros por consulta (e nao por id fixo),
-- para continuar funcionando se a massa de dados for regerada.
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 4. UPDATE
-- =====================================================================

-- 4.1 Reajuste de 3% nos produtos do fornecedor Tigre (RN04: vendas antigas
--     mantem o preco praticado, porque ele esta gravado em item_venda)
UPDATE produto p
JOIN fornecedor f ON f.id_fornecedor = p.id_fornecedor
SET p.preco_unitario = ROUND(p.preco_unitario * 1.03, 2)
WHERE f.nome_fornecedor LIKE 'Tigre%';

-- 4.2 Conversao do orcamento mais antigo em venda CONCLUIDA (RN06).
-- O trigger trg_venda_after_update_status baixa o estoque de todos os itens de uma vez.
SELECT MIN(id_venda) INTO @orc FROM venda WHERE status_venda = 'ORCAMENTO';

SELECT iv.id_produto, p.descricao, iv.quantidade, e.quantidade_atual AS estoque_antes
FROM item_venda iv
JOIN produto p ON p.id_produto = iv.id_produto
JOIN estoque e ON e.id_produto = iv.id_produto
WHERE iv.id_venda = @orc;

UPDATE venda SET status_venda = 'CONCLUIDA', data_venda = '2026-06-30 17:30:00'
WHERE id_venda = @orc;

-- pagamento da venda convertida (RN09: venda concluida e paga integralmente)
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas)
SELECT id_venda, 'PIX', valor_total, data_venda, 1 FROM venda WHERE id_venda = @orc;

SELECT iv.id_produto, p.descricao, iv.quantidade, e.quantidade_atual AS estoque_depois
FROM item_venda iv
JOIN produto p ON p.id_produto = iv.id_produto
JOIN estoque e ON e.id_produto = iv.id_produto
WHERE iv.id_venda = @orc;

-- 4.3 Atualizacao cadastral de um cliente
UPDATE cliente
SET telefone = '(11) 90000-0000', email = 'contato.atualizado@email.com'
WHERE id_cliente = 2;

-- 4.4 Reposicao de estoque: entrada de mercadoria dos produtos no ponto de reposicao
--     (sobe o saldo para o dobro do minimo + 10 unidades)
UPDATE estoque
SET quantidade_atual = quantidade_minima * 2 + 10
WHERE quantidade_atual = 0;

-- =====================================================================
-- 5. DELETE
-- =====================================================================

-- 5.1 Cancelamento (troca) da ultima venda concluida - pratica recomendada (RN08):
-- a venda NAO e apagada; o trigger devolve o estoque de todos os itens.
SELECT MAX(id_venda) INTO @canc FROM venda
WHERE status_venda = 'CONCLUIDA' AND data_venda < '2026-07-01';
UPDATE venda SET status_venda = 'CANCELADA' WHERE id_venda = @canc;

-- 5.2 Cliente desistiu de um item do orcamento: remove o item e recalcula o total (RN05)
SELECT MAX(id_venda) INTO @orc2 FROM venda v
WHERE status_venda = 'ORCAMENTO'
  AND (SELECT COUNT(*) FROM item_venda i WHERE i.id_venda = v.id_venda) >= 2;
SELECT MAX(id_item_venda) INTO @item FROM item_venda WHERE id_venda = @orc2;
DELETE FROM item_venda WHERE id_item_venda = @item;
UPDATE venda v
SET v.valor_total = (SELECT SUM(i.subtotal) FROM item_venda i WHERE i.id_venda = v.id_venda)
WHERE v.id_venda = @orc2;

-- 5.3 Exclusao fisica de uma venda lancada em duplicidade.
-- trg_venda_before_delete devolve o estoque ANTES do ON DELETE CASCADE apagar os itens,
-- sem devolver em dobro. Pagamento nao tem CASCADE de proposito (registro financeiro):
-- e removido primeiro, de forma explicita.
SELECT MIN(id_venda) INTO @dup FROM venda WHERE status_venda = 'CONCLUIDA';
DROP TEMPORARY TABLE IF EXISTS tmp_itens_dup;
CREATE TEMPORARY TABLE tmp_itens_dup AS
SELECT id_produto, quantidade FROM item_venda WHERE id_venda = @dup;

SELECT t.id_produto, t.quantidade, e.quantidade_atual AS estoque_antes_do_delete
FROM tmp_itens_dup t JOIN estoque e ON e.id_produto = t.id_produto;

DELETE FROM pagamento WHERE id_venda = @dup;
DELETE FROM venda     WHERE id_venda = @dup;

SELECT t.id_produto, t.quantidade, e.quantidade_atual AS estoque_depois_do_delete
FROM tmp_itens_dup t JOIN estoque e ON e.id_produto = t.id_produto;
DROP TEMPORARY TABLE tmp_itens_dup;

-- 5.4 Remocao de um funcionario cadastrado por engano (nunca vendeu).
-- Funcionario com vendas nao pode ser apagado (FK, RN17): e inativado.
INSERT INTO funcionario (nome, cargo, cpf, data_admissao) VALUES ('Cadastro Teste', 'Vendedor', '99999999999', '2026-07-01');
DELETE FROM funcionario
WHERE cpf = '99999999999'
  AND NOT EXISTS (SELECT 1 FROM venda WHERE venda.id_funcionario = funcionario.id_funcionario);

-- 5.5 Demonstracao da auditoria A01 dentro de uma transacao (nada fica gravado):
-- apagar um item de venda concluida sem recalcular o total gera divergencia,
-- que a consulta A01 encontra; o ROLLBACK desfaz tudo (inclusive a devolucao de estoque).
START TRANSACTION;
SELECT MAX(id_venda) INTO @demo FROM venda v
WHERE status_venda = 'CONCLUIDA'
  AND (SELECT COUNT(*) FROM item_venda i WHERE i.id_venda = v.id_venda) >= 2;
DELETE FROM item_venda
WHERE id_item_venda = (SELECT id FROM (SELECT MIN(id_item_venda) AS id FROM item_venda WHERE id_venda = @demo) x);
SELECT v.id_venda, v.valor_total AS total_registrado, SUM(iv.subtotal) AS soma_dos_itens
FROM venda v JOIN item_venda iv ON iv.id_venda = v.id_venda
WHERE v.id_venda = @demo GROUP BY v.id_venda, v.valor_total;
ROLLBACK;
