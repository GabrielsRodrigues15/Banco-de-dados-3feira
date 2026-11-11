-- =====================================================================
-- PROJETO: Maximo das Tintas - Sistema de Gestao (loja de tintas e materiais de construcao)
-- Testado em MySQL 8.0.46 a partir de banco vazio, sem erros (requer MySQL 8.0.16+)
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
--   mysql -u seu_usuario -p --default-character-set=utf8mb4 < docs/script.sql
-- =====================================================================

-- =====================================================================
-- BANCO DE DADOS: loja_tintas_materiais
-- Sistema de gestao para loja de tintas e materiais de construcao
-- =====================================================================

DROP DATABASE IF EXISTS loja_tintas_materiais;
CREATE DATABASE loja_tintas_materiais CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE loja_tintas_materiais;


-- =====================================================================
-- Maximo das Tintas - 02 CREATE TABLE (9 tabelas, PK, FK, UNIQUE, NOT NULL, CHECK)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
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
    CONSTRAINT uq_fornecedor_cnpj UNIQUE (cnpj),
    CONSTRAINT chk_fornecedor_cnpj CHECK (cnpj REGEXP '^[0-9]{14}$')                      -- RN11
) ENGINE=InnoDB;

CREATE TABLE produto (
    id_produto       INT AUTO_INCREMENT PRIMARY KEY,
    codigo_interno   VARCHAR(20) NOT NULL,
    codigo_barras    VARCHAR(20),
    descricao        VARCHAR(150) NOT NULL,
    ncm              VARCHAR(10),
    unidade_medida   VARCHAR(5) NOT NULL DEFAULT 'UN',
    preco_unitario   DECIMAL(10,2) NOT NULL,
    preco_custo      DECIMAL(10,2),                 -- valor de custo (o sistema da loja ja guarda; RN16)
    id_categoria     INT NOT NULL,
    id_fornecedor    INT NOT NULL,
    ativo            TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT uq_produto_codigo UNIQUE (codigo_interno),
    CONSTRAINT chk_produto_preco CHECK (preco_unitario >= 0),
    CONSTRAINT chk_produto_custo CHECK (preco_custo IS NULL OR preco_custo >= 0),
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
    CONSTRAINT uq_cliente_doc UNIQUE (cpf_cnpj),                                          -- RN11
    -- RN11: PF tem CPF com 11 digitos; PJ tem CNPJ com 14 digitos (somente numeros)
    CONSTRAINT chk_cliente_doc CHECK (
        (tipo_pessoa = 'PF' AND cpf_cnpj REGEXP '^[0-9]{11}$') OR
        (tipo_pessoa = 'PJ' AND cpf_cnpj REGEXP '^[0-9]{14}$'))
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
    valor_desconto   DECIMAL(10,2) NOT NULL DEFAULT 0, -- desconto de 5% no PIX (RN19)
    valor_total      DECIMAL(10,2) NOT NULL DEFAULT 0, -- soma dos itens - desconto (RN05)
    CONSTRAINT chk_venda_total CHECK (valor_total >= 0),
    CONSTRAINT chk_venda_desconto CHECK (valor_desconto >= 0),
    CONSTRAINT fk_venda_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_venda_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario),
    -- indices para as consultas gerenciais por periodo e por status (RNF05)
    INDEX ix_venda_data (data_venda),
    INDEX ix_venda_status_data (status_venda, data_venda)
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
    CONSTRAINT chk_pagamento_parcelas CHECK (parcelas BETWEEN 1 AND 24),   -- RN20: limite de 24x no credito
    CONSTRAINT fk_pagamento_venda FOREIGN KEY (id_venda) REFERENCES venda(id_venda)
) ENGINE=InnoDB;

-- historico de reajustes de preco (relatorio pedido pela loja: "aumento de preco de produtos")
-- preenchido automaticamente pelo trigger trg_produto_after_update_preco (RN21)
CREATE TABLE historico_preco (
    id_historico     INT AUTO_INCREMENT PRIMARY KEY,
    id_produto       INT NOT NULL,
    preco_anterior   DECIMAL(10,2) NOT NULL,
    preco_novo       DECIMAL(10,2) NOT NULL,
    data_alteracao   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_historico_precos CHECK (preco_anterior >= 0 AND preco_novo >= 0 AND preco_anterior <> preco_novo),
    CONSTRAINT fk_historico_produto FOREIGN KEY (id_produto) REFERENCES produto(id_produto),
    INDEX ix_historico_data (data_alteracao)
) ENGINE=InnoDB;

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

-- RN21: todo reajuste de preco fica registrado em historico_preco
CREATE TRIGGER trg_produto_after_update_preco
AFTER UPDATE ON produto
FOR EACH ROW
BEGIN
    IF NEW.preco_unitario <> OLD.preco_unitario THEN
        INSERT INTO historico_preco (id_produto, preco_anterior, preco_novo)
        VALUES (NEW.id_produto, OLD.preco_unitario, NEW.preco_unitario);
    END IF;
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
    v.data_venda, v.status_venda, v.valor_desconto, v.valor_total
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
-- Maximo das Tintas - 04 Massa de dados ficticia (INSERT)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- GERADO por entrega-2/scripts/gerar_massa.py (semente 20261109) - nao editar a mao.
-- =====================================================================
USE loja_tintas_materiais;

-- Como o volume foi calibrado (entrevista de 07/11/2026 com a responsavel financeira):
--   faturamento de R$ 300 a 500 por dia (~R$ 10 mil/mes), 100 a 120 produtos por mes,
--   2 funcionarios + 1 intermediario, desconto de 5% no PIX, parcelamento 2x a partir
--   de R$ 200 e 3x a partir de R$ 400, boleto para obras parceiras, catalogo do PDV.
-- Periodo simulado: 02/01/2026 a 30/06/2026 (segunda a sabado; domingo fechado).
-- Resultado desta massa (vendas CONCLUIDAS):
--   01/2026:  74 vendas concluidas | R$  10871.54 |  117 unidades
--   02/2026:  60 vendas concluidas | R$   8995.30 |   87 unidades
--   03/2026:  73 vendas concluidas | R$   8742.37 |  103 unidades
--   04/2026:  84 vendas concluidas | R$  11682.61 |  113 unidades
--   05/2026:  79 vendas concluidas | R$  13263.68 |  118 unidades
--   06/2026:  66 vendas concluidas | R$   6774.39 |   83 unidades
-- Totais: 467 vendas (436 concluidas, 18 canceladas,
--         13 orcamentos), 580 itens, 449 pagamentos,
--         121 clientes (10 sem compras), 3 funcionarios.
-- Dados pessoais 100% ficticios. Produtos, codigos, EAN e NCM: reais (listas do PDV).

-- ---------------------------------------------------------------------
-- Catalogo real da loja
-- ---------------------------------------------------------------------
-- Categorias
INSERT INTO categoria (nome_categoria) VALUES ('Ferramentas Manuais');
INSERT INTO categoria (nome_categoria) VALUES ('Tintas e Vernizes');
INSERT INTO categoria (nome_categoria) VALUES ('Pinceis, Rolos e Espatulas');
INSERT INTO categoria (nome_categoria) VALUES ('Acessorios de Pintura');
INSERT INTO categoria (nome_categoria) VALUES ('Instrumentos de Medicao');

-- Fornecedores (marcas reais; CNPJ, telefone e e-mail ficticios)
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

-- Produtos (67 itens reais das listas de preco do PDV; preco = preco vigente apos o reajuste de abril)
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

-- ---------------------------------------------------------------------
-- Pessoas (ficticias)
-- ---------------------------------------------------------------------
INSERT INTO funcionario (nome, cargo, cpf, data_admissao, ativo) VALUES
  ('Rogerio Almeida Prado', 'Vendedor e atendimento', '41592630817', '2023-03-13', 1),
  ('Tatiane Moura Ribeiro', 'Vendedora e atendimento', '52748193604', '2024-02-05', 1),
  ('Diego Santana Lopes', 'Auxiliar (intermediario)', '63815274930', '2025-08-04', 1);

-- id 1 = "Consumidor final": venda de balcao sem cadastro (RN14)
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj, telefone, email, endereco, data_cadastro) VALUES
  ('Consumidor final (venda de balcao sem cadastro)', 'PF', '00000000000', NULL, NULL, NULL, '2026-01-02'),
  ('Denise Silva Silva', 'PF', '27752469039', '(11) 94698-4185', 'denise.silva30@email.com', 'Rua Azurita, 321 - Sao Paulo/SP', '2024-03-11'),
  ('Vanessa Lima Barbosa', 'PF', '33850905026', '(11) 99840-6269', 'vanessa.barbosa17@email.com', 'Rua Santa Marcelina, 15 - Sao Paulo/SP', '2025-09-27'),
  ('Bruno Araujo Carvalho', 'PF', '51035334930', '(11) 96839-8840', NULL, 'Rua Melo Freire, 278 - Sao Paulo/SP', '2025-11-15'),
  ('Renato Gomes Ribeiro', 'PF', '60236947578', '(11) 93103-9820', 'renato.ribeiro72@email.com', 'Rua das Acacias, 678 - Sao Paulo/SP', '2024-12-04'),
  ('Wagner Teixeira Barbosa', 'PF', '89283847684', '(11) 91144-5938', NULL, 'Av. Itaquera, 1314 - Sao Paulo/SP', '2024-11-24'),
  ('Nelson Araujo Costa', 'PF', '21857503968', '(11) 95105-3272', 'nelson.costa79@email.com', 'Rua das Flores, 199 - Sao Paulo/SP', '2024-11-29'),
  ('Mariana Barbosa Martins', 'PF', '11974122802', '(11) 96476-8841', 'mariana.martins19@email.com', 'Av. Itaquera, 889 - Sao Paulo/SP', '2025-04-12'),
  ('Eduarda Moreira Souza', 'PF', '01757098632', '(11) 97479-3726', 'eduarda.souza63@email.com', NULL, '2024-10-18'),
  ('Caio Dias Barbosa', 'PF', '69891340780', '(11) 94565-4525', 'caio.barbosa25@email.com', 'Rua do Comercio, 435 - Sao Paulo/SP', '2023-12-04'),
  ('Fernanda Martins Souza', 'PF', '12734865724', '(11) 97036-5353', NULL, 'Av. Aricanduva, 268 - Sao Paulo/SP', '2024-04-13'),
  ('Thiago Silva Lima', 'PF', '08452163477', '(11) 99611-6198', 'thiago.lima85@email.com', 'Av. Itaquera, 1479 - Sao Paulo/SP', '2023-10-28'),
  ('Thiago Rocha Costa', 'PF', '16408403401', '(11) 92081-5461', 'thiago.costa69@email.com', NULL, '2024-06-27'),
  ('Silvia Souza Rocha', 'PF', '76173101747', '(11) 96369-9491', NULL, NULL, '2025-10-20'),
  ('Andre Oliveira Almeida', 'PF', '15097091986', '(11) 94515-5705', 'andre.almeida49@email.com', 'Rua do Comercio, 780 - Sao Paulo/SP', '2024-03-25'),
  ('Rafael Oliveira Silva', 'PF', '95674650779', '(11) 96333-5736', 'rafael.silva57@email.com', 'Rua do Comercio, 1421 - Sao Paulo/SP', '2024-06-28'),
  ('Eduarda Carvalho Teixeira', 'PF', '79486929101', '(11) 91393-1325', 'eduarda.teixeira22@email.com', 'Rua Padre Anchieta, 584 - Sao Paulo/SP', '2025-02-17'),
  ('Fernanda Pereira Lima', 'PF', '16993036447', '(11) 94032-4525', NULL, NULL, '2024-01-09'),
  ('Isabela Oliveira Lima', 'PF', '77130308603', '(11) 99624-9932', 'isabela.lima73@email.com', NULL, '2025-09-07'),
  ('Karina Gomes Souza', 'PF', '73062135112', '(11) 96449-5384', 'karina.souza61@email.com', NULL, '2025-12-10'),
  ('Vanessa Nascimento Almeida', 'PF', '55959463006', '(11) 97214-8002', 'vanessa.almeida52@email.com', NULL, '2025-05-29'),
  ('Caio Barbosa Souza', 'PF', '38579654312', '(11) 96277-6996', 'caio.souza65@email.com', NULL, '2025-06-06'),
  ('Beatriz Santos Teixeira', 'PF', '10004761344', '(11) 92543-9749', 'beatriz.teixeira90@email.com', NULL, '2024-06-20'),
  ('Isabela Santos Teixeira', 'PF', '15469531320', '(11) 94521-3053', NULL, 'Rua Padre Anchieta, 285 - Sao Paulo/SP', '2024-04-15'),
  ('Eduarda Barbosa Ribeiro', 'PF', '84531189132', '(11) 96884-7503', 'eduarda.ribeiro28@email.com', 'Av. Aricanduva, 1362 - Sao Paulo/SP', '2024-09-16'),
  ('Marcia Costa Costa', 'PF', '62366049280', '(11) 94726-8968', NULL, NULL, '2025-02-20'),
  ('Henrique Ribeiro Lima', 'PF', '28365213017', '(11) 93424-4794', NULL, NULL, '2023-10-09'),
  ('Igor Dias Costa', 'PF', '18831071081', '(11) 97105-9434', 'igor.costa23@email.com', NULL, '2024-06-12'),
  ('Rafael Oliveira Carvalho', 'PF', '29424244300', '(11) 91506-2131', 'rafael.carvalho43@email.com', 'Rua Melo Freire, 1495 - Sao Paulo/SP', '2023-08-27'),
  ('Daniel Moreira Nascimento', 'PF', '26186500842', '(11) 91388-5969', NULL, 'Rua Coronel Santos, 325 - Sao Paulo/SP', '2023-08-16'),
  ('Vitor Ribeiro Ribeiro', 'PF', '50181351019', '(11) 98632-6871', 'vitor.ribeiro97@email.com', NULL, '2023-10-18'),
  ('Isabela Lima Costa', 'PF', '27482469693', '(11) 91846-9560', NULL, NULL, '2025-12-29'),
  ('Igor Barbosa Souza', 'PF', '65030639098', '(11) 95027-5902', NULL, 'Rua Padre Anchieta, 244 - Sao Paulo/SP', '2024-11-07'),
  ('Paulo Gomes Almeida', 'PF', '87395578191', '(11) 98756-9432', 'paulo.almeida47@email.com', 'Rua Azurita, 670 - Sao Paulo/SP', '2025-08-17'),
  ('Yasmin Martins Gomes', 'PF', '03807554671', '(11) 92171-6260', 'yasmin.gomes89@email.com', 'Rua Coronel Santos, 1438 - Sao Paulo/SP', '2025-05-12'),
  ('Henrique Teixeira Moreira', 'PF', '76750116113', '(11) 99446-5278', NULL, 'Rua Santa Marcelina, 435 - Sao Paulo/SP', '2023-08-07'),
  ('Gustavo Martins Souza', 'PF', '05432694003', '(11) 94496-8238', 'gustavo.souza99@email.com', NULL, '2025-07-08'),
  ('Leandro Santos Moreira', 'PF', '63017611774', '(11) 93827-7171', 'leandro.moreira40@email.com', NULL, '2023-09-29'),
  ('Lucas Gomes Oliveira', 'PF', '86762106976', '(11) 93672-4697', NULL, NULL, '2023-09-04'),
  ('Rafael Souza Moreira', 'PF', '74023172928', '(11) 92046-6973', NULL, 'Rua Santa Marcelina, 518 - Sao Paulo/SP', '2025-06-17'),
  ('Lucas Silva Lima', 'PF', '22392890760', '(11) 98042-3077', NULL, 'Rua Sao Jorge, 438 - Sao Paulo/SP', '2023-08-27'),
  ('Ana Araujo Barbosa', 'PF', '39404620576', '(11) 92190-2756', 'ana.barbosa7@email.com', 'Rua Tuiuti, 300 - Sao Paulo/SP', '2025-04-13'),
  ('Bruno Lima Lima', 'PF', '41929307151', '(11) 97545-5685', 'bruno.lima53@email.com', NULL, '2025-05-19'),
  ('Renato Almeida Lima', 'PF', '99923449088', '(11) 98369-9197', 'renato.lima88@email.com', NULL, '2023-12-31'),
  ('Caio Araujo Barbosa', 'PF', '93620136049', '(11) 91256-7114', 'caio.barbosa3@email.com', NULL, '2025-12-25'),
  ('Helena Souza Carvalho', 'PF', '28370867983', '(11) 95574-4328', 'helena.carvalho1@email.com', 'Av. Itaquera, 1127 - Sao Paulo/SP', '2024-05-25'),
  ('Rafael Teixeira Araujo', 'PF', '71568572417', '(11) 93827-3742', 'rafael.araujo68@email.com', 'Rua das Acacias, 100 - Sao Paulo/SP', '2025-06-01'),
  ('Fernanda Rodrigues Santos', 'PF', '26265078806', '(11) 95099-3116', 'fernanda.santos1@email.com', NULL, '2023-11-21'),
  ('Otavio Barbosa Nascimento', 'PF', '16807170532', '(11) 91490-2264', 'otavio.nascimento59@email.com', 'Rua das Flores, 358 - Sao Paulo/SP', '2025-01-01'),
  ('Beatriz Teixeira Oliveira', 'PF', '14261631036', '(11) 92131-7642', NULL, NULL, '2024-06-26'),
  ('Mariana Moreira Silva', 'PF', '04811572706', '(11) 97335-9790', NULL, 'Av. Itaquera, 216 - Sao Paulo/SP', '2023-11-19'),
  ('Thiago Barbosa Araujo', 'PF', '29191657822', '(11) 94401-7593', 'thiago.araujo86@email.com', NULL, '2025-09-26'),
  ('Igor Rodrigues Almeida', 'PF', '87898335686', '(11) 96920-6614', 'igor.almeida90@email.com', 'Rua Padre Anchieta, 272 - Sao Paulo/SP', '2024-10-20'),
  ('Helena Lima Rodrigues', 'PF', '73298128122', '(11) 96777-8577', 'helena.rodrigues87@email.com', NULL, '2023-08-21'),
  ('Andre Gomes Rodrigues', 'PF', '66787900909', '(11) 91770-7766', 'andre.rodrigues54@email.com', 'Rua das Flores, 389 - Sao Paulo/SP', '2025-02-27'),
  ('Rafael Nascimento Barbosa', 'PF', '03646104222', '(11) 99844-6341', 'rafael.barbosa34@email.com', 'Rua das Flores, 1361 - Sao Paulo/SP', '2025-06-22'),
  ('Beatriz Martins Pereira', 'PF', '32892890475', '(11) 96940-8165', 'beatriz.pereira51@email.com', NULL, '2023-08-20'),
  ('Nelson Silva Costa', 'PF', '66190559528', '(11) 94983-7361', 'nelson.costa30@email.com', NULL, '2023-09-14'),
  ('Carla Araujo Araujo', 'PF', '99323201630', '(11) 98333-6601', 'carla.araujo91@email.com', NULL, '2023-12-12'),
  ('Sabrina Rocha Silva', 'PF', '92845097447', '(11) 99896-9265', 'sabrina.silva17@email.com', 'Rua Melo Freire, 1210 - Sao Paulo/SP', '2024-03-08'),
  ('Henrique Almeida Nascimento', 'PF', '02684405485', '(11) 96398-2397', 'henrique.nascimento40@email.com', NULL, '2024-04-11'),
  ('Fernanda Teixeira Almeida', 'PF', '41138394130', '(11) 91221-1536', NULL, 'Rua das Flores, 935 - Sao Paulo/SP', '2025-01-20'),
  ('Silvia Silva Barbosa', 'PF', '62379509648', '(11) 93066-6987', NULL, NULL, '2025-03-02'),
  ('Andre Pereira Araujo', 'PF', '66759292385', '(11) 92487-3682', 'andre.araujo30@email.com', 'Av. Aricanduva, 1378 - Sao Paulo/SP', '2024-11-16'),
  ('Vitor Rodrigues Lima', 'PF', '30365595637', '(11) 94884-1493', 'vitor.lima75@email.com', NULL, '2023-09-19'),
  ('Caio Rocha Araujo', 'PF', '12152647693', '(11) 99730-2400', 'caio.araujo28@email.com', 'Rua do Comercio, 1269 - Sao Paulo/SP', '2025-07-31'),
  ('Juliana Rocha Nascimento', 'PF', '50351667639', '(11) 97352-9930', 'juliana.nascimento6@email.com', NULL, '2024-12-29'),
  ('Silvia Carvalho Ribeiro', 'PF', '15057663575', '(11) 99945-6874', 'silvia.ribeiro79@email.com', NULL, '2025-01-17'),
  ('Rafael Nascimento Santos', 'PF', '91119290237', '(11) 98135-4420', 'rafael.santos49@email.com', NULL, '2025-12-16'),
  ('Leandro Souza Santos', 'PF', '56611468442', '(11) 99762-4278', 'leandro.santos37@email.com', NULL, '2024-09-10'),
  ('Otavio Rodrigues Martins', 'PF', '54315647768', '(11) 99748-5898', NULL, 'Rua Melo Freire, 944 - Sao Paulo/SP', '2024-07-30'),
  ('Eduarda Rocha Santos', 'PF', '61007282980', '(11) 94590-3134', 'eduarda.santos40@email.com', 'Rua das Flores, 503 - Sao Paulo/SP', '2025-08-15'),
  ('Isabela Costa Martins', 'PF', '77597835785', '(11) 95011-7205', 'isabela.martins7@email.com', 'Rua Santa Marcelina, 805 - Sao Paulo/SP', '2024-01-25'),
  ('Vitor Lima Ribeiro', 'PF', '26543227734', '(11) 92700-8270', NULL, 'Rua Coronel Santos, 82 - Sao Paulo/SP', '2024-05-23'),
  ('Daniel Rocha Barbosa', 'PF', '78677137078', '(11) 92196-9530', 'daniel.barbosa2@email.com', 'Rua Coronel Santos, 843 - Sao Paulo/SP', '2025-05-19'),
  ('Lucas Rodrigues Rodrigues', 'PF', '02830467700', '(11) 98502-5640', 'lucas.rodrigues53@email.com', NULL, '2023-12-14'),
  ('Wagner Carvalho Teixeira', 'PF', '81585211916', '(11) 93625-9739', 'wagner.teixeira77@email.com', 'Rua Santa Marcelina, 778 - Sao Paulo/SP', '2025-02-08'),
  ('Sabrina Barbosa Lima', 'PF', '87500108825', '(11) 95962-4654', 'sabrina.lima98@email.com', 'Rua Santa Marcelina, 367 - Sao Paulo/SP', '2025-09-25'),
  ('Wagner Rocha Gomes', 'PF', '97730124692', '(11) 95364-2606', 'wagner.gomes45@email.com', 'Rua Santa Marcelina, 705 - Sao Paulo/SP', '2024-10-11'),
  ('Otavio Rodrigues Teixeira', 'PF', '59721817598', '(11) 92477-8918', NULL, 'Rua Sao Jorge, 1497 - Sao Paulo/SP', '2024-08-02'),
  ('Gabriela Dias Rodrigues', 'PF', '48043888973', '(11) 99667-2345', 'gabriela.rodrigues68@email.com', 'Rua das Flores, 1087 - Sao Paulo/SP', '2025-11-02'),
  ('Ana Martins Pereira', 'PF', '77005297429', '(11) 99611-1764', 'ana.pereira50@email.com', 'Rua Santa Marcelina, 1359 - Sao Paulo/SP', '2024-11-02'),
  ('Yasmin Oliveira Lima', 'PF', '44240034249', '(11) 96686-3181', 'yasmin.lima21@email.com', 'Rua Padre Anchieta, 531 - Sao Paulo/SP', '2025-03-14'),
  ('Igor Gomes Araujo', 'PF', '21688906747', '(11) 95101-3366', 'igor.araujo60@email.com', 'Rua Padre Anchieta, 617 - Sao Paulo/SP', '2025-11-19'),
  ('Marcia Costa Dias', 'PF', '80890631700', '(11) 92313-9949', 'marcia.dias71@email.com', NULL, '2023-10-02'),
  ('Yasmin Rocha Rocha', 'PF', '24659697586', '(11) 94379-6882', 'yasmin.rocha43@email.com', NULL, '2025-05-09'),
  ('Gabriela Souza Silva', 'PF', '72046702132', '(11) 91563-2544', 'gabriela.silva15@email.com', NULL, '2023-11-26'),
  ('Vanessa Dias Carvalho', 'PF', '54710411412', '(11) 98115-2328', 'vanessa.carvalho33@email.com', 'Av. Itaquera, 194 - Sao Paulo/SP', '2025-08-03'),
  ('Gabriela Costa Lima', 'PF', '78990136414', '(11) 99327-5611', NULL, 'Rua do Comercio, 1163 - Sao Paulo/SP', '2023-07-22'),
  ('Sabrina Oliveira Dias', 'PF', '71784384477', '(11) 98389-4060', 'sabrina.dias55@email.com', 'Av. Aricanduva, 1433 - Sao Paulo/SP', '2025-08-07'),
  ('Beatriz Santos Ribeiro', 'PF', '72268470655', '(11) 95192-8181', NULL, 'Rua do Comercio, 607 - Sao Paulo/SP', '2024-07-09'),
  ('Olivia Barbosa Martins', 'PF', '22595433851', '(11) 92169-3503', 'olivia.martins38@email.com', 'Rua Santa Marcelina, 807 - Sao Paulo/SP', '2025-07-19'),
  ('Leandro Rodrigues Rodrigues', 'PF', '40064921886', '(11) 98534-1882', 'leandro.rodrigues20@email.com', NULL, '2024-11-11'),
  ('Daniel Teixeira Lima', 'PF', '15717619023', '(11) 98067-9099', 'daniel.lima26@email.com', NULL, '2024-06-23'),
  ('Nelson Santos Rodrigues', 'PF', '87438093474', '(11) 94563-5143', NULL, NULL, '2023-11-27'),
  ('Elias Rodrigues Costa', 'PF', '87734182485', '(11) 91386-9827', 'elias.costa9@email.com', NULL, '2025-05-31'),
  ('Instaladora Oliveira Servicos ME', 'PJ', '42729199023412', '(11) 4864-2596', 'contato@instaladoraoliveira.com.br', 'Rua Coronel Santos, 1465 - Sao Paulo/SP', '2023-02-11'),
  ('Empreiteira Martins ME', 'PJ', '37243007507968', '(11) 3444-8879', 'contato@empreiteiramartins.com.br', 'Rua Coronel Santos, 306 - Sao Paulo/SP', '2023-11-26'),
  ('Empreiteira Nascimento EIRELI', 'PJ', '82773881289365', '(11) 3660-1305', 'contato@empreiteiranascimento.com.br', 'Av. Aricanduva, 142 - Sao Paulo/SP', '2024-02-20'),
  ('Reformas Barbosa & Filhos Ltda', 'PJ', '41871792957198', '(11) 4312-9727', 'contato@reformasbarbosa.com.br', 'Av. Aricanduva, 1265 - Sao Paulo/SP', '2025-10-22'),
  ('Empreiteira Teixeira EIRELI', 'PJ', '47287987224940', '(11) 3080-9238', 'contato@empreiteirateixeira.com.br', 'Rua das Flores, 424 - Sao Paulo/SP', '2025-07-16'),
  ('Construtora Araujo Servicos ME', 'PJ', '51452327340246', '(11) 4997-2654', 'contato@construtoraaraujo.com.br', 'Rua do Comercio, 1204 - Sao Paulo/SP', '2024-10-12'),
  ('Serralheria Moreira ME', 'PJ', '12147120381256', '(11) 3612-9912', 'contato@serralheriamoreira.com.br', 'Rua das Acacias, 240 - Sao Paulo/SP', '2025-06-14'),
  ('Serralheria Gomes EIRELI', 'PJ', '18391795091006', '(11) 4518-8297', 'contato@serralheriagomes.com.br', 'Rua do Comercio, 355 - Sao Paulo/SP', '2022-12-14'),
  ('Manutencao Predial Rocha EIRELI', 'PJ', '93653537294980', '(11) 2593-5892', 'contato@manutencaorocha.com.br', 'Rua das Acacias, 1181 - Sao Paulo/SP', '2024-12-31'),
  ('Construtora Carvalho EIRELI', 'PJ', '41120115790508', '(11) 4553-7993', 'contato@construtoracarvalho.com.br', 'Av. Aricanduva, 413 - Sao Paulo/SP', '2023-02-19'),
  ('Marcenaria Carvalho ME', 'PJ', '02169724446768', '(11) 2081-2771', 'contato@marcenariacarvalho.com.br', 'Rua das Flores, 656 - Sao Paulo/SP', '2022-11-17'),
  ('Construtora Ribeiro ME', 'PJ', '23266343482053', '(11) 4224-2468', 'contato@construtoraribeiro.com.br', 'Rua Coronel Santos, 42 - Sao Paulo/SP', '2023-02-24'),
  ('Acabamentos Carvalho Ltda', 'PJ', '28866965377900', '(11) 3022-9014', 'contato@acabamentoscarvalho.com.br', 'Rua Azurita, 197 - Sao Paulo/SP', '2025-03-10'),
  ('Serralheria Pereira EIRELI', 'PJ', '18066936054926', '(11) 3311-6317', 'contato@serralheriapereira.com.br', 'Av. Itaquera, 403 - Sao Paulo/SP', '2023-10-03'),
  ('Acabamentos Almeida Servicos ME', 'PJ', '71272182929242', '(11) 2620-4138', 'contato@acabamentosalmeida.com.br', 'Rua das Flores, 1242 - Sao Paulo/SP', '2025-09-27'),
  ('Instaladora Costa ME', 'PJ', '17723406287678', '(11) 2272-8321', 'contato@instaladoracosta.com.br', 'Rua do Comercio, 108 - Sao Paulo/SP', '2023-06-01'),
  ('Construtora Araujo ME', 'PJ', '90006747953931', '(11) 2493-6303', 'contato@construtoraaraujo.com.br', 'Rua Sao Jorge, 762 - Sao Paulo/SP', '2024-10-13'),
  ('Marcenaria Santos Ltda', 'PJ', '76416216782243', '(11) 4858-2798', 'contato@marcenariasantos.com.br', 'Rua Sao Jorge, 241 - Sao Paulo/SP', '2023-10-23'),
  ('Instaladora Pereira & Filhos Ltda', 'PJ', '86837678435038', '(11) 4462-4139', 'contato@instaladorapereira.com.br', 'Rua Santa Marcelina, 746 - Sao Paulo/SP', '2023-07-18'),
  ('Instaladora Rodrigues Servicos ME', 'PJ', '94274449029811', '(11) 3203-5281', 'contato@instaladorarodrigues.com.br', 'Rua das Acacias, 126 - Sao Paulo/SP', '2024-08-25'),
  ('Pinturas Moreira EIRELI', 'PJ', '36657422112316', '(11) 4399-9875', 'contato@pinturasmoreira.com.br', 'Rua Santa Marcelina, 485 - Sao Paulo/SP', '2024-11-17'),
  ('Marcenaria Costa Servicos ME', 'PJ', '58982869944182', '(11) 4284-3086', 'contato@marcenariacosta.com.br', 'Rua Melo Freire, 1137 - Sao Paulo/SP', '2023-08-12'),
  ('Pinturas Carvalho Ltda', 'PJ', '31087419042141', '(11) 2989-9905', 'contato@pinturascarvalho.com.br', 'Rua Padre Anchieta, 256 - Sao Paulo/SP', '2023-11-11'),
  ('Pinturas Moreira & Filhos Ltda', 'PJ', '04339118273415', '(11) 2835-1225', 'contato@pinturasmoreira.com.br', 'Rua do Comercio, 968 - Sao Paulo/SP', '2023-05-22'),
  ('Manutencao Predial Araujo Ltda', 'PJ', '93479872792847', '(11) 4917-8851', 'contato@manutencaoaraujo.com.br', 'Rua Coronel Santos, 1444 - Sao Paulo/SP', '2023-05-02');

-- ---------------------------------------------------------------------
-- Estoque inicial (01/01/2026). Os triggers baixam o estoque a cada item de
-- venda CONCLUIDA inserido abaixo; o saldo inicial foi calculado para que
-- nenhum produto fique negativo e 7 terminem no ponto de reposicao.
-- ---------------------------------------------------------------------
INSERT INTO estoque (id_produto, quantidade_atual, quantidade_minima, localizacao_deposito) VALUES
  (1, 5, 3, 'Deposito A - Prateleira 15'),
  (2, 19, 5, 'Deposito A - Prateleira 20'),
  (3, 11, 5, 'Deposito A - Prateleira 4'),
  (4, 21, 2, 'Deposito A - Prateleira 4'),
  (5, 14, 4, 'Deposito A - Prateleira 9'),
  (6, 7, 5, 'Deposito A - Prateleira 14'),
  (7, 3, 3, 'Deposito A - Prateleira 17'),
  (8, 12, 5, 'Deposito A - Prateleira 9'),
  (9, 20, 6, 'Deposito A - Prateleira 20'),
  (10, 20, 5, 'Deposito A - Prateleira 20'),
  (11, 31, 5, 'Deposito A - Prateleira 5'),
  (12, 19, 4, 'Deposito A - Prateleira 15'),
  (13, 22, 2, 'Deposito A - Prateleira 7'),
  (14, 16, 6, 'Deposito A - Prateleira 5'),
  (15, 16, 4, 'Deposito A - Prateleira 5'),
  (16, 29, 6, 'Deposito A - Prateleira 10'),
  (17, 8, 2, 'Deposito A - Prateleira 19'),
  (18, 13, 6, 'Deposito A - Prateleira 4'),
  (19, 11, 2, 'Deposito A - Prateleira 11'),
  (20, 18, 4, 'Deposito A - Prateleira 5'),
  (21, 9, 6, 'Deposito A - Prateleira 13'),
  (22, 23, 4, 'Deposito A - Prateleira 20'),
  (23, 10, 5, 'Deposito A - Prateleira 4'),
  (24, 10, 4, 'Deposito A - Prateleira 13'),
  (25, 14, 6, 'Deposito A - Prateleira 12'),
  (26, 37, 6, 'Deposito A - Prateleira 1'),
  (27, 5, 3, 'Deposito A - Prateleira 9'),
  (28, 19, 4, 'Deposito A - Prateleira 7'),
  (29, 35, 6, 'Deposito A - Prateleira 6'),
  (30, 25, 6, 'Deposito A - Prateleira 16'),
  (31, 0, 6, 'Deposito A - Prateleira 3'),
  (32, 12, 5, 'Deposito A - Prateleira 17'),
  (33, 45, 2, 'Deposito A - Prateleira 18'),
  (34, 16, 4, 'Deposito A - Prateleira 15'),
  (35, 10, 2, 'Deposito A - Prateleira 17'),
  (36, 23, 6, 'Deposito A - Prateleira 19'),
  (37, 21, 5, 'Deposito A - Prateleira 4'),
  (38, 21, 6, 'Deposito A - Prateleira 6'),
  (39, 15, 2, 'Deposito B - Prateleira 3'),
  (40, 25, 5, 'Deposito B - Prateleira 11'),
  (41, 26, 5, 'Deposito B - Prateleira 3'),
  (42, 16, 3, 'Deposito B - Prateleira 10'),
  (43, 35, 5, 'Deposito A - Prateleira 2'),
  (44, 25, 6, 'Deposito A - Prateleira 12'),
  (45, 32, 2, 'Deposito A - Prateleira 6'),
  (46, 18, 3, 'Deposito A - Prateleira 16'),
  (47, 17, 2, 'Deposito B - Prateleira 9'),
  (48, 0, 2, 'Deposito B - Prateleira 14'),
  (49, 16, 2, 'Deposito B - Prateleira 4'),
  (50, 9, 3, 'Deposito B - Prateleira 5'),
  (51, 20, 4, 'Deposito B - Prateleira 14'),
  (52, 17, 2, 'Deposito B - Prateleira 4'),
  (53, 8, 4, 'Deposito B - Prateleira 15'),
  (54, 24, 5, 'Deposito B - Prateleira 1'),
  (55, 54, 2, 'Deposito B - Prateleira 6'),
  (56, 39, 2, 'Deposito B - Prateleira 10'),
  (57, 42, 6, 'Deposito B - Prateleira 9'),
  (58, 20, 5, 'Deposito B - Prateleira 19'),
  (59, 17, 6, 'Deposito B - Prateleira 13'),
  (60, 26, 2, 'Deposito B - Prateleira 20'),
  (61, 61, 4, 'Deposito B - Prateleira 2'),
  (62, 45, 2, 'Deposito B - Prateleira 20'),
  (63, 41, 4, 'Deposito B - Prateleira 11'),
  (64, 9, 2, 'Deposito B - Prateleira 8'),
  (65, 15, 3, 'Deposito B - Prateleira 2'),
  (66, 16, 6, 'Deposito B - Prateleira 7'),
  (67, 18, 3, 'Deposito B - Prateleira 3');

-- ---------------------------------------------------------------------
-- Vendas, itens e pagamentos (jan a jun/2026)
-- Tintas vendidas antes de 01/04/2026 usam o preco anterior ao reajuste (RN04).
-- ---------------------------------------------------------------------
INSERT INTO venda (id_venda, id_cliente, id_funcionario, data_venda, status_venda, valor_desconto, valor_total) VALUES
  (1, 79, 2, '2026-01-02 08:15:00', 'CONCLUIDA', 0.90, 17.00),
  (2, 70, 2, '2026-01-03 11:30:00', 'CONCLUIDA', 9.23, 175.47),
  (3, 1, 3, '2026-01-03 09:35:00', 'CONCLUIDA', 0.00, 49.90),
  (4, 1, 1, '2026-01-03 09:05:00', 'CONCLUIDA', 0.00, 21.90),
  (5, 1, 2, '2026-01-03 09:00:00', 'CONCLUIDA', 0.00, 19.50),
  (6, 1, 2, '2026-01-05 10:35:00', 'CONCLUIDA', 0.00, 95.80),
  (7, 1, 2, '2026-01-05 09:00:00', 'CANCELADA', 0.00, 31.90),
  (8, 1, 3, '2026-01-06 12:45:00', 'CONCLUIDA', 1.15, 21.75),
  (9, 1, 2, '2026-01-07 16:15:00', 'CONCLUIDA', 27.90, 530.10),
  (10, 1, 1, '2026-01-07 10:50:00', 'CONCLUIDA', 0.84, 16.06),
  (11, 1, 1, '2026-01-07 17:30:00', 'CONCLUIDA', 0.00, 161.80),
  (12, 1, 3, '2026-01-07 08:15:00', 'CONCLUIDA', 0.00, 51.80),
  (13, 109, 1, '2026-01-08 15:00:00', 'CONCLUIDA', 0.00, 249.20),
  (14, 24, 2, '2026-01-08 17:15:00', 'ORCAMENTO', 0.00, 9.90),
  (15, 1, 1, '2026-01-08 14:55:00', 'CONCLUIDA', 0.00, 558.00),
  (16, 1, 3, '2026-01-08 14:40:00', 'CONCLUIDA', 0.25, 4.65),
  (17, 1, 2, '2026-01-09 15:35:00', 'CONCLUIDA', 0.20, 3.70),
  (18, 1, 2, '2026-01-09 10:25:00', 'CONCLUIDA', 8.09, 153.71),
  (19, 1, 2, '2026-01-09 14:50:00', 'CANCELADA', 0.00, 19.90),
  (20, 78, 1, '2026-01-10 08:40:00', 'CONCLUIDA', 27.90, 530.10),
  (21, 81, 2, '2026-01-10 11:35:00', 'CONCLUIDA', 0.00, 23.90),
  (22, 113, 1, '2026-01-12 09:20:00', 'CONCLUIDA', 0.00, 523.20),
  (23, 106, 1, '2026-01-12 10:15:00', 'CONCLUIDA', 0.00, 69.90),
  (24, 115, 1, '2026-01-12 10:50:00', 'CONCLUIDA', 0.00, 603.40),
  (25, 1, 1, '2026-01-12 16:45:00', 'CONCLUIDA', 0.00, 55.80),
  (26, 88, 2, '2026-01-12 12:50:00', 'CONCLUIDA', 0.20, 3.70),
  (27, 14, 3, '2026-01-13 08:50:00', 'CONCLUIDA', 0.00, 3.90),
  (28, 1, 2, '2026-01-13 11:55:00', 'ORCAMENTO', 0.00, 12.90),
  (29, 1, 2, '2026-01-13 08:35:00', 'CONCLUIDA', 0.00, 110.20),
  (30, 1, 1, '2026-01-14 13:40:00', 'CONCLUIDA', 0.00, 69.90),
  (31, 105, 3, '2026-01-14 13:10:00', 'CONCLUIDA', 0.00, 10.90),
  (32, 1, 2, '2026-01-14 11:00:00', 'CONCLUIDA', 0.00, 64.70),
  (33, 66, 2, '2026-01-14 17:15:00', 'CONCLUIDA', 0.00, 176.70),
  (34, 23, 2, '2026-01-14 16:50:00', 'CONCLUIDA', 0.00, 64.70),
  (35, 109, 1, '2026-01-15 15:50:00', 'CONCLUIDA', 0.00, 1125.90),
  (36, 1, 1, '2026-01-16 08:45:00', 'CONCLUIDA', 0.00, 161.80),
  (37, 1, 1, '2026-01-16 17:45:00', 'CONCLUIDA', 4.85, 92.15),
  (38, 75, 2, '2026-01-16 11:15:00', 'CONCLUIDA', 0.00, 568.90),
  (39, 51, 3, '2026-01-16 17:50:00', 'CANCELADA', 0.00, 64.70),
  (40, 1, 1, '2026-01-16 12:40:00', 'CONCLUIDA', 0.00, 558.00),
  (41, 14, 2, '2026-01-17 09:25:00', 'CONCLUIDA', 0.00, 558.00),
  (42, 1, 3, '2026-01-17 08:50:00', 'CONCLUIDA', 3.09, 58.61),
  (43, 1, 2, '2026-01-19 17:50:00', 'CONCLUIDA', 0.00, 161.80),
  (44, 110, 2, '2026-01-19 11:50:00', 'CONCLUIDA', 0.00, 64.70),
  (45, 1, 3, '2026-01-19 09:55:00', 'CONCLUIDA', 1.34, 25.56),
  (46, 77, 1, '2026-01-20 13:25:00', 'CONCLUIDA', 0.90, 17.00),
  (47, 39, 1, '2026-01-20 14:10:00', 'CONCLUIDA', 9.23, 175.47),
  (48, 1, 2, '2026-01-20 14:00:00', 'CONCLUIDA', 0.00, 22.90),
  (49, 1, 1, '2026-01-20 15:05:00', 'CONCLUIDA', 0.00, 119.80),
  (50, 1, 2, '2026-01-21 10:55:00', 'CONCLUIDA', 1.29, 24.51),
  (51, 1, 2, '2026-01-21 15:30:00', 'CONCLUIDA', 0.00, 172.30),
  (52, 57, 2, '2026-01-22 11:50:00', 'CONCLUIDA', 0.00, 30.90),
  (53, 103, 2, '2026-01-22 12:15:00', 'CONCLUIDA', 2.14, 40.66),
  (54, 1, 2, '2026-01-23 14:20:00', 'CONCLUIDA', 0.00, 55.10),
  (55, 28, 2, '2026-01-23 08:40:00', 'CONCLUIDA', 0.00, 25.90),
  (56, 120, 2, '2026-01-23 16:25:00', 'CONCLUIDA', 0.00, 161.80),
  (57, 111, 2, '2026-01-23 08:35:00', 'CONCLUIDA', 5.58, 105.92),
  (58, 1, 1, '2026-01-24 09:55:00', 'CONCLUIDA', 3.24, 61.46),
  (59, 1, 2, '2026-01-24 08:35:00', 'CONCLUIDA', 0.00, 558.00),
  (60, 25, 1, '2026-01-24 09:55:00', 'CONCLUIDA', 0.00, 9.90),
  (61, 1, 2, '2026-01-26 12:20:00', 'CONCLUIDA', 1.29, 24.61),
  (62, 84, 2, '2026-01-26 10:05:00', 'CONCLUIDA', 0.00, 31.80),
  (63, 60, 2, '2026-01-26 12:25:00', 'CONCLUIDA', 6.15, 116.75),
  (64, 113, 1, '2026-01-26 16:45:00', 'CONCLUIDA', 19.41, 368.69),
  (65, 43, 1, '2026-01-26 09:55:00', 'CONCLUIDA', 0.00, 51.80),
  (66, 1, 1, '2026-01-27 17:35:00', 'CONCLUIDA', 9.23, 175.47),
  (67, 1, 1, '2026-01-27 13:20:00', 'CANCELADA', 0.00, 74.90),
  (68, 24, 2, '2026-01-27 12:45:00', 'CONCLUIDA', 0.00, 36.90),
  (69, 120, 1, '2026-01-27 10:05:00', 'CONCLUIDA', 5.99, 113.81),
  (70, 1, 1, '2026-01-28 12:20:00', 'CONCLUIDA', 9.23, 175.47),
  (71, 1, 2, '2026-01-29 17:35:00', 'CONCLUIDA', 0.00, 47.80),
  (72, 1, 1, '2026-01-29 11:00:00', 'CONCLUIDA', 5.51, 104.69),
  (73, 121, 1, '2026-01-30 13:35:00', 'CONCLUIDA', 0.00, 10.90),
  (74, 25, 1, '2026-01-30 09:10:00', 'CONCLUIDA', 0.00, 8.90),
  (75, 98, 2, '2026-01-30 13:25:00', 'CONCLUIDA', 0.00, 53.70),
  (76, 110, 3, '2026-01-30 15:35:00', 'CONCLUIDA', 0.00, 43.80),
  (77, 1, 3, '2026-01-30 12:05:00', 'CONCLUIDA', 1.29, 24.61),
  (78, 1, 3, '2026-01-31 11:30:00', 'CONCLUIDA', 0.00, 44.70),
  (79, 1, 2, '2026-01-31 09:35:00', 'CONCLUIDA', 1.20, 22.70),
  (80, 84, 2, '2026-01-31 11:45:00', 'CONCLUIDA', 0.84, 16.06),
  (81, 39, 2, '2026-02-02 10:30:00', 'CONCLUIDA', 0.00, 64.70),
  (82, 51, 3, '2026-02-02 11:15:00', 'CONCLUIDA', 0.00, 9.90),
  (83, 1, 1, '2026-02-03 15:45:00', 'CANCELADA', 0.00, 110.20),
  (84, 90, 3, '2026-02-03 13:15:00', 'CONCLUIDA', 8.09, 153.71),
  (85, 98, 1, '2026-02-03 11:55:00', 'CONCLUIDA', 8.09, 153.71),
  (86, 1, 1, '2026-02-04 10:35:00', 'CONCLUIDA', 27.90, 530.10),
  (87, 1, 3, '2026-02-04 10:30:00', 'CONCLUIDA', 1.50, 28.40),
  (88, 82, 1, '2026-02-04 15:55:00', 'CONCLUIDA', 0.00, 9.90),
  (89, 1, 2, '2026-02-04 11:00:00', 'CONCLUIDA', 0.00, 325.60),
  (90, 1, 1, '2026-02-05 12:15:00', 'ORCAMENTO', 0.00, 184.70),
  (91, 1, 2, '2026-02-05 17:10:00', 'CONCLUIDA', 0.00, 351.50),
  (92, 115, 1, '2026-02-05 15:55:00', 'CONCLUIDA', 0.84, 16.06),
  (93, 1, 1, '2026-02-06 14:15:00', 'CONCLUIDA', 1.99, 37.81),
  (94, 1, 1, '2026-02-07 08:15:00', 'CONCLUIDA', 0.00, 558.00),
  (95, 109, 3, '2026-02-07 09:00:00', 'CONCLUIDA', 0.00, 738.90),
  (96, 1, 1, '2026-02-09 17:15:00', 'CONCLUIDA', 0.00, 69.90),
  (97, 1, 2, '2026-02-09 14:05:00', 'CONCLUIDA', 0.00, 97.00),
  (98, 31, 3, '2026-02-09 15:35:00', 'CONCLUIDA', 9.08, 172.62),
  (99, 1, 3, '2026-02-09 15:45:00', 'CONCLUIDA', 0.00, 558.00),
  (100, 1, 1, '2026-02-11 16:40:00', 'CONCLUIDA', 1.84, 35.06),
  (101, 1, 1, '2026-02-11 16:20:00', 'CONCLUIDA', 0.00, 342.50),
  (102, 1, 1, '2026-02-11 12:05:00', 'CONCLUIDA', 0.00, 64.70),
  (103, 1, 1, '2026-02-12 17:00:00', 'CONCLUIDA', 0.00, 558.00),
  (104, 76, 3, '2026-02-12 12:10:00', 'ORCAMENTO', 0.00, 184.70),
  (105, 1, 1, '2026-02-13 17:55:00', 'CONCLUIDA', 0.00, 51.80),
  (106, 23, 3, '2026-02-13 16:40:00', 'CONCLUIDA', 0.00, 558.00),
  (107, 1, 2, '2026-02-13 13:25:00', 'CONCLUIDA', 0.00, 42.80),
  (108, 1, 2, '2026-02-14 12:40:00', 'CONCLUIDA', 0.00, 380.70),
  (109, 1, 1, '2026-02-14 10:05:00', 'CONCLUIDA', 2.19, 41.61),
  (110, 5, 2, '2026-02-14 11:40:00', 'CONCLUIDA', 0.00, 15.90),
  (111, 76, 1, '2026-02-16 12:20:00', 'CONCLUIDA', 0.00, 558.00),
  (112, 1, 2, '2026-02-16 12:05:00', 'CONCLUIDA', 0.00, 184.70),
  (113, 1, 1, '2026-02-16 17:00:00', 'CONCLUIDA', 1.15, 21.75),
  (114, 5, 2, '2026-02-17 08:10:00', 'CONCLUIDA', 3.60, 68.40),
  (115, 1, 1, '2026-02-17 11:15:00', 'CONCLUIDA', 1.15, 21.75),
  (116, 1, 2, '2026-02-17 14:00:00', 'CONCLUIDA', 0.00, 31.80),
  (117, 109, 3, '2026-02-18 16:55:00', 'CONCLUIDA', 0.00, 45.80),
  (118, 62, 3, '2026-02-18 13:35:00', 'CONCLUIDA', 0.00, 74.60),
  (119, 17, 3, '2026-02-18 16:20:00', 'CONCLUIDA', 0.00, 325.60),
  (120, 81, 2, '2026-02-18 16:30:00', 'CONCLUIDA', 0.00, 65.60),
  (121, 1, 1, '2026-02-18 09:50:00', 'CONCLUIDA', 0.00, 90.60),
  (122, 1, 2, '2026-02-19 12:15:00', 'CONCLUIDA', 0.00, 64.70),
  (123, 1, 1, '2026-02-19 09:30:00', 'CONCLUIDA', 1.29, 24.61),
  (124, 48, 1, '2026-02-19 10:50:00', 'CONCLUIDA', 0.00, 325.60),
  (125, 73, 2, '2026-02-20 08:35:00', 'CONCLUIDA', 0.00, 19.90),
  (126, 1, 1, '2026-02-20 14:15:00', 'CONCLUIDA', 0.00, 95.80),
  (127, 1, 1, '2026-02-20 16:55:00', 'CONCLUIDA', 0.00, 25.90),
  (128, 1, 3, '2026-02-23 13:20:00', 'CONCLUIDA', 0.00, 116.90),
  (129, 1, 1, '2026-02-23 08:55:00', 'CONCLUIDA', 0.00, 25.90),
  (130, 1, 1, '2026-02-23 13:25:00', 'CONCLUIDA', 0.00, 39.80),
  (131, 1, 1, '2026-02-23 14:10:00', 'CONCLUIDA', 0.00, 347.50),
  (132, 1, 1, '2026-02-23 11:05:00', 'CONCLUIDA', 0.00, 17.80),
  (133, 104, 1, '2026-02-24 13:45:00', 'CONCLUIDA', 0.00, 60.60),
  (134, 9, 1, '2026-02-24 15:55:00', 'ORCAMENTO', 0.00, 558.00),
  (135, 1, 3, '2026-02-24 15:10:00', 'CONCLUIDA', 0.00, 25.90),
  (136, 98, 3, '2026-02-24 08:55:00', 'CONCLUIDA', 0.00, 9.90),
  (137, 41, 2, '2026-02-25 12:50:00', 'CONCLUIDA', 1.20, 22.70),
  (138, 10, 3, '2026-02-25 15:40:00', 'CONCLUIDA', 0.00, 31.90),
  (139, 1, 1, '2026-02-25 09:20:00', 'CONCLUIDA', 0.00, 16.90),
  (140, 87, 2, '2026-02-26 08:10:00', 'CONCLUIDA', 0.50, 9.40),
  (141, 83, 3, '2026-02-26 09:35:00', 'CONCLUIDA', 0.00, 9.90),
  (142, 1, 1, '2026-02-27 16:30:00', 'CONCLUIDA', 0.00, 64.70),
  (143, 1, 2, '2026-02-28 11:55:00', 'CONCLUIDA', 8.09, 153.71),
  (144, 116, 3, '2026-02-28 09:25:00', 'CONCLUIDA', 0.00, 29.80),
  (145, 77, 2, '2026-03-02 15:45:00', 'CONCLUIDA', 1.20, 22.70),
  (146, 21, 1, '2026-03-02 11:25:00', 'CONCLUIDA', 1.15, 21.75),
  (147, 1, 2, '2026-03-02 17:50:00', 'CONCLUIDA', 3.24, 61.46),
  (148, 39, 2, '2026-03-02 12:05:00', 'CONCLUIDA', 6.47, 122.93),
  (149, 1, 3, '2026-03-03 17:20:00', 'CONCLUIDA', 1.54, 29.36),
  (150, 1, 3, '2026-03-03 15:05:00', 'CONCLUIDA', 0.00, 64.70),
  (151, 1, 2, '2026-03-04 13:40:00', 'CONCLUIDA', 0.00, 161.80),
  (152, 1, 2, '2026-03-04 14:30:00', 'CONCLUIDA', 3.50, 66.40),
  (153, 1, 3, '2026-03-04 12:40:00', 'CONCLUIDA', 0.00, 558.00),
  (154, 1, 2, '2026-03-05 16:55:00', 'CONCLUIDA', 0.00, 558.00),
  (155, 1, 2, '2026-03-05 17:55:00', 'CONCLUIDA', 1.29, 24.61),
  (156, 81, 2, '2026-03-05 14:25:00', 'CONCLUIDA', 0.00, 70.00),
  (157, 24, 1, '2026-03-06 09:30:00', 'CONCLUIDA', 0.53, 9.97),
  (158, 13, 1, '2026-03-06 16:15:00', 'CONCLUIDA', 0.30, 5.60),
  (159, 19, 3, '2026-03-07 12:40:00', 'CONCLUIDA', 0.55, 10.35),
  (160, 1, 1, '2026-03-07 08:45:00', 'CONCLUIDA', 0.99, 18.91),
  (161, 1, 2, '2026-03-07 11:40:00', 'CONCLUIDA', 0.98, 18.52),
  (162, 1, 3, '2026-03-09 11:25:00', 'CONCLUIDA', 0.00, 184.70),
  (163, 1, 2, '2026-03-09 12:10:00', 'CONCLUIDA', 1.09, 20.81),
  (164, 1, 1, '2026-03-09 17:15:00', 'CONCLUIDA', 5.94, 112.86),
  (165, 1, 1, '2026-03-09 16:45:00', 'CONCLUIDA', 0.00, 19.50),
  (166, 1, 1, '2026-03-10 08:35:00', 'CONCLUIDA', 1.29, 24.61),
  (167, 1, 1, '2026-03-10 08:40:00', 'CONCLUIDA', 0.45, 8.45),
  (168, 1, 3, '2026-03-10 08:35:00', 'CONCLUIDA', 0.00, 51.80),
  (169, 63, 2, '2026-03-10 12:20:00', 'CONCLUIDA', 0.00, 56.80),
  (170, 95, 1, '2026-03-11 12:10:00', 'CONCLUIDA', 3.48, 66.12),
  (171, 58, 2, '2026-03-11 14:05:00', 'CONCLUIDA', 0.00, 361.40),
  (172, 1, 2, '2026-03-11 15:50:00', 'CANCELADA', 0.00, 19.90),
  (173, 1, 1, '2026-03-11 12:40:00', 'CONCLUIDA', 28.75, 546.15),
  (174, 73, 1, '2026-03-12 15:30:00', 'CONCLUIDA', 0.00, 25.90),
  (175, 78, 2, '2026-03-12 13:55:00', 'CONCLUIDA', 0.00, 25.90),
  (176, 1, 2, '2026-03-12 09:25:00', 'CONCLUIDA', 0.00, 210.60),
  (177, 83, 2, '2026-03-12 08:30:00', 'CONCLUIDA', 2.76, 52.34),
  (178, 1, 1, '2026-03-12 09:40:00', 'CONCLUIDA', 9.23, 175.47),
  (179, 1, 3, '2026-03-13 09:20:00', 'CONCLUIDA', 0.55, 10.35),
  (180, 1, 2, '2026-03-13 13:10:00', 'CONCLUIDA', 0.00, 19.40),
  (181, 1, 3, '2026-03-14 11:55:00', 'CONCLUIDA', 0.00, 22.90),
  (182, 1, 3, '2026-03-14 11:50:00', 'CONCLUIDA', 0.00, 39.00),
  (183, 1, 1, '2026-03-14 08:25:00', 'CONCLUIDA', 0.55, 10.35),
  (184, 107, 3, '2026-03-16 17:05:00', 'CONCLUIDA', 0.00, 79.50),
  (185, 1, 1, '2026-03-16 16:40:00', 'CONCLUIDA', 0.00, 19.90),
  (186, 1, 2, '2026-03-17 16:45:00', 'CONCLUIDA', 0.00, 558.00),
  (187, 1, 2, '2026-03-17 12:55:00', 'CONCLUIDA', 0.00, 19.90),
  (188, 1, 2, '2026-03-17 10:25:00', 'CONCLUIDA', 0.00, 10.90),
  (189, 1, 1, '2026-03-18 15:10:00', 'CONCLUIDA', 9.70, 184.30),
  (190, 1, 2, '2026-03-18 16:25:00', 'CONCLUIDA', 0.00, 12.90),
  (191, 51, 1, '2026-03-18 09:50:00', 'CONCLUIDA', 0.00, 55.10),
  (192, 1, 2, '2026-03-19 17:10:00', 'CONCLUIDA', 16.28, 309.32),
  (193, 1, 1, '2026-03-19 15:40:00', 'CONCLUIDA', 0.00, 79.60),
  (194, 1, 2, '2026-03-19 11:15:00', 'CONCLUIDA', 4.05, 76.95),
  (195, 1, 1, '2026-03-20 09:55:00', 'CONCLUIDA', 0.80, 15.10),
  (196, 1, 2, '2026-03-21 10:40:00', 'CONCLUIDA', 0.00, 239.80),
  (197, 1, 2, '2026-03-21 10:15:00', 'CONCLUIDA', 0.00, 29.90),
  (198, 1, 2, '2026-03-21 12:15:00', 'CONCLUIDA', 0.99, 18.91),
  (199, 1, 3, '2026-03-23 13:35:00', 'CONCLUIDA', 0.30, 5.60),
  (200, 110, 1, '2026-03-23 15:30:00', 'CANCELADA', 0.00, 44.70);
INSERT INTO venda (id_venda, id_cliente, id_funcionario, data_venda, status_venda, valor_desconto, valor_total) VALUES
  (201, 5, 1, '2026-03-23 15:50:00', 'CONCLUIDA', 0.00, 558.00),
  (202, 77, 1, '2026-03-23 17:45:00', 'CONCLUIDA', 0.00, 51.80),
  (203, 1, 2, '2026-03-24 16:50:00', 'CONCLUIDA', 0.99, 18.91),
  (204, 54, 1, '2026-03-24 17:35:00', 'CANCELADA', 0.00, 161.80),
  (205, 1, 1, '2026-03-24 09:10:00', 'CONCLUIDA', 5.75, 109.15),
  (206, 1, 3, '2026-03-24 10:55:00', 'CONCLUIDA', 0.00, 26.90),
  (207, 1, 1, '2026-03-25 08:10:00', 'CANCELADA', 0.00, 161.80),
  (208, 38, 2, '2026-03-25 11:45:00', 'CONCLUIDA', 4.85, 92.15),
  (209, 121, 3, '2026-03-25 13:05:00', 'CONCLUIDA', 0.00, 29.80),
  (210, 1, 2, '2026-03-26 09:00:00', 'CONCLUIDA', 0.00, 558.00),
  (211, 1, 2, '2026-03-26 16:50:00', 'CONCLUIDA', 1.09, 20.81),
  (212, 106, 3, '2026-03-26 14:50:00', 'CONCLUIDA', 27.90, 530.10),
  (213, 49, 1, '2026-03-26 08:20:00', 'CONCLUIDA', 27.90, 530.10),
  (214, 1, 2, '2026-03-27 08:55:00', 'CONCLUIDA', 0.00, 25.90),
  (215, 109, 1, '2026-03-27 09:55:00', 'CONCLUIDA', 3.37, 64.03),
  (216, 7, 1, '2026-03-28 11:40:00', 'CANCELADA', 0.00, 64.70),
  (217, 1, 1, '2026-03-28 11:30:00', 'CONCLUIDA', 0.00, 64.70),
  (218, 1, 1, '2026-03-30 15:00:00', 'CONCLUIDA', 0.00, 97.00),
  (219, 15, 2, '2026-03-30 17:10:00', 'CONCLUIDA', 0.53, 9.97),
  (220, 109, 2, '2026-03-31 15:55:00', 'CONCLUIDA', 0.00, 19.50),
  (221, 1, 2, '2026-03-31 10:05:00', 'CONCLUIDA', 0.00, 19.90),
  (222, 1, 3, '2026-03-31 14:10:00', 'CONCLUIDA', 0.00, 329.50),
  (223, 1, 2, '2026-04-01 16:10:00', 'CONCLUIDA', 29.30, 556.60),
  (224, 1, 2, '2026-04-02 13:40:00', 'CONCLUIDA', 0.00, 223.90),
  (225, 1, 1, '2026-04-02 16:35:00', 'CONCLUIDA', 2.09, 39.71),
  (226, 1, 2, '2026-04-02 10:20:00', 'CONCLUIDA', 0.00, 19.90),
  (227, 1, 3, '2026-04-02 10:00:00', 'CONCLUIDA', 0.00, 19.90),
  (228, 1, 3, '2026-04-02 11:05:00', 'CONCLUIDA', 0.00, 101.90),
  (229, 1, 2, '2026-04-02 16:05:00', 'CONCLUIDA', 1.84, 35.06),
  (230, 33, 3, '2026-04-03 13:45:00', 'CONCLUIDA', 0.00, 165.70),
  (231, 55, 3, '2026-04-03 10:00:00', 'CONCLUIDA', 0.00, 17.90),
  (232, 1, 2, '2026-04-03 16:15:00', 'CONCLUIDA', 0.00, 641.80),
  (233, 27, 1, '2026-04-04 10:55:00', 'CONCLUIDA', 3.64, 69.16),
  (234, 116, 1, '2026-04-04 11:25:00', 'CONCLUIDA', 0.00, 113.60),
  (235, 48, 2, '2026-04-06 15:40:00', 'CONCLUIDA', 0.00, 9.90),
  (236, 72, 1, '2026-04-06 12:55:00', 'CONCLUIDA', 29.30, 556.60),
  (237, 50, 1, '2026-04-06 16:30:00', 'CONCLUIDA', 0.00, 25.90),
  (238, 1, 2, '2026-04-07 10:50:00', 'CONCLUIDA', 0.00, 19.50),
  (239, 1, 2, '2026-04-08 16:10:00', 'CONCLUIDA', 30.27, 575.13),
  (240, 40, 2, '2026-04-08 16:45:00', 'CONCLUIDA', 0.00, 169.90),
  (241, 1, 1, '2026-04-08 08:55:00', 'CONCLUIDA', 0.55, 10.35),
  (242, 1, 1, '2026-04-08 14:45:00', 'CONCLUIDA', 0.00, 101.90),
  (243, 47, 3, '2026-04-08 13:35:00', 'CONCLUIDA', 0.00, 30.90),
  (244, 70, 2, '2026-04-09 16:40:00', 'CONCLUIDA', 0.00, 169.90),
  (245, 84, 2, '2026-04-09 13:00:00', 'CANCELADA', 0.00, 101.90),
  (246, 1, 2, '2026-04-09 08:30:00', 'CONCLUIDA', 0.00, 51.80),
  (247, 80, 2, '2026-04-09 14:25:00', 'CONCLUIDA', 0.65, 12.25),
  (248, 60, 2, '2026-04-10 12:40:00', 'CONCLUIDA', 0.00, 341.90),
  (249, 58, 2, '2026-04-10 16:45:00', 'CONCLUIDA', 2.40, 45.50),
  (250, 113, 2, '2026-04-11 09:30:00', 'CONCLUIDA', 2.40, 45.50),
  (251, 1, 2, '2026-04-11 10:10:00', 'CONCLUIDA', 0.00, 21.90),
  (252, 59, 2, '2026-04-13 09:45:00', 'CONCLUIDA', 3.40, 64.50),
  (253, 1, 3, '2026-04-13 15:00:00', 'CONCLUIDA', 0.00, 45.40),
  (254, 1, 1, '2026-04-14 17:00:00', 'CONCLUIDA', 0.00, 585.90),
  (255, 1, 1, '2026-04-14 12:55:00', 'CONCLUIDA', 0.00, 193.90),
  (256, 43, 3, '2026-04-14 10:05:00', 'CONCLUIDA', 0.00, 169.90),
  (257, 47, 1, '2026-04-14 10:05:00', 'CONCLUIDA', 0.55, 10.35),
  (258, 50, 1, '2026-04-14 16:30:00', 'CONCLUIDA', 1.79, 34.01),
  (259, 1, 2, '2026-04-14 14:40:00', 'CONCLUIDA', 0.00, 16.90),
  (260, 59, 1, '2026-04-14 11:00:00', 'CONCLUIDA', 2.90, 55.00),
  (261, 1, 1, '2026-04-15 12:00:00', 'CONCLUIDA', 0.00, 69.90),
  (262, 1, 2, '2026-04-15 16:50:00', 'CONCLUIDA', 0.00, 47.90),
  (263, 1, 2, '2026-04-15 08:05:00', 'CONCLUIDA', 0.00, 17.90),
  (264, 1, 1, '2026-04-16 16:25:00', 'CONCLUIDA', 0.65, 12.25),
  (265, 105, 2, '2026-04-16 14:55:00', 'CONCLUIDA', 11.28, 214.22),
  (266, 60, 3, '2026-04-16 15:05:00', 'CONCLUIDA', 1.84, 35.06),
  (267, 1, 1, '2026-04-16 12:45:00', 'CONCLUIDA', 0.00, 55.90),
  (268, 1, 2, '2026-04-16 16:10:00', 'CONCLUIDA', 5.10, 96.80),
  (269, 1, 1, '2026-04-17 13:25:00', 'CONCLUIDA', 1.29, 24.61),
  (270, 1, 3, '2026-04-17 10:55:00', 'CONCLUIDA', 3.50, 66.40),
  (271, 1, 3, '2026-04-17 10:00:00', 'CONCLUIDA', 0.00, 25.90),
  (272, 1, 1, '2026-04-17 16:25:00', 'CONCLUIDA', 8.50, 161.40),
  (273, 1, 2, '2026-04-17 14:55:00', 'CONCLUIDA', 1.29, 24.61),
  (274, 1, 2, '2026-04-17 15:30:00', 'CONCLUIDA', 5.10, 96.80),
  (275, 82, 2, '2026-04-18 10:20:00', 'CONCLUIDA', 2.79, 53.11),
  (276, 1, 1, '2026-04-18 12:10:00', 'CONCLUIDA', 0.00, 67.90),
  (277, 1, 1, '2026-04-18 11:25:00', 'CONCLUIDA', 0.00, 25.90),
  (278, 61, 3, '2026-04-18 08:30:00', 'CONCLUIDA', 0.00, 29.90),
  (279, 97, 1, '2026-04-20 09:10:00', 'CONCLUIDA', 0.50, 9.40),
  (280, 1, 3, '2026-04-20 12:25:00', 'CONCLUIDA', 0.00, 67.90),
  (281, 1, 2, '2026-04-20 11:10:00', 'CONCLUIDA', 0.00, 585.90),
  (282, 1, 2, '2026-04-20 13:25:00', 'CONCLUIDA', 3.40, 64.50),
  (283, 1, 2, '2026-04-21 17:45:00', 'CONCLUIDA', 12.33, 234.27),
  (284, 1, 1, '2026-04-21 17:05:00', 'CONCLUIDA', 0.00, 341.90),
  (285, 1, 2, '2026-04-22 09:30:00', 'CONCLUIDA', 0.00, 585.90),
  (286, 1, 3, '2026-04-22 09:25:00', 'CONCLUIDA', 0.00, 25.90),
  (287, 1, 1, '2026-04-23 11:30:00', 'CONCLUIDA', 0.00, 125.80),
  (288, 16, 2, '2026-04-23 09:05:00', 'CONCLUIDA', 0.50, 9.40),
  (289, 1, 3, '2026-04-23 17:20:00', 'CONCLUIDA', 0.00, 31.90),
  (290, 1, 2, '2026-04-23 10:40:00', 'CONCLUIDA', 0.00, 19.90),
  (291, 62, 1, '2026-04-24 17:40:00', 'CONCLUIDA', 0.00, 585.90),
  (292, 1, 1, '2026-04-24 17:30:00', 'ORCAMENTO', 0.00, 112.80),
  (293, 1, 1, '2026-04-24 09:30:00', 'CONCLUIDA', 20.49, 389.31),
  (294, 1, 2, '2026-04-25 12:00:00', 'CONCLUIDA', 0.80, 15.10),
  (295, 19, 2, '2026-04-27 17:25:00', 'CONCLUIDA', 0.00, 606.80),
  (296, 1, 2, '2026-04-27 13:15:00', 'CONCLUIDA', 2.29, 43.51),
  (297, 110, 3, '2026-04-27 12:15:00', 'CONCLUIDA', 0.00, 16.90),
  (298, 1, 1, '2026-04-28 14:45:00', 'CONCLUIDA', 0.00, 29.90),
  (299, 119, 3, '2026-04-28 16:55:00', 'CONCLUIDA', 12.93, 245.67),
  (300, 1, 1, '2026-04-28 14:45:00', 'CONCLUIDA', 0.00, 25.90),
  (301, 1, 1, '2026-04-28 09:20:00', 'CONCLUIDA', 2.09, 39.71),
  (302, 26, 2, '2026-04-29 17:40:00', 'CONCLUIDA', 0.55, 10.35),
  (303, 1, 1, '2026-04-29 12:35:00', 'CONCLUIDA', 0.00, 57.90),
  (304, 80, 3, '2026-04-29 14:50:00', 'CONCLUIDA', 17.09, 324.81),
  (305, 79, 2, '2026-04-29 11:20:00', 'CANCELADA', 0.00, 341.90),
  (306, 1, 3, '2026-04-29 10:05:00', 'CONCLUIDA', 2.40, 45.50),
  (307, 1, 2, '2026-04-30 14:40:00', 'CONCLUIDA', 0.00, 69.90),
  (308, 1, 2, '2026-04-30 15:15:00', 'CONCLUIDA', 29.30, 556.60),
  (309, 1, 2, '2026-04-30 09:35:00', 'CONCLUIDA', 0.00, 19.90),
  (310, 100, 1, '2026-05-01 12:45:00', 'CONCLUIDA', 0.00, 101.90),
  (311, 92, 2, '2026-05-01 09:10:00', 'CONCLUIDA', 0.00, 19.90),
  (312, 77, 1, '2026-05-01 09:05:00', 'CONCLUIDA', 0.80, 15.10),
  (313, 1, 2, '2026-05-01 13:05:00', 'CONCLUIDA', 0.00, 20.90),
  (314, 97, 1, '2026-05-01 08:35:00', 'CONCLUIDA', 0.00, 19.50),
  (315, 1, 1, '2026-05-01 16:40:00', 'CONCLUIDA', 0.00, 67.90),
  (316, 1, 1, '2026-05-02 08:20:00', 'CONCLUIDA', 0.00, 67.90),
  (317, 1, 1, '2026-05-02 09:20:00', 'CONCLUIDA', 20.49, 389.31),
  (318, 7, 3, '2026-05-04 09:05:00', 'CONCLUIDA', 0.00, 10.90),
  (319, 1, 1, '2026-05-04 10:55:00', 'CONCLUIDA', 0.00, 132.80),
  (320, 1, 1, '2026-05-04 14:35:00', 'CONCLUIDA', 1.79, 34.11),
  (321, 1, 1, '2026-05-04 14:00:00', 'CONCLUIDA', 17.29, 328.51),
  (322, 81, 1, '2026-05-04 12:10:00', 'CONCLUIDA', 0.00, 34.80),
  (323, 1, 2, '2026-05-04 17:05:00', 'CONCLUIDA', 0.00, 29.90),
  (324, 8, 1, '2026-05-05 17:25:00', 'CONCLUIDA', 12.04, 228.66),
  (325, 26, 2, '2026-05-05 09:25:00', 'CONCLUIDA', 0.00, 110.50),
  (326, 1, 1, '2026-05-05 10:45:00', 'CONCLUIDA', 0.00, 341.90),
  (327, 112, 1, '2026-05-05 13:05:00', 'CONCLUIDA', 15.81, 300.39),
  (328, 1, 1, '2026-05-05 13:40:00', 'CONCLUIDA', 17.09, 324.81),
  (329, 1, 1, '2026-05-05 12:00:00', 'CONCLUIDA', 0.00, 19.90),
  (330, 1, 1, '2026-05-06 11:00:00', 'CONCLUIDA', 17.09, 324.81),
  (331, 1, 3, '2026-05-07 15:00:00', 'CONCLUIDA', 0.00, 10.50),
  (332, 1, 1, '2026-05-07 08:55:00', 'CONCLUIDA', 6.99, 132.81),
  (333, 101, 2, '2026-05-07 17:50:00', 'CONCLUIDA', 0.00, 373.70),
  (334, 1, 2, '2026-05-08 14:00:00', 'CONCLUIDA', 1.29, 24.61),
  (335, 1, 2, '2026-05-08 16:25:00', 'CONCLUIDA', 0.00, 193.90),
  (336, 98, 1, '2026-05-09 10:50:00', 'CONCLUIDA', 0.00, 17.90),
  (337, 1, 3, '2026-05-09 08:55:00', 'CONCLUIDA', 3.79, 72.01),
  (338, 29, 2, '2026-05-09 11:25:00', 'CONCLUIDA', 0.00, 101.90),
  (339, 1, 2, '2026-05-09 12:55:00', 'CONCLUIDA', 8.50, 161.40),
  (340, 1, 3, '2026-05-11 09:00:00', 'CONCLUIDA', 9.88, 187.82),
  (341, 73, 2, '2026-05-11 09:55:00', 'CONCLUIDA', 0.00, 59.80),
  (342, 1, 3, '2026-05-11 13:30:00', 'CONCLUIDA', 17.09, 324.81),
  (343, 1, 1, '2026-05-11 13:15:00', 'CONCLUIDA', 0.00, 585.90),
  (344, 1, 1, '2026-05-11 14:30:00', 'CONCLUIDA', 5.10, 96.80),
  (345, 84, 1, '2026-05-12 08:20:00', 'CONCLUIDA', 0.00, 193.90),
  (346, 1, 1, '2026-05-12 11:10:00', 'CONCLUIDA', 0.00, 251.80),
  (347, 18, 1, '2026-05-12 10:40:00', 'CONCLUIDA', 0.00, 39.00),
  (348, 98, 2, '2026-05-12 14:45:00', 'CONCLUIDA', 0.00, 94.50),
  (349, 1, 3, '2026-05-12 10:05:00', 'CONCLUIDA', 0.35, 6.55),
  (350, 96, 1, '2026-05-12 09:05:00', 'CONCLUIDA', 0.00, 101.90),
  (351, 9, 1, '2026-05-13 15:50:00', 'CONCLUIDA', 3.40, 64.50),
  (352, 109, 1, '2026-05-13 09:15:00', 'CONCLUIDA', 3.40, 64.50),
  (353, 1, 1, '2026-05-14 16:10:00', 'CANCELADA', 0.00, 9.90),
  (354, 1, 2, '2026-05-14 10:40:00', 'CONCLUIDA', 2.04, 38.76),
  (355, 1, 2, '2026-05-14 11:20:00', 'CONCLUIDA', 1.29, 24.61),
  (356, 1, 1, '2026-05-15 09:40:00', 'CONCLUIDA', 0.00, 341.90),
  (357, 1, 1, '2026-05-15 14:40:00', 'CONCLUIDA', 5.10, 96.80),
  (358, 49, 3, '2026-05-15 14:45:00', 'CONCLUIDA', 0.00, 25.90),
  (359, 1, 1, '2026-05-15 17:05:00', 'CONCLUIDA', 9.70, 184.20),
  (360, 1, 2, '2026-05-16 12:50:00', 'CONCLUIDA', 0.00, 121.80),
  (361, 46, 3, '2026-05-18 11:55:00', 'CONCLUIDA', 0.55, 10.35),
  (362, 120, 2, '2026-05-18 10:40:00', 'CONCLUIDA', 1.84, 35.06),
  (363, 1, 3, '2026-05-19 08:10:00', 'CONCLUIDA', 5.10, 96.80),
  (364, 1, 1, '2026-05-19 11:45:00', 'CONCLUIDA', 0.00, 67.80),
  (365, 1, 2, '2026-05-19 12:00:00', 'CONCLUIDA', 0.00, 585.90),
  (366, 1, 3, '2026-05-19 14:45:00', 'CONCLUIDA', 18.29, 347.51),
  (367, 1, 3, '2026-05-20 16:25:00', 'CONCLUIDA', 0.00, 341.90),
  (368, 119, 3, '2026-05-20 16:15:00', 'CONCLUIDA', 0.00, 813.70),
  (369, 1, 2, '2026-05-20 14:10:00', 'CONCLUIDA', 0.00, 67.90),
  (370, 1, 2, '2026-05-21 13:30:00', 'CONCLUIDA', 1.54, 29.36),
  (371, 1, 2, '2026-05-21 13:10:00', 'CONCLUIDA', 0.00, 585.90),
  (372, 1, 1, '2026-05-21 17:30:00', 'CONCLUIDA', 0.00, 30.90),
  (373, 63, 2, '2026-05-22 10:00:00', 'CONCLUIDA', 1.29, 24.61),
  (374, 1, 2, '2026-05-22 13:10:00', 'CONCLUIDA', 0.00, 69.90),
  (375, 25, 1, '2026-05-25 08:50:00', 'CANCELADA', 0.00, 25.90),
  (376, 1, 2, '2026-05-25 11:05:00', 'CONCLUIDA', 0.00, 29.90),
  (377, 84, 1, '2026-05-25 16:00:00', 'CONCLUIDA', 0.00, 8.90),
  (378, 1, 1, '2026-05-25 14:10:00', 'CONCLUIDA', 0.00, 67.90),
  (379, 26, 2, '2026-05-26 17:40:00', 'CONCLUIDA', 0.00, 585.90),
  (380, 1, 1, '2026-05-26 17:15:00', 'CANCELADA', 0.00, 21.90),
  (381, 1, 1, '2026-05-26 17:35:00', 'CONCLUIDA', 0.00, 295.70),
  (382, 1, 2, '2026-05-26 14:00:00', 'CANCELADA', 0.00, 23.90),
  (383, 47, 1, '2026-05-26 17:00:00', 'CONCLUIDA', 0.00, 57.70),
  (384, 86, 3, '2026-05-26 11:55:00', 'CONCLUIDA', 5.10, 96.80),
  (385, 1, 2, '2026-05-27 16:10:00', 'CONCLUIDA', 0.00, 16.90),
  (386, 1, 1, '2026-05-27 17:40:00', 'CONCLUIDA', 0.00, 15.90),
  (387, 1, 3, '2026-05-27 12:20:00', 'CONCLUIDA', 0.00, 169.90),
  (388, 1, 1, '2026-05-27 13:30:00', 'CONCLUIDA', 0.00, 585.90),
  (389, 119, 1, '2026-05-27 15:50:00', 'CONCLUIDA', 0.00, 342.80),
  (390, 1, 1, '2026-05-28 11:30:00', 'CONCLUIDA', 10.19, 193.61),
  (391, 115, 2, '2026-05-29 15:40:00', 'CONCLUIDA', 0.00, 183.50),
  (392, 54, 2, '2026-05-30 11:20:00', 'CONCLUIDA', 0.00, 585.90),
  (393, 1, 2, '2026-06-01 13:45:00', 'CONCLUIDA', 0.00, 14.90),
  (394, 1, 2, '2026-06-01 13:00:00', 'CONCLUIDA', 1.29, 24.61),
  (395, 76, 1, '2026-06-01 16:50:00', 'CONCLUIDA', 0.00, 169.90),
  (396, 91, 2, '2026-06-02 12:55:00', 'CONCLUIDA', 1.29, 24.61),
  (397, 1, 3, '2026-06-02 16:20:00', 'CONCLUIDA', 9.70, 184.20),
  (398, 1, 2, '2026-06-02 15:05:00', 'CONCLUIDA', 0.00, 77.70),
  (399, 13, 1, '2026-06-02 10:30:00', 'CONCLUIDA', 1.29, 24.61),
  (400, 75, 1, '2026-06-03 14:30:00', 'CONCLUIDA', 0.84, 16.06);
INSERT INTO venda (id_venda, id_cliente, id_funcionario, data_venda, status_venda, valor_desconto, valor_total) VALUES
  (401, 1, 2, '2026-06-03 16:25:00', 'CONCLUIDA', 0.00, 67.80),
  (402, 1, 1, '2026-06-04 10:35:00', 'CONCLUIDA', 0.00, 36.90),
  (403, 1, 2, '2026-06-04 17:25:00', 'CONCLUIDA', 0.00, 169.90),
  (404, 1, 2, '2026-06-04 15:45:00', 'CONCLUIDA', 0.00, 101.90),
  (405, 118, 1, '2026-06-04 17:20:00', 'CONCLUIDA', 18.98, 360.72),
  (406, 1, 1, '2026-06-04 17:55:00', 'CONCLUIDA', 0.00, 25.90),
  (407, 1, 1, '2026-06-04 09:35:00', 'CONCLUIDA', 3.50, 66.40),
  (408, 1, 2, '2026-06-05 16:00:00', 'CONCLUIDA', 1.50, 28.40),
  (409, 1, 3, '2026-06-08 11:00:00', 'CONCLUIDA', 0.00, 14.90),
  (410, 1, 2, '2026-06-08 17:25:00', 'CONCLUIDA', 0.00, 23.90),
  (411, 99, 1, '2026-06-08 10:20:00', 'CONCLUIDA', 0.00, 25.90),
  (412, 114, 1, '2026-06-08 11:15:00', 'CANCELADA', 0.00, 25.90),
  (413, 112, 2, '2026-06-08 17:20:00', 'CANCELADA', 0.00, 191.70),
  (414, 33, 1, '2026-06-08 10:35:00', 'CONCLUIDA', 0.00, 67.90),
  (415, 1, 1, '2026-06-09 11:00:00', 'CONCLUIDA', 3.40, 64.50),
  (416, 1, 2, '2026-06-09 17:10:00', 'CONCLUIDA', 0.00, 101.90),
  (417, 1, 1, '2026-06-09 16:25:00', 'CONCLUIDA', 0.90, 17.00),
  (418, 1, 1, '2026-06-10 15:30:00', 'CONCLUIDA', 1.54, 29.36),
  (419, 12, 2, '2026-06-10 08:35:00', 'CONCLUIDA', 0.00, 193.90),
  (420, 18, 2, '2026-06-10 17:00:00', 'ORCAMENTO', 0.00, 341.90),
  (421, 44, 1, '2026-06-12 10:10:00', 'ORCAMENTO', 0.00, 3.90),
  (422, 1, 3, '2026-06-12 17:30:00', 'CONCLUIDA', 0.00, 69.90),
  (423, 99, 1, '2026-06-12 14:30:00', 'CONCLUIDA', 0.55, 10.35),
  (424, 1, 3, '2026-06-13 10:25:00', 'CONCLUIDA', 0.00, 10.90),
  (425, 1, 3, '2026-06-15 12:55:00', 'ORCAMENTO', 0.00, 16.90),
  (426, 1, 3, '2026-06-15 11:10:00', 'CONCLUIDA', 0.00, 25.90),
  (427, 1, 2, '2026-06-15 08:10:00', 'CONCLUIDA', 0.00, 116.80),
  (428, 1, 2, '2026-06-16 15:10:00', 'ORCAMENTO', 0.00, 69.90),
  (429, 51, 2, '2026-06-16 10:05:00', 'CONCLUIDA', 0.00, 101.90),
  (430, 109, 2, '2026-06-16 08:05:00', 'CONCLUIDA', 0.00, 20.90),
  (431, 1, 2, '2026-06-16 12:40:00', 'CONCLUIDA', 0.25, 4.65),
  (432, 1, 3, '2026-06-17 13:20:00', 'CONCLUIDA', 29.30, 556.60),
  (433, 1, 3, '2026-06-17 17:35:00', 'CONCLUIDA', 0.00, 15.90),
  (434, 7, 1, '2026-06-17 11:50:00', 'CONCLUIDA', 0.00, 29.90),
  (435, 1, 1, '2026-06-18 13:15:00', 'CONCLUIDA', 8.50, 161.40),
  (436, 1, 1, '2026-06-18 11:40:00', 'CONCLUIDA', 0.00, 190.90),
  (437, 1, 3, '2026-06-18 12:45:00', 'CONCLUIDA', 0.00, 585.90),
  (438, 102, 1, '2026-06-18 12:40:00', 'CONCLUIDA', 21.18, 402.42),
  (439, 95, 3, '2026-06-19 16:15:00', 'CONCLUIDA', 0.50, 9.40),
  (440, 30, 1, '2026-06-19 10:20:00', 'ORCAMENTO', 0.00, 609.80),
  (441, 64, 1, '2026-06-19 09:50:00', 'CONCLUIDA', 0.00, 341.90),
  (442, 1, 3, '2026-06-22 10:35:00', 'CONCLUIDA', 0.00, 105.80),
  (443, 30, 2, '2026-06-22 08:45:00', 'ORCAMENTO', 0.00, 21.00),
  (444, 18, 1, '2026-06-22 16:25:00', 'CONCLUIDA', 0.00, 51.80),
  (445, 59, 3, '2026-06-22 08:00:00', 'CONCLUIDA', 0.00, 21.90),
  (446, 1, 2, '2026-06-23 15:45:00', 'CONCLUIDA', 0.65, 12.25),
  (447, 1, 3, '2026-06-23 10:55:00', 'CONCLUIDA', 0.00, 17.90),
  (448, 1, 1, '2026-06-23 09:15:00', 'CONCLUIDA', 0.00, 25.90),
  (449, 1, 2, '2026-06-23 12:15:00', 'CONCLUIDA', 0.00, 69.90),
  (450, 1, 3, '2026-06-23 14:10:00', 'CONCLUIDA', 1.50, 28.40),
  (451, 1, 2, '2026-06-24 12:45:00', 'CONCLUIDA', 17.09, 324.81),
  (452, 10, 3, '2026-06-24 17:20:00', 'CONCLUIDA', 0.00, 22.90),
  (453, 1, 3, '2026-06-24 13:25:00', 'CONCLUIDA', 1.84, 35.06),
  (454, 114, 3, '2026-06-24 17:20:00', 'CONCLUIDA', 0.00, 9.90),
  (455, 1, 1, '2026-06-24 08:00:00', 'CONCLUIDA', 0.00, 139.80),
  (456, 1, 2, '2026-06-25 10:10:00', 'CONCLUIDA', 0.55, 10.35),
  (457, 1, 1, '2026-06-25 17:30:00', 'CONCLUIDA', 3.40, 64.50),
  (458, 1, 2, '2026-06-26 08:30:00', 'CONCLUIDA', 0.00, 115.80),
  (459, 1, 1, '2026-06-26 11:35:00', 'CONCLUIDA', 0.90, 17.00),
  (460, 1, 1, '2026-06-26 08:10:00', 'CONCLUIDA', 0.00, 101.90),
  (461, 1, 2, '2026-06-29 15:40:00', 'ORCAMENTO', 0.00, 399.80),
  (462, 1, 1, '2026-06-29 15:45:00', 'CONCLUIDA', 0.00, 341.90),
  (463, 1, 1, '2026-06-29 12:50:00', 'CONCLUIDA', 1.54, 29.26),
  (464, 72, 1, '2026-06-29 12:15:00', 'CONCLUIDA', 3.40, 64.50),
  (465, 1, 2, '2026-06-30 14:40:00', 'CONCLUIDA', 1.54, 29.36),
  (466, 1, 1, '2026-06-30 13:00:00', 'CONCLUIDA', 25.59, 486.21),
  (467, 9, 3, '2026-06-30 12:05:00', 'CONCLUIDA', 0.00, 57.90);

INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES
  (1, 40, 1, 17.90),
  (2, 60, 1, 184.70),
  (3, 7, 1, 49.90),
  (4, 27, 1, 21.90),
  (5, 11, 1, 19.50),
  (6, 44, 2, 47.90),
  (7, 35, 1, 31.90),
  (8, 13, 1, 22.90),
  (9, 55, 1, 558.00),
  (10, 42, 1, 16.90),
  (11, 56, 1, 161.80),
  (12, 37, 2, 25.90),
  (13, 57, 1, 55.10),
  (13, 61, 3, 64.70),
  (14, 29, 1, 9.90),
  (15, 55, 1, 558.00),
  (16, 65, 1, 4.90),
  (17, 67, 1, 3.90),
  (18, 56, 1, 161.80),
  (19, 38, 1, 19.90),
  (20, 55, 1, 558.00),
  (21, 51, 1, 23.90),
  (22, 40, 2, 17.90),
  (22, 56, 1, 161.80),
  (22, 62, 1, 325.60),
  (23, 16, 1, 69.90),
  (24, 11, 1, 19.50),
  (24, 37, 1, 25.90),
  (24, 55, 1, 558.00),
  (25, 15, 1, 29.90),
  (25, 33, 1, 25.90),
  (26, 67, 1, 3.90),
  (27, 67, 1, 3.90),
  (28, 9, 1, 12.90),
  (29, 57, 2, 55.10),
  (30, 16, 1, 69.90),
  (31, 26, 1, 10.90),
  (32, 61, 1, 64.70),
  (33, 4, 1, 14.90),
  (33, 56, 1, 161.80),
  (34, 61, 1, 64.70),
  (35, 29, 1, 9.90),
  (35, 55, 2, 558.00),
  (36, 56, 1, 161.80),
  (37, 63, 1, 97.00),
  (38, 26, 1, 10.90),
  (38, 55, 1, 558.00),
  (39, 61, 1, 64.70),
  (40, 55, 1, 558.00),
  (41, 55, 1, 558.00),
  (42, 27, 1, 21.90),
  (42, 59, 2, 19.90),
  (43, 56, 1, 161.80),
  (44, 61, 1, 64.70),
  (45, 34, 1, 26.90),
  (46, 40, 1, 17.90),
  (47, 60, 1, 184.70),
  (48, 13, 1, 22.90),
  (49, 57, 1, 55.10),
  (49, 61, 1, 64.70),
  (50, 28, 2, 12.90),
  (51, 14, 1, 10.50),
  (51, 56, 1, 161.80),
  (52, 43, 1, 30.90),
  (53, 33, 1, 25.90),
  (53, 42, 1, 16.90),
  (54, 57, 1, 55.10),
  (55, 33, 1, 25.90),
  (56, 56, 1, 161.80),
  (57, 9, 3, 12.90),
  (57, 14, 2, 10.50),
  (57, 33, 2, 25.90),
  (58, 61, 1, 64.70),
  (59, 55, 1, 558.00),
  (60, 29, 1, 9.90),
  (61, 33, 1, 25.90),
  (62, 10, 2, 15.90),
  (63, 37, 1, 25.90),
  (63, 63, 1, 97.00),
  (64, 61, 3, 64.70),
  (64, 63, 2, 97.00),
  (65, 33, 2, 25.90),
  (66, 60, 1, 184.70),
  (67, 29, 2, 9.90),
  (67, 57, 1, 55.10),
  (68, 39, 1, 36.90),
  (69, 57, 1, 55.10),
  (69, 61, 1, 64.70),
  (70, 60, 1, 184.70),
  (71, 42, 1, 16.90),
  (71, 43, 1, 30.90),
  (72, 57, 2, 55.10),
  (73, 26, 1, 10.90),
  (74, 6, 1, 8.90),
  (75, 40, 3, 17.90),
  (76, 9, 1, 12.90),
  (76, 43, 1, 30.90),
  (77, 33, 1, 25.90),
  (78, 26, 1, 10.90),
  (78, 49, 2, 16.90),
  (79, 36, 1, 23.90),
  (80, 42, 1, 16.90),
  (81, 61, 1, 64.70),
  (82, 29, 1, 9.90),
  (83, 57, 2, 55.10),
  (84, 56, 1, 161.80),
  (85, 56, 1, 161.80),
  (86, 55, 1, 558.00),
  (87, 15, 1, 29.90),
  (88, 29, 1, 9.90),
  (89, 62, 1, 325.60),
  (90, 60, 1, 184.70),
  (91, 37, 1, 25.90),
  (91, 62, 1, 325.60),
  (92, 49, 1, 16.90),
  (93, 30, 2, 19.90),
  (94, 55, 1, 558.00),
  (95, 16, 1, 69.90),
  (95, 22, 2, 8.90),
  (95, 62, 2, 325.60),
  (96, 16, 1, 69.90),
  (97, 63, 1, 97.00),
  (98, 56, 1, 161.80),
  (98, 59, 1, 19.90),
  (99, 55, 1, 558.00),
  (100, 39, 1, 36.90),
  (101, 49, 1, 16.90),
  (101, 62, 1, 325.60),
  (102, 61, 1, 64.70),
  (103, 55, 1, 558.00),
  (104, 60, 1, 184.70),
  (105, 45, 2, 25.90),
  (106, 55, 1, 558.00),
  (107, 33, 1, 25.90),
  (107, 42, 1, 16.90),
  (108, 57, 1, 55.10),
  (108, 62, 1, 325.60),
  (109, 33, 1, 25.90),
  (109, 47, 1, 17.90),
  (110, 41, 1, 15.90),
  (111, 55, 1, 558.00),
  (112, 60, 1, 184.70),
  (113, 13, 1, 22.90),
  (114, 49, 1, 16.90),
  (114, 57, 1, 55.10),
  (115, 13, 1, 22.90),
  (116, 26, 1, 10.90),
  (116, 53, 1, 20.90),
  (117, 13, 2, 22.90),
  (118, 29, 1, 9.90),
  (118, 61, 1, 64.70),
  (119, 62, 1, 325.60),
  (120, 25, 1, 10.50),
  (120, 57, 1, 55.10),
  (121, 33, 1, 25.90),
  (121, 61, 1, 64.70),
  (122, 61, 1, 64.70),
  (123, 45, 1, 25.90),
  (124, 62, 1, 325.60),
  (125, 59, 1, 19.90),
  (126, 44, 2, 47.90),
  (127, 45, 1, 25.90),
  (128, 59, 1, 19.90),
  (128, 63, 1, 97.00),
  (129, 33, 1, 25.90),
  (130, 38, 2, 19.90),
  (131, 50, 1, 21.90),
  (131, 62, 1, 325.60),
  (132, 6, 2, 8.90),
  (133, 29, 3, 9.90),
  (133, 43, 1, 30.90),
  (134, 55, 1, 558.00),
  (135, 45, 1, 25.90),
  (136, 29, 1, 9.90),
  (137, 36, 1, 23.90),
  (138, 35, 1, 31.90),
  (139, 42, 1, 16.90),
  (140, 2, 1, 9.90),
  (141, 29, 1, 9.90),
  (142, 61, 1, 64.70),
  (143, 56, 1, 161.80),
  (144, 4, 2, 14.90),
  (145, 51, 1, 23.90),
  (146, 13, 1, 22.90),
  (147, 61, 1, 64.70),
  (148, 61, 2, 64.70),
  (149, 43, 1, 30.90),
  (150, 61, 1, 64.70),
  (151, 56, 1, 161.80),
  (152, 16, 1, 69.90),
  (153, 55, 1, 558.00),
  (154, 55, 1, 558.00),
  (155, 45, 1, 25.90),
  (156, 4, 1, 14.90),
  (156, 57, 1, 55.10),
  (157, 14, 1, 10.50),
  (158, 17, 1, 5.90),
  (159, 3, 1, 10.90),
  (160, 59, 1, 19.90),
  (161, 11, 1, 19.50);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES
  (162, 60, 1, 184.70),
  (163, 50, 1, 21.90),
  (164, 26, 2, 10.90),
  (164, 63, 1, 97.00),
  (165, 11, 1, 19.50),
  (166, 33, 1, 25.90),
  (167, 22, 1, 8.90),
  (168, 37, 2, 25.90),
  (169, 43, 1, 30.90),
  (169, 45, 1, 25.90),
  (170, 61, 1, 64.70),
  (170, 65, 1, 4.90),
  (171, 10, 1, 15.90),
  (171, 30, 1, 19.90),
  (171, 62, 1, 325.60),
  (172, 12, 1, 19.90),
  (173, 42, 1, 16.90),
  (173, 55, 1, 558.00),
  (174, 45, 1, 25.90),
  (175, 45, 1, 25.90),
  (176, 45, 1, 25.90),
  (176, 60, 1, 184.70),
  (177, 57, 1, 55.10),
  (178, 60, 1, 184.70),
  (179, 26, 1, 10.90),
  (180, 22, 1, 8.90),
  (180, 25, 1, 10.50),
  (181, 13, 1, 22.90),
  (182, 11, 2, 19.50),
  (183, 26, 1, 10.90),
  (184, 2, 2, 9.90),
  (184, 59, 3, 19.90),
  (185, 38, 1, 19.90),
  (186, 55, 1, 558.00),
  (187, 38, 1, 19.90),
  (188, 3, 1, 10.90),
  (189, 63, 2, 97.00),
  (190, 28, 1, 12.90),
  (191, 57, 1, 55.10),
  (192, 62, 1, 325.60),
  (193, 4, 1, 14.90),
  (193, 61, 1, 64.70),
  (194, 33, 1, 25.90),
  (194, 57, 1, 55.10),
  (195, 41, 1, 15.90),
  (196, 57, 1, 55.10),
  (196, 60, 1, 184.70),
  (197, 15, 1, 29.90),
  (198, 30, 1, 19.90),
  (199, 17, 1, 5.90),
  (200, 4, 3, 14.90),
  (201, 55, 1, 558.00),
  (202, 45, 2, 25.90),
  (203, 59, 1, 19.90),
  (204, 56, 1, 161.80),
  (205, 47, 1, 17.90),
  (205, 63, 1, 97.00),
  (206, 34, 1, 26.90),
  (207, 56, 1, 161.80),
  (208, 63, 1, 97.00),
  (209, 4, 2, 14.90),
  (210, 55, 1, 558.00),
  (211, 27, 1, 21.90),
  (212, 55, 1, 558.00),
  (213, 55, 1, 558.00),
  (214, 45, 1, 25.90),
  (215, 20, 3, 7.90),
  (215, 26, 2, 10.90),
  (215, 50, 1, 21.90),
  (216, 61, 1, 64.70),
  (217, 61, 1, 64.70),
  (218, 63, 1, 97.00),
  (219, 25, 1, 10.50),
  (220, 11, 1, 19.50),
  (221, 59, 1, 19.90),
  (222, 62, 1, 325.60),
  (222, 67, 1, 3.90),
  (223, 55, 1, 585.90),
  (224, 11, 1, 19.50),
  (224, 25, 1, 10.50),
  (224, 60, 1, 193.90),
  (225, 54, 2, 20.90),
  (226, 30, 1, 19.90),
  (227, 30, 1, 19.90),
  (228, 63, 1, 101.90),
  (229, 39, 1, 36.90),
  (230, 16, 2, 69.90),
  (230, 33, 1, 25.90),
  (231, 40, 1, 17.90),
  (232, 46, 1, 55.90),
  (232, 55, 1, 585.90),
  (233, 61, 1, 67.90),
  (233, 65, 1, 4.90),
  (234, 43, 3, 30.90),
  (234, 54, 1, 20.90),
  (235, 29, 1, 9.90),
  (236, 55, 1, 585.90),
  (237, 37, 1, 25.90),
  (238, 11, 1, 19.50),
  (239, 11, 1, 19.50),
  (239, 55, 1, 585.90),
  (240, 56, 1, 169.90),
  (241, 26, 1, 10.90),
  (242, 63, 1, 101.90),
  (243, 43, 1, 30.90),
  (244, 56, 1, 169.90),
  (245, 63, 1, 101.90),
  (246, 33, 2, 25.90),
  (247, 28, 1, 12.90),
  (248, 62, 1, 341.90),
  (249, 44, 1, 47.90),
  (250, 44, 1, 47.90),
  (251, 27, 1, 21.90),
  (252, 61, 1, 67.90),
  (253, 11, 1, 19.50),
  (253, 37, 1, 25.90),
  (254, 55, 1, 585.90),
  (255, 60, 1, 193.90),
  (256, 56, 1, 169.90),
  (257, 26, 1, 10.90),
  (258, 47, 2, 17.90),
  (259, 42, 1, 16.90),
  (260, 57, 1, 57.90),
  (261, 16, 1, 69.90),
  (262, 44, 1, 47.90),
  (263, 40, 1, 17.90),
  (264, 9, 1, 12.90),
  (265, 33, 2, 25.90),
  (265, 57, 3, 57.90),
  (266, 39, 1, 36.90),
  (267, 46, 1, 55.90),
  (268, 63, 1, 101.90),
  (269, 45, 1, 25.90),
  (270, 16, 1, 69.90),
  (271, 45, 1, 25.90),
  (272, 56, 1, 169.90),
  (273, 45, 1, 25.90),
  (274, 63, 1, 101.90),
  (275, 46, 1, 55.90),
  (276, 61, 1, 67.90),
  (277, 37, 1, 25.90),
  (278, 15, 1, 29.90),
  (279, 29, 1, 9.90),
  (280, 61, 1, 67.90),
  (281, 55, 1, 585.90),
  (282, 61, 1, 67.90),
  (283, 42, 1, 16.90),
  (283, 45, 1, 25.90),
  (283, 63, 2, 101.90),
  (284, 62, 1, 341.90),
  (285, 55, 1, 585.90),
  (286, 33, 1, 25.90),
  (287, 57, 1, 57.90),
  (287, 61, 1, 67.90),
  (288, 2, 1, 9.90),
  (289, 35, 1, 31.90),
  (290, 30, 1, 19.90),
  (291, 55, 1, 585.90),
  (292, 26, 1, 10.90),
  (292, 63, 1, 101.90),
  (293, 61, 1, 67.90),
  (293, 62, 1, 341.90),
  (294, 41, 1, 15.90),
  (295, 54, 1, 20.90),
  (295, 55, 1, 585.90),
  (296, 13, 2, 22.90),
  (297, 42, 1, 16.90),
  (298, 15, 1, 29.90),
  (299, 13, 1, 22.90),
  (299, 54, 2, 20.90),
  (299, 60, 1, 193.90),
  (300, 33, 1, 25.90),
  (301, 54, 2, 20.90),
  (302, 26, 1, 10.90),
  (303, 57, 1, 57.90),
  (304, 62, 1, 341.90),
  (305, 62, 1, 341.90),
  (306, 44, 1, 47.90),
  (307, 16, 1, 69.90),
  (308, 55, 1, 585.90),
  (309, 59, 1, 19.90),
  (310, 63, 1, 101.90),
  (311, 38, 1, 19.90),
  (312, 41, 1, 15.90),
  (313, 54, 1, 20.90),
  (314, 11, 1, 19.50),
  (315, 61, 1, 67.90),
  (316, 61, 1, 67.90),
  (317, 61, 1, 67.90),
  (317, 62, 1, 341.90),
  (318, 26, 1, 10.90),
  (319, 43, 1, 30.90),
  (319, 63, 1, 101.90),
  (320, 19, 1, 35.90),
  (321, 62, 1, 341.90),
  (321, 67, 1, 3.90),
  (322, 4, 1, 14.90),
  (322, 59, 1, 19.90),
  (323, 15, 1, 29.90),
  (324, 39, 1, 36.90);
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES
  (324, 63, 2, 101.90),
  (325, 24, 1, 8.60),
  (325, 63, 1, 101.90),
  (326, 62, 1, 341.90),
  (327, 25, 1, 10.50),
  (327, 56, 1, 169.90),
  (327, 61, 2, 67.90),
  (328, 62, 1, 341.90),
  (329, 38, 1, 19.90),
  (330, 62, 1, 341.90),
  (331, 25, 1, 10.50),
  (332, 16, 2, 69.90),
  (333, 56, 1, 169.90),
  (333, 63, 2, 101.90),
  (334, 45, 1, 25.90),
  (335, 60, 1, 193.90),
  (336, 40, 1, 17.90),
  (337, 47, 1, 17.90),
  (337, 57, 1, 57.90),
  (338, 63, 1, 101.90),
  (339, 56, 1, 169.90),
  (340, 16, 1, 69.90),
  (340, 37, 1, 25.90),
  (340, 63, 1, 101.90),
  (341, 13, 1, 22.90),
  (341, 39, 1, 36.90),
  (342, 62, 1, 341.90),
  (343, 55, 1, 585.90),
  (344, 63, 1, 101.90),
  (345, 60, 1, 193.90),
  (346, 57, 1, 57.90),
  (346, 60, 1, 193.90),
  (347, 11, 2, 19.50),
  (348, 33, 1, 25.90),
  (348, 41, 3, 15.90),
  (348, 54, 1, 20.90),
  (349, 66, 1, 6.90),
  (350, 63, 1, 101.90),
  (351, 61, 1, 67.90),
  (352, 61, 1, 67.90),
  (353, 58, 1, 9.90),
  (354, 13, 1, 22.90),
  (354, 40, 1, 17.90),
  (355, 33, 1, 25.90),
  (356, 62, 1, 341.90),
  (357, 63, 1, 101.90),
  (358, 45, 1, 25.90),
  (359, 60, 1, 193.90),
  (360, 59, 1, 19.90),
  (360, 63, 1, 101.90),
  (361, 26, 1, 10.90),
  (362, 39, 1, 36.90),
  (363, 63, 1, 101.90),
  (364, 39, 1, 36.90),
  (364, 43, 1, 30.90),
  (365, 55, 1, 585.90),
  (366, 51, 1, 23.90),
  (366, 62, 1, 341.90),
  (367, 62, 1, 341.90),
  (368, 55, 1, 585.90),
  (368, 56, 1, 169.90),
  (368, 57, 1, 57.90),
  (369, 61, 1, 67.90),
  (370, 43, 1, 30.90),
  (371, 55, 1, 585.90),
  (372, 43, 1, 30.90),
  (373, 33, 1, 25.90),
  (374, 16, 1, 69.90),
  (375, 33, 1, 25.90),
  (376, 15, 1, 29.90),
  (377, 22, 1, 8.90),
  (378, 61, 1, 67.90),
  (379, 55, 1, 585.90),
  (380, 27, 1, 21.90),
  (381, 56, 1, 169.90),
  (381, 57, 1, 57.90),
  (381, 61, 1, 67.90),
  (382, 36, 1, 23.90),
  (383, 8, 1, 10.90),
  (383, 13, 1, 22.90),
  (383, 36, 1, 23.90),
  (384, 63, 1, 101.90),
  (385, 49, 1, 16.90),
  (386, 10, 1, 15.90),
  (387, 56, 1, 169.90),
  (388, 55, 1, 585.90),
  (389, 22, 1, 8.90),
  (389, 52, 1, 333.90),
  (390, 63, 2, 101.90),
  (391, 10, 3, 15.90),
  (391, 61, 2, 67.90),
  (392, 55, 1, 585.90),
  (393, 4, 1, 14.90),
  (394, 33, 1, 25.90),
  (395, 56, 1, 169.90),
  (396, 33, 1, 25.90),
  (397, 60, 1, 193.90),
  (398, 33, 1, 25.90),
  (398, 45, 2, 25.90),
  (399, 45, 1, 25.90),
  (400, 42, 1, 16.90),
  (401, 29, 1, 9.90),
  (401, 57, 1, 57.90),
  (402, 39, 1, 36.90),
  (403, 56, 1, 169.90),
  (404, 63, 1, 101.90),
  (405, 26, 1, 10.90),
  (405, 34, 1, 26.90),
  (405, 62, 1, 341.90),
  (406, 33, 1, 25.90),
  (407, 16, 1, 69.90),
  (408, 15, 1, 29.90),
  (409, 4, 1, 14.90),
  (410, 36, 1, 23.90),
  (411, 45, 1, 25.90),
  (412, 33, 1, 25.90),
  (413, 56, 1, 169.90),
  (413, 64, 2, 10.90),
  (414, 61, 1, 67.90),
  (415, 61, 1, 67.90),
  (416, 63, 1, 101.90),
  (417, 40, 1, 17.90),
  (418, 43, 1, 30.90),
  (419, 60, 1, 193.90),
  (420, 62, 1, 341.90),
  (421, 67, 1, 3.90),
  (422, 16, 1, 69.90),
  (423, 26, 1, 10.90),
  (424, 26, 1, 10.90),
  (425, 49, 1, 16.90),
  (426, 33, 1, 25.90),
  (427, 4, 1, 14.90),
  (427, 63, 1, 101.90),
  (428, 16, 1, 69.90),
  (429, 63, 1, 101.90),
  (430, 54, 1, 20.90),
  (431, 65, 1, 4.90),
  (432, 55, 1, 585.90),
  (433, 10, 1, 15.90),
  (434, 15, 1, 29.90),
  (435, 56, 1, 169.90),
  (436, 14, 2, 10.50),
  (436, 56, 1, 169.90),
  (437, 55, 1, 585.90),
  (438, 47, 2, 17.90),
  (438, 60, 2, 193.90),
  (439, 58, 1, 9.90),
  (440, 36, 1, 23.90),
  (440, 55, 1, 585.90),
  (441, 62, 1, 341.90),
  (442, 16, 1, 69.90),
  (442, 19, 1, 35.90),
  (443, 14, 2, 10.50),
  (444, 45, 2, 25.90),
  (445, 27, 1, 21.90),
  (446, 9, 1, 12.90),
  (447, 47, 1, 17.90),
  (448, 45, 1, 25.90),
  (449, 16, 1, 69.90),
  (450, 15, 1, 29.90),
  (451, 62, 1, 341.90),
  (452, 13, 1, 22.90),
  (453, 39, 1, 36.90),
  (454, 29, 1, 9.90),
  (455, 16, 2, 69.90),
  (456, 26, 1, 10.90),
  (457, 61, 1, 67.90),
  (458, 57, 2, 57.90),
  (459, 40, 1, 17.90),
  (460, 63, 1, 101.90),
  (461, 57, 1, 57.90),
  (461, 62, 1, 341.90),
  (462, 62, 1, 341.90),
  (463, 4, 1, 14.90),
  (463, 10, 1, 15.90),
  (464, 61, 1, 67.90),
  (465, 43, 1, 30.90),
  (466, 56, 1, 169.90),
  (466, 62, 1, 341.90),
  (467, 57, 1, 57.90);

INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES
  (1, 'PIX', 17.00, '2026-01-02 08:15:00', 1),
  (2, 'PIX', 175.47, '2026-01-03 11:30:00', 1),
  (3, 'DINHEIRO', 49.90, '2026-01-03 09:35:00', 1),
  (4, 'CARTAO_DEBITO', 21.90, '2026-01-03 09:05:00', 1),
  (5, 'CARTAO_DEBITO', 19.50, '2026-01-03 09:00:00', 1),
  (6, 'CARTAO_CREDITO', 95.80, '2026-01-05 10:35:00', 1),
  (8, 'PIX', 21.75, '2026-01-06 12:45:00', 1),
  (9, 'PIX', 530.10, '2026-01-07 16:15:00', 1),
  (10, 'PIX', 16.06, '2026-01-07 10:50:00', 1),
  (11, 'CARTAO_DEBITO', 161.80, '2026-01-07 17:30:00', 1),
  (12, 'DINHEIRO', 51.80, '2026-01-07 08:15:00', 1),
  (13, 'BOLETO', 249.20, '2026-02-07 15:00:00', 1),
  (15, 'CARTAO_DEBITO', 558.00, '2026-01-08 14:55:00', 1),
  (16, 'PIX', 4.65, '2026-01-08 14:40:00', 1),
  (17, 'PIX', 3.70, '2026-01-09 15:35:00', 1),
  (18, 'PIX', 153.71, '2026-01-09 10:25:00', 1),
  (20, 'PIX', 530.10, '2026-01-10 08:40:00', 1),
  (21, 'CARTAO_DEBITO', 23.90, '2026-01-10 11:35:00', 1),
  (22, 'BOLETO', 523.20, '2026-01-26 09:20:00', 1),
  (23, 'CARTAO_CREDITO', 69.90, '2026-01-12 10:15:00', 1),
  (24, 'BOLETO', 603.40, '2026-02-11 10:50:00', 1),
  (25, 'CARTAO_DEBITO', 55.80, '2026-01-12 16:45:00', 1),
  (26, 'PIX', 3.70, '2026-01-12 12:50:00', 1),
  (27, 'CARTAO_CREDITO', 3.90, '2026-01-13 08:50:00', 1),
  (29, 'CARTAO_CREDITO', 110.20, '2026-01-13 08:35:00', 1),
  (30, 'DINHEIRO', 69.90, '2026-01-14 13:40:00', 1),
  (31, 'BOLETO', 10.90, '2026-02-13 13:10:00', 1),
  (32, 'CARTAO_CREDITO', 64.70, '2026-01-14 11:00:00', 1),
  (33, 'DINHEIRO', 50, '2026-01-14 17:15:00', 1),
  (33, 'PIX', 126.70, '2026-01-14 17:15:00', 1),
  (34, 'CARTAO_CREDITO', 64.70, '2026-01-14 16:50:00', 1),
  (35, 'BOLETO', 1125.90, '2026-01-29 15:50:00', 1),
  (36, 'DINHEIRO', 161.80, '2026-01-16 08:45:00', 1),
  (37, 'PIX', 92.15, '2026-01-16 17:45:00', 1),
  (38, 'CARTAO_CREDITO', 568.90, '2026-01-16 11:15:00', 3),
  (40, 'DINHEIRO', 558.00, '2026-01-16 12:40:00', 1),
  (41, 'CARTAO_CREDITO', 558.00, '2026-01-17 09:25:00', 3),
  (42, 'PIX', 58.61, '2026-01-17 08:50:00', 1),
  (43, 'CARTAO_DEBITO', 161.80, '2026-01-19 17:50:00', 1),
  (44, 'BOLETO', 64.70, '2026-02-18 11:50:00', 1),
  (45, 'PIX', 25.56, '2026-01-19 09:55:00', 1),
  (46, 'PIX', 17.00, '2026-01-20 13:25:00', 1),
  (47, 'PIX', 175.47, '2026-01-20 14:10:00', 1),
  (48, 'CARTAO_CREDITO', 22.90, '2026-01-20 14:00:00', 1),
  (49, 'CARTAO_DEBITO', 119.80, '2026-01-20 15:05:00', 1),
  (50, 'PIX', 24.51, '2026-01-21 10:55:00', 1),
  (51, 'CARTAO_DEBITO', 172.30, '2026-01-21 15:30:00', 1),
  (52, 'CARTAO_CREDITO', 30.90, '2026-01-22 11:50:00', 1),
  (53, 'PIX', 40.66, '2026-01-22 12:15:00', 1),
  (54, 'CARTAO_DEBITO', 55.10, '2026-01-23 14:20:00', 1),
  (55, 'CARTAO_DEBITO', 25.90, '2026-01-23 08:40:00', 1),
  (56, 'CARTAO_CREDITO', 161.80, '2026-01-23 16:25:00', 1),
  (57, 'PIX', 105.92, '2026-01-23 08:35:00', 1),
  (58, 'PIX', 61.46, '2026-01-24 09:55:00', 1),
  (59, 'CARTAO_CREDITO', 558.00, '2026-01-24 08:35:00', 3),
  (60, 'CARTAO_CREDITO', 9.90, '2026-01-24 09:55:00', 1),
  (61, 'PIX', 24.61, '2026-01-26 12:20:00', 1),
  (62, 'CARTAO_DEBITO', 31.80, '2026-01-26 10:05:00', 1),
  (63, 'PIX', 116.75, '2026-01-26 12:25:00', 1),
  (64, 'PIX', 368.69, '2026-01-26 16:45:00', 1),
  (65, 'CARTAO_DEBITO', 51.80, '2026-01-26 09:55:00', 1),
  (66, 'PIX', 175.47, '2026-01-27 17:35:00', 1),
  (68, 'CARTAO_DEBITO', 36.90, '2026-01-27 12:45:00', 1),
  (69, 'PIX', 113.81, '2026-01-27 10:05:00', 1),
  (70, 'PIX', 175.47, '2026-01-28 12:20:00', 1),
  (71, 'CARTAO_CREDITO', 47.80, '2026-01-29 17:35:00', 1),
  (72, 'PIX', 104.69, '2026-01-29 11:00:00', 1),
  (73, 'BOLETO', 10.90, '2026-03-01 13:35:00', 1),
  (74, 'CARTAO_CREDITO', 8.90, '2026-01-30 09:10:00', 1),
  (75, 'CARTAO_CREDITO', 53.70, '2026-01-30 13:25:00', 1),
  (76, 'BOLETO', 43.80, '2026-03-01 15:35:00', 1),
  (77, 'PIX', 24.61, '2026-01-30 12:05:00', 1),
  (78, 'CARTAO_DEBITO', 44.70, '2026-01-31 11:30:00', 1),
  (79, 'PIX', 22.70, '2026-01-31 09:35:00', 1),
  (80, 'PIX', 16.06, '2026-01-31 11:45:00', 1),
  (81, 'DINHEIRO', 64.70, '2026-02-02 10:30:00', 1),
  (82, 'CARTAO_CREDITO', 9.90, '2026-02-02 11:15:00', 1),
  (84, 'PIX', 153.71, '2026-02-03 13:15:00', 1),
  (85, 'PIX', 153.71, '2026-02-03 11:55:00', 1),
  (86, 'PIX', 530.10, '2026-02-04 10:35:00', 1),
  (87, 'PIX', 28.40, '2026-02-04 10:30:00', 1),
  (88, 'DINHEIRO', 9.90, '2026-02-04 15:55:00', 1),
  (89, 'CARTAO_CREDITO', 325.60, '2026-02-04 11:00:00', 1),
  (91, 'DINHEIRO', 20, '2026-02-05 17:10:00', 1),
  (91, 'PIX', 331.50, '2026-02-05 17:10:00', 1),
  (92, 'PIX', 16.06, '2026-02-05 15:55:00', 1),
  (93, 'PIX', 37.81, '2026-02-06 14:15:00', 1),
  (94, 'CARTAO_DEBITO', 558.00, '2026-02-07 08:15:00', 1),
  (95, 'BOLETO', 738.90, '2026-03-07 09:00:00', 1),
  (96, 'CARTAO_CREDITO', 69.90, '2026-02-09 17:15:00', 1),
  (97, 'DINHEIRO', 97.00, '2026-02-09 14:05:00', 1),
  (98, 'PIX', 172.62, '2026-02-09 15:35:00', 1),
  (99, 'DINHEIRO', 20, '2026-02-09 15:45:00', 1),
  (99, 'PIX', 538.00, '2026-02-09 15:45:00', 1),
  (100, 'PIX', 35.06, '2026-02-11 16:40:00', 1),
  (101, 'DINHEIRO', 50, '2026-02-11 16:20:00', 1),
  (101, 'PIX', 292.50, '2026-02-11 16:20:00', 1),
  (102, 'DINHEIRO', 32.35, '2026-02-11 12:05:00', 1),
  (102, 'PIX', 32.35, '2026-02-11 12:05:00', 1),
  (103, 'CARTAO_DEBITO', 558.00, '2026-02-12 17:00:00', 1),
  (105, 'DINHEIRO', 51.80, '2026-02-13 17:55:00', 1),
  (106, 'CARTAO_CREDITO', 558.00, '2026-02-13 16:40:00', 2),
  (107, 'DINHEIRO', 42.80, '2026-02-13 13:25:00', 1),
  (108, 'CARTAO_CREDITO', 380.70, '2026-02-14 12:40:00', 1),
  (109, 'PIX', 41.61, '2026-02-14 10:05:00', 1),
  (110, 'CARTAO_CREDITO', 15.90, '2026-02-14 11:40:00', 1),
  (111, 'CARTAO_CREDITO', 558.00, '2026-02-16 12:20:00', 3),
  (112, 'CARTAO_DEBITO', 184.70, '2026-02-16 12:05:00', 1),
  (113, 'PIX', 21.75, '2026-02-16 17:00:00', 1),
  (114, 'PIX', 68.40, '2026-02-17 08:10:00', 1),
  (115, 'PIX', 21.75, '2026-02-17 11:15:00', 1),
  (116, 'CARTAO_DEBITO', 31.80, '2026-02-17 14:00:00', 1),
  (117, 'BOLETO', 45.80, '2026-03-18 16:55:00', 1),
  (118, 'CARTAO_CREDITO', 74.60, '2026-02-18 13:35:00', 1),
  (119, 'CARTAO_CREDITO', 325.60, '2026-02-18 16:20:00', 1),
  (120, 'CARTAO_DEBITO', 65.60, '2026-02-18 16:30:00', 1),
  (121, 'DINHEIRO', 90.60, '2026-02-18 09:50:00', 1),
  (122, 'CARTAO_DEBITO', 64.70, '2026-02-19 12:15:00', 1),
  (123, 'PIX', 24.61, '2026-02-19 09:30:00', 1),
  (124, 'DINHEIRO', 325.60, '2026-02-19 10:50:00', 1),
  (125, 'CARTAO_DEBITO', 19.90, '2026-02-20 08:35:00', 1),
  (126, 'CARTAO_DEBITO', 95.80, '2026-02-20 14:15:00', 1),
  (127, 'CARTAO_DEBITO', 25.90, '2026-02-20 16:55:00', 1),
  (128, 'DINHEIRO', 58.45, '2026-02-23 13:20:00', 1),
  (128, 'PIX', 58.45, '2026-02-23 13:20:00', 1),
  (129, 'CARTAO_CREDITO', 25.90, '2026-02-23 08:55:00', 1),
  (130, 'CARTAO_DEBITO', 39.80, '2026-02-23 13:25:00', 1),
  (131, 'CARTAO_CREDITO', 347.50, '2026-02-23 14:10:00', 1),
  (132, 'CARTAO_DEBITO', 17.80, '2026-02-23 11:05:00', 1),
  (133, 'BOLETO', 60.60, '2026-03-24 13:45:00', 1),
  (135, 'CARTAO_DEBITO', 25.90, '2026-02-24 15:10:00', 1),
  (136, 'BOLETO', 9.90, '2026-03-10 08:55:00', 1),
  (137, 'PIX', 22.70, '2026-02-25 12:50:00', 1),
  (138, 'DINHEIRO', 31.90, '2026-02-25 15:40:00', 1),
  (139, 'CARTAO_DEBITO', 16.90, '2026-02-25 09:20:00', 1),
  (140, 'PIX', 9.40, '2026-02-26 08:10:00', 1),
  (141, 'CARTAO_CREDITO', 9.90, '2026-02-26 09:35:00', 1),
  (142, 'CARTAO_CREDITO', 64.70, '2026-02-27 16:30:00', 1),
  (143, 'PIX', 153.71, '2026-02-28 11:55:00', 1),
  (144, 'BOLETO', 29.80, '2026-03-28 09:25:00', 1),
  (145, 'PIX', 22.70, '2026-03-02 15:45:00', 1),
  (146, 'PIX', 21.75, '2026-03-02 11:25:00', 1),
  (147, 'PIX', 61.46, '2026-03-02 17:50:00', 1),
  (148, 'PIX', 122.93, '2026-03-02 12:05:00', 1),
  (149, 'PIX', 29.36, '2026-03-03 17:20:00', 1),
  (150, 'CARTAO_CREDITO', 64.70, '2026-03-03 15:05:00', 1),
  (151, 'CARTAO_DEBITO', 161.80, '2026-03-04 13:40:00', 1),
  (152, 'PIX', 66.40, '2026-03-04 14:30:00', 1),
  (153, 'DINHEIRO', 558.00, '2026-03-04 12:40:00', 1),
  (154, 'CARTAO_CREDITO', 558.00, '2026-03-05 16:55:00', 1),
  (155, 'PIX', 24.61, '2026-03-05 17:55:00', 1),
  (156, 'DINHEIRO', 70.00, '2026-03-05 14:25:00', 1),
  (157, 'PIX', 9.97, '2026-03-06 09:30:00', 1),
  (158, 'PIX', 5.60, '2026-03-06 16:15:00', 1),
  (159, 'PIX', 10.35, '2026-03-07 12:40:00', 1),
  (160, 'PIX', 18.91, '2026-03-07 08:45:00', 1),
  (161, 'PIX', 18.52, '2026-03-07 11:40:00', 1),
  (162, 'CARTAO_CREDITO', 184.70, '2026-03-09 11:25:00', 1),
  (163, 'PIX', 20.81, '2026-03-09 12:10:00', 1),
  (164, 'PIX', 112.86, '2026-03-09 17:15:00', 1),
  (165, 'CARTAO_DEBITO', 19.50, '2026-03-09 16:45:00', 1),
  (166, 'PIX', 24.61, '2026-03-10 08:35:00', 1),
  (167, 'PIX', 8.45, '2026-03-10 08:40:00', 1),
  (168, 'DINHEIRO', 51.80, '2026-03-10 08:35:00', 1),
  (169, 'CARTAO_CREDITO', 56.80, '2026-03-10 12:20:00', 1),
  (170, 'PIX', 66.12, '2026-03-11 12:10:00', 1),
  (171, 'CARTAO_CREDITO', 361.40, '2026-03-11 14:05:00', 2),
  (173, 'PIX', 546.15, '2026-03-11 12:40:00', 1),
  (174, 'CARTAO_DEBITO', 25.90, '2026-03-12 15:30:00', 1),
  (175, 'CARTAO_CREDITO', 25.90, '2026-03-12 13:55:00', 1),
  (176, 'CARTAO_DEBITO', 210.60, '2026-03-12 09:25:00', 1),
  (177, 'PIX', 52.34, '2026-03-12 08:30:00', 1),
  (178, 'PIX', 175.47, '2026-03-12 09:40:00', 1),
  (179, 'PIX', 10.35, '2026-03-13 09:20:00', 1),
  (180, 'CARTAO_DEBITO', 19.40, '2026-03-13 13:10:00', 1),
  (181, 'CARTAO_CREDITO', 22.90, '2026-03-14 11:55:00', 1),
  (182, 'CARTAO_CREDITO', 39.00, '2026-03-14 11:50:00', 1),
  (183, 'PIX', 10.35, '2026-03-14 08:25:00', 1),
  (184, 'BOLETO', 79.50, '2026-04-15 17:05:00', 1),
  (185, 'CARTAO_CREDITO', 19.90, '2026-03-16 16:40:00', 1),
  (186, 'CARTAO_DEBITO', 558.00, '2026-03-17 16:45:00', 1),
  (187, 'CARTAO_CREDITO', 19.90, '2026-03-17 12:55:00', 1),
  (188, 'CARTAO_CREDITO', 10.90, '2026-03-17 10:25:00', 1),
  (189, 'PIX', 184.30, '2026-03-18 15:10:00', 1),
  (190, 'DINHEIRO', 12.90, '2026-03-18 16:25:00', 1),
  (191, 'CARTAO_DEBITO', 55.10, '2026-03-18 09:50:00', 1),
  (192, 'PIX', 309.32, '2026-03-19 17:10:00', 1),
  (193, 'CARTAO_DEBITO', 79.60, '2026-03-19 15:40:00', 1),
  (194, 'PIX', 76.95, '2026-03-19 11:15:00', 1),
  (195, 'PIX', 15.10, '2026-03-20 09:55:00', 1),
  (196, 'CARTAO_DEBITO', 239.80, '2026-03-21 10:40:00', 1),
  (197, 'CARTAO_CREDITO', 29.90, '2026-03-21 10:15:00', 1),
  (198, 'PIX', 18.91, '2026-03-21 12:15:00', 1),
  (199, 'PIX', 5.60, '2026-03-23 13:35:00', 1),
  (201, 'CARTAO_DEBITO', 558.00, '2026-03-23 15:50:00', 1),
  (202, 'DINHEIRO', 51.80, '2026-03-23 17:45:00', 1),
  (203, 'PIX', 18.91, '2026-03-24 16:50:00', 1),
  (205, 'PIX', 109.15, '2026-03-24 09:10:00', 1),
  (206, 'CARTAO_CREDITO', 26.90, '2026-03-24 10:55:00', 1),
  (208, 'PIX', 92.15, '2026-03-25 11:45:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES
  (209, 'BOLETO', 29.80, '2026-04-24 13:05:00', 1),
  (210, 'DINHEIRO', 558.00, '2026-03-26 09:00:00', 1),
  (211, 'PIX', 20.81, '2026-03-26 16:50:00', 1),
  (212, 'PIX', 530.10, '2026-03-26 14:50:00', 1),
  (213, 'PIX', 530.10, '2026-03-26 08:20:00', 1),
  (214, 'DINHEIRO', 25.90, '2026-03-27 08:55:00', 1),
  (215, 'PIX', 64.03, '2026-03-27 09:55:00', 1),
  (217, 'CARTAO_CREDITO', 64.70, '2026-03-28 11:30:00', 1),
  (218, 'DINHEIRO', 48.50, '2026-03-30 15:00:00', 1),
  (218, 'PIX', 48.50, '2026-03-30 15:00:00', 1),
  (219, 'PIX', 9.97, '2026-03-30 17:10:00', 1),
  (220, 'BOLETO', 19.50, '2026-04-28 15:55:00', 1),
  (221, 'DINHEIRO', 19.90, '2026-03-31 10:05:00', 1),
  (222, 'DINHEIRO', 329.50, '2026-03-31 14:10:00', 1),
  (223, 'PIX', 556.60, '2026-04-01 16:10:00', 1),
  (224, 'DINHEIRO', 223.90, '2026-04-02 13:40:00', 1),
  (225, 'PIX', 39.71, '2026-04-02 16:35:00', 1),
  (226, 'CARTAO_DEBITO', 19.90, '2026-04-02 10:20:00', 1),
  (227, 'CARTAO_DEBITO', 19.90, '2026-04-02 10:00:00', 1),
  (228, 'DINHEIRO', 50.95, '2026-04-02 11:05:00', 1),
  (228, 'PIX', 50.95, '2026-04-02 11:05:00', 1),
  (229, 'PIX', 35.06, '2026-04-02 16:05:00', 1),
  (230, 'DINHEIRO', 165.70, '2026-04-03 13:45:00', 1),
  (231, 'CARTAO_CREDITO', 17.90, '2026-04-03 10:00:00', 1),
  (232, 'CARTAO_DEBITO', 641.80, '2026-04-03 16:15:00', 1),
  (233, 'PIX', 69.16, '2026-04-04 10:55:00', 1),
  (234, 'BOLETO', 113.60, '2026-04-18 11:25:00', 1),
  (235, 'CARTAO_CREDITO', 9.90, '2026-04-06 15:40:00', 1),
  (236, 'PIX', 556.60, '2026-04-06 12:55:00', 1),
  (237, 'CARTAO_CREDITO', 25.90, '2026-04-06 16:30:00', 1),
  (238, 'CARTAO_DEBITO', 19.50, '2026-04-07 10:50:00', 1),
  (239, 'PIX', 575.13, '2026-04-08 16:10:00', 1),
  (240, 'CARTAO_CREDITO', 169.90, '2026-04-08 16:45:00', 1),
  (241, 'PIX', 10.35, '2026-04-08 08:55:00', 1),
  (242, 'CARTAO_CREDITO', 101.90, '2026-04-08 14:45:00', 1),
  (243, 'DINHEIRO', 30.90, '2026-04-08 13:35:00', 1),
  (244, 'CARTAO_DEBITO', 169.90, '2026-04-09 16:40:00', 1),
  (246, 'CARTAO_DEBITO', 51.80, '2026-04-09 08:30:00', 1),
  (247, 'PIX', 12.25, '2026-04-09 14:25:00', 1),
  (248, 'CARTAO_DEBITO', 341.90, '2026-04-10 12:40:00', 1),
  (249, 'PIX', 45.50, '2026-04-10 16:45:00', 1),
  (250, 'PIX', 45.50, '2026-04-11 09:30:00', 1),
  (251, 'CARTAO_CREDITO', 21.90, '2026-04-11 10:10:00', 1),
  (252, 'PIX', 64.50, '2026-04-13 09:45:00', 1),
  (253, 'DINHEIRO', 45.40, '2026-04-13 15:00:00', 1),
  (254, 'CARTAO_DEBITO', 585.90, '2026-04-14 17:00:00', 1),
  (255, 'CARTAO_DEBITO', 193.90, '2026-04-14 12:55:00', 1),
  (256, 'CARTAO_DEBITO', 169.90, '2026-04-14 10:05:00', 1),
  (257, 'PIX', 10.35, '2026-04-14 10:05:00', 1),
  (258, 'PIX', 34.01, '2026-04-14 16:30:00', 1),
  (259, 'CARTAO_DEBITO', 16.90, '2026-04-14 14:40:00', 1),
  (260, 'PIX', 55.00, '2026-04-14 11:00:00', 1),
  (261, 'DINHEIRO', 69.90, '2026-04-15 12:00:00', 1),
  (262, 'CARTAO_DEBITO', 47.90, '2026-04-15 16:50:00', 1),
  (263, 'CARTAO_DEBITO', 17.90, '2026-04-15 08:05:00', 1),
  (264, 'PIX', 12.25, '2026-04-16 16:25:00', 1),
  (265, 'PIX', 214.22, '2026-04-16 14:55:00', 1),
  (266, 'PIX', 35.06, '2026-04-16 15:05:00', 1),
  (267, 'CARTAO_CREDITO', 55.90, '2026-04-16 12:45:00', 1),
  (268, 'PIX', 96.80, '2026-04-16 16:10:00', 1),
  (269, 'PIX', 24.61, '2026-04-17 13:25:00', 1),
  (270, 'PIX', 66.40, '2026-04-17 10:55:00', 1),
  (271, 'CARTAO_CREDITO', 25.90, '2026-04-17 10:00:00', 1),
  (272, 'PIX', 161.40, '2026-04-17 16:25:00', 1),
  (273, 'PIX', 24.61, '2026-04-17 14:55:00', 1),
  (274, 'PIX', 96.80, '2026-04-17 15:30:00', 1),
  (275, 'PIX', 53.11, '2026-04-18 10:20:00', 1),
  (276, 'CARTAO_CREDITO', 67.90, '2026-04-18 12:10:00', 1),
  (277, 'CARTAO_CREDITO', 25.90, '2026-04-18 11:25:00', 1),
  (278, 'CARTAO_CREDITO', 29.90, '2026-04-18 08:30:00', 1),
  (279, 'PIX', 9.40, '2026-04-20 09:10:00', 1),
  (280, 'CARTAO_DEBITO', 67.90, '2026-04-20 12:25:00', 1),
  (281, 'DINHEIRO', 585.90, '2026-04-20 11:10:00', 1),
  (282, 'PIX', 64.50, '2026-04-20 13:25:00', 1),
  (283, 'PIX', 234.27, '2026-04-21 17:45:00', 1),
  (284, 'CARTAO_CREDITO', 341.90, '2026-04-21 17:05:00', 2),
  (285, 'DINHEIRO', 585.90, '2026-04-22 09:30:00', 1),
  (286, 'CARTAO_CREDITO', 25.90, '2026-04-22 09:25:00', 1),
  (287, 'CARTAO_CREDITO', 125.80, '2026-04-23 11:30:00', 1),
  (288, 'PIX', 9.40, '2026-04-23 09:05:00', 1),
  (289, 'CARTAO_DEBITO', 31.90, '2026-04-23 17:20:00', 1),
  (290, 'DINHEIRO', 19.90, '2026-04-23 10:40:00', 1),
  (291, 'DINHEIRO', 585.90, '2026-04-24 17:40:00', 1),
  (293, 'PIX', 389.31, '2026-04-24 09:30:00', 1),
  (294, 'PIX', 15.10, '2026-04-25 12:00:00', 1),
  (295, 'CARTAO_DEBITO', 606.80, '2026-04-27 17:25:00', 1),
  (296, 'PIX', 43.51, '2026-04-27 13:15:00', 1),
  (297, 'BOLETO', 16.90, '2026-05-11 12:15:00', 1),
  (298, 'CARTAO_CREDITO', 29.90, '2026-04-28 14:45:00', 1),
  (299, 'PIX', 245.67, '2026-04-28 16:55:00', 1),
  (300, 'DINHEIRO', 25.90, '2026-04-28 14:45:00', 1),
  (301, 'PIX', 39.71, '2026-04-28 09:20:00', 1),
  (302, 'PIX', 10.35, '2026-04-29 17:40:00', 1),
  (303, 'CARTAO_CREDITO', 57.90, '2026-04-29 12:35:00', 1),
  (304, 'PIX', 324.81, '2026-04-29 14:50:00', 1),
  (306, 'PIX', 45.50, '2026-04-29 10:05:00', 1),
  (307, 'CARTAO_CREDITO', 69.90, '2026-04-30 14:40:00', 1),
  (308, 'PIX', 556.60, '2026-04-30 15:15:00', 1),
  (309, 'CARTAO_CREDITO', 19.90, '2026-04-30 09:35:00', 1),
  (310, 'BOLETO', 101.90, '2026-05-31 12:45:00', 1),
  (311, 'CARTAO_CREDITO', 19.90, '2026-05-01 09:10:00', 1),
  (312, 'PIX', 15.10, '2026-05-01 09:05:00', 1),
  (313, 'CARTAO_DEBITO', 20.90, '2026-05-01 13:05:00', 1),
  (314, 'BOLETO', 19.50, '2026-05-29 08:35:00', 1),
  (315, 'CARTAO_DEBITO', 67.90, '2026-05-01 16:40:00', 1),
  (316, 'CARTAO_CREDITO', 67.90, '2026-05-02 08:20:00', 1),
  (317, 'PIX', 389.31, '2026-05-02 09:20:00', 1),
  (318, 'DINHEIRO', 10.90, '2026-05-04 09:05:00', 1),
  (319, 'CARTAO_CREDITO', 132.80, '2026-05-04 10:55:00', 1),
  (320, 'PIX', 34.11, '2026-05-04 14:35:00', 1),
  (321, 'PIX', 328.51, '2026-05-04 14:00:00', 1),
  (322, 'DINHEIRO', 34.80, '2026-05-04 12:10:00', 1),
  (323, 'CARTAO_CREDITO', 29.90, '2026-05-04 17:05:00', 1),
  (324, 'PIX', 228.66, '2026-05-05 17:25:00', 1),
  (325, 'DINHEIRO', 110.50, '2026-05-05 09:25:00', 1),
  (326, 'CARTAO_CREDITO', 341.90, '2026-05-05 10:45:00', 2),
  (327, 'PIX', 300.39, '2026-05-05 13:05:00', 1),
  (328, 'PIX', 324.81, '2026-05-05 13:40:00', 1),
  (329, 'CARTAO_DEBITO', 19.90, '2026-05-05 12:00:00', 1),
  (330, 'PIX', 324.81, '2026-05-06 11:00:00', 1),
  (331, 'CARTAO_DEBITO', 10.50, '2026-05-07 15:00:00', 1),
  (332, 'PIX', 132.81, '2026-05-07 08:55:00', 1),
  (333, 'BOLETO', 373.70, '2026-05-21 17:50:00', 1),
  (334, 'PIX', 24.61, '2026-05-08 14:00:00', 1),
  (335, 'CARTAO_DEBITO', 193.90, '2026-05-08 16:25:00', 1),
  (336, 'BOLETO', 17.90, '2026-06-06 10:50:00', 1),
  (337, 'PIX', 72.01, '2026-05-09 08:55:00', 1),
  (338, 'CARTAO_DEBITO', 101.90, '2026-05-09 11:25:00', 1),
  (339, 'PIX', 161.40, '2026-05-09 12:55:00', 1),
  (340, 'PIX', 187.82, '2026-05-11 09:00:00', 1),
  (341, 'DINHEIRO', 59.80, '2026-05-11 09:55:00', 1),
  (342, 'PIX', 324.81, '2026-05-11 13:30:00', 1),
  (343, 'CARTAO_DEBITO', 585.90, '2026-05-11 13:15:00', 1),
  (344, 'PIX', 96.80, '2026-05-11 14:30:00', 1),
  (345, 'CARTAO_DEBITO', 193.90, '2026-05-12 08:20:00', 1),
  (346, 'DINHEIRO', 251.80, '2026-05-12 11:10:00', 1),
  (347, 'CARTAO_CREDITO', 39.00, '2026-05-12 10:40:00', 1),
  (348, 'BOLETO', 94.50, '2026-06-09 14:45:00', 1),
  (349, 'PIX', 6.55, '2026-05-12 10:05:00', 1),
  (350, 'DINHEIRO', 50.95, '2026-05-12 09:05:00', 1),
  (350, 'PIX', 50.95, '2026-05-12 09:05:00', 1),
  (351, 'PIX', 64.50, '2026-05-13 15:50:00', 1),
  (352, 'PIX', 64.50, '2026-05-13 09:15:00', 1),
  (354, 'PIX', 38.76, '2026-05-14 10:40:00', 1),
  (355, 'PIX', 24.61, '2026-05-14 11:20:00', 1),
  (356, 'CARTAO_CREDITO', 341.90, '2026-05-15 09:40:00', 1),
  (357, 'PIX', 96.80, '2026-05-15 14:40:00', 1),
  (358, 'CARTAO_CREDITO', 25.90, '2026-05-15 14:45:00', 1),
  (359, 'PIX', 184.20, '2026-05-15 17:05:00', 1),
  (360, 'DINHEIRO', 100, '2026-05-16 12:50:00', 1),
  (360, 'PIX', 21.80, '2026-05-16 12:50:00', 1),
  (361, 'PIX', 10.35, '2026-05-18 11:55:00', 1),
  (362, 'PIX', 35.06, '2026-05-18 10:40:00', 1),
  (363, 'PIX', 96.80, '2026-05-19 08:10:00', 1),
  (364, 'CARTAO_CREDITO', 67.80, '2026-05-19 11:45:00', 1),
  (365, 'DINHEIRO', 100, '2026-05-19 12:00:00', 1),
  (365, 'PIX', 485.90, '2026-05-19 12:00:00', 1),
  (366, 'PIX', 347.51, '2026-05-19 14:45:00', 1),
  (367, 'DINHEIRO', 50, '2026-05-20 16:25:00', 1),
  (367, 'PIX', 291.90, '2026-05-20 16:25:00', 1),
  (368, 'BOLETO', 813.70, '2026-06-19 16:15:00', 1),
  (369, 'CARTAO_CREDITO', 67.90, '2026-05-20 14:10:00', 1),
  (370, 'PIX', 29.36, '2026-05-21 13:30:00', 1),
  (371, 'DINHEIRO', 585.90, '2026-05-21 13:10:00', 1),
  (372, 'CARTAO_DEBITO', 30.90, '2026-05-21 17:30:00', 1),
  (373, 'PIX', 24.61, '2026-05-22 10:00:00', 1),
  (374, 'DINHEIRO', 34.95, '2026-05-22 13:10:00', 1),
  (374, 'PIX', 34.95, '2026-05-22 13:10:00', 1),
  (376, 'CARTAO_DEBITO', 29.90, '2026-05-25 11:05:00', 1),
  (377, 'CARTAO_CREDITO', 8.90, '2026-05-25 16:00:00', 1),
  (378, 'CARTAO_DEBITO', 67.90, '2026-05-25 14:10:00', 1),
  (379, 'CARTAO_CREDITO', 585.90, '2026-05-26 17:40:00', 3),
  (381, 'DINHEIRO', 295.70, '2026-05-26 17:35:00', 1),
  (383, 'DINHEIRO', 57.70, '2026-05-26 17:00:00', 1),
  (384, 'PIX', 96.80, '2026-05-26 11:55:00', 1),
  (385, 'CARTAO_DEBITO', 16.90, '2026-05-27 16:10:00', 1),
  (386, 'DINHEIRO', 15.90, '2026-05-27 17:40:00', 1),
  (387, 'CARTAO_DEBITO', 169.90, '2026-05-27 12:20:00', 1),
  (388, 'CARTAO_DEBITO', 585.90, '2026-05-27 13:30:00', 1),
  (389, 'BOLETO', 342.80, '2026-06-26 15:50:00', 1),
  (390, 'PIX', 193.61, '2026-05-28 11:30:00', 1),
  (391, 'BOLETO', 183.50, '2026-06-28 15:40:00', 1),
  (392, 'CARTAO_CREDITO', 585.90, '2026-05-30 11:20:00', 1),
  (393, 'CARTAO_CREDITO', 14.90, '2026-06-01 13:45:00', 1),
  (394, 'PIX', 24.61, '2026-06-01 13:00:00', 1),
  (395, 'CARTAO_DEBITO', 169.90, '2026-06-01 16:50:00', 1),
  (396, 'PIX', 24.61, '2026-06-02 12:55:00', 1),
  (397, 'PIX', 184.20, '2026-06-02 16:20:00', 1),
  (398, 'CARTAO_CREDITO', 77.70, '2026-06-02 15:05:00', 1),
  (399, 'PIX', 24.61, '2026-06-02 10:30:00', 1),
  (400, 'PIX', 16.06, '2026-06-03 14:30:00', 1),
  (401, 'CARTAO_DEBITO', 67.80, '2026-06-03 16:25:00', 1),
  (402, 'DINHEIRO', 36.90, '2026-06-04 10:35:00', 1),
  (403, 'CARTAO_DEBITO', 169.90, '2026-06-04 17:25:00', 1),
  (404, 'CARTAO_DEBITO', 101.90, '2026-06-04 15:45:00', 1),
  (405, 'PIX', 360.72, '2026-06-04 17:20:00', 1),
  (406, 'CARTAO_DEBITO', 25.90, '2026-06-04 17:55:00', 1),
  (407, 'PIX', 66.40, '2026-06-04 09:35:00', 1),
  (408, 'PIX', 28.40, '2026-06-05 16:00:00', 1),
  (409, 'DINHEIRO', 14.90, '2026-06-08 11:00:00', 1);
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas) VALUES
  (410, 'DINHEIRO', 23.90, '2026-06-08 17:25:00', 1),
  (411, 'BOLETO', 25.90, '2026-07-06 10:20:00', 1),
  (414, 'CARTAO_CREDITO', 67.90, '2026-06-08 10:35:00', 1),
  (415, 'PIX', 64.50, '2026-06-09 11:00:00', 1),
  (416, 'CARTAO_DEBITO', 101.90, '2026-06-09 17:10:00', 1),
  (417, 'PIX', 17.00, '2026-06-09 16:25:00', 1),
  (418, 'PIX', 29.36, '2026-06-10 15:30:00', 1),
  (419, 'DINHEIRO', 193.90, '2026-06-10 08:35:00', 1),
  (422, 'CARTAO_DEBITO', 69.90, '2026-06-12 17:30:00', 1),
  (423, 'PIX', 10.35, '2026-06-12 14:30:00', 1),
  (424, 'DINHEIRO', 10.90, '2026-06-13 10:25:00', 1),
  (426, 'DINHEIRO', 25.90, '2026-06-15 11:10:00', 1),
  (427, 'CARTAO_CREDITO', 116.80, '2026-06-15 08:10:00', 1),
  (429, 'CARTAO_DEBITO', 101.90, '2026-06-16 10:05:00', 1),
  (430, 'BOLETO', 20.90, '2026-07-16 08:05:00', 1),
  (431, 'PIX', 4.65, '2026-06-16 12:40:00', 1),
  (432, 'PIX', 556.60, '2026-06-17 13:20:00', 1),
  (433, 'CARTAO_DEBITO', 15.90, '2026-06-17 17:35:00', 1),
  (434, 'CARTAO_DEBITO', 29.90, '2026-06-17 11:50:00', 1),
  (435, 'PIX', 161.40, '2026-06-18 13:15:00', 1),
  (436, 'DINHEIRO', 190.90, '2026-06-18 11:40:00', 1),
  (437, 'CARTAO_CREDITO', 585.90, '2026-06-18 12:45:00', 1),
  (438, 'PIX', 402.42, '2026-06-18 12:40:00', 1),
  (439, 'PIX', 9.40, '2026-06-19 16:15:00', 1),
  (441, 'CARTAO_CREDITO', 341.90, '2026-06-19 09:50:00', 1),
  (442, 'CARTAO_DEBITO', 105.80, '2026-06-22 10:35:00', 1),
  (444, 'CARTAO_DEBITO', 51.80, '2026-06-22 16:25:00', 1),
  (445, 'CARTAO_CREDITO', 21.90, '2026-06-22 08:00:00', 1),
  (446, 'PIX', 12.25, '2026-06-23 15:45:00', 1),
  (447, 'CARTAO_DEBITO', 17.90, '2026-06-23 10:55:00', 1),
  (448, 'CARTAO_CREDITO', 25.90, '2026-06-23 09:15:00', 1),
  (449, 'CARTAO_CREDITO', 69.90, '2026-06-23 12:15:00', 1),
  (450, 'PIX', 28.40, '2026-06-23 14:10:00', 1),
  (451, 'PIX', 324.81, '2026-06-24 12:45:00', 1),
  (452, 'CARTAO_CREDITO', 22.90, '2026-06-24 17:20:00', 1),
  (453, 'PIX', 35.06, '2026-06-24 13:25:00', 1),
  (454, 'BOLETO', 9.90, '2026-07-22 17:20:00', 1),
  (455, 'DINHEIRO', 139.80, '2026-06-24 08:00:00', 1),
  (456, 'PIX', 10.35, '2026-06-25 10:10:00', 1),
  (457, 'PIX', 64.50, '2026-06-25 17:30:00', 1),
  (458, 'CARTAO_DEBITO', 115.80, '2026-06-26 08:30:00', 1),
  (459, 'PIX', 17.00, '2026-06-26 11:35:00', 1),
  (460, 'CARTAO_DEBITO', 101.90, '2026-06-26 08:10:00', 1),
  (462, 'CARTAO_CREDITO', 341.90, '2026-06-29 15:45:00', 2),
  (463, 'PIX', 29.26, '2026-06-29 12:50:00', 1),
  (464, 'PIX', 64.50, '2026-06-29 12:15:00', 1),
  (465, 'PIX', 29.36, '2026-06-30 14:40:00', 1),
  (466, 'PIX', 486.21, '2026-06-30 13:00:00', 1),
  (467, 'CARTAO_CREDITO', 57.90, '2026-06-30 12:05:00', 1);

-- Produtos descontinuados no fim do periodo: saem de linha, o historico permanece (RN17)
UPDATE produto SET ativo = 0 WHERE id_produto IN (9, 34);

-- Custo de aquisicao: valores estimados pela margem informada pela loja (45% tintas, 65% maioria,
-- acima de 100% itens pequenos); o custo real de cada item esta no sistema da loja
UPDATE produto SET preco_custo = 4.24 WHERE id_produto = 1;
UPDATE produto SET preco_custo = 4.50 WHERE id_produto = 2;
UPDATE produto SET preco_custo = 6.61 WHERE id_produto = 3;
UPDATE produto SET preco_custo = 9.03 WHERE id_produto = 4;
UPDATE produto SET preco_custo = 3.95 WHERE id_produto = 5;
UPDATE produto SET preco_custo = 4.24 WHERE id_produto = 6;
UPDATE produto SET preco_custo = 30.24 WHERE id_produto = 7;
UPDATE produto SET preco_custo = 6.61 WHERE id_produto = 8;
UPDATE produto SET preco_custo = 7.82 WHERE id_produto = 9;
UPDATE produto SET preco_custo = 9.64 WHERE id_produto = 10;
UPDATE produto SET preco_custo = 11.82 WHERE id_produto = 11;
UPDATE produto SET preco_custo = 12.06 WHERE id_produto = 12;
UPDATE produto SET preco_custo = 13.88 WHERE id_produto = 13;
UPDATE produto SET preco_custo = 6.36 WHERE id_produto = 14;
UPDATE produto SET preco_custo = 18.12 WHERE id_produto = 15;
UPDATE produto SET preco_custo = 42.36 WHERE id_produto = 16;
UPDATE produto SET preco_custo = 2.68 WHERE id_produto = 17;
UPDATE produto SET preco_custo = 6.61 WHERE id_produto = 18;
UPDATE produto SET preco_custo = 21.76 WHERE id_produto = 19;
UPDATE produto SET preco_custo = 3.95 WHERE id_produto = 20;
UPDATE produto SET preco_custo = 4.24 WHERE id_produto = 21;
UPDATE produto SET preco_custo = 4.05 WHERE id_produto = 22;
UPDATE produto SET preco_custo = 4.30 WHERE id_produto = 23;
UPDATE produto SET preco_custo = 3.58 WHERE id_produto = 24;
UPDATE produto SET preco_custo = 6.36 WHERE id_produto = 25;
UPDATE produto SET preco_custo = 6.61 WHERE id_produto = 26;
UPDATE produto SET preco_custo = 13.27 WHERE id_produto = 27;
UPDATE produto SET preco_custo = 7.82 WHERE id_produto = 28;
UPDATE produto SET preco_custo = 4.12 WHERE id_produto = 29;
UPDATE produto SET preco_custo = 12.06 WHERE id_produto = 30;
UPDATE produto SET preco_custo = 7.21 WHERE id_produto = 31;
UPDATE produto SET preco_custo = 9.03 WHERE id_produto = 32;
UPDATE produto SET preco_custo = 15.70 WHERE id_produto = 33;
UPDATE produto SET preco_custo = 16.30 WHERE id_produto = 34;
UPDATE produto SET preco_custo = 19.33 WHERE id_produto = 35;
UPDATE produto SET preco_custo = 14.48 WHERE id_produto = 36;
UPDATE produto SET preco_custo = 15.70 WHERE id_produto = 37;
UPDATE produto SET preco_custo = 12.06 WHERE id_produto = 38;
UPDATE produto SET preco_custo = 22.36 WHERE id_produto = 39;
UPDATE produto SET preco_custo = 10.85 WHERE id_produto = 40;
UPDATE produto SET preco_custo = 9.64 WHERE id_produto = 41;
UPDATE produto SET preco_custo = 10.24 WHERE id_produto = 42;
UPDATE produto SET preco_custo = 18.73 WHERE id_produto = 43;
UPDATE produto SET preco_custo = 29.03 WHERE id_produto = 44;
UPDATE produto SET preco_custo = 15.70 WHERE id_produto = 45;
UPDATE produto SET preco_custo = 33.88 WHERE id_produto = 46;
UPDATE produto SET preco_custo = 10.85 WHERE id_produto = 47;
UPDATE produto SET preco_custo = 3.00 WHERE id_produto = 48;
UPDATE produto SET preco_custo = 10.24 WHERE id_produto = 49;
UPDATE produto SET preco_custo = 13.27 WHERE id_produto = 50;
UPDATE produto SET preco_custo = 14.48 WHERE id_produto = 51;
UPDATE produto SET preco_custo = 202.36 WHERE id_produto = 52;
UPDATE produto SET preco_custo = 12.67 WHERE id_produto = 53;
UPDATE produto SET preco_custo = 12.67 WHERE id_produto = 54;
UPDATE produto SET preco_custo = 404.07 WHERE id_produto = 55;
UPDATE produto SET preco_custo = 117.17 WHERE id_produto = 56;
UPDATE produto SET preco_custo = 39.93 WHERE id_produto = 57;
UPDATE produto SET preco_custo = 4.30 WHERE id_produto = 58;
UPDATE produto SET preco_custo = 12.06 WHERE id_produto = 59;
UPDATE produto SET preco_custo = 133.72 WHERE id_produto = 60;
UPDATE produto SET preco_custo = 46.83 WHERE id_produto = 61;
UPDATE produto SET preco_custo = 235.79 WHERE id_produto = 62;
UPDATE produto SET preco_custo = 70.28 WHERE id_produto = 63;
UPDATE produto SET preco_custo = 6.61 WHERE id_produto = 64;
UPDATE produto SET preco_custo = 2.45 WHERE id_produto = 65;
UPDATE produto SET preco_custo = 3.29 WHERE id_produto = 66;
UPDATE produto SET preco_custo = 1.77 WHERE id_produto = 67;

-- Historico do reajuste de 5% das tintas em 01/04/2026 (a partir daqui o trigger registra sozinho)
INSERT INTO historico_preco (id_produto, preco_anterior, preco_novo, data_alteracao) VALUES
  (55, 558.00, 585.90, '2026-04-01 08:00:00'),
  (56, 161.80, 169.90, '2026-04-01 08:00:00'),
  (57, 55.10, 57.90, '2026-04-01 08:00:00'),
  (60, 184.70, 193.90, '2026-04-01 08:00:00'),
  (61, 64.70, 67.90, '2026-04-01 08:00:00'),
  (62, 325.60, 341.90, '2026-04-01 08:00:00'),
  (63, 97.00, 101.90, '2026-04-01 08:00:00');

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

-- o trigger trg_produto_after_update_preco registrou cada reajuste (RN21)
SELECT h.id_historico, p.descricao, h.preco_anterior, h.preco_novo, h.data_alteracao
FROM historico_preco h JOIN produto p ON p.id_produto = h.id_produto
ORDER BY h.id_historico DESC LIMIT 10;

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

-- pagamento da venda convertida no debito (RN09: venda concluida e paga integralmente;
-- no debito nao ha o desconto de 5% do PIX - RN19)
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, data_pagamento, parcelas)
SELECT id_venda, 'CARTAO_DEBITO', valor_total, data_venda, 1 FROM venda WHERE id_venda = @orc;

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
SET v.valor_total = (SELECT SUM(i.subtotal) FROM item_venda i WHERE i.id_venda = v.id_venda) - v.valor_desconto
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
SELECT v.id_venda, v.valor_total AS total_registrado,
       SUM(iv.subtotal) - v.valor_desconto AS total_calculado
FROM venda v JOIN item_venda iv ON iv.id_venda = v.id_venda
WHERE v.id_venda = @demo GROUP BY v.id_venda, v.valor_total, v.valor_desconto;
ROLLBACK;

-- =====================================================================
-- Maximo das Tintas - 07 Consultas gerenciais (G01 a G19)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- Cada consulta traz: codigo, pergunta, problema (P1..P6) ou KPI que atende.
-- KPIs (formula, periodo e meta) estao na secao 1.6 do README.
-- =====================================================================
USE loja_tintas_materiais;

-- G01 — Qual o faturamento de cada mes (vendas concluidas)?
-- Atende: KPI1 Faturamento mensal (meta: R$ 10.000/mes = R$ 300 a 500 por dia, informado pela loja) · P3
SELECT mes, qtd_vendas, faturamento,
       ROUND(faturamento / 10000 * 100, 1) AS pct_da_meta
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
-- Atende: KPI3 Unidades vendidas por mes (referencia da loja: 100 a 120/mes) · P4
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

-- G07 — Quanto cada categoria fatura (receita bruta dos itens, antes do desconto PIX) e qual a participacao?
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

-- G17 — Quais produtos tiveram aumento de preco, quando e de quanto?
-- Atende: KPI13 Reajuste medio por periodo · relatorio pedido pela loja ("aumento de preco de produtos") · P3
SELECT DATE_FORMAT(h.data_alteracao, '%Y-%m') AS mes, p.descricao, f.nome_fornecedor,
       h.preco_anterior, h.preco_novo,
       ROUND(100 * (h.preco_novo - h.preco_anterior) / h.preco_anterior, 1) AS reajuste_pct
FROM historico_preco h
JOIN produto p    ON p.id_produto = h.id_produto
JOIN fornecedor f ON f.id_fornecedor = p.id_fornecedor
ORDER BY h.data_alteracao, p.descricao;

-- G18 — Qual a margem por categoria (preco praticado x custo)?
-- Atende: KPI14 Margem sobre o custo (markup) e margem bruta, mensal · RN16
-- Referencia da loja: 45% sobre o custo nas tintas, 65% na maioria, acima de 100% nos itens pequenos.
SELECT cat.nome_categoria,
       SUM(iv.subtotal) AS receita_bruta,
       SUM(iv.quantidade * p.preco_custo) AS custo,
       ROUND(100 * (SUM(iv.subtotal) - SUM(iv.quantidade * p.preco_custo)) / SUM(iv.quantidade * p.preco_custo), 1) AS margem_sobre_custo_pct,
       ROUND(100 * (SUM(iv.subtotal) - SUM(iv.quantidade * p.preco_custo)) / SUM(iv.subtotal), 1) AS margem_bruta_pct
FROM item_venda iv
JOIN venda v       ON v.id_venda = iv.id_venda
JOIN produto p     ON p.id_produto = iv.id_produto
JOIN categoria cat ON cat.id_categoria = p.id_categoria
WHERE v.status_venda = 'CONCLUIDA' AND p.preco_custo IS NOT NULL
GROUP BY cat.nome_categoria
ORDER BY margem_sobre_custo_pct DESC;

-- G19 — Quanto a loja concede de desconto no PIX por mes e quanto isso pesa no faturamento?
-- Atende: KPI15 Desconto PIX / faturamento bruto, mensal · RN19 · P5
SELECT DATE_FORMAT(data_venda, '%Y-%m') AS mes,
       SUM(valor_desconto > 0) AS vendas_com_desconto,
       SUM(valor_desconto) AS desconto_total,
       ROUND(100 * SUM(valor_desconto) / SUM(valor_total + valor_desconto), 2) AS desconto_sobre_bruto_pct
FROM venda
WHERE status_venda = 'CONCLUIDA'
GROUP BY DATE_FORMAT(data_venda, '%Y-%m')
ORDER BY mes;

-- =====================================================================
-- Maximo das Tintas - 08 Consultas de auditoria (A01 a A13)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- Cada consulta verifica uma regra de negocio (RNxx). Resultado esperado:
-- NENHUMA linha (0 violacoes). Se aparecer linha, ha inconsistencia a corrigir.
-- =====================================================================
USE loja_tintas_materiais;

-- A01 — Existe venda cujo total nao bate com a soma dos itens menos o desconto?
-- Verifica: RN05 (total da venda = soma dos subtotais - desconto)
SELECT v.id_venda, v.status_venda,
       v.valor_total AS valor_total_registrado,
       COALESCE(SUM(iv.subtotal), 0) - v.valor_desconto AS valor_total_calculado
FROM venda v
LEFT JOIN item_venda iv ON iv.id_venda = v.id_venda
GROUP BY v.id_venda, v.status_venda, v.valor_total, v.valor_desconto
HAVING v.valor_total <> COALESCE(SUM(iv.subtotal), 0) - v.valor_desconto;

-- A02 — Existe venda concluida sem nenhum pagamento?
-- Verifica: RN09 (venda concluida e paga)
SELECT v.id_venda, v.data_venda, v.valor_total
FROM venda v
LEFT JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA' AND pg.id_pagamento IS NULL;

-- A03 — Existe venda concluida cuja soma dos pagamentos difere do total?
-- Verifica: RN09 (pagamento integral, em uma ou mais formas)
SELECT v.id_venda, v.valor_total, SUM(pg.valor_pago) AS total_pago
FROM venda v
JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY v.id_venda, v.valor_total
HAVING SUM(pg.valor_pago) <> v.valor_total;

-- A04 — Existe orcamento com pagamento registrado?
-- Verifica: RN10 (orcamento nao gera pagamento)
SELECT v.id_venda, v.data_venda, pg.id_pagamento, pg.valor_pago
FROM venda v
JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'ORCAMENTO';

-- A05 — Existe produto sem registro de estoque?
-- Verifica: RN13 (todo produto tem exatamente um registro de estoque)
SELECT p.id_produto, p.descricao
FROM produto p
LEFT JOIN estoque e ON e.id_produto = p.id_produto
WHERE e.id_estoque IS NULL;

-- A06 — Existe estoque negativo?
-- Verifica: RN07 (a CHECK ja impede; a consulta audita ambientes sem CHECK)
SELECT e.id_produto, e.quantidade_atual
FROM estoque e
WHERE e.quantidade_atual < 0;

-- A07 — Existe venda concluida sem nenhum item?
-- Verifica: RN02 (toda venda concluida tem ao menos um item)
SELECT v.id_venda, v.data_venda, v.valor_total
FROM venda v
LEFT JOIN item_venda iv ON iv.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA' AND iv.id_item_venda IS NULL;

-- A08 — Existe CPF/CNPJ duplicado ou fora do formato (PF = 11 digitos, PJ = 14)?
-- Verifica: RN11
SELECT c.id_cliente, c.nome, c.tipo_pessoa, c.cpf_cnpj, 'formato invalido' AS problema
FROM cliente c
WHERE NOT ((c.tipo_pessoa = 'PF' AND c.cpf_cnpj REGEXP '^[0-9]{11}$')
        OR (c.tipo_pessoa = 'PJ' AND c.cpf_cnpj REGEXP '^[0-9]{14}$'))
UNION ALL
SELECT NULL, NULL, NULL, c.cpf_cnpj, CONCAT('duplicado ', COUNT(*), 'x')
FROM cliente c
GROUP BY c.cpf_cnpj
HAVING COUNT(*) > 1;

-- A09 — Existe pagamento parcelado fora do cartao de credito?
-- Verifica: RN09 (parcelamento so no cartao de credito)
SELECT pg.id_pagamento, pg.id_venda, pg.forma_pagamento, pg.parcelas
FROM pagamento pg
WHERE pg.parcelas > 1 AND pg.forma_pagamento <> 'CARTAO_CREDITO';

-- A10 — Existe pagamento registrado antes da data da venda?
-- Verifica: RN09 (o pagamento acontece na venda ou depois, ex.: boleto)
SELECT pg.id_pagamento, pg.id_venda, v.data_venda, pg.data_pagamento
FROM pagamento pg
JOIN venda v ON v.id_venda = pg.id_venda
WHERE pg.data_pagamento < v.data_venda;

-- A11 — Existe desconto fora da regra (so no PIX, unico pagamento, e de 5% do valor bruto)?
-- Verifica: RN19 (desconto de 5% no PIX)
SELECT v.id_venda, v.valor_desconto,
       ROUND((v.valor_total + v.valor_desconto) * 0.05, 2) AS desconto_esperado,
       GROUP_CONCAT(pg.forma_pagamento) AS formas
FROM venda v
LEFT JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.valor_desconto > 0
GROUP BY v.id_venda, v.valor_desconto, v.valor_total
HAVING GROUP_CONCAT(pg.forma_pagamento) IS NULL
    OR GROUP_CONCAT(pg.forma_pagamento) <> 'PIX'
    OR ABS(v.valor_desconto - ROUND((v.valor_total + v.valor_desconto) * 0.05, 2)) > 0.01;

-- A12 — Existe parcelamento fora da politica da loja (2x a partir de R$ 200, 3x a partir de R$ 400)?
-- Verifica: RN20 (excecoes ate o limite de 24x sao permitidas "a criterio da maquininha";
-- a consulta lista essas excecoes para conferencia; acima de 24x a CHECK ja bloqueia)
SELECT pg.id_pagamento, pg.id_venda, pg.valor_pago, pg.parcelas
FROM pagamento pg
WHERE pg.forma_pagamento = 'CARTAO_CREDITO'
  AND ((pg.parcelas = 2 AND pg.valor_pago < 200)
    OR (pg.parcelas = 3 AND pg.valor_pago < 400)
    OR  pg.parcelas > 3);

-- A13 — O preco atual de algum produto difere do ultimo preco registrado no historico?
-- Verifica: RN21 (todo reajuste fica no historico)
SELECT p.id_produto, p.descricao, p.preco_unitario, h.preco_novo AS ultimo_preco_no_historico
FROM produto p
JOIN historico_preco h ON h.id_produto = p.id_produto
WHERE h.id_historico = (SELECT MAX(h2.id_historico) FROM historico_preco h2 WHERE h2.id_produto = p.id_produto)
  AND h.preco_novo <> p.preco_unitario;

