# Referência — API REST do Zen ERP

Fornecedor: ZenSoft Sistemas (zenerp.com.br). Baseado na especificação
OpenAPI 3.0.3 fornecida por André — 889 endpoints.

> **Origem:** documento produzido para o projeto **Monitor de Pedidos** e
> replicado aqui porque o Hub Comercial também integra com o Zen (estoque,
> clientes, pedidos, títulos). Ver `INTEGRACAO-ZEN-HUB.md` para o recorte do que
> o Hub usa e o que ainda precisa ser confirmado no ambiente real.

**Convenção de nomenclatura:** todo recurso segue `{recurso}Create`, `{recurso}Read`,
`{recurso}Update`, `{recurso}Delete`, `{recurso}ReadById` para CRUD, e
`{recurso}Op{Ação}` para operações de negócio (`saleOpApprove`, `quoteOpCancel`).
Consistente em toda a API.

**Autenticação:** `POST /auth/login` retorna um token; requisições subsequentes
usam esse token. Há um cabeçalho de contexto `Tenant` (multi-empresa).

**O que este documento NÃO cobre:** os `enum` de status e nomes de campos vêm do
schema OpenAPI (alta confiança). Já o *comportamento* de operações como
`saleOpSplit`, `saleOpMerge`, ou a lista de eventos aceitos por `Watcher.event`,
não está na especificação (ela não tem `description`/`summary` nos endpoints) —
está marcado como **inferido pelo nome** e precisa ser validado em teste prático
antes de qualquer decisão de arquitetura depender disso.

---

## 1. Módulo `sale` — Pedidos e Orçamentos

### 1.1 — `sale.Sale`
**Endpoint base:** `/sale/sale`

| Campo | Descrição |
|---|---|
| `status` | Enum técnico: `PREPARING, PREPARED, APPROVED, MERGED, PICKING, LACK, CANCELED, FINISHED`. **Não é a mesma coisa que as etapas de negócio** (Início, Web Pronta Entrega, Aguardando Limite…) — essas vivem em `workflow` (seção 5) |
| `company`, `person` (cliente), `personSalesperson` (representante), `personShipping` | Partes envolvidas |
| `priceList`, `totalValue`, `availabilityDate` | Preço e valor |
| `quote` | Referência ao orçamento de origem, se veio de um |
| `pickingOrder`, `shipment`, `invoice` | Vínculos com separação, expedição e nota fiscal |
| `saleProfile` | Referencia o `workflow` que rege esse pedido |
| `freightType` | `NONE, ISSUER, RECIPIENT` |

**Operações (`saleOp*`):**

| Endpoint | Função (inferida do nome; validar em teste) |
|---|---|
| `saleOpCreate` | Cria um novo pedido |
| `saleOpApprove/{id}` | Aprova o pedido |
| `saleOpApproveUnconditionally/{id}` | Aprovação forçada — exceção comercial |
| `saleOpForwardAuto/{id}` | Avanço automático de etapa; comportamento não documentado |
| `saleOpSplit/{id}` | Divide o pedido — candidato a faturamento parcial |
| `saleOpMerge` | Consolida múltiplos pedidos |
| `saleOpCancel/{id}` | Cancela |
| `saleOpPickingOrderCreate/{id}` | Envia para separação/logística |
| `saleOpShipmentAssign/{id}` | Vincula a um embarque |
| `saleOpTaxationCalc/{id}` | Recalcula impostos |
| `saleOpClone/{id}` | Duplica |

### 1.2 — `sale.SaleItem`
`/sale/saleItem` — cada linha do pedido. Campos: `productPacking`, `quantity`,
`servedQuantity` (quanto já foi atendido), `unitValue`,
`discountType`/`discountValue`, `totalValue`.

`servedQuantity` separado de `quantity` confirma que o Zen já modela nativamente
"quanto pediu vs. quanto já foi entregue" no nível do item.

### 1.3 — `sale.Quote` (orçamento)
Mesmos campos estruturais de `Sale` (`status`, `company`, `saleProfile`,
`workflow`, `workpiece`, `person`) mais operações próprias: `quoteOpApprove`,
`quoteOpSubmit`, `quoteOpFill`, `quoteOpReject`.

### 1.4 — Preço
- `sale.priceFormation` / `priceFormationOpCalculate` / `OpSimulation`
- `sale.priceList` / `sale.priceListItem`
- `sale.PriceListRetail` — referenciada em `StockCluster` e `Sale.priceList`

---

## 2. Módulo `material` — Estoque (138 endpoints)

### 2.1 — Disponibilidade e saldo

| Entidade/Endpoint | Campos-chave | Função |
|---|---|---|
| `GET /material/stockAvailability` | `type` (INCOMING/OUTGOING/STOCK), `quantity`, `stockCluster`, `date`, `schedule` | **Disponibilidade projetada** — estoque atual e futuro (entradas previstas) |
| `GET /material/stock` | `status` (FREE/MOVING_ORDER/FUTURE), `reservation`, `quantity`, `type` (EXTERNAL/LACK/REGULAR/EXCESS) | Saldo físico por unidade de estoque, com vínculo de reserva |
| `material.StockCluster` | `code`, `description`, `assetValuationMethod` (FIFO/LIFO/WAC), `priceListCost`, `priceListRetail` | **Agrupador de estoque** — provável mecanismo para separar máquinas, avariadas, Mercado Livre. Confirmar via `GET /material/stockCluster` |

### 2.2 — Reserva de estoque

| Entidade/Endpoint | Campos-chave | Função |
|---|---|---|
| `material.Reservation` | `status`: SYSTEM/LOCKED/PREPARING/PREPARED/APPROVED/STARTED/FINISHED/DELETED | Reserva nativa — base do cálculo "estoque disponível real" (bruto − reservas) |
| `POST /material/reservationOpAllocateStock/{id}` (`stockId`, `quantity`) | — | Aloca quantidade específica para uma reserva |

### 2.3 — Entrada de mercadoria

| Entidade | Função |
|---|---|
| `material.IncomingList` / `IncomingListItem` | Recebimento de mercadoria; `incomingListOpImportFromOutgoingList` sugere vínculo com devoluções. Provável gatilho de "item voltou ao estoque" |
| `material.InventoryStock` / `Inventory` | Inventário físico — ajuste e contagem |

### 2.4 — Endereçamento e unidades físicas
`material.Address`, `Lot`, `Serial`, `HandlingUnit`, `Quality` — localização,
lote, série, unidade de movimentação, qualidade. Aparecem como referência em
`Stock`/`StockAvailability`.

### 2.5 — Separação e movimentação
`material.PickingOrder` (`status`, `reservation`, `outgoingList`, `movingOrder`,
`shipment`) — ordem de separação física.

---

## 3. `financial/credit` e `financial` — Crédito e Cobrança

### 3.1 — Limite de crédito

| Entidade | Campos | Função |
|---|---|---|
| `financial.credit.CreditLine` | `code`, `description` | Linha/política de crédito |
| `financial.credit.CreditLineItem` | `creditLine`, `personGroup` ou `person`, `value` | **O limite de crédito em si** |

### 3.2 — Títulos em aberto

| Entidade | Campos-chave | Função |
|---|---|---|
| `financial.Receivable` (herda de `BillingTitle`) | `dueDate`, `balance`, `status` (PREPARING/PREPARED/APPROVED/CANCELED/SETTLED), `value`, `valueSettlement`, `flow` (IN/OUT), `person`, `payer` | Título a receber. **Atraso** = `dueDate < hoje AND status != SETTLED AND balance > 0` |
| `financial/receivableOpSettle` | — | Liquidação — gatilho de "boleto atrasado foi pago" |

### 3.3 — O que NÃO existe nativamente
Não há endpoint para Serasa ou Vadu — integração externa. O campo `properties`
(objeto livre, presente em quase todo schema) é candidato a guardar resultado
dessas consultas, ou uma tabela própria no Supabase.

---

## 4. Módulo `commercial` — Preço e Exceção Comercial

| Entidade/Endpoint | Função |
|---|---|
| `commercial.PriceListChangeRequest` + `OpApprove` / `OpReject` | **Solicitação/aprovação nativa de exceção de preço** |
| `commercial/priceListTransformation` + `OpCalculate` | Recálculo de tabela de preço |
| `commercial/personHierarchy` | Hierarquia entre pessoas — **investigar se é aqui que ficam as carteiras de representante** |

---

## 5. `system/workflow` — Etapas de Negócio Customizadas

Camada onde vivem os nomes usados no dia a dia (Início, Web Pronta Entrega,
Aguardando Limite, Aguardando Importação, Programado) — **não confundir com o
`status` técnico de `sale.Sale`**, que é um enum fixo.

| Entidade | Campos | Função |
|---|---|---|
| `system.workflow.Workflow` | `code`, `description`, `status` | A definição do fluxo |
| `system.workflow.WorkflowNode` | `workflow`, `type` (START/PROCESS/DECISION/BRANCH/MERGE/SUCCESS/FAIL), `code`, `description` | **Cada nó do fluxo** |
| `system.workflow.Workpiece` | `source`, `workflow`, `workflowNode`, `status` | Instância — liga um pedido ao workflow e ao nó atual |

**Ação necessária:** rodar `GET /system/workflow/workflow` e
`GET /system/workflow/workflowNode` no ambiente real para confirmar a
configuração cadastrada.

`sale.SaleProfile` referencia um `workflow` — é a ligação entre pedido e fluxo.

---

## 6. `system/automation` — Webhook Nativo

O Zen **já tem webhook nativo** — elimina a necessidade de polling.

| Entidade | Campos | Função |
|---|---|---|
| `system.automation.Watcher` | `event` (string livre), `uri` | Registra evento + URI; o Zen chama a URI quando o evento ocorre |
| `system.automation.Agent` | `description`, `uri` | Endpoint externo chamável pelo Zen; `agentOpExecute` dispara manualmente |
| `system.automation.Schedule` | `type` (CRON/ONETIME), `expression`, `agent`, `nextRun`, `lastRun` | Executa um Agent em horário agendado |

**Lacuna a confirmar:** a especificação não lista os valores possíveis de
`Watcher.event` (string livre) — confirmar com o fornecedor ou testar em sandbox.

---

## 7. Cadastros (`catalog/*`)

### 7.1 — `catalog.person.Person`
`type`, `name`, `fantasyName`, `documentType`/`documentNumber` (CNPJ/CPF),
endereço, `personGroup`, `personSalesperson` (representante vinculado),
`personShipping`, `priceListCost`/`priceListRetail`, `category1` a `category5`
(campos genéricos — candidatos a segmentação, mas **confirmar, não presumir**).

Auxiliares: `personAddress`, `personContact`, `personDocument`, `personComment`,
`personGroup`.

### 7.2 — `catalog.company.Company`
`stockCluster`, `warehouse`, `priceList`, `creditLine`.

### 7.3 — `catalog.product.Product`
`type`, `code`, `description`, `unit`, dimensões, `category1` a `category5`,
`variant`, `barcode`.

---

## 8. Logística e Fiscal

| Módulo | Papel |
|---|---|
| `shipping` (19 endpoints) | Embarque — `shipmentOpApprove`, `shipmentOpLoadStart`, `shipmentOpFinish` |
| `logistic` (5 endpoints) | Camada mais simples/antiga — checar sobreposição com `shipping` |
| `fiscal` / `fiscal/br` / `fiscal/taxation` (168) | Nota fiscal e tributação. `fiscal.OutgoingInvoice` é referenciado por `sale.Sale.invoice` |

---

## 9. Módulos não detalhados (existência confirmada)

| Módulo | Endpoints | Assunto |
|---|---|---|
| `fiscal` | 102 | Nota fiscal |
| `fiscal/br` | 36 | Obrigações fiscais BR (SPED) |
| `fiscal/taxation` | 22 | Regras de tributação |
| `supply/purchase` | 84 | Compras |
| `supply/production` | 73 | Produção/manufatura |
| `financial/accounting` | 73 | Contabilidade |
| `financial/billing` | 46 | Remessa/retorno bancário, boletos |
| `financial/treasury` | 15 | Tesouraria |
| `financial/salesCommission` | 13 | Comissão de vendas — **interessa se o modo representante mostrar comissão** |
| `commercial/contract` | 41 | Contratos recorrentes |
| `commercial/target` | 20 | Metas comerciais |
| `system/security` | 65 | Usuários e permissões **dentro do Zen** |
| `system/audit` | 12 | Log de auditoria nativo |
| `system/integration` | 24 | Integrações existentes com terceiros |
| `system/data`, `storage`, `file`, `image` | 41 | Armazenamento genérico |
| `trade` | 89 | Não explorado — nome sugere câmbio/comércio exterior |
| `catalog/location` | 18 | Cidades, regiões |
| `system/report`, `printing` | 28 | Relatório e impressão |
| `system/mail`, `job` | 9 | E-mail e jobs em background |
| `auth`, `catalog`, `system` (raiz) | 30 | Autenticação e administração |

---

## 10. Regra de ouro

Sempre que uma decisão de arquitetura depender do **comportamento exato** de um
endpoint (não só do nome ou do schema), testar contra o ambiente real antes de
codar em cima. Candidatos que ainda precisam dessa validação:

- `saleOpSplit` e `saleOpMerge`
- `saleOpForwardAuto`
- Valores aceitos por `Watcher.event`
- Uso real dos campos `category1-5` em `Person` e `Product`
- Sobreposição entre `shipping` e `logistic`
