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
    valor_total      DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_venda_total CHECK (valor_total >= 0),
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
    CONSTRAINT chk_pagamento_parcelas CHECK (parcelas >= 1),
    CONSTRAINT fk_pagamento_venda FOREIGN KEY (id_venda) REFERENCES venda(id_venda)
) ENGINE=InnoDB;

