# Levantamento — Máximo Das Tintas 🫟

Texto organizado pelo grupo a partir da entrevista e da observação na loja. O que foi **dito** pela entrevistada está separado do que foi **observado** no local (seções 3 e 4).

## 1. Identificação da visita

| Item | Registro |
|---|---|
| Organização | **MAXIMO DAS TINTAS LTDA - ME** (nome fantasia: Máximo Das Tintas) — varejo de tintas, ferramentas e materiais de construção |
| CNPJ | 52.489.342/0001-10 |
| Endereço | R. Ana Maria Sirani, 577 — São Paulo/SP |
| Telefone da loja | (11) 91297-8462 |
| Google Meu Negócio | https://share.google/O58fMgnEeO1ujE6RM |
| E-mail | maximosdastintas@gmail.com |
| Responsáveis pela loja | Pedro, Waldeane e Larissa |
| **Entrevistada** | **Larissa** — Financeiro / Ajudas gerais — telefone **(11) 98338-6503** |
| Integrante presente na entrevista | Ítalo Leal Oliveira |
| Data e local | 07/11/2026, por volta de 13h, no balcão da loja (data e hora aparecem no relógio do PDV nas fotos) `[VALIDAR]` |
| Fotos | [`balcao_pdv.jpg`](../evidencias/balcao_pdv.jpg) · [`pdv_tela_venda.jpg`](../evidencias/pdv_tela_venda.jpg) · [`sistema_cadastro_produtos.jpg`](../evidencias/sistema_cadastro_produtos.jpg) · [`visita_loja.jpg`](../evidencias/visita_loja.jpg) |

## 2. Roteiro (o que foi perguntado)

1. Quantos funcionários a loja tem e o que cada um faz?
2. Qual o faturamento médio e quantos produtos saem por mês?
3. Como as vendas são registradas?
4. Como é feito o controle de estoque e a reposição? Quem decide o que comprar?
5. Quais formas de pagamento são aceitas? Há venda a prazo?
6. Como funciona troca e devolução?
7. Como o preço de venda é definido?
8. Há entrega? Há desconto?
9. Quais relatórios o responsável gostaria de ter e não tem?
10. Quais melhorias os funcionários enxergam para a loja?
11. Algo é anotado em papel? Como é feito o caixa?

## 3. Respostas da entrevistada (o que foi **dito**)

| Tema | Resposta |
|---|---|
| Equipe | **2 funcionários e 1 intermediário**. Os três vendem e atendem os clientes, cadastram produtos, **produzem tintas na máquina**, fazem os pedidos de produtos, organizam e limpam a loja |
| Faturamento | **R$ 300 a R$ 500 por dia** (≈ R$ 8 mil a 13 mil por mês, ≈ R$ 10 mil em média) |
| Produtos que saem | **100 a 120 por mês** |
| Registro de vendas | Em **sistema próprio** (PDV) |
| Controle de estoque e compras | A loja é revisada **todo dia**; o que está acabando ou vai acabar é colocado no **carrinho do site dos fornecedores**; o pessoal da loja e do **escritório** decide o que será comprado |
| Formas de pagamento | **PIX, débito, crédito e dinheiro**; para **obras parceiras**, venda **a prazo no boleto** |
| Troca e devolução | **Resposta pendente** (a loja responde depois). Na Entrega 1 foi informado prazo de 2 semanas, com nota fiscal `[VALIDAR]` |
| Preço de venda | O sistema calcula o preço com a **margem que a loja coloca sobre a venda, de 3,6%**, mais um **reajuste** para acompanhar o valor de venda atual do produto |
| Entrega | **Não** faz entrega |
| Desconto | **5% no PIX** |
| Relatórios desejados | **Aumento de preço dos produtos** e **desconto dos fornecedores** |
| Melhorias | Aumento da estrutura: **uma nova loja, maior e em melhor localização, já está sendo construída** |
| Papel e caixa | **Nada é anotado em papel**; o **caixa é contado na abertura e no fechamento** da loja; os materiais que estão acabando são revisados todo dia |

## 4. O que foi **observado** no local

- **Tela de venda do PDV** ([`pdv_tela_venda.jpg`](../evidencias/pdv_tela_venda.jpg)): o tipo de movimento é **Venda** ou **Orçamento** (confirma o orçamento como processo); o cliente padrão é **"BALCAO"** (venda sem cadastro) e o vendedor também é informado; há preço **faturado** e preço **à vista**, **desconto** por item e total, **taxa de entrega** (zerada — a loja não entrega) e a opção **"Gerar NF-e"**. Atalhos: F2-Desconto, F5-Finaliza, F8-Caixa, F9-Movimentos.
- **Cadastro de produtos** ([`sistema_cadastro_produtos.jpg`](../evidencias/sistema_cadastro_produtos.jpg)): cada produto tem **código, código de barras, descrição, NCM, unidade, valor de venda, valor à vista, valor de custo** e **ativo**; é agrupado por **Família** (Elétrica, Ferramentas Manuais, Hidráulica, Selfcolor, Impermeabilizantes...) e **Fabricante** (Ferja, Colorgin, Krona, Tigre, Suvinil...); há classificação fiscal **CSOSN** e a opção de **ajustar preço** em lote.
- **Post-it no monitor** (fotos): **parcelamento a partir de R$ 200 em 2x sem juros e a partir de R$ 400 em 3x sem juros**, "mas podem ajustar a critério da maquininha".
- Câmeras de segurança e telefone fixo no balcão; produtos expostos por tipo (painéis de ferramentas, prateleiras de tintas, rolos/pincéis/fitas no balcão).

**Diferenças entre o dito e o observado:** a entrevistada não citou o orçamento nem o custo, mas os dois estão no sistema; a regra de parcelamento só apareceu no post-it; a tela tem campo de entrega, mas a loja não entrega.

## 5. Problemas levantados → como o modelo resolve

| # | Problema | Onde aparece no modelo | Consultas |
|---|---|---|---|
| P1 | Informação espalhada no PDV e nos carrinhos dos sites dos fornecedores; orçamentos se perdem | 10 tabelas integradas; orçamento = venda com status `ORCAMENTO` | G13, G14, G16 |
| P2 | Saber rápido o que está acabando (hoje: revisão diária manual da loja) | `estoque.quantidade_minima` | G05, G06, G10 |
| P3 | Relatórios gerenciais que o sistema não dá, como **aumento de preço** | `historico_preco`, `venda`, `item_venda`, `produto` | G01, G07, G08, G09, G15, G17, G18 |
| P4 | Estoque coerente com as vendas sem depender de revisão manual | triggers de estoque | G03, G06, A06 |
| P5 | Conferência do caixa (aberto e fechado por contagem) e dos descontos de PIX | `pagamento`, `venda.valor_desconto` | G11, G12, G19, A01–A03, A11 |
| P6 | Troca/desistência sem perder o histórico | `status_venda = CANCELADA` | G04 |

## 6. Processos típicos de uma loja de materiais de construção — conferência

| Processo típico (pesquisa + IA) | Existe na loja? | No modelo? |
|---|---|---|
| Venda de balcão | Sim | Sim |
| Orçamento | Sim (tela do PDV) | Sim (`ORCAMENTO`) |
| Troca e devolução | Resposta pendente | Sim (`CANCELADA` + devolução de estoque) |
| Reposição / compra de fornecedor | Sim, pelo site do fornecedor, decidida com o escritório | Parcial: ponto de reposição (G05/G06); o pedido fica no site do fornecedor |
| Venda a prazo (boleto) | Sim, para obras parceiras | Sim (forma `BOLETO`) |
| Desconto | Sim, 5% no PIX | Sim (`valor_desconto`, RN19) |
| Entrega em obra | **Não** | Não |
| Preparo de tinta na máquina (tintométrico) | Sim | Não (a tinta preparada é vendida como produto; fórmula/cor fora do escopo) |
| Emissão de nota fiscal | Sim, pelo PDV ("Gerar NF-e") | Não (feita pelo sistema fiscal) |
| Desconto de fornecedor | Desejado como relatório | Não (exige dados de compra; ver limitações) |

## 7. O que mudou em relação à Entrega 1

| Item | Entrega 1 | Entrevista de 07/11/2026 | Efeito no trabalho |
|---|---|---|---|
| Equipe | 2 funcionários | 2 funcionários + 1 intermediário | Massa com 3 funcionários ativos |
| Faturamento | ≈ R$ 20 mil/mês | R$ 300–500 por dia (≈ R$ 10 mil/mês) | Massa recalibrada para ≈ R$ 10 mil/mês; meta do KPI1 = R$ 10 mil |
| Produtos por mês | ≈ 500 | 100–120 | Massa recalibrada para ≈ 104 unidades/mês |
| Preço | custo + ≈ 60% | margem de 3,6% sobre a venda + reajuste | Coluna `preco_custo` e consulta de margem (G18) |
| Desconto | não levantado | 5% no PIX | Coluna `valor_desconto` (RN19, A11, G19) |
| Parcelamento | não levantado | 2x a partir de R$ 200, 3x a partir de R$ 400 (observado) | RN20, A12 |
| Entrega | não levantado | não faz | Fora do escopo, confirmado |
| Relatórios desejados | não levantado | aumento de preço; desconto de fornecedor | Tabela `historico_preco` + trigger (RN21, G17) |
