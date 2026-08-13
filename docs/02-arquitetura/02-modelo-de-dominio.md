# HUB-DOC-007: Modelo de Dominio

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

O Modelo de Dominio descreve as entidades de negocio do Boxer Hub, seus atributos essenciais e relacionamentos. Ele e a base para o modelo de dados fisico (HUB-DOC-008) e para as APIs (HUB-DOC-011).

---

## 2. Dominios do Negocio

O Boxer Hub organiza suas entidades em 7 dominios funcionais:

| Dominio | Descricao | Entidades Principais |
|---|---|---|
| **Cadastro** | Clientes, representantes e vinculos | Cliente, Representante, Carteira, Endereco, DocumentoCadastral |
| **Catalogo** | Produtos e conteudo comercial | Produto, Categoria, ProdutoFoto, ProdutoDocumento |
| **Comercial** | Pedidos, cotacoes e carrinho | Pedido, PedidoItem, Cotacao, CotacaoItem |
| **Financeiro** | Titulos, credito e documentos fiscais | Titulo, NotaFiscal, SolicitacaoCredito |
| **Inteligencia** | Regras, precos e campanhas | RegraComercial, TabelaPrecos, TabelaPrecoItem, Campanha, CampanhaProduto |
| **Engajamento** | Pesquisas e notificacoes | Pesquisa, PesquisaPergunta, PesquisaResposta, Notificacao |
| **Auditoria** | Logs e rastreabilidade | LogAlteracoes, LogAutenticacao |

---

## 3. Entidades por Dominio

### 3.1 Dominio: Cadastro

#### Cliente
O revendedor/lojista que compra da Boxer Soldas.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cnpj | string | CNPJ (unico) |
| razao_social | string | Razao social (Receita Federal) |
| nome_fantasia | string | Nome fantasia |
| inscricao_estadual | string | IE |
| segmento | string | Segmento de atuacao |
| canal | string | Canal comercial (varejo, industria, distribuidor) |
| porte | string | Porte (pequeno, medio, grande) |
| email_principal | string | Email de contato principal |
| telefone | string | Telefone principal |
| status_cadastro | enum | pre_cadastro, em_analise, ativo, suspenso, inativo |
| limite_credito | decimal | Limite de credito aprovado |
| limite_disponivel | decimal | Limite disponivel (limite - titulos em aberto) |
| tabela_preco_id | UUID | Tabela de precos vinculada |
| representante_id | UUID | Representante responsavel |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

**Relacionamentos:**
- 1 Cliente → N Pedidos
- 1 Cliente → N Titulos
- 1 Cliente → N NotasFiscais
- 1 Cliente → N Enderecos
- 1 Cliente → N SolicitacoesCredito
- 1 Cliente → 1 Representante (via Carteira)
- 1 Cliente → 1 TabelaPrecos
- 1 Cliente → 1 User (Supabase Auth)

#### Representante
O representante comercial que atende clientes em campo.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| nome | string | Nome completo |
| email | string | Email (login) |
| telefone | string | Telefone |
| regiao | string | Regiao de atuacao |
| meta_mensal | decimal | Meta de vendas mensal |
| comissao_percentual | decimal | Percentual de comissao |
| status | enum | ativo, inativo |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

**Relacionamentos:**
- 1 Representante → N Clientes (via Carteira)
- 1 Representante → 1 User (Supabase Auth)

#### Carteira
Vinculo entre representante e cliente.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| representante_id | UUID | FK representante |
| cliente_id | UUID | FK cliente |
| data_vinculo | date | Data do vinculo |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### Endereco
Enderecos de entrega do cliente (pode ter multiplos — filiais).

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cliente_id | UUID | FK cliente |
| tipo | enum | principal, entrega, cobranca |
| cep | string | CEP |
| logradouro | string | Rua/Avenida |
| numero | string | Numero |
| complemento | string | Complemento |
| bairro | string | Bairro |
| cidade | string | Cidade |
| uf | string | Estado (2 letras) |
| referencia | string | Ponto de referencia |
| padrao | boolean | Endereco padrao de entrega |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### DocumentoCadastral
Documentos enviados no processo de cadastro.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cliente_id | UUID | FK cliente |
| tipo | enum | contrato_social, procuracao, comprovante_endereco, balanco, dre, outro |
| nome_arquivo | string | Nome original do arquivo |
| storage_path | string | Caminho no Supabase Storage |
| criado_em | timestamp | Data de upload |

---

### 3.2 Dominio: Catalogo

#### Produto
Produto do catalogo Boxer. Dados espelhados do ERP via conector.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| sku | string | Codigo SKU (unico, origem ERP) |
| nome | string | Nome do produto |
| descricao | text | Descricao completa |
| ncm | string | NCM (classificacao fiscal) |
| categoria_id | UUID | FK categoria |
| unidade | string | Unidade de medida (un, cx, kg) |
| peso_bruto | decimal | Peso bruto (kg) |
| estoque_disponivel | integer | Quantidade em estoque (espelhado ERP) |
| estoque_minimo | integer | Estoque minimo para alerta |
| previsao_chegada | date | Previsao de reposicao (conector logistica) |
| ficha_tecnica | jsonb | Especificacoes tecnicas estruturadas |
| o_que_acompanha | text[] | Lista do que acompanha o produto |
| ordem_exibicao | integer | Ordem no catalogo |
| destaque | boolean | Produto em destaque |
| criado_em | timestamp | Data de criacao |
| atualizado_em | timestamp | Ultima sincronizacao com ERP |
| ativo | boolean | Exclusao logica |

**Relacionamentos:**
- 1 Produto → N ProdutoFotos
- 1 Produto → N ProdutoDocumentos
- 1 Produto → 1 Categoria
- 1 Produto → N PedidoItens
- 1 Produto → N TabelaPrecoItens
- 1 Produto → N CampanhaProdutos

#### Categoria
Categorias de produtos.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| nome | string | Nome da categoria |
| slug | string | Slug para URL/filtro |
| categoria_pai_id | UUID | FK categoria pai (hierarquia) |
| icone | string | Icone representativo |
| ordem | integer | Ordem de exibicao |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### ProdutoFoto
Fotos do produto para exibicao no catalogo e PDP.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| produto_id | UUID | FK produto |
| storage_path | string | Caminho no Supabase Storage |
| alt_text | string | Texto alternativo |
| ordem | integer | Ordem de exibicao (1 = principal) |
| criado_em | timestamp | Data de upload |

#### ProdutoDocumento
Documentos tecnicos do produto (ficha tecnica, FISPQ, certificado, manual).

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| produto_id | UUID | FK produto |
| tipo | enum | ficha_tecnica, certificado, fispq, manual, catalogo |
| nome | string | Nome do documento |
| storage_path | string | Caminho no Supabase Storage |
| criado_em | timestamp | Data de upload |

---

### 3.3 Dominio: Comercial

#### Pedido
Pedido de compra do revendedor.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| numero | string | Numero sequencial legivel (ex: PED-2026-00158) |
| cliente_id | UUID | FK cliente |
| representante_id | UUID | FK representante (se via proxy) |
| pedido_cliente | string | Numero do pedido interno do cliente (OC) |
| status | enum | rascunho, enviado, em_analise, aprovado, rejeitado, faturado, expedido, em_transito, entregue, cancelado |
| condicao_pagamento | string | Condicao de pagamento escolhida |
| observacoes | text | Observacoes do cliente |
| subtotal | decimal | Soma dos itens |
| desconto_total | decimal | Desconto aplicado |
| valor_total | decimal | Valor final |
| tabela_preco_ref | string | Referencia da tabela de preco usada |
| erp_pedido_id | string | ID do pedido no ERP (apos envio) |
| origem | enum | portal_cliente, proxy_representante, importacao_excel, recompra |
| endereco_entrega_id | UUID | FK endereco de entrega |
| aprovado_por | UUID | FK usuario que aprovou (se manual) |
| aprovado_em | timestamp | Data de aprovacao |
| faturado_em | timestamp | Data de faturamento |
| entregue_em | timestamp | Data de entrega |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

**Relacionamentos:**
- 1 Pedido → N PedidoItens
- 1 Pedido → 1 Cliente
- 1 Pedido → 0..1 Representante (proxy)
- 1 Pedido → 1 Endereco
- 1 Pedido → N Titulos (apos faturamento)
- 1 Pedido → 0..1 NotaFiscal

#### PedidoItem
Item individual de um pedido.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| pedido_id | UUID | FK pedido |
| produto_id | UUID | FK produto |
| sku | string | SKU do produto (snapshot) |
| nome_produto | string | Nome do produto (snapshot) |
| quantidade | integer | Quantidade solicitada |
| preco_unitario | decimal | Preco unitario calculado pelo CIE |
| desconto_item | decimal | Desconto no item |
| preco_final | decimal | Preco final (unitario - desconto) * quantidade |
| backorder | boolean | Item sem estoque (aguardando reposicao) |
| previsao_entrega | date | Previsao de entrega (backorder) |
| regra_preco_ref | string | Referencia da regra CIE aplicada |
| criado_em | timestamp | Data de criacao |

#### Cotacao
Cotacao salva (pre-pedido).

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| numero | string | Numero sequencial (COT-2026-00042) |
| cliente_id | UUID | FK cliente |
| representante_id | UUID | FK representante (se via proxy) |
| status | enum | ativa, expirada, convertida |
| validade | date | Data de validade |
| valor_total | decimal | Valor total da cotacao |
| pedido_id | UUID | FK pedido (se convertida) |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### CotacaoItem
Item individual de uma cotacao.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cotacao_id | UUID | FK cotacao |
| produto_id | UUID | FK produto |
| quantidade | integer | Quantidade |
| preco_unitario | decimal | Preco unitario (snapshot do momento) |
| criado_em | timestamp | Data de criacao |

---

### 3.4 Dominio: Financeiro

#### Titulo
Titulo financeiro (duplicata, boleto). Dados espelhados do ERP/banco.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cliente_id | UUID | FK cliente |
| pedido_id | UUID | FK pedido (vinculo quando existir) |
| nota_fiscal_id | UUID | FK nota fiscal |
| numero_titulo | string | Numero do titulo |
| tipo | enum | duplicata, boleto |
| valor | decimal | Valor do titulo |
| vencimento | date | Data de vencimento |
| status | enum | a_vencer, vencido, pago, cancelado |
| data_pagamento | date | Data em que foi pago |
| nosso_numero | string | Nosso numero (bancario) |
| linha_digitavel | string | Linha digitavel do boleto |
| pix_copia_cola | string | PIX copia e cola |
| boleto_url | string | URL do PDF do boleto (Storage) |
| erp_titulo_id | string | ID no ERP |
| criado_em | timestamp | Data de criacao |
| atualizado_em | timestamp | Ultima sincronizacao |
| ativo | boolean | Exclusao logica |

#### NotaFiscal
Nota fiscal emitida. Dados espelhados do ERP/SEFAZ.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cliente_id | UUID | FK cliente |
| pedido_id | UUID | FK pedido |
| numero_nf | string | Numero da NF |
| serie | string | Serie |
| chave_acesso | string | Chave de acesso NF-e (44 digitos) |
| valor_total | decimal | Valor total da NF |
| data_emissao | date | Data de emissao |
| pdf_url | string | URL do PDF no Storage |
| xml_url | string | URL do XML no Storage |
| status | enum | emitida, cancelada |
| erp_nf_id | string | ID no ERP |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### SolicitacaoCredito
Solicitacao de credito ou aumento de limite.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| cliente_id | UUID | FK cliente |
| tipo | enum | credito_inicial, aumento_limite |
| valor_solicitado | decimal | Valor solicitado |
| valor_aprovado | decimal | Valor aprovado (preenchido na aprovacao) |
| status | enum | em_analise, aprovado, aprovado_parcial, reprovado, pendente_garantia |
| score_bureau | integer | Score do bureau de credito |
| restricoes | text | Restricoes encontradas |
| justificativa | text | Justificativa da decisao |
| analisado_por | UUID | FK usuario que analisou |
| analisado_em | timestamp | Data da analise |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

---

### 3.5 Dominio: Inteligencia (CIE)

#### TabelaPrecos
Tabela de precos com vigencia.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| nome | string | Nome da tabela (ex: "Varejo SP", "Industria Nacional") |
| tipo | enum | base, canal, cliente, campanha, especial |
| vigencia_inicio | date | Inicio da vigencia |
| vigencia_fim | date | Fim da vigencia (null = sem fim) |
| versao | integer | Numero da versao |
| publicada | boolean | Se esta publicada/ativa |
| criada_por | UUID | FK usuario que criou |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### TabelaPrecoItem
Item de uma tabela de precos.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| tabela_preco_id | UUID | FK tabela |
| produto_id | UUID | FK produto |
| preco | decimal | Preco nesta tabela |
| desconto_maximo | decimal | Desconto maximo permitido (%) |
| criado_em | timestamp | Data de criacao |

#### RegraComercial
Regra parametrizada do CIE.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| nome | string | Nome descritivo |
| tipo | enum | precificacao, elegibilidade, aprovacao, recomendacao, restricao, credito |
| condicao | jsonb | Condicao de ativacao (estrutura parametrizada) |
| acao | jsonb | Acao a executar (estrutura parametrizada) |
| prioridade | integer | Ordem de avaliacao |
| vigencia_inicio | date | Inicio da vigencia |
| vigencia_fim | date | Fim da vigencia |
| versao | integer | Versao da regra |
| publicada | boolean | Se esta ativa |
| criada_por | UUID | FK usuario |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### Campanha
Campanha promocional.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| nome | string | Nome da campanha |
| descricao | text | Descricao |
| tipo_desconto | enum | percentual, valor_fixo, preco_especial |
| valor_desconto | decimal | Valor/percentual do desconto |
| vigencia_inicio | date | Inicio |
| vigencia_fim | date | Fim |
| publico_alvo | jsonb | Segmentacao (canal, regiao, segmento) |
| banner_url | string | URL do banner no Storage |
| criada_por | UUID | FK usuario |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### CampanhaProduto
Vinculo campanha-produto.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| campanha_id | UUID | FK campanha |
| produto_id | UUID | FK produto |
| preco_promocional | decimal | Preco promocional (se aplicavel) |
| criado_em | timestamp | Data de criacao |

---

### 3.6 Dominio: Engajamento

#### Pesquisa
Pesquisa/enquete criada pela Boxer.

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| titulo | string | Titulo da pesquisa |
| descricao | text | Descricao/instrucoes |
| vigencia_inicio | date | Inicio |
| vigencia_fim | date | Fim |
| publico_alvo | jsonb | Segmentacao |
| obrigatoria | boolean | Bloqueia acoes ate responder |
| status | enum | rascunho, publicada, encerrada |
| criada_por | UUID | FK usuario |
| criado_em | timestamp | Data de criacao |
| ativo | boolean | Exclusao logica |

#### PesquisaPergunta

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| pesquisa_id | UUID | FK pesquisa |
| texto | text | Texto da pergunta |
| tipo | enum | multipla_escolha, escala, texto_livre |
| opcoes | text[] | Opcoes (para multipla escolha) |
| obrigatoria | boolean | Resposta obrigatoria |
| ordem | integer | Ordem de exibicao |
| criado_em | timestamp | Data de criacao |

#### PesquisaResposta

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| pesquisa_id | UUID | FK pesquisa |
| pergunta_id | UUID | FK pergunta |
| cliente_id | UUID | FK cliente que respondeu |
| resposta | text | Resposta dada |
| criado_em | timestamp | Data da resposta |

#### Notificacao

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| usuario_id | UUID | FK usuario destino |
| tipo | enum | pedido_status, credito_status, promocao, pesquisa, alerta, sistema |
| titulo | string | Titulo curto |
| mensagem | text | Conteudo |
| link | string | URL de acao |
| lida | boolean | Se foi lida |
| criado_em | timestamp | Data de criacao |

---

### 3.7 Dominio: Auditoria

#### LogAlteracoes

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| usuario_id | UUID | FK usuario |
| usuario_email | string | Email (snapshot) |
| tabela_ref | string | Nome da tabela alterada |
| registro_id | string | ID do registro alterado |
| campo | string | Campo alterado |
| valor_anterior | text | Valor antes |
| valor_novo | text | Valor depois |
| acao | enum | insert, update, delete |
| ip_address | string | IP de origem |
| criado_em | timestamp | Data da alteracao |

#### LogAutenticacao

| Atributo | Tipo | Descricao |
|---|---|---|
| id | UUID | Identificador unico |
| usuario_id | UUID | FK usuario (se identificado) |
| email | string | Email tentado |
| evento | enum | login_sucesso, login_falha, logout, refresh, senha_alterada |
| ip_address | string | IP de origem |
| user_agent | string | Browser/dispositivo |
| criado_em | timestamp | Data do evento |

---

## 4. Mapa de Relacionamentos

```
                    ┌─────────────┐
                    │ Representante│
                    └──────┬──────┘
                           │ 1:N (Carteira)
                           ▼
┌──────────┐  1:N   ┌─────────────┐  1:N   ┌──────────┐
│ Endereco ├────────┤   Cliente   ├────────┤  Pedido  │
└──────────┘        └──────┬──────┘        └────┬─────┘
                           │                     │
                    1:N    │              1:N    │
              ┌────────────┼──────────┐         │
              ▼            ▼          ▼         ▼
        ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐
        │ Titulo   │ │ NotaFisc │ │Solicit.│ │PedidoItem│
        └──────────┘ └──────────┘ │Credito │ └────┬─────┘
                                  └────────┘      │ N:1
                                                  ▼
       ┌─────────────┐  1:N   ┌──────────┐  1:N  ┌──────────┐
       │ Categoria   ├────────┤ Produto  ├───────┤ProdFoto  │
       └─────────────┘        └────┬─────┘       └──────────┘
                                   │ 1:N
                              ┌────┴─────┐
                              ▼          ▼
                        ┌──────────┐ ┌───────────┐
                        │ProdDoc   │ │TabelaPreco│
                        └──────────┘ │Item       │
                                     └─────┬─────┘
                                           │ N:1
                                     ┌─────┴─────┐
                                     │TabelaPrecos│
                                     └───────────┘

       ┌──────────┐  1:N   ┌──────────────┐  N:N  ┌──────────┐
       │ Campanha ├────────┤CampanhaProd. ├───────┤ Produto  │
       └──────────┘        └──────────────┘       └──────────┘

       ┌──────────┐  1:N   ┌──────────────┐  1:N  ┌──────────┐
       │ Pesquisa ├────────┤Pesq.Pergunta ├───────┤Pesq.Resp │
       └──────────┘        └──────────────┘       └──────────┘
```

---

## 5. Regras de Negocio por Entidade

### Cliente
- CNPJ deve ser unico e valido
- Status segue fluxo: pre_cadastro → em_analise → ativo
- Limite de credito definido apos analise (J5)
- Limite disponivel = limite_credito - soma(titulos em aberto)
- Inativacao nao deleta — altera status para inativo

### Produto
- SKU e unico (origem ERP)
- Estoque atualizado via conector ERP (polling a cada 30 min)
- Previsao de chegada via conector logistica (polling a cada 6h)
- Preco nunca e fixo no produto — sempre calculado pelo CIE no contexto do cliente

### Pedido
- Pedido so pode ser criado se cliente.status = ativo
- Validacao de credito: valor_total <= cliente.limite_disponivel
- Se item em backorder: pedido aceito, mas com flag backorder=true no item
- Campo pedido_cliente (OC do revendedor) e opcional mas exibido na timeline
- Status atualizado via conector ERP (polling a cada 15 min)
- Modo Proxy: se criado por representante, registra representante_id + origem=proxy_representante

### Titulo
- Dados espelhados do ERP/banco — somente leitura no Boxer Hub
- Segunda via de boleto gerada via conector bancario
- Status atualizado via polling

### CIE (Regras + Precos)
- Hierarquia de resolucao de preco: preco especial > campanha > tabela do cliente > tabela do canal > tabela base
- Toda avaliacao de regra gera log com regra aplicada e resultado
- Regras com vigencia temporal — ativam/desativam automaticamente

### Campanha
- Vigencia temporal com ativacao automatica
- Sinalizacao visual no Portal Cliente: banner, badge "PROMOCAO", preco riscado
- Publico segmentavel (canal, regiao, segmento)

---

## 6. Glossario do Dominio

| Termo | Definicao |
|---|---|
| **Backorder** | Pedido aceito para produto sem estoque, com entrega futura |
| **Carteira** | Conjunto de clientes vinculados a um representante |
| **CIE** | Commercial Intelligence Engine — motor de regras parametrizado |
| **Conector** | Modulo de integracao com sistema externo (interface padronizada) |
| **Modo Proxy** | Representante atua em nome do cliente com registro de auditoria |
| **OC** | Ordem de Compra — numero do pedido interno do revendedor |
| **PDP** | Product Detail Page — pagina completa de detalhe do produto |
| **RLS** | Row Level Security — controle de acesso por linha no banco |
| **SKU** | Stock Keeping Unit — codigo unico do produto |
| **Tabela Base** | Tabela de precos padrao, sem personalizacao |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
