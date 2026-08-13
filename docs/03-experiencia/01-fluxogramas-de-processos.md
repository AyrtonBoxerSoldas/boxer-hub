# HUB-DOC-014: Fluxogramas de Processos

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Convencoes

```
[ Acao ]           = Etapa do processo
< Decisao >        = Ponto de decisao (sim/nao)
(( Sistema ))      = Sistema ou conector envolvido
[[ Ator ]]         = Quem executa
--- notificacao --> = Notificacao automatica
~~~ sync ~~~>      = Sincronizacao de dados
```

Conectores referenciados: C01 ERP (ZEN), C02 Credit (Serasa/Boa Vista), C03 Bank, C04 Fiscal, C05 Logistics, C06 Communication, C07 Federal Revenue, C08 Commercial Policy, C09 Logistics Dashboard, C10 AI.

---

## 2. J1 — Cadastro de Novo Cliente

```
[[ Revendedor OU Representante (Proxy) ]]
              │
              ▼
┌─────────────────────────────┐
│ 1. Acessa pagina de         │
│    pre-cadastro             │
│    (( Boxer Hub Frontend )) │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. Informa CNPJ             │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 3. Consulta automatica      │
│    (( C07 Receita Federal ))│
│    Preenche razao social,   │
│    endereco, atividade      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 4. Complemento cadastral    │
│    (contato, segmento,      │
│     volume estimado)        │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 5. Upload de documentos     │
│    (( Supabase Storage ))   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 6. Submete cadastro         │
│    (( Edge Fn:              │
│       submeter-cadastro ))  │
└──────────────┬──────────────┘
               │
               ├─── notificacao ──► [[ Analista Comercial ]] Push
               ├─── notificacao ──► [[ Representante ]] Push
               │
               ▼
┌─────────────────────────────┐
│ 7. Vinculacao de            │
│    representante            │
│    (( CIE — regra de        │
│       territorialidade ))   │
└──────────────┬──────────────┘
               │
               ▼
      ┌────────────────┐
      │ Se via Proxy:  │
      │ vincula auto   │
      │ ao representante│
      └────────┬───────┘
               │
               ▼
    [[ Analista Comercial (P4) ]]
               │
               ▼
┌─────────────────────────────┐
│ 8. Analise do cadastro      │
│    (( Boxer Hub Portal ADM))│
│    Revisa dados, documentos │
└──────────────┬──────────────┘
               │
               ▼
       < Cadastro completo? >
          │            │
         Nao          Sim
          │            │
          ▼            ▼
  ┌──────────────┐  ┌─────────────────────────┐
  │ Retorna com  │  │ 9. Consulta automatica  │
  │ pendencias   │  │    de credito           │
  │ ao revendedor│  │    (( C02 Serasa/       │
  └──────────────┘  │       Boa Vista ))      │
                    └────────────┬────────────┘
                                 │
                                 ▼
                    < Credito automatico?      >
                    < (valor < limite auto)    >
                         │            │
                        Sim          Nao
                         │            │
                         │            ▼
                         │   [[ Analista Financeiro (P6) ]]
                         │            │
                         │            ▼
                         │   ┌────────────────────────┐
                         │   │ 10. Aprovacao manual    │
                         │   │     de credito          │
                         │   │     (( Portal           │
                         │   │        Financeiro ))    │
                         │   └───────────┬────────────┘
                         │               │
                         │       < Aprovado? >
                         │        │         │
                         │       Sim       Nao
                         │        │         │
                         │        │         ▼
                         │        │   ┌──────────────┐
                         │        │   │ Reprovado    │
                         │        │   │ Notifica     │
                         │        │   │ revendedor   │
                         │        │   └──────────────┘
                         │        │
                         ▼        ▼
                  ┌─────────────────────────┐
                  │ 11. Ativacao no ERP     │
                  │     (( C01 ERP ZEN ))   │
                  │     Cria cliente no ZEN │
                  └────────────┬────────────┘
                               │
                               ▼
                  ┌─────────────────────────┐
                  │ 12. Notificacao e       │
                  │     boas-vindas         │
                  │     (( C06 Email/WA ))  │
                  │     Envia credenciais   │
                  └────────────┬────────────┘
                               │
                               ▼
                        [ Cliente ATIVO ]
```

**Atores:** Revendedor (P1), Representante (P3 — Proxy), Analista Comercial (P4), Analista Financeiro (P6)
**Conectores:** C07, C02, C01, C06
**Decisoes:** Cadastro completo? / Credito automatico? / Aprovado?

---

## 3. J2 — Pedido de Compra

```
[[ Revendedor (P1) OU Representante (Proxy) ]]
              │
              ▼
┌─────────────────────────────┐
│ 1. Acessa catalogo          │
│    (( Boxer Hub Frontend )) │
│    Busca, filtra, navega    │
│    Precos = CIE (calculado) │
│    Estoque = C01 (espelhado)│
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. Seleciona produtos       │
│    Adiciona ao carrinho     │
│    Preco personalizado      │
│    do cliente (CIE)         │
└──────────────┬──────────────┘
               │
               ▼
       < Produto sem estoque? >
          │            │
         Nao          Sim
          │            │
          │            ▼
          │   ┌─────────────────────────┐
          │   │ Exibe previsao de       │
          │   │ chegada (( C09 ))       │
          │   │ Permite adicionar       │
          │   │ ao carrinho (backorder) │
          │   └───────────┬─────────────┘
          │               │
          ▼               ▼
┌─────────────────────────────┐
│ 3. CIE sugere cross-sell,   │
│    upsell, consumiveis      │
│    (( CIE — regras de       │
│       recomendacao ))       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 4. Revisao do carrinho      │
│    Qtd, precos, condicao    │
│    de pagamento, endereco   │
│    Campo "Seu Pedido" (OC)  │
└──────────────┬──────────────┘
               │
               ▼
       < Salvar como cotacao? >
          │            │
         Sim          Nao
          │            │
          ▼            │
  ┌──────────────┐     │
  │ Salva como   │     │
  │ cotacao      │     │
  │ (validade    │     │
  │ parametrizada│     │
  │ pelo CIE)   │     │
  └──────────────┘     │
                       ▼
         ┌─────────────────────────┐
         │ 5. Envia pedido         │
         │    (( Edge Fn:          │
         │       criar-pedido ))   │
         └────────────┬────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │ 6. Validacao CIE        │
         │    - Cliente ativo?     │
         │    - Credito suficiente?│
         │    - Elegibilidade?     │
         │    - Restricoes?        │
         │    (( CIE ))            │
         └────────────┬────────────┘
                      │
                      ▼
              < Aprovacao automatica? >
                 │            │
                Sim          Nao (excecao)
                 │            │
                 │            ▼
                 │   ┌────────────────────────┐
                 │   │ Status = 'em_analise'  │
                 │   │ Fila de aprovacao      │
                 │   └───────────┬────────────┘
                 │               │
                 │    [[ Analista/Gerente (P4/P5) ]]
                 │               │
                 │               ▼
                 │      < Aprovado? >
                 │       │         │
                 │      Sim       Nao
                 │       │         │
                 │       │         ▼
                 │       │   ┌──────────────┐
                 │       │   │ Rejeitado    │
                 │       │   │ (( C06 ))    │
                 │       │   │ Notifica     │
                 │       │   └──────────────┘
                 │       │
                 ▼       ▼
         ┌─────────────────────────┐
         │ 7. Envio ao ERP         │
         │    (( C01 ERP ZEN ))    │
         └────────────┬────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │ 8. Confirmacao          │
         │    (( C06 Email/WA/     │
         │       Push ))           │
         │    Notifica revendedor  │
         │    e representante      │
         └────────────┬────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │ 9. Log de auditoria     │
         │    Se Proxy: registra   │
         │    representante_id,    │
         │    origem =             │
         │    proxy_representante  │
         └────────────┬────────────┘
                      │
                      ▼
              [ Pedido REGISTRADO ]
              [ Timeline iniciada ]
```

**Variantes:**

```
Pedido Rapido:     Etapa 1 → digita SKUs → pula para Etapa 4
Recompra:          Seleciona pedido anterior → Etapa 4 pre-preenchido
Importacao Excel:  Upload planilha → parse → Etapa 4 pre-preenchido
Pedido Recorrente: CIE sugere recompra → confirma → Etapa 5
```

**Atores:** Revendedor (P1), Representante (P3 — Proxy), Analista (P4), Gerente (P5)
**Conectores:** C01, C06, C09
**Decisoes:** Produto sem estoque? / Salvar como cotacao? / Aprovacao automatica? / Aprovado?

---

## 4. J3 — Acompanhamento de Pedido

```
[[ Revendedor (P1) OU Representante (Proxy) ]]
              │
              ▼
┌─────────────────────────────┐
│ 1. Acessa "Meus Pedidos"    │
│    (( Boxer Hub Frontend )) │
│    Lista com filtros:       │
│    status, periodo, valor   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. Seleciona um pedido      │
│    Ve timeline visual:      │
│                             │
│  [x] Recebido      04/08   │
│  [x] Em Analise    04/08   │
│  [x] Aprovado      04/08   │
│  [x] Faturado      05/08   │
│  [x] NF Emitida    05/08   │
│  [ ] Expedido      prev.   │
│  [ ] Em Transito           │
│  [ ] Entregue              │
│                             │
│  Dados: C01 (polling 15min) │
└──────────────┬──────────────┘
               │
               ├────────────────────────────┐
               │                            │
               ▼                            ▼
┌──────────────────────┐   ┌──────────────────────────┐
│ 3. Documentos        │   │ 4. Rastreamento          │
│    do pedido         │   │    da entrega            │
│    - NF em PDF       │   │    (( C05 Logistics ))   │
│    - XML (download)  │   │    Codigo de rastreio    │
│    - Boleto          │   │    Status transportadora │
│    (( C04 Fiscal ))  │   └──────────────────────────┘
│    (( C03 Bank ))    │
└──────────────────────┘

         ┌─────────────────────────────────────────┐
         │ 5. Notificacoes proativas (automaticas)  │
         │    (( C06 Communication ))               │
         │                                          │
         │    pedido.aprovado    → Email + WA + Push │
         │    pedido.faturado    → Email + WA + Push │
         │    pedido.enviado     → Email + WA + Push │
         │    pedido.entregue    → Push              │
         │    pedido.cancelado   → Email + Push      │
         │                                          │
         │    Canais configuraveis pelo usuario      │
         └─────────────────────────────────────────┘
```

**Atores:** Revendedor (P1), Representante (P3 — Proxy)
**Conectores:** C01 (status), C03 (boleto), C04 (NF), C05 (rastreamento), C06 (notificacoes)
**Fluxo passivo:** Dados atualizados via sync automatico, usuario apenas consulta

---

## 5. J4 — Consulta Financeira

```
[[ Revendedor (P1) OU Representante (Proxy) ]]
              │
              ▼
┌─────────────────────────────┐
│ 1. Acessa "Financeiro"      │
│    (( Portal Cliente ))     │
│                             │
│    Exibe resumo:            │
│    ┌──────────────────────┐ │
│    │ Limite: R$ 100.000   │ │
│    │ Disponivel: R$ 45.000│ │
│    │ Vencidos: R$ 8.200   │ │
│    └──────────────────────┘ │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. Consulta titulos         │
│    Filtros: status, periodo,│
│    valor                    │
│    Dados: C01/C03 (polling) │
│    Somente leitura          │
└──────────────┬──────────────┘
               │
       ┌───────┼───────┐
       │       │       │
       ▼       ▼       ▼
┌──────────┐ ┌──────────┐ ┌──────────────┐
│ 3a.      │ │ 3b.      │ │ 3c.          │
│ Segunda  │ │ Download  │ │ Extrato      │
│ via de   │ │ NF/XML   │ │ completo     │
│ boleto   │ │          │ │ com filtros  │
│          │ │ Individual│ │              │
│ (( C03   │ │ ou lote  │ │ Consolidado  │
│   Bank ))│ │          │ │ ERP + Banco  │
│          │ │ (( C04   │ │              │
│ Retorna: │ │  Fiscal))│ │ Somente      │
│ - Boleto │ │          │ │ leitura      │
│   PDF    │ │          │ │              │
│ - Codigo │ │          │ │              │
│   barras │ │          │ │              │
│ - PIX    │ │          │ │              │
└──────────┘ └──────────┘ └──────────────┘
```

**Atores:** Revendedor (P1), Compradora (P2 — download em lote), Representante (P3 — Proxy)
**Conectores:** C01, C03, C04
**Self-service completo:** nenhuma acao requer contato interno

---

## 6. J5 — Solicitacao e Acompanhamento de Credito

```
[[ Revendedor (P1) OU Representante (Proxy) ]]
              │
              ▼
┌─────────────────────────────┐
│ 1. Solicita aumento         │
│    de credito               │
│    (( Edge Fn:              │
│       solicitar-credito ))  │
│    Upload: balanco, DRE,    │
│    referencias              │
└──────────────┬──────────────┘
               │
               ├─── notificacao ──► [[ Analista Financeiro ]] Push
               ├─── notificacao ──► [[ Representante ]] Push
               │
               ▼
┌─────────────────────────────┐
│ 2. Consulta automatica      │
│    a bureaus de credito     │
│    (( C02 Serasa ))         │
│    (( C02 Boa Vista ))      │
│    Score + restricoes       │
│    Cache: 24h               │
└──────────────┬──────────────┘
               │
               ▼
    [[ Analista Financeiro (P6) ]]
               │
               ▼
┌─────────────────────────────┐
│ 3. Analise                  │
│    (( Portal Financeiro ))  │
│    Score, historico de      │
│    compras, documentos,     │
│    regras CIE               │
└──────────────┬──────────────┘
               │
               ▼
       < Valor dentro da alcada? >
          │            │
         Sim          Nao
          │            │
          │            ▼
          │   [[ Gerente (P5) OU Admin ]]
          │            │
          ▼            ▼
┌─────────────────────────────┐
│ 4. Decisao                  │
│    (( Edge Fn:              │
│       decidir-credito ))    │
└──────────────┬──────────────┘
               │
               ▼
       < Decisao >
       │         │         │
   Aprovado  Aprovado   Reprovado
              Parcial
       │         │         │
       ▼         ▼         ▼
┌──────────────────────────────────────────────┐
│ 5. Atualiza limite                           │
│    (( C01 ERP ZEN )) — atualiza limite no ERP│
│    (( C06 Communication ))                   │
│    Notifica revendedor + representante       │
│    Log de auditoria completo                 │
└──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 6. Acompanhamento           │
│    Timeline similar a       │
│    pedidos:                 │
│    [x] Solicitado           │
│    [x] Bureau consultado    │
│    [x] Em analise           │
│    [x] Aprovado (R$ 80k)   │
│    (( Portal Cliente ))     │
└─────────────────────────────┘
```

**Atores:** Revendedor (P1), Representante (P3 — Proxy), Analista Financeiro (P6), Gerente (P5)
**Conectores:** C02, C01, C06
**Decisoes:** Valor dentro da alcada? / Decisao (aprovado/parcial/reprovado)
**Alcadas:** Manager ate R$ 100k, Admin acima de R$ 100k

---

## 7. J6 — Gestao de Carteira (Representante)

```
[[ Representante (P3) ]]
              │
              ▼
┌──────────────────────────────────┐
│ 1. Dashboard da carteira         │
│    (( Portal Representante ))    │
│                                  │
│    ┌─────────────────────────┐   │
│    │ Clientes ativos: 42     │   │
│    │ Faturamento mes: R$ 280k│   │
│    │ Meta: R$ 350k (80%)     │   │
│    │ Pedidos em andamento: 8 │   │
│    └─────────────────────────┘   │
│                                  │
│    Alertas:                      │
│    ⚠ 3 clientes sem compra >30d │
│    ✓ 2 creditos liberados        │
│    ⚠ 1 pedido com problema       │
└──────────────┬───────────────────┘
               │
       ┌───────┼───────────────┐
       │       │               │
       ▼       ▼               ▼
┌──────────┐ ┌──────────────┐ ┌──────────────┐
│ 2. Visao │ │ 3. Acao      │ │ 4. Monitor.  │
│ do       │ │ comercial    │ │ de pedidos   │
│ cliente  │ │              │ │              │
│          │ │ Cria cotacao │ │ Todos os     │
│ Ultimo   │ │ em campo     │ │ pedidos dos  │
│ pedido   │ │ com preco    │ │ seus clientes│
│ Historico│ │ correto      │ │              │
│ Credito  │ │ (CIE)       │ │ Filtro por   │
│ Produtos │ │              │ │ status,      │
│ favoritos│ │ Envia via    │ │ cliente,     │
│          │ │ WA/email     │ │ periodo      │
│ Sugestoes│ │ (( C06 ))   │ │              │
│ CIE      │ │              │ │              │
└──────────┘ └──────────────┘ └──────────────┘

               │
               ▼
┌──────────────────────────────────┐
│ 5. Performance                   │
│    Vendas vs meta (grafico)      │
│    Comissoes acumuladas          │
│    Ranking entre representantes  │
│    Dados: CIE + C01 (ERP)       │
└──────────────────────────────────┘

         ┌──────────────────────────────────┐
         │ MODO PROXY (transversal)         │
         │                                  │
         │ A partir da visao do cliente,    │
         │ o representante pode:            │
         │                                  │
         │ → Fazer pedido (J2) em nome      │
         │   do cliente                     │
         │ → Ver financeiro (J4) do cliente │
         │ → Solicitar credito (J5) para    │
         │   o cliente                      │
         │ → Iniciar cadastro (J1) de       │
         │   novo cliente                   │
         │                                  │
         │ Todas as acoes registram:        │
         │ representante_id + cliente_id    │
         │ + origem = proxy_representante   │
         └──────────────────────────────────┘
```

**Atores:** Representante (P3)
**Conectores:** C01 (dados ERP), C06 (envio de cotacao), CIE (precos, sugestoes)
**Portal:** Representante (mobile-first)

---

## 8. J7 — Gestao de Politica Comercial (ADM)

```
[[ Gerente Comercial (P5) ]]
              │
              ▼
┌─────────────────────────────────────┐
│ 1. Acessa "Politica Comercial"      │
│    no Portal ADM Vendas             │
│    (( Boxer Hub Portal ADM ))       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Redireciona ao sistema externo   │
│    (( boxer-politica-comercial      │
│       .pages.dev ))                 │
│    Iframe ou link direto            │
│    Boxer Hub NAO reconstroi —       │
│    apenas integra                   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 3. Gestao de regras                 │
│    (no sistema existente)           │
│    Cria/edita regras comerciais     │
│    Publica alteracoes               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 4. CIE consome regras publicadas    │
│    (( C08 Commercial Policy ))      │
│    Polling a cada 1 hora            │
│    Alimenta calculo de precos,      │
│    elegibilidade, descontos,        │
│    restricoes                       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 5. Monitoramento no Boxer Hub       │
│    (( Portal ADM Vendas ))          │
│    Como regras estao sendo          │
│    aplicadas nos pedidos:           │
│    - Excecoes concedidas            │
│    - Desvios da politica            │
│    - Aprovacoes manuais             │
│    (( CIE — logs de avaliacao ))    │
└─────────────────────────────────────┘
```

**Atores:** Gerente Comercial (P5)
**Conectores:** C08 (polling politica comercial)
**Nota:** Sistema de politica comercial ja existe em producao — Boxer Hub integra, nao reconstroi

---

## 9. J8 — Pesquisas e Promocoes (Engajamento)

### 9.1 Fluxo de Pesquisas

```
[[ Gerente Comercial (P5) OU Analista (P4) ]]
              │
              ▼
┌─────────────────────────────────────┐
│ 1. Cria pesquisa                    │
│    (( Edge Fn: criar-pesquisa ))    │
│    - Titulo, descricao             │
│    - Perguntas (multipla escolha,  │
│      escala, texto livre)          │
│    - Publico-alvo (canal, regiao,  │
│      representante)               │
│    - Vigencia (inicio/fim)         │
│    - Obrigatoria ou opcional       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Publica pesquisa                 │
│    (( C06 Communication ))          │
│    Notifica revendedores do         │
│    publico-alvo (email + push)      │
└──────────────┬──────────────────────┘
               │
               ▼
    [[ Revendedor (P1) ]]
               │
               ▼
┌─────────────────────────────────────┐
│ 3. Responde pesquisa                │
│    (( Portal Cliente ))             │
│    Card/banner no dashboard         │
│    ou area dedicada                 │
│    (( Edge Fn:                      │
│       responder-pesquisa ))         │
└──────────────┬──────────────────────┘
               │
       < Pesquisa obrigatoria? >
          │            │
         Sim          Nao
          │            │
          ▼            │
  ┌──────────────┐     │
  │ Bloqueia     │     │
  │ acoes ate    │     │
  │ responder    │     │
  └──────────────┘     │
                       │
               ┌───────┘
               ▼
    [[ Gerente Comercial (P5) ]]
               │
               ▼
┌─────────────────────────────────────┐
│ 4. Monitora respostas em tempo real │
│    (( Portal ADM ))                 │
│    Total, % por regiao, graficos    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 5. Relatorio consolidado           │
│    (( Edge Fn:                      │
│       relatorio-pesquisa ))         │
│    Exportavel CSV/PDF               │
│    Analise por segmento             │
└─────────────────────────────────────┘
```

### 9.2 Fluxo de Promocoes

```
[[ Gerente Comercial (P5) OU Analista (P4) ]]
              │
              ▼
┌─────────────────────────────────────┐
│ 1. Configura campanha               │
│    (( Edge Fn: criar-campanha ))    │
│    - Produtos incluidos            │
│    - Tipo desconto (%, fixo,       │
│      preco especial)               │
│    - Vigencia (inicio/fim)         │
│    - Publico-alvo                  │
│    - Banner/badge visual           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ 2. Ativacao automatica              │
│    (conforme data de inicio)        │
│    Sinalizacao no Portal Cliente:   │
│                                     │
│    ┌───────────────────────────┐    │
│    │ ★ BANNER DESTAQUE ★      │    │
│    │ Topo do catalogo          │    │
│    └───────────────────────────┘    │
│                                     │
│    ┌──────────┐                    │
│    │ PROMOCAO │ Badge nos produtos │
│    └──────────┘                    │
│                                     │
│    R$ 150,00  →  R$ 120,00         │
│    (preco riscado + promocional)   │
│                                     │
│    "Valido ate 30/09"              │
│    (contador de vigencia)          │
│                                     │
│    Area "Promocoes Ativas"         │
│    no dashboard                    │
└──────────────┬──────────────────────┘
               │
               ├─── notificacao ──► [[ Revendedores ]] Email + Push
               ├─── notificacao ──► [[ Representantes ]] Push
               │
               ▼
    [[ Revendedor (P1) ]]
               │
               ▼
┌─────────────────────────────────────┐
│ 3. Navega catalogo                  │
│    Ve promocoes sinalizadas         │
│    Filtro rapido "So promocoes"     │
│    Precos calculados pelo CIE       │
│    (( Portal Cliente ))             │
└──────────────┬──────────────────────┘
               │
               ▼
    [[ Gerente Comercial (P5) ]]
               │
               ▼
┌─────────────────────────────────────┐
│ 4. Monitoramento                    │
│    (( Portal ADM ))                 │
│    Vendas, adesao, ROI              │
│    Antes/durante/apos campanha      │
└─────────────────────────────────────┘

         ┌─────────────────────────────────────┐
         │ ENCERRAMENTO AUTOMATICO             │
         │                                     │
         │ Cron diario (00:00 BRT):            │
         │ Desativa campanhas com              │
         │ vigencia_fim passada                │
         │ Remove sinalizacao visual           │
         │ Gera relatorio de performance       │
         └─────────────────────────────────────┘
```

**Atores:** Gerente (P5), Analista (P4), Revendedor (P1), Representante (P3)
**Conectores:** C06 (notificacoes), CIE (precos promocionais)
**Decisoes:** Pesquisa obrigatoria?

---

## 10. Fluxo Transversal: Backorder

```
         ┌─────────────────────────────────────┐
         │ FASE 1: PEDIDO COM BACKORDER        │
         └──────────────┬──────────────────────┘
                        │
[[ Revendedor ]]        ▼
         ┌─────────────────────────────────────┐
         │ Produto sem estoque                  │
         │ Catalogo exibe:                      │
         │ "Sem estoque — Previsao: 15/09"     │
         │ (( C09 Logistics Dashboard ))        │
         │                                      │
         │ Revendedor adiciona ao carrinho      │
         │ e confirma pedido                    │
         └──────────────┬──────────────────────┘
                        │
                        ▼
         ┌─────────────────────────────────────┐
         │ Pedido criado com:                   │
         │ - pedido_item.backorder = true       │
         │ - pedido_item.previsao_entrega       │
         │ - Entra na fila de backorder (FIFO)  │
         └──────────────┬──────────────────────┘
                        │
         ┌──────────────┴──────────────────────┐
         │ FASE 2: ATUALIZACAO DE PREVISAO     │
         └──────────────┬──────────────────────┘
                        │
                        ▼
         ┌─────────────────────────────────────┐
         │ Sync de previsao de estoque          │
         │ (( C09 — polling cada 6h ))          │
         │                                      │
         │ Previsao mudou?                      │
         │   Sim → Atualiza previsao_chegada    │
         │         Notifica clientes com        │
         │         backorder pendente           │
         │         (( C06 Email ))              │
         │   Nao → Nenhuma acao                 │
         └──────────────┬──────────────────────┘
                        │
         ┌──────────────┴──────────────────────┐
         │ FASE 3: ESTOQUE REPOSTO             │
         └──────────────┬──────────────────────┘
                        │
                        ▼
         ┌─────────────────────────────────────┐
         │ Sync de estoque (( C01 — 30min ))    │
         │ Detecta: estoque_disponivel > 0      │
         │ (produto que estava zerado)           │
         │                                      │
         │ → Evento: produto.estoque_reposto    │
         └──────────────┬──────────────────────┘
                        │
                        ▼
         ┌─────────────────────────────────────┐
         │ Processa fila de backorder (FIFO)    │
         │                                      │
         │ Para cada pedido na fila:            │
         │ 1. Reserva estoque disponivel        │
         │ 2. Atualiza status do pedido         │
         │ 3. Envia ao ERP (( C01 ))            │
         │ 4. Notifica cliente + rep (( C06 ))  │
         │                                      │
         │ < Estoque suficiente para todos? >   │
         │   Sim → Processa todos               │
         │   Nao → Processa por ordem FIFO      │
         │         ate acabar estoque            │
         │         Restantes permanecem na fila  │
         └─────────────────────────────────────┘
```

---

## 11. Fluxo Transversal: Modo Proxy

```
[[ Representante (P3) ]]
              │
              ▼
┌─────────────────────────────┐
│ 1. Login com credenciais    │
│    proprias (role = rep)    │
│    (( Supabase Auth ))      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. Ve lista de clientes     │
│    da sua carteira          │
│    (( RLS: carteira.        │
│       representante_id ))   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 3. Seleciona cliente        │
│    Seletor fica visivel     │
│    no topo da tela          │
└──────────────┬──────────────┘
               │
               ▼
       < Cliente na carteira? >
          │            │
         Sim          Nao
          │            │
          │            ▼
          │     [ Acesso negado ]
          │
          ▼
┌─────────────────────────────┐
│ 4. Modo Proxy ativado       │
│    Todas as acoes passam    │
│    a registrar:             │
│    - representante_id       │
│    - cliente_id             │
│    - origem =               │
│      proxy_representante    │
│    - IP e timestamp         │
└──────────────┬──────────────┘
               │
       ┌───────┼───────┐───────┐
       │       │       │       │
       ▼       ▼       ▼       ▼
    [ J1 ]  [ J2 ]  [ J4 ]  [ J5 ]
   Cadastro Pedido  Financ. Credito
               │
               ▼
┌─────────────────────────────┐
│ 5. Cliente notificado       │
│    "Pedido #X criado pelo   │
│     seu representante"      │
│    (( C06 Communication ))  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 6. Portal Cliente exibe     │
│    badge "Criado pelo       │
│    representante"           │
│    Historico mostra quem    │
│    criou cada acao          │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 7. Log de auditoria         │
│    (( log_alteracoes ))     │
│    INSERT-only, imutavel    │
│    Sessao proxy completa    │
└─────────────────────────────┘
```

---

## 12. Fluxo de Sincronizacao (Conectores)

```
         ┌────────────────────────────────────────────┐
         │           FLUXO DE SYNC (POLLING)           │
         └────────────────┬───────────────────────────┘
                          │
      ┌───────────────────┼───────────────────┐
      │                   │                   │
      ▼                   ▼                   ▼
┌───────────┐      ┌───────────┐      ┌───────────┐
│ pg_cron   │      │ GitHub    │      │ cron-job  │
│ (Supabase)│      │ Actions   │      │ .org      │
│ Principal │      │ Backup    │      │ Redundanc.│
└─────┬─────┘      └─────┬─────┘      └─────┬─────┘
      │                   │                   │
      └───────────────────┼───────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   Edge Function       │
              │   (sync-*)            │
              │                       │
              │   1. Autentica via    │
              │      service_role     │
              │   2. Chama conector   │
              │   3. Compara hash     │
              │      antes/depois     │
              │   4. Se mudou:        │
              │      upsert +         │
              │      dispara evento   │
              │   5. Se falhou:       │
              │      circuit breaker  │
              │      + fila retry     │
              └───────────┬───────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
   ┌────────────┐  ┌────────────┐  ┌────────────┐
   │ Sucesso    │  │ Sem        │  │ Falha      │
   │            │  │ mudanca    │  │            │
   │ Upsert    │  │            │  │ Circuit    │
   │ Evento    │  │ Nenhuma    │  │ breaker    │
   │ Log       │  │ acao       │  │ Retry      │
   │            │  │            │  │ queue      │
   └────────────┘  └────────────┘  └────────────┘

FREQUENCIAS:
┌──────────────────────┬──────────┐
│ sync-produtos        │ 30 min   │
│ sync-estoque         │ 30 min   │
│ sync-status-pedidos  │ 15 min   │
│ sync-titulos         │ 1 hora   │
│ sync-notas-fiscais   │ 15 min   │
│ sync-rastreamento    │ 2 horas  │
│ sync-previsao-estoque│ 6 horas  │
└──────────────────────┴──────────┘
```

---

## 13. Resumo de Conectores por Jornada

| Jornada | Conectores Envolvidos | Frequencia |
|---|---|---|
| J1 Cadastro | C07, C02, C01, C06 | Sob demanda |
| J2 Pedido | C01, C06, C09, CIE | Sob demanda + polling |
| J3 Acompanhamento | C01, C03, C04, C05, C06 | Polling (15min-2h) |
| J4 Financeiro | C01, C03, C04 | Polling (15min-1h) |
| J5 Credito | C02, C01, C06 | Sob demanda |
| J6 Carteira | C01, C06, CIE | Polling + sob demanda |
| J7 Politica Comercial | C08 | Polling (1h) |
| J8 Pesquisas/Promocoes | C06, CIE | Sob demanda + cron |
| Backorder | C01, C06, C09 | Polling (30min-6h) |
| Modo Proxy | Todos (contexto do cliente) | Conforme jornada |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
