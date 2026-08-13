# HUB-DOC-025: Plano de Implantacao

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-12
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Estrategia de Implantacao

**Abordagem B:** lancamento em fases — piloto restrito antes de rollout geral.

```
FASE 1: Infraestrutura    → Tudo no ar, ninguem usando
FASE 2: Carga de dados    → Produtos, clientes, precos sincronizados
FASE 3: Piloto            → 3-5 revendedores selecionados
FASE 4: Ajustes           → Correcoes baseadas no feedback
FASE 5: Rollout gradual   → Migrar base em lotes
FASE 6: Operacao plena    → Todos os revendedores no Hub
```

---

## 2. Fase 1 — Infraestrutura

**Quando:** Sprint 1 (semana 1-2)
**Responsavel:** Equipe TI

| # | Tarefa | Detalhe |
|---|---|---|
| 1 | Criar projeto Supabase `boxer-hubcomercial` | Settings → New Project, regiao sa-east-1 |
| 2 | Configurar schemas | `comercial`, `auth`, `config` |
| 3 | Executar migrations | Tabelas core, RLS policies, funcoes |
| 4 | Criar repositorio GitHub | Tekweld/boxer-hub |
| 5 | Configurar Netlify | Auto-deploy do branch `main`, dominio custom |
| 6 | DNS | hub.boxersoldas.com.br → Netlify (CNAME) |
| 7 | HTTPS | Certificado automatico via Netlify |
| 8 | Credenciais no Vault | API keys ZEN, service accounts no Supabase Vault |
| 9 | Criar usuario admin | Bruno → admin, Andre → manager |

**Checklist de validacao:**
- [ ] hub.boxersoldas.com.br abre tela de login
- [ ] Login admin funcional
- [ ] RLS ativado em todas as tabelas
- [ ] CI/CD: push no GitHub → deploy no Netlify em < 2min

---

## 3. Fase 2 — Carga de Dados

**Quando:** Sprint 2 (semana 3-4)
**Responsavel:** Equipe TI + Comercial

| # | Tarefa | Detalhe |
|---|---|---|
| 1 | Ativar C01 — getProducts | Sync inicial de produtos do ERP ZEN |
| 2 | Ativar C01 — getStock | Sync de estoque |
| 3 | Importar tabelas de precos | Via C11 (upload Excel) ou sync ERP |
| 4 | Importar fichas tecnicas | Via C11 (upload de planilha com fichas detalhadas) |
| 5 | Importar base de clientes | Sync de clientes ativos do ERP |
| 6 | Importar titulos financeiros | C01 — getFinancialTitles |
| 7 | Importar NFs | C01 — getInvoices |
| 8 | Configurar regras CIE | Alcadas, descontos por tier, condicoes de pagamento |
| 9 | Validar dados importados | Checar consistencia: SKUs, precos, estoque, limites de credito |

**Checklist de validacao:**
- [ ] Catalogo exibe produtos reais com precos corretos
- [ ] Estoque reflete ERP (comparar 10 SKUs manualmente)
- [ ] Ficha tecnica de pelo menos 20 produtos preenchida
- [ ] Tabela de precos do cliente piloto aplicando desconto correto
- [ ] Titulos financeiros do cliente piloto visiveis e corretos

---

## 4. Fase 3 — Piloto

**Quando:** Sprints 10-11 (semanas 19-22)
**Responsavel:** Andre (produto) + Representante responsavel pelos clientes

### 4.1 Selecao de Revendedores Piloto

| Criterio | Peso | Descricao |
|---|---|---|
| Volume de pedidos | 30% | >= 3 pedidos/mes — gera dados suficientes para validar |
| Relacionamento | 25% | Boa relacao com representante, disposto a dar feedback |
| Maturidade digital | 25% | Usa smartphone/email regularmente |
| Diversidade | 20% | Mix de perfis: P1 (autonomo) + P2 (enterprise) |

**Meta:** 3-5 revendedores, preferencialmente de 2-3 representantes diferentes.

### 4.2 Onboarding do Piloto

| Dia | Acao | Responsavel |
|---|---|---|
| D-7 | Selecionar revendedores e confirmar participacao | Andre |
| D-5 | Criar usuarios no Supabase Auth (email + senha temporaria) | TI |
| D-5 | Verificar dados do cliente no Hub (precos, titulos, credito) | Comercial |
| D-3 | Enviar email de boas-vindas com link + guia rapido PDF | Andre |
| D-1 | Call individual (15min) com cada revendedor: primeiro login, tour guiado | Andre |
| D0 | Piloto ativo — revendedores comecam a usar | — |
| D+1 | Acompanhamento por WhatsApp: "Como foi o primeiro acesso?" | Andre |
| D+7 | Check-in semanal: dificuldades, sugestoes, erros encontrados | Andre |
| D+14 | Avaliacao intermediaria: NPS, uso efetivo, pedidos realizados | Andre |
| D+21 | Avaliacao final: feedback consolidado, decisao go/no-go | Andre + Lideranca |

### 4.3 Metricas do Piloto

| Metrica | Como medir | Meta |
|---|---|---|
| Pedidos via Hub | Contar pedidos com origem = 'hub' | >= 10 total no periodo |
| Tempo medio para pedir | Log de sessao: catalogo → checkout | < 5 minutos |
| Erros de integracao | Tabela fila_integracao | 0 erros nao resolvidos |
| Taxa de conclusao J2 | Inicios de carrinho vs pedidos enviados | >= 70% |
| NPS | Formulario no D+21 | >= 7 |
| Chamadas de suporte | Contar mensagens de duvida | < 3 por revendedor |

### 4.4 Criterios Go/No-Go

| Criterio | Go | No-Go |
|---|---|---|
| Pedidos completados | >= 80% dos pilotos fizeram pedido | < 50% fizeram pedido |
| Erros bloqueantes | 0 erros sem solucao | >= 1 erro sem solucao |
| NPS | >= 7 | < 5 |
| Dados corretos | Precos e estoque consistentes com ERP | Divergencias sistematicas |
| Integracao | C01 funcional (pedido chega no ERP) | Pedidos nao chegam ou duplicam |

---

## 5. Fase 4 — Ajustes Pos-Piloto

**Quando:** Sprint 11 (semanas 21-22)
**Responsavel:** Equipe TI

| Tipo | Acao |
|---|---|
| Bugs bloqueantes | Corrigir imediatamente (hotfix) |
| UX | Ajustar fluxos conforme feedback (tela mais confusa, campo desnecessario) |
| Performance | Otimizar queries lentas, comprimir assets |
| Dados | Corrigir mapeamentos, fichas tecnicas incompletas |
| Seguranca | Revisar logs de acesso, fechar brechas encontradas |

---

## 6. Fase 5 — Rollout Gradual

**Quando:** Sprints 18-19 (semanas 35-38)
**Responsavel:** Andre + Representantes

### 6.1 Estrategia de Migracao

```
Semana 35: Lote 1 — 10-15 revendedores (regiao do representante piloto)
Semana 36: Lote 2 — 15-20 revendedores (outra regiao)
Semana 37: Lote 3 — 20-30 revendedores (demais regioes)
Semana 38: Lote 4 — Restante da base ativa
```

### 6.2 Por Lote

| # | Tarefa | Responsavel |
|---|---|---|
| 1 | Criar usuarios no Supabase Auth | TI (script batch) |
| 2 | Verificar dados de cada cliente (precos, credito) | Comercial |
| 3 | Enviar email de convite com link + guia | Marketing/Comercial |
| 4 | Representante avisa cliente por WhatsApp/visita | Representante |
| 5 | Monitorar primeiro login e primeiro pedido | TI + Andre |
| 6 | Suporte reativo via WhatsApp/email | Comercial |

### 6.3 Canal Paralelo

O canal de pedidos por telefone/email **nao sera desligado imediatamente**. Transicao gradual:

| Fase | Telefone/Email | Hub |
|---|---|---|
| Piloto | 100% ativo | Opcao adicional |
| Rollout lote 1-2 | 100% ativo | Incentivado (desconto? prioridade?) |
| Rollout lote 3-4 | Desencorajado (redirecionar para Hub) | Principal |
| Operacao plena | Apenas para excecoes e suporte | Obrigatorio |

---

## 7. Fase 6 — Operacao Plena

**Quando:** A partir da semana 39
**Responsavel:** Equipe Comercial + TI

### 7.1 Monitoramento Contínuo

| Item | Ferramenta | Frequencia |
|---|---|---|
| Uptime do Hub | UptimeRobot (URL check) | A cada 5 minutos |
| Status dos conectores | Dashboard admin (/admin/conectores) | Diario |
| Erros de integracao | Tabela fila_integracao | Diario |
| Logs de auditoria | /admin/logs | Semanal |
| Metricas de uso | Analytics (sessoes, pedidos, conversao) | Semanal |
| Satisfacao | Pesquisa periodica via J8 | Mensal |

### 7.2 SLA Operacional

| Metrica | Meta |
|---|---|
| Disponibilidade | >= 99.9% (Netlify + Supabase) |
| Sync ERP | Dados defasados em no maximo 30 minutos |
| Tempo de resposta | < 2s para qualquer tela |
| Resolucao de bugs criticos | < 4 horas |
| Resolucao de bugs normais | < 48 horas |

### 7.3 Suporte

| Canal | Publico | Responsavel |
|---|---|---|
| WhatsApp Business | Revendedores (duvidas operacionais) | Comercial |
| Email suporte@boxersoldas.com.br | Revendedores (problemas tecnicos) | TI |
| Portal ADM — fila de solicitacoes | Alteracoes cadastrais, credito | Comercial/Financeiro |
| /admin/logs | Auditoria e debug | TI |

---

## 8. Material de Apoio

| Material | Formato | Responsavel | Quando |
|---|---|---|---|
| Guia rapido do revendedor | PDF 2 paginas | Andre | Antes do piloto |
| Video "Primeiro pedido" | Video 3-5 min | Andre | Antes do piloto |
| FAQ — Perguntas frequentes | Pagina HTML no Hub | Andre | Antes do rollout |
| Guia do representante | PDF 3 paginas | Andre | Antes da Fase 6 |
| Manual do ADM | PDF 5 paginas | Andre | Antes da Fase 4 |
| Treinamento presencial/remoto | Call 30 min por lote | Andre + Rep | Durante rollout |

---

## 9. Plano de Rollback

Se o piloto ou rollout apresentar problemas criticos:

| Nivel | Situacao | Acao |
|---|---|---|
| **Nivel 1** | Bug isolado em uma funcionalidade | Desabilitar funcionalidade, hotfix, reativar |
| **Nivel 2** | Integracao com ERP falhando | Pausar envio de pedidos via Hub, revendedor volta ao telefone temporariamente |
| **Nivel 3** | Problema de seguranca (dados expostos) | Desativar Hub imediatamente, investigar, comunicar afetados |
| **Nivel 4** | Sistema inutilizavel | Apontar DNS para pagina de manutencao, restaurar backup do banco, comunicar prazo |

**Backup:**
- Supabase: backup automatico diario (point-in-time recovery)
- Netlify: rollback para deploy anterior em 1 clique
- Dados: nenhum dado e deletado (exclusao logica via `ativo = false`)

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
