# HUB-DOC-023: Roadmap de Implementacao

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Premissas

- **Abordagem B:** piloto com 3-5 revendedores antes de rollout geral
- **3 trilhas paralelas:** T1 (infra + portal), T2 (conectores), T3 (expansao)
- **Sprints de 2 semanas**
- **Equipe estimada:** 1 dev fullstack + 1 dev backend/integracoes + Andre (produto/validacao)
- **Stack:** HTML+JS puro, Supabase boxer-hubcomercial, Netlify

---

## 2. Fase 1 — Fundacao (Sprints 1-2 / Semanas 1-4)

**Objetivo:** Tudo ligado, nada visivel ao revendedor ainda.

| Sprint | Trilha | Entregas |
|---|---|---|
| S1 | T1 | E01: Projeto Supabase, schemas, tabelas core, RLS, auth, login, roteamento por role |
| S1 | T1 | E16: Paleta, tipografia, componentes base (topbar, botoes, inputs, tabs, toast, modal) |
| S1 | T1 | E01: Repo GitHub, Netlify CI/CD, DNS hub.boxersoldas.com.br |
| S2 | T2 | E09: getProducts, getStock (C01 — dados do catalogo) |
| S2 | T2 | E11: C08 — consumo de regras da politica comercial |
| S2 | T1 | E01: Sessao, refresh JWT, recuperacao de senha |

**Marco:** Login funcional + pipeline de deploy + dados de produtos chegando do ERP.

---

## 3. Fase 2 — Core do Portal Cliente (Sprints 3-5 / Semanas 5-10)

**Objetivo:** Revendedor navega, busca, entende produtos e coloca pedido.

| Sprint | Trilha | Entregas |
|---|---|---|
| S3 | T1 | E02: Grid de produtos, busca, filtros, navegacao por equipamento, breadcrumbs |
| S3 | T1 | E02: PDP completa (galeria, ficha tecnica, "o que acompanha", documentos, relacionados) |
| S3 | T1 | E16: Badges (PROMO, % OFF, BACKORDER), preco riscado |
| S4 | T1 | E03: Carrinho, condicao de pagamento, endereco, OC, validacao de credito |
| S4 | T1 | E03: Enviar pedido (com validacao CIE) |
| S4 | T2 | E09: submitOrder, getOrderStatus (C01 — pedidos) |
| S5 | T1 | E04: Lista de pedidos, timeline visual, documentos (NF, XML, boleto) |
| S5 | T1 | E03: Pedido rapido, recompra, importacao Excel/CSV, cotacoes |

**Marco:** Jornada J2 e J3 completas. Revendedor faz pedido e acompanha.

---

## 4. Fase 3 — Financeiro e Credito (Sprints 6-7 / Semanas 11-14)

**Objetivo:** Revendedor consulta financeiro e gerencia credito com autonomia.

| Sprint | Trilha | Entregas |
|---|---|---|
| S6 | T1 | E05: Dashboard financeiro, titulos, segunda via boleto, NFs, extrato, exportar CSV |
| S6 | T2 | E09: getInvoices, getFinancialTitles (C01) |
| S6 | T2 | E11: C03 — conector bancario (segunda via), C04 — NF PDF/XML |
| S7 | T1 | E06: KPI de credito, painel, solicitar aumento, bloqueio de checkout, timeline |

**Marco:** Jornadas J4 e J5 completas. Autonomia financeira do revendedor.

---

## 5. Fase 4 — Cadastro e ADM (Sprints 8-9 / Semanas 15-18)

**Objetivo:** Novos clientes se cadastram. ADM processa tudo.

| Sprint | Trilha | Entregas |
|---|---|---|
| S8 | T1 | E07: Pre-cadastro publico, CNPJ automatico, formulario 5 etapas, upload docs |
| S8 | T1 | E07: Meu Cadastro read-only, solicitar alteracao |
| S8 | T2 | E09: createClient (C01), E11: C07 — Receita Federal, C06 — email transacional |
| S9 | T1 | E08: Dashboard ADM, fila pedidos, aprovar/rejeitar, fila cadastros, analise |
| S9 | T1 | E08: Base clientes, tabelas de precos, politica comercial, fila alteracoes |
| S9 | T2 | E10: Upload planilha, deteccao, mapeamento, validacao (C11) |

**Marco:** Jornada J1 completa. MVP funcional para piloto.

---

## 6. Fase 5 — Piloto (Sprints 10-11 / Semanas 19-22)

**Objetivo:** 3-5 revendedores usando o sistema real. Coletar feedback e corrigir.

| Sprint | Trilha | Entregas |
|---|---|---|
| S10 | T3 | Selecionar revendedores piloto (criterios: volume, relacionamento, maturidade digital) |
| S10 | T3 | Onboarding: criar usuarios, importar dados, treinar (video + call individual) |
| S10 | T3 | Monitorar uso: sessoes, pedidos, erros, feedback |
| S11 | T1 | Correcoes e ajustes baseados no feedback do piloto |
| S11 | T1 | Polimento de UX (itens mais reportados) |
| S11 | T2 | Ajuste de frequencias de sync, tratamento de edge cases |

**Marco:** Sistema validado por usuarios reais. Decisao de go/no-go para rollout.

---

## 7. Fase 6 — Expansao (Sprints 12-17 / Semanas 23-34)

**Objetivo:** Portal Representante, pesquisas/promocoes, financeiro ADM.

| Sprint | Trilha | Entregas |
|---|---|---|
| S12-13 | T3 | E12: Portal Representante — dashboard, carteira, visao cliente, Modo Proxy |
| S12-13 | T3 | E12: Cotacoes, performance, PWA mobile |
| S14 | T3 | E13: Pesquisas (builder, responder, relatorio) |
| S14 | T3 | E13: Promocoes (campanha, sinalizacao, monitoramento) |
| S15-16 | T3 | E14: Portal Financeiro — dashboard, titulos, credito, NFs |
| S15-16 | T2 | E11: C02 — Serasa, C05 — rastreamento, C06 — WhatsApp |
| S17 | T3 | E15: Painel Admin — dashboard sistema, usuarios, conectores, logs, config |

**Marco:** Todos os 4 portais operacionais. Sistema completo.

---

## 8. Fase 7 — Rollout Geral (Sprints 18-19 / Semanas 35-38)

**Objetivo:** Migrar toda a base de revendedores para o Boxer Hub.

| Sprint | Trilha | Entregas |
|---|---|---|
| S18 | T3 | Migrar revendedores em lotes (10-20 por semana), por regiao/representante |
| S18 | T3 | Material de treinamento (videos, guia PDF, FAQ) |
| S18 | T3 | Canal de suporte dedicado (WhatsApp? email?) |
| S19 | T3 | Monitorar adocao, metricas de uso, satisfacao |
| S19 | T3 | Ajustes finais baseados em feedback em escala |

---

## 9. Visao Temporal

```
2026
Set  Out  Nov  Dez
├────┤────┤────┤────┤
│ F1 │ F2      │ F3 │   ← Fundacao, Core, Financeiro
│    │         │    │

2027
Jan  Fev  Mar  Abr  Mai  Jun
├────┤────┤────┤────┤────┤────┤
│ F4 │ F5      │ F6           │   ← Cadastro/ADM, Piloto, Expansao
│    │ PILOTO  │              │

Jul  Ago
├────┤────┤
│ F7      │   ← Rollout geral
│         │
```

**Duracao total estimada: ~10-11 meses (Set/2026 — Jul/2027)**

---

## 10. Riscos por Fase

| Fase | Risco | Mitigacao |
|---|---|---|
| F1 | API ZEN indisponivel ou documentacao incompleta | Mock data para desenvolvimento; contato com suporte ZEN na semana 1 |
| F2 | CIE complexo de parametrizar | Comecar com regras simples (tier + volume); iterar |
| F3 | Conector bancario requer contrato com banco | Iniciar negociacao na F1; fallback com boleto manual |
| F4 | Receita Federal API instavel | Cache de consultas; campo manual como fallback |
| F5 | Revendedores piloto nao adotam | Selecionar os mais engajados; suporte dedicado; acompanhar por call semanal |
| F6 | Representantes resistem (medo de perder relevancia) | Modo Proxy como ferramenta DO representante; treinar como beneficio |
| F7 | Escala de suporte durante migracao | Migrar em lotes; nao desligar canal telefone/email imediatamente |

---

## 11. KPIs de Sucesso por Fase

| Fase | KPI | Meta |
|---|---|---|
| F2 | Pedido end-to-end funcional | 1 pedido de teste completo via Hub |
| F5 | Pedidos reais via Hub | >= 10 pedidos por revendedor/mes |
| F5 | Satisfacao piloto | NPS >= 7 |
| F5 | Reducao de ligacoes (status) | -30% vs periodo anterior |
| F7 | Adocao | >= 60% da base ativa usando o Hub |
| F7 | Ticket medio | Estavel ou superior ao canal telefone/email |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
