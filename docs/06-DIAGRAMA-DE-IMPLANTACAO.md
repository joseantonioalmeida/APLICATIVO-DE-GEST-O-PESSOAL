# MinhaVida — Diagrama de Implantação (UML)

O diagrama de implantação descreve a **arquitetura física** do sistema: em quais nós computacionais os artefatos de software são instalados e por quais protocolos se comunicam. É o diagrama que responde a "onde isso roda de verdade e quanto custa".

### Notação empregada

| Elemento | Significado |
|---|---|
| `«device»` | nó físico ou virtual com capacidade de processamento |
| `«executionEnvironment»` | ambiente de execução hospedado em um nó (runtime, contêiner, servidor de aplicação) |
| `«artifact»` | artefato implantável — binário, imagem de contêiner, arquivo de banco |
| Linha cheia | caminho de comunicação com protocolo e porta anotados |
| Linha tracejada | dependência ou fluxo secundário |

---

## 1. Ambiente de produção

![Diagrama de Implantação — Produção](imagens/12-implantacao.svg)

### 1.1 Nós e artefatos

| Nó | Ambiente / Artefato | Tecnologia | Função |
|---|---|---|---|
| **Smartphone do usuário** | Android Runtime / iOS Runtime | Android 8+ · iOS 14+ | Dispositivo do usuário final |
| | `minhavida-app.apk / .ipa` | React Native 0.74 + TypeScript | Aplicativo cliente |
| | `minhavida.db` | SQLite (WatermelonDB) | Cache offline e fila outbox |
| | `SecureStore` | Keychain / Keystore | Tokens de autenticação |
| **Borda** | WAF + CDN + limite de requisições | Cloudflare | TLS 1.3, proteção contra DDoS, 100 req/min por IP |
| **Nuvem (AWS sa-east-1)** | Application Load Balancer | AWS ALB | Distribuição de carga, verificação de saúde |
| | Pod `api` (2 a 6 réplicas) | Amazon EKS + Docker | API REST, autoescalonamento a 70% de CPU |
| | `minhavida-api:1.0.0` | Node.js 22 + NestJS | Regras de negócio, porta 3000 |
| | Pod `worker` (1 a 3 réplicas) | Amazon EKS + Docker | Processamento assíncrono |
| | `minhavida-worker:1.0.0` | Node.js + BullMQ | Notificações, recorrências, consolidações |
| | Banco primário | Amazon RDS PostgreSQL 16 Multi-AZ | Persistência transacional, PITR de 7 dias |
| | Réplica de leitura | PostgreSQL streaming replication | Relatórios e consultas pesadas |
| | Cache e filas | Amazon ElastiCache Redis 7 | Cache de 120 s, filas BullMQ, limite de requisições |
| | Armazenamento de objetos | Amazon S3 | Fotos de perfil e comprovantes, URLs pré-assinadas de 15 min |
| | Observabilidade | OpenTelemetry · Grafana · Loki · Prometheus · Sentry | Logs, métricas, rastreamento, erros |
| | Gestão de segredos | AWS Secrets Manager | Chaves JWT e credenciais |
| **Serviços externos** | Firebase Cloud Messaging | SaaS | Notificações push |
| | Google Identity | OAuth 2.0 / OIDC | Login social |
| | Amazon SES | SaaS | E-mails transacionais |

### 1.2 Caminhos de comunicação

| Origem → Destino | Protocolo | Porta | Observação |
|---|---|---|---|
| Aplicativo → Cloudflare | HTTPS / TLS 1.3 | 443 | REST + JSON, *certificate pinning* |
| Cloudflare → ALB | HTTPS | 443 | Somente tráfego validado pelo WAF |
| ALB → Pod api | HTTP/2 | 3000 | Rede interna do cluster |
| API → PostgreSQL primário | TCP com TLS | 5432 | Pool de 20 conexões |
| API → Réplica de leitura | TCP com TLS | 5432 | Somente consultas de relatório |
| API / Worker → Redis | TCP com TLS | 6379 | Cache e filas |
| API → S3 | HTTPS | 443 | SDK da AWS |
| Worker → FCM | HTTPS | 443 | API FCM v1 |
| API → Google Identity | HTTPS | 443 | Validação de `id_token` |
| Worker → SES | SMTP com TLS | 587 | E-mails transacionais |
| API / Worker → Observabilidade | OTLP / gRPC | 4317 | Telemetria |
| FCM → Aplicativo | APNs / FCM | — | Entrega de push |

### 1.3 Justificativas das decisões de implantação

**Região sa-east-1 (São Paulo)** — latência de 15 a 30 ms para o usuário brasileiro, contra 120 a 180 ms se a carga estivesse na Virgínia. Além disso, manter dados pessoais em território nacional simplifica substancialmente a conformidade com a LGPD.

**Kubernetes com autoescalonamento** — o uso do aplicativo é fortemente sazonal: picos pela manhã, no almoço e à noite. Escalar de 2 a 6 réplicas conforme a CPU evita pagar pelo pico 24 horas por dia. A API é **sem estado** — toda sessão vive no banco ou no Redis — o que torna a escala horizontal trivial.

**Separação entre API e Worker** — um disparo de 10.000 notificações não pode degradar o tempo de resposta de quem está usando o aplicativo naquele momento. Processos com perfis de carga distintos merecem pods distintos, com escalonamento independente.

**PostgreSQL Multi-AZ com réplica de leitura** — Multi-AZ atende ao RTO de 1 hora com failover automático. A réplica de leitura isola as consultas analíticas pesadas (gráfico mensal, relatórios) da carga transacional.

**Redis para cache e filas** — um único componente resolve três necessidades: cache do painel, filas BullMQ e contadores de limite de requisições. Menos peças para operar.

**Cloudflare na borda** — a proteção contra DDoS e o limite de requisições por IP acontecem **antes** de o tráfego chegar à infraestrutura paga. Defesa mais barata e mais eficaz.

### 1.4 Dimensionamento inicial e custo estimado

| Recurso | Configuração | Custo mensal aproximado |
|---|---|---|
| EKS (control plane) | 1 cluster | US$ 73 |
| Nós EC2 | 2 × t3.medium | US$ 60 |
| RDS PostgreSQL | db.t3.small Multi-AZ | US$ 95 |
| ElastiCache Redis | cache.t3.micro | US$ 25 |
| S3 + transferência | 50 GB | US$ 8 |
| ALB | 1 unidade | US$ 22 |
| Cloudflare | plano gratuito | US$ 0 |
| **Total** | **até ~10.000 usuários ativos** | **≈ US$ 283/mês** |

> Para a fase de validação, uma alternativa de custo muito menor é executar API e Worker em um único serviço gerenciado (Railway, Render ou Fly.io) com PostgreSQL e Redis inclusos — cerca de US$ 25/mês. A arquitetura em contêineres permite essa migração sem alteração de código.

---

## 2. Ambiente de desenvolvimento e laboratório acadêmico

![Diagrama de Implantação — Desenvolvimento](imagens/13-implantacao-academico.svg)

Para desenvolvimento, apresentação e avaliação acadêmica, toda a infraestrutura roda em uma única máquina via Docker Compose:

| Serviço | Imagem | Porta | Substitui em produção |
|---|---|---|---|
| `api` | build local (Node 22) | 3000 | Pod api no EKS |
| `postgres` | `postgres:16-alpine` | 5432 | Amazon RDS |
| `redis` | `redis:7-alpine` | 6379 | ElastiCache |
| `minio` | `minio/minio` | 9000 | Amazon S3 (API compatível) |
| `pgadmin` | `dpage/pgadmin4` | 5050 | — (ferramenta de inspeção) |
| Aplicativo | Expo Go ou emulador Android | — | Dispositivo físico |

```bash
docker compose up -d      # sobe toda a infraestrutura
npm run migration:run     # aplica as migrações
npm run seed              # popula com os dados do protótipo
```

O MinIO expõe a mesma API do S3, de modo que o código de upload é idêntico nos dois ambientes — apenas a variável de ambiente `S3_ENDPOINT` muda.

---

## 3. Estratégia de implantação

| Aspecto | Definição |
|---|---|
| **Estratégia** | *Rolling update* — nova réplica sobe e passa na verificação de saúde antes de a antiga ser encerrada. Zero indisponibilidade |
| **Migrações** | Executadas por *init container* antes da subida dos pods. Sempre compatíveis com a versão anterior (expand/contract) |
| **Reversão** | `kubectl rollout undo` — retorna à imagem anterior em menos de 1 minuto |
| **Ambientes** | `dev` (local) → `homologação` (réplica reduzida) → `produção` |
| **Publicação do aplicativo** | *Over-the-air* via Expo Updates para alterações de JavaScript; submissão às lojas apenas quando há mudança nativa |
| **Backup** | Snapshot diário do RDS, retenção de 7 dias, PITR ativo. Teste de restauração mensal |
| **Segredos** | Injetados por variável de ambiente a partir do Secrets Manager. Nunca versionados no repositório |

## 4. Atendimento aos requisitos não funcionais

| Requisito | Como a implantação atende |
|---|---|
| RNF01 — p95 ≤ 300 ms | Cache Redis, réplica de leitura, região local, índices adequados |
| RNF07 — TLS obrigatório | TLS 1.3 na borda e criptografia em todos os saltos internos |
| RNF09 — limite de requisições | Cloudflare por IP + Redis por conta |
| RNF23 — 99,5% de disponibilidade | Multi-AZ, múltiplas réplicas, verificação de saúde, *rolling update* |
| RNF24/25 — RPO 5 min, RTO 1 h | Multi-AZ com failover automático e PITR |
| RNF26 — escala horizontal | API sem estado + autoescalonamento por CPU |
| RNF27 — observabilidade | OpenTelemetry ponta a ponta com alertas configurados |
