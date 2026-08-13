# HUB-DOC-004: Jornadas dos Usuarios

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-04
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Metodologia

Cada jornada descreve o fluxo completo de um processo comercial na perspectiva do usuario, incluindo:
- Etapas sequenciais
- Atores envolvidos
- Sistemas participantes
- Origem e destino dos dados
- Pontos de decisao
- Pontos de dor a resolver

---

## 1.1 Conceito Transversal: Modo Representante (Proxy)

O representante comercial (P3 — Roberto) pode atuar **em nome de qualquer cliente da sua carteira** dentro do Boxer Hub. Isso significa que o representante tem acesso as mesmas funcionalidades do revendedor, mas no contexto do cliente selecionado.

### Funcionamento

```
1. Representante faz login com suas credenciais (role: rep)
2. Ve a lista de clientes da sua carteira
3. Seleciona um cliente para atuar em nome dele
4. Um seletor de cliente fica visivel no topo da tela
5. Todas as acoes sao executadas no contexto do cliente selecionado
6. Toda acao registra: quem fez (representante) + em nome de quem (cliente)
```

### Jornadas disponiveis em Modo Representante

| Jornada | O que o representante pode fazer |
|---|---|
| J1 Cadastro | Iniciar cadastro de novo cliente, preencher dados, submeter para analise |
| J2 Pedido | Colocar pedidos em nome do cliente (com precos do cliente) |
| J3 Acompanhamento | Ver timeline e status de pedidos do cliente |
| J4 Financeiro | Consultar titulos, baixar boletos, NFs e XMLs do cliente |
| J5 Credito | Solicitar aumento de credito em nome do cliente |

### Importancia Estrategica

O Modo Representante e essencial para:
- **Adocao:** Representante nao se sente ameacado pela plataforma — ela e sua ferramenta
- **Transicao:** Permite que a Boxer implante o Boxer Hub sem romper a relacao com representantes
- **Servico:** Representante pode atender o cliente em campo, fazendo tudo pelo sistema
- **Rastreabilidade:** Toda acao registra quem fez e em nome de quem (auditoria completa)

---

## 2. Jornada J1: Cadastro de Novo Cliente

**Persona primaria:** P1 (Carlos — Revendedor) + P3 (Roberto — Representante) + P4 (Fernanda — Analista Comercial)
**Portal:** Cliente + Representante (Modo Proxy) + ADM Vendas

### Fluxo

```
ETAPA 1: Acesso Inicial
  Ator: Revendedor (auto-cadastro) OU Representante (Modo Proxy)
  Acao: Revendedor acessa pagina de pre-cadastro do Boxer Hub,
        ou Representante inicia cadastro de um novo cliente pela sua carteira
  Sistema: Boxer Hub Frontend
  Nota: Representante que cadastra cliente ja vincula automaticamente
        o cliente a sua carteira.

ETAPA 2: Informacao do CNPJ
  Ator: Revendedor
  Acao: Digita CNPJ
  Sistema: Boxer Hub → Conector Receita Federal / Serasa
  Resultado: Preenchimento automatico (razao social, endereco, atividade)
  Dado: Origem = Receita Federal. Somente leitura.

ETAPA 3: Complemento Cadastral
  Ator: Revendedor
  Acao: Preenche dados adicionais (contato, volume estimado, segmento)
  Sistema: Boxer Hub Frontend
  Dado: Origem = Revendedor. Editavel.

ETAPA 4: Upload de Documentos
  Ator: Revendedor
  Acao: Envia documentos (contrato social, procuracoes, comprovantes)
  Sistema: Boxer Hub → Conector de Documentos (SharePoint/S3)
  Dado: Origem = Revendedor.

ETAPA 5: Vinculacao de Representante
  Ator: Sistema (automatico) ou ADM Vendas
  Acao: Atribui representante pela regiao
  Sistema: Boxer Hub → CIE (regra de territorialidade)
  Ponto de decisao: Representante automatico ou manual?

ETAPA 6: Analise Interna
  Ator: Fernanda (Analista Comercial)
  Acao: Revisa cadastro, valida documentos, solicita complementos
  Sistema: Boxer Hub Portal ADM
  Ponto de decisao: Cadastro completo? Sim → Etapa 7. Nao → Retorna a Etapa 3 com pendencias.

ETAPA 7: Solicitacao de Credito (opcional)
  Ator: Sistema automatico
  Acao: Dispara consulta a bureaus de credito
  Sistema: Boxer Hub → Conector Serasa/Boa Vista
  Ponto de decisao: Credito automatico (< limite X)? Sim → aprovacao automatica. Nao → Etapa 8.

ETAPA 8: Aprovacao de Credito
  Ator: Analista Financeiro ou Gerente
  Acao: Analisa score, historico, define limite
  Sistema: Boxer Hub Portal Financeiro
  Ponto de decisao: Aprovado/Reprovado/Pendente de garantia

ETAPA 9: Ativacao no ERP
  Ator: Sistema automatico
  Acao: Envia cadastro aprovado para o ERP
  Sistema: Boxer Hub → Conector ERP (ZEN)
  Dado: Boxer Hub → ERP (sincronizacao unidirecional nesta etapa)

ETAPA 10: Notificacao e Boas-Vindas
  Ator: Sistema automatico
  Acao: Envia credenciais de acesso e material de boas-vindas
  Sistema: Boxer Hub → Conector de Comunicacao (email/WhatsApp)
  Resultado: Cliente ativo na plataforma
```

### Pontos de Dor Resolvidos
- Preenchimento automatico elimina digitacao manual
- Upload digital elimina envio de documentos por email
- Fila de aprovacao visivel elimina "nao sei em que ponto esta meu cadastro"
- Consulta automatica de credito reduz tempo de aprovacao

---

## 3. Jornada J2: Pedido de Compra

**Persona primaria:** P1 (Carlos — Revendedor)
**Portal:** Cliente

### Fluxo

```
ETAPA 1: Acesso ao Catalogo
  Ator: Revendedor
  Acao: Navega catalogo, busca por produto, filtra por categoria
  Sistema: Boxer Hub Frontend
  Dado: Produtos = Origem ERP (espelhado). Precos = CIE (calculado).
  Nota: Disponibilidade de estoque exibida em cada produto.
        Produtos sem estoque exibem previsao de recebimento
        (dados do Conector Logistica → dashboard boxer-dashboard-logistica).

ETAPA 2: Selecao de Produtos
  Ator: Revendedor
  Acao: Adiciona produtos ao carrinho
  Sistema: Boxer Hub Frontend
  Nota: Preco exibido ja considera tabela do cliente, campanhas e regras do CIE
  Nota: Produtos sem estoque podem ser adicionados ao carrinho normalmente.
        O sistema informa a previsao de chegada e o pedido entra na
        fila de faturamento prioritario para despacho assim que o
        estoque for recebido.

ETAPA 3: Inteligencia Comercial
  Ator: CIE (automatico)
  Acao: Sugere cross-sell, upsell, consumiveis, acessorios
  Sistema: CIE → Boxer Hub Frontend
  Nota: Sugestoes baseadas em historico, perfil e regras

ETAPA 4: Revisao do Carrinho
  Ator: Revendedor
  Acao: Revisa itens, quantidades, precos, condicao de pagamento
  Sistema: Boxer Hub Frontend
  Ponto de decisao: Salvar como cotacao? Ou enviar como pedido?

ETAPA 5A: Salvar como Cotacao
  Ator: Revendedor
  Acao: Salva carrinho como cotacao (validade parametrizavel)
  Sistema: Boxer Hub
  Resultado: Cotacao disponivel para retomada posterior

ETAPA 5B: Enviar Pedido
  Ator: Revendedor
  Acao: Confirma pedido
  Sistema: Boxer Hub → Validacao CIE → Conector ERP
  Validacoes: Credito disponivel, estoque, politica comercial, alcada

ETAPA 6: Validacao de Regras
  Ator: CIE (automatico)
  Acao: Verifica elegibilidade, limites, restricoes
  Sistema: CIE
  Ponto de decisao: Aprovacao automatica? Sim → Etapa 8. Nao → Etapa 7.

ETAPA 7: Aprovacao Manual
  Ator: Analista Comercial ou Gerente
  Acao: Revisa excecao, aprova ou rejeita
  Sistema: Boxer Hub Portal ADM
  Nota: Cliente ve status "Aguardando Aprovacao" na timeline

ETAPA 8: Envio ao ERP
  Ator: Sistema automatico
  Acao: Transmite pedido aprovado ao ERP
  Sistema: Boxer Hub → Conector ERP (ZEN)
  Dado: Boxer Hub → ERP (pedido integrado)

ETAPA 9: Confirmacao
  Ator: Sistema automatico
  Acao: Notifica revendedor e representante
  Sistema: Boxer Hub → Conector de Comunicacao
  Resultado: Pedido registrado, timeline iniciada
```

### Variantes da Jornada

| Variante | Descricao |
|---|---|
| **Pedido Rapido** | Revendedor digita SKUs diretamente, sem navegar catalogo |
| **Recompra** | Revendedor seleciona pedido anterior e reenvia com 1 clique |
| **Importacao Excel** | P2 (Marina) importa planilha com lista de compras |
| **Pedido Recorrente** | Sistema sugere recompra automatica baseada em historico |
| **Cotacao para Aprovacao** | Revendedor gera cotacao para aprovacao interna da sua empresa |
| **Pedido com Backorder** | Produto sem estoque: cliente ve previsao de recebimento (Conector Logistica) e coloca pedido que entra na fila de faturamento prioritario. Quando mercadoria chega, pedido e faturado automaticamente com prioridade. |
| **Pedido via Representante** | Representante em Modo Proxy seleciona o cliente e coloca o pedido em nome dele, com os precos e condicoes do cliente. Registrado com autor = representante. |

---

## 4. Jornada J3: Acompanhamento de Pedido

**Persona primaria:** P1 (Carlos — Revendedor)
**Portal:** Cliente

### Fluxo

```
ETAPA 1: Visualizacao da Timeline
  Ator: Revendedor
  Acao: Acessa "Meus Pedidos" e seleciona um pedido
  Sistema: Boxer Hub Frontend
  Dado: Status = Origem ERP (espelhado automaticamente)

ETAPA 2: Status em Tempo Real
  A timeline exibe todas as etapas:

  [x] Pedido Recebido           — 04/08 09:15
  [x] Em Analise Comercial      — 04/08 09:20
  [x] Credito Aprovado          — 04/08 10:00
  [x] Pedido Liberado           — 04/08 10:05
  [x] Em Separacao              — 04/08 14:00
  [x] Faturado                  — 05/08 08:30
  [x] NF Emitida                — 05/08 08:31
  [ ] Expedido                  — Previsao: 05/08 16:00
  [ ] Em Transito               —
  [ ] Entregue                  —

  Origem: ERP (ZEN) → Conector ERP → Boxer Hub
  Frequencia de sincronizacao: a cada 15 minutos (configuravel)

ETAPA 3: Documentos do Pedido
  Ator: Revendedor
  Acao: Acessa NF (PDF), XML, boleto vinculado
  Sistema: Boxer Hub → Conector Fiscal/Financeiro
  Dado: Origem = ERP. Somente leitura.

ETAPA 4: Rastreamento
  Ator: Revendedor
  Acao: Consulta rastreamento da transportadora
  Sistema: Boxer Hub → Conector Logistica (transportadora)
  Dado: Origem = Transportadora. Somente leitura.

ETAPA 5: Notificacoes Proativas
  Ator: Sistema automatico
  Acao: Notifica mudancas de status
  Sistema: Boxer Hub → Conector de Comunicacao
  Canais: Push, email, WhatsApp (configuravel pelo usuario)
```

### Pontos de Dor Resolvidos
- "Ligo para saber do pedido" → Timeline visual em tempo real
- "Preciso da NF" → Download direto da plataforma
- "Onde esta minha entrega" → Rastreamento integrado

---

## 5. Jornada J4: Consulta Financeira

**Persona primaria:** P1 (Carlos — Revendedor)
**Portal:** Cliente + Financeiro

### Fluxo

```
ETAPA 1: Acesso ao Painel Financeiro
  Ator: Revendedor
  Acao: Acessa secao "Financeiro" no Portal Cliente
  Sistema: Boxer Hub Frontend
  Exibe: Limite total, limite disponivel, titulos em aberto

ETAPA 2: Consulta de Titulos
  Ator: Revendedor
  Acao: Filtra por status (a vencer, vencido, pago), periodo, valor
  Sistema: Boxer Hub
  Dado: Origem = ERP/Banco. Somente leitura.

ETAPA 3: Segunda Via de Boleto
  Ator: Revendedor
  Acao: Solicita segunda via de boleto de um titulo especifico
  Sistema: Boxer Hub → Conector Bancario
  Resultado: Boleto PDF + codigo de barras + PIX (quando disponivel)
  Nota: Self-service, sem necessidade de contato

ETAPA 4: Download de NF/XML
  Ator: Revendedor
  Acao: Baixa NF em PDF e XML de qualquer nota emitida
  Sistema: Boxer Hub → Conector Fiscal
  Nota: P2 (Marina) pode baixar em lote para conciliacao

ETAPA 5: Extrato
  Ator: Revendedor
  Acao: Visualiza extrato completo com filtros
  Sistema: Boxer Hub
  Dado: Consolidado de ERP + Banco. Somente leitura.
```

---

## 6. Jornada J5: Solicitacao e Acompanhamento de Credito

**Persona primaria:** P1 (Carlos) + P6 (Julia — Analista Financeira)
**Portal:** Cliente + Financeiro

### Fluxo

```
ETAPA 1: Solicitacao
  Ator: Revendedor
  Acao: Solicita aumento de limite ou credito inicial
  Sistema: Boxer Hub Portal Cliente
  Upload: Documentos financeiros (balanco, DRE, referencias)

ETAPA 2: Consulta Automatica
  Ator: Sistema automatico
  Acao: Consulta bureaus de credito (Serasa, Boa Vista)
  Sistema: Boxer Hub → Conectores de Credito
  Dado: Score e restricoes = Origem bureau. Somente leitura.

ETAPA 3: Analise
  Ator: Julia (Analista Financeira) ou CIE (automatico para limites menores)
  Acao: Avalia score, historico de compras, documentos, regras
  Sistema: Boxer Hub Portal Financeiro
  Ponto de decisao: Aprovado | Aprovado parcial | Reprovado | Pendente

ETAPA 4: Decisao
  Ator: Analista ou Gerente (conforme alcada)
  Acao: Define limite aprovado e condicoes
  Sistema: Boxer Hub → Conector ERP (atualiza limite no ERP)
  Notificacao: Revendedor e Representante sao notificados

ETAPA 5: Acompanhamento
  Ator: Revendedor
  Acao: Acompanha status da solicitacao em tempo real
  Sistema: Boxer Hub Portal Cliente
  Timeline similar a de pedidos
```

---

## 7. Jornada J6: Gestao de Carteira (Representante)

**Persona primaria:** P3 (Roberto — Representante)
**Portal:** Representante

### Fluxo

```
ETAPA 1: Dashboard da Carteira
  Ator: Representante
  Acao: Acessa dashboard mobile
  Exibe:
    - Total de clientes ativos/inativos
    - Faturamento do mes vs meta
    - Pedidos em andamento
    - Alertas (clientes sem compra > 30 dias, credito liberado, pedido com problema)

ETAPA 2: Visao do Cliente
  Ator: Representante
  Acao: Seleciona um cliente da carteira
  Exibe:
    - Ultimo pedido, valor, data
    - Historico de compras (grafico)
    - Limite de credito e situacao financeira
    - Produtos mais comprados
    - Oportunidades sugeridas pelo CIE

ETAPA 3: Acao Comercial
  Ator: Representante
  Acao: Cria cotacao para o cliente em campo
  Sistema: Boxer Hub Portal Representante
  Nota: Precos ja calculados pelo CIE. Cotacao pode ser enviada via WhatsApp/email.

ETAPA 4: Monitoramento de Pedidos
  Ator: Representante
  Acao: Acompanha todos os pedidos de seus clientes
  Sistema: Boxer Hub Portal Representante
  Filtros: Por status, por cliente, por periodo

ETAPA 5: Performance
  Ator: Representante
  Acao: Consulta sua performance (vendas, metas, comissoes)
  Sistema: Boxer Hub → CIE + ERP
```

---

## 8. Jornada J7: Gestao de Politica Comercial (ADM)

**Persona primaria:** P5 (Marcos — Gerente Comercial)
**Portal:** ADM Vendas
**Sistema externo integrado:** boxer-politica-comercial.pages.dev

### Abordagem

A Boxer ja possui um sistema dedicado para gestao de politica comercial em producao (boxer-politica-comercial.pages.dev). O Boxer Hub **nao reconstroi** essa funcionalidade — ele integra o sistema existente.

### Fluxo

```
ETAPA 1: Acesso via Boxer Hub
  Ator: Gerente Comercial
  Acao: Acessa "Politica Comercial" no Portal ADM
  Sistema: Boxer Hub Portal ADM
  Nota: Boxer Hub exibe o sistema boxer-politica-comercial integrado
        (iframe ou link direto). O trabalho de gestao continua no
        sistema existente, o Boxer Hub apenas o incorpora na experiencia.

ETAPA 2: Gestao de Regras (no sistema existente)
  Ator: Gerente Comercial
  Acao: Cria/edita regras comerciais usando o sistema de politica comercial
  Sistema: boxer-politica-comercial.pages.dev
  Nota: Toda a logica de gestao permanece no sistema dedicado.

ETAPA 3: Consumo pelo CIE
  Ator: Sistema automatico
  Acao: CIE consome regras publicadas da politica comercial
  Sistema: CIE → Conector Politica Comercial → boxer-politica-comercial
  Nota: As regras publicadas alimentam o CIE para calculo de precos,
        elegibilidade, descontos e restricoes. A integracao e via
        conector padronizado (ADR-001).

ETAPA 4: Monitoramento no Boxer Hub
  Ator: Gerente Comercial
  Acao: Monitora aplicacao das regras nos pedidos do Boxer Hub
  Sistema: Boxer Hub Portal ADM → CIE
  Nota: Boxer Hub mostra como as regras estao sendo aplicadas nos pedidos
        (excecoes, desvios, aprovacoes) mesmo que a gestao das regras
        seja feita no sistema externo.
```

---

## 9. Jornada J8: Pesquisas e Promocoes (Engajamento)

**Persona primaria:** P5 (Marcos — Gerente Comercial) + P1 (Carlos — Revendedor)
**Portal:** ADM Vendas + Cliente + Representante

### 9.1 Fluxo — Pesquisas com Revendedores

```
ETAPA 1: Criacao da Pesquisa
  Ator: Gerente Comercial ou Analista
  Acao: Cria pesquisa no Portal ADM
  Sistema: Boxer Hub Portal ADM
  Configuracoes:
    - Titulo e descricao
    - Tipo de perguntas (multipla escolha, escala, texto livre)
    - Publico-alvo (todos, por canal, por regiao, por representante)
    - Periodo de vigencia (data inicio e fim)
    - Obrigatoria ou opcional

ETAPA 2: Publicacao
  Ator: Gerente Comercial
  Acao: Publica pesquisa
  Sistema: Boxer Hub → Conector de Comunicacao
  Resultado: Pesquisa aparece no Portal Cliente dos revendedores selecionados
  Notificacao: Revendedor e notificado (push, email)

ETAPA 3: Resposta do Revendedor
  Ator: Revendedor
  Acao: Responde pesquisa no Portal Cliente
  Sistema: Boxer Hub Portal Cliente
  Nota: Pesquisa pode aparecer como banner/card no dashboard ou em area dedicada
  Nota: Pesquisas obrigatorias podem bloquear acoes ate serem respondidas

ETAPA 4: Acompanhamento de Respostas
  Ator: Gerente Comercial
  Acao: Monitora taxa de resposta em tempo real
  Sistema: Boxer Hub Portal ADM
  Exibe: Total de respostas, percentual por regiao, graficos de resultados

ETAPA 5: Relatorio Final
  Ator: Gerente Comercial
  Acao: Gera relatorio consolidado ao fim da vigencia
  Sistema: Boxer Hub Portal ADM
  Resultado: Dados exportaveis (CSV, PDF) com analise por segmento
```

### 9.2 Fluxo — Sinalizacao de Promocoes

```
ETAPA 1: Configuracao da Promocao
  Ator: Gerente Comercial ou Analista
  Acao: Cria campanha promocional no Portal ADM
  Sistema: Boxer Hub Portal ADM → CIE
  Configuracoes:
    - Produtos incluidos
    - Desconto ou condicao especial
    - Vigencia (data inicio e fim)
    - Publico-alvo (todos, por canal, por segmento)
    - Material visual (banner, badge, destaque)

ETAPA 2: Ativacao e Sinalizacao
  Ator: Sistema automatico (conforme vigencia)
  Acao: Ativa a promocao nos portais
  Sistema: CIE → Boxer Hub Frontend
  Sinalizacoes visiveis no Portal Cliente:
    - Banner destaque no topo do catalogo
    - Badge "PROMOCAO" nos produtos incluidos
    - Area dedicada "Promocoes Ativas" no dashboard
    - Preco original riscado + preco promocional em destaque
    - Contador de vigencia ("Valido ate DD/MM")

ETAPA 3: Experiencia do Revendedor
  Ator: Revendedor
  Acao: Navega catalogo e ve promocoes sinalizadas
  Sistema: Boxer Hub Portal Cliente
  Nota: Precos promocionais ja calculados pelo CIE
  Nota: Filtro rapido "Ver so promocoes" no catalogo

ETAPA 4: Notificacao ao Representante
  Ator: Sistema automatico
  Acao: Notifica representantes sobre promocoes ativas para seus clientes
  Sistema: Boxer Hub → Conector de Comunicacao
  Nota: Representante pode usar a promocao como argumento de venda em campo

ETAPA 5: Monitoramento
  Ator: Gerente Comercial
  Acao: Acompanha desempenho da promocao (vendas, adesao, ROI)
  Sistema: Boxer Hub Portal ADM
  Exibe: Comparativo antes/durante/apos a promocao
```

### Pontos de Dor Resolvidos
- "Nao sei quais produtos novos a Boxer tem" → Promocoes visualmente destacadas
- "Preciso de feedback dos revendedores" → Pesquisas diretamente no sistema
- "Nao sei se a promocao esta chegando nos clientes" → Sinalizacao automatica e monitoramento de adesao
- "Revendedor so descobre promocao se o representante avisar" → Notificacao direta + destaque visual

---

## 10. Mapa de Jornadas x Portais

| Jornada | Cliente | Representante | ADM Vendas | Financeiro |
|---|---|---|---|---|
| J1 Cadastro | Inicia | **Inicia (Proxy)** | Aprova | Credito |
| J2 Pedido (incl. backorder) | Executa | **Executa (Proxy)** | Aprova excecoes | — |
| J3 Acompanhamento | Consulta | **Consulta (Proxy)** | Monitora | — |
| J4 Financeiro | Consulta | **Consulta (Proxy)** | — | Gerencia |
| J5 Credito | Solicita | **Solicita (Proxy)** | — | Analisa/Aprova |
| J6 Carteira | — | Gerencia | Monitora | — |
| J7 Politica Comercial | — | — | Integra (site externo) | — |
| J8 Pesquisas e Promocoes | Responde/Ve | Ve promocoes | Cria/Monitora | — |

**Legenda:** **(Proxy)** = Representante atuando em nome do cliente via Modo Representante. Toda acao registra quem executou e em nome de qual cliente.

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
