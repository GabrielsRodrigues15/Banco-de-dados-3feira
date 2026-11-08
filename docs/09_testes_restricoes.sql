-- =====================================================================
-- Maximo das Tintas - 09 Testes de restricoes (operacoes que DEVEM falhar)
-- NAO faz parte do script unico: rode DEPOIS do docs/script.sql, com --force
-- para o cliente continuar apos cada erro esperado:
--
--   mysql -u root -p --force loja_tintas_materiais < docs/09_testes_restricoes.sql
--
-- Cada bloco mostra a regra de negocio testada e o erro esperado do MySQL.
-- Nenhum teste altera o banco (todos sao rejeitados).
-- Resultado obtido em MySQL 8.0.46: 11 de 11 operacoes rejeitadas.
-- =====================================================================
USE loja_tintas_materiais;

-- T01 Quantidade do item deve ser > 0           -> ERROR 3819 chk_item_qtd
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (6, 2, 0, 9.90);

-- T02 Preco do produto nao pode ser negativo    -> ERROR 3819 chk_produto_preco
INSERT INTO produto (codigo_interno, descricao, preco_unitario, id_categoria, id_fornecedor)
VALUES ('TESTE01', 'PRODUTO TESTE', -1.00, 1, 1);

-- T03 CPF/CNPJ de cliente e unico               -> ERROR 1062 uq_cliente_doc
INSERT INTO cliente (nome, cpf_cnpj) VALUES ('Cliente Duplicado', '12345678901');

-- T04 Codigo interno (PDV) do produto e unico   -> ERROR 1062 uq_produto_codigo
INSERT INTO produto (codigo_interno, descricao, preco_unitario, id_categoria, id_fornecedor)
VALUES ('16642', 'CODIGO DUPLICADO', 1.00, 1, 1);

-- T05 Item so pode referenciar produto existente -> ERROR 1452 fk_item_produto
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (6, 9999, 1, 1.00);

-- T06 Venda exige cliente cadastrado            -> ERROR 1452 fk_venda_cliente
INSERT INTO venda (id_cliente, id_funcionario) VALUES (999, 1);

-- T07 Mesmo produto nao repete na mesma venda   -> ERROR 1062 uq_item_venda_produto
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (6, 1, 1, 8.90);

-- T08 Estoque nunca fica negativo: venda CONCLUIDA de 100.000 unidades
--     (o trigger tenta baixar o estoque e a CHECK barra) -> ERROR 3819 chk_estoque_qtd
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (6, 2, 100000, 9.90);

-- T09 Parcelas >= 1                             -> ERROR 3819 chk_pagamento_parcelas
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, parcelas) VALUES (6, 'PIX', 10.00, 0);

-- T10 Forma de pagamento fora do dominio        -> ERROR 1265 (ENUM)
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago) VALUES (6, 'CHEQUE', 10.00);

-- T11 Produto com historico nao pode ser apagado (inativar com ativo = 0)
--                                               -> ERROR 1451 fk_estoque_produto / fk_item_produto
DELETE FROM produto WHERE id_produto = 1;

-- Conferencia: nada foi gravado pelos testes acima
SELECT COUNT(*) AS produtos_teste FROM produto WHERE codigo_interno = 'TESTE01';
SELECT COUNT(*) AS clientes_duplicados FROM cliente WHERE nome = 'Cliente Duplicado';
