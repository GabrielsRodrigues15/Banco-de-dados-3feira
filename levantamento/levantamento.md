# Levantamento — Máximo Das Tintas 🫟

> **Modelo para o grupo preencher.** O professor exige um **texto organizado, escrito pelo grupo** (não vale áudio, vídeo, transcrição crua ou formulário colado). Os itens marcados com `[PREENCHER]` só o grupo sabe. O que já foi informado pela loja nas entregas anteriores está preenchido.

## 1. Identificação da visita

| Item | Registro |
|---|---|
| Organização | Máximo Das Tintas — varejo de tintas, ferramentas e materiais de construção |
| Endereço | `[PREENCHER]` endereço completo |
| Google Meu Negócio | https://share.google/O58fMgnEeO1ujE6RM |
| Contato da loja | maximosdastintas@gmail.com |
| Entrevistado | `[PREENCHER]` nome, função (ex.: proprietário/gerente) e **telefone** |
| Data e horário | `[PREENCHER]` |
| Local | Na própria loja, no balcão de atendimento (ver fotos) |
| Integrantes presentes | `[PREENCHER]` |
| Vínculo com a loja | `[PREENCHER]` algum integrante trabalha lá ou tem parente na loja? (declarar; não dispensa a entrevista) |
| Fotos | [`../evidencias/balcao_pdv.jpg`](../evidencias/balcao_pdv.jpg) · [`../evidencias/visita_loja.jpg`](../evidencias/visita_loja.jpg) |

## 2. O que foi perguntado (roteiro)

1. Quantos funcionários a loja tem e o que cada um faz?
2. Qual o faturamento médio e quantos produtos saem por mês?
3. Como uma venda é registrada hoje (sistema, papel, planilha)?
4. Como é feito o controle de estoque e a reposição? Quem decide o que comprar?
5. Quais formas de pagamento são aceitas? Há parcelamento? Vende a prazo (boleto) para empresas?
6. Como funciona troca e devolução?
7. Como o preço de venda é definido?
8. Há entrega? Há desconto no balcão?
9. Quais relatórios o responsável gostaria de ter e não tem?
10. `[PREENCHER]` outras perguntas feitas

## 3. Respostas do entrevistado (o que foi **dito**)

| Tema | Resposta |
|---|---|
| Equipe | **2 funcionários**, que fazem atendimento, caixa e reposição |
| Volume | **≈ R$ 20 mil por mês**; **≈ 500 unidades** saem do estoque por mês |
| Preço | custo do fornecedor **+ ≈ 60%** |
| Troca | prazo de **2 semanas**; nota fiscal exigida **somente para troca** |
| Sistema atual | sistema de frente de caixa (PDV) que exporta listas de preço em PDF/planilha |
| Pagamento | `[PREENCHER]` formas aceitas, parcelamento, boleto para empresas |
| Reposição | `[PREENCHER]` como e quando compram, quem decide |
| Entrega e desconto | `[PREENCHER]` (a tela do PDV tem os campos "taxa de entrega" e "desconto") |
| Relatórios desejados | `[PREENCHER]` |

## 4. O que foi **observado** no local (separado das respostas)

> O professor pede para destacar o que o grupo **viu acontecer**, que muitas vezes difere do que é dito.

- A venda é lançada no **PDV do balcão**: a tela mostra cliente, vendedor, produto (código/descrição), quantidade, preço à vista, **desconto**, **taxa de entrega** e "Total a pagar" (foto `balcao_pdv.jpg`).
- Os produtos ficam expostos por tipo (ferramentas em painéis, tintas em prateleiras, rolos/pincéis/fitas no balcão), o que corresponde às **categorias** do modelo.
- Há câmeras de segurança e telefone fixo no balcão.
- `[PREENCHER]` o que mais foi observado: alguém anota algo em papel? como conferem o caixa? como sabem o que está acabando?

## 5. Problemas levantados → como o modelo resolve

| # | Problema | Onde aparece no modelo | Consulta |
|---|---|---|---|
| P1 | Dados em listas PDF/planilhas soltas, sem base única | 9 tabelas integradas | G13, G14, G16 |
| P2 | Não sabem rápido o que está abaixo do mínimo | `estoque.quantidade_minima` | G05, G06, G10 |
| P3 | Relatório por vendedor/categoria/fornecedor exige planilha | `venda`, `item_venda`, `produto` | G01, G07, G08, G09, G15 |
| P4 | Baixa de estoque depende de alguém lembrar | triggers de estoque | G03, G06, A06 |
| P5 | Conferência venda × pagamento manual | `pagamento` | G11, G12, A01–A03 |
| P6 | Troca/desistência bagunça o histórico | `status_venda = CANCELADA` | G04 |

## 6. Processos típicos de uma loja de materiais de construção — conferência

| Processo típico (pesquisa + IA) | Existe na loja? | No modelo? |
|---|---|---|
| Venda de balcão | Sim | Sim |
| Orçamento para cliente/obra | `[VALIDAR]` | Sim (`status_venda = ORCAMENTO`) |
| Troca e devolução | Sim (2 semanas) | Sim (`CANCELADA` + devolução de estoque) |
| Reposição / compra de fornecedor | Sim | Parcial (ponto de reposição; pedido de compra fora do sistema) |
| Venda a prazo para empresa (boleto) | `[VALIDAR]` | Sim (forma `BOLETO`) |
| Entrega em obra | `[VALIDAR]` — há campo no PDV | Não (ver limitações do README) |
| Desconto no balcão | `[VALIDAR]` — há campo no PDV | Não (ver limitações do README) |
| Mistura de tintas (tintométrico) | `[VALIDAR]` | Não |
| Emissão de nota fiscal | Feita pelo PDV | Não (fora do escopo) |

## 7. O que mudou em relação à Entrega 1

`[PREENCHER]` se houve nova visita: o que foi confirmado, o que mudou (processos, regras, volumes, problemas).
