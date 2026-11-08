#!/usr/bin/env python3
"""
Maximo das Tintas - gera a documentacao do MODELO LOGICO a partir do banco real.

Le o catalogo (information_schema) do banco `loja_tintas_materiais` ja criado
por docs/script.sql e gera:
  - docs/modelo_logico.dot / .png / .svg  (diagrama, via Graphviz)
  - docs/dicionario_dados_logico.html     (dicionario de dados logico)

Assim o diagrama e o dicionario mostram exatamente o que existe no MySQL,
e nao uma copia manual que pode ficar desatualizada.

Requisitos: cliente `mysql` no PATH, Graphviz (`dot`) e o banco ja criado.
Uso:
    mysql -u root -p < docs/script.sql
    python3 scripts/gerar_docs_banco.py --user root --password ... [--host 127.0.0.1 --port 3306]
"""
import argparse
import html
import subprocess
from pathlib import Path

DB = "loja_tintas_materiais"
RAIZ = Path(__file__).resolve().parent.parent
DOCS = RAIZ / "docs"

# Ordem de exibicao das tabelas (catalogo -> pessoas -> transacao)
ORDEM = ["categoria", "fornecedor", "produto", "estoque",
         "cliente", "funcionario", "venda", "item_venda", "pagamento"]

DESC_TABELA = {
    "categoria": "Agrupa os produtos do catalogo (ex.: Tintas e Vernizes, Ferramentas Manuais).",
    "fornecedor": "Marca/distribuidor que fornece os produtos (ex.: Tramontina, Suvinil).",
    "produto": "Item do catalogo vendido no balcao, com codigo do PDV, EAN, NCM e preco vigente.",
    "estoque": "Saldo e estoque minimo de cada produto (1:1 com produto), separado do cadastro.",
    "cliente": "Quem compra: pessoa fisica (consumidor) ou juridica (pintor, construtora).",
    "funcionario": "Quem atende/registra a venda no balcao.",
    "venda": "Cabecalho da venda (orcamento, concluida ou cancelada), com cliente e vendedor.",
    "item_venda": "Associativa VENDA x PRODUTO (N:N): quantidade e preco praticado no momento da venda.",
    "pagamento": "Pagamento(s) de uma venda: forma, valor e parcelas (1:N com venda).",
}

# Significado de negocio de cada coluna (a regra tecnica vem do catalogo)
DESC_COLUNA = {
    ("categoria", "id_categoria"): "Identificador da categoria",
    ("categoria", "nome_categoria"): "Nome da categoria",
    ("categoria", "descricao"): "Descricao complementar",
    ("fornecedor", "id_fornecedor"): "Identificador do fornecedor",
    ("fornecedor", "nome_fornecedor"): "Razao social / marca",
    ("fornecedor", "cnpj"): "CNPJ (somente digitos)",
    ("fornecedor", "telefone"): "Telefone comercial",
    ("fornecedor", "email"): "E-mail comercial",
    ("produto", "id_produto"): "Identificador interno do produto",
    ("produto", "codigo_interno"): "Codigo usado no PDV da loja (ex.: 16642)",
    ("produto", "codigo_barras"): "Codigo de barras EAN (nem todo item tem)",
    ("produto", "descricao"): "Descricao comercial (ex.: CHV FENDA 1/8X5 AM TRAMON)",
    ("produto", "ncm"): "Classificacao fiscal NCM",
    ("produto", "unidade_medida"): "Unidade de venda (UN, LT, GL...)",
    ("produto", "preco_unitario"): "Preco de venda vigente",
    ("produto", "id_categoria"): "Categoria do produto",
    ("produto", "id_fornecedor"): "Fornecedor principal do produto",
    ("produto", "ativo"): "1 = ainda comercializado; 0 = inativo (nao se apaga produto com historico)",
    ("estoque", "id_estoque"): "Identificador do registro de estoque",
    ("estoque", "id_produto"): "Produto controlado (um registro por produto)",
    ("estoque", "quantidade_atual"): "Saldo atual; baixado/devolvido pelos triggers de venda",
    ("estoque", "quantidade_minima"): "Ponto de reposicao (vw_produtos_abaixo_minimo)",
    ("estoque", "localizacao_deposito"): "Prateleira / posicao no deposito",
    ("cliente", "id_cliente"): "Identificador do cliente",
    ("cliente", "nome"): "Nome ou razao social",
    ("cliente", "tipo_pessoa"): "PF ou PJ",
    ("cliente", "cpf_cnpj"): "CPF (11) ou CNPJ (14 digitos)",
    ("cliente", "telefone"): "Telefone de contato",
    ("cliente", "email"): "E-mail de contato",
    ("cliente", "endereco"): "Endereco (texto unico)",
    ("cliente", "data_cadastro"): "Data do primeiro cadastro",
    ("funcionario", "id_funcionario"): "Identificador do funcionario",
    ("funcionario", "nome"): "Nome do funcionario",
    ("funcionario", "cargo"): "Cargo (vendedor, caixa, gerente)",
    ("funcionario", "cpf"): "CPF (somente digitos)",
    ("funcionario", "data_admissao"): "Data de admissao",
    ("funcionario", "ativo"): "1 = trabalha na loja; 0 = desligado",
    ("venda", "id_venda"): "Numero da venda",
    ("venda", "id_cliente"): "Cliente da venda",
    ("venda", "id_funcionario"): "Funcionario que atendeu",
    ("venda", "data_venda"): "Data e hora da venda",
    ("venda", "status_venda"): "ORCAMENTO, CONCLUIDA ou CANCELADA; so CONCLUIDA mexe no estoque",
    ("venda", "valor_total"): "Total da venda (conferido pela auditoria 7.1)",
    ("item_venda", "id_item_venda"): "Identificador do item",
    ("item_venda", "id_venda"): "Venda a que o item pertence",
    ("item_venda", "id_produto"): "Produto vendido",
    ("item_venda", "quantidade"): "Quantidade vendida",
    ("item_venda", "preco_unitario_venda"): "Preco praticado na venda (historico, nao muda com reajuste)",
    ("item_venda", "subtotal"): "Coluna gerada: quantidade x preco_unitario_venda",
    ("pagamento", "id_pagamento"): "Identificador do pagamento",
    ("pagamento", "id_venda"): "Venda paga",
    ("pagamento", "forma_pagamento"): "DINHEIRO, PIX, CARTAO_CREDITO, CARTAO_DEBITO ou BOLETO",
    ("pagamento", "valor_pago"): "Valor desta parcela/transacao",
    ("pagamento", "data_pagamento"): "Data e hora do pagamento",
    ("pagamento", "parcelas"): "Numero de parcelas (cartao de credito)",
}

# Cardinalidade (min,max) em cada ponta de cada FK: (lado_pai, lado_filho)
CARD = {
    ("produto", "id_categoria"): ("(1,1)", "(0,N)"),
    ("produto", "id_fornecedor"): ("(1,1)", "(0,N)"),
    ("estoque", "id_produto"): ("(1,1)", "(1,1)"),
    ("venda", "id_cliente"): ("(1,1)", "(0,N)"),
    ("venda", "id_funcionario"): ("(1,1)", "(0,N)"),
    ("item_venda", "id_venda"): ("(1,1)", "(1,N)"),
    ("item_venda", "id_produto"): ("(1,1)", "(0,N)"),
    ("pagamento", "id_venda"): ("(1,1)", "(0,N)"),
}


def consulta(args, sql):
    cmd = ["mysql", "-B", "-N", "--default-character-set=utf8mb4",
           "-h", args.host, "-P", str(args.port), "-u", args.user]
    if args.password:
        cmd.append(f"-p{args.password}")
    cmd += ["-e", sql]
    out = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout
    return [linha.split("\t") for linha in out.splitlines() if linha]


def ler_catalogo(args):
    colunas = consulta(args, f"""
        SELECT table_name, column_name, column_type, is_nullable,
               IFNULL(column_default,'\\\\N'), column_key, extra, ordinal_position
        FROM information_schema.columns WHERE table_schema='{DB}'
        ORDER BY table_name, ordinal_position""")
    fks = consulta(args, f"""
        SELECT k.table_name, k.column_name, k.referenced_table_name,
               k.referenced_column_name, k.constraint_name, r.delete_rule
        FROM information_schema.key_column_usage k
        JOIN information_schema.referential_constraints r
          ON r.constraint_schema=k.constraint_schema AND r.constraint_name=k.constraint_name
        WHERE k.table_schema='{DB}' AND k.referenced_table_name IS NOT NULL""")
    uniques = consulta(args, f"""
        SELECT tc.table_name, tc.constraint_name,
               GROUP_CONCAT(k.column_name ORDER BY k.ordinal_position)
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage k
          ON k.constraint_schema=tc.constraint_schema AND k.constraint_name=tc.constraint_name
         AND k.table_name=tc.table_name
        WHERE tc.table_schema='{DB}' AND tc.constraint_type='UNIQUE'
        GROUP BY tc.table_name, tc.constraint_name""")
    checks = consulta(args, f"""
        SELECT tc.table_name, cc.constraint_name, cc.check_clause
        FROM information_schema.check_constraints cc
        JOIN information_schema.table_constraints tc
          ON tc.constraint_schema=cc.constraint_schema AND tc.constraint_name=cc.constraint_name
        WHERE cc.constraint_schema='{DB}'""")
    linhas = {t: int(consulta(args, f"SELECT COUNT(*) FROM {DB}.{t}")[0][0]) for t in ORDEM}
    triggers = consulta(args, f"""
        SELECT trigger_name, action_timing, event_manipulation, event_object_table
        FROM information_schema.triggers WHERE trigger_schema='{DB}' ORDER BY event_object_table, trigger_name""")
    views = [v[0] for v in consulta(args, f"""
        SELECT table_name FROM information_schema.views WHERE table_schema='{DB}' ORDER BY table_name""")]
    return colunas, fks, uniques, checks, linhas, triggers, views


def gerar_diagrama(colunas, fks):
    fk_cols = {(f[0], f[1]) for f in fks}
    por_tabela = {}
    for t, c, tipo, nulo, _d, chave, _e, _o in colunas:
        por_tabela.setdefault(t, []).append((c, tipo, nulo, chave))

    cores = {"categoria": "#E8F1FB", "fornecedor": "#E8F1FB", "produto": "#E8F1FB", "estoque": "#E8F1FB",
             "cliente": "#EEF7EE", "funcionario": "#EEF7EE",
             "venda": "#FDF1E6", "item_venda": "#FDF1E6", "pagamento": "#FDF1E6"}
    linhas = [
        "digraph modelo_logico {",
        '  graph [rankdir=LR, splines=spline, nodesep=0.6, ranksep=1.6, concentrate=false, fontname="Helvetica", '
        'label="Maximo das Tintas - Modelo Logico (MySQL 8 - banco loja_tintas_materiais)", labelloc=t, fontsize=20];',
        '  node [shape=plaintext, fontname="Helvetica"];',
        '  edge [fontname="Helvetica", fontsize=11, color="#555555", arrowsize=0.8];',
    ]
    for t in ORDEM:
        rows = [f'<tr><td colspan="3" bgcolor="#5B2C83"><font color="white"><b>{t}</b></font></td></tr>']
        for c, tipo, nulo, chave in por_tabela[t]:
            marca = []
            if chave == "PRI":
                marca.append("PK")
            if (t, c) in fk_cols:
                marca.append("FK")
            if chave == "UNI" and "PK" not in marca:
                marca.append("UQ")
            nome = f"<b>{c}</b>" if "PK" in marca else (f"<i>{c}</i>" if "FK" in marca else c)
            nn = "" if nulo == "YES" else " NN"
            rows.append(f'<tr><td align="left" port="{c}_in">{" ".join(marca)}</td>'
                        f'<td align="left">{nome}</td>'
                        f'<td align="left" port="{c}_out"><font color="#555555">{html.escape(tipo)}{nn}</font></td></tr>')
        tabela = (f'<table border="1" cellborder="0" cellspacing="0" cellpadding="4" bgcolor="{cores[t]}">'
                  + "".join(rows) + "</table>")
        linhas.append(f"  {t} [label=<{tabela}>];")
    for filho, col, pai, col_pai, _n, _r in fks:
        cp, cf = CARD.get((filho, col), ("(1,1)", "(0,N)"))
        cabeca = {"(1,1)": "teetee", "(1,N)": "crowtee", "(0,1)": "teeodot"}.get(cf, "crowodot")
        linhas.append(f'  {pai}:{col_pai}_out:e -> {filho}:{col}_in:w [dir=both, arrowtail=teetee, arrowhead={cabeca}, '
                      f'taillabel="{cp}", headlabel="{cf}", labeldistance=2.2, labelangle=25];')
    linhas.append("}")
    dot = DOCS / "modelo_logico.dot"
    dot.write_text("\n".join(linhas) + "\n", encoding="utf-8")
    subprocess.run(["dot", "-Tpng", "-Gdpi=130", str(dot), "-o", str(DOCS / "modelo_logico.png")], check=True)
    subprocess.run(["dot", "-Tsvg", str(dot), "-o", str(DOCS / "modelo_logico.svg")], check=True)


def gerar_dicionario(colunas, fks, uniques, checks, linhas, triggers, views):
    e = html.escape
    fk_map = {(f[0], f[1]): f for f in fks}
    uq_map = {}
    for t, nome, cols in uniques:
        for c in cols.split(","):
            uq_map.setdefault((t, c), []).append((nome, cols))
    ck_map = {}
    for t, nome, clausula in checks:
        ck_map.setdefault(t, []).append((nome, clausula.replace("`", "")))
    por_tabela = {}
    for t, c, tipo, nulo, d, chave, extra, _o in colunas:
        por_tabela.setdefault(t, []).append((c, tipo, nulo, d, chave, extra))

    secoes = []
    for t in ORDEM:
        corpo = []
        for c, tipo, nulo, d, chave, extra in por_tabela[t]:
            restr = []
            if chave == "PRI":
                restr.append("PK")
            if "auto_increment" in extra:
                restr.append("AUTO_INCREMENT")
            if (t, c) in fk_map:
                f = fk_map[(t, c)]
                regra = f" ON DELETE {f[5]}" if f[5] != "RESTRICT" and f[5] != "NO ACTION" else ""
                restr.append(f"FK &rarr; {e(f[2])}.{e(f[3])}{regra}")
            for nome, cols in uq_map.get((t, c), []):
                restr.append(f"UNIQUE ({e(cols)})" if "," in cols else "UNIQUE")
            for nome, clausula in ck_map.get(t, []):
                if c in clausula:
                    restr.append(f"CHECK {e(clausula)}")
            if "GENERATED" in extra.upper():
                restr.append("Coluna gerada (STORED)")
            padrao = "" if d == "\\N" else e(d)
            corpo.append(
                f"<tr><td><code>{e(c)}</code></td><td><code>{e(tipo)}</code></td>"
                f"<td>{'Sim' if nulo == 'YES' else 'Nao'}</td><td><code>{padrao}</code></td>"
                f"<td>{'<br>'.join(restr)}</td><td>{e(DESC_COLUNA.get((t, c), ''))}</td></tr>")
        secoes.append(
            f'<section id="{t}"><h2>{t}</h2><p class="desc">{e(DESC_TABELA[t])} '
            f'<span class="pill">{linhas[t]} linhas na massa</span></p>'
            "<div class='scroll'><table><thead><tr><th>Coluna</th><th>Tipo</th><th>Nulo</th><th>Padrao</th>"
            "<th>Restricoes</th><th>Significado / regra de negocio</th></tr></thead><tbody>"
            + "".join(corpo) + "</tbody></table></div></section>")

    trig_rows = "".join(f"<tr><td><code>{e(n)}</code></td><td>{e(tm)} {e(ev)}</td><td><code>{e(tb)}</code></td></tr>"
                        for n, tm, ev, tb in triggers)
    view_list = "".join(f"<li><code>{e(v)}</code></li>" for v in views)
    indice = " &middot; ".join(f'<a href="#{t}">{t}</a>' for t in ORDEM)

    pagina = f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dicionario de Dados Logico - Maximo das Tintas</title>
<style>
:root {{ --fg:#1d1d1f; --muted:#5f6368; --bg:#ffffff; --card:#f7f5fa; --line:#ddd6e6; --accent:#5B2C83; }}
@media (prefers-color-scheme: dark) {{ :root {{ --fg:#ecebef; --muted:#a7a3ad; --bg:#16141a; --card:#211e27; --line:#3a3442; --accent:#c9a7ef; }} }}
body {{ font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color:var(--fg); background:var(--bg);
       max-width:1200px; margin:0 auto; padding:24px 16px; line-height:1.45; }}
h1 {{ color:var(--accent); margin-bottom:4px; }} h2 {{ color:var(--accent); border-bottom:2px solid var(--line); padding-bottom:4px; margin-top:36px; }}
.sub {{ color:var(--muted); margin-top:0; }} .desc {{ color:var(--muted); }}
.pill {{ display:inline-block; background:var(--card); border:1px solid var(--line); border-radius:999px; padding:1px 10px; font-size:.85em; margin-left:6px; }}
.scroll {{ overflow-x:auto; }}
table {{ border-collapse:collapse; width:100%; font-size:.92em; }}
th, td {{ border:1px solid var(--line); padding:6px 8px; text-align:left; vertical-align:top; }}
th {{ background:var(--card); }} code {{ font-size:.92em; }}
nav {{ background:var(--card); border:1px solid var(--line); border-radius:8px; padding:10px 14px; }}
a {{ color:var(--accent); }}
</style></head><body>
<h1>Dicionario de Dados Logico</h1>
<p class="sub">Maximo das Tintas &middot; Modelagem de Banco de Dados &middot; Entrega 2 &middot; MySQL 8 &middot; banco <code>{DB}</code></p>
<p>Gerado automaticamente por <code>scripts/gerar_docs_banco.py</code> a partir do catalogo (<code>information_schema</code>)
do banco criado por <code>docs/script.sql</code>. Tipos, nulos, padroes e restricoes sao exatamente os do MySQL;
a coluna "Significado" traz a regra de negocio. Contagem de linhas medida apos a execucao completa do script
(incluindo os exemplos de UPDATE/DELETE).</p>
<nav><b>Tabelas:</b> {indice} &middot; <a href="#automacao">triggers e views</a></nav>
{''.join(secoes)}
<section id="automacao"><h2>Triggers e views</h2>
<p>Os triggers mantem o estoque coerente com o status da venda (baixa ao concluir, devolucao ao cancelar/excluir).</p>
<div class='scroll'><table><thead><tr><th>Trigger</th><th>Momento</th><th>Tabela</th></tr></thead><tbody>{trig_rows}</tbody></table></div>
<p><b>Views ({len(views)}):</b></p><ul>{view_list}</ul></section>
</body></html>
"""
    (DOCS / "dicionario_dados_logico.html").write_text(pagina, encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=3306)
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default="")
    args = ap.parse_args()
    cat = ler_catalogo(args)
    gerar_diagrama(cat[0], cat[1])
    gerar_dicionario(*cat)
    print("Gerados: docs/modelo_logico.(dot|png|svg) e docs/dicionario_dados_logico.html")


if __name__ == "__main__":
    main()
