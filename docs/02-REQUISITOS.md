# MinhaVida — Levantamento de Requisitos

Documento derivado da análise das 8 telas do protótipo. Cada requisito é rastreável até a tela de origem, o caso de uso e a entidade de domínio afetada.

---

## 1. Atores

| Ator | Tipo | Descrição |
|---|---|---|
| **Usuário** | Primário / humano | Pessoa física que gerencia sua rotina e suas finanças |
| **Agendador (Cron)** | Secundário / sistema | Dispara jobs de notificação, recorrência e consolidação |
| **Google Identity** | Secundário / externo | Provedor OAuth 2.0 / OpenID Connect para login social |
| **Firebase Cloud Messaging** | Secundário / externo | Entrega de notificações push |
| **Amazon SES** | Secundário / externo | Envio de e-mails transacionais |

---

## 2. Requisitos Funcionais

Legenda de prioridade (MoSCoW): **M** = Must have · **S** = Should have · **C** = Could have

### 2.1 Módulo Identidade e Acesso

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF01 | O sistema deve permitir o cadastro de usuário informando nome completo, e-mail, senha, confirmação de senha e data de nascimento | M | Cadastro | `Usuario` |
| RF02 | O sistema deve exigir o aceite explícito dos Termos de Uso e da Política de Privacidade, registrando data e versão aceita | M | Cadastro | `Usuario` |
| RF03 | O sistema deve validar que a senha e a confirmação são idênticas e atendem à política mínima de segurança | M | Cadastro | `Usuario` |
| RF04 | O sistema deve impedir cadastro com e-mail ou nome de usuário já existentes | M | Cadastro | `Usuario` |
| RF05 | O sistema deve permitir autenticação por e-mail **ou** nome de usuário, acompanhado de senha | M | Login | `Usuario`, `Sessao` |
| RF06 | O sistema deve oferecer a opção "Lembrar de mim", estendendo a validade do refresh token de 7 para 90 dias | S | Login | `Sessao` |
| RF07 | O sistema deve permitir recuperação de senha por e-mail, com token de uso único e validade de 30 minutos | M | Login | `TokenRecuperacaoSenha` |
| RF08 | O sistema deve permitir autenticação federada via conta Google (OAuth 2.0 / OIDC) | S | Login | `CredencialSocial` |
| RF09 | O sistema deve permitir alternar a visibilidade dos campos de senha | C | Login, Cadastro | — |
| RF10 | O sistema deve permitir encerrar a sessão, revogando o refresh token do dispositivo | M | Perfil | `Sessao` |

### 2.2 Módulo Perfil e Preferências

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF11 | O sistema deve exibir nome, e-mail, foto e a data em que o usuário se cadastrou ("Usuário desde") | M | Perfil | `Usuario` |
| RF12 | O sistema deve permitir editar informações pessoais: nome, e-mail, telefone e data de nascimento | M | Perfil | `Usuario` |
| RF13 | O sistema deve permitir enviar e substituir a foto de perfil | S | Perfil | `Usuario` |
| RF14 | O sistema deve permitir a alteração de senha mediante confirmação da senha atual | M | Perfil | `Usuario` |
| RF15 | O sistema deve permitir configurar preferências de notificação por tipo e por canal | S | Perfil | `PreferenciaUsuario` |
| RF16 | O sistema deve permitir alternar entre tema claro e escuro, persistindo a escolha | S | Perfil | `PreferenciaUsuario` |
| RF17 | O sistema deve permitir selecionar o idioma da interface (padrão Português-BR) | C | Perfil | `PreferenciaUsuario` |
| RF18 | O sistema deve exibir a versão do aplicativo e canal de ajuda e suporte | C | Perfil | — |

### 2.3 Módulo Gestão de Atividades (CRUD de tarefas)

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF19 | O sistema deve permitir **criar** atividade com título (obrigatório), descrição (opcional, até 200 caracteres), categoria, prioridade, data, horário e repetição | M | Cadastrar atividade | `Atividade` |
| RF20 | O sistema deve permitir **consultar** atividades filtrando por categoria (Todas, Trabalho, Estudo, Pessoal, Lazer) e por data | M | Atividades | `Atividade` |
| RF21 | O sistema deve permitir **editar** todos os campos de uma atividade existente | M | Atividades | `Atividade` |
| RF22 | O sistema deve permitir **excluir** uma atividade (exclusão lógica, preservando histórico) | M | Atividades | `Atividade` |
| RF23 | O sistema deve permitir marcar uma atividade como concluída e reabri-la | M | Início, Atividades | `Atividade` |
| RF24 | O sistema deve exibir indicadores do período: total de atividades, concluídas, pendentes e tempo total acumulado, com variação em relação ao dia anterior | M | Atividades | `Atividade` |
| RF25 | O sistema deve agrupar as atividades por dia e permitir ordenação (mais recentes, horário, prioridade) | S | Atividades | `Atividade` |
| RF26 | O sistema deve permitir busca textual por título e descrição da atividade | S | Atividades | `Atividade` |
| RF27 | O sistema deve permitir definir recorrência (diária, semanal, quinzenal, mensal, anual ou personalizada) e gerar as ocorrências futuras | S | Cadastrar atividade | `RegraRecorrencia` |
| RF28 | O sistema deve calcular automaticamente a duração da atividade a partir de hora de início e fim | M | Atividades | `Atividade` |
| RF29 | O sistema deve classificar automaticamente como atrasada a atividade pendente cujo horário já passou | S | Atividades | `Atividade` |

### 2.4 Módulo Gestão Financeira

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF30 | O sistema deve permitir registrar receitas e despesas com descrição, valor, tipo, categoria, conta, data e forma de pagamento | M | Financeiro | `Transacao` |
| RF31 | O sistema deve calcular e exibir o saldo atual consolidado das contas do usuário | M | Financeiro, Início | `ContaFinanceira` |
| RF32 | O sistema deve exibir os totais de receitas e despesas do mês e a variação percentual em relação ao mês anterior | M | Financeiro, Início | `ResumoFinanceiroMensal` |
| RF33 | O sistema deve exibir um gráfico diário de receitas versus despesas do mês selecionado | M | Financeiro | `Transacao` |
| RF34 | O sistema deve permitir navegar entre meses para consulta histórica | M | Financeiro | `Transacao` |
| RF35 | O sistema deve totalizar as despesas agrupadas por categoria no período | M | Financeiro | `Transacao`, `Categoria` |
| RF36 | O sistema deve listar as últimas movimentações em ordem decrescente de data | M | Financeiro, Início | `Transacao` |
| RF37 | O sistema deve permitir editar, estornar e excluir lançamentos, recalculando o saldo | M | Financeiro | `Transacao` |
| RF38 | O sistema deve permitir gerenciar múltiplas contas financeiras (carteira, corrente, poupança, cartão de crédito) | S | Financeiro | `ContaFinanceira` |
| RF39 | O sistema deve permitir criar, editar e inativar categorias personalizadas com cor e ícone | S | Financeiro | `Categoria` |
| RF40 | O sistema deve permitir lançamentos parcelados, gerando as parcelas vinculadas à transação de origem | C | Financeiro | `Transacao` |
| RF41 | O sistema deve permitir definir orçamento mensal por categoria e alertar ao atingir o percentual configurado | C | Financeiro | `Orcamento` |

### 2.5 Módulo Importâncias

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF42 | O sistema deve permitir cadastrar importâncias com título, origem/fornecedor, categoria, data de vencimento, valor e tipo | M | Importâncias | `Importancia` |
| RF43 | O sistema deve permitir filtrar importâncias por Todos, Vencendo hoje, Este mês, Próximos e Concluídos | M | Importâncias | `Importancia` |
| RF44 | O sistema deve permitir navegar entre meses e agrupar os itens por Hoje, Próximos e Concluídos, exibindo a contagem de cada grupo | M | Importâncias | `Importancia` |
| RF45 | O sistema deve calcular e exibir os dias restantes até o vencimento ("Em 6 dias") | M | Início | `Importancia` |
| RF46 | O sistema deve destacar visualmente a urgência por cor conforme a proximidade do vencimento | S | Importâncias | `Importancia` |
| RF47 | O sistema deve permitir concluir uma importância e, quando configurado, **gerar automaticamente a transação financeira** correspondente, debitando a conta escolhida | M | Importâncias | `Importancia`, `Transacao` |
| RF48 | O sistema deve gerar a próxima ocorrência de importâncias recorrentes ao concluir a atual | S | Importâncias | `RegraRecorrencia` |
| RF49 | O sistema deve exibir o total de importâncias pendentes no painel inicial | M | Início | `Importancia` |

### 2.6 Módulo Dashboard e Notificações

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF50 | O sistema deve exibir saudação personalizada com o primeiro nome do usuário | C | Início | `Usuario` |
| RF51 | O sistema deve exibir, em um único painel, saldo do mês, despesas do mês e importâncias pendentes | M | Início | agregação |
| RF52 | O sistema deve exibir as atividades do dia corrente com horário, categoria e possibilidade de conclusão direta | M | Início | `Atividade` |
| RF53 | O sistema deve exibir o resumo financeiro do dia: receitas, despesas e saldo do dia | M | Início | `Transacao` |
| RF54 | O sistema deve oferecer atalhos de acesso rápido às principais ações de cadastro | S | Início | — |
| RF55 | O sistema deve enviar notificação push de lembrete antes do início da atividade, conforme antecedência configurada | S | — | `Notificacao` |
| RF56 | O sistema deve enviar notificação push de importância a vencer, conforme dias de antecedência configurados | M | — | `Notificacao` |
| RF57 | O sistema deve exibir indicador visual de notificações não lidas | S | Início | `Notificacao` |
| RF58 | O sistema deve emitir relatórios de progresso de atividades e de evolução financeira | C | Início | agregação |

### 2.7 Módulo Sincronização

| ID | Requisito | Prior. | Tela | Entidade |
|---|---|---|---|---|
| RF59 | O sistema deve permitir consultar e registrar dados sem conexão, armazenando as operações localmente | S | todas | fila outbox |
| RF60 | O sistema deve sincronizar as operações pendentes ao restabelecer a conexão, de forma idempotente | S | todas | `operacao_processada` |
| RF61 | O sistema deve resolver conflitos de edição pela política de última escrita vence, registrando a divergência | C | todas | — |

---

## 3. Requisitos Não Funcionais

### 3.1 Desempenho
| ID | Requisito | Métrica |
|---|---|---|
| RNF01 | Tempo de resposta da API | p95 ≤ 300 ms · p99 ≤ 800 ms |
| RNF02 | Tempo de abertura do aplicativo até conteúdo utilizável | ≤ 2 s em aparelho intermediário |
| RNF03 | Carga do dashboard | ≤ 1 requisição agregada, servida por cache de 120 s |
| RNF04 | Listagens | paginação obrigatória, 20 itens por página |

### 3.2 Segurança
| ID | Requisito |
|---|---|
| RNF05 | Senhas armazenadas com bcrypt, fator de custo 12. Nunca em texto claro, nunca em log |
| RNF06 | Autenticação por JWT: access token de 15 minutos e refresh token rotativo |
| RNF07 | Todo tráfego obrigatoriamente sobre HTTPS/TLS 1.3; HSTS habilitado |
| RNF08 | Isolamento multiusuário: toda consulta filtra por `usuario_id`; nenhum identificador sequencial exposto (uso de UUID v4) |
| RNF09 | Limite de requisições: 100 req/min por IP e 5 tentativas de login por minuto por conta |
| RNF10 | Validação e sanitização de toda entrada; uso exclusivo de consultas parametrizadas |
| RNF11 | Tokens armazenados no dispositivo em Keychain (iOS) / Keystore (Android), nunca em armazenamento comum |
| RNF12 | Registro de auditoria para operações sensíveis, com retenção mínima de 12 meses |

### 3.3 Privacidade e conformidade legal (LGPD)
| ID | Requisito |
|---|---|
| RNF13 | Consentimento explícito registrado com data e versão dos termos aceitos |
| RNF14 | Direito de acesso: exportação completa dos dados do titular em formato legível por máquina |
| RNF15 | Direito à eliminação: exclusão de conta com anonimização em até 30 dias |
| RNF16 | Minimização: coletar apenas o necessário à finalidade declarada |
| RNF17 | Criptografia em repouso no banco de dados e no armazenamento de objetos |

### 3.4 Usabilidade e acessibilidade
| ID | Requisito |
|---|---|
| RNF18 | Cadastro de atividade concluído em no máximo 3 toques a partir do painel inicial |
| RNF19 | Contraste mínimo 4.5:1 (WCAG 2.1 nível AA) nos dois temas |
| RNF20 | Área mínima de toque de 44×44 pt |
| RNF21 | Compatibilidade com leitor de tela (TalkBack e VoiceOver) |
| RNF22 | Valores monetários no formato brasileiro (R$ 1.234,56) e datas em DD/MM/AAAA |

### 3.5 Confiabilidade e operação
| ID | Requisito |
|---|---|
| RNF23 | Disponibilidade mensal mínima de 99,5% |
| RNF24 | Backup diário automatizado com recuperação a qualquer ponto (PITR) de 7 dias |
| RNF25 | RPO ≤ 5 minutos · RTO ≤ 1 hora |
| RNF26 | Escalabilidade horizontal da API sem estado, com autoescalonamento por CPU |
| RNF27 | Rastreamento distribuído, métricas e log estruturado em toda requisição |

### 3.6 Manutenibilidade e portabilidade
| ID | Requisito |
|---|---|
| RNF28 | Cobertura mínima de testes: 80% no domínio e nos casos de uso |
| RNF29 | Arquitetura em camadas com inversão de dependência; domínio livre de framework |
| RNF30 | Base de código única para Android e iOS |
| RNF31 | Versionamento da API por caminho (`/api/v1`), com política de depreciação documentada |
| RNF32 | Migrações de banco versionadas e reversíveis |

---

## 4. Regras de Negócio

| ID | Regra |
|---|---|
| RN01 | O título da atividade é obrigatório e deve conter entre 3 e 120 caracteres |
| RN02 | A descrição da atividade é limitada a 200 caracteres (conforme contador da tela) |
| RN03 | A hora de fim, quando informada, deve ser posterior à hora de início |
| RN04 | A duração da atividade é sempre derivada: `duracaoMinutos = horaFim − horaInicio`; nunca é informada manualmente |
| RN05 | Somente atividades com status `PENDENTE`, `EM_ANDAMENTO` ou `ATRASADA` podem ser concluídas |
| RN06 | Uma atividade concluída pode ser reaberta, retornando ao status `PENDENTE` e limpando a data de conclusão |
| RN07 | A atividade pendente cujo horário já passou é reclassificada como `ATRASADA` pelo job diário das 00:10 |
| RN08 | O valor de uma transação deve ser estritamente maior que zero; o sinal é determinado pelo campo `tipo`, não pelo valor |
| RN09 | Receita credita a conta; despesa debita a conta. A atualização do saldo e a inserção da transação ocorrem na mesma transação de banco (atomicidade) |
| RN10 | O saldo da conta é sempre recalculável a partir de `saldoInicial` somado às transações efetivadas — a coluna `saldoAtual` é um cache auditável |
| RN11 | Transações com situação `PENDENTE` não afetam o saldo; apenas as `EFETIVADA` |
| RN12 | O estorno nunca altera a transação original: gera uma nova transação de sinal oposto, vinculada à origem |
| RN13 | Uma importância só pode ser concluída uma única vez; nova tentativa retorna conflito |
| RN14 | Ao concluir uma importância com `gerarTransacaoAoConcluir = true` e valor informado, o sistema cria a transação de quitação e a vincula em ambos os sentidos |
| RN15 | Importância com vencimento igual à data corrente recebe status `VENCENDO_HOJE`; ultrapassada a data, torna-se `ATRASADA` |
| RN16 | Ao concluir uma importância recorrente, a próxima ocorrência é gerada automaticamente com a data calculada pela regra |
| RN17 | Categorias do sistema (`padraoSistema = true`) não podem ser excluídas pelo usuário, apenas inativadas |
| RN18 | Uma categoria com lançamentos vinculados não pode ser excluída fisicamente, apenas inativada |
| RN19 | A subcategoria deve pertencer ao mesmo escopo da categoria-pai |
| RN20 | A variação percentual mensal usa a fórmula `((atual − anterior) / anterior) × 100`; quando o mês anterior é zero, exibe-se "—" em vez de divisão por zero |
| RN21 | Nenhum usuário acessa dados de outro usuário: toda consulta é obrigatoriamente filtrada por `usuario_id` |
| RN22 | A exclusão de registros é lógica (`excluido_em`), preservando a integridade histórica e a auditoria |
| RN23 | O usuário deve ter no mínimo 13 anos completos na data do cadastro |
| RN24 | Ao excluir a conta, todos os dados pessoais são anonimizados em até 30 dias, preservando-se apenas agregados estatísticos sem identificação |

---

## 5. Rastreabilidade — Tela → Requisitos → Entidades

| Tela | Requisitos | Entidades principais |
|---|---|---|
| 1. Cadastro | RF01–RF04, RF09, RN23 | `Usuario`, `PreferenciaUsuario`, `Categoria` |
| 2. Login | RF05–RF09 | `Usuario`, `Sessao`, `CredencialSocial`, `TokenRecuperacaoSenha` |
| 3. Início (Dashboard) | RF45, RF49–RF54, RF57 | agregação de `Atividade`, `Transacao`, `Importancia` |
| 4. Atividades | RF20–RF26, RF28, RF29 | `Atividade`, `Categoria` |
| 5. Cadastrar atividade | RF19, RF27 | `Atividade`, `RegraRecorrencia`, `Categoria` |
| 6. Financeiro | RF30–RF41 | `Transacao`, `ContaFinanceira`, `Categoria`, `Orcamento` |
| 7. Importâncias | RF42–RF48 | `Importancia`, `Transacao`, `Categoria` |
| 8. Perfil | RF10–RF18 | `Usuario`, `PreferenciaUsuario`, `Sessao` |
