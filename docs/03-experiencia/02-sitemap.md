# HUB-DOC-015: Sitemap

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

O Boxer Hub possui 4 portais que compartilham autenticacao, design system e banco de dados. Cada portal expoe funcionalidades especificas para o perfil do usuario.

URL base: `plataforma.boxersoldas.com.br`

```
plataforma.boxersoldas.com.br/
├── /login                    ← Tela unica de login (Supabase Auth)
├── /cliente/                 ← Portal Cliente (dealer)
├── /representante/           ← Portal Representante (rep)
├── /adm/                     ← Portal ADM Vendas (analyst, manager)
├── /financeiro/              ← Portal Financeiro (financial)
└── /admin/                   ← Painel Admin (admin — acessa tudo)
```

Apos login, o sistema redireciona para o portal correto com base no `role` do `user_metadata`.

---

## 2. Tela Comum: Login

```
/login
│
├── Campo email
├── Campo senha
├── Botao "Entrar"
├── Link "Esqueci minha senha" → /login/recuperar
└── Link "Pre-cadastro" → /cadastro (J1)

/login/recuperar
│
├── Campo email
├── Botao "Enviar link de recuperacao"
└── Mensagem de confirmacao
```

---

## 3. Portal Cliente (`/cliente/`)

**Role:** `dealer` | **Persona:** P1 (Carlos), P2 (Marina)

```
/cliente/
│
├── /cliente/dashboard                          ← Pagina inicial
│   ├── KPIs: pedidos em andamento, limite disponivel, titulos vencidos
│   ├── Ultimos pedidos (resumo)
│   ├── Notificacoes recentes
│   ├── Pesquisas pendentes (cards)
│   ├── Promocoes ativas (banner destaque)
│   └── Atalhos rapidos: Novo Pedido, Recompra, Financeiro
│
├── /cliente/catalogo                           ← Catalogo de Produtos
│   ├── Barra de busca (texto livre, SKU)
│   ├── Filtros: categoria, disponibilidade, preco, promocao
│   ├── Toggle grid / lista
│   ├── Cards de produto:
│   │   ├── Foto, SKU, nome, preco personalizado (CIE)
│   │   ├── Badge "PROMOCAO" (quando aplicavel)
│   │   ├── Indicador de estoque (disponivel / sem estoque + previsao)
│   │   └── Botao "Adicionar ao carrinho"
│   │
│   ├── /cliente/catalogo/promocoes             ← Filtro: so promocoes ativas
│   │
│   └── /cliente/catalogo/:sku                  ← PDP (Product Detail Page)
│       ├── Galeria de fotos (multiplas, zoom)
│       ├── Nome, SKU, categoria
│       ├── Preco personalizado (CIE) — se promocao: preco riscado + promocional
│       ├── Disponibilidade (estoque ou previsao de chegada)
│       ├── Ficha tecnica (grade de especificacoes)
│       ├── Secao "O que acompanha" (checklist)
│       ├── Documentos para download (ficha tecnica PDF, FISPQ, certificado, manual)
│       ├── Produtos relacionados (CIE)
│       ├── Seletor de quantidade + botao "Adicionar ao carrinho"
│       └── Se backorder: aviso + previsao + botao "Reservar"
│
├── /cliente/carrinho                           ← Carrinho de Compras
│   ├── Lista de itens (foto, nome, SKU, qtd, preco, subtotal)
│   ├── Indicador de backorder por item (quando aplicavel)
│   ├── Sugestoes CIE (cross-sell, consumiveis)
│   ├── Condicao de pagamento (select)
│   ├── Endereco de entrega (select entre enderecos cadastrados)
│   ├── Campo "Seu Pedido (OC)" — numero interno do revendedor
│   ├── Observacoes (textarea)
│   ├── Resumo: subtotal, desconto, total
│   ├── Botao "Salvar como Cotacao"
│   └── Botao "Enviar Pedido"
│
├── /cliente/pedidos                            ← Meus Pedidos
│   ├── Lista com filtros: status, periodo, valor
│   ├── Busca por numero do pedido ou OC
│   ├── Cada linha: numero, data, valor, status (badge colorido), OC
│   │
│   └── /cliente/pedidos/:id                    ← Detalhe do Pedido
│       ├── Timeline visual de status (J3)
│       ├── Badge "Criado pelo representante" (se Modo Proxy)
│       ├── Itens do pedido (tabela)
│       ├── Dados: condicao pagamento, endereco, OC
│       ├── Documentos: NF (PDF), XML, boleto
│       ├── Rastreamento (codigo + status transportadora)
│       └── Botao "Recomprar este pedido"
│
├── /cliente/cotacoes                           ← Minhas Cotacoes
│   ├── Lista: numero, data, validade, valor, status
│   │
│   └── /cliente/cotacoes/:id                   ← Detalhe da Cotacao
│       ├── Itens (tabela)
│       ├── Validade restante
│       ├── Botao "Converter em Pedido"
│       └── Botao "Editar Cotacao"
│
├── /cliente/financeiro                         ← Painel Financeiro (J4)
│   ├── KPIs: limite total, disponivel, titulos vencidos
│   ├── Grafico de evolucao
│   │
│   ├── /cliente/financeiro/titulos             ← Titulos
│   │   ├── Filtros: status (a vencer, vencido, pago), periodo, valor
│   │   ├── Tabela: numero, vencimento, valor, status
│   │   ├── Botao "Segunda via" por titulo (gera boleto + PIX)
│   │   └── Botao "Baixar comprovante" (quando pago)
│   │
│   ├── /cliente/financeiro/notas-fiscais       ← Notas Fiscais
│   │   ├── Filtros: periodo, numero NF
│   │   ├── Tabela: numero, data, valor, chave de acesso
│   │   ├── Botao "Baixar PDF" por NF
│   │   ├── Botao "Baixar XML" por NF
│   │   └── Botao "Baixar XMLs em lote" (selecao multipla)
│   │
│   └── /cliente/financeiro/extrato             ← Extrato
│       ├── Filtros: periodo
│       ├── Lista cronologica de movimentacoes
│       └── Botao "Exportar" (CSV)
│
├── /cliente/credito                            ← Credito (J5)
│   ├── Status atual: limite, score, ultima analise
│   ├── Historico de solicitacoes (timeline)
│   ├── Botao "Solicitar Aumento de Limite"
│   │
│   └── /cliente/credito/solicitar              ← Nova Solicitacao
│       ├── Valor solicitado
│       ├── Upload de documentos (balanco, DRE)
│       ├── Justificativa
│       └── Botao "Enviar Solicitacao"
│
├── /cliente/pesquisas                          ← Pesquisas (J8)
│   ├── Pesquisas pendentes (cards)
│   ├── Pesquisas respondidas (historico)
│   │
│   └── /cliente/pesquisas/:id                  ← Responder Pesquisa
│       ├── Titulo, descricao, vigencia
│       ├── Perguntas (formulario dinamico)
│       └── Botao "Enviar Respostas"
│
├── /cliente/notificacoes                       ← Central de Notificacoes
│   ├── Lista cronologica
│   ├── Filtro por tipo
│   ├── Marcar como lida / todas lidas
│   └── Link de acao em cada notificacao
│
├── /cliente/perfil                             ← Meu Perfil
│   ├── Dados cadastrais (somente leitura — origem ERP)
│   ├── Enderecos de entrega (adicionar, editar, remover)
│   ├── Preferencias de notificacao (email, WA, push)
│   └── Alterar senha
│
└── /cliente/pedido-rapido                      ← Pedido Rapido
    ├── Campo para digitar SKUs + quantidade (linha a linha)
    ├── Importar Excel/CSV (P2 — Marina)
    ├── Previa com precos (CIE)
    └── Botao "Enviar Pedido"
```

**Total de telas Portal Cliente: 19**

---

## 4. Portal Representante (`/representante/`)

**Role:** `rep` | **Persona:** P3 (Roberto)

```
/representante/
│
├── /representante/dashboard                    ← Dashboard da Carteira (J6)
│   ├── KPIs: clientes ativos, faturamento mes, meta (%), pedidos em andamento
│   ├── Alertas proativos:
│   │   ├── Clientes sem compra > 30 dias
│   │   ├── Creditos recentemente liberados
│   │   └── Pedidos com problemas
│   ├── Grafico: faturamento vs meta (mensal)
│   └── Atalhos: Novo Cadastro, Nova Cotacao, Ver Pedidos
│
├── /representante/carteira                     ← Lista de Clientes
│   ├── Busca por nome, CNPJ
│   ├── Filtros: status (ativo, inativo), regiao
│   ├── Cards/lista: nome, CNPJ, ultimo pedido, limite disponivel
│   ├── Botao "Atuar em nome do cliente" (ativa Modo Proxy)
│   │
│   └── /representante/carteira/:clienteId      ← Visao do Cliente
│       ├── Dados cadastrais (resumo)
│       ├── Ultimo pedido, valor, data
│       ├── Historico de compras (grafico)
│       ├── Limite de credito e situacao financeira
│       ├── Produtos mais comprados
│       ├── Oportunidades sugeridas pelo CIE
│       └── Botoes: "Fazer Pedido (Proxy)", "Ver Financeiro", "Criar Cotacao"
│
├── /representante/proxy                        ← Modo Proxy (ativo)
│   │  (Seletor de cliente visivel no topo)
│   │  (Todas as telas abaixo no contexto do cliente selecionado)
│   │
│   ├── /representante/proxy/catalogo           ← Catalogo (precos do cliente)
│   ├── /representante/proxy/carrinho           ← Carrinho (em nome do cliente)
│   ├── /representante/proxy/pedidos            ← Pedidos do cliente
│   ├── /representante/proxy/financeiro         ← Financeiro do cliente
│   ├── /representante/proxy/credito            ← Credito do cliente
│   └── /representante/proxy/cadastro           ← Novo cadastro (vincula auto)
│
├── /representante/pedidos                      ← Pedidos (todos os clientes)
│   ├── Filtros: cliente, status, periodo
│   ├── Tabela: numero, cliente, data, valor, status
│   │
│   └── /representante/pedidos/:id              ← Detalhe (mesmo layout J3)
│
├── /representante/cotacoes                     ← Cotacoes
│   ├── Lista de cotacoes criadas
│   ├── Botao "Nova Cotacao"
│   │
│   ├── /representante/cotacoes/nova            ← Criar Cotacao
│   │   ├── Selecionar cliente
│   │   ├── Adicionar produtos (com preco CIE do cliente)
│   │   ├── Botao "Enviar por WhatsApp/Email"
│   │   └── Botao "Salvar Cotacao"
│   │
│   └── /representante/cotacoes/:id             ← Detalhe
│
├── /representante/performance                  ← Minha Performance
│   ├── Vendas vs meta (mensal, acumulado)
│   ├── Comissoes (acumulado, projetado)
│   ├── Ranking entre representantes
│   └── Historico de performance
│
├── /representante/notificacoes                 ← Notificacoes
│
└── /representante/perfil                       ← Meu Perfil
    ├── Dados pessoais
    ├── Preferencias de notificacao
    └── Alterar senha
```

**Total de telas Portal Representante: 18** (incluindo 6 telas de Proxy)

---

## 5. Portal ADM Vendas (`/adm/`)

**Role:** `analyst`, `manager` | **Personas:** P4 (Fernanda), P5 (Marcos)

```
/adm/
│
├── /adm/dashboard                              ← Dashboard Operacional
│   ├── KPIs: pedidos hoje, pendentes aprovacao, cadastros pendentes
│   ├── Fila de trabalho priorizada (cadastros, aprovacoes, excecoes)
│   ├── Pipeline de pedidos (funil visual)
│   ├── Alertas: desvios de politica, excecoes concedidas
│   └── Grafico: volume de pedidos (semana/mes)
│
├── /adm/pedidos                                ← Gestao de Pedidos
│   ├── Filtros: status, cliente, representante, periodo, valor
│   ├── Tabela: numero, cliente, rep, data, valor, status, origem
│   ├── Fila de aprovacao (pedidos em_analise)
│   │
│   ├── /adm/pedidos/:id                        ← Detalhe do Pedido
│   │   ├── Timeline
│   │   ├── Itens, precos, regras CIE aplicadas
│   │   ├── Historico de acoes (quem fez o que)
│   │   ├── Se excecao: motivo, justificativa
│   │   ├── Botao "Aprovar" (verifica alcada)
│   │   └── Botao "Rejeitar" (justificativa obrigatoria)
│   │
│   └── /adm/pedidos/excecoes                   ← Excecoes Comerciais
│       ├── Lista de excecoes ativas
│       ├── Historico de excecoes concedidas
│       └── Analise: frequencia, valor, por representante
│
├── /adm/cadastros                              ← Gestao de Cadastros (J1)
│   ├── Fila: cadastros pendentes de analise
│   ├── Filtros: status, data, regiao
│   │
│   └── /adm/cadastros/:id                      ← Analise de Cadastro
│       ├── Dados do cliente (preenchido auto + complemento)
│       ├── Documentos enviados (visualizador)
│       ├── Resultado consulta Receita Federal
│       ├── Resultado consulta bureau de credito
│       ├── Botao "Aprovar" / "Solicitar Complemento" / "Rejeitar"
│       └── Campo de observacoes
│
├── /adm/clientes                               ← Base de Clientes
│   ├── Busca: nome, CNPJ
│   ├── Filtros: status, canal, segmento, regiao, representante
│   ├── Tabela: nome, CNPJ, status, rep, limite, ultimo pedido
│   │
│   └── /adm/clientes/:id                       ← Ficha do Cliente
│       ├── Dados cadastrais completos
│       ├── Representante vinculado (editar)
│       ├── Historico de pedidos, credito, financeiro
│       ├── Tabela de precos vinculada (editar)
│       └── Log de alteracoes
│
├── /adm/representantes                         ← Gestao de Representantes
│   ├── Lista: nome, regiao, clientes ativos, faturamento, meta
│   │
│   └── /adm/representantes/:id                 ← Ficha do Representante
│       ├── Dados pessoais
│       ├── Carteira de clientes
│       ├── Performance (vendas vs meta, comissoes)
│       └── Historico de acoes
│
├── /adm/politica-comercial                     ← Politica Comercial (J7)
│   ├── Acesso ao sistema externo (iframe/link)
│   │   → boxer-politica-comercial.pages.dev
│   ├── Monitoramento de aplicacao das regras
│   ├── Excecoes e desvios
│   └── Ultima sincronizacao (C08)
│
├── /adm/tabelas-precos                         ← Tabelas de Precos
│   ├── Lista: nome, tipo, vigencia, status
│   │
│   └── /adm/tabelas-precos/:id                 ← Detalhe/Edicao
│       ├── Informacoes gerais (nome, tipo, vigencia)
│       ├── Itens (produto, preco, desconto maximo)
│       ├── Clientes vinculados
│       └── Historico de versoes
│
├── /adm/campanhas                              ← Campanhas Promocionais (J8)
│   ├── Lista: nome, vigencia, status (ativa/encerrada), produtos
│   ├── Botao "Nova Campanha"
│   │
│   ├── /adm/campanhas/nova                     ← Criar Campanha
│   │   ├── Nome, descricao
│   │   ├── Produtos (selecionar do catalogo)
│   │   ├── Tipo de desconto + valor
│   │   ├── Vigencia
│   │   ├── Publico-alvo
│   │   ├── Upload de banner
│   │   └── Botao "Publicar"
│   │
│   └── /adm/campanhas/:id                      ← Detalhe/Monitoramento
│       ├── Configuracao da campanha
│       ├── Desempenho: vendas, adesao, ROI
│       └── Comparativo antes/durante/apos
│
├── /adm/pesquisas                              ← Pesquisas (J8)
│   ├── Lista: titulo, vigencia, status, respostas
│   ├── Botao "Nova Pesquisa"
│   │
│   ├── /adm/pesquisas/nova                     ← Criar Pesquisa
│   │   ├── Titulo, descricao
│   │   ├── Perguntas (builder dinamico)
│   │   ├── Publico-alvo
│   │   ├── Vigencia
│   │   ├── Obrigatoria (toggle)
│   │   └── Botao "Publicar"
│   │
│   └── /adm/pesquisas/:id                      ← Detalhe/Relatorio
│       ├── Configuracao
│       ├── Respostas em tempo real
│       ├── Graficos por pergunta
│       ├── Taxa de resposta por regiao
│       └── Botao "Exportar" (CSV/PDF)
│
├── /adm/notificacoes                           ← Notificacoes
│
└── /adm/perfil                                 ← Meu Perfil
```

**Total de telas Portal ADM: 22**

---

## 6. Portal Financeiro (`/financeiro/`)

**Role:** `financial` | **Persona:** P6 (Julia)

```
/financeiro/
│
├── /financeiro/dashboard                       ← Dashboard Financeiro
│   ├── KPIs: total a receber, vencidos, recebido (mes), inadimplencia (%)
│   ├── Grafico: recebimentos vs previsao
│   ├── Alertas: titulos vencidos, solicitacoes de credito pendentes
│   └── Fila de trabalho: creditos pendentes de analise
│
├── /financeiro/titulos                         ← Gestao de Titulos
│   ├── Filtros: cliente, status, periodo, valor, representante
│   ├── Tabela: numero, cliente, vencimento, valor, status
│   ├── Botao "Segunda Via" por titulo
│   ├── Exportar (CSV)
│   │
│   └── /financeiro/titulos/:id                 ← Detalhe do Titulo
│       ├── Dados completos
│       ├── Pedido vinculado
│       ├── NF vinculada
│       └── Historico de pagamento
│
├── /financeiro/clientes                        ← Visao Financeira de Clientes
│   ├── Busca: nome, CNPJ
│   ├── Filtros: situacao (adimplente, inadimplente), limite
│   ├── Tabela: nome, limite, disponivel, vencidos, ultimo pagamento
│   │
│   └── /financeiro/clientes/:id                ← Ficha Financeira
│       ├── Limite total, disponivel, utilizado
│       ├── Titulos em aberto (tabela)
│       ├── Historico de pagamentos
│       ├── Score de credito (ultimo)
│       └── Solicitacoes de credito (historico)
│
├── /financeiro/credito                         ← Gestao de Credito (J5)
│   ├── Fila: solicitacoes pendentes de analise
│   ├── Filtros: status, periodo, valor
│   │
│   └── /financeiro/credito/:id                 ← Analise de Credito
│       ├── Dados do cliente
│       ├── Score bureau (Serasa/Boa Vista)
│       ├── Restricoes encontradas
│       ├── Documentos enviados
│       ├── Historico de compras e pagamentos
│       ├── Valor solicitado
│       ├── Campo: valor aprovado
│       ├── Campo: justificativa
│       └── Botoes: "Aprovar" / "Aprovar Parcial" / "Reprovar"
│
├── /financeiro/notas-fiscais                   ← Notas Fiscais (visao geral)
│   ├── Filtros: cliente, periodo, numero NF
│   ├── Tabela: numero, cliente, data, valor
│   ├── Download individual (PDF, XML)
│   └── Download em lote
│
├── /financeiro/notificacoes                    ← Notificacoes
│
└── /financeiro/perfil                          ← Meu Perfil
```

**Total de telas Portal Financeiro: 11**

---

## 7. Painel Admin (`/admin/`)

**Role:** `admin` | Acesso completo a todos os portais +

```
/admin/
│
├── /admin/dashboard                            ← Dashboard do Sistema
│   ├── Status dos conectores (C01-C10): verde/amarelo/vermelho
│   ├── Ultima sincronizacao por conector
│   ├── Usuarios ativos (sessoes)
│   ├── Erros recentes
│   └── Health check do sistema
│
├── /admin/usuarios                             ← Gestao de Usuarios
│   ├── Lista: email, nome, role, ultimo login, status
│   ├── Botao "Criar Usuario"
│   │
│   ├── /admin/usuarios/novo                    ← Criar Usuario
│   │   ├── Email, nome
│   │   ├── Role (select)
│   │   ├── Vinculo (cliente_id ou representante_id conforme role)
│   │   └── Botao "Criar"
│   │
│   └── /admin/usuarios/:id                     ← Editar Usuario
│       ├── Dados
│       ├── Alterar role
│       ├── Sessoes ativas (com botao "Revogar")
│       └── Log de autenticacao
│
├── /admin/conectores                           ← Monitoramento de Conectores
│   ├── Status de cada conector (C01-C10)
│   ├── Circuit breaker: estado, falhas recentes
│   ├── Fila de integracao: itens pendentes de retry
│   └── Logs de sync (sucesso/falha)
│
├── /admin/logs                                 ← Logs de Auditoria
│   ├── Filtros: usuario, tabela, acao, periodo
│   ├── Tabela: data, usuario, acao, tabela, registro, campo
│   └── Detalhe: valor anterior, valor novo, IP
│
├── /admin/logs/autenticacao                    ← Logs de Login
│   ├── Filtros: email, evento, periodo
│   └── Tabela: data, email, evento, IP, user_agent
│
└── /admin/configuracoes                        ← Configuracoes
    ├── Parametros do CIE (alcadas, limites)
    ├── Frequencias de sync
    └── Parametros de sessao (timeout, max dispositivos)
```

**Total de telas Painel Admin: 9**

---

## 8. Pagina de Pre-Cadastro (publica)

```
/cadastro                                       ← Pre-cadastro (sem login)
│
├── Campo CNPJ (com consulta automatica C07)
├── Dados preenchidos automaticamente (razao social, endereco)
├── Campos complementares (contato, segmento)
├── Upload de documentos
├── Termos de uso (checkbox)
└── Botao "Enviar Cadastro"
    → Redireciona para tela de confirmacao
    → Email de acompanhamento enviado
```

---

## 9. Mapa Consolidado

| Portal | Telas | Role | Persona |
|---|---|---|---|
| Login + Pre-cadastro | 3 | Publico | — |
| Portal Cliente | 19 | dealer | P1, P2 |
| Portal Representante | 18 | rep | P3 |
| Portal ADM Vendas | 22 | analyst, manager | P4, P5 |
| Portal Financeiro | 11 | financial | P6 |
| Painel Admin | 9 | admin | — |
| **Total** | **82** | | |

---

## 10. Navegacao Principal por Portal

### Portal Cliente
```
Topbar: Logo Boxer | "Boxer Hub" | [Notificacoes 🔔] | [Perfil ▼] | [Sair]

Menu lateral ou tabs:
├── Dashboard
├── Catalogo
├── Carrinho (badge com qtd)
├── Pedidos
├── Cotacoes
├── Financeiro
│   ├── Titulos
│   ├── Notas Fiscais
│   └── Extrato
├── Credito
├── Pesquisas
└── Pedido Rapido
```

### Portal Representante
```
Topbar: Logo Boxer | "Boxer Hub — Representante" | [Proxy: Cliente X ▼] | [🔔] | [Perfil ▼] | [Sair]

Menu lateral ou tabs:
├── Dashboard
├── Carteira de Clientes
├── Pedidos
├── Cotacoes
├── Performance
└── Notificacoes

(Em Modo Proxy, menu muda para exibir telas do cliente selecionado)
```

### Portal ADM Vendas
```
Topbar: Logo Boxer | "Boxer Hub — ADM" | [🔔] | [Perfil ▼] | [Sair]

Menu lateral:
├── Dashboard
├── Pedidos
│   └── Excecoes
├── Cadastros
├── Clientes
├── Representantes
├── Politica Comercial
├── Tabelas de Precos
├── Campanhas
├── Pesquisas
└── Notificacoes
```

### Portal Financeiro
```
Topbar: Logo Boxer | "Boxer Hub — Financeiro" | [🔔] | [Perfil ▼] | [Sair]

Menu lateral:
├── Dashboard
├── Titulos
├── Clientes (visao financeira)
├── Credito
├── Notas Fiscais
└── Notificacoes
```

---

## 11. Responsividade

| Portal | Desktop | Tablet | Mobile |
|---|---|---|---|
| Portal Cliente | Completo | Completo | Completo (mobile-first) |
| Portal Representante | Completo | Completo | **Primario** (PWA) |
| Portal ADM Vendas | **Primario** | Adaptado | Basico (notificacoes, aprovacoes) |
| Portal Financeiro | **Primario** | Adaptado | Basico (consultas) |
| Painel Admin | **Primario** | — | — |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
