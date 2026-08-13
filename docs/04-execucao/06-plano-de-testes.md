# HUB-DOC-024: Plano de Testes

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Estrategia de Testes

O Boxer Hub usa HTML + JS puro, sem frameworks. A estrategia de testes prioriza **testes manuais estruturados** com checklists por funcionalidade, complementados por testes automatizados onde o risco justifica.

| Nivel | Tipo | Ferramenta | Quando |
|---|---|---|---|
| **1 — Funcional** | Teste manual com checklist | Planilha/checklist | Cada feature entregue |
| **2 — Integracao** | Teste de conectores | Scripts Python/JS | Cada conector implementado |
| **3 — Seguranca** | Teste de permissoes e RLS | SQL + manual | Cada role/policy |
| **4 — Performance** | Teste de carga basico | Lighthouse + manual | Antes do piloto |
| **5 — Aceitacao** | UAT com revendedores | Sessao guiada | Antes do piloto |

---

## 2. Testes Funcionais — Checklists por Jornada

### 2.1 J2 — Pedido de Compra (Critico)

**Pre-condicoes:** Usuario dealer logado, produtos no catalogo, credito disponivel.

| # | Cenario | Resultado esperado | Status |
|---|---|---|---|
| T-J2-01 | Navegar catalogo e ver grid de produtos | Cards com foto, SKU, preco CIE, estoque | |
| T-J2-02 | Buscar por SKU existente | Produto encontrado, card exibido | |
| T-J2-03 | Buscar por SKU inexistente | "Nenhum produto encontrado" | |
| T-J2-04 | Filtrar por categoria | Grid atualiza com produtos da categoria | |
| T-J2-05 | Filtrar por "so promocoes" | Apenas produtos com campanha ativa | |
| T-J2-06 | Abrir PDP | Galeria, ficha tecnica, "o que acompanha", documentos, relacionados | |
| T-J2-07 | Adicionar 1 produto ao carrinho | Badge do carrinho incrementa, toast confirmacao | |
| T-J2-08 | Adicionar mesmo produto novamente | Quantidade incrementa no carrinho | |
| T-J2-09 | Adicionar produto sem estoque (backorder) | Badge laranja, previsao de chegada visivel | |
| T-J2-10 | Revisar carrinho | Todos os itens com foto, qtd editavel, subtotal correto | |
| T-J2-11 | Alterar quantidade no carrinho | Subtotal e total recalculam | |
| T-J2-12 | Remover item do carrinho | Item removido, total atualiza | |
| T-J2-13 | Selecionar condicao de pagamento | Opcoes CIE disponiveis, preco pode variar | |
| T-J2-14 | Preencher OC do cliente | Campo aceita texto livre | |
| T-J2-15 | Enviar pedido com credito suficiente | Pedido criado, toast sucesso, redireciona para detalhe | |
| T-J2-16 | Enviar pedido com credito insuficiente | Botao bloqueado, alerta vermelho com valor excedente | |
| T-J2-17 | Recomprar pedido anterior | Itens copiados para carrinho com precos atuais | |
| T-J2-18 | Pedido rapido por SKU | SKU validado, nome exibido, preco calculado | |
| T-J2-19 | Importar Excel com lista | Itens carregados automaticamente | |
| T-J2-20 | Salvar carrinho como cotacao | Cotacao criada com validade, visivel em "Minhas Cotacoes" | |

### 2.2 J3 — Acompanhamento

| # | Cenario | Resultado esperado | Status |
|---|---|---|---|
| T-J3-01 | Ver lista de pedidos | Pedidos do usuario com status atualizado | |
| T-J3-02 | Filtrar por status "Faturado" | Apenas pedidos faturados | |
| T-J3-03 | Buscar por numero OC | Pedido encontrado | |
| T-J3-04 | Ver timeline de pedido em andamento | Etapas concluidas em verde, atual em azul, futuras em cinza | |
| T-J3-05 | Baixar NF PDF | Download inicia, arquivo valido | |
| T-J3-06 | Baixar XML | Download inicia, XML valido | |
| T-J3-07 | Baixar boleto | Download inicia, boleto com codigo de barras | |

### 2.3 J4 — Financeiro

| # | Cenario | Resultado esperado | Status |
|---|---|---|---|
| T-J4-01 | Ver dashboard financeiro | KPIs: limite, disponivel, vencidos | |
| T-J4-02 | Ver titulos a vencer | Lista filtrada corretamente | |
| T-J4-03 | Ver titulos vencidos | Destacados em vermelho | |
| T-J4-04 | Gerar segunda via de boleto | Boleto PDF gerado, PIX exibido | |
| T-J4-05 | Baixar XML de NF | Download funcional | |
| T-J4-06 | Baixar XMLs em lote (3 NFs) | ZIP com 3 arquivos | |
| T-J4-07 | Exportar extrato CSV | Arquivo CSV com dados corretos | |

### 2.4 J5 — Credito

| # | Cenario | Resultado esperado | Status |
|---|---|---|---|
| T-J5-01 | Ver KPI de credito no dashboard | Disponivel / total com barra colorida | |
| T-J5-02 | Barra verde (uso < 60%) | Cor verde | |
| T-J5-03 | Barra laranja (uso 60-85%) | Cor laranja #e97316 | |
| T-J5-04 | Barra vermelha (uso >= 85%) | Cor vermelha | |
| T-J5-05 | Solicitar aumento de credito | Formulario, submit, toast confirmacao | |
| T-J5-06 | Ver timeline da solicitacao | Status atualizado | |

### 2.5 J1 — Cadastro

| # | Cenario | Resultado esperado | Status |
|---|---|---|---|
| T-J1-01 | Acessar /cadastro sem login | Pagina carrega normalmente | |
| T-J1-02 | Informar CNPJ valido | Dados preenchidos automaticamente (razao social, endereco) | |
| T-J1-03 | Informar CNPJ invalido | Mensagem de erro | |
| T-J1-04 | Preencher 5 etapas completas | Avanca entre etapas com validacao | |
| T-J1-05 | Upload de documento | Arquivo aceito, preview exibido | |
| T-J1-06 | Enviar cadastro | Toast confirmacao, email enviado | |
| T-J1-07 | Ver "Meu Cadastro" | Dados em modo leitura, sem campos editaveis | |
| T-J1-08 | Solicitar alteracao cadastral | Modal abre, submit grava solicitacao | |

---

## 3. Testes de Integracao — Conectores

| # | Conector | Cenario | Resultado esperado |
|---|---|---|---|
| T-C01-01 | C01 ZEN | getProducts() | Retorna lista de produtos, transform aplicado |
| T-C01-02 | C01 ZEN | getProducts() com ERP offline | Retorna cache, registra alerta |
| T-C01-03 | C01 ZEN | submitOrder() com dados validos | erp_pedido_id retornado |
| T-C01-04 | C01 ZEN | submitOrder() com ERP offline | Pedido enfileirado, retry 3x |
| T-C01-05 | C01 ZEN | submitOrder() apos 3 falhas | Pedido na fila_integracao, alerta admin |
| T-C03-01 | C03 Bancario | Gerar segunda via | Boleto PDF retornado |
| T-C04-01 | C04 Fiscal | Buscar NF por numero | PDF e XML retornados |
| T-C06-01 | C06 Comunicacao | Enviar email de boas-vindas | Email recebido |
| T-C07-01 | C07 Receita | Consultar CNPJ valido | Razao social e endereco retornados |
| T-C07-02 | C07 Receita | Consultar CNPJ invalido | Erro tratado, mensagem amigavel |
| T-C08-01 | C08 Politica | Consumir regras publicadas | Regras refletidas no CIE |
| T-C11-01 | C11 Static | Upload Excel 100 linhas | Dados importados, 0 erros |
| T-C11-02 | C11 Static | Upload CSV com coluna faltando | Erro de validacao listado |

---

## 4. Testes de Seguranca

### 4.1 RLS — Row Level Security

| # | Cenario | Resultado esperado |
|---|---|---|
| T-SEC-01 | dealer consulta pedidos de OUTRO cliente | Retorno vazio (RLS bloqueia) |
| T-SEC-02 | dealer tenta acessar /adm/dashboard | Acesso negado |
| T-SEC-03 | rep consulta cliente FORA da sua carteira | Retorno vazio |
| T-SEC-04 | analyst tenta aprovar pedido acima de R$50k | Botao desabilitado / API rejeita |
| T-SEC-05 | Requisicao sem JWT valido | 401 Unauthorized |
| T-SEC-06 | JWT expirado | Redirect para login |
| T-SEC-07 | Tentativa de SQL injection via campo de busca | Input sanitizado, sem erro de banco |
| T-SEC-08 | XSS via campo de observacoes | HTML escapado na exibicao |

### 4.2 Alcadas

| # | Cenario | Resultado esperado |
|---|---|---|
| T-ALC-01 | analyst aprova pedido de R$30.000 | Aprovado com sucesso |
| T-ALC-02 | analyst tenta aprovar pedido de R$80.000 | Rejeitado — "Excede sua alcada" |
| T-ALC-03 | manager aprova pedido de R$150.000 | Aprovado com sucesso |
| T-ALC-04 | manager tenta aprovar pedido de R$250.000 | Rejeitado — escalar para admin |
| T-ALC-05 | financial aprova credito de R$80.000 | Aprovado |
| T-ALC-06 | financial tenta aprovar credito de R$150.000 | Rejeitado — escalar para admin |

---

## 5. Testes de Performance

| # | Cenario | Metrica | Meta |
|---|---|---|---|
| T-PERF-01 | Carregar catalogo (200 produtos) | Tempo de carregamento | < 3s |
| T-PERF-02 | Buscar produto | Tempo de resposta | < 500ms |
| T-PERF-03 | Enviar pedido | Tempo de processamento | < 2s |
| T-PERF-04 | Carregar lista de titulos (100 itens) | Tempo de carregamento | < 2s |
| T-PERF-05 | Lighthouse score (mobile) | Performance | >= 80 |
| T-PERF-06 | Lighthouse score (desktop) | Performance | >= 90 |
| T-PERF-07 | Tamanho do HTML principal | Peso da pagina | < 500KB |

---

## 6. Testes de Aceitacao (UAT)

### 6.1 Participantes

| Grupo | Quantidade | Perfil |
|---|---|---|
| Revendedores piloto | 3-5 | P1 (Carlos) — smartphone, pedidos frequentes |
| Compradora profissional | 1 | P2 (Marina) — notebook, pedidos em lote |
| Analista comercial | 1 | P4 (Fernanda) — desktop, aprovacoes |
| Andre (produto) | 1 | Validacao geral |

### 6.2 Roteiro UAT

| Sessao | Duracao | Tarefas |
|---|---|---|
| 1. Primeiro acesso | 30min | Login, navegar dashboard, explorar catalogo |
| 2. Compra completa | 45min | Buscar produto, ver PDP, adicionar ao carrinho, enviar pedido |
| 3. Acompanhamento | 20min | Ver pedido na lista, timeline, baixar NF |
| 4. Financeiro | 30min | Consultar titulos, gerar segunda via, ver credito |
| 5. Problemas | 20min | Pedido com credito insuficiente, produto sem estoque |
| 6. Enterprise (P2) | 30min | Pedido rapido, importar Excel, baixar XMLs em lote |

### 6.3 Criterios de Aceite UAT

- [ ] 100% dos cenarios criticos (J2, J3) completados sem erro bloqueante
- [ ] NPS dos participantes >= 7
- [ ] Nenhum dado sensivel exposto (credenciais, dados de outro cliente)
- [ ] Tempo medio para colocar pedido < 5 minutos
- [ ] Zero erros de integracao durante a sessao

---

## 7. Ambientes de Teste

| Ambiente | URL | Banco | Dados |
|---|---|---|---|
| **Desenvolvimento** | localhost | boxer-hubcomercial (branch dev) | Mock/seed |
| **Staging** | staging.hub.boxersoldas.com.br | boxer-hubcomercial (branch staging) | Dados reais sanitizados |
| **Producao** | hub.boxersoldas.com.br | boxer-hubcomercial (main) | Dados reais |

---

## 8. Criterios de Go/No-Go para Piloto

| Criterio | Obrigatorio |
|---|---|
| Todos os testes T-J2 passando | Sim |
| Todos os testes T-J3 passando | Sim |
| Todos os testes T-SEC passando | Sim |
| Todos os testes T-C01 passando | Sim |
| Lighthouse >= 80 mobile | Sim |
| Testes J4, J5 passando | Desejavel |
| UAT concluido sem bloqueantes | Sim |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
