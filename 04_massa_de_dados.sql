-- =====================================================================
-- Maximo das Tintas - 04 Massa de dados ficticia (INSERT)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- =====================================================================
USE loja_tintas_materiais;

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

