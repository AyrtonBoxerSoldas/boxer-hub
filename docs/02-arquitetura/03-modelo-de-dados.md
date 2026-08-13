# HUB-DOC-008: Modelo de Dados

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

Modelo de dados fisico do Boxer Hub, implementado no projeto Supabase dedicado `boxer-hubcomercial`. Todas as tabelas ficam no schema `public` com nomenclatura limpa em snake_case portugues (ADR-006).

### Convencoes

- UUIDs como chave primaria (`gen_random_uuid()`)
- `criado_em timestamp default now()` em todas as tabelas
- `ativo boolean default true` para exclusao logica
- RLS ativado em 100% das tabelas
- Indices em colunas de busca frequente
- Constraints de integridade referencial (FK)

---

## 2. DDL — Cadastro

```sql
-- Clientes (revendedores)
create table clientes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id),
  cnpj varchar(18) unique not null,
  razao_social varchar(200) not null,
  nome_fantasia varchar(200),
  inscricao_estadual varchar(20),
  segmento varchar(50),
  canal varchar(50),
  porte varchar(20) check (porte in ('pequeno','medio','grande')),
  email_principal varchar(200),
  telefone varchar(20),
  status_cadastro varchar(20) default 'pre_cadastro'
    check (status_cadastro in ('pre_cadastro','em_analise','ativo','suspenso','inativo')),
  limite_credito numeric(12,2) default 0,
  limite_disponivel numeric(12,2) default 0,
  tabela_preco_id uuid,
  representante_id uuid,
  criado_em timestamp default now(),
  atualizado_em timestamp default now(),
  ativo boolean default true
);

create index idx_clientes_cnpj on clientes(cnpj);
create index idx_clientes_representante on clientes(representante_id);
create index idx_clientes_status on clientes(status_cadastro);

-- Representantes comerciais
create table representantes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id),
  nome varchar(200) not null,
  email varchar(200) unique not null,
  telefone varchar(20),
  regiao varchar(100),
  meta_mensal numeric(12,2) default 0,
  comissao_percentual numeric(5,2) default 0,
  status varchar(20) default 'ativo' check (status in ('ativo','inativo')),
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Carteira (vinculo representante-cliente)
create table carteira (
  id uuid default gen_random_uuid() primary key,
  representante_id uuid not null references representantes(id),
  cliente_id uuid not null references clientes(id),
  data_vinculo date default current_date,
  criado_em timestamp default now(),
  ativo boolean default true,
  unique (representante_id, cliente_id)
);

create index idx_carteira_rep on carteira(representante_id);
create index idx_carteira_cliente on carteira(cliente_id);

-- Enderecos
create table enderecos (
  id uuid default gen_random_uuid() primary key,
  cliente_id uuid not null references clientes(id),
  tipo varchar(20) default 'entrega' check (tipo in ('principal','entrega','cobranca')),
  cep varchar(10),
  logradouro varchar(200),
  numero varchar(20),
  complemento varchar(100),
  bairro varchar(100),
  cidade varchar(100),
  uf char(2),
  referencia varchar(200),
  padrao boolean default false,
  criado_em timestamp default now(),
  ativo boolean default true
);

create index idx_enderecos_cliente on enderecos(cliente_id);

-- Documentos cadastrais (uploads)
create table documentos_cadastrais (
  id uuid default gen_random_uuid() primary key,
  cliente_id uuid not null references clientes(id),
  tipo varchar(30) check (tipo in ('contrato_social','procuracao','comprovante_endereco','balanco','dre','outro')),
  nome_arquivo varchar(200),
  storage_path text not null,
  criado_em timestamp default now()
);
```

---

## 3. DDL — Catalogo

```sql
-- Categorias de produtos
create table categorias (
  id uuid default gen_random_uuid() primary key,
  nome varchar(100) not null,
  slug varchar(100) unique,
  categoria_pai_id uuid references categorias(id),
  icone varchar(50),
  ordem integer default 0,
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Produtos
create table produtos (
  id uuid default gen_random_uuid() primary key,
  sku varchar(50) unique not null,
  nome varchar(200) not null,
  descricao text,
  ncm varchar(10),
  categoria_id uuid references categorias(id),
  unidade varchar(10) default 'un',
  peso_bruto numeric(8,3),
  estoque_disponivel integer default 0,
  estoque_minimo integer default 0,
  previsao_chegada date,
  ficha_tecnica jsonb,
  o_que_acompanha text[],
  ordem_exibicao integer default 0,
  destaque boolean default false,
  criado_em timestamp default now(),
  atualizado_em timestamp default now(),
  ativo boolean default true
);

create index idx_produtos_sku on produtos(sku);
create index idx_produtos_categoria on produtos(categoria_id);
create index idx_produtos_nome on produtos using gin(to_tsvector('portuguese', nome));

-- Fotos do produto
create table produto_fotos (
  id uuid default gen_random_uuid() primary key,
  produto_id uuid not null references produtos(id) on delete cascade,
  storage_path text not null,
  alt_text varchar(200),
  ordem integer default 0,
  criado_em timestamp default now()
);

create index idx_produto_fotos_produto on produto_fotos(produto_id);

-- Documentos do produto (ficha tecnica, FISPQ, certificado, manual)
create table produto_documentos (
  id uuid default gen_random_uuid() primary key,
  produto_id uuid not null references produtos(id) on delete cascade,
  tipo varchar(20) check (tipo in ('ficha_tecnica','certificado','fispq','manual','catalogo')),
  nome varchar(200),
  storage_path text not null,
  criado_em timestamp default now()
);

create index idx_produto_docs_produto on produto_documentos(produto_id);
```

---

## 4. DDL — Comercial

```sql
-- Pedidos
create table pedidos (
  id uuid default gen_random_uuid() primary key,
  numero varchar(20) unique not null,
  cliente_id uuid not null references clientes(id),
  representante_id uuid references representantes(id),
  pedido_cliente varchar(50),
  status varchar(20) default 'rascunho'
    check (status in ('rascunho','enviado','em_analise','aprovado','rejeitado',
                       'faturado','expedido','em_transito','entregue','cancelado')),
  condicao_pagamento varchar(100),
  observacoes text,
  subtotal numeric(12,2) default 0,
  desconto_total numeric(12,2) default 0,
  valor_total numeric(12,2) default 0,
  tabela_preco_ref varchar(100),
  erp_pedido_id varchar(50),
  origem varchar(30) default 'portal_cliente'
    check (origem in ('portal_cliente','proxy_representante','importacao_excel','recompra')),
  endereco_entrega_id uuid references enderecos(id),
  aprovado_por uuid references auth.users(id),
  aprovado_em timestamp,
  faturado_em timestamp,
  entregue_em timestamp,
  criado_em timestamp default now(),
  ativo boolean default true
);

create index idx_pedidos_cliente on pedidos(cliente_id);
create index idx_pedidos_representante on pedidos(representante_id);
create index idx_pedidos_status on pedidos(status);
create index idx_pedidos_numero on pedidos(numero);
create index idx_pedidos_pedido_cliente on pedidos(pedido_cliente);

-- Itens do pedido
create table pedido_itens (
  id uuid default gen_random_uuid() primary key,
  pedido_id uuid not null references pedidos(id) on delete cascade,
  produto_id uuid not null references produtos(id),
  sku varchar(50),
  nome_produto varchar(200),
  quantidade integer not null check (quantidade > 0),
  preco_unitario numeric(12,2) not null,
  desconto_item numeric(12,2) default 0,
  preco_final numeric(12,2) not null,
  backorder boolean default false,
  previsao_entrega date,
  regra_preco_ref varchar(100),
  criado_em timestamp default now()
);

create index idx_pedido_itens_pedido on pedido_itens(pedido_id);

-- Cotacoes
create table cotacoes (
  id uuid default gen_random_uuid() primary key,
  numero varchar(20) unique not null,
  cliente_id uuid not null references clientes(id),
  representante_id uuid references representantes(id),
  status varchar(20) default 'ativa' check (status in ('ativa','expirada','convertida')),
  validade date,
  valor_total numeric(12,2) default 0,
  pedido_id uuid references pedidos(id),
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Itens da cotacao
create table cotacao_itens (
  id uuid default gen_random_uuid() primary key,
  cotacao_id uuid not null references cotacoes(id) on delete cascade,
  produto_id uuid not null references produtos(id),
  quantidade integer not null check (quantidade > 0),
  preco_unitario numeric(12,2) not null,
  criado_em timestamp default now()
);
```

---

## 5. DDL — Financeiro

```sql
-- Titulos financeiros (duplicatas, boletos)
create table titulos (
  id uuid default gen_random_uuid() primary key,
  cliente_id uuid not null references clientes(id),
  pedido_id uuid references pedidos(id),
  nota_fiscal_id uuid,
  numero_titulo varchar(50),
  tipo varchar(20) check (tipo in ('duplicata','boleto')),
  valor numeric(12,2) not null,
  vencimento date not null,
  status varchar(20) default 'a_vencer' check (status in ('a_vencer','vencido','pago','cancelado')),
  data_pagamento date,
  nosso_numero varchar(50),
  linha_digitavel varchar(60),
  pix_copia_cola text,
  boleto_url text,
  erp_titulo_id varchar(50),
  criado_em timestamp default now(),
  atualizado_em timestamp default now(),
  ativo boolean default true
);

create index idx_titulos_cliente on titulos(cliente_id);
create index idx_titulos_vencimento on titulos(vencimento);
create index idx_titulos_status on titulos(status);

-- Notas fiscais
create table notas_fiscais (
  id uuid default gen_random_uuid() primary key,
  cliente_id uuid not null references clientes(id),
  pedido_id uuid references pedidos(id),
  numero_nf varchar(20),
  serie varchar(5),
  chave_acesso varchar(44),
  valor_total numeric(12,2),
  data_emissao date,
  pdf_url text,
  xml_url text,
  status varchar(20) default 'emitida' check (status in ('emitida','cancelada')),
  erp_nf_id varchar(50),
  criado_em timestamp default now(),
  ativo boolean default true
);

create index idx_nf_cliente on notas_fiscais(cliente_id);
create index idx_nf_chave on notas_fiscais(chave_acesso);

-- FK circular titulos → notas_fiscais
alter table titulos add constraint fk_titulo_nf
  foreign key (nota_fiscal_id) references notas_fiscais(id);

-- Solicitacoes de credito
create table solicitacoes_credito (
  id uuid default gen_random_uuid() primary key,
  cliente_id uuid not null references clientes(id),
  tipo varchar(20) check (tipo in ('credito_inicial','aumento_limite')),
  valor_solicitado numeric(12,2) not null,
  valor_aprovado numeric(12,2),
  status varchar(30) default 'em_analise'
    check (status in ('em_analise','aprovado','aprovado_parcial','reprovado','pendente_garantia')),
  score_bureau integer,
  restricoes text,
  justificativa text,
  analisado_por uuid references auth.users(id),
  analisado_em timestamp,
  criado_em timestamp default now(),
  ativo boolean default true
);

create index idx_solic_credito_cliente on solicitacoes_credito(cliente_id);
```

---

## 6. DDL — Inteligencia (CIE)

```sql
-- Tabelas de precos
create table tabela_precos (
  id uuid default gen_random_uuid() primary key,
  nome varchar(100) not null,
  tipo varchar(20) check (tipo in ('base','canal','cliente','campanha','especial')),
  vigencia_inicio date,
  vigencia_fim date,
  versao integer default 1,
  publicada boolean default false,
  criada_por uuid references auth.users(id),
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Itens da tabela de precos
create table tabela_preco_itens (
  id uuid default gen_random_uuid() primary key,
  tabela_preco_id uuid not null references tabela_precos(id) on delete cascade,
  produto_id uuid not null references produtos(id),
  preco numeric(12,2) not null,
  desconto_maximo numeric(5,2) default 0,
  criado_em timestamp default now(),
  unique (tabela_preco_id, produto_id)
);

create index idx_tpi_tabela on tabela_preco_itens(tabela_preco_id);
create index idx_tpi_produto on tabela_preco_itens(produto_id);

-- Regras comerciais (CIE)
create table regras_comerciais (
  id uuid default gen_random_uuid() primary key,
  nome varchar(200) not null,
  tipo varchar(20) check (tipo in ('precificacao','elegibilidade','aprovacao','recomendacao','restricao','credito')),
  condicao jsonb not null,
  acao jsonb not null,
  prioridade integer default 0,
  vigencia_inicio date,
  vigencia_fim date,
  versao integer default 1,
  publicada boolean default false,
  criada_por uuid references auth.users(id),
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Campanhas promocionais
create table campanhas (
  id uuid default gen_random_uuid() primary key,
  nome varchar(200) not null,
  descricao text,
  tipo_desconto varchar(20) check (tipo_desconto in ('percentual','valor_fixo','preco_especial')),
  valor_desconto numeric(12,2),
  vigencia_inicio date not null,
  vigencia_fim date not null,
  publico_alvo jsonb,
  banner_url text,
  criada_por uuid references auth.users(id),
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Vinculo campanha-produto
create table campanha_produtos (
  id uuid default gen_random_uuid() primary key,
  campanha_id uuid not null references campanhas(id) on delete cascade,
  produto_id uuid not null references produtos(id),
  preco_promocional numeric(12,2),
  criado_em timestamp default now(),
  unique (campanha_id, produto_id)
);
```

---

## 7. DDL — Engajamento

```sql
-- Pesquisas
create table pesquisas (
  id uuid default gen_random_uuid() primary key,
  titulo varchar(200) not null,
  descricao text,
  vigencia_inicio date,
  vigencia_fim date,
  publico_alvo jsonb,
  obrigatoria boolean default false,
  status varchar(20) default 'rascunho' check (status in ('rascunho','publicada','encerrada')),
  criada_por uuid references auth.users(id),
  criado_em timestamp default now(),
  ativo boolean default true
);

-- Perguntas
create table pesquisa_perguntas (
  id uuid default gen_random_uuid() primary key,
  pesquisa_id uuid not null references pesquisas(id) on delete cascade,
  texto text not null,
  tipo varchar(20) check (tipo in ('multipla_escolha','escala','texto_livre')),
  opcoes text[],
  obrigatoria boolean default true,
  ordem integer default 0,
  criado_em timestamp default now()
);

-- Respostas
create table pesquisa_respostas (
  id uuid default gen_random_uuid() primary key,
  pesquisa_id uuid not null references pesquisas(id),
  pergunta_id uuid not null references pesquisa_perguntas(id),
  cliente_id uuid not null references clientes(id),
  resposta text,
  criado_em timestamp default now(),
  unique (pergunta_id, cliente_id)
);

-- Notificacoes
create table notificacoes (
  id uuid default gen_random_uuid() primary key,
  usuario_id uuid not null references auth.users(id),
  tipo varchar(30) check (tipo in ('pedido_status','credito_status','promocao','pesquisa','alerta','sistema')),
  titulo varchar(200),
  mensagem text,
  link text,
  lida boolean default false,
  criado_em timestamp default now()
);

create index idx_notif_usuario on notificacoes(usuario_id);
create index idx_notif_lida on notificacoes(usuario_id, lida);
```

---

## 8. DDL — Auditoria

```sql
-- Log de alteracoes
create table log_alteracoes (
  id uuid default gen_random_uuid() primary key,
  usuario_id uuid,
  usuario_email text,
  tabela_ref text,
  registro_id text,
  campo text,
  valor_anterior text,
  valor_novo text,
  acao varchar(10) check (acao in ('insert','update','delete')),
  ip_address varchar(45),
  criado_em timestamp default now()
);

create index idx_log_alt_tabela on log_alteracoes(tabela_ref);
create index idx_log_alt_registro on log_alteracoes(registro_id);
create index idx_log_alt_data on log_alteracoes(criado_em);

-- Log de autenticacao
create table log_autenticacao (
  id uuid default gen_random_uuid() primary key,
  usuario_id uuid,
  email text,
  evento varchar(20) check (evento in ('login_sucesso','login_falha','logout','refresh','senha_alterada')),
  ip_address varchar(45),
  user_agent text,
  criado_em timestamp default now()
);

create index idx_log_auth_email on log_autenticacao(email);
create index idx_log_auth_data on log_autenticacao(criado_em);
```

---

## 9. FK do Cliente (referencias circulares)

```sql
alter table clientes add constraint fk_cliente_tabela_preco
  foreign key (tabela_preco_id) references tabela_precos(id);

alter table clientes add constraint fk_cliente_representante
  foreign key (representante_id) references representantes(id);
```

---

## 10. Resumo de Tabelas

| # | Tabela | Dominio | Registros estimados |
|---|---|---|---|
| 1 | clientes | Cadastro | 2.000 - 5.000 |
| 2 | representantes | Cadastro | 30 - 100 |
| 3 | carteira | Cadastro | 2.000 - 5.000 |
| 4 | enderecos | Cadastro | 3.000 - 10.000 |
| 5 | documentos_cadastrais | Cadastro | 5.000 - 15.000 |
| 6 | categorias | Catalogo | 20 - 50 |
| 7 | produtos | Catalogo | 500 - 2.000 |
| 8 | produto_fotos | Catalogo | 2.000 - 10.000 |
| 9 | produto_documentos | Catalogo | 1.000 - 5.000 |
| 10 | pedidos | Comercial | 50.000+ /ano |
| 11 | pedido_itens | Comercial | 200.000+ /ano |
| 12 | cotacoes | Comercial | 10.000+ /ano |
| 13 | cotacao_itens | Comercial | 30.000+ /ano |
| 14 | titulos | Financeiro | 100.000+ /ano |
| 15 | notas_fiscais | Financeiro | 50.000+ /ano |
| 16 | solicitacoes_credito | Financeiro | 500 - 2.000 /ano |
| 17 | tabela_precos | Inteligencia | 10 - 50 |
| 18 | tabela_preco_itens | Inteligencia | 5.000 - 100.000 |
| 19 | regras_comerciais | Inteligencia | 50 - 500 |
| 20 | campanhas | Inteligencia | 20 - 100 /ano |
| 21 | campanha_produtos | Inteligencia | 200 - 2.000 /ano |
| 22 | pesquisas | Engajamento | 10 - 50 /ano |
| 23 | pesquisa_perguntas | Engajamento | 50 - 250 /ano |
| 24 | pesquisa_respostas | Engajamento | 5.000 - 25.000 /ano |
| 25 | notificacoes | Engajamento | 100.000+ /ano |
| 26 | log_alteracoes | Auditoria | 500.000+ /ano |
| 27 | log_autenticacao | Auditoria | 200.000+ /ano |

**Total: 27 tabelas**

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
