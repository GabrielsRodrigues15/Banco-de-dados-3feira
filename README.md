# Entrega 1 — Modelo Conceitual (DER)
### Modelagem de um sistema de gestão de informações para uma organização de pequeno porte

---

## Metadados

- **Nomes dos alunos e RGM:** `[Gabriel Rodrigues Da Silva 46885030, Gabriel Souza 46683305, Vinicius Batista Merencio 46749527,Ítalo Leal Oliveira 47837098 `

---

## 1. Caracterização da Organização

> ⚠️ **Atenção do grupo:** os campos abaixo marcados com `[PREENCHER]` só podem ser respondidos com a organização **real** visitada pelo grupo. Nada aqui pode ser inventado — o enunciado exige pesquisa de campo. O texto genérico serve apenas de estrutura/exemplo de redação.

- **Nome e natureza da organização:** `[maximos das tintas]` — loja de pequeno/médio porte do varejo de **tintas, ferramentas e materiais de construção**, com fins lucrativos, atuando na venda ao consumidor final (pessoa física) e a pequenos profissionais/empresas de reforma e construção civil (pessoa jurídica).
- **Contexto e porte:** organização comercial familiar/de pequeno porte, com equipe reduzida (ex.: gerente, vendedores, caixa) e catálogo amplo de itens de giro rápido — chaves, alicates, espátulas, pincéis, rolos, fitas, solventes e tintas de marcas como Suvinil, Bilacor, Tramontina, Ferja, Tigre, Condor, Famastil e Thompson. `[PREENCHER: número real de funcionários: 2 funcionarios volume médio de vendas/mês:valor:20 mil reais.em produtos media de 500que saem do estoque  área de atendimento: os mesmos 2 funcionarios]`.
- **Problemas e necessidades identificados:** o controle de produtos hoje é feito por meio de listas de preço em PDF/planilha exportadas do sistema de frente de caixa (como os catálogos fornecidos), sem uma base relacional própria que integre catálogo, estoque, vendas, clientes e fornecedores em um único sistema. Isso dificulta: saber rapidamente o que está abaixo do estoque mínimo, cruzar vendas por vendedor/categoria/fornecedor, e gerar relatórios gerenciais sem exportar e tratar manualmente planilhas. `[PREENCHER: problemas relatados pelo responsável durante a visita]`.
- **Justificativa da escolha:** é um caso real de pequeno negócio com processos de venda, controle de estoque e relacionamento com múltiplos fornecedores — volume de dados suficiente (dezenas de categorias de produtos, múltiplas marcas/fornecedores) sem a complexidade de uma rede varejista, o que a torna adequada ao escopo da disciplina.
- **Evidências da organização:** `[https://share.google/O58fMgnEeO1ujE6RM link da loja no google  email:maximosdastintas@gmail.com]`.

---

## 2. Processos de Negócio

- **Principais processos mapeados:**
  1. **Cadastro de produtos** — inclusão de novos itens no catálogo (código interno, código de barras/EAN, descrição, NCM, unidade, preço, categoria e fornecedor).
  2. **Cadastro de clientes** — pessoa física ou jurídica, com dados de contato.
  3. **Controle de estoque** — entrada de mercadorias (compra ao fornecedor) e baixa automática a cada venda concluída.
  4. **Registro de vendas** — abertura da venda, inclusão de itens (produto + quantidade), fechamento e associação ao vendedor responsável.
  5. **Registro de pagamento** — forma de pagamento (dinheiro, PIX, cartão, boleto) e parcelamento, vinculado à venda.
  6. **Reposição de estoque** — identificação de produtos abaixo do estoque mínimo para novo pedido ao fornecedor.
- **Fluxograma (opcional):** `]`.

---

## 3. Requisitos do Sistema

### 3.1 Requisitos Funcionais
- RF01 — O sistema deve permitir cadastrar, consultar, atualizar e inativar produtos.
- RF02 — O sistema deve permitir cadastrar clientes (pessoa física ou jurídica).
- RF03 — O sistema deve permitir registrar uma venda associada a um cliente e a um funcionário responsável.
- RF04 — O sistema deve permitir adicionar múltiplos produtos a uma mesma venda, com quantidade e preço praticado no momento da venda.
- RF05 — O sistema deve calcular automaticamente o valor total da venda a partir dos itens lançados.
- RF06 — O sistema deve dar baixa no estoque do produto ao concluir uma venda.
- RF07 — O sistema deve permitir registrar um ou mais pagamentos vinculados a uma venda.
- RF08 — O sistema deve permitir consultar produtos com estoque igual ou abaixo do mínimo definido.
- RF09 — O sistema deve permitir gerar relatórios gerenciais de faturamento por período, por categoria e por vendedor.
- RF10 — O sistema deve permitir cancelar uma venda sem apagar seu histórico (mudança de status).

### 3.2 Requisitos Não Funcionais
- RNF01 — **Integridade:** toda venda deve referenciar um cliente e um funcionário já cadastrados (chaves estrangeiras obrigatórias).
- RNF02 — **Consistência:** o valor total da venda deve refletir a soma dos subtotais dos itens (verificável por consulta de auditoria).
- RNF03 — **Disponibilidade:** o sistema deve estar acessível durante o horário comercial da loja, sem indisponibilidades que impeçam o fechamento de vendas.
- RNF04 — **Segurança:** dados de clientes (CPF/CNPJ, contato) devem ter acesso restrito a usuários autorizados do sistema.
- RNF05 — **Desempenho:** consultas gerenciais (faturamento, ranking de produtos) devem responder em tempo aceitável mesmo com histórico de milhares de vendas.
- RNF06 — **Usabilidade:** o cadastro de uma venda deve ser possível em poucos passos, dado o ritmo de atendimento no balcão.

---

## 4. Regras de Negócio

- **Regras operacionais:**
  - Uma venda só pode ser registrada para um produto que exista no catálogo e esteja ativo.
  - Um item de venda não pode ter quantidade menor ou igual a zero.
  - Um produto não pode aparecer duas vezes na mesma venda como itens separados — quantidades adicionais do mesmo produto atualizam a linha existente (garantido por restrição de unicidade `venda + produto`).
  - Um pagamento só pode ser registrado para uma venda existente; o valor pago deve ser maior ou igual a zero.
  - Toda venda concluída deve gerar baixa proporcional no estoque do(s) produto(s) vendido(s).
  - O estoque de um produto não pode ficar negativo.
- **Restrições organizacionais:**
  - CPF/CNPJ de clientes e fornecedores devem ser únicos no cadastro, para evitar duplicidade de registros.
  - Cada produto pertence a exatamly uma categoria e a um fornecedor principal, para permitir relatórios gerenciais por essas dimensões.
  - `[PREENCHER: políticas específicas observadas na loja — ex. prazo de troca: 2 semanas  exigência de nota fiscal para determinadas vendas: somente para troca. forma de precificação por fornecedor:E adicoinado uma porcentagem em media 60% no valor do produto comprado pelo forncedor e repassado ao cliente como preço final após a adição do valor]`.

---

## 5. Dicionário de Dados Conceitual (Preliminar)

> Tabela completa também entregue em formato HTML: `Dicionario_Dados.html`.

### Entidade: CATEGORIA
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_categoria | Identificador único da categoria | Obrigatório, gerado automaticamente |
| nome_categoria | Nome da categoria de produto (ex.: "Tintas e Vernizes") | Obrigatório, único |
| descricao | Descrição complementar da categoria | Opcional |

### Entidade: FORNECEDOR
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_fornecedor | Identificador único do fornecedor | Obrigatório |
| nome_fornecedor | Razão social / marca do fornecedor (ex.: "Tramontina") | Obrigatório |
| cnpj | CNPJ do fornecedor | Obrigatório, único |
| telefone | Telefone de contato | Opcional |
| email | E-mail de contato | Opcional |

### Entidade: PRODUTO
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_produto | Identificador único interno | Obrigatório |
| codigo_interno | Código do produto usado no PDV da loja (ex.: "16642") | Obrigatório, único |
| codigo_barras | Código de barras/EAN do produto | Opcional (nem todo item possui EAN cadastrado) |
| descricao | Descrição comercial do produto (ex.: "CHV FENDA 1/8X5 AM TRAMON") | Obrigatório |
| ncm | Código NCM para fins fiscais | Opcional |
| unidade_medida | Unidade de venda (ex.: UN) | Obrigatório, padrão "UN" |
| preco_unitario | Preço de venda vigente | Obrigatório, deve ser ≥ 0 |
| id_categoria | Categoria à qual o produto pertence | Obrigatório (FK) |
| id_fornecedor | Fornecedor/marca do produto | Obrigatório (FK) |
| ativo | Indica se o produto ainda é comercializado | Obrigatório, padrão verdadeiro |

### Entidade: ESTOQUE
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_estoque | Identificador único do registro de estoque | Obrigatório |
| id_produto | Produto ao qual o estoque se refere | Obrigatório, único (1 estoque por produto) |
| quantidade_atual | Quantidade disponível em estoque | Obrigatório, não pode ser negativo |
| quantidade_minima | Quantidade mínima antes de disparar reposição | Obrigatório, padrão 5 |
| localizacao_deposito | Localização física no depósito/prateleira | Opcional |

### Entidade: CLIENTE
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_cliente | Identificador único | Obrigatório |
| nome | Nome/razão social do cliente | Obrigatório |
| tipo_pessoa | PF ou PJ | Obrigatório |
| cpf_cnpj | Documento do cliente | Obrigatório, único |
| telefone | Telefone de contato | Opcional |
| email | E-mail de contato | Opcional |
| endereco | Endereço do cliente | Opcional |
| data_cadastro | Data do primeiro cadastro | Obrigatório, gerada automaticamente |

*Exemplo fictício (não são dados reais de clientes da loja): "Marcos Aurelio Ribeiro", PF, telefone (11) 98765-4321.*

### Entidade: FUNCIONARIO
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_funcionario | Identificador único | Obrigatório |
| nome | Nome do funcionário | Obrigatório |
| cargo | Cargo (vendedor, caixa, gerente) | Obrigatório |
| cpf | CPF do funcionário | Obrigatório, único |
| data_admissao | Data de admissão | Obrigatório |
| ativo | Indica se ainda trabalha na loja | Obrigatório, padrão verdadeiro |

### Entidade: VENDA
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_venda | Identificador único da venda | Obrigatório |
| id_cliente | Cliente que realizou a compra | Obrigatório (FK) |
| id_funcionario | Funcionário que atendeu a venda | Obrigatório (FK) |
| data_venda | Data/hora da venda | Obrigatório, gerada automaticamente |
| status_venda | Orçamento, concluída ou cancelada | Obrigatório |
| valor_total | Soma dos subtotais dos itens da venda | Obrigatório, deve ser ≥ 0 |

### Entidade: ITEM_VENDA (associativa Venda–Produto)
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_item_venda | Identificador único do item | Obrigatório |
| id_venda | Venda à qual o item pertence | Obrigatório (FK) |
| id_produto | Produto vendido | Obrigatório (FK) |
| quantidade | Quantidade vendida do produto | Obrigatório, deve ser > 0 |
| preco_unitario_venda | Preço praticado no momento da venda (histórico) | Obrigatório |
| subtotal | quantidade × preco_unitario_venda | Calculado automaticamente |

### Entidade: PAGAMENTO
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_pagamento | Identificador único | Obrigatório |
| id_venda | Venda associada ao pagamento | Obrigatório (FK) |
| forma_pagamento | Dinheiro, PIX, cartão de crédito/débito ou boleto | Obrigatório |
| valor_pago | Valor pago | Obrigatório, deve ser ≥ 0 |
| data_pagamento | Data/hora do pagamento | Obrigatório |
| parcelas | Número de parcelas (cartão de crédito) | Obrigatório, deve ser ≥ 1 |

---

## 6. Modelagem Conceitual (Entidades, Atributos, Relacionamentos)

- **Entidades reconhecidas:** CATEGORIA, FORNECEDOR, PRODUTO, ESTOQUE, CLIENTE, FUNCIONARIO, VENDA, ITEM_VENDA (associativa) e PAGAMENTO. Cada uma representa um conceito estável e independente do negócio: o catálogo (categoria/fornecedor/produto/estoque), as pessoas envolvidas na venda (cliente/funcionário) e a transação em si (venda/item_venda/pagamento).
- **Atributos e classificações:** ver Dicionário de Dados (Seção 5). Cada entidade possui um identificador substituto (`id_*`) como chave primária e um atributo natural relevante para consulta (ex.: `codigo_interno` em produto, `cpf_cnpj` em cliente) tratado como chave candidata/única.
- **Relacionamentos pertinentes:**
  - CATEGORIA (1) — (N) PRODUTO: cada produto pertence a exatamente uma categoria; uma categoria agrupa vários produtos.
  - FORNECEDOR (1) — (N) PRODUTO: cada produto é fornecido por um fornecedor principal; um fornecedor fornece vários produtos.
  - PRODUTO (1) — (1) ESTOQUE: cada produto possui exatamente um registro de controle de estoque.
  - CLIENTE (1) — (N) VENDA: um cliente pode realizar várias vendas ao longo do tempo.
  - FUNCIONARIO (1) — (N) VENDA: um funcionário atende várias vendas.
  - VENDA (N) — (N) PRODUTO, resolvido pela entidade associativa ITEM_VENDA: uma venda contém vários produtos, e um produto pode estar em várias vendas.
  - VENDA (1) — (N) PAGAMENTO: uma venda pode ter um ou mais pagamentos (ex.: parcial + complemento).
- **Restrições e políticas organizacionais aplicadas ao modelo:** unicidade de CPF/CNPJ (cliente/fornecedor/funcionário), unicidade de código interno do produto, obrigatoriedade de categoria e fornecedor para todo produto, e impossibilidade de estoque ou quantidade negativa.

---

## 7. Diagrama Entidade-Relacionamento (DER)

Arquivo anexado: **`DER_loja_tintas_materiais.png`** (notação Chen — entidades em retângulo, relacionamentos em losango, atributos em elipse, com as cardinalidades 1:N e 1:1 indicadas em cada ligação).

O modelo já comporta evolução futura, por exemplo: histórico de reajuste de preços por produto, tabela de compras/entradas junto a fornecedores (hoje simplificada no atributo de estoque), múltiplos endereços de entrega por cliente, ou um relacionamento adicional entre funcionário e meta de vendas — sem quebrar a estrutura atual.

---

## 8. Justificativa Técnica

- **Por que uma entidade ESTOQUE separada de PRODUTO?** Para isolar um atributo que muda com alta frequência (quantidade) do cadastro descritivo do produto (que muda raramente), evitando lock/contenção desnecessária em operações de venda e deixando explícito o relacionamento 1:1, que poderá evoluir para 1:N (ex.: estoque por filial) sem afetar a tabela `produto`.
- **Por que uma entidade associativa ITEM_VENDA em vez de uma FK direta de produto em venda?** Porque a relação real é N:N — uma venda contém vários produtos e um produto aparece em várias vendas. A tabela associativa também é o lugar correto para guardar o **preço praticado no momento da venda**, que não deve ser confundido com o preço atual do produto (histórico de preço é uma exigência de qualquer sistema de vendas real).
- **Por que separar PAGAMENTO de VENDA em vez de colocar a forma de pagamento como atributo de venda?** Porque uma venda pode ser paga em mais de uma transação (ex.: parte em dinheiro, parte no cartão), o que exige uma relação 1:N e não um atributo simples.
- **Por que CATEGORIA e FORNECEDOR como entidades e não como atributos de texto em PRODUTO?** Para evitar redundância (o mesmo nome de categoria/fornecedor repetido em centenas de produtos) e permitir relatórios agregados (faturamento por categoria, por fornecedor) sem inconsistência de digitação — motivação que também antecipa a normalização feita na Entrega 2.
- **Por que CLIENTE e FUNCIONARIO como entidades distintas mesmo ambas sendo "pessoas"?** Porque têm ciclos de vida, atributos e regras de negócio completamente diferentes (cliente é quem compra; funcionário é quem vende), não havendo ganho em modelá-los como uma generalização/especialização neste escopo.
- **Alternativa considerada e descartada:** modelar produto-fornecedor como N:N (um produto poderia ter vários fornecedores possíveis). Optou-se por 1:N porque, na prática observada nos catálogos, cada item é associado a uma marca/fornecedor principal; um relacionamento N:N ficaria para uma evolução futura (ex.: cotação de compra com múltiplos fornecedores).

---

## 9. Uso de Inteligência Artificial

| Item | Registro |
|------|------------------|
| **Ferramenta e etapa** | `feeramenta utilizadas chatgpt e claude para alteração de dados e tambem para auxilio na construção do banco de dados "]` |
| **Motivação** | `[]` |
| **Prompt(s) utilizados** | tenho um trabalho da faculdade onde preciso montar um banco de dados pretendo utilizar mysql para realizar a tarefa o meu grupo escolheu o uma loja de tintas e materiais de construção me ajude a criar o banco de dados solido plausivel e com todas as informações como um otimo banco de dados deve ser foi anexado as informações da loja tambem esta anexado o esqueleto e requisitos das entregas solicitados pelo professor  me ajude criar o banco de dados e tambem os requisitos que estão sendo solicitados ]` |
| **Resposta recebida** | `Vou te ajudar com as duas entregas. Antes de gerar tudo, um ponto importante direto: o enunciado exige que a organização seja real, com evidências reais (fotos, endereço, contato, link no Google) — isso não posso inventar para vocês, precisa vir da pesquisa de campo do grupo. Vou montar tudo que é tecnicamente possível (modelo conceitual, DER, dicionário de dados, script SQL completo com massa de dados fictícia, normalização, README das duas entregas) usando os catálogos que vocês anexaram (que mostram claramente uma loja de tintas/ferramentas/materiais de construção), e deixo marcado com [PREENCHER] exatamente os pontos que só vocês podem completar com dados reais da loja.

Vou gerar o script SQL primeiro (a parte mais longa e que precisa ser consistente).

O script final, com o cabeçalho, roda do zero sem erro — banco criado, 67 produtos, 18 vendas, joins/updates/deletes/consultas gerenciais e de auditoria todos funcionando (inclusive a consulta de auditoria pegando de propósito a inconsistência gerada pelo DELETE de exemplo). Todos os arquivos estão prontos.

Presented 6 files

Montei o pacote completo cobrindo as duas entregas, com base nos catálogos que vocês mandaram (uma loja de tintas/ferramentas/materiais de construção):

Banco de dados (rodado do zero e testado num MariaDB de verdade — sem erros):

9 tabelas: categoria, fornecedor, produto, estoque, cliente, funcionario, venda, item_venda (associativa N:N) e pagamento
script_banco_dados.sql — CREATE DATABASE, CREATE TABLE com PK/FK/UNIQUE/CHECK, massa de dados fictícia (67 produtos reais dos seus catálogos + 8 clientes e 5 funcionários fictícios + 18 vendas), SELECT com JOIN, UPDATE, DELETE, consultas gerenciais (faturamento por mês/categoria/vendedor, ranking de produtos, reposição de estoque) e consultas de auditoria

Diagramas (imagens prontas para anexar):

DER_loja_tintas_materiais.png — notação Chen, com cardinalidades
Modelo_Logico_Relacional.png — tabelas, colunas, PK/FK

Documentação (esqueletos preenchidos):

README_Entrega1.md — caracterização, processos, requisitos, regras de negócio, dicionário de dados, justificativa técnica
Relatorio_Tecnico_Entrega2.md — conversão conceitual→lógico, normalização (1FN/2FN/3FN) com exemplos reais do seu modelo, justificativas, proposta de BI/IA
Dicionario_Dados.html

O que só o grupo pode preencher (marcado [PREENCHER] nos arquivos): nome real da loja, endereço, contato, fotos/link do Google e o quadro de "Uso de IA" — isso é exigência explícita do professor de pesquisa de campo real, não posso inventar.

Quer que eu já monte os slides da apresentação final (item 7 da Entrega 2)?` |
| **Fontes consultadas e verificadas** | `[Dados e planilhas do estabelecimento]` |
| **Trechos rejeitados ou corrigidos** | `[todas as informações pessoais forma alteradas por ficticias .]` |
| **Justificativa da escolha final** | `foi escolhido as ias chatgpt e claude pafra auxilio em infomrações e resoluções de problemas |
| **Reflexão crítica** | `[PREENCHER: ex. "a IA não pode confirmar dados reais da loja, então todos os campos de caracterização e evidências tiveram que ser preenchidos pelo grupo após a visita de campo"]` |

> **Importante:** esta seção precisa ser preenchida com honestidade pelo grupo. O conteúdo técnico deste repositório (estrutura de entidades, DER, script SQL) foi produzido com apoio de IA a partir dos catálogos de produtos fornecidos pelo grupo — isso deve constar aqui como uso real de IA, não pode ser omitido.
