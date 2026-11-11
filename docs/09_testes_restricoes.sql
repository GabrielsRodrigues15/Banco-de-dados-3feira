-- =====================================================================
-- Maximo das Tintas - 09 Testes de restricoes (operacoes que DEVEM falhar)
-- NAO faz parte do script unico: rode DEPOIS do docs/script.sql, com --force
-- para o cliente continuar apos cada erro esperado:
--
--   mysql -u root -p --force loja_tintas_materiais < docs/09_testes_restricoes.sql
--
-- Cada teste mostra a regra de negocio (RNxx) e o erro esperado do MySQL.
-- Nenhum teste altera o banco (todos sao rejeitados).
-- =====================================================================
USE loja_tintas_materiais;

-- Venda concluida, produto ja presente nela e produto que NAO esta nela (para os testes)
SELECT MAX(id_venda) INTO @v FROM venda WHERE status_venda = 'CONCLUIDA';
SELECT MIN(id_produto) INTO @p_na_venda FROM item_venda WHERE id_venda = @v;
SELECT MIN(p.id_produto) INTO @p_livre FROM produto p
WHERE p.ativo = 1 AND p.id_produto NOT IN (SELECT id_produto FROM item_venda WHERE id_venda = @v);
SELECT MIN(id_produto) INTO @p_inativo FROM produto WHERE ativo = 0;

-- T01 RN02 Quantidade do item deve ser > 0                -> ERROR 3819 chk_item_qtd
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (@v, @p_livre, 0, 9.90);

-- T02 Preco do produto nao pode ser negativo              -> ERROR 3819 chk_produto_preco
INSERT INTO produto (codigo_interno, descricao, preco_unitario, id_categoria, id_fornecedor)
VALUES ('TESTE01', 'PRODUTO TESTE', -1.00, 1, 1);

-- T03 RN11 CPF/CNPJ de cliente e unico                     -> ERROR 1062 uq_cliente_doc
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj) VALUES ('Cliente Duplicado', 'PF', '00000000000');

-- T04 RN11 PF precisa de CPF com 11 digitos                -> ERROR 3819 chk_cliente_doc
INSERT INTO cliente (nome, tipo_pessoa, cpf_cnpj) VALUES ('CPF Curto', 'PF', '12345');

-- T05 RN12 Codigo interno (PDV) do produto e unico         -> ERROR 1062 uq_produto_codigo
INSERT INTO produto (codigo_interno, descricao, preco_unitario, id_categoria, id_fornecedor)
VALUES ('16642', 'CODIGO DUPLICADO', 1.00, 1, 1);

-- T06 RN01 Item so pode referenciar produto existente      -> ERROR 1452 fk_item_produto
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (@v, 9999, 1, 1.00);

-- T07 RN01 Produto inativo nao pode ser vendido            -> ERROR 1644 (SIGNAL do trigger)
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (@v, @p_inativo, 1, 1.00);

-- T08 RN14 Venda exige cliente cadastrado                  -> ERROR 1452 fk_venda_cliente
INSERT INTO venda (id_cliente, id_funcionario) VALUES (999999, 1);

-- T09 RN03 Mesmo produto nao repete na mesma venda         -> ERROR 1062 uq_item_venda_produto
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (@v, @p_na_venda, 1, 1.00);

-- T10 RN07 Estoque nunca negativo: venda de 100.000 unidades
--      (o trigger tenta baixar o estoque e a CHECK barra)  -> ERROR 3819 chk_estoque_qtd
INSERT INTO item_venda (id_venda, id_produto, quantidade, preco_unitario_venda) VALUES (@v, @p_livre, 100000, 9.90);

-- T11 RN09 Parcelas >= 1                                   -> ERROR 3819 chk_pagamento_parcelas
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, parcelas) VALUES (@v, 'PIX', 10.00, 0);

-- T12 RN09 Forma de pagamento fora do dominio              -> ERROR 1265 (ENUM)
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago) VALUES (@v, 'CHEQUE', 10.00);

-- T13 RN17 Produto com historico nao pode ser apagado (inativar com ativo = 0)
--                                                          -> ERROR 1451 fk_estoque_produto / fk_item_produto
DELETE FROM produto WHERE id_produto = @p_na_venda;

-- T14 RN17 Cliente com historico nao pode ser apagado      -> ERROR 1451 fk_venda_cliente
DELETE FROM cliente WHERE id_cliente = 1;

-- T15 RN19 Desconto da venda nao pode ser negativo         -> ERROR 3819 chk_venda_desconto
INSERT INTO venda (id_cliente, id_funcionario, valor_desconto) VALUES (1, 1, -5.00);

-- T16 RN21 Historico nao aceita "reajuste" com o mesmo preco -> ERROR 3819 chk_historico_precos
INSERT INTO historico_preco (id_produto, preco_anterior, preco_novo) VALUES (1, 10.00, 10.00);

-- T17 RN20 Limite de 24 parcelas no credito                -> ERROR 3819 chk_pagamento_parcelas
INSERT INTO pagamento (id_venda, forma_pagamento, valor_pago, parcelas) VALUES (@v, 'CARTAO_CREDITO', 10.00, 25);

-- Conferencia: nada foi gravado pelos testes acima (esperado: 0 e 0)
SELECT COUNT(*) AS produtos_teste FROM produto WHERE codigo_interno = 'TESTE01';
SELECT COUNT(*) AS clientes_teste FROM cliente WHERE nome IN ('Cliente Duplicado', 'CPF Curto');
