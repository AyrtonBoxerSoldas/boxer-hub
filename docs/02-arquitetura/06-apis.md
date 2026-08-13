# HUB-DOC-011: APIs (Edge Functions)

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

As APIs do Boxer Hub sao implementadas como **Supabase Edge Functions**. O frontend nunca acessa sistemas externos diretamente — toda operacao sensivel passa por uma Edge Function que valida JWT, verifica permissoes, executa logica de negocio e registra no log.

Para leituras simples protegidas por RLS, o frontend acessa o Supabase diretamente via `supabase-js`.

### Padrao de Resposta

```typescript
// Sucesso
{ success: true, data: { ... } }

// Erro
{ success: false, error: { code: 'CREDITO_INSUFICIENTE', message: '...' } }
```

### Autenticacao

Toda Edge Function valida o JWT do usuario:
```typescript
const { data: { user }, error } = await supabase.auth.getUser(
  req.headers.get('Authorization')?.replace('Bearer ', '')
);
if (error || !user) return new Response(JSON.stringify({ success: false, error: { code: 'AUTH_REQUIRED' } }), { status: 401 });
```

---

## 2. APIs por Dominio

### 2.1 Catalogo

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| Direto via RLS | GET | Listar produtos | JWT | Todos |
| Direto via RLS | GET | Detalhe do produto | JWT | Todos |
| `calcular-preco` | POST | Calcula preco personalizado | JWT | dealer, rep |

**`calcular-preco`**
```
Request: { produto_id, cliente_id, quantidade }
Response: {
  preco_unitario, tabela_aplicada, desconto,
  preco_final, regras_aplicadas: [{ regra_id, nome, tipo }]
}
Logica: CIE resolve hierarquia de precos (especial > campanha > cliente > canal > base)
```

### 2.2 Pedidos

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| `criar-pedido` | POST | Cria e envia pedido | JWT | dealer, rep |
| `validar-carrinho` | POST | Valida itens antes de enviar | JWT | dealer, rep |
| `converter-cotacao` | POST | Converte cotacao em pedido | JWT | dealer, rep |
| `aprovar-pedido` | POST | Aprova pedido pendente | JWT | analyst, manager |
| `rejeitar-pedido` | POST | Rejeita pedido pendente | JWT | analyst, manager |
| Direto via RLS | GET | Listar pedidos | JWT | Por role (RLS) |

**`criar-pedido`**
```
Request: {
  itens: [{ produto_id, quantidade }],
  condicao_pagamento,
  endereco_entrega_id,
  pedido_cliente,        // OC do revendedor (opcional)
  observacoes,
  cliente_id             // obrigatorio se role=rep (Modo Proxy)
}
Response: { pedido_id, numero, status, valor_total, itens_backorder: [] }
Logica:
  1. Valida que cliente esta ativo
  2. CIE calcula precos de cada item
  3. Verifica credito disponivel (limite - titulos em aberto >= valor_total)
  4. Verifica regras de elegibilidade e restricao
  5. Se excecao: status = 'em_analise' (aprovacao manual)
  6. Se aprovado automaticamente: C01 ERP envia ao ZEN
  7. C06 Communication notifica cliente e representante
  8. Se Modo Proxy: registra representante_id e origem='proxy_representante'
  9. Log de auditoria
```

**`aprovar-pedido`**
```
Request: { pedido_id, justificativa }
Response: { pedido_id, status: 'aprovado', erp_pedido_id }
Logica:
  1. Verifica alcada do aprovador
  2. Envia ao ERP (C01)
  3. Atualiza status
  4. Notifica cliente e representante (C06)
  5. Log
```

### 2.3 Cadastro

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| `consultar-cnpj` | POST | Consulta dados na Receita Federal | JWT | dealer, rep, analyst |
| `submeter-cadastro` | POST | Envia cadastro para analise | JWT | dealer, rep |
| `aprovar-cadastro` | POST | Aprova cadastro pendente | JWT | analyst, manager |
| `ativar-cliente-erp` | POST | Cria cliente no ERP | JWT | analyst |

**`consultar-cnpj`**
```
Request: { cnpj }
Response: { razao_social, nome_fantasia, endereco, situacao_cadastral, ... }
Logica: C07 Federal Revenue Connector
Cache: 30 dias
```

### 2.4 Credito

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| `solicitar-credito` | POST | Abre solicitacao de credito | JWT | dealer, rep |
| `consultar-bureau` | POST | Consulta Serasa/Boa Vista | JWT | financial, manager |
| `decidir-credito` | POST | Aprova/rejeita credito | JWT | financial, manager |

**`decidir-credito`**
```
Request: { solicitacao_id, decisao: 'aprovado'|'reprovado'|'aprovado_parcial', valor_aprovado, justificativa }
Response: { solicitacao_id, status, limite_atualizado }
Logica:
  1. Verifica alcada (valor > X exige gerente)
  2. Atualiza limite no Hub
  3. C01 ERP atualiza limite no ZEN
  4. C06 notifica cliente e representante
  5. Log
```

### 2.5 Financeiro

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| `gerar-segunda-via` | POST | Gera segunda via de boleto | JWT | dealer, rep, financial |
| `download-xml-lote` | POST | Baixa XMLs em lote | JWT | dealer, rep |
| Direto via RLS | GET | Listar titulos | JWT | Por role (RLS) |
| Direto via RLS | GET | Listar notas fiscais | JWT | Por role (RLS) |

**`gerar-segunda-via`**
```
Request: { titulo_id }
Response: { linha_digitavel, pix_copia_cola, boleto_pdf_url }
Logica: C03 Bank Connector gera boleto atualizado
```

### 2.6 Campanhas e Pesquisas

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| `criar-campanha` | POST | Cria campanha promocional | JWT | analyst, manager |
| `criar-pesquisa` | POST | Cria pesquisa | JWT | analyst, manager |
| `responder-pesquisa` | POST | Registra respostas | JWT | dealer |
| `relatorio-pesquisa` | GET | Relatorio consolidado | JWT | analyst, manager |
| Direto via RLS | GET | Campanhas ativas | JWT | Todos |
| Direto via RLS | GET | Pesquisas pendentes | JWT | dealer |

### 2.7 Sync (Conectores)

| Endpoint | Metodo | Descricao | Auth | Trigger |
|---|---|---|---|---|
| `sync-produtos` | POST | Sincroniza catalogo do ERP | service_role | Cron (30 min) |
| `sync-estoque` | POST | Atualiza estoque do ERP | service_role | Cron (30 min) |
| `sync-status-pedidos` | POST | Atualiza status de pedidos | service_role | Cron (15 min) |
| `sync-titulos` | POST | Sincroniza titulos/boletos | service_role | Cron (1 hora) |
| `sync-notas-fiscais` | POST | Sincroniza NFs | service_role | Cron (15 min) |
| `sync-rastreamento` | POST | Atualiza rastreamento | service_role | Cron (2 horas) |
| `sync-previsao-estoque` | POST | Previsao de chegada | service_role | Cron (6 horas) |

Sync functions sao invocadas via **pg_cron** (Supabase) ou **GitHub Actions** em schedule.

### 2.8 Administracao

| Endpoint | Metodo | Descricao | Auth | Roles |
|---|---|---|---|---|
| `criar-usuario` | POST | Cria usuario no Supabase Auth | JWT | admin |
| `alterar-role` | POST | Altera role de usuario | JWT | admin |
| `revogar-sessao` | POST | Revoga sessao ativa | JWT | admin |
| `health` | GET | Health check | Publico | — |

---

## 3. Acesso Direto via RLS (sem Edge Function)

Operacoes de leitura simples onde o RLS garante seguranca:

| Tabela | Operacao | Policy RLS |
|---|---|---|
| `produtos` | SELECT | Qualquer usuario autenticado |
| `categorias` | SELECT | Qualquer usuario autenticado |
| `pedidos` | SELECT | dealer: seus pedidos. rep: pedidos dos seus clientes. analyst/manager: todos |
| `pedido_itens` | SELECT | Mesmo do pedido pai |
| `titulos` | SELECT | dealer: seus titulos. rep: titulos dos seus clientes. financial: todos |
| `notas_fiscais` | SELECT | Mesmo de titulos |
| `notificacoes` | SELECT/UPDATE | Somente do usuario (marcar como lida) |
| `campanhas` | SELECT | Ativas e dentro do publico-alvo |
| `pesquisas` | SELECT | Publicadas e dentro do publico-alvo |

---

## 4. Rate Limiting

| Endpoint | Limite |
|---|---|
| `consultar-cnpj` | 10 req/min por usuario |
| `consultar-bureau` | 5 req/min por usuario |
| `gerar-segunda-via` | 3 req/min por usuario |
| `criar-pedido` | 10 req/min por usuario |
| Sync functions | 1 req por intervalo de cron |
| Demais | 60 req/min por usuario |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
