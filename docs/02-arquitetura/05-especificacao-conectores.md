# HUB-DOC-010: Especificacao dos Conectores

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Formato de Especificacao

Cada conector e documentado com: interface (operacoes), dados de entrada/saida, direcao do fluxo, frequencia, autenticacao e fallback.

---

## 2. C01 — ERP Connector (ZEN)

**Prioridade:** Critica — MVP
**Direcao:** Bidirecional
**Sistema:** ERP ZEN (API REST)

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `getProducts()` | ERP → Hub | Poll | 30 min |
| `getStock()` | ERP → Hub | Poll | 30 min |
| `getOrderStatus(orderId)` | ERP → Hub | Poll | 15 min |
| `submitOrder(order)` | Hub → ERP | Push | Tempo real |
| `getInvoices(clientId)` | ERP → Hub | Poll | 15 min |
| `getFinancialTitles(clientId)` | ERP → Hub | Poll | 1 hora |
| `createClient(client)` | Hub → ERP | Push | Tempo real |
| `updateCreditLimit(clientId, limit)` | Hub → ERP | Push | Tempo real |

### Dados de Entrada/Saida

**`getProducts()` → Produto[]**
```
Entrada: { lastSync: timestamp }
Saida: [{
  sku, nome, descricao, ncm, categoria,
  unidade, peso_bruto, ativo
}]
Transform: ERP.codigo → Hub.sku, ERP.descricao_completa → Hub.descricao
Cache: 30 min TTL
```

**`submitOrder(order)` → OrderConfirmation**
```
Entrada: {
  cliente_erp_id, itens: [{ sku, qtd, preco_unitario }],
  condicao_pagamento, endereco_entrega, observacoes
}
Saida: { erp_pedido_id, status, mensagem }
Transform: Hub.pedido → formato ZEN
Cache: Sem cache (operacao de escrita)
Retry: 3 tentativas, backoff exponencial (1s, 3s, 9s)
```

### Autenticacao
- API key do ZEN armazenada no Supabase Vault
- Headers: `Authorization: Bearer {zen_api_key}`

### Fallback
- Leitura: retorna dados do cache local
- Escrita: enfileira para retry (tabela `fila_integracao`)

---

## 3. C02 — Credit Connector (Serasa / Boa Vista)

**Prioridade:** Alta — MVP
**Direcao:** Hub ← Bureau
**Sistema:** Serasa Experian API / Boa Vista SCPC API

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `consultarScore(cnpj)` | Hub ← Bureau | Push (on-demand) | Sob solicitacao |
| `consultarRestricoes(cnpj)` | Hub ← Bureau | Push (on-demand) | Sob solicitacao |

### Dados de Entrada/Saida

**`consultarScore(cnpj)` → CreditReport**
```
Entrada: { cnpj: string, tipo_consulta: 'basica' | 'completa' }
Saida: {
  score: number (0-1000),
  classificacao: string,
  restricoes: [{ tipo, valor, data, credor }],
  protestos: number,
  pendencias: number,
  data_consulta: timestamp
}
Cache: 24 horas (mesma consulta nao repete no mesmo dia)
```

### Autenticacao
- API key + secret por contrato com Serasa/Boa Vista
- Armazenados no Supabase Vault

### Fallback
- Se bureau indisponivel: bloqueia aprovacao automatica, exige analise manual
- Log: registra tentativa falha para auditoria

---

## 4. C03 — Bank Connector (Boletos / PIX)

**Prioridade:** Alta — MVP
**Direcao:** Hub ← Banco
**Sistema:** API bancaria (banco a definir)

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `syncTitulos(clientId)` | Banco → Hub | Poll | 1 hora |
| `gerarSegundaVia(tituloId)` | Hub → Banco | Push | On-demand |
| `gerarPix(tituloId)` | Hub → Banco | Push | On-demand |
| `confirmarPagamento(nossoNumero)` | Banco → Hub | Webhook/Poll | Tempo real / 1h |

### Dados de Entrada/Saida

**`gerarSegundaVia(tituloId)` → BoletoData**
```
Entrada: { nosso_numero, valor, vencimento }
Saida: {
  linha_digitavel, codigo_barras,
  pdf_base64, pix_copia_cola,
  novo_vencimento
}
Cache: Sem cache (documento gerado sob demanda)
```

### Autenticacao
- Certificado digital + OAuth2 (padrao bancario)
- Certificado armazenado no Supabase Vault

### Fallback
- "Segunda via de boleto temporariamente indisponivel. Tente novamente em alguns minutos."

---

## 5. C04 — Fiscal Connector (NF/XML)

**Prioridade:** Alta — MVP
**Direcao:** Hub ← ERP/SEFAZ
**Sistema:** ERP ZEN (NF-e) / SEFAZ

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `syncNotasFiscais(clientId)` | ERP → Hub | Poll | 15 min |
| `downloadPDF(chaveAcesso)` | ERP/SEFAZ → Hub | On-demand | Sob solicitacao |
| `downloadXML(chaveAcesso)` | ERP/SEFAZ → Hub | On-demand | Sob solicitacao |
| `downloadXMLLote(chaves[])` | ERP/SEFAZ → Hub | On-demand | Sob solicitacao |

### Dados de Entrada/Saida

**`syncNotasFiscais(clientId)` → NotaFiscal[]**
```
Saida: [{
  numero_nf, serie, chave_acesso,
  valor_total, data_emissao, status,
  pedido_erp_id
}]
Transform: Vincular NF ao pedido via erp_pedido_id
Cache: PDFs e XMLs armazenados no Supabase Storage (imutaveis)
```

### Autenticacao
- Mesma autenticacao do C01 (ERP ZEN) para NFs originadas do ERP
- Certificado digital A1 para consulta direta na SEFAZ (se necessario)

### Fallback
- NFs ja sincronizadas permanecem disponiveis (Storage)
- Novas NFs aparecem na proxima sincronizacao bem-sucedida

---

## 6. C05 — Logistics Connector (Transportadoras)

**Prioridade:** Media — Expansao
**Direcao:** Hub ← Transportadora
**Sistemas:** APIs de transportadoras (variavel conforme contrato)

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `rastrear(codigoRastreio)` | Transp → Hub | Poll | 2 horas |
| `calcularFrete(origem, destino, peso)` | Transp → Hub | Push | On-demand |

### Dados de Entrada/Saida

**`rastrear(codigoRastreio)` → TrackingInfo**
```
Saida: {
  codigo_rastreio, transportadora,
  status: 'coletado' | 'em_transito' | 'saiu_entrega' | 'entregue',
  historico: [{ data, local, descricao }],
  previsao_entrega: date
}
Cache: 2 horas TTL
```

### Fallback
- "Rastreamento indisponivel. Ultima atualizacao em DD/MM HH:MM"

---

## 7. C06 — Communication Connector (Email / WhatsApp / Push)

**Prioridade:** Alta — MVP
**Direcao:** Hub → Destino
**Sistemas:** Microsoft Graph (email), WhatsApp Business API, Web Push

### Operacoes

| Operacao | Direcao | Canal | Frequencia |
|---|---|---|---|
| `enviarEmail(dest, assunto, corpo)` | Hub → Email | Email | Evento |
| `enviarWhatsApp(telefone, template, dados)` | Hub → WA | WhatsApp | Evento |
| `enviarPush(userId, titulo, msg)` | Hub → Browser | Push | Evento |

### Templates de Notificacao

| Evento | Email | WhatsApp | Push |
|---|---|---|---|
| Pedido confirmado | Sim | Sim | Sim |
| Status atualizado | Nao | Sim | Sim |
| NF disponivel | Sim | Sim | Sim |
| Credito aprovado | Sim | Sim | Sim |
| Boleto proximo do vencimento | Sim | Sim | Nao |
| Nova pesquisa disponivel | Sim | Nao | Sim |
| Promocao ativa | Sim | Sim | Sim |
| Boas-vindas | Sim | Nao | Nao |

### Autenticacao
- Microsoft Graph: MSAL token (OAuth2)
- WhatsApp Business: API key
- Push: VAPID keys (Web Push Protocol)

### Fallback
- Fila de retry (3 tentativas com backoff)
- Se todos os canais falharem: registra no log para envio manual

---

## 8. C07 — Federal Revenue Connector (Receita Federal)

**Prioridade:** Alta — MVP
**Direcao:** Hub ← Receita Federal
**Sistema:** API de consulta CNPJ (BrasilAPI ou similar)

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `consultarCNPJ(cnpj)` | RF → Hub | Push | On-demand |

### Dados de Entrada/Saida

```
Entrada: { cnpj: string }
Saida: {
  razao_social, nome_fantasia,
  situacao_cadastral, data_abertura,
  natureza_juridica, atividade_principal,
  endereco: { logradouro, numero, bairro, cidade, uf, cep },
  telefone, email
}
Cache: 30 dias (dados cadastrais mudam raramente)
```

### Autenticacao
- BrasilAPI: sem autenticacao (rate limit publico)
- Alternativa paga: ReceitaWS (API key)

### Fallback
- Se indisponivel: permite preenchimento manual

---

## 9. C08 — Commercial Policy Connector

**Prioridade:** Media — Expansao
**Direcao:** Hub ← boxer-politica-comercial.pages.dev
**Sistema:** Sistema de politica comercial existente

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `getRegrasVigentes()` | Site → Hub | Poll | 1 hora |
| `getHistoricoRegras()` | Site → Hub | On-demand | Sob solicitacao |

### Integracao
- O sistema boxer-politica-comercial ja esta em producao
- CIE consome regras publicadas via API/export do sistema existente
- Portal ADM exibe o sistema via iframe ou link direto (J7)

---

## 10. C09 — Logistics Dashboard Connector

**Prioridade:** Media — Expansao
**Direcao:** Hub ← boxer-dashboard-logistica
**Sistema:** Dashboard de logistica existente

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `getPrevisaoChegada(sku)` | Dashboard → Hub | Poll | 6 horas |
| `getImportacoesEmAndamento()` | Dashboard → Hub | Poll | 6 horas |

### Dados de Entrada/Saida

```
Saida: {
  sku, previsao_chegada: date,
  quantidade_esperada: number,
  origem: string, status_importacao: string
}
Transform: Atualiza campo previsao_chegada na tabela produtos
```

---

## 11. C10 — AI Connector (Futuro)

**Prioridade:** Baixa — Fase IA
**Direcao:** Bidirecional
**Sistema:** A definir (OpenAI, Anthropic, modelo proprio)

### Interface Preparada (ADR-007)

| Operacao | Descricao |
|---|---|
| `recomendarProdutos(clienteId, contexto)` | Lista ranqueada de sugestoes |
| `classificarTexto(texto, categorias)` | Classificacao automatica |
| `assistente(mensagem, historico)` | Resposta conversacional |
| `preverChurn(clienteId)` | Score de risco de churn |

Na fase inicial, retorna respostas baseadas em regras do CIE. Troca por IA e transparente.

---

## 12. C11 — Static Data Connector (Bases Estaticas)

**Prioridade:** Alta — MVP
**Direcao:** Hub ← Arquivos
**Fontes:** Excel/XLSX, CSV, planilhas em SharePoint ou uploads manuais

### Contexto

Nem todos os dados necessarios para o Boxer Hub estao disponiveis via APIs do ERP ZEN. Dados complementares — como especificacoes tecnicas detalhadas, tabelas de compatibilidade, dados de segmentacao de clientes, historicos de importacao — residem em planilhas Excel e bases estaticas mantidas por diferentes departamentos. Este conector padroniza a ingestao dessas fontes.

### Operacoes

| Operacao | Direcao | Metodo | Frequencia |
|---|---|---|---|
| `importarPlanilha(arquivo, mapeamento)` | Arquivo → Hub | Upload / agendado | Sob demanda ou agendado |
| `syncSharePoint(caminho, mapeamento)` | SharePoint → Hub | Poll | Diario |
| `validarDados(dados, regras)` | Interno | Processamento | A cada importacao |

### Dados de Entrada/Saida

**`importarPlanilha(arquivo, mapeamento)` → ImportResult**
```
Entrada: {
  arquivo: File (xlsx, csv),
  mapeamento: {
    colunas: { coluna_origem: campo_destino },
    tabela_destino: string,
    chave_unica: string,
    modo: 'upsert' | 'replace' | 'append'
  }
}
Saida: {
  total_linhas: number,
  importadas: number,
  erros: [{ linha, campo, motivo }],
  ignoradas: number
}
Transform: Aplica mapeamento de colunas e validacao de tipos
Cache: Sem cache (operacao de escrita)
```

### Tipos de Dados Suportados

| Tipo de base | Exemplo | Frequencia de atualizacao |
|---|---|---|
| Especificacoes de produto | Fichas tecnicas detalhadas | Quando fabricante atualiza |
| Tabelas de compatibilidade | Quais eletrodos servem para quais materiais | Trimestral |
| Segmentacao de clientes | Classificacao por canal, porte, regiao | Mensal |
| Historico de importacao | Dados de logistica que complementam C09 | Diario |
| Dados complementares ERP | Campos que o ZEN nao expoe via API | Sob demanda |

### Fluxo de Importacao

```
1. Admin faz upload de planilha no Portal ADM
   (ou agendamento busca arquivo no SharePoint)
2. Edge Function recebe arquivo
3. Valida formato (xlsx/csv), tamanho (<10MB), colunas obrigatorias
4. Aplica mapeamento de colunas (configurado previamente)
5. Valida dados (tipos, ranges, chaves unicas)
6. Upsert na tabela destino (Supabase)
7. Gera relatorio de importacao (sucessos, erros, ignorados)
8. Registra no log de alteracoes
```

### Autenticacao
- Upload manual: usuario autenticado com role `analyst`, `manager` ou `admin`
- SharePoint: Microsoft Graph API (mesmo token usado pelo C06)
- Credenciais no Supabase Vault

### Fallback
- Erros de parsing: relatorio detalhado com linha e campo que falhou
- Arquivo corrompido: rejeita inteiro, notifica admin
- SharePoint indisponivel: retry na proxima execucao agendada

---

## 13. Tabela de Suporte — Fila de Integracao

Para operacoes que falham e precisam de retry:

```sql
create table fila_integracao (
  id uuid default gen_random_uuid() primary key,
  conector varchar(10) not null,
  operacao varchar(50) not null,
  payload jsonb not null,
  tentativas integer default 0,
  max_tentativas integer default 3,
  status varchar(20) default 'pendente'
    check (status in ('pendente','processando','concluido','falha_definitiva')),
  erro_ultimo text,
  proxima_tentativa timestamp,
  criado_em timestamp default now(),
  processado_em timestamp
);

create index idx_fila_status on fila_integracao(status, proxima_tentativa);
```

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
