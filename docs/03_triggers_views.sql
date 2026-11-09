-- =====================================================================
-- Maximo das Tintas - 03 TRIGGERS de estoque e VIEWS
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

-- =====================================================================
-- 1.5. TRIGGERS PARA AUTOMATIZACAO DE ESTOQUE
-- =====================================================================
-- Invariante garantida pelos triggers abaixo:
--   "o estoque de um produto so eh debitado/devolvido quando a venda que
--    contem esse produto esta com status_venda = 'CONCLUIDA'"
-- Isso cobre 4 fluxos automaticamente, sem UPDATE manual em estoque:
--   a) venda criada ja como CONCLUIDA (padrao) + itens inseridos  -> baixa na hora
--   b) orcamento (ORCAMENTO) convertido depois em CONCLUIDA       -> baixa de uma vez, para todos os itens
--   c) venda concluida cancelada (CONCLUIDA -> CANCELADA)         -> devolve o estoque de todos os itens
--   d) venda concluida apagada com DELETE FROM venda              -> devolve o estoque ANTES do CASCADE
--
-- O fluxo (d) e resolvido com um trigger BEFORE DELETE em 'venda' que devolve
-- o estoque de TODOS os itens da venda em bloco antes de o proprio registro
-- ser removido - ou seja, antes de o ON DELETE CASCADE apagar as linhas de
-- item_venda. Para essas linhas cascateadas nao devolverem o estoque de novo
-- (o que causaria devolucao em dobro), a variavel de sessao @venda_em_exclusao
-- sinaliza aos triggers de item_venda que a devolucao desta venda ja foi feita
-- em bloco, e um trigger AFTER DELETE em 'venda' limpa essa sinalizacao ao
-- final. Com isso, DELETE FROM venda passa a ser seguro mesmo para vendas
-- concluidas - ainda assim, cancelar (UPDATE status_venda='CANCELADA') continua
-- sendo a pratica recomendada quando se quer manter o historico para auditoria.

DELIMITER //

CREATE TRIGGER trg_venda_before_delete
BEFORE DELETE ON venda
FOR EACH ROW
BEGIN
    IF OLD.status_venda = 'CONCLUIDA' THEN
        UPDATE estoque e
        JOIN item_venda iv ON iv.id_produto = e.id_produto
        SET e.quantidade_atual = e.quantidade_atual + iv.quantidade
        WHERE iv.id_venda = OLD.id_venda;
    END IF;
    SET @venda_em_exclusao = OLD.id_venda;
END//

CREATE TRIGGER trg_venda_after_delete_cleanup
AFTER DELETE ON venda
FOR EACH ROW
BEGIN
    SET @venda_em_exclusao = NULL;
END//

-- RN01: so produto ATIVO pode entrar em uma venda nova
-- (produto inativo continua no historico das vendas antigas, mas nao e mais vendido)
CREATE TRIGGER trg_item_venda_before_insert
BEFORE INSERT ON item_venda
FOR EACH ROW
BEGIN
    IF (SELECT ativo FROM produto WHERE id_produto = NEW.id_produto) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN01: produto inativo nao pode ser vendido';
    END IF;
END//

CREATE TRIGGER trg_item_venda_after_insert
AFTER INSERT ON item_venda
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status_venda INTO v_status FROM venda WHERE id_venda = NEW.id_venda;
    IF v_status = 'CONCLUIDA' THEN
        UPDATE estoque
        SET quantidade_atual = quantidade_atual - NEW.quantidade
        WHERE id_produto = NEW.id_produto;
    END IF;
END//

CREATE TRIGGER trg_item_venda_after_update
AFTER UPDATE ON item_venda
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status_venda INTO v_status FROM venda WHERE id_venda = NEW.id_venda;
    -- Ajusta apenas a diferenca de quantidade (NEW - OLD); se id_produto tambem
    -- mudou nesta mesma linha, prefira DELETE + INSERT em vez de UPDATE do produto.
    IF v_status = 'CONCLUIDA' AND NEW.quantidade <> OLD.quantidade THEN
        UPDATE estoque
        SET quantidade_atual = quantidade_atual - (NEW.quantidade - OLD.quantidade)
        WHERE id_produto = NEW.id_produto;
    END IF;
END//

CREATE TRIGGER trg_item_venda_after_delete
AFTER DELETE ON item_venda
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    -- Se este DELETE veio do CASCADE de um DELETE FROM venda, o estoque desta
    -- venda ja foi devolvido em bloco pelo trg_venda_before_delete: nao repetir.
    IF @venda_em_exclusao IS NULL OR @venda_em_exclusao <> OLD.id_venda THEN
        SELECT status_venda INTO v_status FROM venda WHERE id_venda = OLD.id_venda;
        IF v_status = 'CONCLUIDA' THEN
            UPDATE estoque
            SET quantidade_atual = quantidade_atual + OLD.quantidade
            WHERE id_produto = OLD.id_produto;
        END IF;
    END IF;
END//

CREATE TRIGGER trg_venda_after_update_status
AFTER UPDATE ON venda
FOR EACH ROW
BEGIN
    IF OLD.status_venda <> 'CONCLUIDA' AND NEW.status_venda = 'CONCLUIDA' THEN
        UPDATE estoque e
        JOIN item_venda iv ON iv.id_produto = e.id_produto
        SET e.quantidade_atual = e.quantidade_atual - iv.quantidade
        WHERE iv.id_venda = NEW.id_venda;
    ELSEIF OLD.status_venda = 'CONCLUIDA' AND NEW.status_venda <> 'CONCLUIDA' THEN
        UPDATE estoque e
        JOIN item_venda iv ON iv.id_produto = e.id_produto
        SET e.quantidade_atual = e.quantidade_atual + iv.quantidade
        WHERE iv.id_venda = NEW.id_venda;
    END IF;
END//

DELIMITER ;

-- =====================================================================
-- 1.6. VIEWS PARA CONSULTAS COM MULTIPLOS JOIN E RELATORIOS GERENCIAIS
-- =====================================================================

-- Visao 1: vendas com nome do cliente e do funcionario responsavel
CREATE VIEW vw_vendas_detalhado AS
SELECT
    v.id_venda, c.nome AS cliente, f.nome AS vendedor,
    v.data_venda, v.status_venda, v.valor_total
FROM venda v
JOIN cliente c     ON c.id_cliente = v.id_cliente
JOIN funcionario f ON f.id_funcionario = v.id_funcionario;

-- Visao 2: itens de cada venda com produto, categoria e fornecedor
CREATE VIEW vw_itens_venda_detalhado AS
SELECT
    v.id_venda, p.descricao AS produto, cat.nome_categoria, forn.nome_fornecedor,
    iv.quantidade, iv.preco_unitario_venda, iv.subtotal
FROM item_venda iv
JOIN venda v         ON v.id_venda = iv.id_venda
JOIN produto p       ON p.id_produto = iv.id_produto
JOIN categoria cat   ON cat.id_categoria = p.id_categoria
JOIN fornecedor forn ON forn.id_fornecedor = p.id_fornecedor;

-- Visao 3: situacao completa de estoque por produto, categoria e fornecedor
CREATE VIEW vw_estoque_situacao AS
SELECT
    p.codigo_interno, p.descricao, cat.nome_categoria, forn.nome_fornecedor,
    e.quantidade_atual, e.quantidade_minima, e.localizacao_deposito
FROM estoque e
JOIN produto p       ON p.id_produto = e.id_produto
JOIN categoria cat   ON cat.id_categoria = p.id_categoria
JOIN fornecedor forn ON forn.id_fornecedor = p.id_fornecedor;

-- Visao 4: produtos em ponto de reposicao (usa a Visao 3 como base)
CREATE VIEW vw_produtos_abaixo_minimo AS
SELECT * FROM vw_estoque_situacao
WHERE quantidade_atual <= quantidade_minima;

-- Visao 5: faturamento mensal (somente vendas concluidas)
CREATE VIEW vw_faturamento_mensal AS
SELECT
    DATE_FORMAT(v.data_venda, '%Y-%m') AS mes,
    COUNT(DISTINCT v.id_venda) AS qtd_vendas,
    SUM(v.valor_total) AS faturamento
FROM venda v
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY DATE_FORMAT(v.data_venda, '%Y-%m');

-- Visao 6: ranking de produtos mais vendidos
CREATE VIEW vw_ranking_produtos AS
SELECT
    p.descricao,
    SUM(iv.quantidade) AS total_unidades_vendidas,
    SUM(iv.subtotal) AS receita_total
FROM item_venda iv
JOIN venda v   ON v.id_venda = iv.id_venda
JOIN produto p ON p.id_produto = iv.id_produto
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY p.id_produto, p.descricao;

-- Visao 7: faturamento por categoria
CREATE VIEW vw_faturamento_categoria AS
SELECT cat.nome_categoria, SUM(iv.subtotal) AS receita_categoria
FROM item_venda iv
JOIN venda v       ON v.id_venda = iv.id_venda
JOIN produto p     ON p.id_produto = iv.id_produto
JOIN categoria cat ON cat.id_categoria = p.id_categoria
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY cat.nome_categoria;

-- Visao 8: desempenho de vendas por funcionario
CREATE VIEW vw_desempenho_vendedor AS
SELECT
    f.nome AS vendedor,
    COUNT(v.id_venda) AS qtd_vendas,
    SUM(v.valor_total) AS total_vendido
FROM funcionario f
LEFT JOIN venda v ON v.id_funcionario = f.id_funcionario AND v.status_venda = 'CONCLUIDA'
GROUP BY f.id_funcionario, f.nome;

