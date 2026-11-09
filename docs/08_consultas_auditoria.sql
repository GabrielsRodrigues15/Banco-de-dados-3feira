-- =====================================================================
-- Maximo das Tintas - 08 Consultas de auditoria (A01 a A10)
-- Parte do script unico docs/script.sql (gerado por docs/build_script.sh)
-- Cada consulta verifica uma regra de negocio (RNxx). Resultado esperado:
-- NENHUMA linha (0 violacoes). Se aparecer linha, ha inconsistencia a corrigir.
-- =====================================================================
USE loja_tintas_materiais;

-- A01 — Existe venda cujo total nao bate com a soma dos itens?
-- Verifica: RN05 (total da venda = soma dos subtotais)
SELECT v.id_venda, v.status_venda,
       v.valor_total AS valor_total_registrado,
       COALESCE(SUM(iv.subtotal), 0) AS valor_total_calculado
FROM venda v
LEFT JOIN item_venda iv ON iv.id_venda = v.id_venda
GROUP BY v.id_venda, v.status_venda, v.valor_total
HAVING v.valor_total <> COALESCE(SUM(iv.subtotal), 0);

-- A02 — Existe venda concluida sem nenhum pagamento?
-- Verifica: RN09 (venda concluida e paga)
SELECT v.id_venda, v.data_venda, v.valor_total
FROM venda v
LEFT JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA' AND pg.id_pagamento IS NULL;

-- A03 — Existe venda concluida cuja soma dos pagamentos difere do total?
-- Verifica: RN09 (pagamento integral, em uma ou mais formas)
SELECT v.id_venda, v.valor_total, SUM(pg.valor_pago) AS total_pago
FROM venda v
JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA'
GROUP BY v.id_venda, v.valor_total
HAVING SUM(pg.valor_pago) <> v.valor_total;

-- A04 — Existe orcamento com pagamento registrado?
-- Verifica: RN10 (orcamento nao gera pagamento)
SELECT v.id_venda, v.data_venda, pg.id_pagamento, pg.valor_pago
FROM venda v
JOIN pagamento pg ON pg.id_venda = v.id_venda
WHERE v.status_venda = 'ORCAMENTO';

-- A05 — Existe produto sem registro de estoque?
-- Verifica: RN13 (todo produto tem exatamente um registro de estoque)
SELECT p.id_produto, p.descricao
FROM produto p
LEFT JOIN estoque e ON e.id_produto = p.id_produto
WHERE e.id_estoque IS NULL;

-- A06 — Existe estoque negativo?
-- Verifica: RN07 (a CHECK ja impede; a consulta audita ambientes sem CHECK)
SELECT e.id_produto, e.quantidade_atual
FROM estoque e
WHERE e.quantidade_atual < 0;

-- A07 — Existe venda concluida sem nenhum item?
-- Verifica: RN02 (toda venda concluida tem ao menos um item)
SELECT v.id_venda, v.data_venda, v.valor_total
FROM venda v
LEFT JOIN item_venda iv ON iv.id_venda = v.id_venda
WHERE v.status_venda = 'CONCLUIDA' AND iv.id_item_venda IS NULL;

-- A08 — Existe CPF/CNPJ duplicado ou fora do formato (PF = 11 digitos, PJ = 14)?
-- Verifica: RN11
SELECT c.id_cliente, c.nome, c.tipo_pessoa, c.cpf_cnpj, 'formato invalido' AS problema
FROM cliente c
WHERE NOT ((c.tipo_pessoa = 'PF' AND c.cpf_cnpj REGEXP '^[0-9]{11}$')
        OR (c.tipo_pessoa = 'PJ' AND c.cpf_cnpj REGEXP '^[0-9]{14}$'))
UNION ALL
SELECT NULL, NULL, NULL, c.cpf_cnpj, CONCAT('duplicado ', COUNT(*), 'x')
FROM cliente c
GROUP BY c.cpf_cnpj
HAVING COUNT(*) > 1;

-- A09 — Existe pagamento parcelado fora do cartao de credito?
-- Verifica: RN09 (parcelamento so no cartao de credito)
SELECT pg.id_pagamento, pg.id_venda, pg.forma_pagamento, pg.parcelas
FROM pagamento pg
WHERE pg.parcelas > 1 AND pg.forma_pagamento <> 'CARTAO_CREDITO';

-- A10 — Existe pagamento registrado antes da data da venda?
-- Verifica: RN09 (o pagamento acontece na venda ou depois, ex.: boleto)
SELECT pg.id_pagamento, pg.id_venda, v.data_venda, pg.data_pagamento
FROM pagamento pg
JOIN venda v ON v.id_venda = pg.id_venda
WHERE pg.data_pagamento < v.data_venda;
