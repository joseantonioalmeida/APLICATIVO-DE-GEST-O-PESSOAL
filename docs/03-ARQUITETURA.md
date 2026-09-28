# MinhaVida — Arquitetura de Software

---

## 1. Visão geral da arquitetura

O MinhaVida adota **Arquitetura Limpa (Clean Architecture)** com **monólito modular** no backend e **MVVM + Clean** no aplicativo mobile. A regra que sustenta todo o desenho é a **Regra da Dependência**: o código-fonte só aponta para dentro. O domínio não conhece banco de dados, framework HTTP nem provedor de nuvem.

```
        ┌──────────────────────────────────────────────┐
        │  Frameworks e Drivers (Infraestrutura)       │
        │  Prisma · Redis · FCM · S3 · SES · Express   │
        │   ┌──────────────────────────────────────┐   │
        │   │  Adaptadores de Interface             │  │
        │   │  Controllers · Presenters · Gateways  │  │
        │   │   ┌──────────────────────────────┐    │  │
        │   │   │  Casos de Uso (Aplicação)    │    │  │
        │   │   │   ┌──────────────────────┐   │    │  │
        │   │   │   │  Entidades (Domínio) │   │    │  │
        │   │   │   │  Regras de negócio   │   │    │  │
        │   │   │   └──────────────────────┘   │    │  │
        │   │   └──────────────────────────────┘    │  │
        │   └──────────────────────────────────────┘   │
        └──────────────────────────────────────────────┘
                 ──── direção das dependências ────▶
```

### Por que monólito modular e não microsserviços

| Critério | Monólito modular | Microsserviços |
|---|---|---|
| Complexidade operacional | Baixa — 2 artefatos | Alta — malha de serviços, observabilidade distribuída |
| Consistência transacional | ACID nativo (`Importancia` + `Transacao` + saldo no mesmo COMMIT) | Exige saga / consistência eventual |
| Custo de nuvem | 1 cluster pequeno | N serviços, N bancos |
| Adequação ao time e ao prazo | **Alta** | Baixa |

O domínio **exige atomicidade** entre quitar uma importância, criar a transação e atualizar o saldo. Fragmentar isso em serviços introduziria consistência eventual sem nenhum ganho real de escala. A modularização interna por *bounded context* mantém a porta aberta para extrair um módulo no futuro, caso a escala justifique.

---

## 2. Contextos delimitados (Bounded Contexts)

| Contexto | Responsabilidade | Agregado raiz |
|---|---|---|
| **Identidade e Acesso** | Cadastro, autenticação, sessões, recuperação de senha, credenciais sociais | `Usuario` |
| **Produtividade** | Atividades, recorrências, conclusão, indicadores de progresso | `Atividade` |
| **Financeiro** | Contas, transações, categorias financeiras, orçamentos, consolidação mensal | `Transacao`, `ContaFinanceira` |
| **Compromissos** | Importâncias, vencimentos, quitação integrada | `Importancia` |
| **Notificação** | Agendamento, entrega multicanal, preferências | `Notificacao` |
| **Insights** | Dashboard, relatórios, resumos consolidados (somente leitura) | *read models* |

Comunicação entre contextos: **síncrona** por interface de serviço dentro do processo, **assíncrona** por eventos de domínio (`TransacaoRegistradaEvent`, `ImportanciaConcluidaEvent`, `AtividadeCriadaEvent`) para efeitos colaterais — notificações, orçamento, consolidação.

---

## 3. Arquitetura do backend

### 3.1 Camadas

| Camada | Pasta | Responsabilidade | Pode depender de |
|---|---|---|---|
| **Apresentação** | `src/presentation` | Controllers REST, DTOs de entrada/saída, validadores, guards, filtros de exceção, documentação OpenAPI | Aplicação |
| **Aplicação** | `src/application` | Casos de uso, orquestração, transações, portas (interfaces) para infraestrutura | Domínio |
| **Domínio** | `src/domain` | Entidades, objetos de valor, enumerações, serviços de domínio, eventos, interfaces de repositório | **nada** |
| **Infraestrutura** | `src/infrastructure` | Implementações de repositório (Prisma), cache, filas, provedores externos, migrações | Domínio, Aplicação |

### 3.2 Estrutura de diretórios sugerida

```
minhavida-api/
├── src/
│   ├── domain/
│   │   ├── entities/            Usuario, Atividade, Transacao, Importancia, ContaFinanceira…
│   │   ├── value-objects/       Email, Dinheiro, PeriodoTempo
│   │   ├── enums/               StatusAtividade, TipoMovimento, Prioridade…
│   │   ├── events/              AtividadeConcluidaEvent, TransacaoRegistradaEvent…
│   │   ├── services/            RecorrenciaService, CalculadoraSaldo
│   │   └── repositories/        IUsuarioRepository, IAtividadeRepository… (interfaces)
│   ├── application/
│   │   ├── use-cases/
│   │   │   ├── auth/            RegistrarUsuario, AutenticarUsuario, RecuperarSenha
│   │   │   ├── atividade/       CriarAtividade, ListarAtividades, ConcluirAtividade…
│   │   │   ├── financeiro/      RegistrarTransacao, ObterResumoMensal…
│   │   │   ├── importancia/     CadastrarImportancia, ConcluirImportancia…
│   │   │   └── dashboard/       ObterResumoDiario
│   │   ├── dtos/
│   │   └── ports/               IHashProvider, ITokenProvider, IPushProvider, IStorageProvider
│   ├── infrastructure/
│   │   ├── database/prisma/     schema.prisma, migrations, repositórios concretos
│   │   ├── cache/               RedisCacheService
│   │   ├── queue/               BullMQ — filas e workers
│   │   ├── providers/           BcryptHash, JwtToken, FcmPush, S3Storage, SesMail, GoogleOAuth
│   │   └── config/              variáveis de ambiente validadas
│   ├── presentation/
│   │   ├── controllers/         AuthController, AtividadeController, TransacaoController…
│   │   ├── middlewares/         JwtAuthGuard, RateLimit, RequestId, Logger
│   │   ├── filters/             FiltroGlobalDeExcecoes
│   │   └── docs/                OpenAPI 3.1
│   └── main.ts
├── test/                        unitários · integração · e2e
├── prisma/
├── docker-compose.yml
└── Dockerfile
```

### 3.3 Padrões de projeto aplicados

| Padrão | Onde | Por quê |
|---|---|---|
| **Repository** | `IAtividadeRepository` → `AtividadeRepositoryPrisma` | Isola o domínio da tecnologia de persistência |
| **Use Case / Interactor** | `ConcluirImportanciaUseCase` | Uma classe por intenção do usuário; testável isoladamente |
| **DTO** | entrada e saída dos controllers | Impede vazamento de entidade de domínio para a borda |
| **Factory** | `Atividade.criar(dto)` | Centraliza a validação de invariantes na construção |
| **Strategy** | `RecorrenciaService` por `Frequencia` | Cada frequência calcula a próxima ocorrência à sua maneira |
| **Observer / Event Bus** | eventos de domínio | Desacopla efeitos colaterais do fluxo principal |
| **Unit of Work** | `GerenciadorTransacional` | Garante atomicidade entre múltiplos repositórios |
| **Specification** | filtros de atividades e transações | Compõe critérios de consulta sem inchar o repositório |
| **Value Object** | `Dinheiro`, `Email`, `PeriodoTempo` | Elimina obsessão por tipos primitivos e concentra a validação |
| **Composite** | `Categoria` auto-relacionada | Representa categoria e subcategoria na mesma estrutura |
| **Adapter** | provedores externos (FCM, S3, SES) | Troca de fornecedor sem tocar no domínio |
| **CQRS leve** | `ResumoFinanceiroMensal` como *read model* | Separa consulta pesada da escrita transacional |

---

## 4. Arquitetura do aplicativo mobile

### 4.1 Camadas (MVVM + Clean)

```
View (Screens/Components)        ← React Native + TypeScript
   ↓ eventos            ↑ estado
ViewModel (hooks/stores)         ← Zustand + TanStack Query
   ↓
Use Cases                        ← regras de apresentação e orquestração
   ↓
Repository (interface)
   ├── RemoteDataSource  → ApiClient (Axios + interceptor de refresh)
   └── LocalDataSource   → SQLite/WatermelonDB (cache + fila outbox)
```

### 4.2 Estratégia offline-first

1. **Leitura** — a tela renderiza primeiro a partir do SQLite local e só depois reconcilia com a resposta da API (*stale-while-revalidate*).
2. **Escrita** — a operação é aplicada localmente de imediato (*optimistic update*) e gravada na **fila outbox** com um `idOperacao` (UUID) próprio.
3. **Sincronização** — ao detectar conexão, o `ServicoSincronizacao` envia o lote para `POST /sync/lote`. O `idOperacao` garante **idempotência**: reenvios não duplicam dados.
4. **Conflito** — resolvido por *última escrita vence*, comparando `atualizado_em`; a divergência é registrada para auditoria.

### 4.3 Estrutura de pastas

```
minhavida-app/
├── src/
│   ├── presentation/  screens/ (Login, Cadastro, Home, Atividades, Financeiro, Importancias, Perfil)
│   │                  components/ · navigation/ · theme/ (tokens claro e escuro)
│   ├── application/   viewmodels/ · use-cases/
│   ├── domain/        entities/ · enums/ (espelham o backend)
│   ├── infrastructure/ api/ · database/ · storage/ · notifications/
│   └── shared/        hooks/ · utils/ (formatadores de moeda e data) · i18n/
```

---

## 5. Decisões arquiteturais (ADR)

### ADR-01 — Monólito modular em vez de microsserviços
**Contexto:** equipe pequena, prazo acadêmico, domínio com forte acoplamento transacional.
**Decisão:** monólito modular com fronteiras internas explícitas por contexto.
**Consequências:** (+) simplicidade operacional, ACID nativo, custo baixo. (−) escala apenas vertical dentro de um artefato; mitigado pelo autoescalonamento horizontal de réplicas sem estado.

### ADR-02 — Enum discriminador em vez de herança para Receita/Despesa
**Contexto:** `Transacao` poderia ser modelada com generalização `Movimentacao ← Receita | Despesa`.
**Decisão:** manter uma única classe `Transacao` com o enum `tipo: TipoMovimento`.
**Justificativa:** receita e despesa possuem **exatamente os mesmos atributos** e diferem apenas no sinal aplicado ao saldo. Herança aqui geraria duas tabelas (ou uma tabela com discriminador de qualquer forma) sem nenhum comportamento polimórfico real — complexidade sem contrapartida. A herança foi reservada para `ItemAgendavel`, onde há de fato comportamento divergente.
**Consequências:** (+) consultas e índices mais simples, um único repositório. (−) um `switch` no cálculo do saldo, encapsulado em `valorComSinal()`.

### ADR-03 — Generalização `ItemAgendavel` para Atividade e Importância
**Contexto:** ambas possuem título, descrição, categoria, prioridade, recorrência, lembrete e ciclo de conclusão.
**Decisão:** classe abstrata `ItemAgendavel` com os atributos e operações comuns; `Atividade` e `Importancia` especializam.
**Justificativa:** há comportamento genuinamente polimórfico — `concluir()`, `dataReferencia()` e `estaAtrasado()` têm implementações distintas e o agendador de notificações trata as duas de forma uniforme.
**Mapeamento no banco:** *table per concrete class* — duas tabelas independentes, sem JOIN em toda leitura. A abstração vive no código, não no esquema.

### ADR-04 — Categoria unificada com escopo e auto-relacionamento
**Contexto:** as telas exibem três conjuntos de categorias (atividade, financeiro, importância) e ainda o par "Categoria • Subcategoria".
**Decisão:** uma entidade `Categoria` com o discriminador `escopo` e auto-relacionamento `categoriaPaiId` (padrão Composite).
**Consequências:** (+) uma tabela, uma tela de gestão, um repositório; hierarquia de profundidade arbitrária. (−) exige a regra RN19 para impedir hierarquia entre escopos diferentes.

### ADR-05 — `saldoAtual` materializado na conta
**Contexto:** somar todas as transações a cada abertura do painel seria O(n) e cresceria indefinidamente.
**Decisão:** manter `saldoAtual` como coluna, escrita **exclusivamente** pelo gatilho `tg_transacao_saldo` na mesma transação do lançamento, com `fn_recalcular_saldo()` disponível para reconciliação.
**Fonte única da verdade:** a camada de aplicação nunca emite `UPDATE … SET saldo_atual`. A entidade `ContaFinanceira` mantém o saldo em memória apenas para validar invariantes. Se os dois escrevessem, haveria dupla contagem.
**Consequências:** (+) leitura O(1) e saldo correto mesmo em cargas feitas por SQL puro. (−) regra de negócio no banco, menos testável em memória; mitigado por testes de integração com banco real em contêiner e por job noturno de conferência.

### ADR-06 — UUID v4 como chave primária
**Contexto:** identificadores sequenciais expostos em API permitem enumeração de registros de outros usuários.
**Decisão:** UUID v4 em todas as chaves primárias.
**Consequências:** (+) segurança, geração no cliente (essencial para o modo offline), fusão de bases sem colisão. (−) índice maior que `bigint`; aceitável na escala prevista.

### ADR-07 — Exclusão lógica (soft delete)
**Decisão:** coluna `excluido_em` em todas as entidades de negócio, com índice parcial `WHERE excluido_em IS NULL`.
**Justificativa:** preserva integridade histórica e auditoria e permite desfazer. A eliminação definitiva exigida pela LGPD é executada por rotina de anonimização.

### ADR-08 — React Native em vez de desenvolvimento nativo duplicado
**Decisão:** base de código única em React Native + TypeScript.
**Justificativa:** o aplicativo é predominantemente formulários, listas e gráficos — sem exigência de desempenho gráfico nativo. TypeScript no aplicativo e no backend permite compartilhar contratos de tipos.
**Alternativa considerada:** Flutter — desempenho ligeiramente superior, mas exigiria uma segunda linguagem no time.

### ADR-09 — JWT com refresh token rotativo
**Decisão:** access token de 15 minutos (sem estado) + refresh token persistido e rotativo.
**Justificativa:** equilibra desempenho (sem consulta ao banco a cada requisição) e segurança (revogação efetiva pela tabela `sessao`, suporte a "sair de todos os dispositivos").

### ADR-10 — Cache de leitura com invalidação por evento
**Decisão:** Redis com TTL de 120 s no dashboard, invalidado ativamente por `TransacaoRegistradaEvent` e afins.
**Justificativa:** o painel inicial é a tela mais acessada e a mais cara de montar (agrega três contextos).

---

## 6. Requisitos transversais

### 6.1 Segurança em profundidade

| Camada | Controle |
|---|---|
| Borda | WAF, proteção DDoS, limite de requisições por IP |
| Transporte | TLS 1.3 obrigatório, HSTS, *certificate pinning* no aplicativo |
| Autenticação | bcrypt custo 12, JWT curto, refresh rotativo, bloqueio após 5 tentativas |
| Autorização | Guard por rota + filtro obrigatório por `usuario_id` em toda consulta |
| Entrada | validação por esquema (Zod/class-validator), sanitização, consultas parametrizadas |
| Dados | criptografia em repouso, segredos no Secrets Manager, log sem dado sensível |
| Auditoria | `log_auditoria` para operações sensíveis |

### 6.2 Observabilidade
- **Logs** estruturados em JSON com `requestId` correlacionado ponta a ponta.
- **Métricas** Prometheus: latência por rota, taxa de erro, profundidade das filas, saturação do pool de conexões.
- **Rastreamento** OpenTelemetry cobrindo HTTP → caso de uso → banco → serviço externo.
- **Alertas**: p95 > 500 ms por 5 min · taxa de erro > 1% · fila > 1.000 itens · réplica atrasada > 30 s.

### 6.3 Estratégia de testes (pirâmide)

| Nível | Alvo | Ferramenta | Meta |
|---|---|---|---|
| Unitário | entidades, objetos de valor, serviços de domínio | Jest | ≥ 90% no domínio |
| Integração | casos de uso + banco real em contêiner | Jest + Testcontainers | ≥ 80% |
| Contrato | esquema das respostas da API | Pact / OpenAPI validator | 100% das rotas |
| E2E mobile | fluxos críticos (cadastro, lançamento, quitação) | Detox | 8 cenários |
| Carga | dashboard e listagens | k6 | 500 usuários simultâneos |

### 6.4 Integração e entrega contínuas
`lint → typecheck → testes unitários → testes de integração → build da imagem → varredura de vulnerabilidades (Trivy) → deploy em homologação → testes E2E → deploy em produção (rolling update, sem indisponibilidade)`

---

## 7. Modelo C4 — Nível 1 (Contexto)

```
                    ┌──────────────┐
                    │   Usuário    │
                    └──────┬───────┘
                           │ organiza rotina e finanças
                    ┌──────▼─────────────┐
                    │    MinhaVida       │
                    │  (sistema mobile)  │
                    └──┬────┬────┬───────┘
          autentica ◀──┘    │    └──▶ envia e-mails
        Google Identity     │         Amazon SES
                            ▼
                    notificações push
                 Firebase Cloud Messaging
```

## 8. Modelo C4 — Nível 2 (Contêineres)

| Contêiner | Tecnologia | Responsabilidade |
|---|---|---|
| Aplicativo mobile | React Native + TypeScript | Interface, cache local, fila offline |
| API REST | Node.js 22 + NestJS | Regras de negócio, autenticação, orquestração |
| Worker | Node.js + BullMQ | Notificações, recorrências, consolidações |
| Banco de dados | PostgreSQL 16 | Persistência transacional |
| Cache e filas | Redis 7 | Cache de leitura, filas, limite de requisições |
| Armazenamento de objetos | Amazon S3 | Fotos de perfil e comprovantes |
