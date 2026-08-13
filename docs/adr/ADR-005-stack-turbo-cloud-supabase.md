# ADR-005: Stack Tecnologica — Netlify + Supabase

**Status:** Aprovada
**Data:** 2026-08-04 (revisada 2026-08-11)
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

A Boxer Soldas avaliou opcoes de hospedagem para o Boxer Hub. O Turbo Cloud (provedor do site corporativo) foi considerado inicialmente, porem descartado por nao oferecer CI/CD moderno, CDN ou deploy automatizado via GitHub. O Netlify, ja utilizado como padrao corporativo para outros sistemas Boxer, oferece melhor experiencia de deploy, CDN global, HTTPS automatico e integracao nativa com GitHub.

O projeto Supabase `boxer-sistemas` compartilhado entre todos os sistemas Boxer nao oferece o controle necessario para uma plataforma do porte do Boxer Hub. O Boxer Hub tera seu proprio projeto Supabase dedicado `boxer-hubcomercial`, com gestao completa pelo lider do projeto.

As fontes de dados do Boxer Hub vao alem do ERP ZEN: incluem bases estaticas (Excel/XLSX), APIs de bureaus de credito (Serasa), e outros sistemas internos. A arquitetura connector-first (ADR-001) acomoda essa diversidade sem mudanca estrutural.

## Decisao

### Stack Principal
- **Netlify:** Hospedagem com CDN global, HTTPS automatico, deploy via GitHub (conta corporativa Boxer Soldas)
- **URL:** hub.boxersoldas.com.br (dominio customizado no Netlify)
- **GitHub (Tekweld):** Codigo-fonte (repositorio `boxer-hub`)
- **GitHub Actions + Netlify:** CI/CD com deploy automatico (push → build → deploy)
- **Supabase (projeto dedicado `boxer-hubcomercial`):** Projeto Supabase exclusivo, separado do boxer-sistemas. Admin: Andre Coelho.
- **Supabase Auth:** Autenticacao de TODOS os perfis (revendedores, representantes, internos)
- **HTML + JavaScript puro:** Frontend sem frameworks
- **CSS inline** nos HTMLs
- **HTTPS obrigatorio:** Automatico via Netlify

### Extensoes
- **Supabase Edge Functions:** Logica server-side do CIE (regras comerciais, validacoes, operacoes sensiveis)
- **Supabase Realtime:** Atualizacoes de status em tempo real
- **Supabase RLS:** Seguranca de dados na camada do banco (ver ADR-008)
- **PWA (Service Worker):** Portal do representante (uso em campo com conectividade limitada)

### NAO sera utilizado
- Turbo Cloud (descartado — sem CI/CD moderno, sem CDN)
- Cloudflare Pages (Netlify e o padrao corporativo)
- Projeto `boxer-sistemas` (Boxer Hub tem projeto Supabase proprio — `boxer-hubcomercial`)
- Frameworks frontend (React, Vue, Angular)
- Backend separado (FastAPI, Node) — Edge Functions cobrem a necessidade

## Consequencias

### Positivas
- Projeto Supabase dedicado com gestao total pelo lider do projeto
- Isolamento completo de outros sistemas Boxer (sem interferencia)
- Netlify ja e o padrao corporativo — equipe familiarizada
- CDN global com HTTPS automatico (sem configuracao manual de certificado)
- Deploy automatico via GitHub (push → deploy)
- Preview deploys para validacao antes de ir para producao
- Nomenclatura de tabelas limpa (sem prefixos de schema compartilhado)
- Operacao minima — Supabase gerencia infraestrutura de banco, auth, functions

### Negativas
- Sem controle de acesso no nivel da hospedagem (ver ADR-008 para mitigacao — seguranca 100% na camada de aplicacao)
- Custo adicional do projeto Supabase dedicado (~$25/mes no plano Pro)
- JavaScript puro exige maior disciplina de organizacao de codigo

### Historico
- 2026-08-04: Decisao original com Turbo Cloud
- 2026-08-11: Substituido por Netlify (melhor CI/CD, CDN, padrao corporativo). Supabase project renomeado de `boxer-hub` para `boxer-hubcomercial`
