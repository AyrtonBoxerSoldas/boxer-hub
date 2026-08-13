# HUB-DOC-020: Epicos

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Estrutura

Os epicos estao organizados em 3 trilhas conforme a estrategia de lancamento (Abordagem B — piloto com 3-5 revendedores).

| Trilha | Foco | Quando |
|---|---|---|
| **T1** | Infraestrutura + Portal Cliente + ADM operacional | MVP (piloto) |
| **T2** | Conectores (ZEN, dados estaticos, futuros) | Paralela a T1 |
| **T3** | Expansao (Representante, Financeiro, Admin, J8) | Pos-piloto |

---

## 2. Trilha 1 — MVP (Portal Cliente + ADM Operacional)

### E01: Infraestrutura Base

**Prioridade:** Critica — Pré-requisito de tudo
**Jornada:** Transversal
**Portal:** Todos

| Item | Descricao |
|---|---|
| Objetivo | Criar o alicerce tecnico: projeto Supabase, auth, schema, deploy pipeline |
| Entrega | Projeto `boxer-hubcomercial` operacional, auth funcional, CI/CD no Netlify |
| Dependencias | Nenhuma |

Escopo:
- Criar projeto Supabase `boxer-hubcomercial`
- Definir schemas (`comercial`, `auth`, `config`)
- Configurar Supabase Auth (email + senha, roles no user_metadata)
- Criar tabelas core (clientes, usuarios, log_alteracoes)
- Ativar RLS em todas as tabelas
- Repositorio `boxer-hub` no GitHub Tekweld
- Deploy pipeline: GitHub → Netlify
- URL: `hub.boxersoldas.com.br`
- Design system base (topbar, paleta, Outfit, componentes)
- Tela de login funcional

---

### E02: Catalogo e PDP

**Prioridade:** Critica — MVP
**Jornada:** J2 (parcial)
**Portal:** Cliente

| Item | Descricao |
|---|---|
| Objetivo | Revendedor navega, busca e entende produtos com confianca |
| Entrega | Grid de produtos, PDP completa, busca, filtros |
| Dependencias | E01 (infra), E09 (C01 para dados reais) |

Escopo:
- Grid de cards (foto, SKU, nome, preco CIE, badge promo, estoque)
- Toggle grid/lista
- Busca por texto e SKU
- Filtros: categoria, disponibilidade, preco, promocao
- Navegacao por equipamento (categoria → subcategoria → modelo)
- Breadcrumbs
- PDP: galeria de fotos com zoom, ficha tecnica (grade), "O que acompanha", descricao abaixo, documentos para download, produtos relacionados
- Badge de backorder com previsao de chegada
- Badge "MAIS VENDIDO", "PROMO", "% OFF" nos cards
- Preco original riscado + preco CIE em destaque
- Condicao de pagamento visivel no card (28/35/42 dias)
- Compartilhar via WhatsApp na PDP

---

### E03: Pedido de Compra

**Prioridade:** Critica — MVP
**Jornada:** J2
**Portal:** Cliente

| Item | Descricao |
|---|---|
| Objetivo | Revendedor coloca pedido completo com CIE, backorder e cotacao |
| Entrega | Carrinho, checkout, cotacoes, pedido rapido, recompra |
| Dependencias | E02 (catalogo), E09 (C01) |

Escopo:
- Carrinho: lista de itens, indicador backorder, sugestoes CIE (cross-sell)
- Condicao de pagamento (select)
- Endereco de entrega (select entre cadastrados)
- Campo "Seu Pedido (OC)" — numero interno do revendedor
- Observacoes (textarea)
- Resumo: subtotal, desconto CIE, total
- Validacao de credito antes de enviar (alerta se excede limite)
- Salvar como cotacao (com validade parametrizavel)
- Enviar pedido → validacao CIE → fila de aprovacao ou envio direto
- Pedido rapido: digitar SKUs + quantidade linha a linha
- Importacao Excel/CSV (P2 — Marina)
- Recompra: selecionar pedido anterior, reenvia com 1 clique
- Cross-sell banner: "Adicione mais e ganhe frete gratis"
- Badge frete gratis (regra CIE por tier)

---

### E04: Acompanhamento de Pedido

**Prioridade:** Critica — MVP
**Jornada:** J3
**Portal:** Cliente

| Item | Descricao |
|---|---|
| Objetivo | Revendedor acompanha pedido sem ligar para ninguem |
| Entrega | Lista de pedidos, timeline, documentos, rastreamento |
| Dependencias | E03 (pedidos), E09 (C01 para status) |

Escopo:
- Lista de pedidos com filtros (status, periodo, valor)
- Busca por numero do pedido ou OC
- Cada linha: numero, data, valor, status (badge colorido), OC
- Detalhe do pedido: timeline visual de status (10 etapas)
- Badge "Criado pelo representante" (se Modo Proxy)
- Itens do pedido (tabela)
- Dados: condicao pagamento, endereco, OC
- Documentos: NF (PDF), XML, boleto — download direto
- Rastreamento: codigo + status da transportadora
- Botao "Recomprar este pedido"
- Cotacoes: lista, detalhe, converter em pedido, editar

---

### E05: Financeiro do Cliente

**Prioridade:** Alta — MVP
**Jornada:** J4
**Portal:** Cliente

| Item | Descricao |
|---|---|
| Objetivo | Revendedor consulta financeiro e resolve boletos sozinho |
| Entrega | Titulos, NFs, extrato, segunda via de boleto |
| Dependencias | E01 (infra), E09 (C01), E11-C03 (conector bancario) |

Escopo:
- Dashboard financeiro: KPIs (limite total, disponivel, titulos vencidos), grafico de evolucao
- Titulos: filtros (status, periodo, valor), tabela, segunda via (boleto + PIX), comprovante
- Notas Fiscais: filtros, download PDF, download XML, download XML em lote (P2)
- Extrato: lista cronologica, filtro por periodo, exportar CSV
- Antecipacao de pagamento: selecionar titulos, gerar boleto consolidado, credito liberado apos confirmacao

---

### E06: Gestao de Credito

**Prioridade:** Alta — MVP
**Jornada:** J5
**Portal:** Cliente

| Item | Descricao |
|---|---|
| Objetivo | Revendedor gerencia credito com autonomia |
| Entrega | Dashboard de credito, solicitacao de aumento, antecipacao |
| Dependencias | E01 (infra), E05 (financeiro) |

Escopo:
- KPI clicavel no dashboard: credito disponivel / total aprovado
- Barra de progresso: verde (<60%), laranja (<85%), vermelho (>=85%)
- Historico de solicitacoes (timeline)
- Solicitar aumento: valor desejado, justificativa, upload de documentos
- Alerta no carrinho quando credito insuficiente (com botoes de acao)
- Bloqueio de checkout quando total > credito disponivel
- Antecipacao de pagamento para liberar credito

---

### E07: Cadastro de Cliente

**Prioridade:** Alta — MVP
**Jornada:** J1
**Portal:** Cliente + ADM

| Item | Descricao |
|---|---|
| Objetivo | Novo revendedor se cadastra e e aprovado digitalmente |
| Entrega | Pre-cadastro, analise, aprovacao, ativacao |
| Dependencias | E01 (infra), E08 (ADM para aprovacao) |

Escopo:
- Pre-cadastro publico (`/cadastro`): CNPJ com consulta automatica (Receita Federal), preenchimento automatico, complemento cadastral, upload de documentos, termos de uso
- 5 etapas: empresa, endereco, entrega, contato, bancario
- Meu Cadastro (read-only): visualizacao de todos os dados, botao "Solicitar Alteracao" com selecao de secao + textarea
- Fila de aprovacao no ADM
- Vinculacao automatica de representante (por regiao)
- Notificacao de boas-vindas com credenciais

---

### E08: Portal ADM Vendas — Operacional

**Prioridade:** Alta — MVP
**Jornada:** J1, J2, J7 (parcial)
**Portal:** ADM Vendas

| Item | Descricao |
|---|---|
| Objetivo | Analistas e gerentes processam cadastros, aprovam pedidos, gerenciam clientes |
| Entrega | Dashboard ADM, filas de trabalho, aprovacoes, gestao de clientes e representantes |
| Dependencias | E01 (infra), E03 (pedidos), E07 (cadastro) |

Escopo:
- Dashboard operacional: KPIs (pedidos hoje, pendentes, cadastros pendentes), fila priorizada, pipeline visual
- Gestao de pedidos: filtros, tabela, fila de aprovacao com alcada (analyst ate R$50k, manager ate R$200k)
- Detalhe do pedido ADM: timeline, regras CIE aplicadas, historico de acoes, aprovar/rejeitar
- Excecoes comerciais: lista, historico, analise por frequencia/valor/representante
- Gestao de cadastros: fila pendente, analise de cadastro (docs, consulta RF, bureau), aprovar/rejeitar/solicitar complemento
- Base de clientes: busca, filtros, ficha do cliente (dados, historico, tabela de precos, log)
- Gestao de representantes: lista, ficha, carteira, performance
- Tabelas de precos: lista, criar, editar, vincular cliente, historico de versoes
- Politica comercial: acesso ao sistema externo (boxer-politica-comercial), monitoramento de aplicacao

---

## 3. Trilha 2 — Conectores

### E09: Conector ERP ZEN (C01)

**Prioridade:** Critica — MVP
**Jornada:** Transversal
**Portal:** Todos (fornece dados)

| Item | Descricao |
|---|---|
| Objetivo | Sincronizar dados bidirecionalmente com o ERP ZEN |
| Entrega | C01 operacional: produtos, estoque, pedidos, NFs, titulos, clientes |
| Dependencias | E01 (infra — Supabase Vault para credenciais) |

Escopo:
- `getProducts()` — ERP → Hub, poll 30min
- `getStock()` — ERP → Hub, poll 30min
- `getOrderStatus()` — ERP → Hub, poll 15min
- `submitOrder()` — Hub → ERP, tempo real
- `getInvoices()` — ERP → Hub, poll 15min
- `getFinancialTitles()` — ERP → Hub, poll 1h
- `createClient()` — Hub → ERP, tempo real
- `updateCreditLimit()` — Hub → ERP, tempo real
- Fila de integracao para retries (tabela `fila_integracao`)
- Circuit breaker com fallback para cache local
- Transform layer: formato ZEN ↔ formato Hub

---

### E10: Conector Static Data (C11)

**Prioridade:** Alta — MVP
**Jornada:** Transversal
**Portal:** ADM (config), todos (consumo)

| Item | Descricao |
|---|---|
| Objetivo | Ingerir dados de planilhas, CSVs e SharePoint que o ZEN nao tem |
| Entrega | C11 operacional: import de Excel/XLSX, validacao, mapeamento |
| Dependencias | E01 (infra) |

Escopo:
- `importarPlanilha()` — upload de Excel/XLSX/CSV com mapeamento de colunas
- `syncSharePoint()` — sincronizacao automatica de arquivos do SharePoint (Microsoft Graph)
- `validarDados()` — validacao de schema, tipos, obrigatoriedade
- Tipos de dados suportados: fichas tecnicas detalhadas, tabelas de compatibilidade, segmentacao de clientes, historico de importacao
- Interface de mapeamento no Portal ADM (arrastar colunas)
- Log de importacao com sucesso/erro por linha
- 8 passos: upload → deteccao → preview → mapeamento → validacao → conflitos → persistencia → log

---

### E11: Conectores de Suporte (C02-C10)

**Prioridade:** Media a Baixa — Incremental
**Jornada:** Varias
**Portal:** Varios

| Conector | Prioridade | Fase | Escopo resumido |
|---|---|---|---|
| C02 — Credit (Serasa/Boa Vista) | Media | Pos-piloto | Consulta score e restricoes |
| C03 — Banking | Alta | MVP | Segunda via boleto, PIX, confirmacao pagamento |
| C04 — Fiscal | Alta | MVP | NF PDF, XML, chave de acesso |
| C05 — Logistics | Media | Pos-piloto | Rastreamento, calculo de frete por CEP |
| C06 — Communication | Alta | MVP | Email transacional, WhatsApp (notificacoes) |
| C07 — Receita Federal | Alta | MVP | Consulta CNPJ, preenchimento automatico |
| C08 — Politica Comercial | Alta | MVP | Consumo de regras do boxer-politica-comercial |
| C09 — Logistics Dashboard | Baixa | Futuro | Previsao de importacao, ETA |
| C10 — IA | Baixa | Futuro | Recomendacoes, score preditivo |

---

## 4. Trilha 3 — Expansao

### E12: Portal Representante + Modo Proxy

**Prioridade:** Alta — Pos-piloto
**Jornada:** J6, J2-J5 (proxy)
**Portal:** Representante

| Item | Descricao |
|---|---|
| Objetivo | Representante gerencia carteira e atua em nome do cliente |
| Entrega | Dashboard carteira, visao do cliente, Modo Proxy completo, cotacoes, performance |
| Dependencias | E01 a E06 (Portal Cliente funcional) |

Escopo:
- Dashboard da carteira: KPIs (clientes ativos, faturamento vs meta, pedidos), alertas proativos
- Lista de clientes da carteira: busca, filtros, cards com ultimo pedido e limite
- Visao do cliente: historico de compras (grafico), limite, produtos mais comprados, oportunidades CIE
- Modo Proxy: seletor de cliente no topo, acesso a catalogo/carrinho/pedidos/financeiro/credito/cadastro no contexto do cliente
- Cotacoes: criar para cliente, enviar por WhatsApp/email
- Performance: vendas vs meta, comissoes, ranking
- PWA mobile-first com cache offline

---

### E13: Pesquisas e Promocoes

**Prioridade:** Media — Pos-piloto
**Jornada:** J8
**Portal:** ADM + Cliente + Representante

| Item | Descricao |
|---|---|
| Objetivo | Engajar revendedores com pesquisas e destacar promocoes no catalogo |
| Entrega | Builder de pesquisas, sinalizacao de promocoes, monitoramento |
| Dependencias | E02 (catalogo), E08 (ADM) |

Escopo:
- Pesquisas: criar no ADM (builder dinamico), publicar, responder no Portal Cliente, monitorar respostas, relatorio exportavel
- Promocoes: configurar campanha no ADM (produtos, desconto, vigencia, publico), ativacao automatica, badge "PROMO" nos cards, banner no catalogo, preco riscado + promocional, filtro "so promocoes", contador de vigencia
- Notificacao ao representante sobre promocoes ativas
- Monitoramento: vendas, adesao, ROI, comparativo antes/durante/apos

---

### E14: Portal Financeiro

**Prioridade:** Media — Pos-piloto
**Jornada:** J4, J5
**Portal:** Financeiro

| Item | Descricao |
|---|---|
| Objetivo | Analista financeiro gerencia cobranc, credito e conciliacao |
| Entrega | Dashboard financeiro, gestao de titulos, analise de credito, NFs |
| Dependencias | E01 (infra), E05 (financeiro cliente), E06 (credito) |

Escopo:
- Dashboard: KPIs (total a receber, vencidos, recebido mes, inadimplencia %), grafico recebimentos vs previsao, alertas
- Gestao de titulos: filtros completos (cliente, status, periodo, valor, representante), segunda via, exportar
- Visao financeira de clientes: situacao, historico, score
- Gestao de credito: fila de analise, dados do cliente, score bureau, restricoes, documentos, historico, aprovar/reprovar/parcial com alcada
- Notas fiscais: visao consolidada, download individual e em lote

---

### E15: Painel Admin

**Prioridade:** Baixa — Pos-piloto
**Jornada:** Transversal
**Portal:** Admin

| Item | Descricao |
|---|---|
| Objetivo | Administrador monitora sistema, gerencia usuarios e conectores |
| Entrega | Dashboard sistema, CRUD usuarios, monitoramento de conectores, logs, config |
| Dependencias | Todos os epicos anteriores |

Escopo:
- Dashboard do sistema: status dos conectores (verde/amarelo/vermelho), ultima sync, usuarios ativos, erros recentes, health check
- Gestao de usuarios: CRUD, alterar role, revogar sessao, log de autenticacao
- Monitoramento de conectores: status, circuit breaker, fila de retry, logs de sync
- Logs de auditoria: filtros (usuario, tabela, acao, periodo), detalhe (valor anterior/novo, IP)
- Configuracoes: parametros CIE (alcadas, limites), frequencias de sync, parametros de sessao

---

## 5. Epico Transversal

### E16: Design System + Boas Praticas

**Prioridade:** Critica — Contínuo
**Jornada:** Transversal
**Portal:** Todos

| Item | Descricao |
|---|---|
| Objetivo | Garantir consistencia visual e UX em todos os portais |
| Entrega | Componentes reutilizaveis, paleta, tipografia, padroes de interacao |
| Dependencias | E01 (infra) |

Escopo:
- Paleta Boxer: navy #1d327b, cyan #25bbee, red #e30613, laranja #e97316 (nunca amarelo)
- Tipografia: Outfit (300-700), escala definida
- Componentes: topbar, tabs, botoes, inputs, tabelas, modais, toasts, login
- Badges de produto: MAIS VENDIDO, PROMO, % OFF, BACKORDER, FRETE GRATIS
- Cards de categoria com imagens
- Barra de credito (verde/laranja/vermelho)
- Lista de favoritos / compra recorrente
- Responsividade: mobile-first para Cliente e Representante, desktop-first para ADM e Financeiro
- Notificacoes: central unificada, preferencias por canal (email, WhatsApp, push)

---

## 6. Mapa Consolidado

| Epico | Trilha | Prioridade | Jornada | Portal | Features |
|---|---|---|---|---|---|
| E01 Infraestrutura Base | T1 | Critica | — | Todos | 10 |
| E02 Catalogo e PDP | T1 | Critica | J2 | Cliente | 14 |
| E03 Pedido de Compra | T1 | Critica | J2 | Cliente | 13 |
| E04 Acompanhamento | T1 | Critica | J3 | Cliente | 10 |
| E05 Financeiro Cliente | T1 | Alta | J4 | Cliente | 8 |
| E06 Gestao de Credito | T1 | Alta | J5 | Cliente | 6 |
| E07 Cadastro | T1 | Alta | J1 | Cliente+ADM | 7 |
| E08 ADM Operacional | T1 | Alta | J1,J2,J7 | ADM | 12 |
| E09 Conector ERP ZEN | T2 | Critica | — | — | 8 |
| E10 Conector Static Data | T2 | Alta | — | ADM | 5 |
| E11 Conectores Suporte | T2 | Media | — | — | 9 |
| E12 Representante + Proxy | T3 | Alta | J6 | Rep | 8 |
| E13 Pesquisas e Promocoes | T3 | Media | J8 | ADM+Cliente | 6 |
| E14 Portal Financeiro | T3 | Media | J4,J5 | Financeiro | 7 |
| E15 Painel Admin | T3 | Baixa | — | Admin | 5 |
| E16 Design System | — | Critica | — | Todos | 8 |
| **Total** | | | | | **136** |

---

## 7. Dependencias entre Epicos

```
E01 ──→ TODOS (pre-requisito universal)

E09 ──→ E02, E03, E04, E05 (dados do ERP)
E10 ──→ E02 (fichas tecnicas, compatibilidade)

E02 ──→ E03 (catalogo alimenta carrinho)
E03 ──→ E04 (pedido gera acompanhamento)
E05 ──→ E06 (financeiro alimenta credito)
E07 ──→ E03 (cadastro antes de pedir)

E01-E06 ──→ E12 (Portal Cliente completo antes do Representante)
E02 + E08 ──→ E13 (catalogo + ADM antes de promocoes)
E05 + E06 ──→ E14 (financeiro cliente antes do portal financeiro)
TODOS ──→ E15 (admin por ultimo)

E16 ──→ paralelo com todos (design system evolui junto)
```

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
