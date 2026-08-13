# HUB-DOC-018: Matriz de Origem dos Dados

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

Esta matriz rastreia, para cada informacao exibida nas telas do Boxer Hub, de onde o dado vem, como chega, com que frequencia e se o usuario pode edita-lo. Ela e a referencia para desenvolvimento e para diagnostico de problemas de dados.

### Legenda — Origem

| Codigo | Origem | Descricao |
|---|---|---|
| **ERP** | ERP ZEN (C01) | Dados transacionais do sistema legado |
| **SUP** | Supabase (direto) | Dados nativos do Boxer Hub |
| **CIE** | Motor de Inteligencia | Dados calculados em tempo real |
| **RF** | Receita Federal (C07) | Consulta BrasilAPI |
| **BUR** | Bureau de credito (C02) | Serasa / Boa Vista |
| **BAN** | Conector bancario (C03) | Dados bancarios |
| **FIS** | Conector fiscal (C04) | NF, XML |
| **LOG** | Conector logistica (C05) | Rastreamento transportadora |
| **LOG-D** | Dashboard logistica (C09) | Previsao de chegada |
| **POL** | Politica comercial (C08) | Regras do sistema externo |
| **USR** | Input do usuario | Preenchido manualmente |
| **AUTH** | Supabase Auth | Dados de autenticacao |
| **CALC** | Calculado no frontend | Derivado de outros campos |

### Legenda — Modo

| Modo | Descricao |
|---|---|
| **Sync** | Sincronizado periodicamente via polling |
| **Demand** | Consultado sob demanda (ao acessar a tela) |
| **Real** | Tempo real (Supabase Realtime / WebSocket) |
| **Local** | Armazenado localmente no Boxer Hub |
| **Cache** | Cacheado por periodo definido |

### Legenda — Editavel

| Simbolo | Descricao |
|---|---|
| ✎ | Editavel pelo usuario |
| 👁 | Somente leitura |
| ✎/👁 | Editavel por alguns roles, leitura para outros |

---

## 2. Portal Cliente — Dashboard

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Pedidos em andamento (qtd) | ERP | Sync | 15 min | 👁 | `pedidos` |
| Limite disponivel | ERP + CALC | Sync | 1h | 👁 | `clientes.limite_disponivel` |
| Titulos vencidos (valor) | ERP/BAN | Sync | 1h | 👁 | `titulos` |
| Promocoes ativas (qtd) | SUP | Local | — | 👁 | `campanhas` |
| Banner de promocao | SUP | Local | — | 👁 | `campanhas.banner_url` |
| Ultimos pedidos (lista) | ERP | Sync | 15 min | 👁 | `pedidos` |
| Pesquisas pendentes | SUP | Real | — | 👁 | `pesquisas` |
| Notificacoes recentes | SUP | Real | — | ✎ (marcar lida) | `notificacoes` |

---

## 3. Portal Cliente — Catalogo

### Grid de Produtos

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Nome do produto | ERP | Sync | 30 min | 👁 | `produtos.nome` |
| SKU | ERP | Sync | 30 min | 👁 | `produtos.sku` |
| Foto principal | SUP | Local | — | 👁 | `produto_fotos` (Storage) |
| Categoria | ERP | Sync | 30 min | 👁 | `categorias.nome` |
| Preco personalizado | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Preco original (se promocao) | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Badge "PROMOCAO" | SUP | Local | — | 👁 | `campanha_produtos` |
| Estoque disponivel | ERP | Sync | 30 min | 👁 | `produtos.estoque_disponivel` |
| Previsao de chegada | LOG-D | Sync | 6h | 👁 | `produtos.previsao_chegada` |
| Destaque (flag) | SUP | Local | — | 👁 | `produtos.destaque` |

### PDP (Pagina de Detalhe)

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Galeria de fotos | SUP | Local | — | 👁 | `produto_fotos` (Storage) |
| Descricao completa | ERP | Sync | 30 min | 👁 | `produtos.descricao` |
| Ficha tecnica (grade) | ERP | Sync | 30 min | 👁 | `produtos.ficha_tecnica` (jsonb) |
| O que acompanha | ERP/SUP | Sync | 30 min | 👁 | `produtos.o_que_acompanha` |
| Documentos (PDF) | SUP | Local | — | 👁 | `produto_documentos` (Storage) |
| Preco (CIE) | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Tabela aplicada (nome) | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Regras aplicadas | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Produtos relacionados | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Unidade de medida | ERP | Sync | 30 min | 👁 | `produtos.unidade` |
| Peso bruto | ERP | Sync | 30 min | 👁 | `produtos.peso_bruto` |
| NCM | ERP | Sync | 30 min | 👁 | `produtos.ncm` |

---

## 4. Portal Cliente — Carrinho e Pedido

### Carrinho

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Itens no carrinho | USR | Local | — | ✎ | Sessao (frontend) |
| Quantidade por item | USR | Local | — | ✎ | Sessao (frontend) |
| Preco unitario | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Subtotal | CALC | Local | — | 👁 | Frontend |
| Desconto por item | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Total do carrinho | CALC | Local | — | 👁 | Frontend |
| Sugestoes cross-sell | CIE | Demand | Tempo real | 👁 | Calculado (Edge Fn) |
| Condicao de pagamento | USR | — | — | ✎ | Input do usuario |
| Endereco de entrega | SUP | Local | — | ✎ (selecionar) | `enderecos` |
| Numero do pedido (OC) | USR | — | — | ✎ | Input do usuario |
| Observacoes | USR | — | — | ✎ | Input do usuario |
| Flag backorder | ERP | Sync | 30 min | 👁 | `produtos.estoque_disponivel` |
| Previsao backorder | LOG-D | Sync | 6h | 👁 | `produtos.previsao_chegada` |

### Pedido (apos envio)

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Numero do pedido | SUP | Local | — | 👁 | `pedidos.numero` |
| Status | ERP | Sync | 15 min | 👁 | `pedidos.status` |
| Timeline (historico de status) | ERP + SUP | Sync | 15 min | 👁 | `pedidos.status` + logs |
| Data de criacao | SUP | Local | — | 👁 | `pedidos.criado_em` |
| Valor total | SUP | Local | — | 👁 | `pedidos.valor_total` |
| Condicao de pagamento | SUP | Local | — | 👁 | `pedidos.condicao_pagamento` |
| OC do cliente | USR | Local | — | 👁 | `pedidos.pedido_cliente` |
| Criado por representante | SUP | Local | — | 👁 | `pedidos.representante_id` |
| Itens (tabela) | SUP | Local | — | 👁 | `pedido_itens` |
| Preco por item | SUP | Local | — | 👁 | `pedido_itens.preco_unitario` |
| Regra CIE aplicada | SUP | Local | — | 👁 | `pedido_itens.regra_preco_ref` |
| ID no ERP | ERP | Sync | 15 min | 👁 | `pedidos.erp_pedido_id` |
| Aprovado por | SUP | Local | — | 👁 | `pedidos.aprovado_por` |

---

## 5. Portal Cliente — Financeiro

### Titulos

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Limite total | ERP | Sync | 1h | 👁 | `clientes.limite_credito` |
| Limite disponivel | CALC | Sync | 1h | 👁 | `clientes.limite_disponivel` |
| Numero do titulo | ERP/BAN | Sync | 1h | 👁 | `titulos.numero_titulo` |
| Tipo (duplicata, boleto) | ERP/BAN | Sync | 1h | 👁 | `titulos.tipo` |
| Valor | ERP/BAN | Sync | 1h | 👁 | `titulos.valor` |
| Vencimento | ERP/BAN | Sync | 1h | 👁 | `titulos.vencimento` |
| Status (a vencer/vencido/pago) | ERP/BAN | Sync | 1h | 👁 | `titulos.status` |
| Data de pagamento | BAN | Sync | 1h | 👁 | `titulos.data_pagamento` |
| Linha digitavel | BAN | Demand | — | 👁 | `titulos.linha_digitavel` |
| PIX copia e cola | BAN | Demand | — | 👁 | `titulos.pix_copia_cola` |
| Boleto PDF (segunda via) | BAN | Demand | — | 👁 | `titulos.boleto_url` (Storage) |

### Notas Fiscais

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Numero NF | FIS | Sync | 15 min | 👁 | `notas_fiscais.numero_nf` |
| Serie | FIS | Sync | 15 min | 👁 | `notas_fiscais.serie` |
| Chave de acesso | FIS | Sync | 15 min | 👁 | `notas_fiscais.chave_acesso` |
| Valor total | FIS | Sync | 15 min | 👁 | `notas_fiscais.valor_total` |
| Data emissao | FIS | Sync | 15 min | 👁 | `notas_fiscais.data_emissao` |
| PDF da NF | FIS | Sync | 15 min | 👁 | `notas_fiscais.pdf_url` (Storage) |
| XML da NF | FIS | Sync | 15 min | 👁 | `notas_fiscais.xml_url` (Storage) |

---

## 6. Portal Cliente — Credito

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Limite atual | ERP | Sync | 1h | 👁 | `clientes.limite_credito` |
| Score bureau | BUR | Demand | Cache 24h | 👁 | `solicitacoes_credito.score_bureau` |
| Restricoes | BUR | Demand | Cache 24h | 👁 | `solicitacoes_credito.restricoes` |
| Status da solicitacao | SUP | Local | — | 👁 | `solicitacoes_credito.status` |
| Valor solicitado | USR | Local | — | ✎ (no envio) | `solicitacoes_credito.valor_solicitado` |
| Valor aprovado | SUP | Local | — | 👁 | `solicitacoes_credito.valor_aprovado` |
| Documentos enviados | USR | Local | — | ✎ (upload) | Supabase Storage |
| Justificativa | USR | Local | — | ✎ (no envio) | Input → Edge Fn |
| Analisado por | SUP | Local | — | 👁 | `solicitacoes_credito.analisado_por` |
| Timeline da solicitacao | SUP | Real | — | 👁 | Derivado de status + logs |

---

## 7. Portal Representante

### Dashboard

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Clientes ativos (qtd) | SUP | Local | — | 👁 | `carteira` + `clientes` |
| Faturamento do mes | ERP | Sync | 30 min | 👁 | `pedidos` (agregado) |
| Meta mensal | SUP | Local | — | 👁 | `representantes.meta_mensal` |
| % da meta | CALC | Local | — | 👁 | Frontend |
| Pedidos em andamento | ERP | Sync | 15 min | 👁 | `pedidos` (filtro carteira) |
| Clientes sem compra >30d | CALC | Demand | — | 👁 | `pedidos` + `clientes` |
| Creditos liberados | SUP | Real | — | 👁 | `solicitacoes_credito` |
| Pedidos com problema | ERP/SUP | Sync | 15 min | 👁 | `pedidos` (status excecao) |

### Visao do Cliente

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Dados cadastrais | ERP/SUP | Sync | 30 min | 👁 | `clientes` |
| Ultimo pedido | ERP | Sync | 15 min | 👁 | `pedidos` |
| Historico compras (grafico) | ERP | Sync | 30 min | 👁 | `pedidos` (agregado) |
| Limite de credito | ERP | Sync | 1h | 👁 | `clientes.limite_credito` |
| Situacao financeira | ERP/BAN | Sync | 1h | 👁 | `titulos` (agregado) |
| Produtos mais comprados | CALC | Demand | — | 👁 | `pedido_itens` (agregado) |
| Oportunidades CIE | CIE | Demand | — | 👁 | Calculado (Edge Fn) |

### Performance

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Vendas vs meta | ERP + SUP | Sync | 30 min | 👁 | `pedidos` + `representantes` |
| Comissoes acumuladas | CALC | Demand | — | 👁 | Calculado |
| Ranking | CALC | Demand | — | 👁 | Calculado |

---

## 8. Portal ADM Vendas

### Dashboard

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Pedidos hoje | SUP | Local | — | 👁 | `pedidos` (agregado) |
| Pendentes de aprovacao | SUP | Real | — | 👁 | `pedidos` (status=em_analise) |
| Cadastros pendentes | SUP | Real | — | 👁 | `clientes` (status=em_analise) |
| Excecoes na semana | SUP | Local | — | 👁 | Log + pedidos |
| Pipeline (funil) | SUP | Local | — | 👁 | `pedidos` (agregado por status) |
| Fila de trabalho | SUP | Real | — | 👁 | Pedidos + cadastros pendentes |

### Gestao de Campanha

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Nome da campanha | USR | Local | — | ✎ | `campanhas.nome` |
| Descricao | USR | Local | — | ✎ | `campanhas.descricao` |
| Produtos incluidos | USR | Local | — | ✎ | `campanha_produtos` |
| Tipo de desconto | USR | Local | — | ✎ | `campanhas.tipo_desconto` |
| Valor do desconto | USR | Local | — | ✎ | `campanhas.valor_desconto` |
| Vigencia inicio/fim | USR | Local | — | ✎ | `campanhas.vigencia_*` |
| Publico-alvo | USR | Local | — | ✎ | `campanhas.publico_alvo` |
| Banner | USR | Local | — | ✎ | `campanhas.banner_url` (Storage) |
| Desempenho (vendas) | CALC | Demand | — | 👁 | Calculado |

### Gestao de Pesquisa

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Titulo | USR | Local | — | ✎ | `pesquisas.titulo` |
| Perguntas | USR | Local | — | ✎ | `pesquisa_perguntas` |
| Publico-alvo | USR | Local | — | ✎ | `pesquisas.publico_alvo` |
| Vigencia | USR | Local | — | ✎ | `pesquisas.vigencia_*` |
| Obrigatoria | USR | Local | — | ✎ | `pesquisas.obrigatoria` |
| Respostas (agregado) | SUP | Real | — | 👁 | `pesquisa_respostas` |
| Taxa de resposta | CALC | Demand | — | 👁 | Calculado |

---

## 9. Portal Financeiro

### Analise de Credito

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Dados do cliente | ERP/SUP | Sync | 30 min | 👁 | `clientes` |
| Score Serasa | BUR | Demand | Cache 24h | 👁 | Via C02 |
| Score Boa Vista | BUR | Demand | Cache 24h | 👁 | Via C02 |
| Restricoes | BUR | Demand | Cache 24h | 👁 | Via C02 |
| Historico de compras | ERP | Sync | 30 min | 👁 | `pedidos` (agregado) |
| Media mensal | CALC | Demand | — | 👁 | Calculado |
| Atrasos (historico) | ERP/BAN | Sync | 1h | 👁 | `titulos` |
| Documentos financeiros | USR | Local | — | 👁 | Supabase Storage |
| Valor solicitado | USR | Local | — | 👁 | `solicitacoes_credito` |
| Valor aprovado | USR | — | — | ✎ (financeiro) | `solicitacoes_credito` |
| Justificativa | USR | — | — | ✎ (financeiro) | `solicitacoes_credito` |

---

## 10. Dados Transversais

### Cadastro (J1)

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| CNPJ | USR | — | — | ✎ (no cadastro) | `clientes.cnpj` |
| Razao social | RF | Demand | Cache 30d | 👁 | `clientes.razao_social` |
| Nome fantasia | RF | Demand | Cache 30d | 👁 | `clientes.nome_fantasia` |
| Endereco | RF + USR | Demand | — | ✎ (complemento) | `enderecos` |
| Inscricao estadual | USR | — | — | ✎ | `clientes.inscricao_estadual` |
| Segmento | USR | — | — | ✎ | `clientes.segmento` |
| Canal | USR/ADM | — | — | ✎/👁 | `clientes.canal` |
| Porte | USR/ADM | — | — | ✎/👁 | `clientes.porte` |
| Email principal | USR | — | — | ✎ | `clientes.email_principal` |
| Telefone | USR | — | — | ✎ | `clientes.telefone` |
| Documentos cadastrais | USR | — | — | ✎ (upload) | `documentos_cadastrais` (Storage) |
| Status do cadastro | SUP | Local | — | ✎/👁 (ADM) | `clientes.status_cadastro` |
| Representante vinculado | CIE/ADM | — | — | ✎/👁 | `carteira` |

### Rastreamento (J3)

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Codigo de rastreio | ERP/LOG | Sync | 2h | 👁 | Via C05 |
| Status da entrega | LOG | Sync | 2h | 👁 | Via C05 |
| Previsao de entrega | LOG | Sync | 2h | 👁 | Via C05 |

### Notificacoes

| Campo / Informacao | Origem | Modo | Freq. | Editavel | Tabela Supabase |
|---|---|---|---|---|---|
| Tipo | SUP | Real | — | 👁 | `notificacoes.tipo` |
| Titulo | SUP | Real | — | 👁 | `notificacoes.titulo` |
| Mensagem | SUP | Real | — | 👁 | `notificacoes.mensagem` |
| Link de acao | SUP | Real | — | 👁 | `notificacoes.link` |
| Lida (flag) | SUP | Real | — | ✎ | `notificacoes.lida` |

---

## 11. Resumo: Frequencias de Sincronizacao

| Conector | Dados | Frequencia | Modo |
|---|---|---|---|
| C01 ERP (ZEN) | Produtos, categorias | 30 min | Sync |
| C01 ERP (ZEN) | Estoque | 30 min | Sync |
| C01 ERP (ZEN) | Status de pedidos | 15 min | Sync |
| C02 Credit | Score, restricoes | Sob demanda | Demand + Cache 24h |
| C03 Bank | Titulos, boletos | 1h | Sync |
| C04 Fiscal | NFs, PDFs, XMLs | 15 min | Sync |
| C05 Logistics | Rastreamento | 2h | Sync |
| C06 Communication | — | Sob demanda | Demand |
| C07 Federal Revenue | CNPJ | Sob demanda | Demand + Cache 30d |
| C08 Commercial Policy | Regras | 1h | Sync |
| C09 Logistics Dashboard | Previsao estoque | 6h | Sync |

---

## 12. Regras de Integridade

1. **Dados do ERP sao somente leitura** no Boxer Hub (espelhamento unidirecional para consulta)
2. **Excecoes de escrita para o ERP:** criar pedido (C01), criar cliente (C01), atualizar limite (C01) — via Edge Functions
3. **Dados do usuario (USR) sao editaveis** apenas no momento do input (cadastro, pedido, solicitacao)
4. **Dados do CIE sao calculados** em tempo real e nunca armazenados (exceto snapshot no pedido: `regra_preco_ref`)
5. **Bureau de credito tem cache** de 24h para evitar consultas excessivas e custos
6. **Receita Federal tem cache** de 30 dias (dados cadastrais mudam raramente)
7. **Dados financeiros (titulos, NFs)** sao a fonte mais critica — discrepancias devem gerar alerta
8. **Carrinho existe apenas no frontend** (sessao) ate o envio do pedido — nao e persistido no banco

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
