# HUB-DOC-009: Estrategia de Integracoes

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Principio Fundamental

Toda integracao entre o Boxer Hub e sistemas externos ocorre atraves de **conectores padronizados** (ADR-001). Nenhum modulo do Boxer Hub se comunica diretamente com um sistema externo. Substituir qualquer sistema externo exige apenas uma nova implementacao do conector, sem alterar os modulos consumidores.

---

## 2. Mapa de Sistemas Externos

```
                          ┌───────────────────┐
                          │    BOXER HUB      │
                          │                   │
                          │  Portal Cliente   │
                          │  Portal Rep       │
                          │  Portal ADM       │
                          │  Portal Financeiro│
                          │  CIE              │
                          └────────┬──────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │         CONECTORES          │
                    └──────────────┬──────────────┘
          ┌──────────┬─────────┬──┴───┬──────────┬────────────┐
          ▼          ▼         ▼      ▼          ▼            ▼
    ┌──────────┐┌────────┐┌───────┐┌───────┐┌──────────┐┌─────────┐
    │ ERP ZEN  ││Serasa/ ││Bancos ││Transp.││Politica  ││Comunic. │
    │          ││BoaVista││       ││       ││Comercial ││         │
    │- Pedidos ││- Score ││-Boleto││-Rastr.││- Regras  ││- Email  │
    │- Produtos││- Restr.││-PIX   ││-Frete ││- Precos  ││- WhatsA.│
    │- Estoque ││        ││       ││       ││          ││- Push   │
    │- NF/XML  ││        ││       ││       ││          ││         │
    │- Status  ││        ││       ││       ││          ││         │
    └──────────┘└────────┘└───────┘└───────┘└──────────┘└─────────┘
                                                  ▲
                                          ┌───────┴───────┐
                                          │ boxer-politica │
                                          │ comercial     │
                                          │ .pages.dev    │
                                          └───────────────┘
    ┌──────────┐┌────────┐┌───────┐┌──────────┐
    │ Receita  ││Logist. ││  IA   ││ Bases    │
    │ Federal  ││Dashb.  ││(futuro││ Estaticas│
    │          ││        ││       ││          │
    │- CNPJ   ││-Previs.││- Recom││- Excel   │
    │- Raz.Soc││-Import.││- Score││- CSV     │
    └──────────┘└────────┘└───────┘└──────────┘
```

---

## 3. Inventario de Conectores

| # | Conector | Sistema Externo | Direcao | Prioridade |
|---|---|---|---|---|
| C01 | ERP Connector | ZEN (ERP) | Bidirecional | Critica — MVP |
| C02 | Credit Connector | Serasa / Boa Vista | Hub ← Bureau | Alta — MVP |
| C03 | Bank Connector | Bancos (boletos, PIX) | Hub ← Banco | Alta — MVP |
| C04 | Fiscal Connector | SEFAZ / ERP (NF, XML) | Hub ← ERP/SEFAZ | Alta — MVP |
| C05 | Logistics Connector | Transportadoras | Hub ← Transp. | Media — Expansao |
| C06 | Communication Connector | Email / WhatsApp / Push | Hub → Destino | Alta — MVP |
| C07 | Federal Revenue Connector | Receita Federal | Hub ← RF | Alta — MVP |
| C08 | Commercial Policy Connector | boxer-politica-comercial | Hub ← Site | Media — Expansao |
| C09 | Logistics Dashboard Connector | boxer-dashboard-logistica | Hub ← Dashboard | Media — Expansao |
| C10 | AI Connector | LLM / ML (futuro) | Bidirecional | Baixa — IA |
| C11 | Static Data Connector | Excel/XLSX, CSV, bases estaticas | Hub ← Arquivos | Alta — MVP |

---

## 4. Padrao de Conector

Todo conector segue a mesma estrutura (ADR-001):

```
┌──────────────────────────────────────────┐
│              CONECTOR                     │
│                                          │
│  ┌───────────────┐    ┌───────────────┐  │
│  │  Interface     │    │  Implementacao│  │
│  │  (contrato)    │───▶│  (ZEN, Serasa │  │
│  │                │    │   etc.)       │  │
│  └───────────────┘    └───────┬───────┘  │
│                               │          │
│  ┌───────────────┐    ┌───────┴───────┐  │
│  │  Cache         │    │  Transform   │  │
│  │  (TTL config.) │    │  (Mapeia      │  │
│  │                │    │   formatos)   │  │
│  └───────────────┘    └───────────────┘  │
│                                          │
│  ┌───────────────┐    ┌───────────────┐  │
│  │  Retry/Circuit│    │  Log/Monitor  │  │
│  │  Breaker      │    │              │  │
│  └───────────────┘    └───────────────┘  │
└──────────────────────────────────────────┘
```

### 4.1 Componentes Obrigatorios

| Componente | Funcao |
|---|---|
| **Interface** | Contrato padronizado (TypeScript types). Modulos chamam a interface, nunca a implementacao. |
| **Implementacao** | Logica especifica do sistema externo (chamadas HTTP, parsers, autenticacao). |
| **Transformacao** | Mapeia dados do formato externo para o formato interno e vice-versa. |
| **Cache** | Cache configuravel por operacao (TTL). Reduz chamadas ao sistema externo. |
| **Retry / Circuit Breaker** | Retry com backoff exponencial. Circuit breaker abre apos N falhas consecutivas. |
| **Log / Monitoramento** | Registra toda chamada (sucesso/falha, latencia, payload resumido). |

### 4.2 Implementacao Tecnica

Cada conector e uma ou mais **Supabase Edge Functions** dedicadas:

```
supabase/functions/
├── connectors/
│   ├── erp/
│   │   ├── index.ts          -- entrypoint
│   │   ├── interface.ts      -- tipos/contrato
│   │   ├── zen-impl.ts       -- implementacao ZEN
│   │   ├── transform.ts      -- transformacao de dados
│   │   └── cache.ts          -- cache layer
│   ├── credit/
│   │   ├── index.ts
│   │   ├── interface.ts
│   │   ├── serasa-impl.ts
│   │   └── boavista-impl.ts
│   ├── bank/
│   ├── fiscal/
│   ├── logistics/
│   ├── communication/
│   └── ...
```

---

## 5. Fluxo de Dados por Jornada

### J1 — Cadastro

```
Cliente digita CNPJ
  → C07 (Receita Federal): consulta dados cadastrais → preenche formulario
  → Cliente completa cadastro, envia docs
  → Aprovacao interna (Portal ADM)
  → C02 (Credit): consulta score/restricoes → analise de credito
  → Aprovacao de credito
  → C01 (ERP): cria cadastro no ZEN
  → C06 (Communication): envia boas-vindas (email)
```

### J2 — Pedido

```
Cliente navega catalogo (dados do C01-ERP, espelhados)
  → CIE calcula precos (regras do CIE + C08 Politica Comercial)
  → Cliente adiciona ao carrinho, confirma pedido
  → CIE valida regras (credito, elegibilidade, alcada)
  → C01 (ERP): envia pedido ao ZEN
  → C06 (Communication): confirma ao cliente e representante
```

### J3 — Acompanhamento

```
C01 (ERP): polling a cada 15min → atualiza status do pedido
  → Supabase Realtime: notifica frontend
  → C04 (Fiscal): sincroniza NF/XML quando faturado
  → C05 (Logistics): consulta rastreamento da transportadora
  → C06 (Communication): notifica mudancas de status
```

### J4 — Financeiro

```
C01 (ERP) + C03 (Bank): sincroniza titulos e boletos
  → Cliente consulta no Portal (dados espelhados)
  → Cliente pede segunda via → C03 (Bank): gera novo boleto
  → C04 (Fiscal): fornece NF PDF e XML para download
```

### J5 — Credito

```
Cliente solicita credito
  → C02 (Credit): consulta Serasa/Boa Vista
  → Analista avalia (Portal Financeiro)
  → Decisao → C01 (ERP): atualiza limite no ZEN
  → C06 (Communication): notifica resultado
```

---

## 6. Estrategia de Sincronizacao

### 6.1 Metodos

| Metodo | Quando usar | Conectores |
|---|---|---|
| **Push (tempo real)** | Boxer Hub origina a acao e precisa de resposta imediata | C01 (envio de pedido), C02 (consulta credito), C07 (CNPJ) |
| **Poll (agendado)** | Sistema externo nao oferece webhook | C01 (status), C03 (titulos), C04 (NFs), C05 (rastreio), C09 (previsoes) |
| **Webhook (evento)** | Sistema externo notifica mudancas | C01 (se ZEN suportar), C03 (confirmacao pagamento) |

### 6.2 Frequencias de Polling

| Dado | Frequencia | Justificativa |
|---|---|---|
| Status de pedido | 15 min | Expectativa do cliente de atualizacao rapida |
| Produtos e estoque | 30 min | Estoque nao muda a cada minuto |
| NF/XML | 15 min | Cliente precisa baixar NF logo apos faturamento |
| Titulos/boletos | 1 hora | Vencimentos nao mudam frequentemente |
| Rastreamento | 2 horas | Transportadoras atualizam com baixa frequencia |
| Previsao de estoque | 6 horas | Dados de importacao mudam diariamente |

### 6.3 Conflitos e Prioridade

| Situacao | Resolucao |
|---|---|
| Dado diverge entre Hub e ERP | **ERP vence** para dados transacionais (estoque, status, financeiro) |
| Politica comercial diverge | **Hub vence** — politica e ativo do Boxer Hub (ADR-003) |
| Cadastro diverge | **Hub vence** para dados de contato. ERP vence para dados fiscais. |

---

## 7. Tratamento de Falhas

### 7.1 Degradacao Graciosa

| Conector indisponivel | Comportamento do Boxer Hub |
|---|---|
| C01 (ERP) — leitura | Exibe dados do cache local. Banner "Dados atualizados ate HH:MM" |
| C01 (ERP) — escrita | Enfileira pedido para envio posterior. Status "Aguardando envio ao ERP" |
| C02 (Credit) | Bloqueia aprovacao automatica. Exige aprovacao manual. |
| C03 (Bank) | Boleto indisponivel temporariamente. Exibe mensagem com previsao. |
| C05 (Logistics) | "Rastreamento indisponivel. Ultima atualizacao em DD/MM HH:MM" |
| C06 (Communication) | Enfileira notificacao. Retry automatico. |

### 7.2 Circuit Breaker

```
Estado FECHADO (normal)
  → Chamadas passam normalmente
  → Se 5 falhas consecutivas → abre circuito

Estado ABERTO (falha)
  → Todas as chamadas retornam cache ou erro controlado
  → Apos 60 segundos → half-open

Estado HALF-OPEN (teste)
  → Permite 1 chamada de teste
  → Se sucesso → fecha circuito
  → Se falha → abre novamente
```

### 7.3 Alertas

| Evento | Acao |
|---|---|
| Conector falha 3x seguidas | Log + alerta no painel ADM |
| Circuit breaker abre | Notificacao ao admin (email/push) |
| Polling atrasado > 2x a frequencia | Alerta no dashboard |
| Divergencia de dados detectada | Log para reconciliacao manual |

---

## 8. Seguranca nas Integracoes

| Aspecto | Implementacao |
|---|---|
| Credenciais de APIs externas | Supabase Vault (secrets encriptados) |
| Autenticacao com ERP | API key ou OAuth (conforme ZEN suportar) |
| Autenticacao com bureaus | API key por contrato |
| Transporte | HTTPS obrigatorio em todas as chamadas |
| Dados sensiveis em log | Mascarar CPF, CNPJ, valores (exibir apenas ultimos 4 digitos) |
| Rate limiting | Respeitar limites de cada API externa |

---

## 9. Monitoramento

Dashboard de saude dos conectores no Portal ADM:

| Metrica | Visualizacao |
|---|---|
| Status de cada conector | Semaforo (verde/amarelo/vermelho) |
| Ultima sincronizacao bem-sucedida | Timestamp por conector |
| Taxa de erro (ultimas 24h) | Percentual |
| Latencia media | Milissegundos |
| Fila de retry | Quantidade de itens pendentes |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
