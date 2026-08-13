# HUB-DOC-022: User Stories e Criterios de Aceite

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Formato

```
US-[epico].[seq]: Como [persona], quero [acao] para [beneficio].

Criterios de Aceite:
- [ ] CA-1: ...
- [ ] CA-2: ...
```

Foco: User Stories das features P0 e P1 (bloqueantes e criticas para MVP). Features P2 listadas com stories resumidas.

---

## 2. E01 — Infraestrutura Base

### US-01.1: Login

**Como** revendedor (P1), **quero** fazer login com email e senha **para** acessar meu portal com seguranca.

- [ ] CA-1: Tela de login exibe campos email e senha com design Boxer (paleta navy, Outfit)
- [ ] CA-2: Login bem-sucedido redireciona para `/cliente/dashboard` se role = dealer
- [ ] CA-3: Login com credenciais erradas exibe "Email ou senha incorretos" sem revelar qual esta errado
- [ ] CA-4: Campo email aceita apenas formato valido
- [ ] CA-5: Apos login, SESSION armazena access_token e user_metadata (incluindo role)
- [ ] CA-6: Topbar exibe nome do usuario logado e botao "Sair"
- [ ] CA-7: Logout limpa sessao e redireciona para tela de login

### US-01.2: Roteamento por role

**Como** usuario, **quero** ser redirecionado automaticamente ao meu portal **para** nao precisar escolher onde entrar.

- [ ] CA-1: dealer → `/cliente/dashboard`
- [ ] CA-2: rep → `/representante/dashboard`
- [ ] CA-3: analyst/manager → `/adm/dashboard`
- [ ] CA-4: financial → `/financeiro/dashboard`
- [ ] CA-5: admin → `/admin/dashboard`
- [ ] CA-6: Acesso direto a URL de outro portal retorna "Acesso negado"

### US-01.3: Recuperacao de senha

**Como** revendedor (P1), **quero** recuperar minha senha por email **para** nao depender de suporte.

- [ ] CA-1: Link "Esqueci minha senha" na tela de login
- [ ] CA-2: Informar email envia link de reset via Supabase Auth
- [ ] CA-3: Mensagem de confirmacao exibida independente do email existir (seguranca)
- [ ] CA-4: Link expira em 1 hora

---

## 3. E02 — Catalogo e PDP

### US-02.1: Navegar catalogo

**Como** revendedor (P1), **quero** ver os produtos em grid com foto e preco **para** escolher o que comprar sem precisar ligar.

- [ ] CA-1: Grid exibe cards com: foto, SKU, nome, preco CIE personalizado, indicador de estoque
- [ ] CA-2: Preco exibido ja reflete tabela do cliente e regras CIE
- [ ] CA-3: Produto com estoque exibe "Disponivel" em verde
- [ ] CA-4: Produto sem estoque exibe "Sem estoque — Previsao: DD/MM" em laranja
- [ ] CA-5: Card exibe badge "PROMO" quando produto esta em campanha ativa
- [ ] CA-6: Preco original riscado e preco final com "X% OFF" quando ha desconto
- [ ] CA-7: Grid carrega com paginacao (20 produtos por pagina)

### US-02.2: Buscar produto

**Como** revendedor (P1), **quero** buscar por SKU ou nome **para** encontrar rapidamente o que preciso.

- [ ] CA-1: Campo de busca no topo do catalogo
- [ ] CA-2: Busca por SKU exato retorna o produto correspondente
- [ ] CA-3: Busca por texto busca em nome e descricao
- [ ] CA-4: Resultados atualizam ao digitar (debounce 300ms)
- [ ] CA-5: Sem resultados exibe "Nenhum produto encontrado"

### US-02.3: Filtrar catalogo

**Como** compradora profissional (P2), **quero** filtrar por categoria e disponibilidade **para** refinar minha busca.

- [ ] CA-1: Filtros laterais: categoria (arvore), disponibilidade (disponivel, sem estoque, todos), faixa de preco, promocao (sim/nao)
- [ ] CA-2: Filtros combinam entre si (AND)
- [ ] CA-3: Contador de resultados atualiza com filtros aplicados
- [ ] CA-4: Botao "Limpar filtros" reseta todos

### US-02.4: Ver PDP

**Como** revendedor (P1), **quero** ver a pagina completa do produto **para** entender exatamente o que estou comprando.

- [ ] CA-1: Galeria de fotos com thumbnails e zoom ao clicar
- [ ] CA-2: Nome, SKU, categoria exibidos em destaque
- [ ] CA-3: Preco CIE personalizado — se promo: preco riscado + promocional + % OFF
- [ ] CA-4: Estoque ou previsao de chegada
- [ ] CA-5: Ficha tecnica em grade (classificacao, diametro, peso, gas, posicoes, etc.)
- [ ] CA-6: Secao "O que acompanha" com checklist
- [ ] CA-7: Secao "Sobre o produto" posicionada ABAIXO de "O que acompanha"
- [ ] CA-8: Documentos para download (ficha tecnica PDF, FISPQ, certificado, manual) — cada com icone e tamanho
- [ ] CA-9: Produtos relacionados (CIE) no rodape da PDP
- [ ] CA-10: Seletor de quantidade + botao "Adicionar ao carrinho"
- [ ] CA-11: Se sem estoque + backorder: aviso + previsao + botao "Reservar"
- [ ] CA-12: Breadcrumbs no topo (Home > Categoria > Produto)

---

## 4. E03 — Pedido de Compra

### US-03.1: Adicionar ao carrinho

**Como** revendedor (P1), **quero** adicionar produtos ao carrinho **para** montar meu pedido.

- [ ] CA-1: Botao "Adicionar ao carrinho" no grid e na PDP
- [ ] CA-2: Seletor de quantidade (minimo 1, maximo = estoque ou sem limite se backorder)
- [ ] CA-3: Adicionar produto ja no carrinho incrementa quantidade
- [ ] CA-4: Badge no icone do carrinho atualiza com total de itens
- [ ] CA-5: Toast de confirmacao "Produto adicionado ao carrinho"

### US-03.2: Revisar carrinho

**Como** revendedor (P1), **quero** revisar itens, quantidades e precos antes de enviar **para** garantir que esta tudo correto.

- [ ] CA-1: Lista de itens com foto, nome, SKU, quantidade editavel, preco unitario, subtotal
- [ ] CA-2: Botao remover item (com confirmacao)
- [ ] CA-3: Itens com backorder sinalizados com badge laranja e previsao
- [ ] CA-4: Condicao de pagamento: select com opcoes CIE (28/35/42 dias)
- [ ] CA-5: Endereco de entrega: select entre enderecos cadastrados
- [ ] CA-6: Campo "Seu Pedido (OC)": texto livre para numero interno do revendedor
- [ ] CA-7: Campo observacoes: textarea para instrucoes adicionais
- [ ] CA-8: Resumo: subtotal, descontos CIE (detalhados), total final
- [ ] CA-9: Se total > credito disponivel: alerta vermelho com valor excedente e botoes "Solicitar Aumento" e "Antecipar Pagamento"

### US-03.3: Enviar pedido

**Como** revendedor (P1), **quero** confirmar e enviar meu pedido **para** que a Boxer processe.

- [ ] CA-1: Botao "Enviar Pedido" submete para validacao CIE
- [ ] CA-2: CIE valida: credito, politica comercial, elegibilidade, alcada
- [ ] CA-3: Se aprovacao automatica: pedido vai direto ao ERP (C01)
- [ ] CA-4: Se precisa aprovacao manual: status = "Aguardando Aprovacao", notifica analyst/manager
- [ ] CA-5: Se credito insuficiente: checkout bloqueado, nao permite envio
- [ ] CA-6: Sucesso: toast "Pedido #XXX enviado com sucesso" + redireciona para detalhe do pedido
- [ ] CA-7: Erro de integracao: toast de erro + pedido enfileirado para retry

### US-03.4: Recomprar pedido anterior

**Como** revendedor (P1), **quero** reenviar um pedido anterior com 1 clique **para** nao perder tempo repetindo.

- [ ] CA-1: Botao "Recomprar" no detalhe do pedido
- [ ] CA-2: Copia todos os itens para o carrinho com quantidades originais
- [ ] CA-3: Precos recalculados pelo CIE (refletem condicoes atuais)
- [ ] CA-4: Itens descontinuados sinalizados com aviso
- [ ] CA-5: Redireciona para o carrinho para revisao antes de enviar

### US-03.5: Pedido rapido

**Como** compradora profissional (P2), **quero** digitar SKUs e quantidades diretamente **para** nao navegar o catalogo inteiro.

- [ ] CA-1: Tela com campo SKU + quantidade, linha a linha
- [ ] CA-2: SKU validado em tempo real (exibe nome do produto ao confirmar)
- [ ] CA-3: SKU invalido exibe erro "Produto nao encontrado"
- [ ] CA-4: Botao "Adicionar linha" para mais itens
- [ ] CA-5: Preview com precos CIE antes de enviar
- [ ] CA-6: Botao "Importar Excel/CSV" abre upload de planilha
- [ ] CA-7: Planilha importada preenche a lista automaticamente

---

## 5. E04 — Acompanhamento de Pedido

### US-04.1: Ver meus pedidos

**Como** revendedor (P1), **quero** ver todos os meus pedidos com status **para** saber o que esta em andamento.

- [ ] CA-1: Lista de pedidos com colunas: numero, data, valor total, status (badge), OC
- [ ] CA-2: Filtros: status (todos, em analise, aprovado, em separacao, faturado, expedido, entregue), periodo, faixa de valor
- [ ] CA-3: Busca por numero do pedido ou numero da OC
- [ ] CA-4: Ordenacao por data (mais recente primeiro)
- [ ] CA-5: Paginacao (10 pedidos por pagina)

### US-04.2: Ver timeline do pedido

**Como** revendedor (P1), **quero** ver uma timeline visual do meu pedido **para** saber exatamente onde ele esta sem ligar para ninguem.

- [ ] CA-1: Timeline vertical com 10 etapas possiveis
- [ ] CA-2: Etapa concluida: icone verde, data/hora
- [ ] CA-3: Etapa atual: icone azul pulsante
- [ ] CA-4: Etapa futura: icone cinza com previsao quando disponivel
- [ ] CA-5: Documentos vinculados ao pedido: NF PDF, XML, boleto — botao de download em cada
- [ ] CA-6: Itens do pedido em tabela (foto, SKU, nome, qtd, preco, subtotal)
- [ ] CA-7: Dados: condicao de pagamento, endereco de entrega, OC, observacoes

---

## 6. E05 — Financeiro do Cliente

### US-05.1: Consultar titulos

**Como** revendedor (P1), **quero** ver meus titulos em aberto e vencidos **para** controlar meu financeiro.

- [ ] CA-1: Dashboard com KPIs: limite total, limite disponivel, total a vencer, total vencido
- [ ] CA-2: Lista de titulos com filtros: status (a vencer, vencido, pago), periodo, faixa de valor
- [ ] CA-3: Cada titulo exibe: numero, vencimento, valor, status (badge colorido)
- [ ] CA-4: Titulo vencido destacado em vermelho

### US-05.2: Segunda via de boleto

**Como** revendedor (P1), **quero** gerar segunda via de boleto direto no sistema **para** nao ter que ligar pedindo.

- [ ] CA-1: Botao "Segunda via" em cada titulo com status "a vencer" ou "vencido"
- [ ] CA-2: Gera boleto atualizado via conector bancario (C03)
- [ ] CA-3: Exibe codigo de barras + codigo PIX (quando disponivel)
- [ ] CA-4: Botao "Baixar PDF" do boleto
- [ ] CA-5: Toast de sucesso "Boleto gerado"
- [ ] CA-6: Erro de geracao: toast com mensagem "Tente novamente em alguns minutos"

### US-05.3: Baixar NFs

**Como** compradora profissional (P2), **quero** baixar XMLs em lote **para** conciliacao automatica no meu sistema.

- [ ] CA-1: Lista de NFs com filtros: periodo, numero NF
- [ ] CA-2: Cada NF com botao "PDF" e botao "XML"
- [ ] CA-3: Checkbox de selecao multipla
- [ ] CA-4: Botao "Baixar XMLs selecionados" gera ZIP
- [ ] CA-5: Limite de 50 XMLs por download em lote

---

## 7. E06 — Gestao de Credito

### US-06.1: Ver credito disponivel

**Como** revendedor (P1), **quero** ver meu credito disponivel no dashboard **para** saber se posso fazer um pedido.

- [ ] CA-1: KPI no dashboard: "Credito disponivel: R$ XX.XXX / R$ YY.YYY"
- [ ] CA-2: Barra de progresso: verde (<60%), laranja (<85%), vermelho (>=85%)
- [ ] CA-3: Clicar no KPI abre painel de credito completo
- [ ] CA-4: Painel exibe: limite total, usado, disponivel, ultima analise, score

### US-06.2: Solicitar aumento de credito

**Como** revendedor (P1), **quero** solicitar aumento de limite pelo sistema **para** nao depender do representante.

- [ ] CA-1: Botao "Solicitar Aumento de Limite" no painel de credito
- [ ] CA-2: Formulario: valor desejado, justificativa (textarea), upload de documentos
- [ ] CA-3: Submit cria registro na tabela de solicitacoes pendentes
- [ ] CA-4: Toast "Solicitacao enviada — prazo de analise: ate 5 dias uteis"
- [ ] CA-5: Timeline de acompanhamento visivel no painel (enviado → em analise → aprovado/reprovado)

### US-06.3: Bloqueio de checkout por credito

**Como** sistema, **quero** bloquear o checkout quando o total excede o credito **para** evitar pedidos que serao rejeitados.

- [ ] CA-1: Se total_carrinho > credito_disponivel: botao "Enviar Pedido" desabilitado
- [ ] CA-2: Alerta vermelho: "Credito insuficiente. Seu pedido excede o limite em R$ XX.XXX"
- [ ] CA-3: Dois botoes de acao no alerta: "Solicitar Aumento" e "Antecipar Pagamento"
- [ ] CA-4: "Solicitar Aumento" abre formulario de solicitacao (US-06.2)
- [ ] CA-5: "Antecipar Pagamento" redireciona para titulos em aberto com opcao de antecipar

---

## 8. E07 — Cadastro de Cliente

### US-07.1: Pre-cadastro com CNPJ

**Como** novo revendedor, **quero** iniciar meu cadastro informando meu CNPJ **para** que os dados sejam preenchidos automaticamente.

- [ ] CA-1: Pagina publica `/cadastro` sem login
- [ ] CA-2: Campo CNPJ com mascara (XX.XXX.XXX/XXXX-XX)
- [ ] CA-3: Ao completar CNPJ: consulta automatica Receita Federal (C07)
- [ ] CA-4: Preenche automaticamente: razao social, nome fantasia, endereco, atividade (somente leitura)
- [ ] CA-5: Campos complementares editaveis: contato, telefone, email, volume estimado, segmento
- [ ] CA-6: CNPJ invalido ou nao encontrado: mensagem de erro

### US-07.2: Formulario de cadastro completo

**Como** novo revendedor, **quero** preencher meus dados em etapas organizadas **para** nao me perder no processo.

- [ ] CA-1: 5 etapas sequenciais: (1) Empresa, (2) Endereco, (3) Entrega, (4) Contato, (5) Bancario
- [ ] CA-2: Navegacao entre etapas com indicador de progresso
- [ ] CA-3: Validacao por etapa antes de avancar
- [ ] CA-4: Upload de documentos (contrato social, procuracoes, comprovantes) na etapa final
- [ ] CA-5: Termos de uso com checkbox obrigatorio
- [ ] CA-6: Botao "Enviar Cadastro" grava tudo no Supabase
- [ ] CA-7: Tela de confirmacao: "Cadastro enviado — voce recebera um email com o andamento"
- [ ] CA-8: Email de confirmacao enviado automaticamente

---

## 9. E08 — ADM Operacional

### US-08.1: Aprovar pedido

**Como** analista comercial (P4), **quero** ver pedidos pendentes e aprovar ou rejeitar **para** processar sem atraso.

- [ ] CA-1: Dashboard ADM exibe quantidade de pedidos pendentes de aprovacao
- [ ] CA-2: Fila de pedidos filtravel: status, cliente, representante, periodo, valor
- [ ] CA-3: Detalhe do pedido ADM: itens, precos, regras CIE aplicadas, historico de acoes
- [ ] CA-4: Botao "Aprovar" — habilitado apenas se valor dentro da alcada do role (analyst ate R$50k)
- [ ] CA-5: Botao "Rejeitar" com justificativa obrigatoria (textarea)
- [ ] CA-6: Pedido acima da alcada: botao "Escalar para Gerente" visivel
- [ ] CA-7: Aprovacao envia pedido ao ERP via C01; rejeicao notifica cliente e representante

### US-08.2: Analisar cadastro

**Como** analista comercial (P4), **quero** revisar cadastros pendentes **para** aprovar ou solicitar complementos.

- [ ] CA-1: Fila de cadastros pendentes com data de envio
- [ ] CA-2: Detalhe: dados do cliente (preenchido auto + complemento), documentos enviados (visualizador inline)
- [ ] CA-3: Resultado da consulta Receita Federal (status, atividade, endereco)
- [ ] CA-4: Botao "Aprovar" — cria usuario Supabase Auth, notifica cliente
- [ ] CA-5: Botao "Solicitar Complemento" — especificar o que falta, notifica cliente
- [ ] CA-6: Botao "Rejeitar" com justificativa

---

## 10. E09 — Conector ERP ZEN

### US-09.1: Sincronizar produtos

**Como** sistema, **quero** importar produtos do ERP a cada 30 minutos **para** manter o catalogo atualizado.

- [ ] CA-1: Edge Function executa poll a cada 30 minutos
- [ ] CA-2: Transform ERP.codigo → Hub.sku, ERP.descricao_completa → Hub.descricao
- [ ] CA-3: Produtos novos inseridos, existentes atualizados (upsert por SKU)
- [ ] CA-4: Produto inativado no ERP fica ativo=false no Hub (nao aparece no catalogo)
- [ ] CA-5: Log de sync registra: inicio, fim, total inseridos, total atualizados, erros
- [ ] CA-6: Falha de conexao: retorna dados do cache, registra alerta

### US-09.2: Enviar pedido ao ERP

**Como** sistema, **quero** transmitir pedidos aprovados ao ERP em tempo real **para** que o faturamento comece.

- [ ] CA-1: Apos aprovacao (automatica ou manual), Edge Function chama C01.submitOrder
- [ ] CA-2: Payload: cliente_erp_id, itens (sku, qtd, preco), condicao, endereco, observacoes
- [ ] CA-3: Resposta: erp_pedido_id gravado na tabela de pedidos do Hub
- [ ] CA-4: Status do pedido atualizado para "Enviado ao ERP"
- [ ] CA-5: Retry: 3 tentativas com backoff exponencial (1s, 3s, 9s)
- [ ] CA-6: Apos 3 falhas: pedido vai para fila_integracao, alerta no admin

---

## 11. User Stories Resumidas — P2

### E02 — Catalogo (complementares)

| ID | Story resumida |
|---|---|
| US-02.5 | Como P1, quero alternar entre grid e lista para ver mais produtos de uma vez |
| US-02.6 | Como P1, quero navegar por equipamento (maquina → pecas) para achar pecas especificas |
| US-02.7 | Como P1, quero ver o que acompanha o produto para saber se preciso comprar algo a mais |
| US-02.8 | Como P1, quero baixar ficha tecnica PDF para consultar offline |
| US-02.9 | Como P1, quero ver produtos relacionados para completar minha compra |

### E03 — Pedido (complementares)

| ID | Story resumida |
|---|---|
| US-03.6 | Como P2, quero importar Excel com lista de compras para nao digitar item por item |
| US-03.7 | Como P1, quero salvar carrinho como cotacao para decidir depois |
| US-03.8 | Como P1, quero ver sugestoes de produtos no carrinho para aumentar meu pedido |

### E04 — Acompanhamento (complementares)

| ID | Story resumida |
|---|---|
| US-04.3 | Como P1, quero baixar NF e boleto direto do pedido para nao procurar em outro lugar |

### E05 — Financeiro (complementares)

| ID | Story resumida |
|---|---|
| US-05.4 | Como P1, quero ver extrato completo para controlar meu historico financeiro |
| US-05.5 | Como P2, quero exportar extrato em CSV para importar no meu sistema |

### E07 — Cadastro (complementares)

| ID | Story resumida |
|---|---|
| US-07.3 | Como P1, quero ver meu cadastro sem poder editar para ter seguranca dos dados |
| US-07.4 | Como P1, quero solicitar alteracao cadastral pelo sistema para nao precisar ligar |

### E08 — ADM (complementares)

| ID | Story resumida |
|---|---|
| US-08.3 | Como P4, quero ver a base de clientes com filtros para encontrar rapidamente |
| US-08.4 | Como P5, quero gerenciar tabelas de precos para vincular a cada cliente |
| US-08.5 | Como P4, quero processar solicitacoes de alteracao cadastral para manter dados atualizados |

### E10 — Static Data

| ID | Story resumida |
|---|---|
| US-10.1 | Como P4, quero importar planilha de fichas tecnicas para completar dados que o ERP nao tem |
| US-10.2 | Como P4, quero mapear colunas da planilha para campos do sistema para flexibilidade |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
