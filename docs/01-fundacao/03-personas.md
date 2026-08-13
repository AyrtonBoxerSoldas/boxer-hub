# HUB-DOC-003: Personas

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-04
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Metodologia

As personas foram definidas a partir da analise dos perfis de usuarios que interagem com os processos comerciais da Boxer Soldas. Cada persona representa um arquetipo real de usuario, com suas necessidades, frustracoees, motivacoes e nivel de maturidade digital.

---

## 2. Personas Primarias

### P1: Carlos — O Revendedor Autonomo

**Perfil:**
- Dono de distribuidora de soldas e EPIs em cidade de medio porte
- 45 anos, ensino medio completo
- Compra da Boxer ha 8 anos
- Faz 3-5 pedidos por mes
- Usa smartphone como ferramenta principal (WhatsApp, banco)
- Maturidade digital: media

**Objetivos:**
- Fazer pedidos rapidamente sem depender de telefone
- Acompanhar entregas sem precisar ligar
- Consultar precos e disponibilidade antes de prometer ao cliente final
- Ter controle sobre seu financeiro (boletos, limites, NFs)
- Recomprar com facilidade

**Frustracoees:**
- "Ligo para saber do pedido e ninguem sabe me informar na hora"
- "Preciso de segunda via de boleto e demoro para conseguir"
- "Nao sei quais produtos novos a Boxer tem"
- "Perco tempo repetindo os mesmos pedidos todo mes"
- "Nao consigo ver meu limite disponivel quando preciso"

**Comportamento:**
- Prefere resolver tudo pelo celular
- Nao tem paciencia para sistemas complexos
- Confia no representante, mas quer autonomia
- Faz pedidos recorrentes com pouca variacao

**Necessidades no Boxer Hub:**
- Pedido rapido (1-2 cliques para recompra)
- Catalogo visual com precos ja calculados
- Status do pedido em tempo real
- Area financeira completa e acessivel
- Notificacoes por WhatsApp/push

---

### P2: Marina — A Compradora Profissional

**Perfil:**
- Compradora de grupo industrial com 12 filiais
- 32 anos, formacao em Administracao
- Responsavel por compras de MRO (manutencao, reparo e operacao)
- Faz pedidos grandes, planificados, com aprovacao interna
- Usa notebook e sistemas de compras (SAP, TOTVS)
- Maturidade digital: alta

**Objetivos:**
- Importar lista de compras via Excel/CSV
- Comparar produtos e precos entre fornecedores
- Ter historico de compras para auditoria
- Rastrear entregas por filial
- Obter XMLs e NFs para conciliacao automatica

**Frustracoees:**
- "Cada fornecedor tem um processo diferente"
- "Preciso do XML da NF para dar entrada no meu sistema e demoro para receber"
- "Nao consigo exportar meu historico de compras"
- "Tenho que refazer cotacoes manualmente todo mes"

**Comportamento:**
- Trabalha com multiplos fornecedores simultaneamente
- Valoriza eficiencia e integrabilidade
- Decide por custo total (preco + frete + prazo + confiabilidade)
- Precisa de funcionalidades enterprise (multi-filial, aprovacao, relatorios)

**Necessidades no Boxer Hub:**
- Importacao de pedidos via Excel
- Download de XMLs em lote
- Historico exportavel
- Cotacoes salvas e comparaveis
- Multi-filial com enderecos diferentes

---

### P3: Roberto — O Representante Comercial

**Perfil:**
- Representante comercial autonomo, 15 anos de experiencia
- 50 anos, cobre regiao metropolitana (40+ clientes ativos)
- Usa celular para tudo, visita clientes diariamente
- Maturidade digital: media-baixa

**Objetivos:**
- Saber rapidamente a situacao de cada cliente (credito, pedidos, pendencias)
- Identificar clientes que nao compram ha tempo
- Fazer cotacoes em campo e enviar ao cliente na hora
- Acompanhar suas metas e comissoes
- Ser notificado quando algo exige sua atencao

**Frustracoees:**
- "Ligo para o comercial para saber status e estao em reuniao"
- "Nao sei quais clientes estao inativos ate alguem me cobrar"
- "Preciso de uma tabela de precos atualizada e nunca tenho a ultima"
- "Perco vendas porque nao consigo dar preco na hora"
- "Nao sei minha comissao ate o pagamento chegar"

**Comportamento:**
- Trabalha principalmente no celular
- Pouca paciencia para navegacao complexa
- Precisa de informacao rapida e contextual
- Valoriza relacionamento, mas precisa de dados para embasar

**Necessidades no Boxer Hub:**
- Dashboard mobile com visao da carteira
- Alertas proativos (cliente inativo, credito liberado, pedido com problema)
- Cotacao rapida com preco correto do cliente
- Historico de compras do cliente na ponta do dedo
- Relatorio de performance acessivel

---

## 3. Personas Secundarias

### P4: Fernanda — A Analista Comercial Interna

**Perfil:**
- Analista do departamento comercial da Boxer
- 28 anos, formacao em Gestao Comercial
- Processa cadastros, pedidos e aprovacoes diariamente
- Trabalha em desktop, usa ERP + email + planilhas
- Maturidade digital: alta

**Objetivos:**
- Processar cadastros e aprovacoes rapidamente
- Ter visao consolidada de todos os pedidos pendentes
- Aplicar politica comercial sem erro
- Reduzir retrabalho de informacoes

**Frustracoees:**
- "Gasto tempo demais digitando dados que o cliente ja forneceu"
- "Nao sei se a regra de preco que estou aplicando e a mais atual"
- "Tenho que consultar 3 sistemas para responder uma pergunta simples"
- "Quando erro uma regra, o problema so aparece depois"

**Necessidades no Boxer Hub:**
- Fila de trabalho priorizada (cadastros, aprovacoes, excecoes)
- Aplicacao automatica de regras via CIE
- Visao unica consolidada (sem alternar entre sistemas)
- Alertas de excecoes e desvios

---

### P5: Marcos — O Gerente Comercial

**Perfil:**
- Gerente nacional de vendas da Boxer
- 42 anos, MBA em Gestao Empresarial
- Responsavel por metas, politica comercial e equipe de representantes
- Maturidade digital: media-alta

**Objetivos:**
- Ter visao estrategica de vendas (pipeline, conversao, ticket medio)
- Gerenciar politica comercial e campanhas
- Monitorar performance dos representantes
- Aprovar excecoes comerciais rapidamente

**Frustracoees:**
- "Nao tenho dashboard em tempo real — espero relatorios semanais"
- "Ajustar a politica comercial exige pedir para o TI"
- "Nao sei quais excecoes estao sendo concedidas"

**Necessidades no Boxer Hub:**
- Dashboard executivo em tempo real
- Gestao de politica comercial via interface
- Aprovacao de excecoes com historico e justificativa
- Comparativo de performance entre representantes/regioes

---

### P6: Julia — A Analista Financeira

**Perfil:**
- Analista do departamento financeiro da Boxer
- 30 anos, formacao em Contabilidade
- Gerencia cobranca, limites de credito, conciliacao
- Maturidade digital: alta

**Objetivos:**
- Consultar situacao financeira de clientes rapidamente
- Emitir segunda via de boletos sem depender de outros departamentos
- Monitorar titulos vencidos e em aberto
- Fornecer documentos fiscais aos clientes

**Frustracoees:**
- "Clientes ligam pedindo boleto e eu preciso acessar o banco"
- "Nao tenho visao consolidada da carteira de recebimentos"

**Necessidades no Boxer Hub:**
- Visao financeira do cliente (limites, titulos, historico)
- Self-service de boletos para o revendedor
- Alertas de vencimento e inadimplencia
- Exportacao de dados para conciliacao

---

## 4. Anti-Personas (quem NAO e usuario)

| Perfil | Porque nao e usuario |
|---|---|
| Consumidor final | Boxer Hub e exclusivamente B2B |
| Fornecedores da Boxer | Boxer Hub cobre apenas o canal de vendas |
| Equipe de producao/fabrica | Boxer Hub nao gerencia operacoes industriais |
| Contabilidade tributaria | Boxer Hub espelha dados fiscais, nao os origina |

---

## 5. Matriz de Prioridade de Personas

| Persona | Portal | Prioridade | Fase |
|---|---|---|---|
| P1: Carlos (Revendedor Autonomo) | Cliente | Critica | MVP |
| P2: Marina (Compradora Profissional) | Cliente | Alta | MVP + Expansao |
| P3: Roberto (Representante) | Representante | Alta | Expansao |
| P4: Fernanda (Analista Comercial) | ADM Vendas | Alta | MVP |
| P5: Marcos (Gerente Comercial) | ADM Vendas | Media | Expansao |
| P6: Julia (Analista Financeira) | Financeiro | Media | Expansao |

---

## 6. Implicacoes para Design

| Insight | Decisao de Design |
|---|---|
| P1 e P3 usam celular primariamente | Mobile-first e obrigatorio |
| P2 precisa de funcoes enterprise | Importacao Excel, multi-filial, XML em lote |
| P3 tem conectividade limitada | PWA com cache offline |
| P1 faz pedidos recorrentes | Funcao de recompra em 1-2 cliques |
| P4 alterna entre sistemas | Visao consolidada, eliminar alt-tab |
| Todos reclamam de falta de transparencia | Status em tempo real e obrigatorio |
| P5 quer autonomia sobre politica comercial | Interface de gestao de regras (sem TI) |

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
