# MinhaVida — Resumo do Projeto

> **"Organize hoje, viva melhor amanhã."**

| Item | Descrição |
|---|---|
| **Nome do produto** | MinhaVida |
| **Autor / Arquiteto** | José Antonio de Almeida Silva |
| **Versão do documento** | 1.0.0 |
| **Data** | 28/09/2026 |
| **Tipo** | Aplicativo mobile de gestão pessoal (produtividade + finanças) |
| **Plataformas** | Android 8+ e iOS 14+ |
| **Base de referência** | Protótipo de alta fidelidade — 8 telas (Cadastro, Login, Início, Atividades, Cadastrar Atividade, Financeiro, Importâncias, Perfil) |

---

## 1. O problema

A vida pessoal de um adulto brasileiro hoje é gerenciada em ferramentas desconectadas: a lista de tarefas fica no aplicativo de notas, os compromissos no calendário, as contas a pagar em lembretes do celular e o controle de gastos em uma planilha que ninguém atualiza. O resultado é previsível:

- **Fragmentação** — a pessoa não tem uma visão única do seu dia.
- **Esquecimento de vencimentos** — contas pagas com multa e juros por pura falta de aviso.
- **Falta de consciência financeira** — o dinheiro "some" sem que se saiba em quê.
- **Abandono da ferramenta** — soluções genéricas exigem disciplina de preenchimento e não devolvem valor percebido.

## 2. A solução

O **MinhaVida** unifica, em um único aplicativo, os três pilares da organização pessoal:

| Pilar | O que resolve | Telas |
|---|---|---|
| **Atividades** | CRUD completo de tarefas, com categoria, prioridade, horário, duração e recorrência | Atividades, Cadastrar atividade |
| **Financeiro** | Registro de receitas e despesas, saldo em tempo real, gastos por categoria e evolução mensal | Financeiro |
| **Importâncias** | Compromissos e datas críticas (contas, licenciamento, assinaturas) com alerta de vencimento e quitação integrada ao financeiro | Importâncias |

O diferencial competitivo está na **integração entre os pilares**: ao marcar a importância *"Pagamento da internet — Vivo Fibra — R$ 99,90"* como concluída, o sistema **gera automaticamente a despesa correspondente**, debita a conta, atualiza o saldo e cria a ocorrência do mês seguinte. Nenhum concorrente direto no mercado brasileiro faz esse fechamento de ciclo em uma única ação.

## 3. Proposta de valor

> *Um único lugar para saber o que fazer hoje, quanto você tem e o que vence amanhã.*

A tela **Início** materializa essa promessa: em uma só rolagem o usuário vê saldo do mês, despesas do mês, importâncias pendentes, atividades do dia, resumo financeiro do dia, movimentações recentes e próximos vencimentos.

## 4. Persona principal

**Júlio César, 24 anos** — estudante universitário que também trabalha. Renda variável, rotina apertada entre faculdade, trabalho, academia e lazer. Usa o celular como computador principal. Precisa de algo que registre em menos de 15 segundos e devolva clareza imediata. Não tolera aplicativo lento nem cadastro longo.

## 5. Escopo do MVP (versão 1.0.0)

### Dentro do escopo
1. Cadastro e autenticação (e-mail/senha + Google, recuperação de senha, "lembrar de mim")
2. CRUD de atividades com categoria, subcategoria, prioridade, horário e recorrência
3. CRUD de lançamentos financeiros (receitas e despesas) com contas e categorias
4. CRUD de importâncias com vencimento, alerta e quitação que gera transação
5. Dashboard diário e mensal com indicadores e variação percentual
6. Notificações push de lembrete e vencimento
7. Perfil, preferências (tema claro/escuro, idioma) e segurança
8. Funcionamento offline com sincronização posterior

### Fora do escopo (roadmap)
- Open Finance / importação automática de extrato bancário
- Compartilhamento familiar de contas e metas
- Metas de economia e investimentos
- Versão web responsiva
- Relatórios em PDF e exportação contábil
- Gamificação e conquistas

## 6. Indicadores de sucesso

| Indicador | Meta |
|---|---|
| Tempo para registrar uma atividade | ≤ 15 segundos |
| Retenção em 30 dias (D30) | ≥ 35% |
| Usuários ativos que registram lançamento semanal | ≥ 60% |
| Redução autorrelatada de contas pagas em atraso | ≥ 50% em 3 meses |
| Tempo de resposta da API (p95) | ≤ 300 ms |
| Disponibilidade mensal | ≥ 99,5% |

## 7. Restrições e premissas

**Restrições**
- Equipe reduzida e prazo acadêmico — exige arquitetura simples de operar (monólito modular, não microsserviços).
- Custo de nuvem controlado — sem serviços de alto custo fixo no MVP.
- Conformidade obrigatória com a **LGPD** (Lei 13.709/2018): dados financeiros e de rotina são dados pessoais sensíveis à privacidade.

**Premissas**
- O usuário possui smartphone com conexão intermitente (daí o requisito offline-first).
- Todos os valores monetários em BRL na v1, mas o modelo já é preparado para múltiplas moedas.
- Fuso horário padrão `America/Sao_Paulo`, configurável por usuário.

## 8. Estrutura desta documentação

| Documento | Conteúdo |
|---|---|
| `01-RESUMO-DO-PROJETO.md` | Este documento — visão, problema, solução, escopo |
| `02-REQUISITOS.md` | Requisitos funcionais, não funcionais e regras de negócio |
| `03-ARQUITETURA.md` | Arquitetura de software, camadas, padrões e decisões (ADR) |
| `04-DIAGRAMA-DE-CLASSES.md` | **Diagrama de Classes** + dicionário completo de atributos |
| `05-DIAGRAMAS-DE-INTERACAO.md` | **Diagramas de Interação** (sequência e comunicação) |
| `06-DIAGRAMA-DE-IMPLANTACAO.md` | **Diagrama de Implantação** (produção e ambiente acadêmico) |
| `07-DICIONARIO-DE-DADOS.md` | Colunas, tipos, chaves e índices de cada tabela |
| `08-CONTRATO-API-REST.md` | Endpoints, payloads e códigos de retorno |
| `09-DIAGRAMAS-COMPLEMENTARES.md` | Casos de uso, máquinas de estado e modelo ER |
| `banco/schema.sql` | DDL PostgreSQL pronto para execução |
| `apresentacao/APRESENTACAO.md` | Apresentação consolidada dos três diagramas |
