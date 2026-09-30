# MinhaVida — Arquitetura e Modelagem UML

> **"Organize hoje, viva melhor amanhã."**
> Aplicativo de gestão pessoal: lista de tarefas (CRUD) + gestão financeira + compromissos.

**Autor:** José Antonio de Almeida Silva · **Versão:** 1.0.0 · **Data:** 28/09/2026

Documentação completa de arquitetura derivada das 8 telas do protótipo de alta fidelidade. Serve de base para a construção do banco de dados, do back-end e do aplicativo mobile.

---

## 🎯 Comece por aqui

| Se você quer… | Abra |
|---|---|
| **A apresentação dos três diagramas + resumo do projeto** | [`apresentacao/APRESENTACAO.md`](apresentacao/APRESENTACAO.md) |
| **Os slides prontos para projetar** (9 slides · 6 min) | https://claude.ai/artifact/HCE8uftTYYjjWZoe6phcds |
| O roteiro de fala do **Paulo** (2min46) | [`apresentacao/roteiro-paulo-6min.txt`](apresentacao/roteiro-paulo-6min.txt) |
| O roteiro de fala do **Júlio César** (2min53) | [`apresentacao/roteiro-julio-cesar-6min.txt`](apresentacao/roteiro-julio-cesar-6min.txt) |
| Criar o banco de dados agora | [`banco/schema.sql`](banco/schema.sql) |
| **A análise de concorrentes** (atividade avaliativa, 40 páginas) | [`pesquisa/Analise-de-Concorrentes-MinhaVida.pdf`](pesquisa/Analise-de-Concorrentes-MinhaVida.pdf) |

> ⏱️ **A apresentação foi calibrada para 6 minutos** — 9 slides, Paulo nos slides 1 a 5 e Júlio César nos 6 a 9.
> Os roteiros longos (`roteiro-paulo.txt` e `roteiro-julio-cesar.txt`, ~20 min) continuam no repositório como material de estudo e preparo para a arguição.

---

## 📚 Documentação

| # | Documento | Conteúdo |
|---|---|---|
| 01 | [Resumo do Projeto](docs/01-RESUMO-DO-PROJETO.md) | Problema, solução, persona, escopo, indicadores |
| 02 | [Requisitos](docs/02-REQUISITOS.md) | 61 RF · 32 RNF · 24 regras de negócio · rastreabilidade tela→requisito→entidade |
| 03 | [Arquitetura](docs/03-ARQUITETURA.md) | Clean Architecture, contextos delimitados, 12 padrões, 10 ADRs, C4 |
| 04 | **[Diagrama de Classes](docs/04-DIAGRAMA-DE-CLASSES.md)** | Diagrama UML + dicionário de 187 atributos por entidade |
| 05 | **[Diagramas de Interação](docs/05-DIAGRAMAS-DE-INTERACAO.md)** | 8 diagramas de sequência + 1 de comunicação |
| 06 | **[Diagrama de Implantação](docs/06-DIAGRAMA-DE-IMPLANTACAO.md)** | Produção (AWS) e ambiente acadêmico, protocolos, custos |
| 07 | [Dicionário de Dados](docs/07-DICIONARIO-DE-DADOS.md) | 16 tabelas · 227 colunas · índices · gatilhos · validação executada |
| 08 | [Contrato da API REST](docs/08-CONTRATO-API-REST.md) | 60+ endpoints com payloads e códigos de retorno |
| 09 | [Diagramas Complementares](docs/09-DIAGRAMAS-COMPLEMENTARES.md) | Casos de uso · máquinas de estado · modelo ER |

## 📑 Pesquisa de mercado

| Arquivo | Descrição |
|---|---|
| [`pesquisa/Analise-de-Concorrentes-MinhaVida.pdf`](pesquisa/Analise-de-Concorrentes-MinhaVida.pdf) | Análise de 5 concorrentes (Organizze, Mobills, Todoist, TickTick, Notion) — identificação, problema, funcionalidades, monetização, tecnologias, avaliações, diferenciais e relação com o projeto |
| [`pesquisa/analise-concorrentes.html`](pesquisa/analise-concorrentes.html) | Fonte do documento; o PDF é gerado a partir dele |

## 🗄️ Banco de dados

| Arquivo | Descrição |
|---|---|
| [`banco/schema.sql`](banco/schema.sql) | DDL PostgreSQL 16 — 16 tabelas, 17 enums, 53 índices, 11 gatilhos, 3 visões |
| [`banco/seed.sql`](banco/seed.sql) | Carga de demonstração que reproduz os dados das telas |

```bash
createdb minhavida
psql -d minhavida -f banco/schema.sql
psql -d minhavida -f banco/seed.sql
```

> ✅ **Validado em PostgreSQL 16.13 real.** O esquema executa sem erros e o modelo reproduz exatamente os indicadores das telas (saldo R$ 1.220,35 · 12 atividades · 18h45min). Todas as regras de negócio foram testadas contra o banco.

## 📐 Diagramas

Fontes em Mermaid: [`docs/diagramas/`](docs/diagramas/) · Imagens SVG: [`docs/imagens/`](docs/imagens/)

| Diagrama | Arquivo |
|---|---|
| Classes do domínio — completo | `01-classes-dominio` |
| Classes do domínio — núcleo (projeção) | `01b-classes-nucleo` |
| Classes por camada | `02-classes-camadas` |
| Sequência — Cadastro | `03-seq-cadastro` |
| Sequência — Login | `04-seq-login` |
| Sequência — Dashboard | `05-seq-dashboard` |
| Sequência — CRUD de atividade | `06-seq-crud-atividade` |
| Sequência — Transação financeira | `07-seq-transacao-financeira` |
| Sequência — Quitação de importância ⭐ | `08-seq-importancia-quitacao` |
| Sequência — Notificações agendadas | `09-seq-notificacao-agendada` |
| Sequência — Sincronização offline | `10-seq-sincronizacao-offline` |
| Comunicação — Transação | `11-comunicacao-transacao` |
| Implantação — Produção | `12-implantacao` |
| Implantação — Desenvolvimento | `13-implantacao-academico` |
| Casos de uso | `14-casos-de-uso` |
| Estados — Atividade | `15-estados-atividade` |
| Estados — Importância | `16-estados-importancia` |
| Entidade-Relacionamento | `17-entidade-relacionamento` |

**Para regenerar as imagens:**
```bash
npm install -g @mermaid-js/mermaid-cli
for f in docs/diagramas/*.mmd; do
  mmdc -i "$f" -o "docs/imagens/$(basename "$f" .mmd).svg" -b "#0b1020"
done
```

## 🏗️ Stack proposta

| Camada | Tecnologia |
|---|---|
| Mobile | React Native 0.74 + TypeScript · MVVM + Clean · SQLite offline |
| Back-end | Node.js 22 + NestJS · Clean Architecture · monólito modular |
| Banco | PostgreSQL 16 |
| Cache e filas | Redis 7 + BullMQ |
| Infraestrutura | Docker · Kubernetes (EKS) · AWS sa-east-1 |
| Externos | Firebase Cloud Messaging · Google Identity (OAuth 2.0) · Amazon SES · S3 |

## 📊 O projeto em números

| Elemento | Quantidade |
|---|---|
| Telas analisadas | 8 |
| Requisitos funcionais | 61 |
| Requisitos não funcionais | 32 |
| Regras de negócio | 24 |
| Casos de uso | 24 |
| Entidades de domínio | 15 |
| Tabelas no banco | 16 |
| Colunas mapeadas | 227 |
| Diagramas UML | 18 |
| Decisões arquiteturais (ADR) | 10 |

## 🚀 Próximos passos

- [x] Levantamento de requisitos a partir das telas
- [x] Modelagem de domínio (Diagrama de Classes)
- [x] Diagramas de Interação
- [x] Diagrama de Implantação
- [x] Esquema do banco de dados validado
- [x] Contrato da API REST
- [ ] Implementação do back-end (NestJS)
- [ ] Implementação do aplicativo mobile (React Native)
- [ ] Testes automatizados
- [ ] Publicação nas lojas
