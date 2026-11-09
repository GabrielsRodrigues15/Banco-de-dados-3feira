#!/usr/bin/env python3
"""
Maximo das Tintas - gerador da massa de dados ficticia (docs/04_massa_de_dados.sql).

Mantem as categorias, fornecedores e os 67 produtos reais do catalogo (lidos do
proprio 04_massa_de_dados.sql) e gera, de forma reproduzivel (semente fixa):
  - funcionarios, clientes PF/PJ e o cliente "Consumidor final";
  - 6 meses de vendas (jan a jun/2026) calibradas pelos numeros reais da loja:
      ~500 unidades vendidas por mes e ~R$ 20 mil de faturamento por mes;
  - itens, pagamentos (formas variadas, parcelas e pagamento dividido),
    vendas canceladas, orcamentos em aberto, reajuste de preco das tintas;
  - estoque inicial calculado para fechar o periodo sem saldo negativo e com
    alguns produtos no ponto de reposicao.

Todos os nomes, CPFs, CNPJs, telefones e e-mails sao inventados.
Uso: python3 scripts/gerar_massa.py   (reescreve docs/04_massa_de_dados.sql)
"""
import random
import re
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

SEMENTE = 20261109
RAIZ = Path(__file__).resolve().parent.parent
ARQ = RAIZ / "docs" / "04_massa_de_dados.sql"
INICIO, FIM = date(2026, 1, 2), date(2026, 6, 30)
DATA_REAJUSTE = date(2026, 4, 1)      # tintas reajustadas em 5% nesta data
CAT_TINTAS = 2

rnd = random.Random(SEMENTE)

# --------------------------------------------------------------------------
# 1) Catalogo real (mantido do arquivo atual)
# --------------------------------------------------------------------------
texto = ARQ.read_text(encoding="utf-8")
linhas_cat = [l for l in texto.splitlines() if l.startswith("INSERT INTO categoria")]
linhas_forn = [l for l in texto.splitlines() if l.startswith("INSERT INTO fornecedor")]
linhas_prod = [l for l in texto.splitlines() if l.startswith("INSERT INTO produto")]
assert len(linhas_cat) == 5 and len(linhas_forn) == 10 and len(linhas_prod) == 67

padrao = re.compile(r"VALUES \('([^']*)', (NULL|'[^']*'), '([^']*)', (NULL|'[^']*'), '([^']*)', ([0-9.]+), (\d+), (\d+)\);")
produtos = []
for i, l in enumerate(linhas_prod, start=1):
    m = padrao.search(l)
    assert m, l
    produtos.append({"id": i, "desc": m.group(3), "preco": float(m.group(6)), "cat": int(m.group(7))})


def preco_na_data(p, d):
    """Preco praticado: tintas custavam 5% menos antes do reajuste de abril."""
    if p["cat"] == CAT_TINTAS and d < DATA_REAJUSTE:
        return round(p["preco"] / 1.05, 1) - 0.0  # arredonda para R$ 0,10
    return p["preco"]


# Popularidade (curva ABC): poucos itens vendem muito, muitos vendem pouco
for p in produtos:
    base = rnd.lognormvariate(0, 0.9)
    if p["preco"] > 300:          # galoes de 18L e thinner 18L: giro baixo
        base *= 0.45
    elif p["preco"] > 150:
        base *= 0.85
    if p["cat"] == CAT_TINTAS:    # tinta e o carro-chefe da loja
        base *= 4.0
    p["peso"] = base
PESOS = [p["peso"] for p in produtos]

# --------------------------------------------------------------------------
# 2) Pessoas (ficticias)
# --------------------------------------------------------------------------
funcionarios = [
    # nome, cargo, cpf, admissao, ativo
    ("Rogerio Almeida Prado", "Gerente e vendedor", "41592630817", "2019-03-11", 1),
    ("Tatiane Moura Ribeiro", "Vendedora e caixa", "52748193604", "2022-08-01", 1),
    ("Diego Santana Lopes", "Vendedor", "63815274930", "2023-02-06", 0),   # desligado em 31/03/2026
]
DESLIGAMENTO_DIEGO = date(2026, 3, 31)

nomes = ["Ana", "Bruno", "Carla", "Daniel", "Eduarda", "Felipe", "Gabriela", "Henrique", "Isabela", "Joao",
         "Karina", "Lucas", "Mariana", "Nelson", "Olivia", "Paulo", "Quiteria", "Rafael", "Sabrina", "Thiago",
         "Vanessa", "Wagner", "Yasmin", "Andre", "Beatriz", "Caio", "Denise", "Elias", "Fernanda", "Gustavo",
         "Helena", "Igor", "Juliana", "Leandro", "Marcia", "Otavio", "Patricia", "Renato", "Silvia", "Vitor"]
sobrenomes = ["Silva", "Santos", "Oliveira", "Souza", "Lima", "Pereira", "Costa", "Rodrigues", "Almeida", "Nascimento",
              "Carvalho", "Gomes", "Martins", "Araujo", "Ribeiro", "Barbosa", "Rocha", "Dias", "Teixeira", "Moreira"]
ruas = ["Rua das Acacias", "Rua Sao Jorge", "Av. Itaquera", "Rua Coronel Santos", "Rua do Comercio", "Rua Tuiuti",
        "Rua Padre Anchieta", "Av. Aricanduva", "Rua das Flores", "Rua Santa Marcelina", "Rua Melo Freire", "Rua Azurita"]
empresas = ["Pinturas", "Reformas", "Construtora", "Acabamentos", "Serralheria", "Manutencao Predial", "Decoracoes",
            "Instaladora", "Marcenaria", "Empreiteira"]
sufixo_emp = ["Ltda", "ME", "EIRELI", "& Filhos Ltda", "Servicos ME"]


def digitos(n):
    return "".join(str(rnd.randint(0, 9)) for _ in range(n))


docs_usados = set()


def doc_unico(n):
    while True:
        d = digitos(n)
        if d not in docs_usados and d.strip("0"):
            docs_usados.add(d)
            return d


def fone(movel=True):
    if movel:
        return f"(11) 9{rnd.randint(1000, 9999)}-{rnd.randint(1000, 9999)}"
    return f"(11) {rnd.randint(2000, 4999)}-{rnd.randint(1000, 9999)}"


def sem_acento(s):
    return s.lower().replace(" ", ".").replace("&", "e")


clientes = [("Consumidor final (venda de balcao sem cadastro)", "PF", "00000000000", None, None, None, "2026-01-02")]
docs_usados.add("00000000000")
for _ in range(95):
    n, s1, s2 = rnd.choice(nomes), rnd.choice(sobrenomes), rnd.choice(sobrenomes)
    nome = f"{n} {s1} {s2}"
    email = f"{sem_acento(n)}.{sem_acento(s2)}{rnd.randint(1, 99)}@email.com" if rnd.random() < 0.7 else None
    end = f"{rnd.choice(ruas)}, {rnd.randint(10, 1500)} - Sao Paulo/SP" if rnd.random() < 0.6 else None
    cad = INICIO - timedelta(days=rnd.randint(0, 900))
    clientes.append((nome, "PF", doc_unico(11), fone(True), email, end, cad.isoformat()))
for _ in range(25):
    s = rnd.choice(sobrenomes)
    nome = f"{rnd.choice(empresas)} {s} {rnd.choice(sufixo_emp)}"
    email = f"contato@{sem_acento(nome.split()[0])}{sem_acento(s)}.com.br"
    end = f"{rnd.choice(ruas)}, {rnd.randint(10, 1500)} - Sao Paulo/SP"
    cad = INICIO - timedelta(days=rnd.randint(0, 1200))
    clientes.append((nome, "PJ", doc_unico(14), fone(False), email, end, cad.isoformat()))
IDS_PF = list(range(2, 97))
IDS_PJ = list(range(97, 122))
# ~10 clientes cadastrados que nunca compraram no periodo (situacao real e testavel)
SEM_COMPRA = set(rnd.sample(IDS_PF, 8) + rnd.sample(IDS_PJ, 2))
PF_ATIVOS = [c for c in IDS_PF if c not in SEM_COMPRA]
PJ_ATIVOS = [c for c in IDS_PJ if c not in SEM_COMPRA]

# --------------------------------------------------------------------------
# 3) Vendas
# --------------------------------------------------------------------------
fator_mes = {1: 1.05, 2: 0.90, 3: 0.95, 4: 1.00, 5: 1.00, 6: 1.10}   # verao/fim de ferias pinta mais
vendas, itens, pagamentos = [], [], []
vendido = defaultdict(int)          # unidades efetivamente baixadas (vendas CONCLUIDAS)

d = INICIO
while d <= FIM:
    if d.weekday() == 6:            # domingo fechado
        d += timedelta(days=1)
        continue
    sabado = d.weekday() == 5
    media = (3.5 if sabado else 6.5) * fator_mes[d.month]
    qtd_vendas = max(0, int(round(rnd.gauss(media, 2.0))))
    for _ in range(qtd_vendas):
        h_ini, h_fim = (8, 13) if sabado else (8, 18)
        dh = datetime(d.year, d.month, d.day, rnd.randint(h_ini, h_fim - 1), rnd.choice(range(0, 60, 5)))
        r = rnd.random()
        if r < 0.50:
            cli, pj = 1, False
        elif r < 0.84:
            cli, pj = rnd.choice(PF_ATIVOS), False
        else:
            cli, pj = rnd.choice(PJ_ATIVOS), True
        # funcionario: Diego so vende ate o desligamento
        func_opts = [1, 2] + ([3] if d <= DESLIGAMENTO_DIEGO else [])
        func = rnd.choices(func_opts, weights=[45, 40, 30][:len(func_opts)])[0]
        # status: orcamentos ficam em aberto (mais comuns no fim do periodo); ~4% cancelada
        dias_fim = (FIM - d).days
        r = rnd.random()
        if r < (0.12 if dias_fim < 21 else 0.015):
            status = "ORCAMENTO"
        elif r < (0.12 if dias_fim < 21 else 0.015) + 0.04:
            status = "CANCELADA"
        else:
            status = "CONCLUIDA"
        n_itens = rnd.choices([1, 2, 3, 4, 5, 6], weights=[42, 30, 15, 8, 3, 2] if not pj else [10, 20, 25, 20, 15, 10])[0]
        escolhidos = set()
        while len(escolhidos) < n_itens:
            escolhidos.add(rnd.choices(range(len(produtos)), weights=PESOS)[0])
        id_venda = len(vendas) + 1
        total = 0.0
        for idx in sorted(escolhidos):
            p = produtos[idx]
            if p["preco"] > 150:
                q = rnd.choices([1, 2, 3], weights=[80, 15, 5])[0]
            elif pj:
                q = rnd.choices([1, 2, 3, 4, 6], weights=[30, 30, 20, 12, 8])[0]
            else:
                q = rnd.choices([1, 2, 3], weights=[75, 20, 5])[0]
            preco = preco_na_data(p, d)
            itens.append((id_venda, p["id"], q, preco))
            total += round(q * preco, 2)
            if status == "CONCLUIDA":
                vendido[p["id"]] += q
        total = round(total, 2)
        vendas.append((id_venda, cli, func, dh, status, total))
        # pagamentos: so venda concluida (orcamento nao paga; cancelada = desistencia antes do pagamento)
        if status == "CONCLUIDA":
            if pj:
                forma = rnd.choices(["BOLETO", "PIX", "CARTAO_CREDITO"], weights=[45, 35, 20])[0]
            else:
                forma = rnd.choices(["PIX", "CARTAO_DEBITO", "CARTAO_CREDITO", "DINHEIRO"], weights=[36, 27, 22, 15])[0]
            if not pj and total > 60 and rnd.random() < 0.08:       # pagamento dividido: dinheiro + PIX
                parte = round(rnd.choice([20, 30, 50, 100]) if total > 120 else total / 2, 2)
                parte = min(parte, round(total - 1, 2))
                pagamentos.append((id_venda, "DINHEIRO", parte, dh, 1))
                pagamentos.append((id_venda, "PIX", round(total - parte, 2), dh, 1))
            else:
                parcelas = 1
                if forma == "CARTAO_CREDITO" and total >= 150:
                    parcelas = rnd.choices([1, 2, 3, 4, 6], weights=[30, 30, 25, 10, 5])[0]
                dpag = dh if forma != "BOLETO" else dh + timedelta(days=rnd.choice([7, 14, 28]))
                pagamentos.append((id_venda, forma, total, dpag, parcelas))
    d += timedelta(days=1)

# --------------------------------------------------------------------------
# 4) Estoque: saldo final desejado + o que foi baixado = estoque inicial
# --------------------------------------------------------------------------
estoque = []
abaixo = set(rnd.sample(range(1, 68), 7))       # produtos que terminam no ponto de reposicao
for p in produtos:
    minimo = rnd.choice([3, 4, 5, 6, 8, 10, 12]) if p["preco"] < 150 else rnd.choice([2, 3])
    if p["id"] in abaixo:
        final = rnd.randint(0, minimo)
    else:
        final = minimo + rnd.randint(4, 40)
    inicial = final + vendido[p["id"]]
    prat = f"Deposito {'A' if p['cat'] in (1, 5) else 'B'} - Prateleira {rnd.randint(1, 20)}"
    estoque.append((p["id"], inicial, minimo, prat))

# produtos descontinuados (inativados ao fim do periodo; o historico permanece)
INATIVOS = [9, 34]

# --------------------------------------------------------------------------
# 5) Escrita do SQL
# --------------------------------------------------------------------------
def q(v):
    if v is None:
        return "NULL"
    if isinstance(v, str):
        return "'" + v.replace("'", "''") + "'"
    if isinstance(v, datetime):
        return f"'{v:%Y-%m-%d %H:%M:%S}'"
    if isinstance(v, float):
        return f"{v:.2f}"
    return str(v)


def bloco(tabela, colunas, linhas, tam=200):
    out = []
    for i in range(0, len(linhas), tam):
        parte = linhas[i:i + tam]
        out.append(f"INSERT INTO {tabela} ({', '.join(colunas)}) VALUES\n" +
                   ",\n".join("  (" + ", ".join(q(v) for v in l) + ")" for l in parte) + ";")
    return "\n".join(out)


conc = [v for v in vendas if v[4] == "CONCLUIDA"]
meses = defaultdict(lambda: [0, 0.0, 0])
for v in conc:
    meses[v[3].month][0] += 1
    meses[v[3].month][1] += v[5]
for (idv, idp, qt, pr) in itens:
    if vendas[idv - 1][4] == "CONCLUIDA":
        meses[vendas[idv - 1][3].month][2] += qt
resumo = "\n".join(f"--   {m:02d}/2026: {n:3d} vendas concluidas | R$ {f:9.2f} | {u:4d} unidades"
                   for m, (n, f, u) in sorted(meses.items()))

sql = f"""-- =====================================================================
-- Maximo das Tintas - 04 Massa de dados ficticia (INSERT)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- GERADO por scripts/gerar_massa.py (semente {SEMENTE}) - nao editar a mao.
-- =====================================================================
USE loja_tintas_materiais;

-- Como o volume foi calibrado (numeros informados pela loja):
--   ~500 unidades vendidas por mes e ~R$ 20 mil de faturamento por mes,
--   2 funcionarios, troca em ate 2 semanas, catalogo das listas do PDV.
-- Periodo simulado: {INICIO:%d/%m/%Y} a {FIM:%d/%m/%Y} (segunda a sabado; domingo fechado).
-- Resultado desta massa (vendas CONCLUIDAS):
{resumo}
-- Totais: {len(vendas)} vendas ({len(conc)} concluidas, {sum(v[4]=='CANCELADA' for v in vendas)} canceladas,
--         {sum(v[4]=='ORCAMENTO' for v in vendas)} orcamentos), {len(itens)} itens, {len(pagamentos)} pagamentos,
--         {len(clientes)} clientes ({len(SEM_COMPRA)} sem compras), {len(funcionarios)} funcionarios (1 desligado).
-- Dados pessoais 100% ficticios. Produtos, codigos, EAN e NCM: reais (listas do PDV).

-- ---------------------------------------------------------------------
-- Catalogo real da loja
-- ---------------------------------------------------------------------
-- Categorias
{chr(10).join(linhas_cat)}

-- Fornecedores (marcas reais; CNPJ, telefone e e-mail ficticios)
{chr(10).join(linhas_forn)}

-- Produtos (67 itens reais das listas de preco do PDV; preco = preco vigente apos o reajuste de abril)
{chr(10).join(linhas_prod)}

-- ---------------------------------------------------------------------
-- Pessoas (ficticias)
-- ---------------------------------------------------------------------
{bloco("funcionario", ["nome", "cargo", "cpf", "data_admissao", "ativo"], funcionarios)}

-- id 1 = "Consumidor final": venda de balcao sem cadastro (RN14)
{bloco("cliente", ["nome", "tipo_pessoa", "cpf_cnpj", "telefone", "email", "endereco", "data_cadastro"], clientes)}

-- ---------------------------------------------------------------------
-- Estoque inicial (01/01/2026). Os triggers baixam o estoque a cada item de
-- venda CONCLUIDA inserido abaixo; o saldo inicial foi calculado para que
-- nenhum produto fique negativo e {len(abaixo)} terminem no ponto de reposicao.
-- ---------------------------------------------------------------------
{bloco("estoque", ["id_produto", "quantidade_atual", "quantidade_minima", "localizacao_deposito"], estoque)}

-- ---------------------------------------------------------------------
-- Vendas, itens e pagamentos (jan a jun/2026)
-- Tintas vendidas antes de 01/04/2026 usam o preco anterior ao reajuste (RN04).
-- ---------------------------------------------------------------------
{bloco("venda", ["id_venda", "id_cliente", "id_funcionario", "data_venda", "status_venda", "valor_total"], vendas)}

{bloco("item_venda", ["id_venda", "id_produto", "quantidade", "preco_unitario_venda"], itens)}

{bloco("pagamento", ["id_venda", "forma_pagamento", "valor_pago", "data_pagamento", "parcelas"], pagamentos)}

-- Produtos descontinuados no fim do periodo: saem de linha, o historico permanece (RN17)
UPDATE produto SET ativo = 0 WHERE id_produto IN ({", ".join(map(str, INATIVOS))});
"""
ARQ.write_text(sql, encoding="utf-8")
print(f"OK: {ARQ.relative_to(RAIZ)}")
print(resumo)
print(f"{len(vendas)} vendas, {len(itens)} itens, {len(pagamentos)} pagamentos, {len(clientes)} clientes")
