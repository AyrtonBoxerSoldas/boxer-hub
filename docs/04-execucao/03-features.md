# HUB-DOC-021: Features

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Formato

Cada feature segue: `F[epico].[sequencia] — Nome`. Prioridade herdada do epico, com ajuste por dependencia tecnica.

---

## 2. E01 — Infraestrutura Base

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F01.1 | Projeto Supabase | Criar `boxer-hubcomercial`, schemas, config inicial | MVP |
| F01.2 | Autenticacao | Supabase Auth, login/logout, roles em user_metadata | MVP |
| F01.3 | Tabelas core | clientes, usuarios, log_alteracoes, configuracoes | MVP |
| F01.4 | RLS base | Policies para todas as tabelas core | MVP |
| F01.5 | Repositorio e CI/CD | GitHub Tekweld `boxer-hub`, Netlify auto-deploy | MVP |
| F01.6 | DNS e HTTPS | hub.boxersoldas.com.br apontando para Netlify | MVP |
| F01.7 | Tela de login | Login funcional com Supabase Auth | MVP |
| F01.8 | Roteamento por role | Redirect automatico para portal correto apos login | MVP |
| F01.9 | Recuperacao de senha | Fluxo esqueci senha via email Supabase | MVP |
| F01.10 | Sessao e refresh | Auto-refresh JWT, expirar sessao inativa | MVP |

---

## 3. E02 — Catalogo e PDP

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F02.1 | Grid de produtos | Cards com foto, SKU, nome, preco CIE, estoque | MVP |
| F02.2 | Toggle grid/lista | Alternar visualizacao entre cards e tabela | MVP |
| F02.3 | Busca de produtos | Busca por texto livre e SKU | MVP |
| F02.4 | Filtros de catalogo | Categoria, disponibilidade, faixa de preco, promocao | MVP |
| F02.5 | Navegacao por equipamento | Arvore categoria → subcategoria → modelo de maquina | MVP |
| F02.6 | Breadcrumbs | Trail de navegacao (Home > Pecas > MIGFLEX 160 BV) | MVP |
| F02.7 | PDP — Galeria de fotos | Multiplas fotos com thumbnails e zoom | MVP |
| F02.8 | PDP — Ficha tecnica | Grade de especificacoes (classificacao, diametro, peso, etc.) | MVP |
| F02.9 | PDP — O que acompanha | Checklist do que vem incluso no produto | MVP |
| F02.10 | PDP — Documentos | Download de ficha PDF, FISPQ, certificado, manual | MVP |
| F02.11 | PDP — Produtos relacionados | Sugestoes CIE de consumiveis e acessorios compativeis | MVP |
| F02.12 | Badges nos cards | MAIS VENDIDO, PROMO, % OFF, BACKORDER | MVP |
| F02.13 | Preco riscado + desconto | Preco original, preco CIE, percentual de desconto | MVP |
| F02.14 | Compartilhar via WhatsApp | Botao share na PDP com link e descricao do produto | Pos-piloto |

---

## 4. E03 — Pedido de Compra

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F03.1 | Adicionar ao carrinho | Botao na PDP e no grid, com seletor de quantidade | MVP |
| F03.2 | Carrinho completo | Lista de itens, quantidades editaveis, subtotais | MVP |
| F03.3 | Condicao de pagamento | Select com opcoes do CIE (28/35/42 dias) | MVP |
| F03.4 | Endereco de entrega | Select entre enderecos cadastrados do cliente | MVP |
| F03.5 | Campo OC do cliente | "Seu Pedido" — numero interno do revendedor | MVP |
| F03.6 | Validacao de credito | Alerta vermelho se total > credito, botoes de acao | MVP |
| F03.7 | Enviar pedido | Submit com validacao CIE completa | MVP |
| F03.8 | Salvar como cotacao | Salvar carrinho com validade parametrizavel | MVP |
| F03.9 | Pedido rapido | Digitar SKU + quantidade, linha a linha | MVP |
| F03.10 | Importacao Excel/CSV | Upload de planilha com lista de compras (P2) | MVP |
| F03.11 | Recompra | Selecionar pedido anterior, reenvia com 1 clique | MVP |
| F03.12 | Sugestoes CIE no carrinho | Cross-sell de consumiveis, acessorios | MVP |
| F03.13 | Badge frete gratis | Regra CIE por tier + cross-sell banner | Pos-piloto |

---

## 5. E04 — Acompanhamento de Pedido

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F04.1 | Lista de pedidos | Tabela com filtros (status, periodo, valor), busca por OC | MVP |
| F04.2 | Timeline visual | 10 etapas com datas, status colorido por etapa | MVP |
| F04.3 | Itens do pedido | Tabela com foto, SKU, qtd, preco, subtotal | MVP |
| F04.4 | Dados do pedido | Condicao de pagamento, endereco, OC, observacoes | MVP |
| F04.5 | Download NF PDF | Botao para baixar nota fiscal em PDF | MVP |
| F04.6 | Download XML | Botao para baixar XML da NF | MVP |
| F04.7 | Download boleto | Botao para baixar boleto vinculado | MVP |
| F04.8 | Rastreamento | Codigo + status atualizado da transportadora | Pos-piloto |
| F04.9 | Badge proxy | Indicador "Criado pelo representante" quando aplicavel | Pos-piloto |
| F04.10 | Botao recomprar | "Recomprar este pedido" no detalhe | MVP |

---

## 6. E05 — Financeiro do Cliente

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F05.1 | Dashboard financeiro | KPIs: limite total, disponivel, titulos vencidos | MVP |
| F05.2 | Lista de titulos | Filtros (status, periodo, valor), tabela com vencimento | MVP |
| F05.3 | Segunda via de boleto | Gerar boleto + codigo PIX por titulo | MVP |
| F05.4 | Notas fiscais | Lista, filtros, download PDF e XML individual | MVP |
| F05.5 | Download XML em lote | Selecao multipla + download ZIP (P2 — Marina) | MVP |
| F05.6 | Extrato | Lista cronologica, filtro por periodo | MVP |
| F05.7 | Exportar extrato CSV | Download do extrato em formato planilha | MVP |
| F05.8 | Antecipacao de pagamento | Selecionar titulos, gerar boleto consolidado | Pos-piloto |

---

## 7. E06 — Gestao de Credito

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F06.1 | KPI de credito no dashboard | Card clicavel: disponivel / total com barra colorida | MVP |
| F06.2 | Painel de credito | Status, limite, score, ultima analise, historico | MVP |
| F06.3 | Solicitar aumento | Formulario: valor, justificativa, upload de documentos | MVP |
| F06.4 | Bloqueio de checkout | Impedir envio quando total > credito, com alerta | MVP |
| F06.5 | Timeline de solicitacao | Acompanhar status da solicitacao em tempo real | MVP |
| F06.6 | Antecipacao para liberar credito | Vincular antecipacao a liberacao de credito | Pos-piloto |

---

## 8. E07 — Cadastro de Cliente

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F07.1 | Pre-cadastro publico | Pagina `/cadastro` sem login, CNPJ + dados auto | MVP |
| F07.2 | Consulta CNPJ | Preenchimento automatico via Receita Federal (C07) | MVP |
| F07.3 | Formulario 5 etapas | Empresa, endereco, entrega, contato, bancario | MVP |
| F07.4 | Upload de documentos | Contrato social, procuracoes, comprovantes | MVP |
| F07.5 | Meu Cadastro read-only | Visualizacao de dados, sem edicao direta | MVP |
| F07.6 | Solicitar alteracao | Modal com selecao de secao + textarea | MVP |
| F07.7 | Notificacao de boas-vindas | Email com credenciais apos aprovacao | MVP |

---

## 9. E08 — ADM Operacional

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F08.1 | Dashboard ADM | KPIs, fila de trabalho priorizada, pipeline visual | MVP |
| F08.2 | Fila de pedidos | Lista com filtros, separacao por status | MVP |
| F08.3 | Aprovar/rejeitar pedido | Com verificacao de alcada (analyst R$50k, manager R$200k) | MVP |
| F08.4 | Excecoes comerciais | Lista, historico, analise por rep/valor/frequencia | MVP |
| F08.5 | Fila de cadastros | Cadastros pendentes de analise | MVP |
| F08.6 | Analise de cadastro | Docs, consulta RF, bureau, aprovar/rejeitar/complemento | MVP |
| F08.7 | Base de clientes | Busca, filtros, ficha completa com log | MVP |
| F08.8 | Gestao de representantes | Lista, ficha, carteira, performance | MVP |
| F08.9 | Tabelas de precos | CRUD, vincular cliente, historico de versoes | MVP |
| F08.10 | Politica comercial | Iframe/link para boxer-politica-comercial, monitoramento | MVP |
| F08.11 | Fila de alteracoes cadastrais | Solicitacoes de clientes aguardando analise | MVP |
| F08.12 | Fila de credito (visao ADM) | Solicitacoes de aumento pendentes (encaminhar para financeiro) | MVP |

---

## 10. E09 — Conector ERP ZEN

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F09.1 | getProducts | Sync de produtos ERP → Hub, poll 30min | MVP |
| F09.2 | getStock | Sync de estoque ERP → Hub, poll 30min | MVP |
| F09.3 | submitOrder | Enviar pedido Hub → ERP, tempo real | MVP |
| F09.4 | getOrderStatus | Sync de status ERP → Hub, poll 15min | MVP |
| F09.5 | getInvoices | Sync de NFs ERP → Hub, poll 15min | MVP |
| F09.6 | getFinancialTitles | Sync de titulos ERP → Hub, poll 1h | MVP |
| F09.7 | createClient | Criar cliente Hub → ERP, tempo real | MVP |
| F09.8 | Circuit breaker + fila | Retry com backoff, fallback para cache | MVP |

---

## 11. E10 — Conector Static Data

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F10.1 | Upload de planilha | Interface de upload Excel/XLSX/CSV no ADM | MVP |
| F10.2 | Deteccao e preview | Detectar colunas, mostrar preview dos dados | MVP |
| F10.3 | Mapeamento de colunas | Interface drag-and-drop para mapear campos | MVP |
| F10.4 | Validacao e persistencia | Validar tipos, obrigatoriedade, gravar no Supabase | MVP |
| F10.5 | Sync SharePoint | Automatizar sync via Microsoft Graph (futuro) | Pos-piloto |

---

## 12. E11 — Conectores de Suporte

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F11.1 | C03 — Segunda via boleto | Gerar boleto via API bancaria | MVP |
| F11.2 | C04 — NF PDF e XML | Recuperar documentos fiscais do ERP | MVP |
| F11.3 | C06 — Email transacional | Envio de notificacoes por email (Supabase + SMTP) | MVP |
| F11.4 | C07 — Consulta CNPJ | API Receita Federal para pre-cadastro | MVP |
| F11.5 | C08 — Politica comercial | Consumir regras do boxer-politica-comercial | MVP |
| F11.6 | C02 — Consulta Serasa | Score e restricoes para analise de credito | Pos-piloto |
| F11.7 | C05 — Rastreamento | Status da transportadora, calculo de frete | Pos-piloto |
| F11.8 | C06 — WhatsApp | Notificacoes por WhatsApp Business API | Pos-piloto |
| F11.9 | C09/C10 — Logistica e IA | Previsao de importacao, recomendacoes | Futuro |

---

## 13. E12 — Portal Representante + Modo Proxy

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F12.1 | Dashboard carteira | KPIs, alertas proativos, grafico faturamento vs meta | Pos-piloto |
| F12.2 | Lista de clientes | Carteira com busca, filtros, ultimo pedido, limite | Pos-piloto |
| F12.3 | Visao do cliente | Historico, limite, produtos mais comprados, oportunidades CIE | Pos-piloto |
| F12.4 | Modo Proxy — ativar | Seletor de cliente no topo, troca de contexto | Pos-piloto |
| F12.5 | Modo Proxy — telas | Catalogo, carrinho, pedidos, financeiro, credito, cadastro | Pos-piloto |
| F12.6 | Cotacoes | Criar, enviar por WhatsApp/email, salvar | Pos-piloto |
| F12.7 | Performance | Vendas vs meta, comissoes, ranking | Pos-piloto |
| F12.8 | PWA mobile | Service Worker, cache offline, manifest.json | Pos-piloto |

---

## 14. E13 — Pesquisas e Promocoes

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F13.1 | Builder de pesquisas | Criar perguntas (MC, escala, texto), publico, vigencia | Pos-piloto |
| F13.2 | Responder pesquisa | Formulario no Portal Cliente, historico | Pos-piloto |
| F13.3 | Relatorio de pesquisa | Graficos, taxa por regiao, exportar CSV/PDF | Pos-piloto |
| F13.4 | Campanha promocional | Configurar no ADM: produtos, desconto, vigencia, publico | Pos-piloto |
| F13.5 | Sinalizacao visual | Badges, banner, preco riscado, filtro "so promocoes" | Pos-piloto |
| F13.6 | Monitoramento de campanha | Vendas, adesao, ROI, comparativo | Pos-piloto |

---

## 15. E14 — Portal Financeiro

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F14.1 | Dashboard financeiro | KPIs, grafico recebimentos vs previsao, alertas | Pos-piloto |
| F14.2 | Gestao de titulos | Filtros completos, segunda via, exportar | Pos-piloto |
| F14.3 | Visao financeira de clientes | Situacao, historico, score | Pos-piloto |
| F14.4 | Analise de credito | Fila, score bureau, aprovar/reprovar com alcada | Pos-piloto |
| F14.5 | NFs consolidadas | Visao geral, download individual e lote | Pos-piloto |
| F14.6 | Detalhe do titulo | Pedido vinculado, NF vinculada, historico pagamento | Pos-piloto |
| F14.7 | Exportacao financeira | CSV com filtros para conciliacao | Pos-piloto |

---

## 16. E15 — Painel Admin

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F15.1 | Dashboard do sistema | Status conectores, ultima sync, erros, health check | Pos-piloto |
| F15.2 | CRUD de usuarios | Criar, editar role, revogar sessao, log auth | Pos-piloto |
| F15.3 | Monitoramento de conectores | Status, circuit breaker, fila retry, logs | Pos-piloto |
| F15.4 | Logs de auditoria | Filtros, detalhe com valor anterior/novo | Pos-piloto |
| F15.5 | Configuracoes | Parametros CIE, frequencias sync, sessao | Pos-piloto |

---

## 17. E16 — Design System

| ID | Feature | Descricao resumida | Fase |
|---|---|---|---|
| F16.1 | Paleta e tipografia | Variaveis CSS, escala tipografica, Outfit | MVP |
| F16.2 | Componentes base | Topbar, botoes, inputs, selects, tabs | MVP |
| F16.3 | Tabela de dados | Componente de tabela com sort, filtro, paginacao | MVP |
| F16.4 | Modal padrao | Overlay, formulario, acoes | MVP |
| F16.5 | Toast de notificacao | Sucesso, erro, animacao | MVP |
| F16.6 | Badges de produto | MAIS VENDIDO, PROMO, % OFF, BACKORDER, FRETE GRATIS | MVP |
| F16.7 | Central de notificacoes | Lista, filtro por tipo, marcar como lida | Pos-piloto |
| F16.8 | Responsividade | Breakpoints, mobile-first para Cliente/Rep | MVP |

---

## 18. Contagem por Fase

| Fase | Features |
|---|---|
| **MVP** | 89 |
| **Pos-piloto** | 42 |
| **Futuro** | 1 |
| **Total** | **132** |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
