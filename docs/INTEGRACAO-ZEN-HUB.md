# Integração Zen ↔ Hub Comercial — plano e perguntas em aberto

Recorte do que o Hub precisa da API Zen. Referência completa da API em
`referencia-api-zen.md`.

Estado em 2026-08-27: **nenhuma integração Zen ativa no Hub.** As credenciais
`ZEN_EMAIL` e `ZEN_SENHA` existem na Vercel, mas nenhum código as usa.

| Tabela SYNC | Linhas hoje | Origem Zen |
|---|---|---|
| `hub_clientes` | 2 | `catalog.person.Person` |
| `hub_representantes` | 0 | `catalog.person.Person` (`personSalesperson`) |
| `hub_titulos` | 0 | `financial.Receivable` |
| `hub_notas_fiscais` | 0 | `fiscal.OutgoingInvoice` |
| `hub_produtos.estoque_disponivel` | 0 em 560 | `material.Stock` / `StockAvailability` |

---

## 1. Estoque — não existe "um campo de estoque"

**Este é o ponto que mais muda em relação ao que se imaginava.** O Zen não expõe
um `saldo_disponivel` pronto. O disponível para venda é uma composição:

```
disponível = Stock.quantity
             onde status = FREE
             e stockCluster ∈ (clusters que valem para revenda)
             − Reservation ativas
```

Três decisões precisam ser tomadas antes de escrever o conector — e nenhuma
delas é técnica:

### 1.1 Quais `stockCluster` contam?

`material.StockCluster` agrupa o estoque. A Boxer tem tipos distintos (máquinas,
avariadas, Mercado Livre). **Vender para revenda o que está no cluster de
avariadas ou reservado ao Mercado Livre seria um erro grave.**

→ Rodar `GET /material/stockCluster` e decidir cluster por cluster.

### 1.2 Reserva conta como indisponível?

`material.Reservation` tem status
`SYSTEM/LOCKED/PREPARING/PREPARED/APPROVED/STARTED/FINISHED/DELETED`.
Uma reserva `PREPARING` provavelmente ainda não deveria bloquear; uma `APPROVED`
provavelmente sim.

→ Definir quais status descontam do disponível.

### 1.3 `Stock` ou `StockAvailability`?

- `material.Stock` — saldo físico atual
- `material.StockAvailability` — projetado, com `type` (INCOMING/OUTGOING/STOCK)
  e `date`

`StockAvailability` é mais interessante para o Hub: além do saldo atual, o campo
`date` das entradas previstas (`INCOMING`) alimenta diretamente
`hub_produtos.previsao_chegada`, que hoje está sempre nulo. Isso destrava o
status "Sob encomenda" com data, em vez de só "Indisponível".

### 1.4 Casamento de SKU

`hub_produtos.sku` ↔ `catalog.product.Product.code`.
Atenção: `SaleItem` e `Stock` referenciam `productPacking`, não `product`
direto — pode haver uma camada de embalagem (unidade vs. caixa) entre os dois.

→ Confirmar se `Product.code` é o mesmo código da tabela de preço, e como
`productPacking` se relaciona com `product`.

---

## 2. Webhook nativo muda a arquitetura

`system.automation.Watcher` (evento + URI) elimina a necessidade de polling.
O padrão passa a ser:

```
Zen (evento) → Watcher → /api/webhook-zen (Vercel) → Supabase
```

Em vez de um cron varrendo a API. Vale para estoque, títulos liquidados e
mudança de status de pedido.

**Lacuna:** a especificação não lista os valores válidos de `Watcher.event` —
é string livre. Confirmar com o fornecedor ou testar em sandbox antes de
desenhar em cima disso.

Enquanto não confirmado, o fallback é `system.automation.Schedule` (CRON) ou um
cron do lado da Vercel.

---

## 3. Pedido — quem é dono do quê

O Hub tem `hub_pedidos` com status próprio
(`rascunho → submetido → em_analise → aprovado → …`). O Zen tem `sale.Sale.status`
(enum técnico fixo) **e** um workflow customizado com as etapas de negócio
(Aguardando Limite, Aguardando Importação…).

São três máquinas de estado para a mesma coisa. **Sem uma decisão explícita de
qual é a fonte da verdade, elas vão divergir.**

Duas opções:

| | Hub como dono | Zen como dono |
|---|---|---|
| Pedido nasce | `hub_pedidos` | `sale.Quote` ou `sale.Sale` via `saleOpCreate` |
| Status | Hub decide, empurra para o Zen | Zen decide, Hub espelha via webhook |
| Risco | Divergir do ERP | Hub depende do Zen estar no ar |

Recomendação: **Zen como dono a partir da submissão.** O Hub é dono do rascunho
e do carrinho; ao submeter, cria um `Quote`/`Sale` no Zen e passa a espelhar o
status. Evita reimplementar regra de crédito e workflow que já existem no ERP.

Note que `sale.Quote` tem `quoteOpSubmit` e `quoteOpApprove` — o pedido do
revendedor encaixa naturalmente como Quote até ser aprovado.

---

## 4. Crédito e títulos

- `financial.credit.CreditLineItem.value` → `hub_clientes.limite_credito`
- `financial.Receivable` → `hub_titulos`; atraso =
  `dueDate < hoje AND status != SETTLED AND balance > 0`
- `financial/receivableOpSettle` é o gatilho de "título pago" — relevante para
  liberar crédito bloqueado

O Hub hoje tem `limite_credito` e `limite_disponivel` preenchidos manualmente.
Com o Zen integrado, viram campos espelhados — não editáveis no Hub.

---

## 5. Sobreposição com o Monitor de Pedidos — decidir antes de construir

O documento `referencia-api-zen.md` foi escrito para o **Monitor de Pedidos**,
outro projeto, que também trata de pedidos, crédito, estoque e workflow do Zen.

**Hub e Monitor tocam os mesmos módulos.** Antes de escrever o conector, definir:

- Existe um conector Zen compartilhado, ou cada projeto faz o seu?
- Se ambos registram `Watcher` para o mesmo evento, quem processa o quê?
- O Monitor decide aprovação de pedido; o Hub também tem
  `hub_pedidos.status = aprovado`. Quem manda?

Duplicar o conector é o caminho mais rápido no curto prazo e o mais caro depois.

---

## 6. Ordem sugerida

1. **Autenticar** — `POST /auth/login`, descobrir o header `Tenant` correto
2. **Explorar** — `GET /material/stockCluster`, `GET /system/workflow/workflow`,
   `GET /system/workflow/workflowNode` no ambiente real, e registrar o que
   existe de fato
3. **Estoque** (menor esforço, destrava o pedido) — conector
   `StockAvailability` → `hub_produtos.estoque_disponivel` + `previsao_chegada`
4. **Clientes e representantes** — `Person` → `hub_clientes`,
   `hub_representantes`, `hub_carteira`
5. **Pedido** — decidir dono (seção 3), então implementar
6. **Títulos e notas** — tela financeira

---

## 7. A confirmar no ambiente real

Nada abaixo deve ser presumido a partir do nome do endpoint:

- [ ] Quais `stockCluster` existem e quais valem para revenda
- [ ] Quais status de `Reservation` descontam do disponível
- [ ] `Product.code` é o mesmo SKU da tabela de preço?
- [ ] Como `productPacking` se relaciona com `product`
- [ ] Valores aceitos por `Watcher.event`
- [ ] Nós de workflow cadastrados (`WorkflowNode`)
- [ ] Se há ambiente de sandbox ou só produção
