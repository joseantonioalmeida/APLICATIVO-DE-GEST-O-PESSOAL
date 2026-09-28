-- =====================================================================
--  MinhaVida — Carga de dados de demonstração
--  Reproduz fielmente os dados exibidos nas 8 telas do protótipo.
--  Uso: psql -d minhavida -f seed.sql
-- =====================================================================
BEGIN;

-- ---------------------------------------------------------------------
-- 1. Usuário do protótipo: Júlio César
-- ---------------------------------------------------------------------
INSERT INTO usuario (id, nome_completo, nome_usuario, email, senha_hash, telefone,
                     data_nascimento, status, email_verificado, aceite_termos,
                     versao_termos_aceita, data_aceite_termos, data_cadastro)
VALUES ('11111111-1111-4111-8111-111111111111',
        'Júlio César', 'juliocesar', 'julio@email.com',
        '$2b$12$abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQR',
        '(83) 99999-0000', '2001-05-14', 'ATIVO', TRUE, TRUE,
        '1.0', '2025-08-01 10:00-03', '2025-08-01 10:00-03');

INSERT INTO preferencia_usuario (usuario_id, tema, idioma, moeda)
VALUES ('11111111-1111-4111-8111-111111111111', 'ESCURO', 'pt-BR', 'BRL');

-- ---------------------------------------------------------------------
-- 2. Categorias — escopo ATIVIDADE (filtros da tela Atividades)
-- ---------------------------------------------------------------------
INSERT INTO categoria (id, usuario_id, categoria_pai_id, nome, escopo, cor_hex, icone, padrao_sistema, ordem_exibicao) VALUES
 ('a0000000-0000-4000-8000-000000000001', NULL, NULL, 'Trabalho', 'ATIVIDADE', '#8B5CF6', 'briefcase', TRUE, 1),
 ('a0000000-0000-4000-8000-000000000002', NULL, NULL, 'Estudo',   'ATIVIDADE', '#10B981', 'laptop',    TRUE, 2),
 ('a0000000-0000-4000-8000-000000000003', NULL, NULL, 'Pessoal',  'ATIVIDADE', '#3B82F6', 'user',      TRUE, 3),
 ('a0000000-0000-4000-8000-000000000004', NULL, NULL, 'Lazer',    'ATIVIDADE', '#A855F7', 'gamepad',   TRUE, 4);

-- Subcategorias observadas no protótipo ("Estudo • Faculdade", "Pessoal • Saúde"…)
INSERT INTO categoria (id, usuario_id, categoria_pai_id, nome, escopo, cor_hex, icone, padrao_sistema, ordem_exibicao) VALUES
 ('a0000000-0000-4000-8000-000000000011', NULL, 'a0000000-0000-4000-8000-000000000002', 'Faculdade',   'ATIVIDADE', '#10B981', 'laptop',   TRUE, 1),
 ('a0000000-0000-4000-8000-000000000012', NULL, 'a0000000-0000-4000-8000-000000000003', 'Saúde',       'ATIVIDADE', '#EF4444', 'dumbbell', TRUE, 2),
 ('a0000000-0000-4000-8000-000000000013', NULL, 'a0000000-0000-4000-8000-000000000001', 'Programação', 'ATIVIDADE', '#8B5CF6', 'code',     TRUE, 3),
 ('a0000000-0000-4000-8000-000000000014', NULL, 'a0000000-0000-4000-8000-000000000003', 'Alimentação', 'ATIVIDADE', '#F59E0B', 'utensils', TRUE, 4),
 ('a0000000-0000-4000-8000-000000000015', NULL, 'a0000000-0000-4000-8000-000000000003', 'Casa',        'ATIVIDADE', '#22C55E', 'file',     TRUE, 5),
 ('a0000000-0000-4000-8000-000000000016', NULL, 'a0000000-0000-4000-8000-000000000003', 'Mercado',     'ATIVIDADE', '#EC4899', 'cart',     TRUE, 6),
 ('a0000000-0000-4000-8000-000000000017', NULL, 'a0000000-0000-4000-8000-000000000004', 'Games',       'ATIVIDADE', '#A855F7', 'gamepad',  TRUE, 7),
 ('a0000000-0000-4000-8000-000000000018', NULL, 'a0000000-0000-4000-8000-000000000004', 'Leitura',     'ATIVIDADE', '#3B82F6', 'book',     TRUE, 8);

-- ---------------------------------------------------------------------
-- 3. Categorias — escopo FINANCEIRO (tela Financeiro)
-- ---------------------------------------------------------------------
INSERT INTO categoria (id, usuario_id, categoria_pai_id, nome, escopo, tipo_movimento, cor_hex, icone, padrao_sistema, ordem_exibicao) VALUES
 ('f0000000-0000-4000-8000-000000000001', NULL, NULL, 'Alimentação', 'FINANCEIRO', 'DESPESA', '#F59E0B', 'utensils', TRUE, 1),
 ('f0000000-0000-4000-8000-000000000002', NULL, NULL, 'Transporte',  'FINANCEIRO', 'DESPESA', '#3B82F6', 'car',      TRUE, 2),
 ('f0000000-0000-4000-8000-000000000003', NULL, NULL, 'Moradia',     'FINANCEIRO', 'DESPESA', '#8B5CF6', 'home',     TRUE, 3),
 ('f0000000-0000-4000-8000-000000000004', NULL, NULL, 'Compras',     'FINANCEIRO', 'DESPESA', '#EC4899', 'bag',      TRUE, 4),
 ('f0000000-0000-4000-8000-000000000005', NULL, NULL, 'Outros',      'FINANCEIRO', 'DESPESA', '#6B7280', 'plus',     TRUE, 5),
 ('f0000000-0000-4000-8000-000000000006', NULL, NULL, 'Salário',     'FINANCEIRO', 'RECEITA', '#22C55E', 'download', TRUE, 6),
 ('f0000000-0000-4000-8000-000000000007', NULL, NULL, 'Saúde',       'FINANCEIRO', 'DESPESA', '#EF4444', 'heart',    TRUE, 7);

-- ---------------------------------------------------------------------
-- 4. Categorias — escopo IMPORTANCIA (etiquetas da tela Importâncias)
-- ---------------------------------------------------------------------
INSERT INTO categoria (id, usuario_id, categoria_pai_id, nome, escopo, cor_hex, icone, padrao_sistema, ordem_exibicao) VALUES
 ('c0000000-0000-4000-8000-000000000001', NULL, NULL, 'Contas',  'IMPORTANCIA', '#EF4444', 'calendar', TRUE, 1),
 ('c0000000-0000-4000-8000-000000000002', NULL, NULL, 'Compras', 'IMPORTANCIA', '#22C55E', 'bag',      TRUE, 2),
 ('c0000000-0000-4000-8000-000000000003', NULL, NULL, 'Veículo', 'IMPORTANCIA', '#3B82F6', 'car',      TRUE, 3),
 ('c0000000-0000-4000-8000-000000000004', NULL, NULL, 'Lazer',   'IMPORTANCIA', '#A855F7', 'card',     TRUE, 4),
 ('c0000000-0000-4000-8000-000000000005', NULL, NULL, 'Saúde',   'IMPORTANCIA', '#8B5CF6', 'heart',    TRUE, 5);

-- ---------------------------------------------------------------------
-- 5. Conta financeira
-- ---------------------------------------------------------------------
INSERT INTO conta_financeira (id, usuario_id, nome, tipo, saldo_inicial, saldo_atual)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        '11111111-1111-4111-8111-111111111111', 'Carteira', 'CARTEIRA', 0, 0);

-- ---------------------------------------------------------------------
-- 6. Atividades de 29/09/2025 (tela Atividades: 12 no total, 10 concluídas)
-- ---------------------------------------------------------------------
INSERT INTO atividade (usuario_id, categoria_id, subcategoria_id, titulo, data_atividade,
                       hora_inicio, hora_fim, prioridade, status, concluida_em) VALUES
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000011','Estudar para a prova','2025-09-29','08:00','10:00','ALTA','CONCLUIDA','2025-09-29 10:05-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000012','Treino na academia', '2025-09-29','17:00','18:30','MEDIA','CONCLUIDA','2025-09-29 18:35-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000013','Trabalho (projeto)', '2025-09-29','13:00','16:00','ALTA','CONCLUIDA','2025-09-29 16:10-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000014','Almoço',             '2025-09-29','12:00','13:00','BAIXA','CONCLUIDA','2025-09-29 13:00-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000018','Ler um livro',       '2025-09-29','20:00','21:30','BAIXA','CONCLUIDA','2025-09-29 21:30-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000004','a0000000-0000-4000-8000-000000000017','Jogar um pouco',     '2025-09-29','22:00','23:30','BAIXA','PENDENTE',  NULL),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000015','Organizar o quarto', '2025-09-29','15:00','16:30','BAIXA','PENDENTE',  NULL),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000016','Fazer compras',      '2025-09-29','11:00','12:00','MEDIA','CONCLUIDA','2025-09-29 12:00-03'),
 -- Itens não listados na tela (ela mostra 8 de 12), necessários para fechar
 -- os indicadores "Total 12 · Concluídas 10 · Tempo total 18h45min".
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000003','a0000000-0000-4000-8000-000000000012','Corrida matinal e café','2025-09-29','05:45','08:00','MEDIA','CONCLUIDA','2025-09-29 08:00-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000011','Revisar anotações',     '2025-09-29','10:00','11:00','MEDIA','CONCLUIDA','2025-09-29 11:00-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000001','a0000000-0000-4000-8000-000000000013','Reunião do projeto',    '2025-09-29','16:00','17:00','ALTA', 'CONCLUIDA','2025-09-29 17:00-03'),
 ('11111111-1111-4111-8111-111111111111','a0000000-0000-4000-8000-000000000002','a0000000-0000-4000-8000-000000000011','Curso de inglês',       '2025-09-29','18:30','20:00','MEDIA','CONCLUIDA','2025-09-29 20:00-03');

-- ---------------------------------------------------------------------
-- 7. Movimentações financeiras (tela Financeiro: "Últimas movimentações")
--    O saldo da conta é atualizado automaticamente pelo gatilho.
-- ---------------------------------------------------------------------
INSERT INTO transacao (usuario_id, conta_id, categoria_id, descricao, tipo, valor,
                       data_movimento, data_competencia, forma_pagamento, situacao) VALUES
 -- Movimentações exibidas na tela Financeiro
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000006','Salário',    'RECEITA',2450.75,'2025-09-29','2025-09-29','TRANSFERENCIA','EFETIVADA'),
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000004','Mercado',    'DESPESA', 245.30,'2025-09-28','2025-09-28','DEBITO',       'EFETIVADA'),
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000001','Restaurante','DESPESA',  89.90,'2025-09-27','2025-09-27','PIX',          'EFETIVADA'),
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000002','Uber',       'DESPESA',  32.50,'2025-09-26','2025-09-26','CREDITO',      'EFETIVADA'),
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000007','Academia',   'DESPESA',  89.90,'2025-09-26','2025-09-26','PIX',          'EFETIVADA'),
 -- Lançamentos não listados na tela (ela mostra só as 4 últimas), necessários
 -- para fechar o total de despesas do mês em R$ 1.230,40 e o saldo em R$ 1.220,35.
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000003','Aluguel',     'DESPESA',600.00,'2025-09-05','2025-09-05','PIX',    'EFETIVADA'),
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000002','Combustível', 'DESPESA',100.00,'2025-09-18','2025-09-18','DEBITO', 'EFETIVADA'),
 ('11111111-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','f0000000-0000-4000-8000-000000000005','Farmácia',    'DESPESA', 72.80,'2025-09-22','2025-09-22','PIX',    'EFETIVADA');

-- ---------------------------------------------------------------------
-- 8. Importâncias (tela Importâncias)
-- ---------------------------------------------------------------------
-- Vencendo hoje
INSERT INTO importancia (usuario_id, categoria_id, titulo, origem, data_vencimento, valor, tipo, status, prioridade) VALUES
 ('11111111-1111-4111-8111-111111111111','c0000000-0000-4000-8000-000000000001','Pagamento da internet','Vivo Fibra','2025-09-29', 99.90,'CONTA_A_PAGAR','VENCENDO_HOJE','ALTA');
-- Próximos (outubro)
INSERT INTO importancia (usuario_id, categoria_id, titulo, origem, data_vencimento, valor, tipo, status, prioridade) VALUES
 ('11111111-1111-4111-8111-111111111111','c0000000-0000-4000-8000-000000000002','Compra do mês',           'Mercado','2025-10-05',245.30,'CONTA_A_PAGAR','PENDENTE','MEDIA'),
 ('11111111-1111-4111-8111-111111111111','c0000000-0000-4000-8000-000000000003','Licenciamento do veículo','Detran', '2025-10-15',120.00,'CONTA_A_PAGAR','PENDENTE','ALTA'),
 ('11111111-1111-4111-8111-111111111111','c0000000-0000-4000-8000-000000000004','Assinatura do streaming', 'Netflix','2025-10-20', 39.90,'CONTA_A_PAGAR','PENDENTE','BAIXA');
-- Concluídos (setembro)
INSERT INTO importancia (usuario_id, categoria_id, titulo, origem, data_vencimento, valor, tipo, status, prioridade, concluida_em) VALUES
 ('11111111-1111-4111-8111-111111111111','c0000000-0000-4000-8000-000000000001','Conta de luz','Energisa', '2025-09-10',152.34,'CONTA_A_PAGAR','CONCLUIDA','ALTA', '2025-09-10 09:00-03'),
 ('11111111-1111-4111-8111-111111111111','c0000000-0000-4000-8000-000000000005','Academia',    'Smart Fit','2025-09-12', 89.90,'CONTA_A_PAGAR','CONCLUIDA','MEDIA','2025-09-12 08:30-03');

-- ---------------------------------------------------------------------
-- 9. Orçamento de exemplo
-- ---------------------------------------------------------------------
INSERT INTO orcamento (usuario_id, categoria_id, mes_referencia, valor_limite, percentual_alerta) VALUES
 ('11111111-1111-4111-8111-111111111111','f0000000-0000-4000-8000-000000000001','2025-09', 500.00, 80),
 ('11111111-1111-4111-8111-111111111111','f0000000-0000-4000-8000-000000000002','2025-09', 400.00, 80);

COMMIT;
