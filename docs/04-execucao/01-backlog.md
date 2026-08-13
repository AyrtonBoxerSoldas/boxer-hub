# HUB-DOC-019: Backlog do Produto

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Criterios de Priorizacao

| Criterio | Peso | Descricao |
|---|---|---|
| Valor para o revendedor | 40% | Resolve dor real da persona P1/P2 |
| Dependencia tecnica | 25% | Bloqueia outros itens se nao feito |
| Complexidade | 20% | Esforco de desenvolvimento |
| Risco | 15% | Integracao externa, incerteza tecnica |

**Escala de prioridade:**
- **P0** — Bloqueante. Sem isso, nada funciona.
- **P1** — Critico para MVP. Revendedor nao usa sem isso.
- **P2** — Importante para MVP. Melhora experiencia, mas funciona sem.
- **P3** — Pos-piloto. Expansao planejada.
- **P4** — Futuro. Backlog para avaliar.

---

## 2. Backlog MVP — Prioridade P0 (Bloqueante)

| # | Feature | Epico | Justificativa |
|---|---|---|---|
| 1 | F01.1 Projeto Supabase | E01 | Sem banco, sem sistema |
| 2 | F01.2 Autenticacao | E01 | Sem login, sem acesso |
| 3 | F01.3 Tabelas core | E01 | Estrutura de dados base |
| 4 | F01.4 RLS base | E01 | Seguranca obrigatoria |
| 5 | F01.5 Repositorio e CI/CD | E01 | Sem deploy, sem entrega |
| 6 | F01.7 Tela de login | E01 | Porta de entrada |
| 7 | F01.8 Roteamento por role | E01 | Direciona para portal correto |
| 8 | F16.1 Paleta e tipografia | E16 | Base visual para tudo |
| 9 | F16.2 Componentes base | E16 | Topbar, botoes, inputs |
| 10 | F09.1 getProducts | E09 | Sem produtos, sem catalogo |
| 11 | F09.2 getStock | E09 | Sem estoque, sem pedido |

---

## 3. Backlog MVP — Prioridade P1 (Critico)

| # | Feature | Epico | Justificativa |
|---|---|---|---|
| 12 | F02.1 Grid de produtos | E02 | Core da experiencia de compra |
| 13 | F02.3 Busca de produtos | E02 | Revendedor encontra o que precisa |
| 14 | F02.4 Filtros de catalogo | E02 | Navegacao eficiente |
| 15 | F02.7 PDP — Galeria de fotos | E02 | Confianca na compra |
| 16 | F02.8 PDP — Ficha tecnica | E02 | Entender o produto sem ligar |
| 17 | F02.13 Preco riscado + desconto | E02 | Perceber valor do desconto |
| 18 | F03.1 Adicionar ao carrinho | E03 | Fluxo de compra |
| 19 | F03.2 Carrinho completo | E03 | Revisar antes de comprar |
| 20 | F03.3 Condicao de pagamento | E03 | Essencial para B2B |
| 21 | F03.5 Campo OC do cliente | E03 | Rastreabilidade do revendedor |
| 22 | F03.6 Validacao de credito | E03 | Evitar pedido que sera rejeitado |
| 23 | F03.7 Enviar pedido | E03 | Acao principal do sistema |
| 24 | F09.3 submitOrder | E09 | Pedido chega no ERP |
| 25 | F09.4 getOrderStatus | E09 | Status volta do ERP |
| 26 | F04.1 Lista de pedidos | E04 | Acompanhar pedidos |
| 27 | F04.2 Timeline visual | E04 | Dor #1: "nao sei do meu pedido" |
| 28 | F04.3 Itens do pedido | E04 | Ver o que pediu |
| 29 | F06.1 KPI de credito | E06 | Saber quanto pode gastar |
| 30 | F06.4 Bloqueio de checkout | E06 | Impedir pedido inviavel |

---

## 4. Backlog MVP — Prioridade P2 (Importante)

| # | Feature | Epico | Justificativa |
|---|---|---|---|
| 31 | F01.6 DNS e HTTPS | E01 | URL profissional |
| 32 | F01.9 Recuperacao de senha | E01 | Autonomia do usuario |
| 33 | F01.10 Sessao e refresh | E01 | Evitar perda de sessao |
| 34 | F02.2 Toggle grid/lista | E02 | Preferencia do usuario |
| 35 | F02.5 Navegacao por equipamento | E02 | Boa pratica da loja propria |
| 36 | F02.6 Breadcrumbs | E02 | Orientacao no catalogo |
| 37 | F02.9 PDP — O que acompanha | E02 | Checklist incluso |
| 38 | F02.10 PDP — Documentos | E02 | Fichas, FISPQ, certificados |
| 39 | F02.11 PDP — Produtos relacionados | E02 | Cross-sell, compatibilidade |
| 40 | F02.12 Badges nos cards | E02 | Destaque visual |
| 41 | F03.4 Endereco de entrega | E03 | Multiplos enderecos |
| 42 | F03.8 Salvar como cotacao | E03 | Cotacao antes de pedir |
| 43 | F03.9 Pedido rapido | E03 | P2 — Marina (enterprise) |
| 44 | F03.10 Importacao Excel/CSV | E03 | P2 — Marina (listas) |
| 45 | F03.11 Recompra | E03 | Dor P1: "repito pedidos" |
| 46 | F03.12 Sugestoes CIE no carrinho | E03 | Ticket medio |
| 47 | F04.4 Dados do pedido | E04 | Condicao, endereco, OC |
| 48 | F04.5 Download NF PDF | E04 | Self-service |
| 49 | F04.6 Download XML | E04 | Conciliacao (P2) |
| 50 | F04.7 Download boleto | E04 | Self-service financeiro |
| 51 | F04.10 Botao recomprar | E04 | Atalho de recompra |
| 52 | F05.1 Dashboard financeiro | E05 | Visao geral do credito |
| 53 | F05.2 Lista de titulos | E05 | Controle financeiro |
| 54 | F05.3 Segunda via de boleto | E05 | Dor P1: "demoro pra conseguir" |
| 55 | F05.4 Notas fiscais | E05 | Download de NFs |
| 56 | F05.5 Download XML em lote | E05 | P2 — conciliacao |
| 57 | F05.6 Extrato | E05 | Historico de movimentacoes |
| 58 | F05.7 Exportar extrato CSV | E05 | P2 — exportacao |
| 59 | F06.2 Painel de credito | E06 | Detalhes de credito |
| 60 | F06.3 Solicitar aumento | E06 | Autonomia do cliente |
| 61 | F06.5 Timeline de solicitacao | E06 | Transparencia |
| 62 | F07.1 Pre-cadastro publico | E07 | Porta de entrada J1 |
| 63 | F07.2 Consulta CNPJ | E07 | Preenchimento automatico |
| 64 | F07.3 Formulario 5 etapas | E07 | Cadastro completo |
| 65 | F07.4 Upload de documentos | E07 | Digitalizacao |
| 66 | F07.5 Meu Cadastro read-only | E07 | Visualizacao segura |
| 67 | F07.6 Solicitar alteracao | E07 | Fluxo controlado |
| 68 | F07.7 Notificacao boas-vindas | E07 | Onboarding |
| 69 | F08.1 Dashboard ADM | E08 | Operacional ADM |
| 70 | F08.2 Fila de pedidos | E08 | Processar pedidos |
| 71 | F08.3 Aprovar/rejeitar pedido | E08 | Alcada por role |
| 72 | F08.5 Fila de cadastros | E08 | Processar cadastros |
| 73 | F08.6 Analise de cadastro | E08 | Aprovar/rejeitar |
| 74 | F08.7 Base de clientes | E08 | Gestao de clientes |
| 75 | F08.9 Tabelas de precos | E08 | Gestao comercial |
| 76 | F08.10 Politica comercial | E08 | Integracao existente |
| 77 | F08.11 Fila de alteracoes | E08 | Solicitacoes pendentes |
| 78 | F09.5 getInvoices | E09 | NFs do ERP |
| 79 | F09.6 getFinancialTitles | E09 | Titulos do ERP |
| 80 | F09.7 createClient | E09 | Cadastro → ERP |
| 81 | F09.8 Circuit breaker | E09 | Resiliencia |
| 82 | F10.1 Upload de planilha | E10 | Dados estaticos |
| 83 | F10.2 Deteccao e preview | E10 | UX de importacao |
| 84 | F10.3 Mapeamento de colunas | E10 | Flexibilidade |
| 85 | F10.4 Validacao e persistencia | E10 | Qualidade de dados |
| 86 | F11.1 C03 — Segunda via boleto | E11 | Financeiro |
| 87 | F11.2 C04 — NF PDF e XML | E11 | Documentos fiscais |
| 88 | F11.3 C06 — Email transacional | E11 | Notificacoes |
| 89 | F11.4 C07 — Consulta CNPJ | E11 | Pre-cadastro |
| 90 | F11.5 C08 — Politica comercial | E11 | Regras CIE |
| 91 | F16.3 Tabela de dados | E16 | Componente reutilizavel |
| 92 | F16.4 Modal padrao | E16 | Componente reutilizavel |
| 93 | F16.5 Toast | E16 | Feedback visual |
| 94 | F16.6 Badges de produto | E16 | Componente visual |
| 95 | F16.8 Responsividade | E16 | Mobile funcional |

---

## 5. Backlog Pos-Piloto — P3

| # | Feature | Epico |
|---|---|---|
| 96 | F02.14 Compartilhar via WhatsApp | E02 |
| 97 | F03.13 Badge frete gratis | E03 |
| 98 | F04.8 Rastreamento | E04 |
| 99 | F04.9 Badge proxy | E04 |
| 100 | F05.8 Antecipacao de pagamento | E05 |
| 101 | F06.6 Antecipacao para liberar credito | E06 |
| 102 | F08.4 Excecoes comerciais | E08 |
| 103 | F08.8 Gestao de representantes | E08 |
| 104 | F08.12 Fila de credito visao ADM | E08 |
| 105 | F10.5 Sync SharePoint | E10 |
| 106 | F11.6 C02 — Serasa | E11 |
| 107 | F11.7 C05 — Rastreamento | E11 |
| 108 | F11.8 C06 — WhatsApp | E11 |
| 109-116 | F12.1 a F12.8 | E12 (Representante) |
| 117-122 | F13.1 a F13.6 | E13 (Pesquisas/Promocoes) |
| 123-129 | F14.1 a F14.7 | E14 (Portal Financeiro) |
| 130-134 | F15.1 a F15.5 | E15 (Painel Admin) |
| 135 | F16.7 Central de notificacoes | E16 |

---

## 6. Backlog Futuro — P4

| # | Feature | Epico |
|---|---|---|
| 136 | F11.9 C09/C10 — Logistica e IA | E11 |

---

## 7. Velocidade Estimada

| Sprint | Duracao | Features estimadas |
|---|---|---|
| Sprint 1-2 | 4 semanas | P0 (11 features) — infraestrutura |
| Sprint 3-5 | 6 semanas | P1 (19 features) — core do portal |
| Sprint 6-9 | 8 semanas | P2 (65 features) — MVP completo |
| Sprint 10-14 | 10 semanas | P3 (40 features) — expansao |
| Contínuo | — | P4 — avaliar conforme demanda |

**Total MVP (P0+P1+P2): ~95 features em ~18 semanas (~4.5 meses)**

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
