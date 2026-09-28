# MinhaVida — Contrato da API REST

**Base:** `https://api.minhavida.app/api/v1` · **Formato:** JSON · **Autenticação:** `Authorization: Bearer <access_token>`

---

## 1. Convenções

| Aspecto | Definição |
|---|---|
| Versionamento | por caminho (`/api/v1`) |
| Paginação | `?pagina=1&tamanho=20` — resposta com `{ dados, total, pagina, tamanho, totalPaginas }` |
| Ordenação | `?ordenarPor=dataAtividade&direcao=desc` |
| Datas | ISO 8601 (`2025-09-29`, `2025-09-29T13:45:00-03:00`) |
| Valores monetários | número decimal com duas casas (`245.30`), nunca texto formatado |
| Idempotência | cabeçalho `Idempotency-Key: <uuid>` nas operações de escrita |
| Correlação | cabeçalho `X-Request-Id` ecoado em toda resposta |

### Códigos de status

| Código | Uso |
|---|---|
| 200 | Consulta ou atualização bem-sucedida |
| 201 | Recurso criado |
| 204 | Exclusão bem-sucedida, sem corpo |
| 400 | Requisição malformada |
| 401 | Token ausente, inválido ou expirado |
| 403 | Autenticado, porém sem permissão |
| 404 | Recurso inexistente ou de outro usuário |
| 409 | Conflito de estado (e-mail em uso, importância já concluída) |
| 422 | Entidade não processável — violação de regra de negócio |
| 429 | Limite de requisições excedido |
| 500 | Erro interno |

### Formato padrão de erro

```json
{
  "erro": {
    "codigo": "IMPORTANCIA_JA_CONCLUIDA",
    "mensagem": "Esta importância já foi concluída em 29/09/2025.",
    "detalhes": [
      { "campo": "status", "problema": "Transição de estado inválida" }
    ],
    "requestId": "9f2c1a7e-3b6d-4c11-8e5a-7d0f2b9a4c31",
    "timestamp": "2025-09-29T13:45:00-03:00"
  }
}
```

---

## 2. Autenticação

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| POST | `/auth/registrar` | Cadastra novo usuário | RF01–RF04 |
| POST | `/auth/login` | Autentica por e-mail ou nome de usuário | RF05, RF06 |
| POST | `/auth/google` | Autentica com `id_token` do Google | RF08 |
| POST | `/auth/refresh` | Renova o par de tokens | RNF06 |
| POST | `/auth/logout` | Revoga a sessão atual | RF10 |
| POST | `/auth/esqueci-senha` | Envia e-mail de recuperação | RF07 |
| POST | `/auth/redefinir-senha` | Redefine a senha com o token | RF07 |
| POST | `/auth/verificar-email` | Confirma o e-mail | RF01 |

**`POST /auth/registrar`**
```json
{
  "nomeCompleto": "Júlio César",
  "email": "julio@email.com",
  "senha": "SenhaForte@123",
  "confirmacaoSenha": "SenhaForte@123",
  "dataNascimento": "2001-05-14",
  "aceiteTermos": true
}
```
→ `201 Created`
```json
{
  "usuario": { "id": "uuid", "nomeCompleto": "Júlio César", "email": "julio@email.com", "nomeUsuario": "juliocesar" },
  "accessToken": "eyJhbGciOi...",
  "refreshToken": "eyJhbGciOi...",
  "expiraEm": 900
}
```

**`POST /auth/login`**
```json
{ "identificador": "julio@email.com", "senha": "SenhaForte@123", "lembrarDeMim": true }
```

---

## 3. Perfil e preferências

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| GET | `/usuarios/me` | Dados do usuário autenticado | RF11 |
| PATCH | `/usuarios/me` | Atualiza nome, telefone, data de nascimento | RF12 |
| POST | `/usuarios/me/foto` | Envia a foto de perfil (multipart) | RF13 |
| PATCH | `/usuarios/me/senha` | Altera a senha | RF14 |
| GET | `/usuarios/me/preferencias` | Consulta as preferências | RF15–RF17 |
| PATCH | `/usuarios/me/preferencias` | Atualiza tema, idioma e notificações | RF15–RF17 |
| GET | `/usuarios/me/sessoes` | Lista as sessões ativas | RNF06 |
| DELETE | `/usuarios/me/sessoes/{id}` | Revoga uma sessão específica | RF10 |
| GET | `/usuarios/me/exportar` | Exporta todos os dados (LGPD) | RNF14 |
| DELETE | `/usuarios/me` | Solicita exclusão da conta (LGPD) | RNF15 |

---

## 4. Atividades

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| POST | `/atividades` | Cria atividade | RF19 |
| GET | `/atividades` | Lista com filtros | RF20, RF25, RF26 |
| GET | `/atividades/{id}` | Detalha | RF20 |
| PUT | `/atividades/{id}` | Atualiza integralmente | RF21 |
| PATCH | `/atividades/{id}` | Atualiza parcialmente | RF21 |
| DELETE | `/atividades/{id}` | Exclui logicamente | RF22 |
| PATCH | `/atividades/{id}/concluir` | Marca como concluída | RF23 |
| PATCH | `/atividades/{id}/reabrir` | Reabre | RF23 |
| GET | `/atividades/indicadores` | Total, concluídas, pendentes, tempo total | RF24 |

**Filtros de `GET /atividades`:** `data`, `dataInicio`, `dataFim`, `categoriaId`, `status`, `prioridade`, `busca`, `pagina`, `tamanho`, `ordenarPor`, `direcao`

**`POST /atividades`**
```json
{
  "titulo": "Estudar para a prova",
  "descricao": "Revisar capítulos 4 e 5",
  "categoriaId": "uuid-estudo",
  "subcategoriaId": "uuid-faculdade",
  "dataAtividade": "2025-09-29",
  "horaInicio": "08:00",
  "horaFim": "10:00",
  "prioridade": "ALTA",
  "lembreteAtivo": true,
  "recorrencia": { "frequencia": "SEMANAL", "intervalo": 1, "diasSemana": ["SEG","QUA","SEX"], "dataFim": "2025-12-20" }
}
```
→ `201 Created` com a atividade criada e `duracaoMinutos: 120` calculado.

**`GET /atividades/indicadores?data=2025-09-29`**
```json
{
  "total": 12, "concluidas": 10, "pendentes": 2,
  "tempoTotalMinutos": 1125, "tempoTotalFormatado": "18h45min",
  "variacao": { "total": 2, "concluidas": 2, "pendentes": -1, "tempoMinutos": 200 }
}
```

---

## 5. Financeiro

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| POST | `/transacoes` | Registra receita ou despesa | RF30 |
| GET | `/transacoes` | Lista movimentações | RF36 |
| GET | `/transacoes/{id}` | Detalha | RF36 |
| PUT | `/transacoes/{id}` | Atualiza | RF37 |
| DELETE | `/transacoes/{id}` | Exclui logicamente | RF37 |
| POST | `/transacoes/{id}/estornar` | Gera transação de sinal oposto | RF37, RN12 |
| GET | `/financeiro/resumo` | Receitas, despesas, saldo e variação | RF32 |
| GET | `/financeiro/grafico-diario` | Série diária de receitas e despesas | RF33 |
| GET | `/financeiro/por-categoria` | Totais agrupados por categoria | RF35 |
| GET | `/contas` · POST · PUT · DELETE | Gerencia contas financeiras | RF38 |
| GET | `/categorias` · POST · PUT · DELETE | Gerencia categorias | RF39 |
| GET | `/orcamentos` · POST · PUT · DELETE | Gerencia orçamentos | RF41 |

**`POST /transacoes`**
```json
{
  "contaId": "uuid-carteira",
  "categoriaId": "uuid-compras",
  "descricao": "Mercado",
  "tipo": "DESPESA",
  "valor": 245.30,
  "dataMovimento": "2025-09-28",
  "formaPagamento": "DEBITO"
}
```
→ `201 Created`
```json
{ "transacao": { "id": "uuid", "valor": 245.30, "tipo": "DESPESA" }, "saldoAtualizado": 1220.35 }
```

**`GET /financeiro/resumo?mes=2025-09`**
```json
{
  "mes": "2025-09",
  "receitas": 2450.75,
  "despesas": 1230.40,
  "saldo": 1220.35,
  "variacaoReceitasPercentual": 12.0,
  "variacaoDespesasPercentual": 8.0,
  "qtdTransacoes": 8
}
```

---

## 6. Importâncias

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| POST | `/importancias` | Cadastra | RF42 |
| GET | `/importancias` | Lista com filtros e agrupamento | RF43, RF44 |
| GET | `/importancias/{id}` | Detalha | RF42 |
| PUT | `/importancias/{id}` | Atualiza | RF42 |
| DELETE | `/importancias/{id}` | Exclui logicamente | RF42 |
| PATCH | `/importancias/{id}/concluir` | **Conclui e gera a transação** | RF47 |
| GET | `/importancias/proximas` | Próximos vencimentos para o painel | RF45, RF49 |

**Filtros:** `filtro` ∈ `TODOS`, `VENCENDO_HOJE`, `ESTE_MES`, `PROXIMOS`, `CONCLUIDOS` · `mes=2025-09` · `categoriaId`

**`PATCH /importancias/{id}/concluir`** — o endpoint mais importante da API
```json
{ "contaId": "uuid-carteira", "dataPagamento": "2025-09-29", "formaPagamento": "PIX" }
```
→ `200 OK`
```json
{
  "importancia": { "id": "uuid", "status": "CONCLUIDA", "concluidaEm": "2025-09-29T13:45:00-03:00", "transacaoId": "uuid-transacao" },
  "transacaoGerada": { "id": "uuid-transacao", "descricao": "Pagamento da internet", "tipo": "DESPESA", "valor": 99.90 },
  "saldoAtualizado": 1120.45,
  "proximaOcorrencia": { "id": "uuid-nova", "dataVencimento": "2025-10-29" }
}
```
→ `409 Conflict` se já concluída (RN13).

---

## 7. Painel inicial e notificações

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| GET | `/dashboard` | Agrega tudo o que a tela Início exibe | RF51–RF53 |
| GET | `/notificacoes` | Lista notificações | RF57 |
| PATCH | `/notificacoes/{id}/lida` | Marca como lida | RF57 |
| PATCH | `/notificacoes/lidas` | Marca todas como lidas | RF57 |
| POST | `/dispositivos` | Registra o token push do aparelho | RF55, RF56 |
| DELETE | `/dispositivos/{token}` | Remove o registro | RF55 |

**`GET /dashboard?data=2025-09-29`**
```json
{
  "usuario": { "primeiroNome": "Júlio" },
  "cards": {
    "receitasMes": { "valor": 2450.75, "variacaoPercentual": 12.0 },
    "despesasMes": { "valor": 1230.40, "variacaoPercentual": 8.0 },
    "importanciasPendentes": 3
  },
  "hoje": {
    "data": "2025-09-29",
    "atividades": [
      { "id": "uuid", "titulo": "Estudar para a prova", "horaInicio": "08:00", "horaFim": "10:00", "categoria": "Estudo", "status": "PENDENTE" }
    ],
    "resumoFinanceiro": { "receitas": 0.00, "despesas": 145.30, "saldo": -145.30 }
  },
  "movimentacoesRecentes": [
    { "id": "uuid", "descricao": "Mercado", "data": "2025-09-29", "tipo": "DESPESA", "valor": 245.30 }
  ],
  "proximasImportancias": [
    { "id": "uuid", "titulo": "Aluguel", "dataVencimento": "2025-10-05", "valor": 1200.00, "diasRestantes": 6 }
  ],
  "notificacoesNaoLidas": 1
}
```

---

## 8. Sincronização offline

| Método | Rota | Descrição | Requisito |
|---|---|---|---|
| POST | `/sync/lote` | Envia operações pendentes e recebe as alterações do servidor | RF59–RF61 |
| GET | `/sync/alteracoes?desde=<timestamp>` | Busca apenas o que mudou | RF60 |

```json
{
  "ultimaSincronizacao": "2025-09-29T10:00:00-03:00",
  "operacoes": [
    { "idOperacao": "uuid-op-1", "tipo": "CRIAR_ATIVIDADE", "timestamp": "2025-09-29T10:15:00-03:00", "dados": { } },
    { "idOperacao": "uuid-op-2", "tipo": "CONCLUIR_ATIVIDADE", "timestamp": "2025-09-29T10:20:00-03:00", "dados": { "id": "uuid" } }
  ]
}
```

---

## 9. Limites de requisição

| Escopo | Limite |
|---|---|
| Global por IP | 100 req/min |
| `/auth/login` por conta | 5 tentativas/min |
| `/auth/esqueci-senha` por e-mail | 3 solicitações/hora |
| Upload de arquivos | 10 req/min, máximo de 5 MB por arquivo |

Cabeçalhos de resposta: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.
