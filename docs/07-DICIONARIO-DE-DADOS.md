# MinhaVida — Dicionário de Dados

> Gerado a partir do esquema real, após execução bem-sucedida de [`../banco/schema.sql`](../banco/schema.sql) em **PostgreSQL 16.13**.

| Métrica | Valor |
|---|---|
| Tabelas | 16 |
| Colunas | 227 |
| Índices | 53 |
| Restrições (PK, FK, UK, CHECK, NOT NULL) | 221 |
| Tipos enumerados | 17 |
| Visões de consulta | 3 |
| Gatilhos | 11 |

**Legenda:** `PK` chave primária · `FK` chave estrangeira · `UK` chave única · `NN` obrigatório

---

## `usuario`

*Titular da conta — raiz do agregado de identidade*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `nome_completo` | `varchar(120)` | ✔ |  | — | Campo "Nome completo" da tela de Cadastro |
| 3 | `nome_usuario` | `varchar(40)` | ✔ | UK | — | Permite o login por nome de usuário além do e-mail (tela de Login). |
| 4 | `email` | `citext` | ✔ | UK | — | Único, CITEXT (sem distinção de caixa) |
| 5 | `senha_hash` | `varchar(255)` |  |  | — | bcrypt custo 12. Nulo quando a conta é exclusivamente social. |
| 6 | `telefone` | `varchar(20)` |  |  | — | Perfil > Informações pessoais |
| 7 | `data_nascimento` | `date` | ✔ |  | — | Tela de Cadastro. Valida idade mínima de 13 anos |
| 8 | `url_foto_perfil` | `varchar(500)` |  |  | — | Avatar do Perfil (upload no S3) |
| 9 | `status` | `status_usuario` | ✔ |  | PENDENTE_VERIFICACAO |  |
| 10 | `email_verificado` | `bool` | ✔ |  | false |  |
| 11 | `aceite_termos` | `bool` | ✔ |  | false | Checkbox obrigatório do Cadastro |
| 12 | `versao_termos_aceita` | `varchar(20)` |  |  | — | Versão do documento aceito (LGPD) |
| 13 | `data_aceite_termos` | `timestamptz` |  |  | — |  |
| 14 | `data_cadastro` | `timestamptz` | ✔ |  | now() | Exibido no Perfil como "Usuário desde". |
| 15 | `ultimo_acesso` | `timestamptz` |  |  | — |  |
| 16 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 17 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |
| 18 | `excluido_em` | `timestamptz` |  |  | — | Exclusão lógica — nulo = registro ativo (RN22) |

## `preferencia_usuario`

*Preferências de tema, idioma e notificação (1:1 com usuário)*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK UK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `tema` | `tema_app` | ✔ |  | ESCURO | Alternador claro/escuro do Perfil |
| 4 | `idioma` | `varchar(10)` | ✔ |  | pt-BR | "Idioma — Português (BR)" |
| 5 | `moeda` | `char(3)` | ✔ |  | BRL |  |
| 6 | `fuso_horario` | `varchar(50)` | ✔ |  | America/Sao_Paulo |  |
| 7 | `notificacao_push` | `bool` | ✔ |  | true |  |
| 8 | `notificacao_email` | `bool` | ✔ |  | true |  |
| 9 | `notificar_atividades` | `bool` | ✔ |  | true |  |
| 10 | `notificar_importancias` | `bool` | ✔ |  | true |  |
| 11 | `antecedencia_lembrete_min` | `int2` | ✔ |  | 30 |  |
| 12 | `dias_antecedencia_importancia` | `int2` | ✔ |  | 3 |  |
| 13 | `resumo_diario_ativo` | `bool` | ✔ |  | false |  |
| 14 | `hora_resumo_diario` | `time` | ✔ |  | 07:00:00 |  |
| 15 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 16 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |

## `credencial_social`

*Vínculo com provedor OAuth (Entrar com o Google)*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `provedor` | `provedor_oauth` | ✔ | UK | — |  |
| 4 | `id_provedor` | `varchar(255)` | ✔ | UK | — |  |
| 5 | `email_provedor` | `varchar(255)` |  |  | — |  |
| 6 | `vinculado_em` | `timestamptz` | ✔ |  | now() |  |

## `sessao`

*Sessão ativa / refresh token ("Lembrar de mim", "Sair da conta")*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `refresh_token_hash` | `varchar(255)` | ✔ | UK | — | Somente o hash SHA-256 é persistido |
| 4 | `dispositivo` | `varchar(120)` |  |  | — |  |
| 5 | `sistema_operacional` | `varchar(50)` |  |  | — |  |
| 6 | `app_versao` | `varchar(20)` |  |  | — |  |
| 7 | `endereco_ip` | `varchar(45)` |  |  | — |  |
| 8 | `user_agent` | `varchar(255)` |  |  | — |  |
| 9 | `lembrar_de_mim` | `bool` | ✔ |  | false | Define validade: 7 dias (falso) ou 90 dias (verdadeiro) |
| 10 | `criada_em` | `timestamptz` | ✔ |  | now() |  |
| 11 | `expira_em` | `timestamptz` | ✔ |  | — |  |
| 12 | `revogada_em` | `timestamptz` |  |  | — |  |
| 13 | `ultima_atividade_em` | `timestamptz` | ✔ |  | now() |  |

## `token_recuperacao_senha`

*Token de uso único para "Esqueceu a senha?"*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `token_hash` | `varchar(255)` | ✔ | UK | — |  |
| 4 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 5 | `expira_em` | `timestamptz` | ✔ |  | (now() + 00:30:00 |  |
| 6 | `usado_em` | `timestamptz` |  |  | — |  |
| 7 | `endereco_ip` | `varchar(45)` |  |  | — |  |

## `dispositivo_usuario`

*Dispositivo registrado para notificação push*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `token_push` | `varchar(255)` | ✔ | UK | — | Token do Firebase Cloud Messaging |
| 4 | `plataforma` | `plataforma` | ✔ |  | — |  |
| 5 | `modelo` | `varchar(120)` |  |  | — |  |
| 6 | `versao_app` | `varchar(20)` |  |  | — |  |
| 7 | `ativo` | `bool` | ✔ |  | true |  |
| 8 | `registrado_em` | `timestamptz` | ✔ |  | now() |  |
| 9 | `ultimo_uso_em` | `timestamptz` | ✔ |  | now() |  |

## `categoria`

*Categoria unificada (padrão Composite) — atividade, financeiro e importância*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` |  | FK | — | Nulo = categoria padrão do sistema, visível a todos os usuários. |
| 3 | `categoria_pai_id` | `uuid` |  | FK | — | Auto-relacionamento: subcategoria. Ex.: Estudo > Faculdade. |
| 4 | `nome` | `varchar(60)` | ✔ |  | — | Trabalho/Estudo/Pessoal/Lazer · Alimentação/Transporte/… · Contas/Veículo/… |
| 5 | `escopo` | `escopo_categoria` | ✔ |  | — | Separa os três universos de categoria |
| 6 | `tipo_movimento` | `tipo_movimento` |  |  | — |  |
| 7 | `cor_hex` | `char(7)` | ✔ |  | #6366F1 |  |
| 8 | `icone` | `varchar(50)` | ✔ |  | tag |  |
| 9 | `padrao_sistema` | `bool` | ✔ |  | false |  |
| 10 | `ativa` | `bool` | ✔ |  | true |  |
| 11 | `ordem_exibicao` | `int2` | ✔ |  | 0 |  |
| 12 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 13 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |

## `regra_recorrencia`

*Regra de repetição compartilhada por atividade, importância e transação*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `frequencia` | `frequencia` | ✔ |  | — |  |
| 4 | `intervalo` | `int2` | ✔ |  | 1 |  |
| 5 | `dias_semana` | `ARRAY` |  |  | — |  |
| 6 | `dia_do_mes` | `int2` |  |  | — |  |
| 7 | `data_inicio` | `date` | ✔ |  | — |  |
| 8 | `data_fim` | `date` |  |  | — |  |
| 9 | `ocorrencias_max` | `int2` |  |  | — |  |
| 10 | `ocorrencias_geradas` | `int2` | ✔ |  | 0 |  |
| 11 | `proxima_ocorrencia` | `date` |  |  | — |  |
| 12 | `ativa` | `bool` | ✔ |  | true |  |
| 13 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |

## `atividade`

*Tarefa da agenda — CRUD da lista de tarefas*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `categoria_id` | `uuid` |  | FK | — | Categoria de classificação |
| 4 | `subcategoria_id` | `uuid` |  | FK | — | Referência a subcategoria |
| 5 | `titulo` | `varchar(120)` | ✔ |  | — | "Título da atividade *" — 3 a 120 caracteres |
| 6 | `descricao` | `varchar(200)` |  |  | — | Limite de 200 caracteres conforme o contador da tela de cadastro. |
| 7 | `data_atividade` | `date` | ✔ |  | — | Campo "Data" da tela de cadastro |
| 8 | `hora_inicio` | `time` |  |  | — | Campo "Horário" |
| 9 | `hora_fim` | `time` |  |  | — | Deve ser posterior a hora_inicio |
| 10 | `duracao_minutos` | `int4` |  |  | — | Derivado de hora_fim - hora_inicio. Alimenta o indicador "Tempo total". |
| 11 | `prioridade` | `prioridade` | ✔ |  | BAIXA | Campo "Prioridade" (Baixa/Média/Alta/Urgente) |
| 12 | `status` | `status_atividade` | ✔ |  | PENDENTE | Etiqueta "Concluída" / "Pendente" da lista |
| 13 | `concluida_em` | `timestamptz` |  |  | — |  |
| 14 | `lembrete_ativo` | `bool` | ✔ |  | true |  |
| 15 | `minutos_antes_lembrete` | `int2` |  |  | — |  |
| 16 | `regra_recorrencia_id` | `uuid` |  | FK | — | Campo "Repetir (opcional)" |
| 17 | `atividade_origem_id` | `uuid` |  | FK | — | Instância gerada por recorrência |
| 18 | `ordem` | `int4` | ✔ |  | 0 |  |
| 19 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 20 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |
| 21 | `excluido_em` | `timestamptz` |  |  | — | Exclusão lógica — nulo = registro ativo (RN22) |

## `conta_financeira`

*Conta/carteira do usuário — mantém o saldo*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK UK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `nome` | `varchar(80)` | ✔ | UK | — |  |
| 4 | `tipo` | `tipo_conta` | ✔ |  | CARTEIRA |  |
| 5 | `instituicao` | `varchar(80)` |  |  | — |  |
| 6 | `saldo_inicial` | `numeric(15,2)` | ✔ |  | 0 | Saldo na abertura da conta no aplicativo |
| 7 | `saldo_atual` | `numeric(15,2)` | ✔ |  | 0 | Derivado materializado (ADR-05). Reconciliável por recalcularSaldo(). |
| 8 | `moeda` | `char(3)` | ✔ |  | BRL |  |
| 9 | `cor_hex` | `char(7)` | ✔ |  | #3B82F6 |  |
| 10 | `icone` | `varchar(50)` | ✔ |  | wallet |  |
| 11 | `incluir_no_saldo_total` | `bool` | ✔ |  | true |  |
| 12 | `ativa` | `bool` | ✔ |  | true |  |
| 13 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 14 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |

## `transacao`

*Movimentação financeira (receita ou despesa)*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `conta_id` | `uuid` | ✔ | FK | — | Referência a conta |
| 4 | `categoria_id` | `uuid` |  | FK | — | Categoria de classificação |
| 5 | `importancia_id` | `uuid` |  | FK | — | Preenchido quando a transação quita uma importância (RN14). |
| 6 | `descricao` | `varchar(120)` | ✔ |  | — | "Salário", "Mercado", "Uber", "Restaurante" |
| 7 | `tipo` | `tipo_movimento` | ✔ |  | — | Determina o sinal aplicado ao saldo |
| 8 | `valor` | `numeric(15,2)` | ✔ |  | — | Sempre positivo. O sinal é determinado pelo campo tipo (RN08). |
| 9 | `data_movimento` | `date` | ✔ |  | CURRENT_DATE |  |
| 10 | `data_competencia` | `date` | ✔ |  | CURRENT_DATE | Regime de competência para relatórios |
| 11 | `forma_pagamento` | `forma_pagamento` |  |  | — |  |
| 12 | `situacao` | `situacao_transacao` | ✔ |  | EFETIVADA | Somente EFETIVADA afeta o saldo |
| 13 | `observacao` | `varchar(300)` |  |  | — |  |
| 14 | `url_comprovante` | `varchar(500)` |  |  | — |  |
| 15 | `regra_recorrencia_id` | `uuid` |  | FK | — | Referência a regra recorrencia |
| 16 | `transacao_origem_id` | `uuid` |  | FK | — | Referência a transacao origem |
| 17 | `parcela_numero` | `int2` |  |  | — |  |
| 18 | `parcela_total` | `int2` |  |  | — |  |
| 19 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 20 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |
| 21 | `excluido_em` | `timestamptz` |  |  | — | Exclusão lógica — nulo = registro ativo (RN22) |

## `importancia`

*Compromisso ou data importante (conta a pagar, licenciamento, assinatura)*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `categoria_id` | `uuid` |  | FK | — | Categoria de classificação |
| 4 | `titulo` | `varchar(120)` | ✔ |  | — | "Pagamento da internet" |
| 5 | `origem` | `varchar(120)` |  |  | — | Fornecedor ou origem: Vivo Fibra, Detran, Netflix, Energisa. |
| 6 | `descricao` | `varchar(300)` |  |  | — |  |
| 7 | `data_vencimento` | `date` | ✔ |  | — | "Dia 29/09/2025" — base do agrupamento e dos alertas |
| 8 | `valor` | `numeric(15,2)` |  |  | — | "R$ 99,90" — nulo em compromissos sem valor |
| 9 | `tipo` | `tipo_importancia` | ✔ |  | CONTA_A_PAGAR |  |
| 10 | `status` | `status_importancia` | ✔ |  | PENDENTE | Define o agrupamento Hoje / Próximos / Concluídos |
| 11 | `prioridade` | `prioridade` | ✔ |  | MEDIA |  |
| 12 | `concluida_em` | `timestamptz` |  |  | — |  |
| 13 | `transacao_id` | `uuid` |  | FK | — | Transação gerada na quitação |
| 14 | `gerar_transacao_ao_concluir` | `bool` | ✔ |  | true | Integração entre os módulos: ao concluir, cria a despesa correspondente. |
| 15 | `dias_antecedencia_alerta` | `int2` | ✔ |  | 3 |  |
| 16 | `lembrete_ativo` | `bool` | ✔ |  | true |  |
| 17 | `regra_recorrencia_id` | `uuid` |  | FK | — | Referência a regra recorrencia |
| 18 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |
| 19 | `atualizado_em` | `timestamptz` | ✔ |  | now() | Data da última alteração (gatilho automático) |
| 20 | `excluido_em` | `timestamptz` |  |  | — | Exclusão lógica — nulo = registro ativo (RN22) |

## `orcamento`

*Limite mensal de gasto por categoria*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK UK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `categoria_id` | `uuid` | ✔ | FK UK | — | Categoria de classificação |
| 4 | `mes_referencia` | `char(7)` | ✔ | UK | — |  |
| 5 | `valor_limite` | `numeric(15,2)` | ✔ |  | — |  |
| 6 | `percentual_alerta` | `int2` | ✔ |  | 80 |  |
| 7 | `ativo` | `bool` | ✔ |  | true |  |
| 8 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |

## `notificacao`

*Notificação agendada ou enviada*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `titulo` | `varchar(120)` | ✔ |  | — |  |
| 4 | `mensagem` | `varchar(300)` | ✔ |  | — |  |
| 5 | `tipo` | `tipo_notificacao` | ✔ |  | — |  |
| 6 | `canal` | `canal_notificacao` | ✔ |  | PUSH |  |
| 7 | `entidade_relacionada_tipo` | `varchar(40)` |  |  | — |  |
| 8 | `entidade_relacionada_id` | `uuid` |  |  | — | Referência a entidade relacionada |
| 9 | `agendada_para` | `timestamptz` | ✔ |  | — |  |
| 10 | `enviada_em` | `timestamptz` |  |  | — |  |
| 11 | `lida_em` | `timestamptz` |  |  | — | Nulo = não lida (alimenta o indicador do sino) |
| 12 | `status` | `status_notificacao` | ✔ |  | AGENDADA |  |
| 13 | `tentativas` | `int2` | ✔ |  | 0 |  |
| 14 | `criado_em` | `timestamptz` | ✔ |  | now() | Data de criação (auditoria) |

## `log_auditoria`

*Trilha de auditoria de operações sensíveis*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id` | `uuid` | ✔ | PK | gen_random_uuid() | Identificador único (UUID v4) |
| 2 | `usuario_id` | `uuid` |  | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `acao` | `varchar(60)` | ✔ |  | — |  |
| 4 | `entidade` | `varchar(60)` | ✔ |  | — |  |
| 5 | `entidade_id` | `uuid` |  |  | — | Referência a entidade |
| 6 | `dados_anteriores` | `jsonb` |  |  | — |  |
| 7 | `dados_novos` | `jsonb` |  |  | — |  |
| 8 | `endereco_ip` | `varchar(45)` |  |  | — |  |
| 9 | `ocorrido_em` | `timestamptz` | ✔ |  | now() |  |

## `operacao_processada`

*Controle de idempotência da sincronização offline*

| # | Coluna | Tipo | NN | Chave | Padrão | Descrição |
|---:|---|---|:-:|:-:|---|---|
| 1 | `id_operacao` | `uuid` | ✔ | PK | — |  |
| 2 | `usuario_id` | `uuid` | ✔ | FK | — | Proprietário do registro — filtro obrigatório (RN21) |
| 3 | `tipo_operacao` | `varchar(60)` | ✔ |  | — |  |
| 4 | `resultado` | `jsonb` |  |  | — |  |
| 5 | `processado_em` | `timestamptz` | ✔ |  | now() |  |
---

## Índices e sua justificativa

| Índice | Tabela | Consulta que ele atende |
|---|---|---|
| `ix_atividade_usuario_data` | atividade | Lista de atividades por dia (telas Início e Atividades) |
| `ix_atividade_status` | atividade | Indicadores "Concluídas / Pendentes" |
| `ix_atividade_busca` (GIN trigram) | atividade | Busca textual pela lupa da tela Atividades |
| `ix_transacao_usuario_data` | transacao | "Últimas movimentações" em ordem decrescente |
| `ix_transacao_tipo_mes` | transacao | Totais de receita e despesa do mês (parcial: só efetivadas) |
| `ix_transacao_categoria` | transacao | Gasto por categoria e gráfico mensal |
| `ix_importancia_vencimento` | importancia | Agrupamento Hoje / Próximos / Concluídos |
| `ix_importancia_pendente` | importancia | Job diário que reclassifica vencimentos |
| `ix_notificacao_fila` | notificacao | Worker com `FOR UPDATE SKIP LOCKED` |
| `ix_sessao_ativa` | sessao | Validação de refresh token |
| `uk_categoria_nome_usuario` | categoria | Impede categorias duplicadas por usuário e escopo |

Os índices parciais (`WHERE excluido_em IS NULL`) reduzem substancialmente o tamanho do índice, já que registros excluídos logicamente nunca aparecem nas consultas do aplicativo.

## Visões de consulta

| Visão | Alimenta |
|---|---|
| `vw_resumo_financeiro_mensal` | Cards "Receitas / Despesas / Saldo do mês" e a variação percentual |
| `vw_gasto_por_categoria` | Seção "Categorias" da tela Financeiro |
| `vw_progresso_atividade` | Indicadores "Total / Concluídas / Pendentes / Tempo total" |

> Na v1 são visões comuns. Quando o volume exigir, basta convertê-las em **visões materializadas** com atualização pelo job das 02:00 — sem alterar as consultas da aplicação.

## Gatilhos

| Gatilho | Tabela | Função |
|---|---|---|
| `tg_*_timestamp` (7 tabelas) | várias | Atualiza `atualizado_em` automaticamente |
| `tg_atividade_duracao` | atividade | Calcula `duracao_minutos` a partir do horário (RN04) |
| `tg_transacao_saldo` | transacao | **Fonte única** do `saldo_atual` da conta (RN09, RN10) |
| `tg_categoria_protecao` | categoria | Impede exclusão de categoria do sistema (RN17) |
| `tg_categoria_escopo` | categoria | Garante escopo coerente entre categoria e subcategoria (RN19) |

---

## Validação executada

O esquema e a carga de demonstração foram **executados em PostgreSQL 16.13 real**, e o modelo reproduz exatamente os indicadores das telas:

| Indicador | Calculado pelo modelo | Exibido na tela |
|---|---|---|
| Saldo atual | R$ 1.220,35 | R$ 1.220,35 ✔ |
| Receitas do mês | R$ 2.450,75 | R$ 2.450,75 ✔ |
| Despesas do mês | R$ 1.230,40 | R$ 1.230,40 ✔ |
| Total de atividades | 12 | 12 ✔ |
| Concluídas | 10 | 10 ✔ |
| Pendentes | 2 | 2 ✔ |
| Tempo total | 18h45min | 18h45min ✔ |
| "Compra do mês" — dias restantes | 6 | "Em 6 dias" ✔ |

As regras de negócio também foram testadas contra o banco, todas rejeitando corretamente as violações:

| Teste | Regra | Resultado |
|---|---|---|
| Transação com valor negativo | RN08 | rejeitada por `ck_transacao_valor` ✔ |
| Atividade com hora de fim anterior à de início | RN03 | rejeitada por `ck_atividade_horario` ✔ |
| Exclusão de categoria do sistema | RN17 | rejeitada por `tg_categoria_protecao` ✔ |
| Subcategoria em escopo divergente | RN19 | rejeitada por `tg_categoria_escopo` ✔ |
| Cadastro de menor de 13 anos | RN23 | rejeitado por `ck_usuario_idade_minima` ✔ |
| Quitação de importância gerando despesa | RN14 | transação criada, saldo debitado em R$ 99,90 ✔ |
| Estorno por exclusão lógica | RN22 | saldo devolvido, histórico preservado ✔ |

---

## ⚠️ Inconsistências encontradas no protótipo

Ao reproduzir os números das telas no banco, três divergências internas do protótipo vieram à tona. Nenhuma compromete a modelagem, mas **precisam ser decididas antes de o back-end ser construído**, porque o sistema real não pode exibir números que não fecham.

**1. A soma das categorias não bate com o total de despesas (tela Financeiro)**
A tela informa "Despesas R$ 1.230,40", mas as fichas de categoria somam R$ 1.661,40:

`Alimentação 420,30 + Transporte 310,20 + Moradia 600,00 + Compras 210,50 + Outros 120,40 = 1.661,40`

O valor de R$ 1.230,40 é corroborado por outro número da mesma tela — `2.450,75 − 1.230,40 = 1.220,35`, exatamente o "Saldo atual" exibido. Por isso o total do cabeçalho foi adotado como verdadeiro e a distribuição por categoria foi recalculada para fechar nele.
**Decisão necessária:** ajustar os valores das fichas de categoria no protótipo.

**2. Salário com data e valor diferentes entre duas telas**
- Tela **Início**, em "Atividades recentes": `Salário · 28/09/2025 · + R$ 3.200,00`
- Tela **Financeiro**, em "Últimas movimentações": `Salário · 29/09/2025 · + R$ 2.450,75`

O mesmo lançamento aparece com data e valor distintos. Adotou-se a versão da tela Financeiro, que é consistente com os cards de resumo.
**Decisão necessária:** unificar o valor e a data do salário.

**3. "Saldo do mês" e "Receitas" usam o mesmo número com rótulos diferentes**
Na tela Início o card exibe "**Saldo** do mês — R$ 2.450,75"; na tela Financeiro, o mesmo R$ 2.450,75 aparece como "**Receitas**". Saldo e receita são grandezas diferentes: o saldo do mês deveria ser R$ 1.220,35.
**Decisão necessária:** corrigir o rótulo do card da tela Início para "Receitas do mês", ou exibir ali o saldo real.

> Esse tipo de divergência é absolutamente normal em protótipos de alta fidelidade feitos em ferramenta de design — os números são escritos à mão, um de cada vez. O valor de modelar os dados antes de programar está justamente em fazer essas inconsistências aparecerem agora, e não em produção.
