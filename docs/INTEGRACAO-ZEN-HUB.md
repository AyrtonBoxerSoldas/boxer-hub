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

### Decidido em 2026-08-27

| Questão | Decisão |
|---|---|
| Quais `stockCluster` | **Somente máquinas novas (`MAQ`).** Todos os demais clusters são ignorados — avariadas, Mercado Livre e afins não podem aparecer como disponíveis para revenda |
| SKU | **Mesmo código entre as fontes** — `hub_produtos.sku` = `Product.code` |
| Unidade | **Sempre item unitário.** A Boxer ainda não trabalha com caixa master, então `productPacking` não introduz conversão por ora |
| Previsão de chegada | **Não puxar do Zen agora** — será resolvida por outro caminho. `hub_produtos.previsao_chegada` continua nulo |

Consequência do recorte `MAQ`: o estoque só terá valor para os produtos de
máquina. Consumíveis, acessórios e peças continuam sem informação — o
`status_estoque = 'sem_info'` da view segue valendo para eles, e o front segue
omitindo o selo. Isso é intencional, não lacuna.

### Em aberto — reserva desconta?

`material.Reservation` tem status
`SYSTEM/LOCKED/PREPARING/PREPARED/APPROVED/STARTED/FINISHED/DELETED`.
Ainda não definido quais descontam do disponível.

**Enquanto não houver decisão, o conector não deve descontar reserva nenhuma** —
e isso precisa estar registrado, porque significa que o Hub pode mostrar como
disponível um item já comprometido. Se isso for inaceitável, a decisão vira
bloqueante.

Caminho para resolver sem adivinhar: comparar, para alguns SKUs de máquina, o
saldo do Zen com o que a operação considera vendável. A diferença mostra quais
reservas contam.

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

**Decidido em 2026-08-27: Zen como dono a partir da submissão.** O Hub é dono do
rascunho e do carrinho; ao submeter, cria um `Quote`/`Sale` no Zen e passa a
espelhar o status. Evita reimplementar regra de crédito e workflow que já existem
no ERP.

`sale.Quote` tem `quoteOpSubmit` e `quoteOpApprove` — o pedido do revendedor
encaixa naturalmente como Quote até ser aprovado.

Implicação prática: `hub_pedidos.status` deixa de ser decidido pelo Hub e passa a
ser campo espelhado. O único status que o Hub controla sozinho é `rascunho`.
`hub_pedidos` ganha uma referência ao id do Zen (`erp_pedido_id`).

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

## 5a. Autenticação REAL — o que a spec não conta

**A spec descreve `/auth/login`, mas não é o que funciona.** O padrão validado em
produção está em `Tekweld/bav-boxer` (`scripts/zen_importador.py`), que importa
vendas do Zen diariamente há meses:

```
POST /system/security/tokenOpRequest
  headers: { tenant: "boxer" }
  body:    { "email": ..., "password": ... }     ← email, não username
  → resposta em TEXTO PURO, o token entre aspas — não é JSON

Demais chamadas:
  Authorization: Bearer <token>
  tenant: boxer
```

Três diferenças em relação ao que a spec sugere, e cada uma quebraria o
conector: endpoint diferente, `email` em vez de `username`, e resposta em texto
em vez de `{accessToken}`.

**`tenant` = `boxer`** — confirmado em dois projetos independentes
(`bav-boxer` e `boxer-app/supabase/functions/sync-zenerp-stock`).

### Sintaxe do filtro `q` — é RSQL/FIQL

A spec declara só `type: string`. O uso real:

```
sale.invoice.date>=2026-08-01;sale.invoice.flow==OUT;(status==APPROVED,status==SHIPMENT)
```

| Operador | Significado |
|---|---|
| `;` | AND |
| `,` | OR |
| `==` / `!=` | igual / diferente |
| `>=` `<=` `>` `<` | comparação |
| `( )` | agrupamento |
| `a.b.c` | navegação por relação |

### ⚠ Bug de paginação conhecido na API Zen

Documentado no `zen_importador.py`, com defesa já implementada:

> *"queries com range de datas entram em loop infinito após o último item real"*

O contorno em produção é fatiar por dia **e** manter um conjunto de ids já
vistos, parando quando a página não traz nada novo. `api/_zen.js` implementa a
mesma proteção (anti-ciclo por id + teto de segurança). **Não remover** achando
que é excesso de zelo — é bug real do fornecedor.

---

## 5b. Contrato declarado na spec (para referência)

Spec pública: `https://api.zenerp.app.br/platform/openapi.json` (2,18 MB,
889 paths, 342 schemas). O Swagger UI aponta para ela via
`swagger-initializer.js`.

```
POST /auth/login
  header: tenant: <valor>          ← obrigatório, inclusive no login
  body:   { "username": "...", "password": "..." }
  → 200:  { "accessToken": "...", "refreshToken": "..." }

Demais chamadas:
  Authorization: Bearer <accessToken>
  tenant: <valor>
```

`securitySchemes`: `Auth` = http bearer JWT · `Tenant` = apiKey no header `tenant`.
Há `POST /auth/refresh` para renovar sem novo login.

**Paginação:** todo GET de listagem aceita `q`, `order`, `first`, `max`. Sem
`max` explícito o servidor provavelmente aplica um default — **paginar sempre**,
pelo mesmo motivo que segurou as fotos da BOM.

**Sintaxe de `q` é desconhecida.** A spec declara só `type: string`, sem
`description`. Precisa ser descoberta em teste — é o que decide se dá para
buscar cliente por CNPJ direto ou se será preciso varrer e filtrar localmente.

### Mapeamento `catalog.person.Person` → `hub_clientes`

| Zen | Hub | Observação |
|---|---|---|
| `id` | `erp_cliente_id` | hoje NULO nos 2 clientes |
| `documentNumber` (com `documentType = BR_CNPJ`) | `cnpj` | **chave de casamento** |
| `name` | `razao_social` | |
| `fantasyName` | `nome_fantasia` | |
| `document2Number` (`BR_INSCRICAO_ESTADUAL`) | `inscricao_estadual` | |
| `email`, `phone` | `email_principal`, `telefone` | |
| `zipcode`/`street`/`number`/`complement`/`district`/`city` | `hub_enderecos` | |
| `personSalesperson` | `representante_id` | **é outra `Person`** |
| `priceListRetail` | `tabela_preco_id` | |
| `category1`–`category5` | `segmento`, `canal`, `porte` | **confirmar antes de usar** |
| — | `limite_credito` | **não vem de Person** → `credit.CreditLineItem` |

`personSalesperson` ser do tipo `Person` significa que **cliente e representante
saem da mesma entidade** — um único conector popula `hub_clientes` e
`hub_representantes`, e `hub_carteira` sai da própria referência.

`catalog.person.PersonCompact` (`id`, `type`, `name`, `fantasyName`,
`documentType`, `documentNumber`, `tags`) é a versão leve — suficiente para o
casamento inicial por CNPJ, sem trafegar o registro completo.

### Duas armadilhas já identificadas

**1. `Person` não tem campo de "ativo"** — nenhum schema de person na spec tem
`active`, `status`, `enabled` ou `blocked`. O critério é de negócio, e foi
definido em 2026-08-27:

> **Quem importar:** pessoas dos canais de venda **Híbrido, Ecommerce e Varejo**,
> cadastradas no Zen, **independente da data**.
>
> **Qual status dar:** com compra nos **últimos 12 meses** → `ativo`.
> Os demais entram como **suspensos** — ficam no Hub, mas não compram.

Duas consequências de arquitetura:

- O canal de venda precisa ser localizado em `Person`. Candidatos: `category1`–
  `category5`, `personGroup` ou `tags` — **a descobrir, não presumir**. É o que
  `api/zen-explorar.js` responde.
- "Compra nos últimos 12 meses" não está em `Person`: exige cruzar com
  `sale.Sale` ou `financial.Receivable` por pessoa. É uma segunda consulta, e
  define `hub_clientes.status_cadastro`.

Suspenso não é o mesmo que inativo: o cliente existe, aparece, mas não fecha
pedido. O RLS precisa refletir isso — hoje `status_cadastro` não é checado em
lugar nenhum.

**2. Formato de CNPJ inconsistente já no Hub:**

```
00.000.000/0001-00     ← com máscara
11222333000181         ← sem máscara
```

O CNPJ é a chave de casamento com `documentNumber`. É o mesmo problema do
`'99032 '` que quebrou o `on_conflict` do catálogo — e desta vez dá para
resolver antes. Normalizar para só dígitos, dos dois lados, com `CHECK`
constraint em `hub_clientes.cnpj`.

O formato usado pelo Zen em `documentNumber` também precisa ser verificado —
não presumir que é só dígitos.

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

Nada abaixo deve ser presumido a partir do nome do endpoint ou do schema:

**Bloqueia o conector de cliente:**
- [ ] Credenciais: `username`, `password` e o valor do header `tenant`
- [ ] Sintaxe do parâmetro `q` — dá para filtrar por CNPJ direto?
- [ ] Formato de `documentNumber` no Zen (com ou sem máscara)
- [ ] **Critério de "cliente ativo"** — `Person` não tem essa flag
- [ ] Uso real de `category1`–`category5` em `Person`

**Depois:**
- [ ] Nós de workflow cadastrados (`WorkflowNode`)
- [ ] Valores aceitos por `Watcher.event`
- [ ] Se há ambiente de sandbox ou só produção

**Pendência declarada — estoque e previsão** (André resolve em outro momento):
- [ ] Quais status de `Reservation` descontam do disponível
- [ ] Código exato do cluster de máquinas novas (`MAQ`)
- [ ] Origem da previsão de chegada (não virá do Zen por ora)
