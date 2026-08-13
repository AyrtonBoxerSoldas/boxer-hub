# HUB-DOC-013: Modelo de Seguranca

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Visao Geral

O modelo de seguranca do Boxer Hub implementa **defesa em profundidade** com 6 camadas (ADR-008). Cada camada funciona independentemente — se uma falhar, as outras continuam protegendo o sistema.

```
┌─────────────────────────────────────────────┐
│  Camada 1: Autenticacao (Supabase Auth)     │
├─────────────────────────────────────────────┤
│  Camada 2: Autorizacao (Roles + RLS)        │
├─────────────────────────────────────────────┤
│  Camada 3: Validacao (Edge Functions)       │
├─────────────────────────────────────────────┤
│  Camada 4: Transporte (HTTPS + Headers)     │
├─────────────────────────────────────────────┤
│  Camada 5: Dados (Vault + Encriptacao)      │
├─────────────────────────────────────────────┤
│  Camada 6: Auditoria (Logs imutaveis)       │
└─────────────────────────────────────────────┘
```

---

## 2. Camada 1 — Autenticacao

### 2.1 Provedor

**Supabase Auth** com email + senha. Sem login social (Google, Microsoft) na fase inicial.

### 2.2 Fluxo de Login

```
1. Usuario envia email + senha
2. Supabase Auth valida credenciais
3. Retorna par de tokens:
   - access_token (JWT, expira em 1 hora)
   - refresh_token (expira em 7 dias)
4. Frontend armazena tokens em memoria (nao localStorage)
5. Toda requisicao envia access_token no header Authorization
6. Antes de expirar: refresh automatico via refresh_token
```

### 2.3 Gestao de Usuarios

| Acao | Responsavel | Como |
|---|---|---|
| Criar usuario | Admin | Edge Function `criar-usuario` ou painel Supabase |
| Redefinir senha | Usuario (self-service) | Supabase Auth "Reset Password" (email) |
| Bloquear usuario | Admin | Desativa no Supabase Auth |
| Revogar sessao | Admin | Edge Function `revogar-sessao` |

### 2.4 Politica de Senhas

| Regra | Valor |
|---|---|
| Tamanho minimo | 8 caracteres |
| Complexidade | Pelo menos 1 maiuscula, 1 numero |
| Historico | Nao reutilizar ultimas 3 senhas |
| Tentativas falhas | Bloqueia apos 5 tentativas (15 min) |
| Expiracao | 90 dias (configuravel) |

### 2.5 Sessoes

| Parametro | Valor |
|---|---|
| Duracao do access_token | 1 hora |
| Duracao do refresh_token | 7 dias |
| Refresh automatico | Sim (antes dos ultimos 5 min) |
| Multiplas sessoes | Permitido (maximo 3 dispositivos) |
| Inatividade | Logout apos 30 min sem acao |

---

## 3. Camada 2 — Autorizacao

### 3.1 Roles (Perfis)

| Role | Descricao | Portal Principal |
|---|---|---|
| `dealer` | Cliente/revendedor | Portal Cliente |
| `rep` | Representante comercial | Portal Representante |
| `analyst` | Analista comercial | Portal ADM Vendas |
| `manager` | Gerente comercial | Portal ADM Vendas |
| `financial` | Analista financeiro | Portal Financeiro |
| `admin` | Administrador do sistema | Todos |

### 3.2 Armazenamento do Role

Role armazenado nos **user_metadata** do Supabase Auth:

```json
{
  "role": "dealer",
  "cliente_id": "uuid-do-cliente"
}
```

Para representantes:
```json
{
  "role": "rep",
  "representante_id": "uuid-do-representante"
}
```

### 3.3 Matriz de Permissoes

| Recurso | dealer | rep | analyst | manager | financial | admin |
|---|---|---|---|---|---|---|
| Catalogo (ver) | Sim | Sim | Sim | Sim | Sim | Sim |
| Catalogo (precos) | Seus precos | Precos dos clientes | Todos | Todos | — | Todos |
| Pedido (criar) | Seus | Modo Proxy | — | — | — | Sim |
| Pedido (ver) | Seus | Dos seus clientes | Todos | Todos | — | Todos |
| Pedido (aprovar) | — | — | Sim (ate alcada) | Sim | — | Sim |
| Cadastro (submeter) | Proprio | Novo cliente | — | — | — | Sim |
| Cadastro (aprovar) | — | — | Sim | Sim | — | Sim |
| Credito (solicitar) | Proprio | Para cliente | — | — | — | Sim |
| Credito (decidir) | — | — | — | Sim | Sim | Sim |
| Titulos (ver) | Seus | Dos seus clientes | — | — | Todos | Todos |
| NFs (ver/baixar) | Suas | Dos seus clientes | — | — | Todas | Todas |
| Segunda via boleto | Seus | Dos seus clientes | — | — | Todos | Todos |
| Campanha (criar) | — | — | Sim | Sim | — | Sim |
| Pesquisa (criar) | — | — | Sim | Sim | — | Sim |
| Pesquisa (responder) | Sim | — | — | — | — | — |
| Usuarios (gerenciar) | — | — | — | — | — | Sim |
| Conectores (monitorar) | — | — | — | — | — | Sim |
| Logs (ver) | — | — | — | Sim | — | Sim |

### 3.4 Row Level Security (RLS)

Exemplo de policies por tabela:

**Tabela `pedidos`:**
```sql
-- Dealer ve apenas seus pedidos
create policy "dealer_select_pedidos" on pedidos
  for select using (
    auth.jwt() ->> 'role' = 'dealer'
    and cliente_id = (auth.jwt() -> 'user_metadata' ->> 'cliente_id')::uuid
  );

-- Representante ve pedidos dos seus clientes
create policy "rep_select_pedidos" on pedidos
  for select using (
    auth.jwt() ->> 'role' = 'rep'
    and cliente_id in (
      select cliente_id from carteira
      where representante_id = (auth.jwt() -> 'user_metadata' ->> 'representante_id')::uuid
      and ativo = true
    )
  );

-- Analyst e manager veem todos
create policy "adm_select_pedidos" on pedidos
  for select using (
    auth.jwt() ->> 'role' in ('analyst', 'manager', 'admin')
  );
```

**Tabela `titulos`:**
```sql
-- Dealer ve seus titulos
create policy "dealer_select_titulos" on titulos
  for select using (
    auth.jwt() ->> 'role' = 'dealer'
    and cliente_id = (auth.jwt() -> 'user_metadata' ->> 'cliente_id')::uuid
  );

-- Financial e admin veem todos
create policy "fin_select_titulos" on titulos
  for select using (
    auth.jwt() ->> 'role' in ('financial', 'admin')
  );
```

### 3.5 Alcadas de Aprovacao

| Acao | Analyst | Manager | Admin |
|---|---|---|---|
| Aprovar pedido (ate R$ 50k) | Sim | Sim | Sim |
| Aprovar pedido (R$ 50k-200k) | — | Sim | Sim |
| Aprovar pedido (acima R$ 200k) | — | — | Sim |
| Aprovar credito (ate R$ 100k) | — | Sim | Sim |
| Aprovar credito (acima R$ 100k) | — | — | Sim |
| Aprovar cadastro | Sim | Sim | Sim |

Valores de alcada sao parametrizaveis pelo CIE (regras na tabela `regras_cie`).

---

## 4. Camada 3 — Validacao

### 4.1 Edge Functions como Barreira

Toda operacao de escrita sensivel passa por Edge Functions que validam:

| Validacao | Exemplo |
|---|---|
| **Tipo de dado** | CNPJ tem 14 digitos, email tem formato valido |
| **Regra de negocio** | Cliente ativo, credito suficiente, quantidade > 0 |
| **Permissao** | Role permite a acao, alcada suficiente |
| **Integridade referencial** | Produto existe, cliente existe |
| **Limites** | Valor maximo por pedido, quantidade maxima por item |

### 4.2 Sanitizacao de Entrada

```typescript
// Toda Edge Function sanitiza inputs
function sanitize(input: string): string {
  return input
    .replace(/<[^>]*>/g, '')     // remove HTML
    .replace(/['"\\]/g, '')       // remove caracteres perigosos
    .trim()
    .substring(0, 1000);          // limita tamanho
}
```

### 4.3 Protecao contra Ataques

| Vetor | Protecao |
|---|---|
| SQL Injection | Supabase usa queries parametrizadas. Edge Functions usam supabase-js (ORM). |
| XSS | Sanitizacao de inputs. CSP headers. Sem innerHTML com dados de usuario. |
| CSRF | JWT via header (nao cookie). Origin check. |
| Brute force | Rate limiting (camada 4). Lockout apos 5 tentativas. |
| Enumeracao | Respostas genericas ("Credenciais invalidas", nao "Email nao encontrado"). |

---

## 5. Camada 4 — Transporte

### 5.1 HTTPS

- Todo trafego via HTTPS (TLS 1.2+)
- Certificado SSL automatico via Netlify / Supabase
- Redirecionamento HTTP → HTTPS automatico

### 5.2 Headers de Seguranca

```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' fonts.googleapis.com; font-src fonts.gstatic.com; connect-src *.supabase.co;
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### 5.3 CORS

```
Access-Control-Allow-Origin: https://plataforma.boxersoldas.com.br
Access-Control-Allow-Methods: GET, POST, PATCH, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type, apikey
Access-Control-Max-Age: 86400
```

---

## 6. Camada 5 — Dados

### 6.1 Supabase Vault

Todas as credenciais de sistemas externos ficam no **Supabase Vault**:

| Secret | Conector | Descricao |
|---|---|---|
| `zen_api_key` | C01 | API key do ERP ZEN |
| `serasa_api_key` | C02 | API key Serasa |
| `serasa_api_secret` | C02 | Secret Serasa |
| `boavista_api_key` | C02 | API key Boa Vista |
| `bank_client_id` | C03 | Client ID do banco |
| `bank_client_secret` | C03 | Secret do banco |
| `bank_certificate` | C03 | Certificado digital (base64) |
| `msal_token_cache` | C06 | Token cache Microsoft Graph |
| `whatsapp_api_key` | C06 | API key WhatsApp Business |
| `vapid_private_key` | C06 | VAPID private key (Web Push) |

### 6.2 Dados Sensiveis

| Dado | Tratamento |
|---|---|
| Senhas | Hash bcrypt (Supabase Auth) — nunca armazenadas em texto |
| CNPJ/CPF | Armazenados completos no banco. Mascarados em logs (XX.XXX.XXX/0001-XX) |
| Score de credito | Armazenado com data de consulta. Acesso restrito por RLS. |
| Tokens JWT | Armazenados em memoria (JS). Nunca em localStorage. |
| Documentos enviados (KYC) | Supabase Storage com acesso restrito por policy |

### 6.3 Backup e Recuperacao

| Aspecto | Configuracao |
|---|---|
| Backup automatico (Supabase) | Diario, retencao de 7 dias |
| Point-in-time recovery | Disponivel no plano Pro do Supabase |
| Backup manual | Script mensal exportando tabelas criticas |
| Teste de restore | Trimestral |

---

## 7. Camada 6 — Auditoria

### 7.1 Log de Alteracoes

Toda operacao de escrita registra na tabela `log_alteracoes`:

```sql
-- Ja definida no modelo de dados (HUB-DOC-008)
-- log_alteracoes: usuario_id, usuario_email, acao, tabela_ref,
--                 registro_id, dados_anteriores, dados_novos,
--                 ip, user_agent, criado_em
```

### 7.2 O que e Registrado

| Acao | Dados Registrados |
|---|---|
| Login bem-sucedido | Email, IP, user_agent, timestamp |
| Login falho | Email tentado, IP, motivo |
| Criar pedido | Todos os campos, valor total, itens |
| Alterar status | Status anterior, status novo, quem alterou, justificativa |
| Aprovar/rejeitar | Decisao, justificativa, alcada usada |
| Alterar credito | Limite anterior, limite novo, quem decidiu |
| Criar/editar usuario | Campos alterados, por quem |
| Modo Proxy ativado | Representante, cliente, duracao, acoes realizadas |

### 7.3 Imutabilidade

- Tabela `log_alteracoes` tem **apenas INSERT** (sem UPDATE ou DELETE)
- RLS impede qualquer role de modificar logs
- Policy: `for select` apenas para `admin` e `manager`
- Retencao minima: 2 anos

```sql
-- Policy: ninguem modifica logs
create policy "log_insert_only" on log_alteracoes
  for insert with check (true);

-- Policy: apenas admin e manager podem ler
create policy "log_select_admin" on log_alteracoes
  for select using (
    auth.jwt() ->> 'role' in ('admin', 'manager')
  );

-- Nenhuma policy de UPDATE ou DELETE (bloqueado por padrao com RLS ativado)
```

### 7.4 Modo Proxy — Auditoria Especial

Quando o representante age em nome do cliente, registros adicionais:

| Campo | Descricao |
|---|---|
| `representante_id` | Quem esta agindo |
| `cliente_id` | Em nome de quem |
| `origem` | `proxy_representante` |
| `sessao_proxy_id` | ID unico da sessao proxy |
| `ip_representante` | IP de origem |
| `acoes_realizadas` | Lista de acoes na sessao |

---

## 8. Modo Proxy — Seguranca Adicional

### 8.1 Restricoes

| Restricao | Descricao |
|---|---|
| Apenas clientes da carteira | Rep so acessa clientes vinculados a ele |
| Notificacao ao cliente | Cliente recebe alerta de toda acao feita em seu nome |
| Audit trail completo | Toda acao registrada com origem `proxy_representante` |
| Sem alteracao de cadastro | Rep nao pode alterar dados cadastrais do cliente em modo proxy |
| Sem acesso a dados financeiros detalhados | Rep ve titulos mas nao detalhes de pagamento |

### 8.2 Fluxo de Autorizacao

```
1. Rep loga no Portal Representante (proprio JWT, role=rep)
2. Seleciona cliente da carteira
3. Sistema valida: cliente esta na carteira do rep?
4. Se sim: ativa modo proxy
5. Todas as operacoes verificam:
   - JWT do rep (quem esta agindo)
   - cliente_id (em nome de quem)
   - carteira ativa (vinculo valido)
6. Ao sair do modo proxy: sessao proxy encerrada e logada
```

---

## 9. Checklist de Seguranca por Release

Antes de qualquer deploy em producao:

- [ ] Nenhuma credencial no codigo (grep por `service_role`, `password`, `secret`, `api_key`)
- [ ] Todas as tabelas com RLS ativado
- [ ] Policies testadas (usuario ve apenas o que deve)
- [ ] Edge Functions validam JWT em toda operacao
- [ ] Inputs sanitizados (sem XSS, sem injection)
- [ ] Rate limiting configurado
- [ ] Headers de seguranca configurados
- [ ] HTTPS obrigatorio
- [ ] Logs de auditoria funcionando
- [ ] Secrets no Vault (nao em variaveis de ambiente do frontend)
- [ ] Backup verificado

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
