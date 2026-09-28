# MinhaVida — Diagrama de Classes (UML)

> Fonte: [`diagramas/01-classes-dominio.mmd`](diagramas/01-classes-dominio.mmd) · Imagem: [`imagens/01-classes-dominio.svg`](imagens/01-classes-dominio.svg)

---

## 1. O diagrama

### 1.1 Versão-núcleo (para projeção e leitura rápida)

![Diagrama de Classes — núcleo](imagens/01b-classes-nucleo.svg)

Concentra as 8 classes que sustentam o modelo e todos os tipos de relacionamento UML empregados. É esta a versão que deve ir ao slide.

### 1.2 Versão completa

![Diagrama de Classes do Domínio](imagens/01-classes-dominio.svg)

15 entidades, 1 classe abstrata, 3 objetos de valor e 19 enumerações. Use o arquivo SVG, que é vetorial e suporta ampliação sem perda.

## 2. Como ler este diagrama

| Notação | Significado |
|---|---|
| `-` | visibilidade **privada** (atributo encapsulado) |
| `#` | visibilidade **protegida** (herdada pelas subclasses) |
| `+` | visibilidade **pública** (operação da interface da classe) |
| `◆——` | **composição** — o todo controla o ciclo de vida da parte (excluir o `Usuario` elimina suas `Atividade`s) |
| `◇——` | **agregação** — a parte existe independentemente (uma `Categoria` sobrevive à exclusão de uma `Transacao`) |
| `——▷` | **generalização** (herança) |
| `- - ▷` | **dependência** / realização de interface |
| `«enumeration»` | tipo enumerado |
| `«value object»` | objeto de valor — sem identidade própria, imutável, comparado por valor |
| `«abstract»` | classe abstrata — não instanciável |
| `1`, `0..1`, `0..*` | multiplicidade da associação |

---

## 3. Decisões de modelagem que sustentam o diagrama

### 3.1 Generalização: `ItemAgendavel`
`Atividade` e `Importancia` compartilham um conjunto substancial de atributos (título, descrição, categoria, prioridade, recorrência, lembrete) **e** de comportamento (`concluir()`, `cancelar()`, `estaAtrasado()`). A superclasse abstrata `ItemAgendavel` captura essa comunalidade e permite que o agendador de notificações trate as duas de forma polimórfica.

O mapeamento no banco é *table per concrete class*: duas tabelas independentes, sem JOIN obrigatório em cada leitura. A abstração existe no código; o esquema permanece plano e rápido.

### 3.2 Por que Receita e Despesa **não** são subclasses
Ambas teriam exatamente os mesmos atributos e a única diferença seria o sinal aplicado ao saldo. Herança sem comportamento divergente é complexidade sem retorno. A distinção é feita pelo enum `TipoMovimento`, e o polimorfismo necessário fica encapsulado em `Transacao.valorComSinal()`. (Ver ADR-02.)

### 3.3 Composite em `Categoria`
As telas mostram "Estudo • Faculdade" e "Pessoal • Saúde": há hierarquia de categoria e subcategoria. Em vez de duas tabelas, `Categoria` se auto-relaciona por `categoriaPaiId` (0..1 → 0..*), o padrão **Composite**. O discriminador `escopo` separa os três universos de categoria — atividade, financeiro e importância — sem triplicar a estrutura.

### 3.4 Objetos de valor
`Dinheiro`, `Email` e `PeriodoTempo` eliminam a *primitive obsession*. `Dinheiro` carrega valor **e** moeda juntos, tornando impossível somar reais com dólares por acidente, e concentra o arredondamento em um único ponto do sistema.

### 3.5 Agregados e fronteiras de consistência
| Agregado raiz | Membros | Regra |
|---|---|---|
| `Usuario` | `PreferenciaUsuario`, `Sessao`, `CredencialSocial`, `DispositivoUsuario` | só se acessa pelo usuário |
| `Atividade` | — | consistência própria |
| `Importancia` | — | referencia `Transacao` por identidade |
| `ContaFinanceira` | `Transacao` | saldo e lançamento alterados na mesma transação de banco |

Referências **entre** agregados são sempre por identificador (`transacaoId`), nunca por objeto — o que mantém as fronteiras transacionais explícitas.

---

## 4. Dicionário de atributos por entidade

Tipos expressos na notação UML/conceitual. O mapeamento para tipos PostgreSQL está em [`07-DICIONARIO-DE-DADOS.md`](07-DICIONARIO-DE-DADOS.md).

### 4.1 `Usuario` — *raiz do agregado de identidade*
Origem: telas **Cadastro**, **Login** e **Perfil**.

| # | Atributo | Tipo | Obrig. | Regra / origem |
|---|---|---|---|---|
| 1 | `id` | UUID | sim | Identificador. UUID v4, gerado pela aplicação |
| 2 | `nomeCompleto` | String(120) | sim | Campo "Nome completo" da tela de cadastro |
| 3 | `nomeUsuario` | String(40) | sim | Único. Permite o login por "nome de usuário" da tela de login. Derivado do e-mail no cadastro |
| 4 | `email` | Email (VO) | sim | Único, normalizado em minúsculas |
| 5 | `senhaHash` | String(255) | não | bcrypt custo 12. Nulo quando a conta é exclusivamente social |
| 6 | `telefone` | String(20) | não | "Informações pessoais: nome, e-mail, telefone e mais" |
| 7 | `dataNascimento` | LocalDate | sim | Campo da tela de cadastro. Valida idade mínima de 13 anos (RN23) |
| 8 | `urlFotoPerfil` | String(500) | não | Avatar com ícone de câmera na tela de perfil |
| 9 | `status` | StatusUsuario | sim | `PENDENTE_VERIFICACAO` no cadastro → `ATIVO` |
| 10 | `emailVerificado` | Boolean | sim | Padrão `false` |
| 11 | `aceiteTermos` | Boolean | sim | Checkbox obrigatório da tela de cadastro |
| 12 | `versaoTermosAceita` | String(20) | sim | Versão do documento aceito — exigência de conformidade |
| 13 | `dataAceiteTermos` | DateTime | sim | Prova de consentimento (LGPD, art. 8º) |
| 14 | `dataCadastro` | DateTime | sim | Exibido como "Usuário desde 01/08/2025" |
| 15 | `ultimoAcesso` | DateTime | não | Atualizado a cada login bem-sucedido |
| 16 | `criadoEm` / `atualizadoEm` | DateTime | sim | Auditoria técnica |
| 17 | `excluidoEm` | DateTime | não | Exclusão lógica |

**Operações:** `autenticar(senha)` · `alterarSenha(atual, nova)` · `atualizarPerfil(dados)` · `registrarAcesso()` · `desativarConta()` · `idade()`

### 4.2 `PreferenciaUsuario` — 1:1 com `Usuario`
Origem: tela **Perfil** (Tema, Idioma, Notificações).

| # | Atributo | Tipo | Padrão | Regra / origem |
|---|---|---|---|---|
| 1 | `id` | UUID | — | Identificador |
| 2 | `usuarioId` | UUID | — | Chave estrangeira única |
| 3 | `tema` | TemaApp | `ESCURO` | Alternador claro/escuro. O protótipo é predominantemente escuro |
| 4 | `idioma` | String(10) | `pt-BR` | "Idioma — Português (BR)" |
| 5 | `moeda` | String(3) | `BRL` | Prepara internacionalização futura |
| 6 | `fusoHorario` | String(50) | `America/Sao_Paulo` | Base para o cálculo de "hoje" e dos vencimentos |
| 7 | `notificacaoPush` | Boolean | `true` | "Configure suas preferências de alerta" |
| 8 | `notificacaoEmail` | Boolean | `true` | Canal alternativo |
| 9 | `notificarAtividades` | Boolean | `true` | Lembrete de atividade |
| 10 | `notificarImportancias` | Boolean | `true` | Alerta de vencimento |
| 11 | `antecedenciaLembreteMin` | Integer | `30` | Minutos antes do início da atividade |
| 12 | `diasAntecedenciaImportancia` | Integer | `3` | Dias antes do vencimento |
| 13 | `resumoDiarioAtivo` | Boolean | `false` | Resumo do dia por push |
| 14 | `horaResumoDiario` | LocalTime | `07:00` | Horário do resumo |
| 15 | `atualizadoEm` | DateTime | — | Auditoria |

### 4.3 `CredencialSocial` — login federado
Origem: botão **"Entrar com o Google"**.

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Chave estrangeira |
| 3 | `provedor` | ProvedorOAuth | `GOOGLE`, `APPLE` |
| 4 | `idProvedor` | String(255) | `sub` do token OIDC. Único por provedor |
| 5 | `emailProvedor` | String(255) | E-mail retornado pelo provedor |
| 6 | `vinculadoEm` | DateTime | Data do vínculo |

### 4.4 `Sessao` — controle de acesso
Origem: **"Lembrar de mim"** e **"Sair da conta"**.

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Chave estrangeira |
| 3 | `refreshTokenHash` | String(255) | Somente o hash SHA-256 é persistido |
| 4 | `dispositivo` | String(120) | Modelo do aparelho |
| 5 | `sistemaOperacional` | String(50) | Ex.: `Android 14` |
| 6 | `appVersao` | String(20) | Versão do aplicativo |
| 7 | `enderecoIp` | String(45) | Suporta IPv6 |
| 8 | `userAgent` | String(255) | Identificação do cliente |
| 9 | `lembrarDeMim` | Boolean | Define a validade: 7 dias (falso) ou 90 dias (verdadeiro) |
| 10 | `criadaEm` / `expiraEm` | DateTime | Janela de validade |
| 11 | `revogadaEm` | DateTime | Preenchido no logout |
| 12 | `ultimaAtividadeEm` | DateTime | Detecção de sessão ociosa |

### 4.5 `TokenRecuperacaoSenha`
Origem: **"Esqueceu a senha?"**.

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Chave estrangeira |
| 3 | `tokenHash` | String(255) | Token aleatório de 256 bits, persistido com hash |
| 4 | `criadoEm` | DateTime | Emissão |
| 5 | `expiraEm` | DateTime | Validade de 30 minutos |
| 6 | `usadoEm` | DateTime | Uso único — nulo enquanto não consumido |
| 7 | `enderecoIp` | String(45) | Origem da solicitação |

### 4.6 `DispositivoUsuario` — destino das notificações

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Chave estrangeira |
| 3 | `tokenPush` | String(255) | Token do Firebase Cloud Messaging. Único |
| 4 | `plataforma` | Plataforma | `ANDROID`, `IOS`, `WEB` |
| 5 | `modelo` | String(120) | Modelo do aparelho |
| 6 | `versaoApp` | String(20) | Versão instalada |
| 7 | `ativo` | Boolean | Desativado quando o FCM responde `UNREGISTERED` |
| 8 | `registradoEm` / `ultimoUsoEm` | DateTime | Ciclo de vida |

### 4.7 `Categoria` — classificação unificada (Composite)
Origem: filtros **Trabalho/Estudo/Pessoal/Lazer**, categorias financeiras **Alimentação/Transporte/Moradia/Compras/Outros** e etiquetas de importância **Contas/Compras/Veículo/Lazer/Saúde**.

| # | Atributo | Tipo | Obrig. | Regra |
|---|---|---|---|---|
| 1 | `id` | UUID | sim | Identificador |
| 2 | `usuarioId` | UUID | não | Nulo = categoria padrão do sistema, visível a todos |
| 3 | `categoriaPaiId` | UUID | não | Auto-relacionamento. Nulo = categoria raiz |
| 4 | `nome` | String(60) | sim | Único por (usuário, escopo, pai) |
| 5 | `escopo` | EscopoCategoria | sim | `ATIVIDADE`, `FINANCEIRO`, `IMPORTANCIA` |
| 6 | `tipoMovimento` | TipoMovimento | não | Só para escopo financeiro: se a categoria serve a receita, despesa ou ambos |
| 7 | `corHex` | String(7) | sim | Cor do ícone na interface (`#22C55E`) |
| 8 | `icone` | String(50) | sim | Identificador do ícone (`cart`, `car`, `home`) |
| 9 | `padraoSistema` | Boolean | sim | Impede exclusão pelo usuário (RN17) |
| 10 | `ativa` | Boolean | sim | Inativação lógica preserva o histórico |
| 11 | `ordemExibicao` | Integer | sim | Ordem na interface |
| 12 | `criadoEm` / `atualizadoEm` | DateTime | sim | Auditoria |

### 4.8 `Atividade` — CRUD da lista de tarefas
Origem: telas **Atividades** e **Cadastrar atividade**. Herda de `ItemAgendavel`.

| # | Atributo | Tipo | Obrig. | Regra / origem |
|---|---|---|---|---|
| 1 | `id` | UUID | sim | Identificador |
| 2 | `usuarioId` | UUID | sim | Proprietário. Filtro obrigatório (RN21) |
| 3 | `categoriaId` | UUID | não | "Categoria" — Trabalho, Estudo, Pessoal, Lazer |
| 4 | `subcategoriaId` | UUID | não | Segundo nível: "Estudo • **Faculdade**" |
| 5 | `titulo` | String(120) | **sim** | "Título da atividade *" — 3 a 120 caracteres (RN01) |
| 6 | `descricao` | String(200) | não | "Descrição (opcional)" — contador 0/200 (RN02) |
| 7 | `dataAtividade` | LocalDate | sim | "Data — 29/09/2025" |
| 8 | `horaInicio` | LocalTime | não | "Horário — 09:00" |
| 9 | `horaFim` | LocalTime | não | Deve ser maior que `horaInicio` (RN03) |
| 10 | `duracaoMinutos` | Integer | não | **Derivado**. Alimenta o indicador "Tempo total 18h45min" (RN04) |
| 11 | `prioridade` | Prioridade | sim | "Prioridade — Baixa/Média/Alta/Urgente" |
| 12 | `status` | StatusAtividade | sim | Etiqueta "Concluída" / "Pendente" |
| 13 | `concluidaEm` | DateTime | não | Preenchido ao marcar o checkbox |
| 14 | `lembreteAtivo` | Boolean | sim | Padrão `true` |
| 15 | `minutosAntesLembrete` | Integer | não | Sobrepõe a preferência global |
| 16 | `regraRecorrenciaId` | UUID | não | "Repetir (opcional)" |
| 17 | `atividadeOrigemId` | UUID | não | Aponta para a atividade-modelo, quando gerada por recorrência |
| 18 | `ordem` | Integer | não | Reordenação manual na lista |
| 19 | `criadoEm` / `atualizadoEm` | DateTime | sim | Auditoria |
| 20 | `excluidoEm` | DateTime | não | Exclusão lógica (RN22) |

**Operações:** `concluir()` · `reabrir()` · `cancelar()` · `reagendar(data, hora)` · `calcularDuracao()` · `conflitaCom(outra)`

### 4.9 `Importancia` — compromissos e datas importantes
Origem: tela **Importâncias**. Herda de `ItemAgendavel`.

| # | Atributo | Tipo | Obrig. | Regra / origem |
|---|---|---|---|---|
| 1 | `id` | UUID | sim | Identificador |
| 2 | `usuarioId` | UUID | sim | Proprietário |
| 3 | `categoriaId` | UUID | sim | Etiqueta: Contas, Compras, Veículo, Lazer, Saúde |
| 4 | `titulo` | String(120) | sim | "Pagamento da internet" |
| 5 | `origem` | String(120) | não | Fornecedor: "Vivo Fibra", "Detran", "Netflix", "Energisa" |
| 6 | `descricao` | String(300) | não | Observações |
| 7 | `dataVencimento` | LocalDate | sim | "Dia 29/09/2025". Base do agrupamento e dos alertas |
| 8 | `valor` | Dinheiro | não | "R$ 99,90". Nulo em compromissos sem valor |
| 9 | `tipo` | TipoImportancia | sim | `CONTA_A_PAGAR`, `CONTA_A_RECEBER`, `COMPROMISSO`, `DATA_COMEMORATIVA` |
| 10 | `status` | StatusImportancia | sim | Define o agrupamento Hoje / Próximos / Concluídos |
| 11 | `prioridade` | Prioridade | sim | Influencia a ordenação |
| 12 | `concluidaEm` | DateTime | não | Item exibido riscado quando preenchido |
| 13 | `transacaoId` | UUID | não | Transação gerada na quitação (RN14) |
| 14 | `gerarTransacaoAoConcluir` | Boolean | sim | Padrão `true` para contas. **Este campo é o coração da integração entre os módulos** |
| 15 | `diasAntecedenciaAlerta` | Integer | sim | Padrão 3. Sobrepõe a preferência global |
| 16 | `lembreteAtivo` | Boolean | sim | Habilita a notificação |
| 17 | `regraRecorrenciaId` | UUID | não | Conta mensal recorrente |
| 18 | `criadoEm` / `atualizadoEm` | DateTime | sim | Auditoria |
| 19 | `excluidoEm` | DateTime | não | Exclusão lógica |

**Atributo derivado:** `diasRestantes()` = `dataVencimento − hoje` → exibido como "Em 6 dias".
**Operações:** `concluir(contaId)` · `cancelar()` · `diasRestantes()` · `estaVencida()` · `classificarUrgencia()`

### 4.10 `RegraRecorrencia`
Origem: campo **"Repetir (opcional)"**.

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `frequencia` | Frequencia | `DIARIA`, `SEMANAL`, `QUINZENAL`, `MENSAL`, `ANUAL`, `PERSONALIZADA` |
| 3 | `intervalo` | Integer | "a cada N períodos". Padrão 1 |
| 4 | `diasSemana` | List\<DiaSemana\> | Para frequência semanal: seg, qua, sex |
| 5 | `diaDoMes` | Integer | Para frequência mensal: todo dia 5 |
| 6 | `dataInicio` | LocalDate | Início da série |
| 7 | `dataFim` | LocalDate | Fim opcional |
| 8 | `ocorrenciasMax` | Integer | Limite alternativo por quantidade |
| 9 | `ocorrenciasGeradas` | Integer | Contador de controle |
| 10 | `proximaOcorrencia` | LocalDate | Calculado — otimiza a consulta do agendador |
| 11 | `ativa` | Boolean | Permite interromper a série |

### 4.11 `ContaFinanceira`
Origem: card **"Saldo atual R$ 1.220,35"**.

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Proprietário |
| 3 | `nome` | String(80) | "Carteira", "Nubank" |
| 4 | `tipo` | TipoConta | `CARTEIRA`, `CORRENTE`, `POUPANCA`, `CARTAO_CREDITO`, `INVESTIMENTO` |
| 5 | `instituicao` | String(80) | Banco emissor |
| 6 | `saldoInicial` | Dinheiro | Saldo na abertura da conta no aplicativo |
| 7 | `saldoAtual` | Dinheiro | **Derivado materializado** — sempre reconciliável (ADR-05, RN10) |
| 8 | `moeda` | String(3) | Padrão `BRL` |
| 9 | `corHex` / `icone` | String | Identidade visual |
| 10 | `incluirNoSaldoTotal` | Boolean | Permite excluir investimentos do saldo do dia a dia |
| 11 | `ativa` | Boolean | Inativação lógica |
| 12 | `criadoEm` / `atualizadoEm` | DateTime | Auditoria |

### 4.12 `Transacao` — movimentação financeira
Origem: **"Últimas movimentações"** e **"Atividades recentes"**.

| # | Atributo | Tipo | Obrig. | Regra / origem |
|---|---|---|---|---|
| 1 | `id` | UUID | sim | Identificador |
| 2 | `usuarioId` | UUID | sim | Proprietário |
| 3 | `contaId` | UUID | sim | Conta movimentada |
| 4 | `categoriaId` | UUID | sim | Alimentação, Transporte, Moradia, Compras, Outros |
| 5 | `importanciaId` | UUID | não | Preenchido quando a transação quita uma importância |
| 6 | `descricao` | String(120) | sim | "Salário", "Mercado", "Uber", "Restaurante" |
| 7 | `tipo` | TipoMovimento | sim | `RECEITA`, `DESPESA`, `TRANSFERENCIA` |
| 8 | `valor` | Dinheiro | sim | Sempre positivo; o sinal vem do tipo (RN08) |
| 9 | `dataMovimento` | LocalDate | sim | Data exibida na lista |
| 10 | `dataCompetencia` | LocalDate | sim | Regime de competência para relatórios. Padrão igual ao movimento |
| 11 | `formaPagamento` | FormaPagamento | não | `DINHEIRO`, `PIX`, `DEBITO`, `CREDITO`, `BOLETO`, `TRANSFERENCIA` |
| 12 | `situacao` | SituacaoTransacao | sim | Só `EFETIVADA` afeta o saldo (RN11) |
| 13 | `observacao` | String(300) | não | Texto livre |
| 14 | `urlComprovante` | String(500) | não | Anexo no S3 |
| 15 | `regraRecorrenciaId` | UUID | não | Lançamento recorrente |
| 16 | `transacaoOrigemId` | UUID | não | Aponta para a 1ª parcela ou para a transação estornada |
| 17 | `parcelaNumero` / `parcelaTotal` | Integer | não | "3/12" |
| 18 | `criadoEm` / `atualizadoEm` | DateTime | sim | Auditoria |
| 19 | `excluidoEm` | DateTime | não | Exclusão lógica |

**Operações:** `efetivar()` · `cancelar()` · `estornar()` · `valorComSinal()` · `ehParcelada()`

### 4.13 `Orcamento`

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Proprietário |
| 3 | `categoriaId` | UUID | Categoria limitada |
| 4 | `mesReferencia` | String(7) | Formato `2025-09`. Único por (usuário, categoria, mês) |
| 5 | `valorLimite` | Dinheiro | Teto planejado |
| 6 | `valorGasto` | Dinheiro | Derivado das transações do mês |
| 7 | `percentualAlerta` | Integer | Padrão 80% |
| 8 | `ativo` | Boolean | Habilita o alerta |

### 4.14 `Notificacao`
Origem: **sino com indicador** no cabeçalho.

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Destinatário |
| 3 | `titulo` | String(120) | Título exibido |
| 4 | `mensagem` | String(300) | Corpo |
| 5 | `tipo` | TipoNotificacao | `LEMBRETE_ATIVIDADE`, `VENCIMENTO_IMPORTANCIA`, `RESUMO_DIARIO`, `ALERTA_ORCAMENTO`, `SISTEMA` |
| 6 | `canal` | CanalNotificacao | `PUSH`, `EMAIL`, `IN_APP` |
| 7 | `entidadeRelacionadaTipo` | String(40) | Referência polimórfica: `ATIVIDADE` ou `IMPORTANCIA` |
| 8 | `entidadeRelacionadaId` | UUID | Identificador do item de origem |
| 9 | `agendadaPara` | DateTime | Momento programado de envio |
| 10 | `enviadaEm` | DateTime | Confirmação de envio |
| 11 | `lidaEm` | DateTime | Nulo = não lida (alimenta o indicador do sino) |
| 12 | `status` | StatusNotificacao | `AGENDADA`, `ENVIADA`, `LIDA`, `FALHA`, `CANCELADA` |
| 13 | `tentativas` | Integer | Controle de reenvio com recuo exponencial |

### 4.15 `LogAuditoria`

| # | Atributo | Tipo | Regra |
|---|---|---|---|
| 1 | `id` | UUID | Identificador |
| 2 | `usuarioId` | UUID | Autor da ação |
| 3 | `acao` | String(60) | `CRIAR`, `ATUALIZAR`, `EXCLUIR`, `LOGIN`, `ALTERAR_SENHA` |
| 4 | `entidade` | String(60) | Nome da entidade afetada |
| 5 | `entidadeId` | UUID | Registro afetado |
| 6 | `dadosAnteriores` | JSON | Estado anterior (sem campos sensíveis) |
| 7 | `dadosNovos` | JSON | Estado posterior |
| 8 | `enderecoIp` | String(45) | Origem |
| 9 | `ocorridoEm` | DateTime | Data e hora do evento |

---

## 5. Objetos de valor

### `Email`
| Atributo | Tipo | Regra |
|---|---|---|
| `valor` | String(255) | Validado por expressão regular; normalizado em minúsculas |

Operações: `validar()` · `dominio()`

### `Dinheiro`
| Atributo | Tipo | Regra |
|---|---|---|
| `valor` | Decimal(15,2) | Nunca ponto flutuante binário — evita erro de arredondamento monetário |
| `moeda` | String(3) | ISO 4217 |

Operações: `somar()` · `subtrair()` · `negativo()` · `formatar()` → `R$ 1.234,56`

### `PeriodoTempo`
| Atributo | Tipo | Regra |
|---|---|---|
| `inicio` | LocalTime | Hora inicial |
| `fim` | LocalTime | Deve ser posterior ao início |

Operações: `duracaoMinutos()` · `sobrepoe(outro)`

---

## 6. Enumerações

| Enumeração | Valores |
|---|---|
| `StatusUsuario` | ATIVO · INATIVO · BLOQUEADO · PENDENTE_VERIFICACAO |
| `StatusAtividade` | PENDENTE · EM_ANDAMENTO · CONCLUIDA · ATRASADA · CANCELADA |
| `StatusImportancia` | PENDENTE · VENCENDO_HOJE · ATRASADA · CONCLUIDA · CANCELADA |
| `Prioridade` | BAIXA · MEDIA · ALTA · URGENTE |
| `EscopoCategoria` | ATIVIDADE · FINANCEIRO · IMPORTANCIA |
| `TipoMovimento` | RECEITA · DESPESA · TRANSFERENCIA |
| `SituacaoTransacao` | PENDENTE · EFETIVADA · CANCELADA |
| `FormaPagamento` | DINHEIRO · PIX · DEBITO · CREDITO · BOLETO · TRANSFERENCIA |
| `TipoImportancia` | CONTA_A_PAGAR · CONTA_A_RECEBER · COMPROMISSO · DATA_COMEMORATIVA |
| `TipoConta` | CARTEIRA · CORRENTE · POUPANCA · CARTAO_CREDITO · INVESTIMENTO |
| `Frequencia` | DIARIA · SEMANAL · QUINZENAL · MENSAL · ANUAL · PERSONALIZADA |
| `DiaSemana` | DOM · SEG · TER · QUA · QUI · SEX · SAB |
| `TemaApp` | CLARO · ESCURO · SISTEMA |
| `ProvedorOAuth` | GOOGLE · APPLE |
| `Plataforma` | ANDROID · IOS · WEB |
| `TipoNotificacao` | LEMBRETE_ATIVIDADE · VENCIMENTO_IMPORTANCIA · RESUMO_DIARIO · ALERTA_ORCAMENTO · SISTEMA |
| `CanalNotificacao` | PUSH · EMAIL · IN_APP |
| `StatusNotificacao` | AGENDADA · ENVIADA · LIDA · FALHA · CANCELADA |
| `NivelUrgencia` | NORMAL · ATENCAO · CRITICO · VENCIDO |

---

## 7. Diagrama de classes de projeto (camadas e inversão de dependência)

![Classes por camada](imagens/02-classes-camadas.svg)

Este segundo diagrama mostra as **classes de projeto** — controllers, casos de uso, repositórios e adaptadores — e evidencia a inversão de dependência: o domínio declara a interface `IAtividadeRepository` e a infraestrutura fornece `AtividadeRepositoryPrisma`. Trocar Prisma por TypeORM não altera uma linha do domínio.

---

## 8. Resumo quantitativo

| Elemento | Quantidade |
|---|---|
| Entidades de domínio | 15 |
| Classe abstrata | 1 (`ItemAgendavel`) |
| Objetos de valor | 3 |
| Enumerações | 19 |
| Associações | 28 |
| Atributos mapeados | 187 |
