-- =====================================================================
-- PROJETO: Maximo das Tintas - Sistema de Gestao (loja de tintas e materiais de construcao)
-- Testado em MySQL 8.0.46 a partir de banco vazio, sem erros (requer MySQL 8.0.16+)
--
-- SUMARIO DO SCRIPT (ordem exigida pelo enunciado da Entrega 2):
--   1)   CREATE DATABASE
--   1.1) CREATE TABLE (9 tabelas, com tipos de dados adequados)
--        Constraints (PK, FK, NOT NULL, UNIQUE, CHECK) ja embutidas em cada CREATE TABLE
--   1.5) TRIGGERS de automacao de estoque (baixa/devolucao automatica)
--   1.6) VIEWS para consultas com JOIN e relatorios gerenciais
--   2)   INSERT INTO (massa de dados ficticia e coerente)
--   3)   SELECT com JOIN (via views)
--   4)   UPDATE
--   5)   DELETE
--   6)   Consultas gerenciais (via views)
--   7)   Consultas de auditoria
--
-- Baixa/devolucao de estoque nao e mais manual: acontece via TRIGGERS (Secao
-- 1.5), cobrindo 4 cenarios sem nenhum UPDATE direto em "estoque":
--   a) venda criada ja concluida + itens inseridos      -> baixa na hora
--   b) orcamento convertido depois em venda concluida   -> baixa de uma vez
--   c) venda concluida cancelada                        -> devolve o estoque
--   d) venda concluida apagada com DELETE FROM venda    -> devolve o estoque
--      ANTES do ON DELETE CASCADE remover os itens (ver comentario na Secao 1.5)
--
-- Como executar:
--   mysql -u seu_usuario -p --default-character-set=utf8mb4 < docs/script.sql
-- =====================================================================

-- =====================================================================
-- BANCO DE DADOS: loja_tintas_materiais
-- Sistema de gestao para loja de tintas e materiais de construcao
-- =====================================================================

DROP DATABASE IF EXISTS loja_tintas_materiais;
CREATE DATABASE loja_tintas_materiais CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE loja_tintas_materiais;

