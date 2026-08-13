# ADR-008: Modelo de Seguranca — Hosting-Only (Netlify)

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

O Netlify fornece hospedagem com CDN e HTTPS automatico, porem nao possui controle de acesso de borda nativo no plano utilizado (sem equivalente a Cloudflare Access ou AWS WAF). Qualquer pessoa com acesso a URL pode carregar os arquivos HTML/JS da plataforma. Isso exige que TODA a seguranca seja implementada na camada de aplicacao. Andre exigiu explicitamente "seguranca absoluta e acesso restrito."

## Decisao

Implementar seguranca em profundidade (defense in depth) inteiramente na camada de aplicacao, com as seguintes camadas:

### Camada 1: Autenticacao (Supabase Auth)

- **Todos os perfis** autenticam via Supabase Auth (email + senha) — internos e externos
- **Sem acesso anonimo** a qualquer dado. Sem anon key com permissoes de leitura em tabelas do Boxer Hub
- **Politica de senhas:** minimo 10 caracteres, complexidade obrigatoria
- **Bloqueio por tentativas:** apos 5 tentativas falhas, bloqueio temporario (Supabase rate limit + Edge Function)
- **Sessao com expiracao:** JWT expira em 1h, refresh token expira em 7 dias (configuraveis)
- **Refresh automatico:** Frontend renova JWT transparentemente antes da expiracao

### Camada 2: Autorizacao (RLS + Roles)

- **Row Level Security (RLS)** ativado em 100% das tabelas do Boxer Hub — sem excecao
- **Roles definidos no JWT:** `dealer`, `rep`, `analyst`, `manager`, `financial`, `admin`
- **Metadata no user:** Role e tenant armazenados em `auth.users.raw_user_meta_data`
- **Politicas RLS por role:** cada perfil ve apenas os dados que lhe pertencem

```sql
-- Exemplo: revendedor so ve seus proprios pedidos
CREATE POLICY "dealer_own_orders" ON pedidos
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'dealer'
    AND cliente_id = auth.uid()
  );

-- Exemplo: representante ve pedidos de seus clientes
CREATE POLICY "rep_client_orders" ON pedidos
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'rep'
    AND cliente_id IN (
      SELECT cliente_id FROM carteira
      WHERE representante_id = auth.uid()
    )
  );
```

### Camada 3: Operacoes Sensiveis (Edge Functions)

Operacoes criticas NUNCA executam diretamente do frontend:
- Calculo de precos finais (CIE)
- Envio de pedidos ao ERP
- Aprovacao de credito
- Alteracao de limites financeiros
- Gestao de politica comercial
- Criacao/edicao de usuarios

Essas operacoes rodam em **Supabase Edge Functions**, que:
- Validam o JWT do usuario
- Verificam permissoes (role + alcada)
- Executam a logica com `service_role` key (nunca exposta ao frontend)
- Registram no log de auditoria

### Camada 4: Protecao de Dados

- **Nenhum dado sensivel no frontend.** HTML/JS sao apenas interface.
- **Precos nao sao pre-carregados.** CIE calcula sob demanda via Edge Function, retornando apenas o preco do cliente autenticado.
- **XMLs e boletos** servidos via Edge Function com validacao de propriedade.
- **Regras do CIE** armazenadas no banco, nunca expostas ao frontend.

### Camada 5: Monitoramento e Auditoria

- **Log de autenticacao:** toda tentativa de login (sucesso/falha) registrada
- **Log de acesso:** operacoes criticas registradas em `log_alteracoes`
- **Alertas:** notificacao a TI para padroes anomalos (muitas falhas de login, acesso fora de horario)
- **Sessoes ativas:** admin pode visualizar e revogar sessoes

### Camada 6: Transporte

- **HTTPS obrigatorio** via Netlify (certificado SSL automatico)
- **CORS restrito:** apenas `plataforma.boxersoldas.com.br` e subdominos autorizados
- **Content Security Policy (CSP):** bloqueia scripts de terceiros

## Consequencias

### Positivas
- Seguranca independente do provedor de hospedagem (portavel)
- RLS garante que mesmo um bug no frontend nao expoe dados de outro usuario
- Edge Functions protegem logica de negocio e credenciais
- Modelo auditavel e rastreavel

### Negativas
- Sem bloqueio na borda — usuario nao autenticado ve a tela de login (aceitavel)
- Frontend (HTML/JS) e acessivel publicamente (sem dados sensiveis — aceitavel)
- Complexidade maior de desenvolvimento (cada tabela precisa de RLS policies)

### Vs. Cloudflare Access (modelo BAV)
- CF Access bloquearia na borda com Microsoft OAuth — usuario nem veria o login
- Com Netlify (hosting-only), o usuario ve a tela de login, mas nao consegue NADA alem disso sem autenticar
- Na pratica, a seguranca dos DADOS e identica — RLS e auth protegem tudo que importa
