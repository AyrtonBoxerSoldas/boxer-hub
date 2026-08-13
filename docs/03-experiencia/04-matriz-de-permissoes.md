# HUB-DOC-017: Matriz de Permissoes

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

Esta matriz define, para cada recurso e acao do Boxer Hub, quais roles tem acesso e em que condicoes. Ela complementa o Modelo de Seguranca (HUB-DOC-013) com uma visao operacional por tela e funcionalidade.

### Roles

| Role | Codigo | Portal | Persona |
|---|---|---|---|
| Cliente/Revendedor | `dealer` | Portal Cliente | P1 (Carlos), P2 (Marina) |
| Representante | `rep` | Portal Representante | P3 (Roberto) |
| Analista Comercial | `analyst` | Portal ADM Vendas | P4 (Fernanda) |
| Gerente Comercial | `manager` | Portal ADM Vendas | P5 (Marcos) |
| Analista Financeiro | `financial` | Portal Financeiro | P6 (Julia) |
| Administrador | `admin` | Todos | — |

### Legenda

| Simbolo | Significado |
|---|---|
| ✓ | Acesso total |
| ◐ | Acesso parcial (com restricao descrita) |
| P | Apenas via Modo Proxy (em nome do cliente) |
| — | Sem acesso |

---

## 2. Matriz por Dominio

### 2.1 Catalogo

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver catalogo de produtos** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Ver preco personalizado** | ◐ Seus precos | ◐ Precos dos clientes | ✓ | ✓ | — | ✓ |
| **Ver PDP (detalhe do produto)** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Baixar documentos do produto** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Ver estoque disponivel** | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| **Ver previsao de chegada** | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| **Filtrar por promocoes** | ✓ | ✓ | ✓ | ✓ | — | ✓ |

**Implementacao:** Acesso direto via RLS (SELECT em `produtos`, `categorias`). Precos calculados via Edge Function `calcular-preco`.

### 2.2 Pedidos

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Criar pedido** | ✓ | P | — | — | — | ✓ |
| **Criar pedido rapido (SKU)** | ✓ | P | — | — | — | ✓ |
| **Importar pedido via Excel** | ✓ | P | — | — | — | ✓ |
| **Recomprar pedido anterior** | ✓ | P | — | — | — | ✓ |
| **Salvar cotacao** | ✓ | P | — | — | — | ✓ |
| **Converter cotacao em pedido** | ✓ | P | — | — | — | ✓ |
| **Ver meus pedidos** | ◐ Seus | ◐ Dos seus clientes | ✓ | ✓ | — | ✓ |
| **Ver detalhe do pedido** | ◐ Seus | ◐ Dos seus clientes | ✓ | ✓ | — | ✓ |
| **Ver timeline de status** | ◐ Seus | ◐ Dos seus clientes | ✓ | ✓ | — | ✓ |
| **Aprovar pedido** | — | — | ◐ Ate R$ 50k | ◐ Ate R$ 200k | — | ✓ |
| **Rejeitar pedido** | — | — | ✓ | ✓ | — | ✓ |
| **Ver excecoes comerciais** | — | — | ✓ | ✓ | — | ✓ |
| **Cancelar pedido** | — | — | ✓ | ✓ | — | ✓ |

**Implementacao:**
- Criar: Edge Function `criar-pedido` (valida JWT + role + CIE)
- Listar: RLS em `pedidos` (filtro por `cliente_id` ou `carteira`)
- Aprovar: Edge Function `aprovar-pedido` (verifica alcada)

### 2.3 Cadastro

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Pre-cadastro (sem login)** | ✓ | — | — | — | — | — |
| **Submeter cadastro de novo cliente** | ✓ | P | — | — | — | ✓ |
| **Ver fila de cadastros pendentes** | — | — | ✓ | ✓ | — | ✓ |
| **Analisar cadastro** | — | — | ✓ | ✓ | — | ✓ |
| **Aprovar cadastro** | — | — | ✓ | ✓ | — | ✓ |
| **Rejeitar cadastro** | — | — | ✓ | ✓ | — | ✓ |
| **Solicitar complemento** | — | — | ✓ | ✓ | — | ✓ |
| **Ativar cliente no ERP** | — | — | ✓ | — | — | ✓ |
| **Consultar CNPJ (Receita Federal)** | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| **Ver base de clientes** | — | ◐ Sua carteira | ✓ | ✓ | ◐ Visao financeira | ✓ |
| **Editar dados do cliente** | — | — | ✓ | ✓ | — | ✓ |
| **Alterar representante vinculado** | — | — | ✓ | ✓ | — | ✓ |
| **Alterar tabela de precos** | — | — | — | ✓ | — | ✓ |

**Implementacao:**
- Pre-cadastro: pagina publica `/cadastro`
- Submeter: Edge Function `submeter-cadastro`
- Aprovar: Edge Function `aprovar-cadastro`

### 2.4 Credito

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Solicitar credito/aumento** | ✓ | P | — | — | — | ✓ |
| **Upload de documentos** | ✓ | P | — | — | — | ✓ |
| **Ver status da solicitacao** | ◐ Sua | ◐ Dos seus clientes | — | ✓ | ✓ | ✓ |
| **Ver fila de credito pendente** | — | — | — | — | ✓ | ✓ |
| **Consultar bureau (Serasa/Boa Vista)** | — | — | — | ✓ | ✓ | ✓ |
| **Aprovar credito** | — | — | — | ◐ Ate R$ 100k | ◐ Ate R$ 100k | ✓ |
| **Aprovar credito acima de R$ 100k** | — | — | — | — | — | ✓ |
| **Reprovar credito** | — | — | — | ✓ | ✓ | ✓ |
| **Aprovar credito parcial** | — | — | — | ✓ | ✓ | ✓ |
| **Ver historico de credito** | ◐ Seu | ◐ Dos seus clientes | — | ✓ | ✓ | ✓ |

**Implementacao:**
- Solicitar: Edge Function `solicitar-credito`
- Bureau: Edge Function `consultar-bureau`
- Decidir: Edge Function `decidir-credito` (verifica alcada)

### 2.5 Financeiro

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver titulos** | ◐ Seus | ◐ Dos seus clientes | — | — | ✓ | ✓ |
| **Filtrar titulos** | ◐ Seus | ◐ Dos seus clientes | — | — | ✓ | ✓ |
| **Gerar segunda via de boleto** | ◐ Seus | P | — | — | ✓ | ✓ |
| **Gerar PIX** | ◐ Seus | P | — | — | ✓ | ✓ |
| **Ver notas fiscais** | ◐ Suas | ◐ Dos seus clientes | — | — | ✓ | ✓ |
| **Baixar NF (PDF)** | ◐ Suas | ◐ Dos seus clientes | — | — | ✓ | ✓ |
| **Baixar XML** | ◐ Suas | ◐ Dos seus clientes | — | — | ✓ | ✓ |
| **Baixar XMLs em lote** | ◐ Suas | P | — | — | ✓ | ✓ |
| **Ver extrato** | ◐ Seu | P | — | — | ✓ | ✓ |
| **Exportar extrato (CSV)** | ◐ Seu | P | — | — | ✓ | ✓ |
| **Ver limite de credito** | ◐ Seu | ◐ Dos seus clientes | — | — | ✓ | ✓ |
| **Ver visao financeira do cliente** | — | — | — | — | ✓ | ✓ |

**Implementacao:**
- Listar: RLS em `titulos`, `notas_fiscais`
- Segunda via: Edge Function `gerar-segunda-via`
- XML lote: Edge Function `download-xml-lote`

### 2.6 Campanhas e Promocoes

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver campanhas ativas** | ◐ Do seu publico | ◐ Dos seus clientes | ✓ | ✓ | — | ✓ |
| **Ver sinalizacao de promocao** | ✓ | ✓ | ✓ | ✓ | — | ✓ |
| **Criar campanha** | — | — | ✓ | ✓ | — | ✓ |
| **Editar campanha** | — | — | ✓ | ✓ | — | ✓ |
| **Encerrar campanha** | — | — | ✓ | ✓ | — | ✓ |
| **Ver desempenho da campanha** | — | — | ✓ | ✓ | — | ✓ |

**Implementacao:**
- Ver: RLS em `campanhas` (filtro por publico_alvo)
- Criar: Edge Function `criar-campanha`

### 2.7 Pesquisas

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver pesquisas pendentes** | ◐ Do seu publico | — | — | — | — | — |
| **Responder pesquisa** | ✓ | — | — | — | — | — |
| **Criar pesquisa** | — | — | ✓ | ✓ | — | ✓ |
| **Publicar pesquisa** | — | — | ✓ | ✓ | — | ✓ |
| **Encerrar pesquisa** | — | — | ✓ | ✓ | — | ✓ |
| **Ver respostas em tempo real** | — | — | ✓ | ✓ | — | ✓ |
| **Gerar relatorio** | — | — | ✓ | ✓ | — | ✓ |
| **Exportar relatorio (CSV/PDF)** | — | — | ✓ | ✓ | — | ✓ |

**Implementacao:**
- Ver/Responder: RLS em `pesquisas`, Edge Function `responder-pesquisa`
- Criar: Edge Function `criar-pesquisa`
- Relatorio: Edge Function `relatorio-pesquisa`

### 2.8 Representante (Carteira)

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver dashboard da carteira** | — | ✓ | — | — | — | ✓ |
| **Ver lista de clientes** | — | ◐ Sua carteira | ✓ | ✓ | — | ✓ |
| **Ver visao do cliente** | — | ◐ Sua carteira | ✓ | ✓ | — | ✓ |
| **Ativar Modo Proxy** | — | ✓ | — | — | — | — |
| **Criar cotacao para cliente** | — | ✓ | — | — | — | — |
| **Enviar cotacao (WA/email)** | — | ✓ | — | — | — | — |
| **Ver performance pessoal** | — | ✓ | — | — | — | — |
| **Ver ranking de representantes** | — | ◐ Posicao propria | — | ✓ | — | ✓ |
| **Ver comissoes** | — | ✓ | — | ✓ | — | ✓ |

### 2.9 Tabelas de Precos

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver tabelas de precos** | — | — | ✓ | ✓ | — | ✓ |
| **Criar tabela de precos** | — | — | — | ✓ | — | ✓ |
| **Editar tabela de precos** | — | — | — | ✓ | — | ✓ |
| **Publicar tabela** | — | — | — | ✓ | — | ✓ |
| **Vincular cliente a tabela** | — | — | — | ✓ | — | ✓ |
| **Ver historico de versoes** | — | — | ✓ | ✓ | — | ✓ |

### 2.10 Administracao

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Criar usuario** | — | — | — | — | — | ✓ |
| **Alterar role de usuario** | — | — | — | — | — | ✓ |
| **Revogar sessao** | — | — | — | — | — | ✓ |
| **Ver status dos conectores** | — | — | — | — | — | ✓ |
| **Ver fila de integracao** | — | — | — | — | — | ✓ |
| **Ver logs de auditoria** | — | — | — | ✓ | — | ✓ |
| **Ver logs de autenticacao** | — | — | — | — | — | ✓ |
| **Configurar parametros CIE** | — | — | — | — | — | ✓ |
| **Health check** | — | — | — | — | — | ✓ |

### 2.11 Perfil e Geral

| Recurso / Acao | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| **Ver perfil proprio** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Alterar senha** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Configurar notificacoes** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Ver notificacoes** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Marcar notificacao como lida** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Gerenciar enderecos** | ✓ | — | — | — | — | ✓ |

---

## 3. Alcadas de Aprovacao

Valores parametrizaveis via CIE (tabela `regras_cie`).

### 3.1 Pedidos

| Faixa de Valor | analyst | manager | admin |
|---|---|---|---|
| Ate R$ 50.000 | ✓ Aprova | ✓ Aprova | ✓ Aprova |
| R$ 50.001 — R$ 200.000 | — | ✓ Aprova | ✓ Aprova |
| Acima de R$ 200.000 | — | — | ✓ Aprova |

### 3.2 Credito

| Faixa de Valor | manager | financial | admin |
|---|---|---|---|
| Ate R$ 100.000 | ✓ Aprova | ✓ Aprova | ✓ Aprova |
| Acima de R$ 100.000 | — | — | ✓ Aprova |

### 3.3 Cadastro

| Acao | analyst | manager | admin |
|---|---|---|---|
| Aprovar cadastro | ✓ | ✓ | ✓ |
| Ativar no ERP | ✓ | — | ✓ |

---

## 4. Modo Proxy — Permissoes Especificas

Quando o representante ativa o Modo Proxy, ele herda as permissoes do `dealer` no contexto do cliente selecionado, com as seguintes restricoes:

| Acao no Proxy | Permitido | Restricao |
|---|---|---|
| Fazer pedido | ✓ | Precos do cliente (nao do rep) |
| Ver financeiro | ◐ | Ve titulos, NAO ve detalhes de pagamento |
| Gerar segunda via | ✓ | Boleto do cliente |
| Solicitar credito | ✓ | Em nome do cliente |
| Ver catalogo | ✓ | Precos do cliente |
| Alterar dados cadastrais | — | Bloqueado em proxy |
| Alterar senha do cliente | — | Bloqueado |
| Ver outros representantes | — | Apenas sua carteira |

---

## 5. Implementacao Tecnica

### 5.1 Armazenamento do Role

```json
// user_metadata no Supabase Auth
// dealer
{ "role": "dealer", "cliente_id": "uuid" }

// rep
{ "role": "rep", "representante_id": "uuid" }

// analyst, manager, financial, admin
{ "role": "analyst" }
```

### 5.2 Verificacao no Frontend

```javascript
const role = SESSION.user.user_metadata.role;
if (role === 'dealer') {
  // Mostra Portal Cliente
} else if (role === 'rep') {
  // Mostra Portal Representante
}
// ...
```

### 5.3 Verificacao na Edge Function

```typescript
const role = user.user_metadata.role;
if (!['analyst', 'manager', 'admin'].includes(role)) {
  return new Response(JSON.stringify({
    success: false,
    error: { code: 'PERMISSAO_NEGADA', message: 'Role insuficiente' }
  }), { status: 403 });
}
```

### 5.4 Verificacao no Banco (RLS)

```sql
-- Exemplo: dealer ve apenas seus pedidos
create policy "dealer_pedidos" on pedidos
  for select using (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dealer'
    and cliente_id = (auth.jwt() -> 'user_metadata' ->> 'cliente_id')::uuid
  );
```

---

## 6. Regras de Negocio

1. **Principio do menor privilegio:** cada role ve apenas o que precisa para sua funcao
2. **Dupla validacao:** permissoes verificadas no frontend (UX) E no backend (seguranca)
3. **Proxy nao eleva privilegios:** representante em proxy tem acesso igual ou menor que o dealer
4. **Alcadas sao parametrizaveis:** valores de aprovacao configurados via CIE, nao hardcoded
5. **Admin herda tudo:** admin tem acesso a todas as funcionalidades de todos os portais
6. **Segregacao de deveres:** quem solicita credito nao pode aprovar; quem cria pedido com excecao nao pode aprovar a excecao

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
