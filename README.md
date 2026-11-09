# Máximo Das Tintas 🫟 — Relatório Técnico Final

### Modelagem de Banco de Dados · Entrega 2 (modelo lógico, SQL em MySQL e arquitetura analítica)

> Este README é o relatório da Entrega 2 e segue o esqueleto da disciplina (`00-d_Esqueleto_Entrega_2.md`). A Entrega 1 (caracterização, processos, requisitos, regras, dicionário conceitual e DER) está preservada no **[Anexo A](#anexo-a--entrega-1-modelo-conceitual)** no fim do arquivo.
> Marcadores: **`[PREENCHER]`** = dado que só o grupo tem · **`[VALIDAR]`** = ponto a confirmar com o grupo, a loja ou o professor.

## Integrantes

| Nome completo do aluno | RGM | Usuário do GitHub |
|---|---|---|
| Gabriel Souza | 46683305 | [gabrieldesouza1830-cell](https://github.com/gabrieldesouza1830-cell) |
| Gabriel Rodrigues da Silva | 46885030 | [GabrielsRodrigues15](https://github.com/GabrielsRodrigues15) (repositório `GabrielsRodrigues15/Banco-de-dados-3feira`) |
| Ítalo Leal Oliveira | 47837098 | [italoleal567](https://github.com/italoleal567) |
| Vinicius Batista Merencio | 46749527 | [viniciusmerencio0-cpu](https://github.com/viniciusmerencio0-cpu) |

**Curso / Disciplina:** Banco de Dados — Modelagem de Banco de Dados (turma de terça-feira, noturno) · Prof. Cid Andrade.
**SGBD:** MySQL 8.0 (InnoDB, `utf8mb4`) · **Banco:** `loja_tintas_materiais`.

## Situação atual do projeto

Atualizado em 09/11/2026. **Entrega da turma de terça: 10/11** (só a branch `main` é corrigida). **Vídeo do pitch: até 16/11** — a Máximo Das Tintas não está na lista de seminários presenciais da terça, então o link do vídeo (YouTube, "Não listado", 8 min) vai na [seção 7](#7-apresentação-corporativa-final).

| Item da entrega | Situação | Onde está |
|---|---|---|
| Caracterização, problemas P1–P6, escopo | ✅ pronto | [1.1](#11-revisão-do-modelo-conceitual) |
| Responsável (nome e telefone), endereço completo | ⚠️ **falta** | [1.1](#evidências-da-organização) |
| Relato da entrevista e `levantamento.md` | ⚠️ modelo pronto, **grupo completa** | [`levantamento/levantamento.md`](levantamento/levantamento.md) |
| Processos, requisitos (RF/RNF) e regras (RN01–RN18) detalhados | ✅ pronto | [1.1](#processos-de-negócio) |
| Tabela de apontamentos da correção da Entrega 1 (Caso A) | ⚠️ **falta a correção do professor** | [1.1](#caso-a--revisão-a-partir-da-correção-da-entrega-1) |
| DER na notação do brModelo | ✅ feito no brModelo Web | [`entrega-1/DER_brmodelo_22-09-2026.pdf`](entrega-1/DER_brmodelo_22-09-2026.pdf) |
| Conversão, PK/FK, normalização, justificativas | ✅ pronto | [1.2 a 1.5](#12-conversão-do-modelo-conceitual-para-o-modelo-lógico) |
| BI e IA com 12 KPIs (fórmula, período, meta, consulta) | ✅ pronto | [1.6](#16-proposta-de-arquitetura-analítica-para-bi-e-ia) |
| Modelo lógico | ✅ gerado do banco · ⚠️ refazer no brModelo `[VALIDAR]` | [2](#2-modelo-lógico-relacional) |
| Script SQL com consultas G01–G16 e A01–A10 | ✅ testado no MySQL 8.0.46, sem erros | [`docs/script.sql`](docs/script.sql) |
| Massa de dados calibrada pelo porte real (940 vendas) | ✅ pronto | [4](#4-massa-de-dados) |
| Dicionário de dados no modelo 02-03g (HTML único) | ✅ pronto | [`docs/dicionario_dados.html`](docs/dicionario_dados.html) |
| Testes de restrições | ✅ 14 de 14 operações inválidas rejeitadas | [`docs/09_testes_restricoes.sql`](docs/09_testes_restricoes.sql) |
| Fotos JPG no repositório | ✅ 2 fotos · ⚠️ falta foto da fachada/entrevista | [`evidencias/`](evidencias/) |
| Uso de IA — reflexão crítica do grupo | ⚠️ falta o texto do grupo | [6](#6-uso-de-inteligência-artificial) |
| Commits equilibrados entre os 4 integrantes | ⚠️ conferir | [5](#5-repositório-github) |
| Vídeo do pitch (8 min) | ⚠️ gravar até 16/11 | [7](#7-apresentação-corporativa-final) |

## Sumário

1. [Relatório Técnico Final](#1-relatório-técnico-final)
   1.1 [Revisão do modelo conceitual](#11-revisão-do-modelo-conceitual) · 1.2 [Conversão](#12-conversão-do-modelo-conceitual-para-o-modelo-lógico) · 1.3 [PKs e FKs](#13-definição-de-chaves-primárias-e-estrangeiras) · 1.4 [Normalização](#14-processo-de-normalização-1fn-2fn-e-3fn) · 1.5 [Justificativas](#15-justificativas-técnicas-das-decisões) · 1.6 [BI e IA](#16-proposta-de-arquitetura-analítica-para-bi-e-ia)
2. [Modelo lógico relacional](#2-modelo-lógico-relacional)
3. [Script SQL completo](#3-script-sql-completo)
4. [Massa de dados](#4-massa-de-dados)
5. [Repositório GitHub](#5-repositório-github)
6. [Uso de Inteligência Artificial](#6-uso-de-inteligência-artificial)
7. [Apresentação corporativa final](#7-apresentação-corporativa-final)
8. [Limitações e pontos a validar](#8-limitações-e-pontos-a-validar)
9. [Referências da disciplina](#referências-da-disciplina)

**[Anexo A — Entrega 1 (modelo conceitual)](#anexo-a--entrega-1-modelo-conceitual)**

---

## 1. Relatório Técnico Final

### 1.1 Revisão do Modelo Conceitual

#### Caracterização da organização

- **Nome e natureza:** **Máximo Das Tintas**, loja de pequeno porte do varejo de **tintas, ferramentas e materiais de construção**, com fins lucrativos. Vende ao consumidor final (pessoa física) e a pintores, pequenas construtoras e empresas de reforma (pessoa jurídica). Trabalha com marcas como Suvinil, Bilacor, Tramontina, Ferja, Tigre, Condor, Famastil e Thompson.
- **Contexto e porte (números informados pela loja):**

  | Item | Informado |
  |---|---|
  | Funcionários | **2** (os mesmos fazem atendimento, caixa e reposição) |
  | Faturamento médio | **≈ R$ 20 mil por mês** |
  | Saída de produtos | **≈ 500 unidades por mês** |
  | Formação de preço | custo do fornecedor **+ ≈ 60%** |
  | Troca | prazo de **2 semanas**; nota fiscal exigida **somente para troca** |
  | Sistema atual | PDV de frente de caixa que exporta listas de preço em PDF/planilha |

- **Problemas e necessidades** (todo problema aparece no DER e tem consulta gerencial; ver a rastreabilidade na [seção 1.6](#16-proposta-de-arquitetura-analítica-para-bi-e-ia)):

  | # | Problema de gestão de informações | Como o modelo resolve | Consultas |
  |---|---|---|---|
  | P1 | Catálogo, estoque, vendas e clientes em listas PDF/planilhas soltas, sem base única; orçamentos se perdem | 9 tabelas integradas; orçamento é uma venda com status `ORCAMENTO` | G13, G14, G16 |
  | P2 | Não se sabe rapidamente o que está abaixo do estoque mínimo | `estoque.quantidade_minima` + ponto de reposição | G05, G06, G10 |
  | P3 | Relatórios por vendedor, categoria e fornecedor exigem tratar planilhas à mão | `venda`, `item_venda`, `produto`, `categoria`, `fornecedor`, `funcionario` | G01, G02, G07, G08, G09, G15 |
  | P4 | A baixa de estoque depende de alguém lembrar de atualizar | Triggers: venda concluída baixa; cancelamento/exclusão devolve | G03, G06, A06 |
  | P5 | Conferência de venda × pagamento e do caixa feita à mão | `pagamento` (1:N com venda, várias formas) | G11, G12, A01–A03 |
  | P6 | Troca/desistência apaga ou bagunça o histórico | Venda vira `CANCELADA` (não é apagada) e o estoque volta | G04 |

- **Escopo do sistema:** o banco reúne **todos os dados da operação da loja**: catálogo (categoria, fornecedor, produto), estoque, clientes, funcionários, vendas de balcão e orçamentos, itens, pagamentos, cancelamentos/trocas. Ficaram fora (justificativa em [processos não incluídos](#processos-típicos-não-incluídos)): pedido de compra ao fornecedor, custo de aquisição, entrega, emissão de nota fiscal, contas a pagar e folha.
- **Justificativa da escolha:** negócio real com processos claros de venda, estoque e vários fornecedores, com volume suficiente (67 produtos de 5 categorias e 10 marcas, ≈ 150 vendas/mês) sem a complexidade de uma rede varejista. `[PREENCHER]` vínculo de algum integrante com a loja, se houver (declarar; não dispensa a entrevista).

#### Evidências da organização

| Evidência | Registro |
|---|---|
| Google Meu Negócio | [share.google/O58fMgnEeO1ujE6RM](https://share.google/O58fMgnEeO1ujE6RM) |
| E-mail da loja | maximosdastintas@gmail.com |
| Endereço completo | `[PREENCHER]` |
| **Responsável (nome e telefone)** | `[PREENCHER]` — o professor pode ligar para confirmar |
| Fotos (JPG no repositório) | [`evidencias/balcao_pdv.jpg`](evidencias/balcao_pdv.jpg) (balcão com o PDV) · [`evidencias/visita_loja.jpg`](evidencias/visita_loja.jpg) (integrante na loja, `[PREENCHER]` quem) · `[PREENCHER]` foto da entrevista/fachada |

| Balcão e sistema de frente de caixa | Visita à loja |
|---|---|
| ![Balcão com o PDV da Máximo Das Tintas](evidencias/balcao_pdv.jpg) | ![Integrante do grupo na loja](evidencias/visita_loja.jpg) |

#### Relato da entrevista

Resumo do levantamento (o texto completo, com o que foi **dito** separado do que foi **observado**, está em [`levantamento/levantamento.md`](levantamento/levantamento.md)):

- **Quem / quando / onde:** `[PREENCHER]` nome e função do entrevistado, data, integrantes presentes. Entrevista no balcão da loja (fotos acima).
- **Dito pelo entrevistado:** 2 funcionários; ≈ R$ 20 mil e ≈ 500 unidades por mês; preço = custo + ≈ 60%; troca em 2 semanas com nota; controle em listas exportadas do PDV.
- **Observado no local:** a venda é lançada no PDV com cliente, vendedor, produto, quantidade, preço, **desconto** e **taxa de entrega**; produtos expostos por tipo (painéis de ferramentas, prateleiras de tinta, rolos e fitas no balcão), o que corresponde às categorias do modelo. Desconto e entrega não haviam sido citados na entrevista e ficaram registrados como ponto a validar (seção 8).

#### Processos de negócio

| Código | Processo | Dados envolvidos |
|---|---|---|
| PR1 | **Cadastro de produto** — o gerente inclui o item do catálogo | código interno do PDV, código de barras (EAN), descrição, NCM, unidade de medida, preço de venda, categoria, fornecedor principal, ativo |
| PR2 | **Cadastro de cliente** (opcional no balcão) | nome/razão social, tipo de pessoa (PF/PJ), CPF ou CNPJ, telefone, e-mail, endereço, data de cadastro; sem cadastro, a venda usa o cliente "Consumidor final" |
| PR3 | **Orçamento** — o vendedor monta os itens e o cliente decide depois | cliente, funcionário, data, status `ORCAMENTO`, itens (produto, quantidade, preço praticado), total; não baixa estoque nem gera pagamento |
| PR4 | **Venda de balcão** — abertura, itens, fechamento | cliente, funcionário, data/hora, status `CONCLUIDA`, por item: produto, quantidade, preço praticado, subtotal; total da venda |
| PR5 | **Recebimento** | por pagamento: forma (dinheiro, PIX, cartão de crédito, cartão de débito, boleto), valor, data, parcelas; uma venda pode ter mais de um pagamento |
| PR6 | **Baixa e controle de estoque** | saldo atual, estoque mínimo, localização no depósito; baixa automática na venda concluída |
| PR7 | **Troca/cancelamento** (até 2 semanas, com nota) | venda passa a `CANCELADA`, o estoque dos itens volta; a venda não é apagada |
| PR8 | **Reposição** — gerente consulta o ponto de reposição e compra do fornecedor | produtos com saldo ≤ mínimo, fornecedor, cobertura em dias; entrada atualiza o saldo |
| PR9 | **Reajuste de preço** | novo preço do produto; vendas antigas mantêm o preço praticado |

Fluxogramas: [`fluxograma/fluxo_vendas.png`](fluxograma/fluxo_vendas.png) (PR2–PR5, PR7) e [`fluxograma/fluxo_reposicao.png`](fluxograma/fluxo_reposicao.png) (PR6, PR8).

##### Processos típicos não incluídos

Levantados por pesquisa e IA (registro na seção 6) sobre lojas de materiais de construção e conferidos com o que a loja informou:

| Processo típico | Por que ficou fora |
|---|---|
| Pedido de compra e recebimento de fornecedor | Feito fora do sistema (como é feito hoje: `[VALIDAR]` com a loja); o modelo cobre o ponto de reposição (G05/G06). Evolução: tabelas `compra`/`item_compra` (seção 8) |
| Entrega em obra | Campo existe no PDV, mas a loja não citou entregas na entrevista `[VALIDAR]` |
| Desconto no balcão | Campo existe no PDV `[VALIDAR]` com a loja |
| Emissão de nota fiscal | Feita pelo próprio PDV/emissor fiscal, fora do escopo de modelagem |
| Mistura de tintas (tintométrico) | `[VALIDAR]` se a loja tem máquina tintométrica |
| Contas a pagar, folha e escala | Dados administrativos fora da operação de venda/estoque |

#### Requisitos

**Requisitos funcionais**

| Código | Requisito (com os dados envolvidos) | Problema |
|---|---|---|
| RF01 | Cadastrar, consultar, atualizar e **inativar** produto com código interno, EAN, descrição, NCM, unidade, preço, categoria e fornecedor | P1 |
| RF02 | Cadastrar cliente com nome/razão social, tipo de pessoa, CPF ou CNPJ, telefone, e-mail e endereço; permitir venda sem cadastro ("Consumidor final") | P1 |
| RF03 | Registrar venda com data/hora, cliente, funcionário e status (orçamento, concluída, cancelada) | P1, P3 |
| RF04 | Lançar vários produtos na venda, com quantidade e **preço praticado** no momento | P3 |
| RF05 | Calcular o subtotal de cada item e o total da venda | P5 |
| RF06 | Baixar o estoque automaticamente ao concluir a venda e devolver ao cancelar ou excluir | P4 |
| RF07 | Registrar um ou mais pagamentos por venda, com forma, valor, data e parcelas | P5 |
| RF08 | Listar produtos com saldo ≤ estoque mínimo e a cobertura em dias | P2 |
| RF09 | Emitir relatórios de faturamento por mês, categoria, fornecedor, vendedor, perfil de cliente e forma de pagamento | P3, P5 |
| RF10 | Cancelar venda sem apagar o histórico | P6 |
| RF11 | Converter orçamento em venda e listar orçamentos em aberto com valor e idade | P1 |
| RF12 | Registrar entrada de mercadoria (atualizar saldo) e reajustar preços sem alterar vendas antigas | P2 |

**Requisitos não funcionais**

| Código | Requisito |
|---|---|
| RNF01 | **Integridade:** toda venda referencia cliente e funcionário cadastrados; regras garantidas pelo próprio banco (FK, CHECK, triggers), valendo para qualquer aplicação |
| RNF02 | **Consistência:** total = soma dos itens e pagamento = total, verificados pelas auditorias A01–A03 |
| RNF03 | **Disponibilidade:** acessível em todo o horário comercial (seg–sáb) |
| RNF04 | **Segurança e LGPD:** CPF/CNPJ e contatos com acesso restrito por perfil (dicionário, seção 6) |
| RNF05 | **Desempenho:** consultas gerenciais em menos de 1 s com milhares de vendas (índices `ix_venda_data`, `ix_venda_status_data`) |
| RNF06 | **Usabilidade:** venda de balcão em poucos passos, sem exigir cadastro do cliente |

**Requisitos típicos não incluídos:** multiloja/filiais (a loja tem uma unidade), programa de fidelidade (não existe), integração com e-commerce (não vende on-line), controle de lote/validade de tintas `[VALIDAR]` (a loja não relatou controle de validade).

#### Regras de negócio

| Código | Regra | Implementação | Verificação |
|---|---|---|---|
| RN01 | Só produto cadastrado e **ativo** pode ser vendido | FK `fk_item_produto` + trigger `trg_item_venda_before_insert` | T06, T07 |
| RN02 | Item com quantidade > 0; toda venda concluída tem ao menos um item | `chk_item_qtd` | T01, A07 |
| RN03 | O mesmo produto não se repete na venda (aumenta-se a quantidade) | `uq_item_venda_produto` | T09 |
| RN04 | O preço praticado fica gravado no item; reajuste não altera vendas antigas | coluna `preco_unitario_venda` | `UPDATE` 4.1 |
| RN05 | Total da venda = soma dos subtotais dos itens | coluna gerada `subtotal` | A01 |
| RN06 | Venda concluída baixa o estoque; orçamento não baixa | triggers `trg_item_venda_after_insert`, `trg_venda_after_update_status` | `UPDATE` 4.2 |
| RN07 | O estoque nunca fica negativo | `chk_estoque_qtd` | T10, A06 |
| RN08 | Cancelamento não apaga a venda e devolve o estoque | `status_venda` + `trg_venda_after_update_status` | `DELETE` 5.1 |
| RN09 | Venda concluída é paga integralmente, em uma ou mais formas; parcelas ≥ 1 e só no cartão de crédito; valor ≥ 0; pagamento não antes da venda | FK + `chk_pagamento_valor` + `chk_pagamento_parcelas` + `ENUM` | T11, T12, A02, A03, A09, A10 |
| RN10 | Orçamento não gera pagamento | — | A04 |
| RN11 | CPF/CNPJ únicos; PF com 11 dígitos, PJ com 14 | `uq_cliente_doc` + `chk_cliente_doc` + `chk_fornecedor_cnpj` | T03, T04, A08 |
| RN12 | Código interno do produto (PDV) é único | `uq_produto_codigo` | T05 |
| RN13 | Todo produto tem uma categoria, um fornecedor principal e um registro de estoque | FKs `NOT NULL` + `uq_estoque_produto` | A05 |
| RN14 | Toda venda tem cliente e funcionário; venda sem cadastro usa o "Consumidor final" | FKs `NOT NULL` | T08 |
| RN15 | Troca em até 2 semanas, com nota fiscal | processo (PR7); não verificado pelo banco | seção 8 |
| RN16 | Preço de venda ≈ custo + 60% | não modelado (sem custo) | seção 8 |
| RN17 | Produto, cliente e funcionário com histórico não são apagados — são inativados | FKs sem `CASCADE` + coluna `ativo` | T13, T14 |
| RN18 | LGPD: dados pessoais com acesso restrito, fora da camada analítica; anonimização a pedido | política de acesso | [dicionário, §6](docs/dicionario_dados.html#s6) |

**Regras típicas não incluídas:** limite de crédito para cliente PJ (a loja não relatou venda a prazo com limite), desconto máximo por funcionário (desconto `[VALIDAR]`), venda de produtos controlados (thinner/solventes não exigem registro de comprador neste porte `[VALIDAR]`).

#### DER conceitual (notação do brModelo)

- **DER do grupo no brModelo Web** (22/09/2026): [`entrega-1/DER_brmodelo_22-09-2026.pdf`](entrega-1/DER_brmodelo_22-09-2026.pdf) — retângulos, losangos, círculos preenchidos (identificador) e vazios (atributos) e cardinalidade (mín, máx) dos dois lados.
- **DER em notação de Chen** (apoio visual, gerado com Graphviz): [`entrega-1/DER_chen_loja_tintas.png`](entrega-1/DER_chen_loja_tintas.png).
- **Software:** brModelo Web (DER oficial) e Graphviz (diagrama de apoio).
- `[VALIDAR]` **Atualizar o DER no brModelo** com a revisão abaixo (ESTOQUE ligado a PRODUTO, FUNCIONARIO no lugar de VENDEDOR, ITEM_VENDA como entidade associativa, sem chaves estrangeiras desenhadas).

#### Caso A — revisão a partir da correção da Entrega 1

| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
|---|---|---|
| `[PREENCHER]` apontamento 1 do professor | | |
| `[PREENCHER]` apontamento 2 do professor | | |

> Apontamento não citado na tabela é tratado como não corrigido. Copiar aqui **cada** apontamento recebido na correção da Entrega 1.

Mudanças feitas pelo grupo entre o DER do brModelo e o modelo implementado:

| No DER do brModelo (22/09) | No modelo final | Por quê |
|---|---|---|
| ESTOQUE ligado a CATEGORIA (1,1) | ESTOQUE ligado a **PRODUTO** (1:1) | O saldo é de cada produto, não da categoria |
| VENDEDOR com `id` e `nome` | **FUNCIONARIO** com `cargo`, `cpf`, `data_admissao` e `ativo` | Os mesmos 2 funcionários vendem, operam o caixa e repõem; `ativo` preserva o histórico de quem saiu |
| ENDEREÇO como entidade (1,N) de CLIENTE | Atributo `endereco` (texto) em CLIENTE `[VALIDAR]` | A loja não entrega nem usa vários endereços; pode voltar a ser tabela (seção 8) |
| "Refere-se" ligando ITEM_VENDA, PRODUTO e CATEGORIA | CATEGORIA 1:N PRODUTO; ITEM_VENDA como **associativa** entre VENDA e PRODUTO | A categoria é do produto; o item liga venda e produto |
| Atributos `id_cliente`, `id_funcionario`, `id_categoria`... desenhados nas entidades | Removidos do conceitual; viram FK só no modelo lógico | FK é decisão do modelo lógico |
| `nome_produto`, `preco_unitario` | `descricao`, `preco_unitario` + `codigo_interno`, `ncm`, `unidade_medida`, `ativo` | Campos reais do PDV; `ativo` permite inativar (RN01, RN17) |
| VENDA com `data_hora` | `data_venda` + **`status_venda`** | Orçamento e cancelamento precisam de estado (PR3, PR7) |
| ITEM_VENDA com `preco_unitario` e `subtotal` | `preco_unitario_venda` + `subtotal` como coluna gerada | Preço histórico (RN04); subtotal nunca diverge (RN05) |
| PAGAMENTO com `forma_pagamento`, `valor_pago` | + `data_pagamento`, `parcelas`; forma como domínio fechado | Parcelamento e conferência por data (RN09) |
| CLIENTE com `cpf_cnpj` | + `tipo_pessoa` e cliente "Consumidor final" | PF e PJ (RN11); venda sem cadastro (RN14) |
| FORNECEDOR com `endereco` | Sem endereço `[VALIDAR]` | Não é usado em nenhum processo |

### 1.2 Conversão do Modelo Conceitual para o Modelo Lógico

- **Entidades → tabelas:** cada uma das 8 entidades virou uma tabela (`categoria`, `fornecedor`, `produto`, `estoque`, `cliente`, `funcionario`, `venda`, `pagamento`) e a associativa ITEM_VENDA virou `item_venda`.
- **Atributos → colunas:** identificador → PK `id_*` `INT AUTO_INCREMENT`; atributo opcional → coluna que aceita `NULL` (`codigo_barras`, `ncm`, `telefone`, `email`, `endereco`, `localizacao_deposito`); domínio fechado → `ENUM` (`tipo_pessoa`, `status_venda`, `forma_pagamento`) ou `TINYINT(1)` (`ativo`); derivado → coluna gerada (`subtotal`); valores em dinheiro → `DECIMAL(10,2)`.
- **Relacionamentos → chaves:** 1:N vira FK no lado N; 1:1 (PRODUTO–ESTOQUE) vira FK com `UNIQUE` em `estoque`; N:N com atributos (VENDA × PRODUTO) vira a tabela `item_venda` com duas FKs e `UNIQUE (id_venda, id_produto)`.
- **Cardinalidades:** mínima 1 → FK `NOT NULL` (todo produto tem categoria e fornecedor; toda venda tem cliente e funcionário); mínima 0 do lado N → nenhum registro filho obrigatório (cliente sem compras, orçamento sem pagamento).
- **Generalização/especialização:** não há no DER. Cliente PF e PJ ficou em **tabela única** com `tipo_pessoa`, porque os atributos são os mesmos e só o formato do documento muda (garantido por `chk_cliente_doc`).

Resultado: **9 tabelas**, 8 FKs, 7 `UNIQUE`, 8 `CHECK`, 2 índices extras, 7 triggers e 8 views.

### 1.3 Definição de Chaves Primárias e Estrangeiras

| Tabela | PK | FK → tabela pai | Cardinalidade (pai — filho) | Ao excluir o pai |
|---|---|---|---|---|
| categoria | id_categoria | — | | |
| fornecedor | id_fornecedor | — | | |
| produto | id_produto | id_categoria → categoria; id_fornecedor → fornecedor | (1,1) — (0,N) | bloqueia |
| estoque | id_estoque | id_produto → produto (`UNIQUE`) | (1,1) — (1,1) | bloqueia |
| cliente | id_cliente | — | | |
| funcionario | id_funcionario | — | | |
| venda | id_venda | id_cliente → cliente; id_funcionario → funcionario | (1,1) — (0,N) | bloqueia |
| item_venda | id_item_venda | id_venda → venda; id_produto → produto | (1,1) — (1,N) / (1,1) — (0,N) | venda: **CASCADE**; produto: bloqueia |
| pagamento | id_pagamento | id_venda → venda | (1,1) — (0,N) | bloqueia |

Chaves candidatas mantidas como `UNIQUE`: `produto.codigo_interno`, `cliente.cpf_cnpj`, `fornecedor.cnpj`, `funcionario.cpf`, `categoria.nome_categoria`, `estoque.id_produto`, `item_venda (id_venda, id_produto)`.

### 1.4 Processo de Normalização (1FN, 2FN e 3FN)

- **1FN** — eliminar grupos repetitivos e multivalorados. Na lista do PDV, uma venda traz vários produtos e pode ter vários pagamentos: colocar "produto1, produto2..." ou "forma1, forma2" na venda criaria grupos repetitivos. Por isso itens foram para `item_venda` e pagamentos para `pagamento`. ENDEREÇO, que no brModelo era multivalorado (1,N), ficou como um único texto por cliente, porque a loja não usa mais de um endereço `[VALIDAR]`. Todas as colunas são atômicas e toda tabela tem PK.
- **2FN** — eliminar dependências parciais. Em `item_venda`, a chave candidata é `(id_venda, id_produto)`. A descrição e o preço vigente dependem só de `id_produto` (dependência parcial) e por isso ficam em `produto`; em `item_venda` ficam só `quantidade` e `preco_unitario_venda`, que dependem do par inteiro. As demais tabelas têm PK simples.
- **3FN** — eliminar dependências transitivas. Em uma "planilha de vendas" única, `nome_categoria` e `nome_fornecedor` dependeriam de `id_produto`, que depende da venda (venda → produto → categoria): o nome da categoria seria repetido em centenas de linhas e um erro de digitação quebraria o relatório por categoria (P3). Por isso `categoria` e `fornecedor` são tabelas próprias, o nome do cliente e do vendedor não se repetem em `venda`, e o saldo fica em `estoque`, não em `produto`.
- **Por que cada forma foi necessária aqui:** a 1FN permite registrar vendas com vários itens e pagamento dividido (24 vendas da massa pagam em duas formas); a 2FN permite reajustar o preço do produto sem alterar o histórico (RN04, `UPDATE` 4.1); a 3FN dá relatórios por categoria/fornecedor/vendedor sem inconsistência (G07, G08, G09).

**Redundâncias deliberadas e proteção:**

| Redundância | Por quê | Proteção |
|---|---|---|
| `item_venda.preco_unitario_venda` | Preço praticado não muda com o reajuste (as tintas vendidas antes de abril/2026 mantêm o preço antigo) | Gravado na venda (RN04) |
| `item_venda.subtotal` | Relatórios mais simples | Coluna gerada pelo MySQL: não diverge |
| `venda.valor_total` | Total instantâneo no balcão | Auditoria A01 |
| `estoque.quantidade_atual` | Saldo instantâneo | Só triggers alteram na venda; `CHECK >= 0`; A06 |

### 1.5 Justificativas Técnicas das Decisões

| Decisão | Justificativa | RN |
|---|---|---|
| **PK substituta** (`INT AUTO_INCREMENT`) em todas as tabelas | Código do PDV, CPF/CNPJ e nomes podem ser digitados errado ou mudar; um número interno estável evita atualizar FKs. As chaves naturais ficam `UNIQUE` | RN11, RN12 |
| **FKs `NOT NULL`** em produto e venda | Todo produto tem categoria e fornecedor; toda venda tem cliente e funcionário | RN13, RN14 |
| **`ON DELETE CASCADE` só em `item_venda → venda`** | O item não existe sem a venda; pagamento e cadastros nunca somem em cascata | RN17 |
| **ESTOQUE separado de PRODUTO (1:1)** | Separa o dado que muda a cada venda do cadastro; permite evoluir para estoque por depósito | RN13 |
| **`item_venda` associativa + `UNIQUE (id_venda, id_produto)`** | Resolve o N:N, guarda o preço praticado e impede produto repetido | RN03, RN04 |
| **`status_venda` em vez de apagar** | Orçamento, venda e cancelamento no mesmo registro, com histórico | RN06, RN08, RN10 |
| **Cliente "Consumidor final"** | Boa parte das vendas de balcão é feita sem cadastro; evita FK nula e dados pessoais desnecessários (minimização da LGPD) | RN14, RN18 |
| **`CHECK`** de valores (preço, quantidade, saldo, total, valor pago, parcelas) e de formato (CPF/CNPJ) | Bloqueiam valores impossíveis na origem | RN02, RN07, RN09, RN11 |
| **`ENUM`** em `tipo_pessoa`, `status_venda`, `forma_pagamento` | Só os valores previstos no dicionário | RN09 |
| **Triggers de estoque** (7, criados antes da carga) | A regra vale para qualquer aplicação; a própria massa passa pela baixa automática; a variável `@venda_em_exclusao` evita devolução em dobro no `DELETE` em cascata | RN01, RN06, RN08 |
| **Índices** `ix_venda_data` e `ix_venda_status_data` | Consultas gerenciais por período e status | RNF05 |
| **`DECIMAL(10,2)`** | Dinheiro sem erro de arredondamento | RN05, RN09 |
| **MySQL 8.0.16+** | SGBD da disciplina; `CHECK` só é aplicada a partir do 8.0.16 e `DEFAULT (CURRENT_DATE)` exige 8.0.13 | — |

### 1.6 Proposta de Arquitetura Analítica para BI e IA

```
PDV / balcão ──► MySQL (OLTP, 9 tabelas, triggers de estoque)
                     │  views (somente leitura) / exportação periódica
                     ▼
          Camada analítica (8 views + consultas G01–G16)
                     │
        ┌────────────┴─────────────┐
        ▼                          ▼
  Painéis de BI (gerência)    Modelos de IA (demanda, reposição)
```

**Informações estratégicas:** quanto a loja fatura e com quais produtos (curva ABC), quais marcas sustentam a receita (negociação com fornecedor), quando falta mercadoria, quem compra (balcão, PF, PJ), em que dias e horários a loja precisa dos dois funcionários, quanto dinheiro está parado em estoque.

**KPIs** (cada um com consulta no script):

| KPI | Fórmula | Período | Meta | Consulta | Na massa (jan–jun/2026) |
|---|---|---|---|---|---|
| KPI1 Faturamento | Σ `valor_total` das vendas concluídas | mensal | R$ 20.000 (informado pela loja) | G01 | R$ 14,2 mil a R$ 22,1 mil; média R$ 18,9 mil |
| KPI2 Ticket médio | faturamento ÷ nº de vendas concluídas | mensal | ≥ R$ 130 `[VALIDAR]` | G02 | média R$ 128,43 |
| KPI3 Unidades vendidas | Σ `quantidade` dos itens de vendas concluídas | mensal | ≈ 500 (informado) | G03 | média 536 |
| KPI4 Taxa de cancelamento | canceladas ÷ (concluídas + canceladas) | mensal | ≤ 5% | G04 | 1,9% a 4,6% |
| KPI5 Produtos abaixo do mínimo | nº de produtos com saldo ≤ mínimo | diário | 0 | G05 | 7 na carga |
| KPI6 Cobertura de estoque | saldo ÷ média diária vendida (90 dias) | diário | ≥ 15 dias `[VALIDAR]` | G06 | lista os 15 piores |
| KPI7 Desempenho por vendedor | faturamento e ticket por funcionário | mensal | — | G09 | |
| KPI8 Concentração da receita (ABC) | % acumulado da receita por produto | semestral | — | G10 | 18 produtos fazem 80% |
| KPI9 Formas de pagamento | % do valor por forma | mensal | — | G11 | PIX 34%, crédito 21%, boleto 19% |
| KPI10 Perfil de cliente | % do faturamento por perfil | mensal | — | G14 | balcão 40%, PJ 36%, PF 24% |
| KPI11 Vendas por dia/turno | nº de vendas por dia da semana e turno | semanal | — | G15 | |
| KPI12 Valor do estoque | Σ saldo × preço de venda | mensal | — | G16 | |

**Rastreabilidade — problema ou KPI → tabelas → consulta:**

| Problema ou KPI | Tabelas envolvidas | Consulta no script |
|---|---|---|
| P1 base única, orçamentos e visão do estoque | VENDA, CLIENTE, ESTOQUE, PRODUTO, CATEGORIA | G13, G14, G16 |
| P2 ponto de reposição | ESTOQUE, PRODUTO, FORNECEDOR, ITEM_VENDA | G05, G06, G10 |
| P3 relatórios por vendedor/categoria/fornecedor | VENDA, ITEM_VENDA, PRODUTO, CATEGORIA, FORNECEDOR, FUNCIONARIO | G01, G02, G07, G08, G09, G15 |
| P4 baixa automática de estoque | ITEM_VENDA, VENDA, ESTOQUE | G03, G06, A06 |
| P5 conferência de venda × pagamento e caixa | PAGAMENTO, VENDA, ITEM_VENDA | G11, G12, A01, A02, A03 |
| P6 cancelamentos sem perder histórico | VENDA | G04 |
| KPI1 a KPI12 | ver tabela de KPIs | G01–G16 |

**Potencial para BI:** uma ferramenta de BI (Power BI, Metabase, Looker Studio) ligada às 8 views e às consultas G01–G16 entrega um painel com faturamento × meta, ticket médio, curva ABC, alerta de reposição, formas de pagamento e desempenho por vendedor. O modelo já é praticamente um esquema estrela: fatos em `item_venda` e `pagamento`; dimensões tempo (`data_venda`), produto/categoria/fornecedor, funcionário e cliente.

**Aplicações de IA** (propostas): (1) **previsão de demanda** por produto e mês sobre `item_venda` (tintas têm sazonalidade: verão e fim de ano); (2) **reposição sugerida**, em que G05/G06 são a versão em SQL e um modelo ajusta o estoque mínimo pelo giro real; (3) **produtos comprados juntos** (regras de associação sobre `item_venda`: tinta + rolo + fita + lixa) para sugerir itens no balcão; (4) **detecção de anomalias** em cancelamentos e diferenças de caixa (G04, A01–A03).

**Cuidados:** CPF/CNPJ, telefone, e-mail e endereço ficam fora da camada analítica (LGPD, RN18). A massa é 100% fictícia.

---

## 2. Modelo Lógico Relacional

![Modelo lógico](docs/modelo_logico.png)

- **Tabelas, colunas com tipo, PK, FK e cardinalidade (mín, máx) em cada ponta.** Gerado com **Graphviz** a partir do catálogo do MySQL real (`scripts/gerar_docs_banco.py`), então reflete exatamente o banco. Versão vetorial: [`docs/modelo_logico.svg`](docs/modelo_logico.svg).
- `[VALIDAR]` O esqueleto pede a **notação visual do brModelo** para o modelo lógico. Recomenda-se redesenhá-lo no brModelo Web a partir deste diagrama (mesmas tabelas, tipos, PK/FK e cardinalidades) e salvar a imagem em `docs/`.
- As demais restrições (`NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`) estão no **dicionário de dados**: [`docs/dicionario_dados.html`](docs/dicionario_dados.html), no modelo do `02-03g_Exemplo_Dicionario_Dados.pdf` (modelo conceitual, fluxo de dados, convenções, notação formal por entidade, índices, log de acesso e acesso por operação/LGPD).

## 3. Script SQL Completo

O script único é [`docs/script.sql`](docs/script.sql), na ordem exigida, montado por [`docs/build_script.sh`](docs/build_script.sh) a partir dos arquivos numerados:

| Arquivo | Conteúdo (ordem do esqueleto) |
|---|---|
| `01_create_database.sql` | 1. `CREATE DATABASE` |
| `02_create_tables.sql` | 2–3. `CREATE TABLE` com PK, FK, `NOT NULL`, `UNIQUE`, `CHECK`, `ENUM`, `DEFAULT`, coluna gerada e índices |
| `03_triggers_views.sql` | 7 triggers (estoque e RN01) e 8 views — criados antes da carga para a massa passar pelas regras |
| `04_massa_de_dados.sql` | 4. `INSERT INTO` (gerado por `scripts/gerar_massa.py`) |
| `05_select_join.sql` | 5. `SELECT` com `JOIN` (S01–S05) |
| `06_update_delete.sql` | 6–7. `UPDATE` (reajuste, orçamento → venda, cadastro, reposição) e `DELETE` (cancelamento, item de orçamento, venda duplicada com devolução de estoque, funcionário, demonstração da auditoria com `ROLLBACK`) |
| `07_consultas_gerenciais.sql` | 8. **G01–G16**, cada uma com código, pergunta e problema/KPI atendido |
| `08_consultas_auditoria.sql` | 9. **A01–A10**, cada uma com código, pergunta e `Verifica: RNxx` |
| `09_testes_restricoes.sql` | 14 operações inválidas que o banco deve rejeitar (fora do script único; rodar com `--force`) |

Exemplo de cabeçalho usado:

```sql
-- G05 — Quais produtos estao no ponto de reposicao agora?
-- Atende: KPI5 Produtos abaixo do minimo (meta: 0) · P2

-- A03 — Existe venda concluida cuja soma dos pagamentos difere do total?
-- Verifica: RN09 (pagamento integral, em uma ou mais formas)
```

Como executar:

```bash
mysql -u root -p --default-character-set=utf8mb4 < docs/script.sql
```

```bash
mysql -u root -p --force loja_tintas_materiais < docs/09_testes_restricoes.sql
```

**Testes (09/11/2026, MySQL 8.0.46, banco vazio):** script executado do início ao fim **sem erros (exit 0)**; auditoria **A01–A10 com 0 violações** na carga e após os `UPDATE`/`DELETE`; **14 de 14** operações inválidas rejeitadas (quantidade zero, preço negativo, CPF duplicado, CPF com formato errado, código interno duplicado, produto inexistente, produto inativo, cliente inexistente, produto repetido na venda, venda maior que o estoque, parcelas = 0, forma de pagamento inválida, exclusão de produto e de cliente com histórico). A seção 5.5 do `06` mostra a auditoria A01 encontrando uma divergência provocada dentro de uma transação desfeita com `ROLLBACK`.

## 4. Massa de Dados

Arquivo: [`docs/04_massa_de_dados.sql`](docs/04_massa_de_dados.sql), gerado por [`scripts/gerar_massa.py`](scripts/gerar_massa.py) (Python, semente fixa: a mesma saída a cada execução). **Nenhum dado pessoal real**: nomes, CPFs, CNPJs, telefones e e-mails são inventados. Os 67 produtos (código, EAN, NCM, descrição) são os reais das listas do PDV.

**Como o porte real justifica o volume de cada tabela** (período simulado: jan–jun/2026, segunda a sábado):

| Tabela | Linhas | Justificativa |
|---|---|---|
| categoria | 5 | Categorias das listas do PDV |
| fornecedor | 10 | Marcas reais das listas (contatos fictícios) |
| produto | 67 | Itens reais das listas de preço; 2 inativados no fim do período (descontinuados) |
| estoque | 67 | 1 por produto; 7 terminam no ponto de reposição |
| funcionario | 3 | Os **2 funcionários** da loja + 1 ex-funcionário desligado em 31/03 (mostra o histórico preservado e `ativo = 0`) |
| cliente | 121 | "Consumidor final" + 95 PF + 25 PJ; 10 nunca compraram |
| venda | 940 | ≈ 150 vendas/mês (881 concluídas, 31 canceladas, 28 orçamentos) → com ticket médio de R$ 128, dá **≈ R$ 18,9 mil/mês** (real: ≈ R$ 20 mil) |
| item_venda | 2.199 | ≈ 2,3 itens por venda → **≈ 536 unidades/mês** (real: ≈ 500) |
| pagamento | 905 | 1 por venda concluída; 24 vendas pagas em duas formas; 32 parcelamentos no crédito; boleto só para PJ |

**Variedade para os testes:** vendas canceladas (3–5% ao mês), orçamentos em aberto, clientes sem compras, produtos abaixo do mínimo e zerados, 5 formas de pagamento, pagamento dividido, parcelamento, boleto com vencimento posterior, reajuste de 5% nas tintas em 01/04 (vendas antigas mantêm o preço antigo), ex-funcionário com vendas, produtos inativos com histórico, variação mensal (fevereiro mais fraco, junho mais forte).

**Coerência:** o estoque inicial é calculado para que nenhum saldo fique negativo depois das baixas automáticas; todo total bate com os itens e todo pagamento com o total — a auditoria A01–A10 retorna 0 violações.

## 5. Repositório GitHub

```text
Banco-de-dados-3feira/
├── README.md                      ← relatório técnico (Entrega 2 + Anexo A com a Entrega 1)
├── levantamento/levantamento.md   ← levantamento da entrevista (o grupo completa)
├── evidencias/                    ← fotos JPG da visita (balcão/PDV, loja)
├── docs/                          ← script.sql, 01..09, build_script.sh,
│                                    modelo lógico (.png/.svg/.dot), dicionario_dados.html
├── entrega-1/                     ← DER no brModelo (PDF), DER em Chen (PNG), dicionário conceitual (HTML)
├── fluxograma/                    ← fluxos de venda e de reposição (.dot/.png/.svg)
└── scripts/                       ← gerar_massa.py, gerar_docs_banco.py, gerar_dicionario.py
```

**Commits:** o histórico deve ser **equilibrado entre os 4 integrantes**, cada um com a **própria conta do GitHub** e nome compatível com a tabela de integrantes. Evitar um único commit final.

**Responsabilidades:** `[PREENCHER]` (ex.: visita e levantamento; DER no brModelo; script SQL; documentação; pitch e vídeo).

## 6. Uso de Inteligência Artificial

| Item | Registro |
|---|---|
| **Ferramentas e etapas** | **ChatGPT** (Entrega 1: apoio na construção do banco e alteração de dados). **Claude (Anthropic)**: script SQL inicial e esqueletos da documentação (Entrega 1); na Entrega 2: reorganização do repositório no padrão do esqueleto, testes no MySQL 8.0.46, gerador da massa de dados, consultas G01–G16 e A01–A10, códigos RN, dicionário no modelo 02-03g, diagrama do modelo lógico, fluxogramas, levantamento de processos/requisitos/regras/KPIs típicos de lojas de materiais de construção e redação deste relatório |
| **Motivação** | Organizar o trabalho no padrão do esqueleto, testar o script de verdade no MySQL, gerar uma massa coerente com o porte real e conferir o atendimento a cada item da Entrega 2 |
| **Prompts utilizados** | "gostaria que você pudesse me fazer uma atualização geral de como está esse projeto referente a aula de banco de dados. Gostaria que você utilizasse esse projeto como base de organização e apresentação [repositório de referência], não quero que copie o tema"; "Coloque mais um integrante nos membros"; "você consegue acessar o drive agora?" (material da disciplina); "Sim, por gentileza" (aplicar os ajustes do esqueleto). O prompt da Entrega 1 está no [Anexo A, seção 9](#9-uso-de-inteligência-artificial) |
| **Resposta recebida (resumo)** | Reorganização do repositório; script dividido em arquivos e testado; lista do que faltava em relação ao esqueleto (códigos G/A e RN, KPIs com meta, levantamento, responsável, volume da massa, notação brModelo, dicionário no modelo 02-03g); geração dos artefatos correspondentes |
| **Fontes consultadas e verificadas** | Esqueleto e enunciado da Entrega 2, modelo de dicionário 02-03g e links da disciplina (Drive do professor); números da loja (informados pelo grupo); execução real do script no MySQL 8.0.46 |
| **Trechos rejeitados ou corrigidos** | O cabeçalho do script dizia "testado em MariaDB": refeito e documentado em MySQL 8.0.46. O `FLUXOGRAMA.pdf` era o DER do brModelo e foi renomeado. A primeira massa (20 vendas) não refletia o porte: substituída por uma massa calibrada (≈ R$ 18,9 mil e ≈ 536 unidades/mês). A primeira calibração gerou ≈ 700 unidades e R$ 14 mil/mês (produtos baratos demais), e a seguinte R$ 26 mil/mês; os pesos foram ajustados até chegar perto dos números reais. Exemplos de `UPDATE`/`DELETE` com id fixo foram trocados por consultas, para não quebrar se a massa mudar. Dados pessoais trocados por fictícios |
| **Justificativa da escolha final** | Mantido o que foi verificado executando no MySQL e conferindo com o esqueleto; dados reais da loja (responsável, entrevista, correção da E1) ficaram como `[PREENCHER]`, porque a IA não pode inventá-los |
| **Reflexão crítica** | `[PREENCHER]` texto do grupo (sugestões: o que a IA não podia saber; o que só foi descoberto rodando o script; quais respostas vieram genéricas por falta de contexto no prompt; o que o grupo aprendeu de modelagem revisando o material) |

## 7. Apresentação Corporativa Final

**Vídeo do pitch (8 min, YouTube "Não listado"):** `[PREENCHER — link até 16/11]`. A Máximo Das Tintas não está na lista de seminários presenciais da turma de terça; por isso o pitch é entregue em vídeo, com o link aqui no README.

Roteiro (ordem do esqueleto, slides limpos, sem blocos de texto):

1. **Problema (1 min)** — loja com 2 funcionários, ≈ R$ 20 mil/mês, controle em PDF/planilha (P1–P6); foto do balcão.
2. **Solução (1 min)** — 9 tabelas integradas; regras e estoque garantidos pelo próprio banco.
3. **Modelo lógico (1,5 min)** — diagrama; o que mudou desde o DER do brModelo.
4. **SQL rodando (1,5 min)** — `script.sql` do zero; converter um orçamento e ver o estoque baixar; tentar vender além do estoque (T10) e ver o bloqueio.
5. **Consultas (1,5 min)** — G01 faturamento × meta, G05 reposição, G10 curva ABC; auditoria A01–A10 com 0 violações.
6. **BI e IA (1 min)** — KPIs e rastreabilidade; previsão de demanda e produtos comprados juntos.
7. **Benefícios (0,5 min)** — estoque confiável, relatórios sem planilha, histórico preservado.

Defesa: cada integrante responde só às perguntas dirigidas a ele; todos presentes, com vestimenta corporativa.

## 8. Limitações e pontos a validar

1. **Correção da Entrega 1:** a tabela "Caso A" precisa dos apontamentos do professor. `[PREENCHER]`
2. **Notação brModelo:** o DER revisado e o modelo lógico devem ser redesenhados no brModelo. `[VALIDAR]`
3. **ENDEREÇO** virou atributo de texto em `cliente`; se exigido, criar `endereco (id_endereco, id_cliente, logradouro, numero, bairro, cidade, cep)`. `[VALIDAR]`
4. **Custo e margem (RN16):** o modelo não guarda o custo de aquisição; evolução: `produto.preco_custo` ou tabelas `compra`/`item_compra`, permitindo relatório de margem.
5. **Desconto e taxa de entrega** aparecem no PDV (foto) mas não estão no modelo; se a loja confirmar, incluir `venda.valor_desconto` e `venda.taxa_entrega` e ajustar A01. `[VALIDAR]`
6. **Troca em 2 semanas (RN15)** não é verificada pelo banco (não há data do cancelamento); evolução: `venda.data_cancelamento` + `CHECK`.
7. **Estorno:** venda cancelada depois de paga mantém o pagamento registrado; o estorno não é modelado.
8. **Entrada de mercadoria** é um `UPDATE` em `estoque`; uma tabela de movimentação daria o histórico de entradas e saídas.
9. **Evidências:** faltam endereço, responsável com telefone, foto da entrevista e o texto do levantamento. `[PREENCHER]`

## Referências da disciplina

| Tema | Link | Onde foi aplicado |
|---|---|---|
| Material da disciplina (Drive) | [Pasta do Prof. Cid Andrade](https://drive.google.com/drive/folders/1QVVdiG4LxFE7L3BSnZDFmHyakaoPX94A) | Esqueleto e enunciado da Entrega 2; modelo de dicionário 02-03g |
| Dicionário de dados | [medium.com/datapsico — Dicionário de dados](https://medium.com/datapsico/dicionario-de-dados-ac3ce726c34b) | [`docs/dicionario_dados.html`](docs/dicionario_dados.html) |
| Script SQL passo a passo (Westeros) | [cidandrade.github.io/script-sql-westeros](https://cidandrade.github.io/script-sql-westeros/#passo-2) | Ordem do `script.sql` (seção 3) |
| Conversão do DER em tabelas | [cidandrade.github.io/conversor-der-tabelas](https://cidandrade.github.io/conversor-der-tabelas/#c=lotacao&a=11&b=0n&alt=1) | Seção 1.2 |
| Cardinalidade no DER | [cidandrade.github.io/cardinalidade-der](https://cidandrade.github.io/cardinalidade-der/) | Seção 1.3 e modelo lógico |
| Normalização (conferência) | [cidandrade.github.io/normalizacao](http://cidandrade.github.io/normalizacao/#conferencia) | Seção 1.4 |

---

# Anexo A — Entrega 1 (modelo conceitual)

*Conteúdo da Entrega 1 preservado, com os campos `[PREENCHER]` já respondidos pelo grupo incorporados ao texto e os caminhos de arquivos atualizados para a nova estrutura do repositório. Os processos usam o prefixo `PR` (PR1 a PR6) para não se confundir com os problemas P1 a P6 do relatório.*

**Integrantes na Entrega 1:** Gabriel Rodrigues da Silva (46885030), Gabriel Souza (46683305), Vinicius Batista Merencio (46749527) e Ítalo Leal Oliveira (47837098).

### 1. Caracterização da Organização

- **Nome e natureza da organização:** **Máximo Das Tintas** — loja de pequeno porte do varejo de **tintas, ferramentas e materiais de construção**, com fins lucrativos, que vende ao consumidor final (pessoa física) e a pequenos profissionais/empresas de reforma e construção civil (pessoa jurídica).
- **Contexto e porte:** organização comercial de pequeno porte, com **2 funcionários** (que também fazem o atendimento), **faturamento médio de R$ 20 mil por mês** e **cerca de 500 produtos saindo do estoque por mês**. Catálogo amplo de itens de giro rápido — chaves, alicates, espátulas, pincéis, rolos, fitas, solventes e tintas de marcas como Suvinil, Bilacor, Tramontina, Ferja, Tigre, Condor, Famastil e Thompson.
- **Problemas e necessidades identificados:** o controle de produtos é feito por listas de preço em PDF/planilha exportadas do sistema de frente de caixa, sem uma base relacional própria que integre catálogo, estoque, vendas, clientes e fornecedores. Isso dificulta saber rapidamente o que está abaixo do estoque mínimo, cruzar vendas por vendedor/categoria/fornecedor e gerar relatórios gerenciais sem exportar e tratar planilhas à mão. `[PREENCHER]` problemas relatados pelo responsável durante a visita.
- **Justificativa da escolha:** caso real de pequeno negócio com processos de venda, controle de estoque e relacionamento com vários fornecedores — volume de dados suficiente sem a complexidade de uma rede varejista, adequado ao escopo da disciplina.
- **Evidências da organização:** [link da loja no Google](https://share.google/O58fMgnEeO1ujE6RM) · e-mail: maximosdastintas@gmail.com.

### 2. Processos de Negócio

- **Principais processos mapeados:**
  1. **PR1 — Cadastro de produtos:** inclusão de novos itens no catálogo (código interno, código de barras/EAN, descrição, NCM, unidade, preço, categoria e fornecedor).
  2. **PR2 — Cadastro de clientes:** pessoa física ou jurídica, com dados de contato.
  3. **PR3 — Controle de estoque:** entrada de mercadorias (compra ao fornecedor) e baixa automática a cada venda concluída.
  4. **PR4 — Registro de vendas:** abertura da venda, inclusão de itens (produto + quantidade), fechamento e associação ao vendedor responsável.
  5. **PR5 — Registro de pagamento:** forma de pagamento (dinheiro, PIX, cartão, boleto) e parcelamento, vinculado à venda.
  6. **PR6 — Reposição de estoque:** identificação de produtos abaixo do estoque mínimo para novo pedido ao fornecedor.
- **Fluxogramas:** [`fluxograma/fluxo_vendas.png`](fluxograma/fluxo_vendas.png) (PR2, PR4, PR5 e troca) e [`fluxograma/fluxo_reposicao.png`](fluxograma/fluxo_reposicao.png) (PR3 e PR6).

### 3. Requisitos do Sistema

#### 3.1 Requisitos Funcionais
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

#### 3.2 Requisitos Não Funcionais
- RNF01 — **Integridade:** toda venda deve referenciar um cliente e um funcionário já cadastrados (chaves estrangeiras obrigatórias).
- RNF02 — **Consistência:** o valor total da venda deve refletir a soma dos subtotais dos itens (verificável por consulta de auditoria).
- RNF03 — **Disponibilidade:** o sistema deve estar acessível durante o horário comercial da loja, sem indisponibilidades que impeçam o fechamento de vendas.
- RNF04 — **Segurança:** dados de clientes (CPF/CNPJ, contato) devem ter acesso restrito a usuários autorizados.
- RNF05 — **Desempenho:** consultas gerenciais (faturamento, ranking de produtos) devem responder em tempo aceitável mesmo com milhares de vendas.
- RNF06 — **Usabilidade:** o cadastro de uma venda deve ser possível em poucos passos, dado o ritmo de atendimento no balcão.

### 4. Regras de Negócio

- **Regras operacionais:**
  - Uma venda só pode ser registrada para um produto que exista no catálogo e esteja ativo.
  - Um item de venda não pode ter quantidade menor ou igual a zero.
  - Um produto não pode aparecer duas vezes na mesma venda como itens separados — quantidades adicionais atualizam a linha existente (restrição de unicidade `venda + produto`).
  - Um pagamento só pode ser registrado para uma venda existente; o valor pago deve ser maior ou igual a zero.
  - Toda venda concluída deve gerar baixa proporcional no estoque dos produtos vendidos.
  - O estoque de um produto não pode ficar negativo.
- **Restrições organizacionais:**
  - CPF/CNPJ de clientes e fornecedores devem ser únicos no cadastro, para evitar duplicidade.
  - Cada produto pertence a exatamente uma categoria e a um fornecedor principal, para permitir relatórios por essas dimensões.
  - **Troca:** prazo de **2 semanas**; a nota fiscal é exigida **somente para troca**.
  - **Precificação:** sobre o valor de compra do fornecedor é adicionada, em média, **60%**, que é repassado ao cliente como preço final.

### 5. Dicionário de Dados Conceitual (Preliminar)

> Versão em HTML: [`entrega-1/dicionario_dados_conceitual.html`](entrega-1/dicionario_dados_conceitual.html). A versão da Entrega 2, com tipos e restrições do MySQL, é o [dicionário de dados](docs/dicionario_dados.html).

#### Entidade: CATEGORIA
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_categoria | Identificador único da categoria | Obrigatório, gerado automaticamente |
| nome_categoria | Nome da categoria de produto (ex.: "Tintas e Vernizes") | Obrigatório, único |
| descricao | Descrição complementar da categoria | Opcional |

#### Entidade: FORNECEDOR
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_fornecedor | Identificador único do fornecedor | Obrigatório |
| nome_fornecedor | Razão social / marca do fornecedor (ex.: "Tramontina") | Obrigatório |
| cnpj | CNPJ do fornecedor | Obrigatório, único |
| telefone | Telefone de contato | Opcional |
| email | E-mail de contato | Opcional |

#### Entidade: PRODUTO
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

#### Entidade: ESTOQUE
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_estoque | Identificador único do registro de estoque | Obrigatório |
| id_produto | Produto ao qual o estoque se refere | Obrigatório, único (1 estoque por produto) |
| quantidade_atual | Quantidade disponível em estoque | Obrigatório, não pode ser negativo |
| quantidade_minima | Quantidade mínima antes de disparar reposição | Obrigatório, padrão 5 |
| localizacao_deposito | Localização física no depósito/prateleira | Opcional |

#### Entidade: CLIENTE
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

#### Entidade: FUNCIONARIO
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_funcionario | Identificador único | Obrigatório |
| nome | Nome do funcionário | Obrigatório |
| cargo | Cargo (vendedor, caixa, gerente) | Obrigatório |
| cpf | CPF do funcionário | Obrigatório, único |
| data_admissao | Data de admissão | Obrigatório |
| ativo | Indica se ainda trabalha na loja | Obrigatório, padrão verdadeiro |

#### Entidade: VENDA
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_venda | Identificador único da venda | Obrigatório |
| id_cliente | Cliente que realizou a compra | Obrigatório (FK) |
| id_funcionario | Funcionário que atendeu a venda | Obrigatório (FK) |
| data_venda | Data/hora da venda | Obrigatório, gerada automaticamente |
| status_venda | Orçamento, concluída ou cancelada | Obrigatório |
| valor_total | Soma dos subtotais dos itens da venda | Obrigatório, deve ser ≥ 0 |

#### Entidade: ITEM_VENDA (associativa Venda–Produto)
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_item_venda | Identificador único do item | Obrigatório |
| id_venda | Venda à qual o item pertence | Obrigatório (FK) |
| id_produto | Produto vendido | Obrigatório (FK) |
| quantidade | Quantidade vendida do produto | Obrigatório, deve ser > 0 |
| preco_unitario_venda | Preço praticado no momento da venda (histórico) | Obrigatório |
| subtotal | quantidade × preco_unitario_venda | Calculado automaticamente |

#### Entidade: PAGAMENTO
| Atributo | Descrição | Regra de negócio associada |
|---|---|---|
| id_pagamento | Identificador único | Obrigatório |
| id_venda | Venda associada ao pagamento | Obrigatório (FK) |
| forma_pagamento | Dinheiro, PIX, cartão de crédito/débito ou boleto | Obrigatório |
| valor_pago | Valor pago | Obrigatório, deve ser ≥ 0 |
| data_pagamento | Data/hora do pagamento | Obrigatório |
| parcelas | Número de parcelas (cartão de crédito) | Obrigatório, deve ser ≥ 1 |

### 6. Modelagem Conceitual (Entidades, Atributos, Relacionamentos)

- **Entidades reconhecidas:** CATEGORIA, FORNECEDOR, PRODUTO, ESTOQUE, CLIENTE, FUNCIONARIO, VENDA, ITEM_VENDA (associativa) e PAGAMENTO. Cada uma representa um conceito estável do negócio: o catálogo (categoria/fornecedor/produto/estoque), as pessoas envolvidas na venda (cliente/funcionário) e a transação (venda/item_venda/pagamento).
- **Atributos e classificações:** ver o Dicionário de Dados (seção 5). Cada entidade tem um identificador substituto (`id_*`) como chave primária e um atributo natural relevante para consulta (ex.: `codigo_interno` em produto, `cpf_cnpj` em cliente) tratado como chave candidata/única.
- **Relacionamentos pertinentes:**
  - CATEGORIA (1) — (N) PRODUTO: cada produto pertence a exatamente uma categoria; uma categoria agrupa vários produtos.
  - FORNECEDOR (1) — (N) PRODUTO: cada produto é fornecido por um fornecedor principal; um fornecedor fornece vários produtos.
  - PRODUTO (1) — (1) ESTOQUE: cada produto possui exatamente um registro de controle de estoque.
  - CLIENTE (1) — (N) VENDA: um cliente pode realizar várias vendas ao longo do tempo.
  - FUNCIONARIO (1) — (N) VENDA: um funcionário atende várias vendas.
  - VENDA (N) — (N) PRODUTO, resolvido pela entidade associativa ITEM_VENDA.
  - VENDA (1) — (N) PAGAMENTO: uma venda pode ter um ou mais pagamentos (ex.: parcial + complemento).
- **Restrições e políticas aplicadas ao modelo:** unicidade de CPF/CNPJ (cliente/fornecedor/funcionário), unicidade do código interno do produto, obrigatoriedade de categoria e fornecedor para todo produto e impossibilidade de estoque ou quantidade negativa.

### 7. Diagrama Entidade-Relacionamento (DER)

**DER em notação de Chen** — entidades em retângulo, relacionamentos em losango, atributos em elipse, com as cardinalidades 1:N e 1:1 em cada ligação ([`entrega-1/DER_chen_loja_tintas.png`](entrega-1/DER_chen_loja_tintas.png)):

![DER em notação de Chen](entrega-1/DER_chen_loja_tintas.png)

#### 7.1 DER do grupo no BRModelo (22/09/2026)

Arquivo: [`entrega-1/DER_brmodelo_22-09-2026.pdf`](entrega-1/DER_brmodelo_22-09-2026.pdf) (antes chamado `FLUXOGRAMA.pdf`). As diferenças entre este DER e o modelo final estão na [tabela de revisão da seção 1.1](#caso-a--revisão-a-partir-da-correção-da-entrega-1).

O modelo comporta evolução futura sem quebrar a estrutura atual: histórico de reajuste de preços por produto, compras/entradas junto a fornecedores, vários endereços por cliente ou metas de vendas por funcionário.

### 8. Justificativa Técnica

- **Por que uma entidade ESTOQUE separada de PRODUTO?** Para isolar um atributo que muda com alta frequência (quantidade) do cadastro descritivo do produto (que muda raramente), deixando explícito o relacionamento 1:1, que poderá evoluir para 1:N (ex.: estoque por filial) sem afetar a tabela `produto`.
- **Por que uma entidade associativa ITEM_VENDA em vez de uma FK de produto em venda?** Porque a relação real é N:N — uma venda contém vários produtos e um produto aparece em várias vendas. A associativa também é o lugar correto do **preço praticado no momento da venda**, que não deve ser confundido com o preço atual do produto.
- **Por que separar PAGAMENTO de VENDA?** Porque uma venda pode ser paga em mais de uma transação (ex.: parte em dinheiro, parte no cartão), o que exige uma relação 1:N e não um atributo simples.
- **Por que CATEGORIA e FORNECEDOR como entidades e não como texto em PRODUTO?** Para evitar redundância (o mesmo nome repetido em centenas de produtos) e permitir relatórios agregados (faturamento por categoria, por fornecedor) sem inconsistência de digitação — motivação que antecipa a normalização da Entrega 2.
- **Por que CLIENTE e FUNCIONARIO como entidades distintas?** Porque têm ciclos de vida, atributos e regras completamente diferentes (cliente compra; funcionário vende), sem ganho em uma generalização/especialização neste escopo.
- **Alternativa considerada e descartada:** produto–fornecedor como N:N. Optou-se por 1:N porque, nos catálogos da loja, cada item está associado a uma marca/fornecedor principal; o N:N fica para uma evolução futura (ex.: cotação com vários fornecedores).

### 9. Uso de Inteligência Artificial

| Item | Registro |
|------|------------------|
| **Ferramentas e etapa** | ChatGPT e Claude, para alteração de dados e auxílio na construção do banco de dados |
| **Motivação** | `[PREENCHER]` |
| **Prompt utilizado** | "tenho um trabalho da faculdade onde preciso montar um banco de dados pretendo utilizar mysql para realizar a tarefa o meu grupo escolheu o uma loja de tintas e materiais de construção me ajude a criar o banco de dados solido plausivel e com todas as informações como um otimo banco de dados deve ser foi anexado as informações da loja tambem esta anexado o esqueleto e requisitos das entregas solicitados pelo professor me ajude criar o banco de dados e tambem os requisitos que estão sendo solicitados" |
| **Resposta recebida (resumo)** | A IA avisou que não poderia inventar a organização real nem as evidências (fotos, endereço, contato), que deveriam vir da pesquisa de campo. Gerou, a partir dos catálogos anexados: 9 tabelas (categoria, fornecedor, produto, estoque, cliente, funcionario, venda, item_venda e pagamento); o script SQL com `CREATE`, PK/FK/`UNIQUE`/`CHECK`, massa fictícia (67 produtos reais dos catálogos, 8 clientes e 5 funcionários fictícios, 18 vendas), `JOIN`, `UPDATE`, `DELETE`, consultas gerenciais e de auditoria; o DER em Chen; o modelo lógico; os esqueletos do README da Entrega 1 e do relatório da Entrega 2; e o dicionário de dados em HTML. Marcou com `[PREENCHER]` o que só o grupo poderia completar. |
| **Fontes consultadas e verificadas** | Dados e planilhas (listas de preço) do estabelecimento |
| **Trechos rejeitados ou corrigidos** | Todas as informações pessoais foram trocadas por fictícias |
| **Justificativa da escolha final** | ChatGPT e Claude foram escolhidos para auxílio em informações e resolução de problemas |
| **Reflexão crítica** | `[PREENCHER]` (ex.: "a IA não pode confirmar dados reais da loja, então todos os campos de caracterização e evidências tiveram de ser preenchidos pelo grupo após a visita") |

> O conteúdo técnico deste repositório (entidades, DER, script SQL) foi produzido com apoio de IA a partir dos catálogos de produtos fornecidos pelo grupo — isso consta aqui como uso real de IA.
