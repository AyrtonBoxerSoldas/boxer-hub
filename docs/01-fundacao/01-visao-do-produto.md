# HUB-DOC-001: Visao do Produto

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-04
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Declaracao de Visao

A Boxer Hub sera a camada oficial de experiencia digital da Boxer Soldas, concentrando toda a jornada comercial entre a empresa, seus revendedores, representantes comerciais e equipes internas em uma plataforma unica, moderna, inteligente e integrada.

**Visao em uma frase:**
> Permitir que toda a relacao comercial entre Boxer e Revendedor aconteca dentro da plataforma — do cadastro ao pos-venda — sem telefone, sem email, com total transparencia.

---

## 2. Problema

### 2.1 Situacao Atual

A jornada comercial da Boxer Soldas depende de multiplos canais desconectados:

| Canal | Limitacao |
|---|---|
| Telefone | Sem registro, sem rastreabilidade, dependente de disponibilidade |
| Email | Lento, sem padronizacao, informacao dispersa em caixas individuais |
| ERP (ZEN) | Interface operacional, nao desenhada para o cliente final |
| Planilhas | Dados duplicados, sem governanca, risco de inconsistencia |
| WhatsApp | Informal, sem auditoria, dados fragmentados |

### 2.2 Consequencias

- Revendedor nao tem autonomia para consultar seus proprios dados
- Representante comercial depende de contato interno para informacoes basicas
- Equipe interna gasta tempo em tarefas operacionais que poderiam ser self-service
- Falta de transparencia no andamento de pedidos, credito e financeiro
- Impossibilidade de aplicar inteligencia comercial de forma sistematica
- Risco de compliance (LGPD) em canais informais

---

## 3. Solucao

### 3.1 O que e o Boxer Hub

O Boxer Hub e uma plataforma comercial B2B que funciona como a interface digital oficial entre a Boxer Soldas e seu ecossistema comercial. Ela:

- **Nao substitui o ERP.** O ERP (ZEN) permanece como sistema transacional oficial.
- **Nao e um ecommerce.** Nao processa pagamentos diretamente.
- **E a camada de experiencia.** Orquestra processos, oferece inteligencia comercial e proporciona autonomia aos usuarios.

### 3.2 O que o Boxer Hub faz

| Capacidade | Descricao |
|---|---|
| **Orquestra** | Conecta sistemas isolados em uma experiencia unica e coerente |
| **Automatiza** | Aplica regras comerciais parametrizadas sem intervencao manual |
| **Transparece** | Espelha status de pedidos, credito e financeiro em tempo real |
| **Empodera** | Da ao revendedor autonomia total sobre sua jornada comercial |
| **Intelige** | Sugere produtos, identifica oportunidades, otimiza a carteira |

### 3.3 Principio Fundamental

> Toda informacao comercial relevante deve possuir uma origem oficial, um responsavel pela atualizacao e transparencia total ao usuario.

---

## 4. Portais

O Boxer Hub sera composto por quatro portais que compartilham infraestrutura, autenticacao, design system e dados, diferenciando-se apenas na perspectiva e nas funcionalidades acessiveis a cada perfil.

### 4.1 Portal Cliente (Revendedor)

**Proposito:** Dar ao revendedor total autonomia sobre sua jornada comercial.

**Funcionalidades-chave:**
- Catalogo de produtos com precos personalizados
- Carrinho, cotacao e pedido
- Acompanhamento de pedidos em tempo real
- Consulta financeira (limites, duplicatas, boletos, NF)
- Solicitacao e acompanhamento de credito
- Historico completo de transacoes
- Recompra inteligente
- Promocoes e campanhas em destaque (banners, badges nos produtos, area dedicada)
- Pesquisas e enquetes (responder pesquisas enviadas pela Boxer)
- Pos-venda e garantias

**Experiencia de referencia:** Amazon Business, Fastenal, Grainger — nao copiar layout, absorver conceitos de UX B2B.

### 4.2 Portal Representante

**Proposito:** Fornecer ao representante comercial ferramentas para gestao eficiente de sua carteira E capacidade de atuar em nome de seus clientes.

**Funcionalidades-chave:**
- Dashboard de performance da carteira
- Visao consolidada de todos os clientes
- **Modo Proxy: atuar em nome do cliente** (pedidos, financeiro, cadastro, credito)
- Cadastro de novos clientes (vinculacao automatica a carteira)
- Alertas de oportunidades (recompra, cross-sell, upsell)
- Acompanhamento de pedidos de seus clientes
- Consulta financeira do cliente (boletos, NFs, limites)
- Acoes comerciais (cotacoes, negociacoes)
- Pipeline de novos clientes
- Relatorios de desempenho

### 4.3 Portal ADM de Vendas

**Proposito:** Dar a equipe interna de vendas controle operacional e visao estrategica.

**Funcionalidades-chave:**
- Gestao de cadastros e aprovacoes
- Gestao de politica comercial
- Gestao de tabelas de precos
- Aprovacao de excecoes e alcadas
- Configuracao de campanhas e promocoes (com sinalizacao visual no Portal Cliente)
- Criacao e gestao de pesquisas/enquetes para revendedores
- Monitoramento de pedidos e pipeline
- Relatorios gerenciais

### 4.4 Portal Financeiro

**Proposito:** Centralizar consultas e operacoes financeiras para todas as partes.

**Funcionalidades-chave:**
- Consulta de credito e limites
- Gestao de titulos e duplicatas
- Emissao de segunda via de boletos
- Consulta de notas fiscais e XMLs
- Extrato e historico financeiro
- Integracoes bancarias

---

## 5. Diferenciadores Estrategicos

### 5.1 Motor de Inteligencia Comercial (CIE)

Componente proprio da plataforma que interpreta todas as regras comerciais de forma parametrizada. Nenhuma regra sera codificada diretamente — todas serao configuradas, versionadas e auditaveis.

### 5.2 Arquitetura Connector-First

Nenhum modulo depende diretamente de um sistema externo. Toda integracao ocorre via conectores padronizados. Substituir o ERP, o bureau de credito ou o gateway de pagamento nao exige alteracao nos modulos da plataforma.

### 5.3 Politica Comercial como Ativo Digital

A Politica Comercial da Boxer sera tratada como um ativo independente do ERP, com versionamento, vigencia, parametrizacao e capacidade de evolucao autonoma.

### 5.4 Tabela de Precos Inteligente

Coexistencia de multiplas tabelas de precos com vigencia, campanhas, regras por canal/cliente/segmento, historico completo e aplicacao automatica pelo CIE.

---

## 6. Metricas de Sucesso

| Metrica | Baseline (hoje) | Meta (12 meses) |
|---|---|---|
| % pedidos via plataforma | 0% | 60% |
| Tempo medio para colocar um pedido | Variavel (telefone/email) | < 5 minutos |
| Chamadas telefonicas para consulta de status | Alto | Reducao de 80% |
| Autonomia do revendedor (self-service) | Baixa | Alta (90% das consultas) |
| Tempo de aprovacao de cadastro | Dias | < 24 horas |
| Satisfacao do revendedor (NPS) | Nao medido | > 50 |

---

## 7. O que o Boxer Hub NAO e

- Nao e um ERP. Nao gerencia estoque, producao ou contabilidade.
- Nao e um ecommerce B2C. Nao vende para consumidor final.
- Nao e um CRM. Nao gerencia relacionamento — integra com ferramentas de CRM.
- Nao e um sistema financeiro. Espelha dados financeiros, nao os origina.
- Nao e um marketplace. Vende exclusivamente produtos Boxer.

---

## 8. Horizonte de Evolucao

| Fase | Horizonte | Foco |
|---|---|---|
| **MVP** | 0-6 meses | Portal Cliente completo (catalogo, pedido, acompanhamento, financeiro self-service), Portal ADM basico |
| **Expansao** | 6-12 meses | Portal Representante, Portal Financeiro (gestao interna), CIE basico |
| **Inteligencia** | 12-18 meses | CIE completo, recomendacoes, analytics avancado |
| **IA** | 18-24 meses | Assistente comercial IA, analise preditiva, chatbot |

---

## 9. Stakeholders

| Stakeholder | Papel | Interesse |
|---|---|---|
| Diretoria Comercial | Sponsor executivo | ROI, eficiencia operacional, satisfacao do canal |
| Equipe Comercial Interna | Usuarios operacionais | Reducao de trabalho manual, visao consolidada |
| Representantes Comerciais | Usuarios de campo | Autonomia, informacoes em tempo real |
| Revendedores | Usuarios finais | Self-service, transparencia, experiencia moderna |
| TI | Operacao e manutencao | Estabilidade, seguranca, integrabilidade |
| Financeiro | Consulta e validacao | Acuracidade dos dados, compliance |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
