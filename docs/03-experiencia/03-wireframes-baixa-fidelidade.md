# HUB-DOC-016: Wireframes de Baixa Fidelidade

**Boxer Hub**
**Versao:** 1.0
**Data:** 2026-08-10
**Autor:** Andre Coelho / Arquitetura Boxer Hub
**Status:** Em revisao

---

## 1. Convencoes

Os wireframes abaixo representam a estrutura e hierarquia de informacao das telas principais. Usam ASCII art para descrever layout sem comprometimento visual final.

```
┌──────────┐  = Container/card
│          │
└──────────┘

[  Botao  ]    = Botao clicavel
( campo  )     = Input/campo de formulario
< select >     = Select/dropdown
[x] / [ ]      = Checkbox/toggle
● / ○          = Radio button

--- linha ---  = Separador visual
```

Design system aplicado: Boxer (navy #1d327b, cyan #25bbee, red #e30613, Outfit).

---

## 2. Login

```
┌─────────────────────────────────────────────────┐
│                                                 │
│                                                 │
│         ┌───────────────────────────┐           │
│         │       ★ BOXER LOGO ★     │           │
│         │                           │           │
│         │       Boxer Hub           │           │
│         │   Plataforma Comercial    │           │
│         │                           │           │
│         │  ┌─────────────────────┐  │           │
│         │  │ Email               │  │           │
│         │  ( seu@email.com      )  │           │
│         │  └─────────────────────┘  │           │
│         │                           │           │
│         │  ┌─────────────────────┐  │           │
│         │  │ Senha               │  │           │
│         │  ( ••••••••           )  │           │
│         │  └─────────────────────┘  │           │
│         │                           │           │
│         │  [ ████ ENTRAR ████ ]     │           │
│         │                           │           │
│         │  Esqueci minha senha      │           │
│         │                           │           │
│         │  ─────────────────────    │           │
│         │  Novo? Pre-cadastre-se    │           │
│         └───────────────────────────┘           │
│                                                 │
│              bg: #f0f4f8                         │
└─────────────────────────────────────────────────┘
```

---

## 3. Portal Cliente — Dashboard

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER    Boxer Hub                    🔔 3  Andre C. ▼    Sair  │
│ ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔ │
│ topbar navy gradient + cyan border                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐      │
│  │ Pedidos em │ │ Limite     │ │ Titulos    │ │ Promocoes  │      │
│  │ andamento  │ │ Disponivel │ │ Vencidos   │ │ Ativas     │      │
│  │            │ │            │ │            │ │            │      │
│  │    5       │ │ R$ 45.000  │ │ R$ 8.200   │ │    3       │      │
│  │            │ │            │ │  ⚠ vermelho│ │            │      │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐      │
│  │ 🎯 PROMOCAO: Maquinas MIG com 15% OFF — ate 30/09      │      │
│  │    [ Ver Produtos em Promocao ]                          │      │
│  └──────────────────────────────────────────────────────────┘      │
│  banner destaque (cyan bg)                                          │
│                                                                     │
│  ┌── Ultimos Pedidos ─────────────────────── [ Ver Todos ] ──┐     │
│  │                                                            │     │
│  │  PED-2026-00158  04/08  R$ 12.350  ● Faturado   OC: 4521 │     │
│  │  PED-2026-00155  01/08  R$ 8.900   ● Em transito         │     │
│  │  PED-2026-00149  28/07  R$ 22.100  ● Entregue            │     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Atalhos Rapidos ─────────────────────────────────────────┐    │
│  │                                                             │    │
│  │  [ 🛒 Novo Pedido ]  [ 🔄 Recomprar ]  [ 💰 Financeiro ] │    │
│  │                                                             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌── Pesquisa Pendente ──────────────────────────────────────┐     │
│  │  📋 Pesquisa de Satisfacao — Atendimento Comercial        │     │
│  │     Vigencia: ate 20/08/2026       [ Responder Agora ]    │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Portal Cliente — Catalogo (Grid)

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER    Boxer Hub                    🔔 3  Andre C. ▼    Sair  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Catalogo de Produtos                                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ 🔍 ( Buscar por nome ou SKU...                            ) │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  Filtros:  < Categoria ▼ >  < Disponibilidade ▼ >  [x] Promocoes  │
│                                                    ▦ Grid  ≡ Lista │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │             │
│  │  │  FOTO  │  │  │  │  FOTO  │  │  │  │  FOTO  │  │             │
│  │  │        │  │  │  │ PROMO  │  │  │  │        │  │             │
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │             │
│  │              │  │  PROMOCAO    │  │              │             │
│  │  SKU: MIG350 │  │              │  │ SKU: TIG200  │             │
│  │  MIG 350A    │  │  SKU: ELE250 │  │ TIG 200A AC/ │             │
│  │  Multiproc.  │  │  Eletrodo    │  │ DC           │             │
│  │              │  │  2.5mm       │  │              │             │
│  │  R$ 8.450,00 │  │  R$ 150,00  │  │ R$ 5.200,00  │             │
│  │              │  │  R$ 120,00  │  │              │             │
│  │  ● Disponivel│  │  ● Dispon.  │  │ ○ Sem estoque│             │
│  │              │  │              │  │  Prev: 15/09 │             │
│  │ [+ Carrinho] │  │ [+ Carrinho] │  │ [+ Reservar] │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │     ...      │  │     ...      │  │     ...      │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                     │
│  Pagina 1 de 12     < Anterior   1  2  3  ...  12   Proxima >      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 5. Portal Cliente — PDP (Pagina de Detalhe do Produto)

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER    Boxer Hub                    🔔 3  Andre C. ▼    Sair  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Catalogo > Maquinas MIG > MIG 350A Multiprocesso                  │
│  (breadcrumb)                                                       │
│                                                                     │
│  ┌────────────────────────┐  ┌──────────────────────────────────┐  │
│  │                        │  │                                  │  │
│  │    ┌──────────────┐    │  │  MIG 350A Multiprocesso          │  │
│  │    │              │    │  │  SKU: MIG350                      │  │
│  │    │  FOTO GRANDE │    │  │  Categoria: Maquinas MIG          │  │
│  │    │  (zoom)      │    │  │                                  │  │
│  │    │              │    │  │  ┌────────────────────────────┐  │  │
│  │    └──────────────┘    │  │  │ Seu preco:                 │  │  │
│  │                        │  │  │ R$ 8.450,00                │  │  │
│  │  [o] [o] [o] [o]      │  │  │ Tabela: Varejo SP          │  │  │
│  │  (thumbnails)          │  │  └────────────────────────────┘  │  │
│  │                        │  │                                  │  │
│  └────────────────────────┘  │  ● Disponivel (42 em estoque)   │  │
│                              │                                  │  │
│                              │  Quantidade: ( 1 )  [- ] [+ ]   │  │
│                              │                                  │  │
│                              │  [ ████ ADICIONAR AO CARRINHO ]  │  │
│                              │                                  │  │
│                              └──────────────────────────────────┘  │
│                                                                     │
│  ┌── Ficha Tecnica ─────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │  Classificacao    │ MIG/MAG/TIG/Eletrodo                     │  │
│  │  Tensao           │ 220/380V Trifasico                       │  │
│  │  Corrente         │ 30-350A                                   │  │
│  │  Fator de trabalho│ 60% a 350A                                │  │
│  │  Peso             │ 42 kg                                     │  │
│  │  Dimensoes        │ 620 x 280 x 480 mm                       │  │
│  │  Gas              │ CO2 / Mistura Argonio                     │  │
│  │  Posicoes         │ Todas                                     │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌── O que Acompanha ───────────────────────────────────────────┐  │
│  │                                                               │  │
│  │  ✓ Tocha MIG 3m                                              │  │
│  │  ✓ Cabo de retorno 3m com garra                              │  │
│  │  ✓ Regulador de pressao CO2                                  │  │
│  │  ✓ Manual de instrucoes                                      │  │
│  │  ✓ Certificado de garantia                                   │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌── Documentos ────────────────────────────────────────────────┐  │
│  │                                                               │  │
│  │  📄 Ficha Tecnica (PDF)      [ Baixar ]                      │  │
│  │  📄 Certificado              [ Baixar ]                      │  │
│  │  📄 FISPQ                    [ Baixar ]                      │  │
│  │  📄 Manual                   [ Baixar ]                      │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌── Produtos Relacionados ─────────────────────────────────────┐  │
│  │                                                               │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │  │
│  │  │  FOTO    │  │  FOTO    │  │  FOTO    │  │  FOTO    │    │  │
│  │  │ Arame    │  │ Bico     │  │ Bocal    │  │ Tocha    │    │  │
│  │  │ MIG 1.0  │  │ contato  │  │ ceramico │  │ MIG 5m   │    │  │
│  │  │ R$ 85,00 │  │ R$ 12,00 │  │ R$ 28,00 │  │ R$ 320,00│    │  │
│  │  │[Carrinho]│  │[Carrinho]│  │[Carrinho]│  │[Carrinho]│    │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │  │
│  │  Sugeridos pelo CIE                                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. Portal Cliente — Carrinho

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER    Boxer Hub                    🔔 3  Andre C. ▼    Sair  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Carrinho de Compras (3 itens)                                      │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ FOTO │ MIG 350A Multiprocesso    │ Qtd: (1) │ R$ 8.450,00   │  │
│  │      │ SKU: MIG350               │ [-] [+]  │               │  │
│  │      │                           │          │   [ Remover ] │  │
│  ├──────┼───────────────────────────┼──────────┼───────────────┤  │
│  │ FOTO │ Arame MIG 1.0mm 15kg     │ Qtd: (3) │ R$ 255,00     │  │
│  │      │ SKU: ARM100-15            │ [-] [+]  │               │  │
│  │      │                           │          │   [ Remover ] │  │
│  ├──────┼───────────────────────────┼──────────┼───────────────┤  │
│  │ FOTO │ Eletrodo 2.5mm 5kg       │ Qtd: (2) │ R$ 240,00     │  │
│  │      │ SKU: ELE250-5   PROMOCAO │ [-] [+]  │ (era R$300)   │  │
│  │      │ ⚠ BACKORDER prev: 15/09  │          │   [ Remover ] │  │
│  └──────┴───────────────────────────┴──────────┴───────────────┘  │
│                                                                     │
│  ┌── Voce tambem pode precisar (CIE) ───────────────────────┐     │
│  │  Bico de contato 1.0mm (R$ 12,00) [+ Adicionar]           │     │
│  │  Bocal ceramico MIG (R$ 28,00)     [+ Adicionar]           │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Dados do Pedido ────────────────────────────────────────┐     │
│  │                                                            │     │
│  │  Condicao de pagamento:  < 30/60/90 DDL ▼ >              │     │
│  │                                                            │     │
│  │  Endereco de entrega:    < Filial SP - Rua... ▼ >         │     │
│  │                                                            │     │
│  │  Seu Pedido (OC):        ( 4523                         ) │     │
│  │  (numero interno da sua empresa — opcional)                │     │
│  │                                                            │     │
│  │  Observacoes:            ( Entregar no periodo da manha ) │     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Resumo ─────────────────────────────────────────────────┐     │
│  │                                                            │     │
│  │  Subtotal:        R$ 8.945,00                              │     │
│  │  Desconto:       -R$   60,00  (promocao eletrodo)          │     │
│  │  ─────────────────────────────                             │     │
│  │  Total:           R$ 8.885,00                              │     │
│  │                                                            │     │
│  │  ⚠ 1 item em backorder (previsao: 15/09)                  │     │
│  │                                                            │     │
│  │  [ Salvar como Cotacao ]    [ ████ ENVIAR PEDIDO ████ ]   │     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Portal Cliente — Detalhe do Pedido (Timeline)

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER    Boxer Hub                    🔔 3  Andre C. ▼    Sair  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Pedidos > PED-2026-00158                                           │
│                                                                     │
│  ┌── Informacoes ────────────────────────────────────────────┐     │
│  │                                                            │     │
│  │  Numero: PED-2026-00158     Seu Pedido (OC): 4521         │     │
│  │  Data: 04/08/2026           Status: ● Faturado             │     │
│  │  Valor: R$ 12.350,00       Cond. Pgto: 30/60/90 DDL      │     │
│  │                                                            │     │
│  │  👤 Criado pelo representante Roberto Silva                │     │
│  │  (badge: Modo Proxy)                                       │     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Timeline ───────────────────────────────────────────────┐     │
│  │                                                            │     │
│  │  ● ─── Recebido ─────────────── 04/08 09:15              │     │
│  │  │                                                         │     │
│  │  ● ─── Em Analise ───────────── 04/08 09:20              │     │
│  │  │                                                         │     │
│  │  ● ─── Credito Aprovado ─────── 04/08 10:00              │     │
│  │  │                                                         │     │
│  │  ● ─── Pedido Liberado ──────── 04/08 10:05              │     │
│  │  │                                                         │     │
│  │  ● ─── Em Separacao ─────────── 04/08 14:00              │     │
│  │  │                                                         │     │
│  │  ● ─── Faturado ─────────────── 05/08 08:30              │     │
│  │  │     NF: 123456  [ Baixar PDF ] [ Baixar XML ]          │     │
│  │  │                                                         │     │
│  │  ○ ─── Expedido ─────────────── Previsao: 05/08 16:00    │     │
│  │  │                                                         │     │
│  │  ○ ─── Em Transito                                        │     │
│  │  │                                                         │     │
│  │  ○ ─── Entregue                                           │     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Itens do Pedido ────────────────────────────────────────┐     │
│  │                                                            │     │
│  │  SKU       │ Produto              │ Qtd │ Preco    │ Total│     │
│  │  ──────────┼──────────────────────┼─────┼──────────┼──────│     │
│  │  MIG350    │ MIG 350A Multiproc.  │  1  │ 8.450,00 │ 8.450│     │
│  │  ARM100-15 │ Arame MIG 1.0 15kg   │  3  │    85,00 │   255│     │
│  │  TOC300    │ Tocha MIG 3m         │  1  │   320,00 │   320│     │
│  │            │                      │     │          │      │     │
│  │            │              Subtotal│     │          │ 9.025│     │
│  │            │              Desconto│     │          │  -175│     │
│  │            │                Total │     │          │ 8.850│     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Documentos ─────────────────────────────────────────────┐     │
│  │  📄 NF 123456      [ PDF ] [ XML ]                        │     │
│  │  📄 Boleto 1/3     [ Baixar ] Venc: 05/09                │     │
│  │  📄 Boleto 2/3     [ Baixar ] Venc: 05/10                │     │
│  │  📄 Boleto 3/3     [ Baixar ] Venc: 05/11                │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  [ 🔄 Recomprar este Pedido ]                                      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8. Portal Cliente — Financeiro

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER    Boxer Hub                    🔔 3  Andre C. ▼    Sair  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Financeiro                                                         │
│                                                                     │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐      │
│  │ Limite     │ │ Disponivel │ │ Em Aberto  │ │ Vencidos   │      │
│  │ Total      │ │            │ │            │ │            │      │
│  │R$ 100.000  │ │ R$ 45.000  │ │ R$ 55.000  │ │ R$ 8.200   │      │
│  │            │ │  (45%)     │ │            │ │  ⚠ 2 tit.  │      │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘      │
│                                                                     │
│  ┌ Titulos ┐ ┌ Notas Fiscais ┐ ┌ Extrato ┐                       │
│  └─────────┘ └───────────────┘ └─────────┘  (tabs)                │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Filtros: < Status ▼ > < Periodo ▼ > ( Buscar numero... )   │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │  Numero    │ Vencimento │ Valor      │ Status     │ Acao     │  │
│  │  ──────────┼────────────┼────────────┼────────────┼──────────│  │
│  │  DUP-45231 │ 05/08      │ R$ 4.100   │ ● Vencido  │[2a Via]  │  │
│  │  DUP-45232 │ 05/08      │ R$ 4.100   │ ● Vencido  │[2a Via]  │  │
│  │  DUP-45890 │ 15/08      │ R$ 3.200   │ ○ A vencer │[2a Via]  │  │
│  │  DUP-45891 │ 15/09      │ R$ 3.200   │ ○ A vencer │[2a Via]  │  │
│  │  DUP-44200 │ 01/07      │ R$ 5.500   │ ● Pago     │          │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ── Segunda Via (modal ao clicar) ──────────────────────────────   │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │  Segunda Via — DUP-45231                                   │     │
│  │                                                            │     │
│  │  Valor: R$ 4.100,00      Vencimento atualizado: 12/08     │     │
│  │                                                            │     │
│  │  Codigo de barras:                                         │     │
│  │  23793.38128 60000.000045 23100.036906 1 92380000041000    │     │
│  │  [ Copiar ]                                                │     │
│  │                                                            │     │
│  │  PIX Copia e Cola:                                         │     │
│  │  00020126...                                               │     │
│  │  [ Copiar ]                                                │     │
│  │                                                            │     │
│  │  [ Baixar Boleto PDF ]                  [ Fechar ]        │     │
│  └───────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 9. Portal Representante — Dashboard

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER  Boxer Hub — Representante       🔔 5  Roberto S. ▼  Sair│
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Minha Carteira                                                     │
│                                                                     │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐      │
│  │ Clientes   │ │ Faturamento│ │ Meta       │ │ Pedidos em │      │
│  │ Ativos     │ │ Mes        │ │            │ │ Andamento  │      │
│  │    42      │ │ R$ 280.000 │ │ R$ 350.000 │ │     8      │      │
│  │            │ │            │ │   80% ████ │ │            │      │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘      │
│                                                                     │
│  ┌── Alertas ────────────────────────────────────────────────┐     │
│  │  ⚠ 3 clientes sem compra ha mais de 30 dias              │     │
│  │    Distribuidora ABC (45 dias) | Loja XYZ (38 dias) | ...│     │
│  │  ✓ 2 creditos liberados recentemente                      │     │
│  │    Metal Sul (R$ 50k) | Ferrosoldas (R$ 30k)             │     │
│  │  ⚠ 1 pedido com problema                                 │     │
│  │    PED-2026-00145 — Credito insuficiente                  │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Atalhos ────────────────────────────────────────────────┐     │
│  │  [ 👤 Novo Cadastro ]  [ 📋 Nova Cotacao ]  [ 📦 Pedidos]│     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌── Faturamento vs Meta ────────────────────────────────────┐     │
│  │                                                            │     │
│  │  350k ┤                                          ── Meta  │     │
│  │       │                                                    │     │
│  │  280k ┤                              ████                  │     │
│  │       │                    ████      ████                  │     │
│  │  200k ┤          ████    ████      ████                    │     │
│  │       │  ████    ████    ████      ████                    │     │
│  │       └──Jan──── Feb──── Mar──── ... Ago                  │     │
│  │                                                            │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 10. Portal Representante — Modo Proxy (Ativo)

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER  Boxer Hub — Representante       🔔 5  Roberto S. ▼  Sair│
├─────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────┐│
│ │ 👤 Atuando em nome de: Distribuidora ABC Ltda    [ ✕ Sair ]   ││
│ │ CNPJ: 12.345.678/0001-90                                       ││
│ └─────────────────────────────────────────────────────────────────┘│
│  (barra de contexto — cyan bg — sempre visivel)                    │
│                                                                     │
│  ┌ Catalogo ┐ ┌ Pedidos ┐ ┌ Financeiro ┐ ┌ Credito ┐  (tabs)    │
│  └──────────┘ └─────────┘ └────────────┘ └─────────┘             │
│                                                                     │
│  (Conteudo identico ao Portal Cliente,                              │
│   porem no contexto do cliente selecionado)                         │
│                                                                     │
│  Diferencas visuais:                                                │
│  - Barra de contexto proxy no topo (cyan)                          │
│  - Badge "Via Representante" em acoes                               │
│  - Precos calculados com tabela do CLIENTE (nao do rep)            │
│  - Toda acao registra representante_id                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 11. Portal ADM — Dashboard

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER  Boxer Hub — ADM                 🔔 2  Fernanda M. ▼ Sair│
├──────────┬──────────────────────────────────────────────────────────┤
│          │                                                          │
│ Menu     │  Dashboard                                               │
│          │                                                          │
│ Dashboard│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│ Pedidos  │  │ Pedidos  │ │ Pendentes│ │ Cadastros│ │ Excecoes │  │
│ Cadastros│  │ Hoje     │ │ Aprov.   │ │ Pendentes│ │ Semana   │  │
│ Clientes │  │   12     │ │    3     │ │    2     │ │    5     │  │
│ Repres.  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│ Politica │                                                          │
│ Tabelas  │  ┌── Fila de Trabalho ────────────────────────────┐     │
│ Campanhas│  │                                                 │     │
│ Pesquisas│  │  🔴 Pedido PED-158 — Excecao de preco (R$ 85k)│     │
│          │  │     Cliente: Distribuidora ABC | Rep: Roberto  │     │
│          │  │     [ Analisar ]                                │     │
│          │  │                                                 │     │
│          │  │  🟡 Cadastro — Metal Sul Ltda                  │     │
│          │  │     CNPJ: 45.678.901/0001-23 | Docs OK        │     │
│          │  │     [ Analisar ]                                │     │
│          │  │                                                 │     │
│          │  │  🟡 Pedido PED-162 — Credito insuficiente      │     │
│          │  │     Cliente: Loja XYZ | Falta: R$ 12.000       │     │
│          │  │     [ Analisar ]                                │     │
│          │  │                                                 │     │
│          │  └─────────────────────────────────────────────────┘     │
│          │                                                          │
│          │  ┌── Pipeline Pedidos (funil) ─────────────────────┐    │
│          │  │                                                  │    │
│          │  │  Recebidos   ████████████████████  45            │    │
│          │  │  Em Analise  ██████                 8            │    │
│          │  │  Aprovados   █████████████████     38            │    │
│          │  │  Faturados   ████████████████      35            │    │
│          │  │  Enviados    ██████████            22            │    │
│          │  │  Entregues   ████████              18            │    │
│          │  │                                                  │    │
│          │  └──────────────────────────────────────────────────┘    │
│          │                                                          │
└──────────┴──────────────────────────────────────────────────────────┘
```

---

## 12. Portal Financeiro — Analise de Credito

```
┌─────────────────────────────────────────────────────────────────────┐
│ ★ BOXER  Boxer Hub — Financeiro          🔔 1  Julia R. ▼    Sair│
├──────────┬──────────────────────────────────────────────────────────┤
│          │                                                          │
│ Menu     │  Analise de Credito — Distribuidora ABC Ltda            │
│          │                                                          │
│ Dashboard│  ┌── Dados do Cliente ────────────────────────────┐     │
│ Titulos  │  │  CNPJ: 12.345.678/0001-90                      │     │
│ Clientes │  │  Canal: Varejo  |  Porte: Medio                │     │
│ Credito  │  │  Limite atual: R$ 50.000                       │     │
│ NFs      │  │  Disponivel: R$ 22.000  |  Vencidos: R$ 0     │     │
│          │  └─────────────────────────────────────────────────┘     │
│          │                                                          │
│          │  ┌── Bureau de Credito ────────────────────────────┐    │
│          │  │  Serasa Score: 720 / 1000  (Bom)                │    │
│          │  │  Restricoes: Nenhuma                             │    │
│          │  │  Consultado em: 10/08/2026                       │    │
│          │  │  [ Consultar Novamente ]                         │    │
│          │  └──────────────────────────────────────────────────┘    │
│          │                                                          │
│          │  ┌── Historico ────────────────────────────────────┐     │
│          │  │  Compras (12 meses): R$ 180.000                │     │
│          │  │  Media mensal: R$ 15.000                        │     │
│          │  │  Atrasos: 0 nos ultimos 12 meses               │     │
│          │  │  Pagamento medio: 3 dias antes do vencimento   │     │
│          │  └─────────────────────────────────────────────────┘     │
│          │                                                          │
│          │  ┌── Documentos Enviados ─────────────────────────┐     │
│          │  │  📄 Balanco 2025.pdf          [ Visualizar ]    │     │
│          │  │  📄 DRE 2025.pdf              [ Visualizar ]    │     │
│          │  └──────────────────────────────────────────────────┘    │
│          │                                                          │
│          │  ┌── Solicitacao ─────────────────────────────────┐     │
│          │  │  Valor solicitado: R$ 80.000                    │     │
│          │  │                                                 │     │
│          │  │  Valor aprovado:  ( R$ 80.000               )  │     │
│          │  │  Justificativa:   ( Historico excelente, sem  ) │     │
│          │  │                   ( restricoes, score 720    ) │     │
│          │  │                                                 │     │
│          │  │  [ Reprovar ]  [ Aprovar Parcial ]  [ APROVAR ]│     │
│          │  └─────────────────────────────────────────────────┘     │
│          │                                                          │
└──────────┴──────────────────────────────────────────────────────────┘
```

---

## 13. Componentes Compartilhados

### Topbar
Presente em todos os portais. Conteudo varia conforme portal:

| Portal | Titulo | Elementos extras |
|---|---|---|
| Cliente | "Boxer Hub" | Notificacoes, perfil, sair |
| Representante | "Boxer Hub — Representante" | Seletor de proxy, notificacoes |
| ADM Vendas | "Boxer Hub — ADM" | Notificacoes, perfil |
| Financeiro | "Boxer Hub — Financeiro" | Notificacoes, perfil |

### Toast (Notificacao)
Aparece no canto superior direito apos acoes:
- Sucesso (verde): "Pedido enviado com sucesso"
- Erro (vermelho): "Credito insuficiente"
- Alerta (amarelo): "1 item em backorder"

### Modal
Usado para: segunda via de boleto, confirmacoes, formularios rapidos.

### Notificacao no Sino
Badge com contagem no icone de sino. Dropdown com lista de notificacoes recentes. Link para central completa de notificacoes.

---

*Documento sujeito a revisao e aprovacao antes do inicio do desenvolvimento.*
