#!/usr/bin/env python3
"""
Maximo das Tintas - Dicionario de Dados (docs/dicionario_dados.html)

Segue a estrutura do modelo da disciplina (02-03g_Exemplo_Dicionario_Dados.pdf):
  1. Modelo conceitual (entidades, relacionamentos e cardinalidades)
  2. Fluxo de dados (visao de DFD)
  3. Convencoes (SGBD, codificacao, notacao formal, versao)
  4. Dicionario por entidade: notacao formal + leitura + tabela de atributos
     (tipo, obrigatorio, valores permitidos, padrao, restricoes, significado) + indices
  5. Log de acesso (metadado operacional)
  6. Acesso por operacao e conformidade com a LGPD (metadado administrativo)
  7. Automacao no banco (triggers e views)

Tipos, nulos, padroes, CHECK, UNIQUE, FK e indices sao lidos do catalogo do
MySQL (information_schema), entao o dicionario mostra exatamente o que existe
no banco criado por docs/script.sql.

Uso: python3 entrega-2/scripts/gerar_dicionario.py --user root --password ... [--host --port]
"""
import argparse
import html
from pathlib import Path

from gerar_docs_banco import DB, ORDEM, DESC_COLUNA, consulta

RAIZ = Path(__file__).resolve().parent.parent.parent   # raiz do repositorio (scripts em entrega-2/scripts)
SAIDA = RAIZ / "docs" / "dicionario_dados.html"
e = html.escape

DEFINICAO = {
    "categoria": "Agrupamento comercial dos produtos, usado na exposicao da loja e nos relatorios (ex.: Tintas e Vernizes, Ferramentas Manuais).",
    "fornecedor": "Industria ou distribuidora (marca) que abastece a loja com os produtos do catalogo.",
    "produto": "Item vendido no balcao, identificado pelo codigo interno do PDV, com EAN, NCM, unidade e preco de venda vigente.",
    "estoque": "Controle fisico de cada produto: saldo atual, estoque minimo (ponto de reposicao) e local no deposito.",
    "cliente": "Quem compra: consumidor (pessoa fisica) ou empresa/profissional (pessoa juridica). Venda sem cadastro usa o cliente 'Consumidor final'.",
    "funcionario": "Pessoa que atende e registra a venda no balcao (a loja tem 2 funcionarios e 1 intermediario).",
    "venda": "Evento comercial no balcao: orcamento, venda concluida ou venda cancelada (troca/desistencia).",
    "item_venda": "Entidade associativa entre VENDA e PRODUTO: cada produto vendido, com quantidade e preco praticado.",
    "pagamento": "Recebimento de uma venda, em uma ou mais formas (dinheiro, PIX, cartao, boleto a prazo para obras parceiras).",
    "historico_preco": "Registro de cada reajuste de preco de produto, gravado automaticamente pelo banco; atende o relatorio de aumento de precos pedido pela loja.",
}

NOTACAO = {
    "categoria": ("CATEGORIA = @id_categoria + nome_categoria + (descricao)",
                  "@id_categoria identifica a categoria; o nome e obrigatorio e unico; a descricao e opcional."),
    "fornecedor": ("FORNECEDOR = @id_fornecedor + nome_fornecedor + cnpj + (telefone) + (email)",
                   "CNPJ obrigatorio, unico e com 14 digitos; contatos opcionais."),
    "produto": ("PRODUTO = @id_produto + codigo_interno + (codigo_barras) + descricao + (ncm) + unidade_medida + preco_unitario + (preco_custo) + id_categoria + id_fornecedor + ativo",
                "Todo produto pertence a uma categoria e a um fornecedor principal (FKs obrigatorias); EAN, NCM e custo vem entre ( ) porque nem todo item do PDV os tem cadastrados."),
    "estoque": ("ESTOQUE = @id_estoque + id_produto + quantidade_atual + quantidade_minima + (localizacao_deposito)",
                "id_produto obrigatorio e unico garante o 1:1 com PRODUTO; o saldo nunca e negativo."),
    "cliente": ("CLIENTE = @id_cliente + nome + [PF | PJ] + cpf_cnpj + (telefone) + (email) + (endereco) + data_cadastro",
                "[PF | PJ] exige escolher o tipo de pessoa; o documento acompanha a escolha (CPF de 11 digitos para PF, CNPJ de 14 para PJ)."),
    "funcionario": ("FUNCIONARIO = @id_funcionario + nome + cargo + cpf + data_admissao + ativo",
                    "Funcionario desligado fica com ativo = 0 e mantem o historico das vendas que atendeu."),
    "venda": ("VENDA = @id_venda + id_cliente + id_funcionario + data_venda + [ORCAMENTO | CONCLUIDA | CANCELADA] + valor_desconto + valor_total + 1{/ITEM_VENDA/}n + 0{/PAGAMENTO/}n",
              "Toda venda tem cliente e funcionario; o status e escolha obrigatoria; uma venda tem de 1 a n itens e de 0 a n pagamentos (orcamento nao tem pagamento)."),
    "item_venda": ("ITEM_VENDA = @id_item_venda + id_venda + id_produto + quantidade + preco_unitario_venda + subtotal *subtotal = quantidade x preco, calculado pelo banco*",
                   "O par (id_venda, id_produto) e unico: o mesmo produto nao repete na venda. O preco e o praticado na data, nao o vigente."),
    "historico_preco": ("HISTORICO_PRECO = @id_historico + id_produto + preco_anterior + preco_novo + data_alteracao *gravado pelo trigger trg_produto_after_update_preco*",
                        "Cada alteracao de preco gera uma linha; os dois precos sao obrigatorios e diferentes entre si."),
    "pagamento": ("PAGAMENTO = @id_pagamento + id_venda + [DINHEIRO | PIX | CARTAO_CREDITO | CARTAO_DEBITO | BOLETO] + valor_pago + data_pagamento + parcelas",
                  "A forma e escolha obrigatoria entre cinco; parcelas > 1 so no cartao de credito (auditoria A09)."),
}

VALORES = {
    ("produto", "unidade_medida"): "UN, LT, GL, KG, M...",
    ("cliente", "tipo_pessoa"): "PF | PJ",
    ("venda", "status_venda"): "ORCAMENTO | CONCLUIDA | CANCELADA",
    ("pagamento", "forma_pagamento"): "DINHEIRO | PIX | CARTAO_CREDITO | CARTAO_DEBITO | BOLETO",
    ("produto", "ativo"): "0 | 1", ("funcionario", "ativo"): "0 | 1",
    ("produto", "preco_unitario"): ">= 0", ("venda", "valor_total"): ">= 0",
    ("item_venda", "quantidade"): "> 0", ("estoque", "quantidade_atual"): ">= 0",
    ("pagamento", "valor_pago"): ">= 0", ("pagamento", "parcelas"): "1 a 24 (2x a partir de R$ 200; 3x a partir de R$ 400; limite de 24x)",
    ("venda", "valor_desconto"): ">= 0 (5% do bruto no PIX)", ("produto", "preco_custo"): ">= 0",
    ("historico_preco", "preco_novo"): ">= 0 e diferente do anterior",
    ("cliente", "cpf_cnpj"): "11 digitos (PF) ou 14 (PJ)", ("fornecedor", "cnpj"): "14 digitos",
    ("funcionario", "cpf"): "11 digitos",
}

RN_COLUNA = {
    ("produto", "codigo_interno"): "RN12", ("produto", "ativo"): "RN01, RN17", ("produto", "id_categoria"): "RN13",
    ("produto", "id_fornecedor"): "RN13", ("estoque", "id_produto"): "RN13", ("estoque", "quantidade_atual"): "RN06, RN07",
    ("cliente", "cpf_cnpj"): "RN11, RN18", ("cliente", "telefone"): "RN18", ("cliente", "email"): "RN18",
    ("cliente", "endereco"): "RN18", ("fornecedor", "cnpj"): "RN11", ("venda", "id_cliente"): "RN14",
    ("venda", "id_funcionario"): "RN14", ("venda", "status_venda"): "RN06, RN08, RN10", ("venda", "valor_total"): "RN05",
    ("item_venda", "id_produto"): "RN01, RN03", ("item_venda", "quantidade"): "RN02",
    ("item_venda", "preco_unitario_venda"): "RN04", ("item_venda", "subtotal"): "RN05",
    ("pagamento", "valor_pago"): "RN09", ("pagamento", "parcelas"): "RN09", ("pagamento", "data_pagamento"): "RN09",
    ("funcionario", "ativo"): "RN17", ("venda", "valor_desconto"): "RN19", ("produto", "preco_custo"): "RN16",
    ("pagamento", "forma_pagamento"): "RN09, RN19", ("historico_preco", "preco_novo"): "RN21",
    ("historico_preco", "id_produto"): "RN21",
}

INDICE_USO = {
    "PRIMARY": "chave primaria (indice clusterizado do InnoDB)",
    "uq_produto_codigo": "busca pelo codigo do PDV no balcao",
    "uq_cliente_doc": "evita cadastro duplicado e localiza o cliente pelo documento",
    "uq_estoque_produto": "garante o 1:1 e abre o estoque do produto",
    "uq_item_venda_produto": "impede produto repetido na venda",
    "ix_venda_data": "relatorios por periodo (G01, G02, G12)",
    "ix_venda_status_data": "consultas por status e periodo (G04, G13)",
}


def gerar(args):
    colunas = consulta(args, f"""
        SELECT table_name, column_name, column_type, is_nullable,
               IFNULL(column_default,'\\\\N'), column_key, extra
        FROM information_schema.columns WHERE table_schema='{DB}'
        ORDER BY table_name, ordinal_position""")
    fks = {(r[0], r[1]): r for r in consulta(args, f"""
        SELECT k.table_name, k.column_name, k.referenced_table_name, k.referenced_column_name, r.delete_rule
        FROM information_schema.key_column_usage k
        JOIN information_schema.referential_constraints r
          ON r.constraint_schema=k.constraint_schema AND r.constraint_name=k.constraint_name
        WHERE k.table_schema='{DB}' AND k.referenced_table_name IS NOT NULL""")}
    checks = consulta(args, f"""
        SELECT tc.table_name, cc.constraint_name, cc.check_clause
        FROM information_schema.check_constraints cc
        JOIN information_schema.table_constraints tc
          ON tc.constraint_schema=cc.constraint_schema AND tc.constraint_name=cc.constraint_name
        WHERE cc.constraint_schema='{DB}'""")
    indices = consulta(args, f"""
        SELECT table_name, index_name, non_unique, GROUP_CONCAT(column_name ORDER BY seq_in_index)
        FROM information_schema.statistics WHERE table_schema='{DB}'
        GROUP BY table_name, index_name, non_unique ORDER BY table_name, index_name='PRIMARY' DESC, index_name""")
    triggers = consulta(args, f"""
        SELECT trigger_name, action_timing, event_manipulation, event_object_table
        FROM information_schema.triggers WHERE trigger_schema='{DB}' ORDER BY event_object_table, trigger_name""")
    views = [v[0] for v in consulta(args, f"SELECT table_name FROM information_schema.views WHERE table_schema='{DB}' ORDER BY 1")]
    linhas = {t: int(consulta(args, f"SELECT COUNT(*) FROM {DB}.{t}")[0][0]) for t in ORDEM}
    uniq_col = {(t, c) for t, nome, nu, cols in indices if nu == "0" and nome != "PRIMARY" and "," not in cols for c in [cols]}

    por_tab = {}
    for t, c, tipo, nulo, d, chave, extra in colunas:
        por_tab.setdefault(t, []).append((c, tipo, nulo, d, chave, extra))

    secoes = []
    for t in ORDEM:
        notacao, leitura = NOTACAO[t]
        rows = []
        for c, tipo, nulo, d, chave, extra in por_tab[t]:
            obrig = "Sim" if nulo == "NO" else "Nao"
            marcas = []
            if chave == "PRI":
                marcas.append("PK")
            if (t, c) in fks:
                f = fks[(t, c)]
                marcas.append(f"FK &rarr; {e(f[2])}" + (" (CASCADE)" if f[4] == "CASCADE" else ""))
            if (t, c) in uniq_col:
                marcas.append("UNIQUE")
            if "auto_increment" in extra:
                marcas.append("AUTO_INCREMENT")
            if "STORED GENERATED" in extra.upper() or "VIRTUAL GENERATED" in extra.upper():
                marcas.append("coluna gerada")
            for _, nome, clausula in [x for x in checks if x[0] == t]:
                if f"`{c}`" in clausula or f" {c} " in clausula:
                    marcas.append(f"CHECK {e(nome)}")
            padrao = "" if d.replace("\\", "") == "N" else e(d)
            rn = RN_COLUNA.get((t, c), "")
            rows.append(
                f"<tr><td><code>{e(c)}</code></td><td><code>{e(tipo)}</code></td><td>{obrig}"
                f"{' (' + ', '.join(m for m in marcas if m in ('PK',) or m.startswith('FK') or m == 'UNIQUE') + ')' if any(m == 'PK' or m.startswith('FK') or m == 'UNIQUE' for m in marcas) else ''}</td>"
                f"<td>{e(VALORES.get((t, c), ''))}</td><td><code>{padrao}</code></td>"
                f"<td>{'<br>'.join(marcas)}</td><td>{e(DESC_COLUNA.get((t, c), ''))}{(' <span class=rn>' + rn + '</span>') if rn else ''}</td></tr>")
        idx = "; ".join(
            f"{'PK' if nome == 'PRIMARY' else ('UNIQUE ' if nu == '0' else 'indice ')}{'' if nome == 'PRIMARY' else e(nome)} "
            f"({e(cols)}){(' &mdash; ' + INDICE_USO[nome]) if nome in INDICE_USO else ''}"
            for tt, nome, nu, cols in indices if tt == t)
        secoes.append(f"""
<section id="{t}"><h3>{t.upper()} <span class="pill">{linhas[t]} linhas na massa</span></h3>
<p class="def">{e(DEFINICAO[t])}</p>
<pre class="formal">{e(notacao)}</pre>
<p class="leitura"><b>Leitura:</b> {e(leitura)}</p>
<div class="scroll"><table><thead><tr><th>Atributo</th><th>Tipo fisico</th><th>Obrigatorio</th><th>Valores permitidos</th>
<th>Padrao</th><th>Restricoes</th><th>Significado e relevancia</th></tr></thead><tbody>{''.join(rows)}</tbody></table></div>
<p class="idx"><b>Indices:</b> {idx}.</p></section>""")

    trig = "".join(f"<tr><td><code>{e(n)}</code></td><td>{e(tm)} {e(ev)}</td><td><code>{e(tb)}</code></td></tr>" for n, tm, ev, tb in triggers)
    vlist = ", ".join(f"<code>{e(v)}</code>" for v in views)
    nav = " &middot; ".join(f'<a href="#{t}">{t}</a>' for t in ORDEM)

    pagina = f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dicionario de Dados - Maximo das Tintas</title>
<style>
:root {{ --fg:#1d1d1f; --muted:#5f6368; --bg:#ffffff; --card:#f7f5fa; --line:#ddd6e6; --accent:#5B2C83; --rn:#2e7d32; }}
@media (prefers-color-scheme: dark) {{ :root {{ --fg:#ecebef; --muted:#a7a3ad; --bg:#16141a; --card:#211e27; --line:#3a3442; --accent:#c9a7ef; --rn:#81c784; }} }}
body {{ font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color:var(--fg); background:var(--bg);
       max-width:1200px; margin:0 auto; padding:24px 16px; line-height:1.5; }}
h1 {{ color:var(--accent); margin-bottom:4px; }} h2 {{ color:var(--accent); border-bottom:2px solid var(--line); padding-bottom:4px; margin-top:40px; }}
h3 {{ margin-top:32px; }} .sub,.def,.leitura,.idx {{ color:var(--muted); }}
.pill {{ font-size:.75em; font-weight:400; background:var(--card); border:1px solid var(--line); border-radius:999px; padding:1px 10px; margin-left:6px; color:var(--muted); }}
.rn {{ font-size:.8em; color:var(--rn); font-weight:600; white-space:nowrap; }}
pre.formal {{ background:var(--card); border-left:4px solid var(--accent); padding:10px 12px; white-space:pre-wrap; font-size:.9em; }}
.scroll {{ overflow-x:auto; }} table {{ border-collapse:collapse; width:100%; font-size:.9em; margin:8px 0; }}
th, td {{ border:1px solid var(--line); padding:6px 8px; text-align:left; vertical-align:top; }} th {{ background:var(--card); }}
nav {{ background:var(--card); border:1px solid var(--line); border-radius:8px; padding:10px 14px; }} a {{ color:var(--accent); }}
</style></head><body>
<h1>Dicionario de Dados</h1>
<p class="sub">Maximo das Tintas &middot; Modelagem de Banco de Dados &middot; Entrega 2 &middot; banco <code>{DB}</code></p>
<nav><b>Secoes:</b> <a href="#s1">1. Modelo conceitual</a> &middot; <a href="#s2">2. Fluxo de dados</a> &middot; <a href="#s3">3. Convencoes</a> &middot;
<a href="#s4">4. Entidades</a> ({nav}) &middot; <a href="#s5">5. Log de acesso</a> &middot; <a href="#s6">6. Acesso e LGPD</a> &middot; <a href="#s7">7. Triggers e views</a></nav>

<h2 id="s1">1. Modelo conceitual</h2>
<p>Loja de tintas, ferramentas e materiais de construcao de pequeno porte (2 funcionarios + 1 intermediario, R$ 300 a 500 de faturamento por dia, 100 a 120 produtos vendidos por mes).
O catalogo (categoria, fornecedor, produto e estoque) alimenta as vendas de balcao; cada venda tem cliente, funcionario, itens e pagamentos.</p>
<div class="scroll"><table><thead><tr><th>Entidade</th><th>Relaciona-se com</th><th>Cardinalidade</th></tr></thead><tbody>
<tr><td>CATEGORIA</td><td>PRODUTO</td><td>1:N &mdash; toda categoria agrupa 0..n produtos; todo produto pertence a exatamente 1 categoria</td></tr>
<tr><td>FORNECEDOR</td><td>PRODUTO</td><td>1:N &mdash; um fornecedor abastece 0..n produtos; todo produto tem 1 fornecedor principal</td></tr>
<tr><td>PRODUTO</td><td>ESTOQUE</td><td>1:1 &mdash; todo produto tem exatamente um registro de estoque</td></tr>
<tr><td>CLIENTE</td><td>VENDA</td><td>1:N &mdash; um cliente faz 0..n vendas; toda venda tem 1 cliente (balcao sem cadastro = "Consumidor final")</td></tr>
<tr><td>FUNCIONARIO</td><td>VENDA</td><td>1:N &mdash; um funcionario atende 0..n vendas; toda venda tem 1 funcionario</td></tr>
<tr><td>VENDA</td><td>PRODUTO</td><td>N:N &mdash; resolvido pela associativa ITEM_VENDA (1..n itens por venda; produto em 0..n vendas)</td></tr>
<tr><td>PRODUTO</td><td>HISTORICO_PRECO</td><td>1:N &mdash; um produto tem 0..n reajustes registrados; cada reajuste e de 1 produto</td></tr>
<tr><td>VENDA</td><td>PAGAMENTO</td><td>1:N &mdash; uma venda tem 0..n pagamentos (orcamento: 0; venda concluida: 1 ou mais)</td></tr>
</tbody></table></div>
<ul>{''.join(f'<li><b>{t.upper()}</b>: {e(DEFINICAO[t])}</li>' for t in ORDEM)}</ul>

<h2 id="s2">2. Fluxo de dados (visao de DFD)</h2>
<p>Cliente chega ao balcao &rarr; e localizado ou cadastrado em CLIENTE (ou a venda usa o "Consumidor final") &rarr; o funcionario abre a VENDA e lanca os
produtos em ITEM_VENDA, que grava o preco praticado e consulta PRODUTO (precisa estar ativo) &rarr; se a venda e CONCLUIDA, os triggers baixam o ESTOQUE;
se fica como ORCAMENTO, nada e baixado &rarr; o recebimento gera um ou mais PAGAMENTOs &rarr; troca ou desistencia muda a venda para CANCELADA e o estoque
volta &rarr; a gerencia consulta o ponto de reposicao (ESTOQUE &times; PRODUTO &times; FORNECEDOR) para comprar &rarr; toda leitura e escrita fica sujeita ao log de acesso (&sect;5)
e as regras de acesso da LGPD (&sect;6).</p>

<h2 id="s3">3. Convencoes do dicionario</h2>
<p><b>SGBD:</b> MySQL 8.0 (8.0.16+, para que as CHECK sejam aplicadas), mecanismo InnoDB &mdash; transacoes, chaves estrangeiras e indice primario clusterizado.<br>
<b>Codificacao:</b> <code>utf8mb4</code> com collation <code>utf8mb4_unicode_ci</code>: cobre a acentuacao do portugues em nomes, enderecos e descricoes.<br>
<b>Nomes:</b> tabelas e colunas em minusculas com <code>_</code>; chave primaria <code>id_&lt;tabela&gt;</code>; chave estrangeira com o mesmo nome da PK referenciada.
O grupo optou por nomes descritivos (<code>quantidade_atual</code>, <code>data_venda</code>) em vez dos prefixos NM_/DT_/QT_ do exemplo da disciplina, por legibilidade; a equivalencia e direta
(<code>nome</code> = NM_, <code>data_*</code> = DT_, <code>quantidade*</code> = QT_, <code>tipo_*</code>/<code>status_*</code> = TP_, <code>ativo</code> = IN_).</p>
<div class="scroll"><table><thead><tr><th>Simbolo</th><th>Significado</th></tr></thead><tbody>
<tr><td>=</td><td>e composto de</td></tr><tr><td>+</td><td>e (elementos obrigatorios)</td></tr><tr><td>( )</td><td>opcional</td></tr>
<tr><td>{{ }}, n{{ }}m</td><td>iteracao, com minimo n e maximo m</td></tr><tr><td>[ | ]</td><td>escolha obrigatoria entre alternativas</td></tr>
<tr><td>/ /</td><td>rotulo de um grupo repetitivo</td></tr><tr><td>@</td><td>identificador (chave primaria)</td></tr><tr><td>* *</td><td>comentario, fora da estrutura formal</td></tr>
</tbody></table></div>
<p><b>Codigos RNxx:</b> regras de negocio do README (secao 1.1/Anexo A), citadas em verde junto ao atributo que as implementa.<br>
<b>Versao:</b> v2.1, 10/novembro/2026 (Entrega 2, apos a entrevista de 07/11). v1.0 = dicionario conceitual da Entrega 1 (<code>entrega-1/dicionario_dados_conceitual.html</code>).
Tipos, nulos, padroes e restricoes foram gerados do catalogo do MySQL por <code>entrega-2/scripts/gerar_dicionario.py</code>.</p>

<h2 id="s4">4. Dicionario de dados por entidade</h2>
{''.join(secoes)}

<h2 id="s5">5. Log de acesso (metadado operacional)</h2>
<p>As dez tabelas ficam sob o mesmo mecanismo de auditoria do SGBD. Em producao, recomenda-se o plugin de auditoria do MySQL (<code>audit_log</code>,
gravando em JSON) ou, na sua ausencia, o log geral (<code>general_log=ON</code>, <code>log_output=TABLE</code>), consultavel em <code>mysql.general_log</code>.
O log registra quem leu ou alterou cadastros de clientes (dado pessoal) e precos. A retencao do log segue politica propria (sugestao: 12 meses),
independente dos dados de venda. As consultas de auditoria A01&ndash;A10 (<code>docs/08_consultas_auditoria.sql</code>) complementam o log verificando a integridade dos dados.</p>

<h2 id="s6">6. Acesso por operacao e conformidade com a LGPD (metadado administrativo)</h2>
<div class="scroll"><table><thead><tr><th>Tabela</th><th>Ler</th><th>Inserir</th><th>Atualizar</th><th>Apagar</th></tr></thead><tbody>
<tr><td>CATEGORIA, FORNECEDOR, PRODUTO</td><td>Todos</td><td>Gerente</td><td>Gerente (preco, ativo)</td><td>Ninguem com historico &mdash; inativar (RN17)</td></tr>
<tr><td>ESTOQUE</td><td>Todos</td><td>Gerente</td><td>Triggers de venda; Gerente (entrada de mercadoria)</td><td>Ninguem</td></tr>
<tr><td>CLIENTE</td><td>Vendedor, Gerente</td><td>Vendedor</td><td>Vendedor</td><td>Ninguem com historico; anonimizar a pedido do titular</td></tr>
<tr><td>FUNCIONARIO</td><td>Gerente</td><td>Gerente</td><td>Gerente</td><td>Ninguem com historico &mdash; inativar</td></tr>
<tr><td>VENDA, ITEM_VENDA</td><td>Vendedor, Gerente</td><td>Vendedor</td><td>Vendedor (status); Gerente</td><td>Gerente (lancamento em duplicidade); cancelar e o padrao (RN08)</td></tr>
<tr><td>HISTORICO_PRECO</td><td>Gerente, escritorio</td><td>Somente o trigger</td><td>Ninguem</td><td>Ninguem</td></tr>
<tr><td>PAGAMENTO</td><td>Vendedor, Gerente</td><td>Vendedor</td><td>Gerente</td><td>Gerente</td></tr>
</tbody></table></div>
<p>CPF/CNPJ, telefone, e-mail e endereco de CLIENTE e o CPF de FUNCIONARIO sao <b>dados pessoais</b> (LGPD, art. 5&ordm;, I). O tratamento se ampara na execucao do
contrato de compra e venda e no cumprimento de obrigacao legal/fiscal (art. 7&ordm;, II e V). Minimizacao: a venda de balcao nao exige cadastro (cliente
"Consumidor final"). Esses campos ficam fora da camada analitica de BI (README, secao 1.6). A pedido do titular, o cadastro e anonimizado &mdash; nunca apagado
fisicamente, para preservar o historico fiscal das vendas (RN18). Nao ha dado pessoal sensivel (art. 5&ordm;, II) no modelo. Toda a massa de dados do projeto e ficticia.</p>

<h2 id="s7">7. Automacao no banco: triggers e views</h2>
<div class="scroll"><table><thead><tr><th>Trigger</th><th>Momento</th><th>Tabela</th></tr></thead><tbody>{trig}</tbody></table></div>
<p><b>Views ({len(views)}):</b> {vlist}.</p>
</body></html>
"""
    SAIDA.write_text(pagina, encoding="utf-8")
    print(f"Gerado: {SAIDA.relative_to(RAIZ)}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=3306)
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default="")
    gerar(ap.parse_args())
