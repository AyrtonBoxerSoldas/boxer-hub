# HUB-DOC-012: Eventos e Fluxos Reativos

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

O Boxer Hub usa um modelo orientado a eventos para desacoplar acoes e suas consequencias. Quando algo acontece (um pedido e criado, um status muda, um credito e aprovado), o sistema registra o evento e dispara reacoes (notificacoes, atualizacoes, logs) de forma independente.

### Mecanismo Principal

**Supabase Realtime + Database Triggers**

O fluxo de eventos usa dois mecanismos nativos do Supabase:
1. **Database Triggers (pg_notify)** — disparam Edge Functions quando registros mudam
2. **Supabase Realtime** — notifica o frontend em tempo real via WebSocket

---

## 2. Catalogo de Eventos

### 2.1 Dominio: Pedidos

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `pedido.criado` | INSERT em `pedidos` | Edge Function `criar-pedido` | Novo pedido registrado |
| `pedido.status_alterado` | UPDATE em `pedidos.status` | Sync C01 ou acao manual | Status mudou (ex: aprovado → faturado) |
| `pedido.aprovado` | UPDATE `status = 'aprovado'` | Edge Function `aprovar-pedido` | Pedido aprovado pela analise |
| `pedido.rejeitado` | UPDATE `status = 'rejeitado'` | Edge Function `rejeitar-pedido` | Pedido rejeitado |
| `pedido.faturado` | UPDATE `status = 'faturado'` | Sync C01 (ERP) | ERP confirmou faturamento |
| `pedido.enviado` | UPDATE `status = 'enviado'` | Sync C01 (ERP) | Pedido saiu para transporte |
| `pedido.entregue` | UPDATE `status = 'entregue'` | Sync C05 (Logistics) | Transportadora confirmou entrega |
| `pedido.cancelado` | UPDATE `status = 'cancelado'` | Acao manual | Pedido cancelado |

### 2.2 Dominio: Cadastro

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `cliente.pre_cadastro` | INSERT em `clientes` | Edge Function `submeter-cadastro` | Cadastro submetido para analise |
| `cliente.aprovado` | UPDATE `status = 'ativo'` | Edge Function `aprovar-cadastro` | Cadastro aprovado e ativado |
| `cliente.bloqueado` | UPDATE `status = 'bloqueado'` | Acao manual ADM | Cliente bloqueado |
| `cliente.erp_criado` | UPDATE `erp_id` preenchido | Edge Function `ativar-cliente-erp` | Cliente criado no ERP ZEN |

### 2.3 Dominio: Credito

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `credito.solicitado` | INSERT em `solicitacoes_credito` | Edge Function `solicitar-credito` | Nova solicitacao de credito |
| `credito.aprovado` | UPDATE `status = 'aprovado'` | Edge Function `decidir-credito` | Credito aprovado |
| `credito.reprovado` | UPDATE `status = 'reprovado'` | Edge Function `decidir-credito` | Credito reprovado |
| `credito.limite_alterado` | UPDATE em `clientes.limite_credito` | Sync ou manual | Limite de credito mudou |

### 2.4 Dominio: Financeiro

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `titulo.vencendo` | Cron diario | Scheduled job | Titulo vence em 3 dias |
| `titulo.vencido` | Cron diario | Scheduled job | Titulo passou do vencimento |
| `titulo.pago` | UPDATE `status = 'pago'` | Sync C03 (Bank) | Pagamento confirmado |
| `nf.disponivel` | INSERT em `notas_fiscais` | Sync C04 (Fiscal) | Nova NF sincronizada |

### 2.5 Dominio: Catalogo

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `produto.atualizado` | UPDATE em `produtos` | Sync C01 (ERP) | Dados do produto mudaram |
| `produto.sem_estoque` | UPDATE `estoque_disponivel = 0` | Sync C01 (ERP) | Estoque zerou |
| `produto.estoque_reposto` | UPDATE `estoque_disponivel > 0` (era 0) | Sync C01 (ERP) | Estoque voltou |

### 2.6 Dominio: Engajamento

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `campanha.ativada` | UPDATE `ativa = true` | Portal ADM | Campanha promocional ativou |
| `campanha.encerrada` | UPDATE `ativa = false` ou data_fim | Cron ou manual | Campanha encerrou |
| `pesquisa.publicada` | UPDATE `status = 'publicada'` | Portal ADM | Pesquisa disponivel para respostas |
| `pesquisa.respondida` | INSERT em `pesquisa_respostas` | Portal Cliente | Cliente respondeu pesquisa |

### 2.7 Dominio: Sistema

| Evento | Trigger | Origem | Descricao |
|---|---|---|---|
| `conector.falha` | Circuit breaker abre | Qualquer conector | Conector entrou em estado de falha |
| `conector.recuperado` | Circuit breaker fecha | Qualquer conector | Conector voltou ao normal |
| `sync.concluida` | Fim de job de sync | Scheduled job | Sincronizacao completou |
| `sync.falha` | Erro em job de sync | Scheduled job | Sincronizacao falhou |

---

## 3. Matriz de Reacoes

Para cada evento, o que acontece automaticamente:

### 3.1 Pedidos

| Evento | Notif. Cliente | Notif. Rep | Notif. ADM | Outras Acoes |
|---|---|---|---|---|
| `pedido.criado` | Email + Push | Email + Push | — | Log auditoria |
| `pedido.aprovado` | Email + WA + Push | Push | — | C01 envia ao ERP |
| `pedido.rejeitado` | Email + Push | Email + Push | — | Log motivo |
| `pedido.faturado` | Email + WA + Push | Push | — | Dispara sync NF (C04) |
| `pedido.enviado` | Email + WA + Push | Push | — | Inicia rastreamento (C05) |
| `pedido.entregue` | Push | Push | — | — |
| `pedido.cancelado` | Email + Push | Email + Push | Push | Estorna credito reservado |

### 3.2 Cadastro e Credito

| Evento | Notif. Cliente | Notif. Rep | Notif. ADM | Outras Acoes |
|---|---|---|---|---|
| `cliente.pre_cadastro` | Email (confirmacao) | Push | Push | Fila de analise |
| `cliente.aprovado` | Email (boas-vindas) | Push | — | C01 cria no ERP |
| `credito.solicitado` | — | Push | Push (financeiro) | Fila de analise |
| `credito.aprovado` | Email + WA | Push | — | C01 atualiza limite ERP |
| `credito.reprovado` | Email | Push | — | Log motivo |

### 3.3 Financeiro

| Evento | Notif. Cliente | Notif. Rep | Notif. ADM | Outras Acoes |
|---|---|---|---|---|
| `titulo.vencendo` | Email + WA | — | — | — |
| `titulo.vencido` | Email + WA | Push (rep do cliente) | Push (financeiro) | Marca como inadimplente |
| `titulo.pago` | Push | — | — | Atualiza saldo disponivel |
| `nf.disponivel` | Email + Push | — | — | Armazena PDF/XML no Storage |

### 3.4 Catalogo e Engajamento

| Evento | Notif. Cliente | Notif. Rep | Notif. ADM | Outras Acoes |
|---|---|---|---|---|
| `produto.sem_estoque` | — | — | Push | Marca como indisponivel no catalogo |
| `produto.estoque_reposto` | Push (quem tem backorder) | Push | — | Processa fila de backorder |
| `campanha.ativada` | Email + Push (publico-alvo) | Push | — | Sinalizacao visual no catalogo |
| `pesquisa.publicada` | Email + Push | — | — | — |

---

## 4. Implementacao Tecnica

### 4.1 Database Trigger → Edge Function

```sql
-- Exemplo: trigger para mudanca de status do pedido
create or replace function notificar_status_pedido()
returns trigger as $$
begin
  if OLD.status is distinct from NEW.status then
    perform pg_notify('pedido_status', json_build_object(
      'pedido_id', NEW.id,
      'status_anterior', OLD.status,
      'status_novo', NEW.status,
      'cliente_id', NEW.cliente_id
    )::text);
  end if;
  return NEW;
end;
$$ language plpgsql;

create trigger trg_pedido_status
  after update of status on pedidos
  for each row
  execute function notificar_status_pedido();
```

### 4.2 Tabela de Notificacoes (persistencia)

Eventos que geram notificacao pro usuario sao gravados na tabela `notificacoes`:

```sql
-- Ja definida no modelo de dados (HUB-DOC-008)
-- notificacoes: tipo, titulo, mensagem, lida, usuario_id, link, criado_em
```

O frontend escuta via Supabase Realtime:
```javascript
supabase
  .channel('notificacoes')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notificacoes',
    filter: `usuario_id=eq.${userId}`
  }, (payload) => {
    mostrarNotificacao(payload.new);
  })
  .subscribe();
```

### 4.3 Jobs Agendados (Cron)

| Job | Frequencia | Descricao |
|---|---|---|
| `check-titulos-vencendo` | Diario 08:00 BRT | Identifica titulos vencendo em 3 dias |
| `check-titulos-vencidos` | Diario 08:00 BRT | Identifica titulos vencidos |
| `check-campanhas-expiradas` | Diario 00:00 BRT | Desativa campanhas com data_fim passada |
| `sync-produtos` | A cada 30 min | Sincroniza catalogo do ERP |
| `sync-estoque` | A cada 30 min | Atualiza estoque |
| `sync-status-pedidos` | A cada 15 min | Atualiza status dos pedidos |
| `sync-titulos` | A cada 1 hora | Sincroniza titulos financeiros |
| `sync-notas-fiscais` | A cada 15 min | Sincroniza NFs |
| `sync-rastreamento` | A cada 2 horas | Atualiza rastreamento |
| `sync-previsao-estoque` | A cada 6 horas | Previsao de chegada de produtos |

Implementados via **pg_cron** (extensao Supabase) ou **GitHub Actions** com schedule.

---

## 5. Fluxo de Backorder

O backorder e um fluxo reativo especial que cruza varios eventos:

```
1. Cliente faz pedido com produto sem estoque
   → pedido.criado (com backorder=true)
   → Registra na fila de backorder

2. Sync de previsao de estoque (C09)
   → Atualiza previsao_chegada no produto
   → Notifica clientes com backorder pendente (previsao atualizada)

3. Estoque reposto (sync C01)
   → produto.estoque_reposto
   → Sistema processa fila de backorder (FIFO)
   → Para cada pedido na fila:
     - Reserva estoque
     - Atualiza status do pedido
     - Envia ao ERP (C01)
     - Notifica cliente e representante
```

---

## 6. Fluxo de Modo Proxy

Quando o representante age em nome do cliente:

```
1. Rep seleciona cliente no Portal Representante
   → proxy.ativado (evento local, nao persistido)
   → Todas as acoes passam a registrar:
     - representante_id no pedido
     - origem = 'proxy_representante'
     - IP e timestamp da sessao proxy

2. Rep cria pedido em nome do cliente
   → pedido.criado (com modo_proxy=true)
   → Notificacao ao cliente: "Pedido #X criado pelo seu representante"
   → Log de auditoria completo

3. Cliente ve no Portal Cliente
   → Badge "Criado pelo representante" no pedido
   → Historico mostra quem criou
```

---

## 7. Regras de Deduplicacao

Para evitar notificacoes duplicadas:

| Regra | Implementacao |
|---|---|
| Mesmo evento em <5 minutos | Ignora segunda notificacao |
| Sync que nao muda dados | Nao dispara evento (compara hash antes/depois) |
| Multiplas mudancas de status rapidas | Agrupa em uma unica notificacao |
| Campanha ja notificada | Flag `notificado` por usuario/campanha |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
