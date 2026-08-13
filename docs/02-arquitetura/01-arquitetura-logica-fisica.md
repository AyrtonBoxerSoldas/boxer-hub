# HUB-DOC-006: Arquitetura Logica e Fisica

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral da Arquitetura

O Boxer Hub adota uma arquitetura de camadas com separacao clara entre experiencia (frontend), logica de negocio (Edge Functions + CIE), dados (Supabase) e integracoes (conectores). O principio fundamental e **connector-first** (ADR-001): nenhum modulo depende diretamente de um sistema externo.

### 1.1 Principios Arquiteturais

| Principio | Descricao |
|---|---|
| **Connector-First** | Toda integracao via conectores padronizados. Substituir ERP nao afeta modulos. |
| **Seguranca em Profundidade** | 6 camadas de defesa (ADR-008). Toda seguranca na camada de aplicacao. |
| **Zero Regras Hardcoded** | CIE avalia 100% das regras comerciais de forma parametrizada. |
| **Operacao Minima** | Supabase gerencia infra (banco, auth, functions). Sem DevOps dedicado. |
| **Frontend Simples** | HTML + JS puro. Sem frameworks. CSS inline. |
| **Dados como Espelho** | Boxer Hub espelha dados do ERP, nao os origina (exceto politica comercial e pesquisas). |

---

## 2. Arquitetura Logica

### 2.1 Diagrama de Camadas

```
┌─────────────────────────────────────────────────────────────────┐
│                     CAMADA DE EXPERIENCIA                       │
│  ┌──────────┐ ┌──────────────┐ ┌───────────┐ ┌──────────────┐  │
│  │ Portal   │ │ Portal       │ │ Portal    │ │ Portal       │  │
│  │ Cliente  │ │ Representante│ │ ADM Vendas│ │ Financeiro   │  │
│  └────┬─────┘ └──────┬───────┘ └─────┬─────┘ └──────┬───────┘  │
│       │               │               │              │          │
│       │    ┌──────────┴───────────────┴──────────────┘          │
│       │    │  Modo Proxy (Representante → Cliente)              │
│       └────┤                                                    │
│            │  Componentes Compartilhados:                       │
│            │  Auth UI, Design System, Navegacao, Notificacoes   │
└────────────┴────────────────────────────────────────────────────┘
             │
             │ HTTPS (JWT em toda requisicao)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAMADA DE LOGICA                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Supabase Edge Functions                      │    │
│  │  ┌──────────────┐  ┌────────────────┐  ┌─────────────┐  │    │
│  │  │ CIE          │  │ Pedidos        │  │ Credito     │  │    │
│  │  │ (Regras      │  │ (Validacao,    │  │ (Consulta,  │  │    │
│  │  │  Comerciais) │  │  envio ERP)    │  │  aprovacao) │  │    │
│  │  └──────────────┘  └────────────────┘  └─────────────┘  │    │
│  │  ┌──────────────┐  ┌────────────────┐  ┌─────────────┐  │    │
│  │  │ Cadastro     │  │ Documentos     │  │ Campanhas/  │  │    │
│  │  │ (Validacao,  │  │ (NF, XML,      │  │ Pesquisas   │  │    │
│  │  │  ativacao)   │  │  Boletos)      │  │             │  │    │
│  │  └──────────────┘  └────────────────┘  └─────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
             │
             │ service_role key (nunca exposta ao frontend)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CAMADA DE DADOS                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │        Supabase (Projeto Dedicado boxer-hubcomercial)     │    │
│  │  ┌──────────────┐  ┌────────────────┐  ┌─────────────┐  │    │
│  │  │ PostgreSQL   │  │ Supabase Auth  │  │ Realtime    │  │    │
│  │  │ (schema      │  │ (JWT, roles,   │  │ (Status     │  │    │
│  │  │  public)     │  │  sessoes)      │  │  updates)   │  │    │
│  │  └──────────────┘  └────────────────┘  └─────────────┘  │    │
│  │  ┌──────────────┐  ┌────────────────┐                    │    │
│  │  │ Storage      │  │ RLS Policies   │                    │    │
│  │  │ (Docs, fotos)│  │ (100% tabelas) │                    │    │
│  │  └──────────────┘  └────────────────┘                    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
             │
             │ Conectores padronizados (ADR-001)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CAMADA DE INTEGRACAO                          │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────────┐   │
│  │ Conector  │ │ Conector  │ │ Conector  │ │ Conector      │   │
│  │ ERP       │ │ Credito   │ │ Logistica │ │ Comunicacao   │   │
│  │ (ZEN)     │ │ (Serasa/  │ │ (Transp.) │ │ (Email/WA)    │   │
│  └─────┬─────┘ │ Boa Vista)│ └─────┬─────┘ └───────┬───────┘   │
│        │       └─────┬─────┘       │               │           │
│  ┌─────┴─────┐ ┌─────┴─────┐ ┌────┴──────┐ ┌──────┴────────┐  │
│  │ Conector  │ │ Conector  │ │ Conector  │ │ Conector      │  │
│  │ Fiscal    │ │ Bancario  │ │ Politica  │ │ IA (futuro)   │  │
│  │ (NF/XML)  │ │ (Boletos) │ │ Comercial │ │               │  │
│  └───────────┘ └───────────┘ └───────────┘ └───────────────┘  │
└─────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SISTEMAS EXTERNOS                             │
│  ERP ZEN │ Serasa │ Boa Vista │ Transportadoras │ Bancos       │
│  SEFAZ   │ Receita Federal │ boxer-politica-comercial.pages.dev│
│  boxer-dashboard-logistica │ Microsoft Graph (email)           │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Descricao das Camadas

**Camada de Experiencia (Frontend)**
- 4 portais HTML + JS puro, hospedados no Netlify
- Compartilham: auth UI, design system Boxer, componentes de navegacao
- Modo Proxy permite ao representante atuar no contexto de qualquer cliente
- Sem dados sensiveis — o frontend e apenas interface
- PWA com Service Worker para Portal Representante (uso em campo)

**Camada de Logica (Edge Functions)**
- Supabase Edge Functions executam toda logica sensivel
- CIE (Motor de Inteligencia Comercial) roda aqui — calcula precos, valida regras, aplica politica comercial
- Cada funcao valida JWT, verifica permissoes e registra no log
- Usa `service_role` key internamente — nunca exposta ao frontend
- Funcoes criticas: calculo de preco, envio de pedido ao ERP, aprovacao de credito, gestao de usuarios

**Camada de Dados (Supabase)**
- Projeto Supabase dedicado `boxer-hubcomercial` (ADR-005/006)
- PostgreSQL com schema `public`, tabelas em snake_case portugues
- RLS ativado em 100% das tabelas
- Supabase Auth gerencia todos os perfis (dealer, rep, analyst, manager, financial, admin)
- Supabase Realtime para atualizacoes de status em tempo real
- Supabase Storage para documentos, fotos de produtos, fichas tecnicas

**Camada de Integracao (Conectores)**
- Cada conector implementa uma interface padronizada (ADR-001)
- Conectores sao Edge Functions dedicadas a integracao
- Transformacao de dados ocorre no conector (formato interno ↔ formato externo)
- Cache, retry e fallback gerenciados pelo conector
- Monitoramento de saude de cada conector

---

## 3. Arquitetura Fisica

### 3.1 Infraestrutura

```
┌─────────────────────────┐     ┌──────────────────────────────┐
│        NETLIFY          │     │         SUPABASE             │
│  (Hospedagem frontend)  │     │  (Projeto boxer-hubcomercial)│
│                         │     │                              │
│  hub.boxersoldas        │     │  ┌────────────────────────┐  │
│  .com.br                │     │  │ PostgreSQL             │  │
│                         │     │  │ (us-east-1 ou sa-east) │  │
│  ┌───────────────────┐  │     │  └────────────────────────┘  │
│  │ index.html        │  │     │  ┌────────────────────────┐  │
│  │ representante.html│  │     │  │ Edge Functions         │  │
│  │ admin.html        │  │     │  │ (Deno runtime)         │  │
│  │ financeiro.html   │  │     │  └────────────────────────┘  │
│  │ login.html        │  │     │  ┌────────────────────────┐  │
│  │ sw.js (PWA)       │  │     │  │ Auth                   │  │
│  └───────────────────┘  │     │  │ (GoTrue)               │  │
│                         │     │  └────────────────────────┘  │
│  SSL/HTTPS automatico   │     │  ┌────────────────────────┐  │
│  CDN global             │     │  │ Realtime               │  │
│                         │     │  │ (WebSocket)             │  │
└─────────────────────────┘     │  └────────────────────────┘  │
                                │  ┌────────────────────────┐  │
                                │  │ Storage                │  │
                                │  │ (Documentos, fotos)    │  │
                                │  └────────────────────────┘  │
                                └──────────────────────────────┘

┌───────────────────────────┐   ┌──────────────────────────────┐
│       GITHUB              │   │     SISTEMAS EXTERNOS        │
│   (Org: Tekweld)          │   │                              │
│                           │   │  ERP ZEN (API REST)          │
│  Repo: boxer-hub          │   │  Serasa/Boa Vista (API)      │
│  CI/CD: GitHub Actions    │   │  Transportadoras (API/EDI)   │
│  Deploy: Netlify           │   │  Bancos (API bancaria)       │
│                           │   │  SEFAZ (NF-e/XML)            │
│  ┌─────────────────────┐  │   │  Receita Federal (CNPJ)      │
│  │ Actions Workflow    │  │   │  Microsoft Graph (email)     │
│  │ push → build → deploy│  │   │  boxer-politica-comercial    │
│  └─────────────────────┘  │   │  boxer-dashboard-logistica   │
└───────────────────────────┘   └──────────────────────────────┘
```

### 3.2 Componentes por Ambiente

| Componente | Tecnologia | Hospedagem | Responsavel |
|---|---|---|---|
| Portal Cliente | HTML/JS/CSS | Netlify | Andre / TI |
| Portal Representante | HTML/JS/CSS + PWA | Netlify | Andre / TI |
| Portal ADM Vendas | HTML/JS/CSS | Netlify | Andre / TI |
| Portal Financeiro | HTML/JS/CSS | Netlify | Andre / TI |
| Edge Functions | TypeScript (Deno) | Supabase | Andre / TI |
| Banco de Dados | PostgreSQL 15+ | Supabase | Andre |
| Autenticacao | GoTrue (Supabase Auth) | Supabase | Andre |
| Storage | Supabase Storage | Supabase | Andre |
| CI/CD | GitHub Actions | GitHub | Andre / TI |
| Codigo | Git | GitHub (Tekweld) | Andre / TI |

### 3.3 Fluxo de Deploy

```
Desenvolvedor → git push → GitHub Actions → Build/Lint → Deploy (Netlify CLI) → Netlify
                                          → supabase db push → Supabase (migrations)
                                          → supabase functions deploy → Edge Functions
```

### 3.4 Ambientes

| Ambiente | URL | Supabase | Proposito |
|---|---|---|---|
| Desenvolvimento | localhost | Supabase local (Docker) | Dev e testes |
| Staging | staging.boxersoldas.com.br | Projeto staging | Validacao antes de prod |
| Producao | hub.boxersoldas.com.br | Projeto boxer-hubcomercial | Producao |

---

## 4. Comunicacao Entre Camadas

### 4.1 Frontend → Supabase (direto)

Operacoes de leitura simples com RLS:
- Listar produtos do catalogo
- Consultar pedidos do cliente autenticado
- Ver titulos financeiros proprios
- Acompanhar status de pedidos (Realtime)

```javascript
const { data } = await supabase
  .from('pedidos')
  .select('*')
  .eq('cliente_id', session.user.id)
  .order('criado_em', { ascending: false });
```

### 4.2 Frontend → Edge Functions (operacoes sensiveis)

Tudo que envolve logica de negocio, escrita critica ou acesso a sistemas externos:

```javascript
const { data } = await supabase.functions.invoke('criar-pedido', {
  body: { itens, condicao_pagamento, observacoes, pedido_cliente }
});
```

### 4.3 Edge Functions → Conectores (integracoes)

Conectores sao chamados exclusivamente por Edge Functions, nunca pelo frontend:

```typescript
// Dentro da Edge Function "criar-pedido"
const erpResponse = await erpConnector.enviarPedido(pedidoValidado);
const notifResponse = await comunicacaoConnector.notificar({
  tipo: 'pedido_confirmado',
  destinatario: cliente.email,
  dados: { numero_pedido, itens }
});
```

### 4.4 Sistemas Externos → Boxer Hub (webhooks/polling)

Atualizacoes de status do ERP e outros sistemas:

```
ERP ZEN → Webhook/Polling → Edge Function "sync-status" → Atualiza banco → Realtime → Frontend
```

| Integracao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| Pedidos | Hub → ERP | Push (API REST) | Tempo real |
| Status do pedido | ERP → Hub | Poll ou Webhook | A cada 15 min |
| Produtos/Estoque | ERP → Hub | Poll | A cada 30 min |
| NF/XML | ERP → Hub | Poll | A cada 15 min |
| Boletos | Banco → Hub | Poll | A cada 1 hora |
| Credito | Bureau → Hub | On-demand | Sob solicitacao |
| Rastreamento | Transp → Hub | Poll | A cada 2 horas |
| Previsao estoque | Logistica → Hub | Poll | A cada 6 horas |

---

## 5. Escalabilidade e Performance

### 5.1 Estrategia de Cache

| Dado | TTL | Estrategia |
|---|---|---|
| Catalogo de produtos | 30 min | Cache em memoria (Edge Function) |
| Precos calculados | 5 min | Cache por cliente (Edge Function) |
| Status de pedido | Tempo real | Supabase Realtime (sem cache) |
| Documentos (NF, XML) | 24 horas | Supabase Storage (imutavel) |
| Dados financeiros | 15 min | Cache por cliente |

### 5.2 Limites e Dimensionamento

| Metrica | Estimativa inicial | Supabase Pro suporta |
|---|---|---|
| Usuarios simultaneos | ~100-300 | Ate 10.000 |
| Requisicoes/segundo | ~50-100 | Ate 1.000 |
| Tamanho do banco | ~5-20 GB | Ate 8 TB |
| Edge Function invocacoes/mes | ~100.000 | 2.000.000 (Pro) |
| Storage | ~10-50 GB | Ate 100 GB (Pro) |

---

## 6. Disponibilidade e Recuperacao

| Aspecto | Estrategia |
|---|---|
| Backup do banco | Supabase: backup diario automatico (Pro) + PITR |
| Monitoramento | UptimeRobot (URL) + Supabase Dashboard |
| Fallback de conectores | Cada conector degrada graciosamente com cache local |
| Disaster Recovery | Restore do backup Supabase + redeploy via GitHub Actions |
| SLA alvo | 99.9% (Netlify + Supabase Pro) |

---

## 7. Decisoes Arquiteturais Relacionadas

| ADR | Impacto na Arquitetura |
|---|---|
| ADR-001 | Define a camada de integracao (conectores) |
| ADR-002 | CIE roda nas Edge Functions, nao no frontend |
| ADR-003 | Politica comercial e dado do Boxer Hub, sincronizado ao ERP |
| ADR-005 | Stack: Netlify + Supabase dedicado (boxer-hubcomercial) |
| ADR-006 | Schema public, tabelas limpas, RLS 100% |
| ADR-007 | AI Connector preparado na camada de integracao |
| ADR-008 | 6 camadas de seguranca na aplicacao |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
