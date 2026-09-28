-- =====================================================================
--  MinhaVida — Esquema do banco de dados
--  SGBD......: PostgreSQL 16+
--  Autor.....: José Antonio de Almeida Silva
--  Versão....: 1.0.0
--  Codificação: UTF-8
-- =====================================================================
--  Convenções adotadas
--   · Nomes de tabela no singular e em snake_case
--   · Chave primária UUID v4 (ADR-06)
--   · Timestamps com fuso horário (timestamptz)
--   · Valores monetários em NUMERIC(15,2) — nunca FLOAT
--   · Exclusão lógica por excluido_em + índice parcial (ADR-07)
--   · Toda tabela de negócio é particionável por usuario_id no futuro
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- e-mail sem distinção de caixa
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- busca textual por similaridade

-- =====================================================================
--  1. TIPOS ENUMERADOS
-- =====================================================================
CREATE TYPE status_usuario       AS ENUM ('ATIVO','INATIVO','BLOQUEADO','PENDENTE_VERIFICACAO');
CREATE TYPE tema_app             AS ENUM ('CLARO','ESCURO','SISTEMA');
CREATE TYPE provedor_oauth       AS ENUM ('GOOGLE','APPLE');
CREATE TYPE plataforma           AS ENUM ('ANDROID','IOS','WEB');
CREATE TYPE escopo_categoria     AS ENUM ('ATIVIDADE','FINANCEIRO','IMPORTANCIA');
CREATE TYPE tipo_movimento       AS ENUM ('RECEITA','DESPESA','TRANSFERENCIA');
CREATE TYPE situacao_transacao   AS ENUM ('PENDENTE','EFETIVADA','CANCELADA');
CREATE TYPE forma_pagamento      AS ENUM ('DINHEIRO','PIX','DEBITO','CREDITO','BOLETO','TRANSFERENCIA');
CREATE TYPE tipo_conta           AS ENUM ('CARTEIRA','CORRENTE','POUPANCA','CARTAO_CREDITO','INVESTIMENTO');
CREATE TYPE prioridade           AS ENUM ('BAIXA','MEDIA','ALTA','URGENTE');
CREATE TYPE status_atividade     AS ENUM ('PENDENTE','EM_ANDAMENTO','CONCLUIDA','ATRASADA','CANCELADA');
CREATE TYPE status_importancia   AS ENUM ('PENDENTE','VENCENDO_HOJE','ATRASADA','CONCLUIDA','CANCELADA');
CREATE TYPE tipo_importancia     AS ENUM ('CONTA_A_PAGAR','CONTA_A_RECEBER','COMPROMISSO','DATA_COMEMORATIVA');
CREATE TYPE frequencia           AS ENUM ('DIARIA','SEMANAL','QUINZENAL','MENSAL','ANUAL','PERSONALIZADA');
CREATE TYPE tipo_notificacao     AS ENUM ('LEMBRETE_ATIVIDADE','VENCIMENTO_IMPORTANCIA','RESUMO_DIARIO','ALERTA_ORCAMENTO','SISTEMA');
CREATE TYPE canal_notificacao    AS ENUM ('PUSH','EMAIL','IN_APP');
CREATE TYPE status_notificacao   AS ENUM ('AGENDADA','ENVIADA','LIDA','FALHA','CANCELADA');

-- =====================================================================
--  2. IDENTIDADE E ACESSO
-- =====================================================================
CREATE TABLE usuario (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_completo           VARCHAR(120)    NOT NULL,
    nome_usuario            VARCHAR(40)     NOT NULL,
    email                   CITEXT          NOT NULL,
    senha_hash              VARCHAR(255),
    telefone                VARCHAR(20),
    data_nascimento         DATE            NOT NULL,
    url_foto_perfil         VARCHAR(500),
    status                  status_usuario  NOT NULL DEFAULT 'PENDENTE_VERIFICACAO',
    email_verificado        BOOLEAN         NOT NULL DEFAULT FALSE,
    aceite_termos           BOOLEAN         NOT NULL DEFAULT FALSE,
    versao_termos_aceita    VARCHAR(20),
    data_aceite_termos      TIMESTAMPTZ,
    data_cadastro           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    ultimo_acesso           TIMESTAMPTZ,
    criado_em               TIMESTAMPTZ     NOT NULL DEFAULT now(),
    atualizado_em           TIMESTAMPTZ     NOT NULL DEFAULT now(),
    excluido_em             TIMESTAMPTZ,
    CONSTRAINT uk_usuario_email        UNIQUE (email),
    CONSTRAINT uk_usuario_nome_usuario UNIQUE (nome_usuario),
    CONSTRAINT ck_usuario_nome_len     CHECK (char_length(nome_completo) >= 3),
    CONSTRAINT ck_usuario_idade_minima CHECK (data_nascimento <= CURRENT_DATE - INTERVAL '13 years'),
    CONSTRAINT ck_usuario_termos       CHECK (aceite_termos = TRUE),
    CONSTRAINT ck_usuario_autenticacao CHECK (senha_hash IS NOT NULL OR status = 'ATIVO')
);
COMMENT ON TABLE  usuario                IS 'Titular da conta. Raiz do agregado de identidade.';
COMMENT ON COLUMN usuario.nome_usuario   IS 'Permite o login por nome de usuário além do e-mail (tela de Login).';
COMMENT ON COLUMN usuario.senha_hash     IS 'bcrypt custo 12. Nulo quando a conta é exclusivamente social.';
COMMENT ON COLUMN usuario.data_cadastro  IS 'Exibido no Perfil como "Usuário desde".';

CREATE INDEX ix_usuario_ativo ON usuario (status) WHERE excluido_em IS NULL;

CREATE TABLE preferencia_usuario (
    id                              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id                      UUID        NOT NULL,
    tema                            tema_app    NOT NULL DEFAULT 'ESCURO',
    idioma                          VARCHAR(10) NOT NULL DEFAULT 'pt-BR',
    moeda                           CHAR(3)     NOT NULL DEFAULT 'BRL',
    fuso_horario                    VARCHAR(50) NOT NULL DEFAULT 'America/Sao_Paulo',
    notificacao_push                BOOLEAN     NOT NULL DEFAULT TRUE,
    notificacao_email               BOOLEAN     NOT NULL DEFAULT TRUE,
    notificar_atividades            BOOLEAN     NOT NULL DEFAULT TRUE,
    notificar_importancias          BOOLEAN     NOT NULL DEFAULT TRUE,
    antecedencia_lembrete_min       SMALLINT    NOT NULL DEFAULT 30,
    dias_antecedencia_importancia   SMALLINT    NOT NULL DEFAULT 3,
    resumo_diario_ativo             BOOLEAN     NOT NULL DEFAULT FALSE,
    hora_resumo_diario              TIME        NOT NULL DEFAULT '07:00',
    criado_em                       TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_pref_usuario  FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT uk_pref_usuario  UNIQUE (usuario_id),
    CONSTRAINT ck_pref_antecedencia CHECK (antecedencia_lembrete_min BETWEEN 0 AND 1440),
    CONSTRAINT ck_pref_dias_antec   CHECK (dias_antecedencia_importancia BETWEEN 0 AND 30)
);

CREATE TABLE credencial_social (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID            NOT NULL,
    provedor        provedor_oauth  NOT NULL,
    id_provedor     VARCHAR(255)    NOT NULL,
    email_provedor  VARCHAR(255),
    vinculado_em    TIMESTAMPTZ     NOT NULL DEFAULT now(),
    CONSTRAINT fk_credsocial_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT uk_credsocial_provedor UNIQUE (provedor, id_provedor)
);
CREATE INDEX ix_credsocial_usuario ON credencial_social (usuario_id);

CREATE TABLE sessao (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id              UUID            NOT NULL,
    refresh_token_hash      VARCHAR(255)    NOT NULL,
    dispositivo             VARCHAR(120),
    sistema_operacional     VARCHAR(50),
    app_versao              VARCHAR(20),
    endereco_ip             VARCHAR(45),
    user_agent              VARCHAR(255),
    lembrar_de_mim          BOOLEAN         NOT NULL DEFAULT FALSE,
    criada_em               TIMESTAMPTZ     NOT NULL DEFAULT now(),
    expira_em               TIMESTAMPTZ     NOT NULL,
    revogada_em             TIMESTAMPTZ,
    ultima_atividade_em     TIMESTAMPTZ     NOT NULL DEFAULT now(),
    CONSTRAINT fk_sessao_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT uk_sessao_token   UNIQUE (refresh_token_hash),
    CONSTRAINT ck_sessao_validade CHECK (expira_em > criada_em)
);
CREATE INDEX ix_sessao_ativa ON sessao (usuario_id, expira_em) WHERE revogada_em IS NULL;

CREATE TABLE token_recuperacao_senha (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id   UUID         NOT NULL,
    token_hash   VARCHAR(255) NOT NULL,
    criado_em    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expira_em    TIMESTAMPTZ  NOT NULL DEFAULT now() + INTERVAL '30 minutes',
    usado_em     TIMESTAMPTZ,
    endereco_ip  VARCHAR(45),
    CONSTRAINT fk_tokenrec_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT uk_tokenrec_hash    UNIQUE (token_hash)
);
CREATE INDEX ix_tokenrec_valido ON token_recuperacao_senha (usuario_id) WHERE usado_em IS NULL;

CREATE TABLE dispositivo_usuario (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id    UUID         NOT NULL,
    token_push    VARCHAR(255) NOT NULL,
    plataforma    plataforma   NOT NULL,
    modelo        VARCHAR(120),
    versao_app    VARCHAR(20),
    ativo         BOOLEAN      NOT NULL DEFAULT TRUE,
    registrado_em TIMESTAMPTZ  NOT NULL DEFAULT now(),
    ultimo_uso_em TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_dispositivo_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT uk_dispositivo_token   UNIQUE (token_push)
);
CREATE INDEX ix_dispositivo_ativo ON dispositivo_usuario (usuario_id) WHERE ativo = TRUE;

-- =====================================================================
--  3. CLASSIFICAÇÃO — CATEGORIA (Composite: escopo + auto-relacionamento)
-- =====================================================================
CREATE TABLE categoria (
    id                UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id        UUID,
    categoria_pai_id  UUID,
    nome              VARCHAR(60)       NOT NULL,
    escopo            escopo_categoria  NOT NULL,
    tipo_movimento    tipo_movimento,
    cor_hex           CHAR(7)           NOT NULL DEFAULT '#6366F1',
    icone             VARCHAR(50)       NOT NULL DEFAULT 'tag',
    padrao_sistema    BOOLEAN           NOT NULL DEFAULT FALSE,
    ativa             BOOLEAN           NOT NULL DEFAULT TRUE,
    ordem_exibicao    SMALLINT          NOT NULL DEFAULT 0,
    criado_em         TIMESTAMPTZ       NOT NULL DEFAULT now(),
    atualizado_em     TIMESTAMPTZ       NOT NULL DEFAULT now(),
    CONSTRAINT fk_categoria_usuario FOREIGN KEY (usuario_id)       REFERENCES usuario(id)   ON DELETE CASCADE,
    CONSTRAINT fk_categoria_pai     FOREIGN KEY (categoria_pai_id) REFERENCES categoria(id) ON DELETE SET NULL,
    CONSTRAINT ck_categoria_cor     CHECK (cor_hex ~ '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT ck_categoria_mov     CHECK (escopo = 'FINANCEIRO' OR tipo_movimento IS NULL),
    CONSTRAINT ck_categoria_nao_pai_de_si CHECK (id <> categoria_pai_id)
);
COMMENT ON TABLE  categoria                  IS 'Categoria unificada (padrão Composite). O escopo separa os três universos.';
COMMENT ON COLUMN categoria.usuario_id       IS 'Nulo = categoria padrão do sistema, visível a todos os usuários.';
COMMENT ON COLUMN categoria.categoria_pai_id IS 'Auto-relacionamento: subcategoria. Ex.: Estudo > Faculdade.';

CREATE UNIQUE INDEX uk_categoria_nome_usuario
    ON categoria (usuario_id, escopo, nome) WHERE usuario_id IS NOT NULL;
CREATE UNIQUE INDEX uk_categoria_nome_sistema
    ON categoria (escopo, nome) WHERE usuario_id IS NULL;
CREATE INDEX ix_categoria_escopo ON categoria (escopo, ativa);
CREATE INDEX ix_categoria_pai    ON categoria (categoria_pai_id) WHERE categoria_pai_id IS NOT NULL;

-- =====================================================================
--  4. RECORRÊNCIA (compartilhada por atividade, importância e transação)
-- =====================================================================
CREATE TABLE regra_recorrencia (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id           UUID        NOT NULL,
    frequencia           frequencia  NOT NULL,
    intervalo            SMALLINT    NOT NULL DEFAULT 1,
    dias_semana          SMALLINT[],
    dia_do_mes           SMALLINT,
    data_inicio          DATE        NOT NULL,
    data_fim             DATE,
    ocorrencias_max      SMALLINT,
    ocorrencias_geradas  SMALLINT    NOT NULL DEFAULT 0,
    proxima_ocorrencia   DATE,
    ativa                BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_recorrencia_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT ck_recorrencia_intervalo CHECK (intervalo BETWEEN 1 AND 365),
    CONSTRAINT ck_recorrencia_dia_mes   CHECK (dia_do_mes IS NULL OR dia_do_mes BETWEEN 1 AND 31),
    CONSTRAINT ck_recorrencia_periodo   CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);
CREATE INDEX ix_recorrencia_proxima ON regra_recorrencia (proxima_ocorrencia) WHERE ativa = TRUE;

-- =====================================================================
--  5. ATIVIDADES (CRUD da lista de tarefas)
-- =====================================================================
CREATE TABLE atividade (
    id                      UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id              UUID              NOT NULL,
    categoria_id            UUID,
    subcategoria_id         UUID,
    titulo                  VARCHAR(120)      NOT NULL,
    descricao               VARCHAR(200),
    data_atividade          DATE              NOT NULL,
    hora_inicio             TIME,
    hora_fim                TIME,
    duracao_minutos         INTEGER,
    prioridade              prioridade        NOT NULL DEFAULT 'BAIXA',
    status                  status_atividade  NOT NULL DEFAULT 'PENDENTE',
    concluida_em            TIMESTAMPTZ,
    lembrete_ativo          BOOLEAN           NOT NULL DEFAULT TRUE,
    minutos_antes_lembrete  SMALLINT,
    regra_recorrencia_id    UUID,
    atividade_origem_id     UUID,
    ordem                   INTEGER           NOT NULL DEFAULT 0,
    criado_em               TIMESTAMPTZ       NOT NULL DEFAULT now(),
    atualizado_em           TIMESTAMPTZ       NOT NULL DEFAULT now(),
    excluido_em             TIMESTAMPTZ,
    CONSTRAINT fk_atividade_usuario     FOREIGN KEY (usuario_id)           REFERENCES usuario(id)           ON DELETE CASCADE,
    CONSTRAINT fk_atividade_categoria   FOREIGN KEY (categoria_id)         REFERENCES categoria(id)         ON DELETE SET NULL,
    CONSTRAINT fk_atividade_subcat      FOREIGN KEY (subcategoria_id)      REFERENCES categoria(id)         ON DELETE SET NULL,
    CONSTRAINT fk_atividade_recorrencia FOREIGN KEY (regra_recorrencia_id) REFERENCES regra_recorrencia(id) ON DELETE SET NULL,
    CONSTRAINT fk_atividade_origem      FOREIGN KEY (atividade_origem_id)  REFERENCES atividade(id)         ON DELETE SET NULL,
    CONSTRAINT ck_atividade_titulo      CHECK (char_length(trim(titulo)) BETWEEN 3 AND 120),
    CONSTRAINT ck_atividade_horario     CHECK (hora_fim IS NULL OR hora_inicio IS NULL OR hora_fim > hora_inicio),
    CONSTRAINT ck_atividade_conclusao   CHECK ((status = 'CONCLUIDA') = (concluida_em IS NOT NULL))
);
COMMENT ON COLUMN atividade.descricao       IS 'Limite de 200 caracteres conforme o contador da tela de cadastro.';
COMMENT ON COLUMN atividade.duracao_minutos IS 'Derivado de hora_fim - hora_inicio. Alimenta o indicador "Tempo total".';

CREATE INDEX ix_atividade_usuario_data ON atividade (usuario_id, data_atividade DESC) WHERE excluido_em IS NULL;
CREATE INDEX ix_atividade_status       ON atividade (usuario_id, status)              WHERE excluido_em IS NULL;
CREATE INDEX ix_atividade_categoria    ON atividade (categoria_id)                    WHERE excluido_em IS NULL;
CREATE INDEX ix_atividade_busca        ON atividade USING gin (titulo gin_trgm_ops);

-- =====================================================================
--  6. FINANCEIRO
-- =====================================================================
CREATE TABLE conta_financeira (
    id                      UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id              UUID           NOT NULL,
    nome                    VARCHAR(80)    NOT NULL,
    tipo                    tipo_conta     NOT NULL DEFAULT 'CARTEIRA',
    instituicao             VARCHAR(80),
    saldo_inicial           NUMERIC(15,2)  NOT NULL DEFAULT 0,
    saldo_atual             NUMERIC(15,2)  NOT NULL DEFAULT 0,
    moeda                   CHAR(3)        NOT NULL DEFAULT 'BRL',
    cor_hex                 CHAR(7)        NOT NULL DEFAULT '#3B82F6',
    icone                   VARCHAR(50)    NOT NULL DEFAULT 'wallet',
    incluir_no_saldo_total  BOOLEAN        NOT NULL DEFAULT TRUE,
    ativa                   BOOLEAN        NOT NULL DEFAULT TRUE,
    criado_em               TIMESTAMPTZ    NOT NULL DEFAULT now(),
    atualizado_em           TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CONSTRAINT fk_conta_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT uk_conta_nome    UNIQUE (usuario_id, nome)
);
COMMENT ON COLUMN conta_financeira.saldo_atual IS 'Derivado materializado (ADR-05). Reconciliável por recalcularSaldo().';
CREATE INDEX ix_conta_usuario ON conta_financeira (usuario_id) WHERE ativa = TRUE;

CREATE TABLE transacao (
    id                    UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id            UUID                NOT NULL,
    conta_id              UUID                NOT NULL,
    categoria_id          UUID,
    importancia_id        UUID,
    descricao             VARCHAR(120)        NOT NULL,
    tipo                  tipo_movimento      NOT NULL,
    valor                 NUMERIC(15,2)       NOT NULL,
    data_movimento        DATE                NOT NULL DEFAULT CURRENT_DATE,
    data_competencia      DATE                NOT NULL DEFAULT CURRENT_DATE,
    forma_pagamento       forma_pagamento,
    situacao              situacao_transacao  NOT NULL DEFAULT 'EFETIVADA',
    observacao            VARCHAR(300),
    url_comprovante       VARCHAR(500),
    regra_recorrencia_id  UUID,
    transacao_origem_id   UUID,
    parcela_numero        SMALLINT,
    parcela_total         SMALLINT,
    criado_em             TIMESTAMPTZ         NOT NULL DEFAULT now(),
    atualizado_em         TIMESTAMPTZ         NOT NULL DEFAULT now(),
    excluido_em           TIMESTAMPTZ,
    CONSTRAINT fk_transacao_usuario     FOREIGN KEY (usuario_id)           REFERENCES usuario(id)           ON DELETE CASCADE,
    CONSTRAINT fk_transacao_conta       FOREIGN KEY (conta_id)             REFERENCES conta_financeira(id)  ON DELETE RESTRICT,
    CONSTRAINT fk_transacao_categoria   FOREIGN KEY (categoria_id)         REFERENCES categoria(id)         ON DELETE SET NULL,
    CONSTRAINT fk_transacao_recorrencia FOREIGN KEY (regra_recorrencia_id) REFERENCES regra_recorrencia(id) ON DELETE SET NULL,
    CONSTRAINT fk_transacao_origem      FOREIGN KEY (transacao_origem_id)  REFERENCES transacao(id)         ON DELETE SET NULL,
    CONSTRAINT ck_transacao_valor       CHECK (valor > 0),
    CONSTRAINT ck_transacao_parcela     CHECK ((parcela_numero IS NULL) = (parcela_total IS NULL)),
    CONSTRAINT ck_transacao_parcela_ord CHECK (parcela_numero IS NULL OR parcela_numero <= parcela_total)
);
COMMENT ON COLUMN transacao.valor          IS 'Sempre positivo. O sinal é determinado pelo campo tipo (RN08).';
COMMENT ON COLUMN transacao.importancia_id IS 'Preenchido quando a transação quita uma importância (RN14).';

CREATE INDEX ix_transacao_usuario_data ON transacao (usuario_id, data_movimento DESC) WHERE excluido_em IS NULL;
CREATE INDEX ix_transacao_conta        ON transacao (conta_id)                        WHERE excluido_em IS NULL;
CREATE INDEX ix_transacao_categoria    ON transacao (categoria_id, data_competencia)  WHERE excluido_em IS NULL;
CREATE INDEX ix_transacao_tipo_mes     ON transacao (usuario_id, tipo, data_competencia) WHERE excluido_em IS NULL AND situacao = 'EFETIVADA';
CREATE INDEX ix_transacao_importancia  ON transacao (importancia_id) WHERE importancia_id IS NOT NULL;

-- =====================================================================
--  7. IMPORTÂNCIAS (compromissos e contas)
-- =====================================================================
CREATE TABLE importancia (
    id                          UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id                  UUID                NOT NULL,
    categoria_id                UUID,
    titulo                      VARCHAR(120)        NOT NULL,
    origem                      VARCHAR(120),
    descricao                   VARCHAR(300),
    data_vencimento             DATE                NOT NULL,
    valor                       NUMERIC(15,2),
    tipo                        tipo_importancia    NOT NULL DEFAULT 'CONTA_A_PAGAR',
    status                      status_importancia  NOT NULL DEFAULT 'PENDENTE',
    prioridade                  prioridade          NOT NULL DEFAULT 'MEDIA',
    concluida_em                TIMESTAMPTZ,
    transacao_id                UUID,
    gerar_transacao_ao_concluir BOOLEAN             NOT NULL DEFAULT TRUE,
    dias_antecedencia_alerta    SMALLINT            NOT NULL DEFAULT 3,
    lembrete_ativo              BOOLEAN             NOT NULL DEFAULT TRUE,
    regra_recorrencia_id        UUID,
    criado_em                   TIMESTAMPTZ         NOT NULL DEFAULT now(),
    atualizado_em               TIMESTAMPTZ         NOT NULL DEFAULT now(),
    excluido_em                 TIMESTAMPTZ,
    CONSTRAINT fk_importancia_usuario     FOREIGN KEY (usuario_id)           REFERENCES usuario(id)           ON DELETE CASCADE,
    CONSTRAINT fk_importancia_categoria   FOREIGN KEY (categoria_id)         REFERENCES categoria(id)         ON DELETE SET NULL,
    CONSTRAINT fk_importancia_transacao   FOREIGN KEY (transacao_id)         REFERENCES transacao(id)         ON DELETE SET NULL,
    CONSTRAINT fk_importancia_recorrencia FOREIGN KEY (regra_recorrencia_id) REFERENCES regra_recorrencia(id) ON DELETE SET NULL,
    CONSTRAINT ck_importancia_valor       CHECK (valor IS NULL OR valor > 0),
    CONSTRAINT ck_importancia_conclusao   CHECK ((status = 'CONCLUIDA') = (concluida_em IS NOT NULL)),
    CONSTRAINT ck_importancia_gera_valor  CHECK (NOT gerar_transacao_ao_concluir OR valor IS NOT NULL OR status <> 'CONCLUIDA')
);
COMMENT ON TABLE  importancia                             IS 'Compromissos e datas importantes: contas, licenciamentos, assinaturas.';
COMMENT ON COLUMN importancia.origem                      IS 'Fornecedor ou origem: Vivo Fibra, Detran, Netflix, Energisa.';
COMMENT ON COLUMN importancia.gerar_transacao_ao_concluir IS 'Integração entre os módulos: ao concluir, cria a despesa correspondente.';

CREATE INDEX ix_importancia_vencimento ON importancia (usuario_id, data_vencimento) WHERE excluido_em IS NULL;
CREATE INDEX ix_importancia_status     ON importancia (usuario_id, status)          WHERE excluido_em IS NULL;
CREATE INDEX ix_importancia_pendente   ON importancia (data_vencimento)             WHERE status IN ('PENDENTE','VENCENDO_HOJE') AND excluido_em IS NULL;

-- Vínculo bidirecional transacao <-> importancia (criado após ambas as tabelas)
ALTER TABLE transacao
    ADD CONSTRAINT fk_transacao_importancia
    FOREIGN KEY (importancia_id) REFERENCES importancia(id) ON DELETE SET NULL;

-- =====================================================================
--  8. ORÇAMENTO
-- =====================================================================
CREATE TABLE orcamento (
    id                 UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id         UUID           NOT NULL,
    categoria_id       UUID           NOT NULL,
    mes_referencia     CHAR(7)        NOT NULL,
    valor_limite       NUMERIC(15,2)  NOT NULL,
    percentual_alerta  SMALLINT       NOT NULL DEFAULT 80,
    ativo              BOOLEAN        NOT NULL DEFAULT TRUE,
    criado_em          TIMESTAMPTZ    NOT NULL DEFAULT now(),
    CONSTRAINT fk_orcamento_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuario(id)   ON DELETE CASCADE,
    CONSTRAINT fk_orcamento_categoria FOREIGN KEY (categoria_id) REFERENCES categoria(id) ON DELETE CASCADE,
    CONSTRAINT uk_orcamento           UNIQUE (usuario_id, categoria_id, mes_referencia),
    CONSTRAINT ck_orcamento_limite    CHECK (valor_limite > 0),
    CONSTRAINT ck_orcamento_mes       CHECK (mes_referencia ~ '^\d{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT ck_orcamento_alerta    CHECK (percentual_alerta BETWEEN 1 AND 100)
);

-- =====================================================================
--  9. NOTIFICAÇÃO E AUDITORIA
-- =====================================================================
CREATE TABLE notificacao (
    id                        UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id                UUID                NOT NULL,
    titulo                    VARCHAR(120)        NOT NULL,
    mensagem                  VARCHAR(300)        NOT NULL,
    tipo                      tipo_notificacao    NOT NULL,
    canal                     canal_notificacao   NOT NULL DEFAULT 'PUSH',
    entidade_relacionada_tipo VARCHAR(40),
    entidade_relacionada_id   UUID,
    agendada_para             TIMESTAMPTZ         NOT NULL,
    enviada_em                TIMESTAMPTZ,
    lida_em                   TIMESTAMPTZ,
    status                    status_notificacao  NOT NULL DEFAULT 'AGENDADA',
    tentativas                SMALLINT            NOT NULL DEFAULT 0,
    criado_em                 TIMESTAMPTZ         NOT NULL DEFAULT now(),
    CONSTRAINT fk_notificacao_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    CONSTRAINT ck_notificacao_tentativas CHECK (tentativas BETWEEN 0 AND 5)
);
-- Índice que sustenta o worker: FOR UPDATE SKIP LOCKED
CREATE INDEX ix_notificacao_fila     ON notificacao (agendada_para) WHERE status = 'AGENDADA';
CREATE INDEX ix_notificacao_nao_lida ON notificacao (usuario_id)    WHERE lida_em IS NULL;

CREATE TABLE log_auditoria (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id       UUID,
    acao             VARCHAR(60)  NOT NULL,
    entidade         VARCHAR(60)  NOT NULL,
    entidade_id      UUID,
    dados_anteriores JSONB,
    dados_novos      JSONB,
    endereco_ip      VARCHAR(45),
    ocorrido_em      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL
);
CREATE INDEX ix_auditoria_usuario  ON log_auditoria (usuario_id, ocorrido_em DESC);
CREATE INDEX ix_auditoria_entidade ON log_auditoria (entidade, entidade_id);

-- Controle de idempotência da sincronização offline
CREATE TABLE operacao_processada (
    id_operacao   UUID         PRIMARY KEY,
    usuario_id    UUID         NOT NULL,
    tipo_operacao VARCHAR(60)  NOT NULL,
    resultado     JSONB,
    processado_em TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT fk_operacao_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE
);
CREATE INDEX ix_operacao_limpeza ON operacao_processada (processado_em);

-- =====================================================================
--  10. VISÕES DE CONSULTA (read models)
-- =====================================================================
CREATE OR REPLACE VIEW vw_resumo_financeiro_mensal AS
SELECT
    t.usuario_id,
    to_char(t.data_competencia, 'YYYY-MM')                                        AS ano_mes,
    COALESCE(SUM(t.valor) FILTER (WHERE t.tipo = 'RECEITA'), 0)                   AS total_receitas,
    COALESCE(SUM(t.valor) FILTER (WHERE t.tipo = 'DESPESA'), 0)                   AS total_despesas,
    COALESCE(SUM(t.valor) FILTER (WHERE t.tipo = 'RECEITA'), 0)
      - COALESCE(SUM(t.valor) FILTER (WHERE t.tipo = 'DESPESA'), 0)               AS saldo,
    COUNT(*)                                                                      AS qtd_transacoes
FROM transacao t
WHERE t.excluido_em IS NULL
  AND t.situacao = 'EFETIVADA'
GROUP BY t.usuario_id, to_char(t.data_competencia, 'YYYY-MM');

CREATE OR REPLACE VIEW vw_gasto_por_categoria AS
SELECT
    t.usuario_id,
    t.categoria_id,
    c.nome                                    AS categoria_nome,
    c.cor_hex,
    c.icone,
    to_char(t.data_competencia, 'YYYY-MM')    AS ano_mes,
    SUM(t.valor)                              AS total_gasto,
    COUNT(*)                                  AS qtd_lancamentos
FROM transacao t
JOIN categoria c ON c.id = t.categoria_id
WHERE t.excluido_em IS NULL
  AND t.situacao = 'EFETIVADA'
  AND t.tipo = 'DESPESA'
GROUP BY t.usuario_id, t.categoria_id, c.nome, c.cor_hex, c.icone, to_char(t.data_competencia, 'YYYY-MM');

CREATE OR REPLACE VIEW vw_progresso_atividade AS
SELECT
    a.usuario_id,
    a.data_atividade,
    COUNT(*)                                                    AS total,
    COUNT(*) FILTER (WHERE a.status = 'CONCLUIDA')              AS concluidas,
    COUNT(*) FILTER (WHERE a.status IN ('PENDENTE','ATRASADA')) AS pendentes,
    COALESCE(SUM(a.duracao_minutos), 0)                         AS minutos_totais
FROM atividade a
WHERE a.excluido_em IS NULL
GROUP BY a.usuario_id, a.data_atividade;

-- =====================================================================
--  11. GATILHOS
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_atualizar_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['usuario','preferencia_usuario','categoria','atividade',
                             'conta_financeira','transacao','importancia'] LOOP
        EXECUTE format(
            'CREATE TRIGGER tg_%1$s_timestamp BEFORE UPDATE ON %1$s
             FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp()', t);
    END LOOP;
END $$;

-- Calcula automaticamente a duração da atividade (RN04)
CREATE OR REPLACE FUNCTION fn_calcular_duracao_atividade() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.hora_inicio IS NOT NULL AND NEW.hora_fim IS NOT NULL THEN
        NEW.duracao_minutos := EXTRACT(EPOCH FROM (NEW.hora_fim - NEW.hora_inicio)) / 60;
    ELSE
        NEW.duracao_minutos := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_atividade_duracao
    BEFORE INSERT OR UPDATE OF hora_inicio, hora_fim ON atividade
    FOR EACH ROW EXECUTE FUNCTION fn_calcular_duracao_atividade();

-- Mantém o saldo da conta sincronizado com as transações efetivadas (RN09, RN10).
--
-- IMPORTANTE — fonte única da verdade:
--   Este gatilho é o ÚNICO mecanismo que escreve em conta_financeira.saldo_atual.
--   A camada de aplicação NÃO deve emitir "UPDATE conta_financeira SET saldo_atual",
--   sob pena de dupla contagem. A entidade de domínio ContaFinanceira mantém o saldo
--   em memória apenas para validar invariantes (ex.: saldo suficiente) dentro do
--   caso de uso; a persistência é responsabilidade exclusiva deste gatilho.
--   Vantagem: o saldo permanece correto mesmo para cargas e correções feitas em SQL puro.
CREATE OR REPLACE FUNCTION fn_atualizar_saldo_conta() RETURNS TRIGGER AS $$
DECLARE
    v_delta NUMERIC(15,2) := 0;
BEGIN
    IF TG_OP = 'INSERT' AND NEW.situacao = 'EFETIVADA' AND NEW.excluido_em IS NULL THEN
        v_delta := CASE WHEN NEW.tipo = 'RECEITA' THEN NEW.valor ELSE -NEW.valor END;
        UPDATE conta_financeira SET saldo_atual = saldo_atual + v_delta WHERE id = NEW.conta_id;

    ELSIF TG_OP = 'DELETE' AND OLD.situacao = 'EFETIVADA' AND OLD.excluido_em IS NULL THEN
        v_delta := CASE WHEN OLD.tipo = 'RECEITA' THEN -OLD.valor ELSE OLD.valor END;
        UPDATE conta_financeira SET saldo_atual = saldo_atual + v_delta WHERE id = OLD.conta_id;

    ELSIF TG_OP = 'UPDATE' THEN
        -- desfaz o efeito anterior
        IF OLD.situacao = 'EFETIVADA' AND OLD.excluido_em IS NULL THEN
            UPDATE conta_financeira
               SET saldo_atual = saldo_atual + CASE WHEN OLD.tipo = 'RECEITA' THEN -OLD.valor ELSE OLD.valor END
             WHERE id = OLD.conta_id;
        END IF;
        -- aplica o efeito novo
        IF NEW.situacao = 'EFETIVADA' AND NEW.excluido_em IS NULL THEN
            UPDATE conta_financeira
               SET saldo_atual = saldo_atual + CASE WHEN NEW.tipo = 'RECEITA' THEN NEW.valor ELSE -NEW.valor END
             WHERE id = NEW.conta_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_transacao_saldo
    AFTER INSERT OR UPDATE OR DELETE ON transacao
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_saldo_conta();

-- Impede a exclusão de categorias padrão do sistema (RN17)
CREATE OR REPLACE FUNCTION fn_proteger_categoria_sistema() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.padrao_sistema THEN
        RAISE EXCEPTION 'Categoria padrão do sistema não pode ser excluída. Use inativação.'
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_categoria_protecao
    BEFORE DELETE ON categoria
    FOR EACH ROW EXECUTE FUNCTION fn_proteger_categoria_sistema();

-- Garante que a subcategoria pertença ao mesmo escopo da categoria-pai (RN19)
CREATE OR REPLACE FUNCTION fn_validar_escopo_subcategoria() RETURNS TRIGGER AS $$
DECLARE v_escopo_pai escopo_categoria;
BEGIN
    IF NEW.categoria_pai_id IS NOT NULL THEN
        SELECT escopo INTO v_escopo_pai FROM categoria WHERE id = NEW.categoria_pai_id;
        IF v_escopo_pai <> NEW.escopo THEN
            RAISE EXCEPTION 'A subcategoria deve pertencer ao mesmo escopo da categoria-pai.'
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_categoria_escopo
    BEFORE INSERT OR UPDATE OF categoria_pai_id, escopo ON categoria
    FOR EACH ROW EXECUTE FUNCTION fn_validar_escopo_subcategoria();

-- =====================================================================
--  12. FUNÇÃO DE RECONCILIAÇÃO DE SALDO (job noturno — RN10)
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_recalcular_saldo(p_conta_id UUID)
RETURNS NUMERIC AS $$
DECLARE v_saldo NUMERIC(15,2);
BEGIN
    SELECT c.saldo_inicial
         + COALESCE(SUM(CASE WHEN t.tipo = 'RECEITA' THEN t.valor ELSE -t.valor END), 0)
      INTO v_saldo
      FROM conta_financeira c
      LEFT JOIN transacao t
             ON t.conta_id = c.id
            AND t.situacao = 'EFETIVADA'
            AND t.excluido_em IS NULL
     WHERE c.id = p_conta_id
     GROUP BY c.saldo_inicial;

    UPDATE conta_financeira SET saldo_atual = v_saldo WHERE id = p_conta_id;
    RETURN v_saldo;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
--  FIM DO ESQUEMA
-- =====================================================================
