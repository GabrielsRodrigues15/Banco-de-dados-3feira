-- =====================================================================
-- PROJETO: Sistema de Gestao - Loja de Tintas e Materiais de Construcao
-- Testado em MariaDB 10.11 / compativel com MySQL 5.7+ / 8.x
--
-- SUMARIO DO SCRIPT (ordem exigida pelo enunciado da Entrega 2):
--   1)   CREATE DATABASE
--   1.1) CREATE TABLE (9 tabelas, com tipos de dados adequados)
--        Constraints (PK, FK, NOT NULL, UNIQUE, CHECK) ja embutidas em cada CREATE TABLE
--   1.5) TRIGGERS de automacao de estoque (baixa/devolucao automatica)
--   1.6) VIEWS para consultas com JOIN e relatorios gerenciais
--   2)   INSERT INTO (massa de dados ficticia e coerente)
--   3)   SELECT com JOIN (via views)
--   4)   UPDATE
--   5)   DELETE
--   6)   Consultas gerenciais (via views)
--   7)   Consultas de auditoria
--
-- Baixa/devolucao de estoque nao e mais manual: acontece via TRIGGERS (Secao
-- 1.5), cobrindo 4 cenarios sem nenhum UPDATE direto em "estoque":
--   a) venda criada ja concluida + itens inseridos      -> baixa na hora
--   b) orcamento convertido depois em venda concluida   -> baixa de uma vez
--   c) venda concluida cancelada                        -> devolve o estoque
--   d) venda concluida apagada com DELETE FROM venda    -> devolve o estoque
--      ANTES do ON DELETE CASCADE remover os itens (ver comentario na Secao 1.5)
--
-- Como executar:
--   mysql -u seu_usuario -p < script_banco_dados.sql
-- =====================================================================

-- =====================================================================
-- BANCO DE DADOS: loja_tintas_materiais
-- Sistema de gestao para loja de tintas e materiais de construcao
-- =====================================================================

DROP DATABASE IF EXISTS loja_tintas_materiais;
CREATE DATABASE loja_tintas_materiais CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE loja_tintas_materiais;

-- =====================================================================
-- 1. CRIACAO DAS TABELAS E CONSTRAINTS
-- =====================================================================

CREATE TABLE categoria (
    id_categoria     INT AUTO_INCREMENT PRIMARY KEY,
    nome_categoria   VARCHAR(60) NOT NULL,
    descricao        VARCHAR(200),
    CONSTRAINT uq_categoria_nome UNIQUE (nome_categoria)
) ENGINE=InnoDB;

CREATE TABLE fornecedor (
    id_fornecedor    INT AUTO_INCREMENT PRIMARY KEY,
    nome_fornecedor  VARCHAR(100) NOT NULL,
    cnpj             CHAR(14) NOT NULL,
    telefone         VARCHAR(20),
    email            VARCHAR(100),
    CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj)
) ENGINE=InnoDB;

CREATE TABLE produto (
    id_produto       INT AUTO_INCREMENT PRIMARY KEY,
    codigo_interno   VARCHAR(20) NOT NULL,
    codigo_barras    VARCHAR(20),
    descricao        VARCHAR(150) NOT NULL,
    ncm              VARCHAR(10),
    unidade_medida   VARCHAR(5) NOT NULL DEFAULT 'UN',
    preco_unitario   DECIMAL(10,2) NOT NULL,
    id_categoria     INT NOT NULL,
    id_fornecedor    INT NOT NULL,
    ativo            TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT uq_produto_codigo UNIQUE (codigo_interno),
    CONSTRAINT chk_produto_preco CHECK (preco_unitario >= 0),
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
    CONSTRAINT fk_produto_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
) ENGINE=InnoDB;

CREATE TABLE cliente (
    id_cliente       INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(100) NOT NULL,
    tipo_pessoa      ENUM('PF','PJ') NOT NULL DEFAULT 'PF',
    cpf_cnpj         VARCHAR(14) NOT NULL,
    telefone         VARCHAR(20),
    email            VARCHAR(100),
    endereco         VARCHAR(150),
    data_cadastro    DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT uq_cliente_doc UNIQUE (cpf_cnpj)
) ENGINE=InnoDB;

CREATE TABLE funcionario (
    id_funcionario   INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(100) NOT NULL,
    cargo            VARCHAR(50) NOT NULL,
    cpf              CHAR(11) NOT NULL,
    data_admissao    DATE NOT NULL,
    ativo            TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT uq_funcionario_cpf UNIQUE (cpf)
) ENGINE=InnoDB;

CREATE TABLE venda (
    id_venda         INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente       INT NOT NULL,
    id_funcionario   INT NOT NULL,
    data_venda       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_venda     ENUM('ORCAMENTO','CONCLUIDA','CANCELADA') NOT NULL DEFAULT 'CONCLUIDA',
    valor_total      DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_venda_total CHECK (valor_total >= 0),
    CONSTRAINT fk_venda_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_venda_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario)
) ENGINE=InnoDB;

-- tabela associativa: resolve o N:N entre venda e produto
CREATE TABLE item_venda (
    id_item_venda        INT AUTO_INCREMENT PRIMARY KEY,
    id_venda             INT NOT NULL,
    id_produto           INT NOT NULL,
    quantidade           INT NOT NULL,
    preco_unitario_venda DECIMAL(10,2) NOT NULL,
    subtotal             DECIMAL(10,2) GENERATED ALWAYS AS (quantidade * preco_unitario_venda) STORED,
    CONSTRAINT chk_item_qtd CHECK (quantidade > 0),
    CONSTRAINT uq_item_venda_produto UNIQUE (id_venda, id_produto),
    CONSTRAINT fk_item_venda FOREIGN KEY (id_venda) REFERENCES venda(id_venda) ON DELETE CASCADE,
    CONSTRAINT fk_item_produto FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
) ENGINE=InnoDB;

-- relacionamento 1:1 com produto (cada produto tem exatamente um registro de estoque)
CREATE TABLE estoque (
    id_estoque           INT AUTO_INCREMENT PRIMARY KEY,
    id_produto           INT NOT NULL,
    quantidade_atual     INT NOT NULL DEFAULT 0,
    quantidade_minima    INT NOT NULL DEFAULT 5,
    localizacao_deposito VARCHAR(50),
    CONSTRAINT chk_estoque_qtd CHECK (quantidade_atual >= 0),
    CONSTRAINT uq_estoque_produto UNIQUE (id_produto),
    CONSTRAINT fk_estoque_produto FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
) ENGINE=InnoDB;

CREATE TABLE pagamento (
    id_pagamento     INT AUTO_INCREMENT PRIMARY KEY,
    id_venda         INT NOT NULL,
    forma_pagamento  ENUM('DINHEIRO','PIX','CARTAO_CREDITO','CARTAO_DEBITO','BOLETO') NOT NULL,
    valor_pago       DECIMAL(10,2) NOT NULL,
    data_pagamento   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    parcelas         INT NOT NULL DEFAULT 1,
    CONSTRAINT chk_pagamento_valor CHECK (valor_pago >= 0),
    CONSTRAINT chk_pagamento_parcelas CHECK (parcelas >= 1),
    CONSTRAINT fk_pagamento_venda FOREIGN KEY (id_venda) REFERENCES venda(id_venda)
) ENGINE=InnoDB;

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

-- =====================================================================
-- 2. CARGA DE DADOS (massa ficticia, coerente com as operacoes da loja)
-- =====================================================================

-- Categorias
INSERT INTO categoria (nome_categoria) VALUES ('Ferramentas Manuais');
INSERT INTO categoria (nome_categoria) VALUES ('Tintas e Vernizes');
INSERT INTO categoria (nome_categoria) VALUES ('Pinceis, Rolos e Espatulas');
INSERT INTO categoria (nome_categoria) VALUES ('Acessorios de Pintura');
INSERT INTO categoria (nome_categoria) VALUES ('Instrumentos de Medicao');

-- Fornecedores
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Tramontina Ferramentas Ltda', '11222333000181', '(11) 4002-1111', 'vendas@tramontina-dist.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Famastil Ferramentas S.A.', '22333444000192', '(11) 4002-2222', 'comercial@famastil.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Ferja Industria e Comercio', '33444555000103', '(11) 4002-3333', 'contato@ferja.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Thompson Ferramentas Ltda', '44555666000114', '(11) 4002-4444', 'sac@thompson.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Condor S.A.', '55666777000125', '(11) 4002-5555', 'vendas@condor.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Tigre Materiais para Pintura', '66777888000136', '(11) 4002-6666', 'comercial@tigretintas.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Suvinil Distribuidora', '77888999000147', '(11) 4002-7777', 'vendas@suvinil-dist.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Bilacor Tintas Ltda', '88999000000158', '(11) 4002-8888', 'atendimento@bilacor.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Sparta Instrumentos', '99000111000169', '(11) 4002-9999', 'sac@sparta.com.br');
INSERT INTO fornecedor (nome_fornecedor, cnpj, telefone, email) VALUES ('Itaqua Quimica e Solventes', '10111222000170', '(11) 4003-1010', 'vendas@itaqua.com.br');

-- Produtos
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16642', '7891114010862', 'CHV FENDA 1/8X5 AM TRAMON', '82054000', 'UN', 8.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16643', NULL, 'CHV FENDA 3/16X3 AM TRAMON', '82054000', 'UN', 9.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16646', '7891114010916', 'CHV FENDA 3/16X6 AM TRAMON', '82054000', 'UN', 10.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16649', '7891114010947', 'CHV FENDA 1/4X6 AM TRAMON', '82054000', 'UN', 14.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16640', '7891114010848', 'CHV FENDA 1/8X3 AM TRAMON', '82054000', 'UN', 7.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('17394', '7898105776035', 'CHV FENDA CRV TOCO 1/4X1.1/2 FAMASTIL', '82054000', 'UN', 8.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16886', '7898105779241', 'CHV FENDA/PHIL JG 6PC FAMASTIL', '82054000', 'UN', 49.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16667', '7891114063462', 'CHV FIXA 10X11 TRAMON', '82041100', 'UN', 10.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16668', '7891114063479', 'CHV FIXA 12X13 TRAMON', '82041100', 'UN', 12.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16669', '7891114063486', 'CHV FIXA 14X15 TRAMON', '82041100', 'UN', 15.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16670', '7891114063493', 'CHV FIXA 16X17 TRAMON', '82041100', 'UN', 19.50, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16671', '7891114092882', 'CHV FIXA 18X19 TRAMON', '82041100', 'UN', 19.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16672', '7891114092899', 'CHV FIXA 20X22 TRAMON', '82041100', 'UN', 22.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16666', '7891114063455', 'CHV FIXA 8X9 TRAMON', '82041100', 'UN', 10.50, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('190826', NULL, 'CHV GRIFO STILLSON 8 FERJA', '82041200', 'UN', 29.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('192150', NULL, 'CHV INGLESA 12 EMBOR FERJA', '82041200', 'UN', 69.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('190418', '7899932004537', 'CHV MANDRIL 3/8 FERJA', '84669340', 'UN', 5.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16681', '7891114011067', 'CHV PHIL 3/16X3 AM TRAMON', '82054000', 'UN', 10.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('166401', '7891114011111', 'CHV PHIL 3/8X8 AM TRAMON', '82054000', 'UN', 35.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('17397', '7898105776189', 'CHV PHIL CRV 1/8X2 LAR FAMASTIL', '82054000', 'UN', 7.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('190732', '7899932008832', 'CHV PHIL CRV 1/8X4 EMBO FERJA', '82054000', 'UN', 8.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('18457', '7898105776219', 'CHV PHIL CRV 1/8X5 LAR FAMASTIL', '82054000', 'UN', 8.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('190734', '7899932008856', 'CHV PHIL CRV 1/8X6 EMBO FERJA', '82054000', 'UN', 9.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('192483', '7899932014093', 'CHV PHIL CRV 3/16X5 EMBO FERJA', '82054000', 'UN', 8.60, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('18472', '7898105776264', 'CHV PHIL CRV 3/16X5 LAR FAMASTIL', '82054000', 'UN', 10.50, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16783', '7898105776271', 'CHV PHIL CRV 3/16X6 LAR FAMASTIL', '82054000', 'UN', 10.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16787', '7898105776370', 'CHV PHIL CRV 5/16X8 LAR FAMASTIL', '82054000', 'UN', 21.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16687', '7891114013795', 'CHV PHIL TOCO 1/4X1.1/2 AM TRAMON', '82054000', 'UN', 12.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('119979', '7899612795113', 'CHV TEST DIG 12V-220V SPARTA', '90303990', 'UN', 9.90, 5, 9);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('179125', '7898011972996', 'CHV ALLEN JG 10PC 1,5/10MM THOMPSON', '82054000', 'UN', 19.90, 1, 4);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('179124', '7898011972989', 'CHV ALLEN JG 8PC 1,5/6MM THOMPSON', '82054000', 'UN', 11.90, 1, 4);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('179183', '7898011973979', 'CHV ALLEN JG 8PC 1,5/8MM THOMPSON', '82054000', 'UN', 14.90, 1, 4);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('192406', '7899932007880', 'CHV BIELA 10MM FERJA', '82041100', 'UN', 25.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('192407', '7899932007897', 'CHV BIELA 11MM FERJA', '82041100', 'UN', 26.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16795', '7898105776646', 'CHV CANHAO CRV 10MM FAMASTIL', '82041100', 'UN', 31.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('16793', '7898105776592', 'CHV CANHAO CRV 5MM FAMASTIL', '82041100', 'UN', 23.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('192401', '7899932013560', 'CHV COMBINADA 22MM CRV FERJA', '82041100', 'UN', 25.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('190833', '7899932009853', 'CHV ESTRELA 12X13MM FERJA', '82041100', 'UN', 19.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('21535', '7891395014962', 'ESPATULA 2153 5 ACO INOX TIGRE', '82055900', 'UN', 36.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('62151012', '7891395014894', 'ESPATULA 2151 3 ACO POLIDO TIGRE', '82055900', 'UN', 17.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('971568', '7899389012000', 'ESPATULA ACO 12 - 857 CONDOR', '82055900', 'UN', 15.90, 3, 5);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('970219', '7899389000953', 'ESPATULA ACO INOX MULTIUSO 145 CONDOR', '82055900', 'UN', 16.90, 3, 5);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('179149', '7898011971623', 'ALIC BICO RETO 6 NIQ THOMPSON', '82032010', 'UN', 30.90, 1, 4);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('10784', '7898105775830', 'ALIC BOMBA D AGUA 10 FAMASTIL', '82032010', 'UN', 47.90, 1, 2);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('190130', '7899932000706', 'ALIC CORTE DIAG 5 PRO FERJA', '82032010', 'UN', 25.90, 1, 3);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('166125', '7891114008869', 'ALIC UNIV 8 1000V 41001 TRAMON', '82032010', 'UN', 55.90, 1, 1);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('61375090', '7891395040039', 'ROLO LA SINT 1375 9 ANTIRRESP TIGRE', '96034010', 'UN', 17.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('14589', '7891395047625', 'ROLO LA SINT 1377 5CM TIGRE', '96034010', 'UN', 6.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('970207', '7899389000823', 'ROLO LA SINT 15CM C/SUP Z/GOTAS CONDOR', '96034010', 'UN', 16.90, 3, 5);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('970204', '7899389000786', 'ROLO LA SINT 23CM S/S Z/GOTAS CONDOR', '96034010', 'UN', 21.90, 3, 5);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('61352090', '7891395062796', 'ROLO TEXT 1352 9 TIGRE', '96034010', 'UN', 23.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('917', NULL, 'THINNER 16 ITAQUA 18L', '38140090', 'UN', 333.90, 4, 10);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('152115', '7898941765057', 'THINNER 16 ITAQUA 900ML', '38140090', 'UN', 20.90, 4, 10);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('449520', '7891567551110', 'THINNER SAYERLACK 900ML', '38140090', 'UN', 20.90, 4, 10);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('PR60.0001', NULL, 'SUVINIL TOQ FSC BR NEVE 18L', '32091010', 'UN', 585.90, 2, 7);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('PR61.0001', '7891260561713', 'SUVINIL TOQ FSC BR NEVE 3,6L', '32091010', 'UN', 169.90, 2, 7);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('PR62.0001', '7891260561706', 'SUVINIL TOQ FSC BR NEVE 900ML', '32091010', 'UN', 57.90, 2, 7);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('62181025', '7891395068125', 'FITA CREPE 24MMX50M TIGRE', '48114110', 'UN', 9.90, 4, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('62181050', '7891395068132', 'FITA CREPE 48MMX50M TIGRE', '48114190', 'UN', 19.90, 4, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('PR882.0001', '7891260250402', 'ESM SUVINIL AGUA ACET BR 3,6L', '32091010', 'UN', 193.90, 2, 7);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('PR883.0001', '7891260250440', 'ESM SUVINIL AGUA ACET BR 900ML', '32091010', 'UN', 67.90, 2, 7);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('06050', NULL, 'BILACOR FOSCO BRANCO 18L', '32091010', 'UN', 341.90, 2, 8);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('769', NULL, 'BILACOR FOSCO BRANCO 3,6L', '32091010', 'UN', 101.90, 2, 8);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('60573006', '7891395004024', 'TRINCHA 573 1.1/2 TIGRE', '96034090', 'UN', 10.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('60573002', '7891395003997', 'TRINCHA 573 1/2 TIGRE', '96034090', 'UN', 4.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('60695006', '7891395061591', 'TRINCHA 695 1.1/2 TIGRE', '96034090', 'UN', 6.90, 3, 6);
INSERT INTO produto (codigo_interno, codigo_barras, descricao, ncm, unidade_medida, preco_unitario, id_categoria, id_fornecedor) VALUES ('60695002', '7891395061560', 'TRINCHA 695 1/2 TIGRE', '96034090', 'UN', 3.90, 3, 6);

-- Clientes
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Marcos Aurelio Ribeiro', 'PF', '12345678901', '(11) 98765-4321', 'marcos.ribeiro@email.com', 'Rua das Palmeiras, 120 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Construtora Horizonte Ltda', 'PJ', '12345678000199', '(11) 3344-5566', 'compras@horizonteconstrutora.com.br', 'Av. Industrial, 900 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Fernanda Costa Lima', 'PF', '23456789012', '(11) 91234-5678', 'fernanda.lima@email.com', 'Rua Sete de Setembro, 45 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Jose Carlos Pereira', 'PF', '34567890123', '(11) 99876-1234', 'jc.pereira@email.com', 'Rua Bento Freitas, 78 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Pinturas Rapidas ME', 'PJ', '23456789000188', '(11) 2233-4455', 'contato@pinturasrapidas.com.br', 'Rua dos Pintores, 210 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Ana Paula Souza', 'PF', '45678901234', '(11) 98888-2222', 'ana.souza@email.com', 'Alameda das Rosas, 33 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Reformas Silva & Filhos', 'PJ', '34567890000177', '(11) 3322-1100', 'atendimento@reformassilva.com.br', 'Rua da Reforma, 15 - Sao Paulo/SP');
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco) VALUES ('Roberto Almeida Santos', 'PF', '56789012345', '(11) 97777-3333', 'roberto.santos@email.com', 'Rua Voluntarios da Patria, 500 - Sao Paulo/SP');

-- Funcionarios
INSERT INTO funcionario (nome, cargo, cpf, data_admissao) VALUES ('Camila Fernandes', 'Vendedora', '11122233344', '2023-02-01');
INSERT INTO funcionario (nome, cargo, cpf, data_admissao) VALUES ('Bruno Henrique Tavares', 'Vendedor', '22233344455', '2022-08-15');
INSERT INTO funcionario (nome, cargo, cpf, data_admissao) VALUES ('Patricia Gomes', 'Caixa', '33344455566', '2024-01-10');
INSERT INTO funcionario (nome, cargo, cpf, data_admissao) VALUES ('Eduardo Martins', 'Gerente de Loja', '44455566677', '2020-05-20');
INSERT INTO funcionario (nome, cargo, cpf, data_admissao) VALUES ('Larissa Oliveira', 'Vendedora', '55566677788', '2024-06-01');

-- Estoque (um registro por produto)
-- Observacao: a quantidade inicial simula o recebimento de mercadoria do
-- fornecedor ANTES do periodo de vendas de exemplo. Como os triggers da
-- Secao 1.5 debitam o estoque automaticamente a cada item_venda de uma
-- venda CONCLUIDA inserido mais abaixo, o valor abaixo ja inclui uma folga
-- (consumo futuro + margem aleatoria) para nunca violar a CHECK de estoque >= 0.
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (1, 34, 10, 'Deposito A - Prateleira 5');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (2, 17, 10, 'Deposito A - Prateleira 12');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (3, 15, 10, 'Deposito A - Prateleira 7');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (4, 41, 15, 'Deposito A - Prateleira 4');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (5, 55, 15, 'Deposito A - Prateleira 14');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (6, 29, 5, 'Deposito A - Prateleira 6');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (7, 37, 10, 'Deposito A - Prateleira 1');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (8, 32, 15, 'Deposito A - Prateleira 11');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (9, 62, 15, 'Deposito A - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (10, 44, 5, 'Deposito A - Prateleira 4');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (11, 58, 5, 'Deposito A - Prateleira 16');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (12, 38, 5, 'Deposito A - Prateleira 15');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (13, 58, 10, 'Deposito A - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (14, 39, 5, 'Deposito A - Prateleira 7');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (15, 61, 10, 'Deposito A - Prateleira 9');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (16, 18, 10, 'Deposito A - Prateleira 12');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (17, 75, 10, 'Deposito A - Prateleira 18');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (18, 52, 5, 'Deposito A - Prateleira 4');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (19, 43, 5, 'Deposito A - Prateleira 19');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (20, 44, 5, 'Deposito A - Prateleira 4');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (21, 65, 10, 'Deposito A - Prateleira 11');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (22, 65, 15, 'Deposito A - Prateleira 17');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (23, 24, 10, 'Deposito A - Prateleira 19');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (24, 34, 10, 'Deposito A - Prateleira 2');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (25, 74, 5, 'Deposito A - Prateleira 17');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (26, 78, 15, 'Deposito A - Prateleira 7');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (27, 56, 10, 'Deposito A - Prateleira 3');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (28, 52, 15, 'Deposito A - Prateleira 11');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (29, 25, 15, 'Deposito E - Prateleira 10');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (30, 74, 10, 'Deposito A - Prateleira 14');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (31, 59, 10, 'Deposito A - Prateleira 10');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (32, 80, 5, 'Deposito A - Prateleira 7');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (33, 69, 15, 'Deposito A - Prateleira 13');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (34, 32, 15, 'Deposito A - Prateleira 19');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (35, 53, 10, 'Deposito A - Prateleira 18');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (36, 10, 10, 'Deposito A - Prateleira 10');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (37, 38, 10, 'Deposito A - Prateleira 19');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (38, 57, 10, 'Deposito A - Prateleira 15');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (39, 69, 15, 'Deposito C - Prateleira 7');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (40, 75, 10, 'Deposito C - Prateleira 6');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (41, 23, 10, 'Deposito C - Prateleira 17');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (42, 52, 5, 'Deposito C - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (43, 49, 5, 'Deposito A - Prateleira 7');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (44, 28, 5, 'Deposito A - Prateleira 2');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (45, 41, 10, 'Deposito A - Prateleira 20');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (46, 25, 10, 'Deposito A - Prateleira 14');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (47, 34, 15, 'Deposito C - Prateleira 13');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (48, 73, 10, 'Deposito C - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (49, 32, 15, 'Deposito C - Prateleira 1');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (50, 23, 10, 'Deposito C - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (51, 32, 15, 'Deposito C - Prateleira 17');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (52, 75, 5, 'Deposito D - Prateleira 18');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (53, 45, 5, 'Deposito D - Prateleira 15');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (54, 27, 10, 'Deposito D - Prateleira 17');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (55, 51, 10, 'Deposito B - Prateleira 20');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (56, 78, 10, 'Deposito B - Prateleira 18');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (57, 72, 5, 'Deposito B - Prateleira 16');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (58, 67, 10, 'Deposito D - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (59, 45, 15, 'Deposito D - Prateleira 16');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (60, 40, 10, 'Deposito B - Prateleira 15');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (61, 19, 15, 'Deposito B - Prateleira 10');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (62, 40, 10, 'Deposito B - Prateleira 11');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (63, 55, 15, 'Deposito B - Prateleira 3');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (64, 27, 5, 'Deposito C - Prateleira 8');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (65, 60, 15, 'Deposito C - Prateleira 5');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (66, 37, 5, 'Deposito C - Prateleira 14');
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES (67, 62, 10, 'Deposito C - Prateleira 18');

-- Vendas (o trigger trg_item_venda_after_insert ja debita o estoque
-- automaticamente para toda venda inserida com status_venda = 'CONCLUIDA')
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (4, 4, '2026-02-05 14:00:00', 'CONCLUIDA', 1148.60);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (1, 1, '2026-07-05 11:30:00', 'CONCLUIDA', 2003.40);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (6, 1, '2026-01-05 11:00:00', 'CANCELADA', 60.60);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (3, 3, '2026-02-12 14:30:00', 'ORCAMENTO', 422.70);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (2, 2, '2026-04-12 11:00:00', 'CONCLUIDA', 287.40);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (7, 1, '2026-05-12 14:00:00', 'CONCLUIDA', 94.30);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (8, 3, '2026-05-12 11:00:00', 'CONCLUIDA', 383.60);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (1, 3, '2026-02-19 14:00:00', 'CONCLUIDA', 249.50);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (8, 5, '2026-05-26 09:00:00', 'CANCELADA', 24.70);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (2, 5, '2026-03-26 09:30:00', 'CONCLUIDA', 47.60);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (2, 5, '2026-05-19 11:00:00', 'CANCELADA', 152.60);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (6, 3, '2026-04-12 16:30:00', 'CONCLUIDA', 95.30);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (3, 3, '2026-06-12 11:00:00', 'ORCAMENTO', 188.80);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (4, 5, '2026-04-26 11:00:00', 'CANCELADA', 128.20);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (3, 4, '2026-04-05 11:30:00', 'CONCLUIDA', 141.00);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (2, 5, '2026-06-19 16:00:00', 'CONCLUIDA', 211.30);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (6, 2, '2026-02-26 14:00:00', 'CONCLUIDA', 262.20);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (7, 3, '2026-01-12 14:30:00', 'CONCLUIDA', 26.70);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (3, 3, '2026-02-12 14:00:00', 'CONCLUIDA', 875.40);
INSERT INTO venda (id_cliente, id_funcionario, data_venda, status_venda, valor_total) VALUES (2, 1, '2026-01-19 09:00:00', 'ORCAMENTO', 74.00);

-- Itens de venda
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (1, 25, 4, 10.50);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (1, 13, 4, 22.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (1, 56, 4, 169.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (1, 46, 6, 55.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (2, 52, 6, 333.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (3, 25, 2, 10.50);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (3, 58, 4, 9.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (4, 32, 1, 14.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (4, 10, 6, 15.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (4, 57, 5, 57.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (4, 13, 1, 22.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (5, 53, 4, 20.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (5, 63, 2, 101.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (6, 49, 4, 16.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (6, 1, 3, 8.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (7, 63, 2, 101.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (7, 20, 1, 7.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (7, 25, 5, 10.50);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (7, 38, 6, 19.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (8, 7, 5, 49.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (9, 8, 1, 10.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (9, 66, 2, 6.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (10, 31, 4, 11.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (11, 6, 4, 8.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (11, 11, 6, 19.50);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (12, 41, 3, 15.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (12, 31, 4, 11.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (13, 41, 5, 15.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (13, 10, 5, 15.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (13, 2, 1, 9.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (13, 59, 1, 19.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (14, 17, 2, 5.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (14, 45, 3, 25.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (14, 9, 3, 12.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (15, 2, 2, 9.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (15, 39, 3, 36.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (15, 14, 1, 10.50);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (16, 35, 5, 31.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (16, 37, 2, 25.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (17, 65, 1, 4.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (17, 63, 1, 101.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (17, 33, 6, 25.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (18, 1, 3, 8.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (19, 57, 5, 57.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (19, 55, 1, 585.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (20, 5, 5, 7.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (20, 48, 5, 6.90);

-- Pagamentos (apenas vendas concluidas ou canceladas ja teriam sido pagas antes do cancelamento; orcamento ainda nao gera pagamento)
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (1, 'CARTAO_DEBITO', 1148.60, '2026-02-05 14:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (2, 'CARTAO_DEBITO', 2003.40, '2026-07-05 11:30:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (3, 'DINHEIRO', 60.60, '2026-01-05 11:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (5, 'PIX', 287.40, '2026-04-12 11:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (6, 'CARTAO_DEBITO', 94.30, '2026-05-12 14:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (7, 'CARTAO_DEBITO', 383.60, '2026-05-12 11:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (8, 'BOLETO', 249.50, '2026-02-19 14:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (9, 'DINHEIRO', 24.70, '2026-05-26 09:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (10, 'BOLETO', 47.60, '2026-03-26 09:30:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (11, 'CARTAO_DEBITO', 152.60, '2026-05-19 11:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (12, 'CARTAO_DEBITO', 95.30, '2026-04-12 16:30:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (14, 'DINHEIRO', 128.20, '2026-04-26 11:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (15, 'CARTAO_CREDITO', 141.00, '2026-04-05 11:30:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (16, 'CARTAO_DEBITO', 211.30, '2026-06-19 16:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (17, 'CARTAO_DEBITO', 262.20, '2026-02-26 14:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (18, 'BOLETO', 26.70, '2026-01-12 14:30:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES (19, 'BOLETO', 875.40, '2026-02-12 14:00:00', 1);

-- =====================================================================
-- 3. CONSULTAS COM JOIN (agora encapsuladas como VIEWS - ver Secao 1.6)
-- =====================================================================

-- 3.1 Lista de vendas com cliente e vendedor
SELECT * FROM vw_vendas_detalhado ORDER BY data_venda;

-- 3.2 Detalhe de itens de cada venda com produto, categoria e fornecedor
SELECT * FROM vw_itens_venda_detalhado ORDER BY id_venda;

-- 3.3 Situacao de estoque por produto, categoria e fornecedor
SELECT * FROM vw_estoque_situacao ORDER BY nome_categoria, descricao;

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
