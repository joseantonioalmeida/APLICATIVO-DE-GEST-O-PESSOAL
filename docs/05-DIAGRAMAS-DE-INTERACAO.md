# MinhaVida — Diagramas de Interação (UML)

Os diagramas de interação mostram **como os objetos colaboram no tempo** para realizar um caso de uso. Enquanto o diagrama de classes descreve a estrutura estática, estes descrevem o comportamento dinâmico.

A UML 2.5 define quatro tipos de diagrama de interação. Este projeto utiliza os dois mais expressivos:

| Tipo | Ênfase | Uso aqui |
|---|---|---|
| **Sequência** | ordem temporal das mensagens | 8 diagramas — fluxos principais |
| **Comunicação** | topologia das ligações entre objetos | 1 diagrama — registro de transação |

### Notação empregada

| Elemento | Significado |
|---|---|
| Linha de vida | existência do objeto ao longo do tempo |
| Barra de ativação | período em que o objeto executa uma operação |
| `→` seta cheia | mensagem **síncrona** (o remetente aguarda o retorno) |
| `⇢` seta tracejada | mensagem de **retorno** |
| `→)` seta aberta | mensagem **assíncrona** (o remetente não aguarda) |
| `alt` | fragmento alternativo — caminhos mutuamente exclusivos |
| `opt` | fragmento opcional — executa se a condição for verdadeira |
| `loop` | repetição |
| `par` | execução paralela |
| `[condição]` | guarda do fragmento |

---

## SD-01 — Cadastro de usuário
**Caso de uso:** UC01 · **Tela:** Cadastro · **Requisitos:** RF01–RF04

![Sequência — Cadastro](imagens/03-seq-cadastro.svg)

**Pontos de arquitetura demonstrados**
1. **Validação em duas camadas** — o cliente valida para dar resposta imediata; o servidor revalida porque *toda entrada vinda do cliente é não confiável*.
2. **Transação atômica de provisionamento** — o novo usuário nasce com preferências, 18 categorias padrão e uma conta "Carteira" criadas no mesmo `COMMIT`. Falha em qualquer etapa desfaz tudo: nunca existe usuário pela metade.
3. **Assincronismo no envio de e-mail** — o e-mail de verificação é enfileirado, não enviado na requisição. Indisponibilidade do provedor de e-mail não impede o cadastro.
4. **Fragmento `alt` para e-mail duplicado** — retorna `409 Conflict` com código de erro estruturado, não uma mensagem de texto solta.

---

## SD-02 — Autenticação (login)
**Caso de uso:** UC02 · **Tela:** Login · **Requisitos:** RF05, RF06

![Sequência — Login](imagens/04-seq-login.svg)

**Pontos de arquitetura demonstrados**
1. **Resposta genérica em falha** — "E-mail ou senha incorretos" nunca revela se o e-mail existe. Com tempo de resposta constante, impede-se a enumeração de contas.
2. **Dois tokens com propósitos distintos** — o *access token* (15 min, sem estado) evita consulta ao banco a cada requisição; o *refresh token* (persistido em `sessao`) permite revogação real.
3. **"Lembrar de mim" como parâmetro de validade** — a mesma mecânica, com expiração de 7 ou 90 dias.
4. **Armazenamento seguro no dispositivo** — Keychain/Keystore, nunca armazenamento comum.

---

## SD-03 — Carregamento do painel inicial
**Caso de uso:** UC22 · **Tela:** Início · **Requisitos:** RF51–RF53

![Sequência — Dashboard](imagens/05-seq-dashboard.svg)

**Pontos de arquitetura demonstrados**
1. **Renderização progressiva** — a tela aparece imediatamente com o cache local do SQLite; a rede só refina o que já está na frente do usuário.
2. **Uma requisição, não quatro** — o painel agrega três contextos em um único endpoint. Em rede móvel, latência de ida e volta custa mais que processamento.
3. **Fragmento `par`** — as três consultas ocorrem em paralelo no servidor; o tempo total é o da mais lenta, não a soma.
4. **Cache com TTL curto** — 120 segundos no Redis. A tela mais acessada do aplicativo é também a mais cara de montar.

---

## SD-04 — CRUD de atividade (criação e conclusão)
**Caso de uso:** UC07 e UC10 · **Telas:** Cadastrar atividade, Atividades · **Requisitos:** RF19, RF23, RF27

![Sequência — CRUD de atividade](imagens/06-seq-crud-atividade.svg)

**Pontos de arquitetura demonstrados**
1. **Modelo rico, não anêmico** — quem valida as invariantes e calcula a duração é a entidade `Atividade`, não o controller. A regra de negócio vive no domínio.
2. **Fila outbox para o modo offline** — sem conexão, a operação é gravada localmente e exibida com selo de pendência. O usuário nunca é bloqueado pela rede.
3. **Evento de domínio** — `AtividadeCriadaEvent` dispara o agendamento da notificação de forma desacoplada. O caso de uso de criar atividade não conhece o serviço de notificação.
4. **Atualização otimista com reversão** — ao concluir, a interface risca o item antes da resposta do servidor; se a requisição falhar, o estado é revertido.

---

## SD-05 — Registro de transação financeira
**Caso de uso:** UC13 · **Tela:** Financeiro · **Requisitos:** RF30, RF31

![Sequência — Transação financeira](imagens/07-seq-transacao-financeira.svg)

**Pontos de arquitetura demonstrados**
1. **Bloqueio pessimista (`SELECT … FOR UPDATE`)** — dois lançamentos simultâneos na mesma conta seriam uma condição de corrida clássica. O bloqueio serializa a atualização do saldo.
2. **Atomicidade obrigatória** — inserir a transação e atualizar o saldo ocorrem no mesmo `COMMIT`. Falha em qualquer ponto resulta em `ROLLBACK`: **o saldo jamais fica inconsistente**.
3. **Fonte única do saldo** — quem escreve `saldo_atual` é o gatilho `tg_transacao_saldo`, no banco, e **somente ele**. A entidade `ContaFinanceira` mantém o saldo em memória apenas para validar invariantes dentro do caso de uso. Se a aplicação também emitisse o `UPDATE`, haveria dupla contagem. Com a regra no banco, o saldo permanece correto até para cargas e correções feitas em SQL puro.
4. **Invalidação ativa de cache** — em vez de esperar o TTL expirar, o caso de uso invalida as chaves afetadas. O usuário vê o saldo correto imediatamente.
5. **Verificação de orçamento por evento** — ocorre depois do `COMMIT`, fora do caminho crítico. Se o alerta falhar, o lançamento permanece válido.

---

## SD-06 — Conclusão de importância com geração de transação
**Caso de uso:** UC21 · **Tela:** Importâncias · **Requisitos:** RF47, RF48 · **Regras:** RN13, RN14, RN16

![Sequência — Quitação de importância](imagens/08-seq-importancia-quitacao.svg)

> **Este é o diagrama mais importante do projeto.** Ele materializa o diferencial competitivo do MinhaVida: uma única ação do usuário atravessa três contextos delimitados mantendo consistência total.

**O que acontece em um único toque**
1. A importância é validada e muda para `CONCLUIDA`.
2. Uma `Transacao` de despesa é criada e vinculada em ambos os sentidos.
3. A `ContaFinanceira` é debitada e o saldo atualizado.
4. Se houver recorrência, a ocorrência do mês seguinte é gerada.
5. As notificações pendentes daquela importância são canceladas.
6. O cache do painel é invalidado.

Os passos 1 a 4 estão dentro de **uma única transação de banco**. Os passos 5 e 6 ocorrem depois do `COMMIT`, porque são efeitos colaterais que não podem derrubar a operação principal.

**Fragmento `alt` de idempotência** — tentar concluir uma importância já concluída retorna `409 Conflict`. Sem essa guarda, um duplo toque geraria duas despesas e debitaria a conta duas vezes (RN13).

---

## SD-07 — Processamento de notificações agendadas
**Caso de uso:** UC24 · **Ator:** Agendador · **Requisitos:** RF55, RF56

![Sequência — Notificações](imagens/09-seq-notificacao-agendada.svg)

**Pontos de arquitetura demonstrados**
1. **`FOR UPDATE SKIP LOCKED`** — permite que vários workers consumam a mesma fila em paralelo sem que dois processem a mesma notificação. É o padrão correto de fila sobre banco relacional.
2. **Respeito às preferências** — antes de enviar, o worker consulta `PreferenciaUsuario`. Canal desativado resulta em notificação cancelada, não enviada.
3. **Tratamento diferenciado de falhas** — token inválido desativa o dispositivo; falha temporária agenda nova tentativa com recuo exponencial, até cinco vezes.
4. **Jobs complementares** — 00:05 reclassifica importâncias vencidas · 00:10 marca atividades atrasadas · 07:00 envia o resumo diário · 02:00 materializa o resumo mensal.

---

## SD-08 — Sincronização offline
**Requisitos:** RF59–RF61

![Sequência — Sincronização](imagens/10-seq-sincronizacao-offline.svg)

**Pontos de arquitetura demonstrados**
1. **Idempotência por `idOperacao`** — cada operação carrega um UUID gerado no cliente. Se a resposta se perder e o aplicativo reenviar, o servidor reconhece a operação e devolve o resultado anterior em vez de duplicar o registro. É por isso que as chaves primárias são UUID e não sequenciais (ADR-06).
2. **Sincronização em lote** — uma requisição para N operações, em vez de N requisições.
3. **Resolução de conflito explícita** — política de *última escrita vence* comparando `atualizado_em`, com registro da divergência para auditoria.

---

## DC-01 — Diagrama de comunicação: registro de transação
**Mesmo caso de uso do SD-05, em notação de comunicação**

![Comunicação — Transação](imagens/11-comunicacao-transacao.svg)

**Sequência × Comunicação — qual é a diferença**

| Aspecto | Diagrama de sequência | Diagrama de comunicação |
|---|---|---|
| Ênfase | **quando** — ordem temporal no eixo vertical | **quem fala com quem** — topologia das ligações |
| Ordem | implícita, de cima para baixo | explícita, por numeração (1, 2, 2.1…) |
| Ideal para | fluxos longos com condicionais e paralelismo | avaliar acoplamento e coesão entre objetos |
| Limitação | não evidencia o grau de acoplamento | difícil de ler em fluxos longos |

Os dois são **semanticamente equivalentes** — descrevem a mesma interação com ênfases diferentes. O diagrama de comunicação acima revela algo que o de sequência esconde: `RegistrarTransacaoUseCase` conversa com sete objetos distintos. Esse é o ponto de maior acoplamento do sistema e o primeiro candidato a refatoração caso novas regras sejam agregadas ao lançamento financeiro.

---

## Matriz de rastreabilidade

| Diagrama | Caso de uso | Tela | Requisitos | Regras |
|---|---|---|---|---|
| SD-01 | UC01 | Cadastro | RF01–RF04 | RN23 |
| SD-02 | UC02 | Login | RF05, RF06, RF08 | — |
| SD-03 | UC22 | Início | RF51–RF53 | RN20 |
| SD-04 | UC07, UC10 | Cadastrar atividade, Atividades | RF19, RF23, RF27 | RN01–RN06 |
| SD-05 | UC13 | Financeiro | RF30, RF31 | RN08–RN11 |
| SD-06 | UC21 | Importâncias | RF47, RF48 | RN13, RN14, RN16 |
| SD-07 | UC24 | — | RF55, RF56 | RN07, RN15 |
| SD-08 | — | todas | RF59–RF61 | — |
| DC-01 | UC13 | Financeiro | RF30 | RN09 |
