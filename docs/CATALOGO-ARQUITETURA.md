# Catálogo — Arquitetura de Categorias e Fotos

Estado verificado em 2026-08-27. Substitui `ESTADO-FINAL-CATALOGO.md` e
`MUDANCAS-VIEW-CATEGORIAS.md`, que se contradiziam e afirmavam cobertura de
fotos que nunca existiu.

---

## Categoria — vem da tabela de preço, não do PDM

A tabela de preços vive no **schema `public` do mesmo projeto Supabase**:

| Objeto | Conteúdo |
|---|---|
| `public.tabelas` | 1 = Principal, 2 = Automação, 3 = Revendas Teste |
| `public.produtos` | `codigo`, `categoria_id`, `pv_sp`, `tabela_id` |
| `public.categorias` | INVERSORAS, MULTI PROCESSO, TIG, MÁSCARAS, … |

`hub_v_catalogo` faz o join por SKU normalizado:

```
hub_produtos.sku → public.produtos.codigo → public.categorias.nome
```

### Somente a tabela Principal (`tabela_id = 1`)

**Automação é venda para cliente final, não para revenda** — não pode ser
comprada pelo revendedor no Hub (regra confirmada em 2026-08-27). A tabela 3
("Revendas Teste") é cópia de teste e também fica de fora.

A regra é de inclusão, não de exclusão: **se o produto está na Principal, ele
aparece** — mesmo que também exista na Automação. Os 30 SKUs presentes nas duas
tabelas continuam no catálogo, com o preço da Principal. Só saem os 23
exclusivos da Automação (mesas posicionadoras, tochas robóticas, fontes para
robô, lasers LQ, chiller).

Por isso `CONSUMÍVEIS LASER` e `CONSUMÍVEIS TOCHAS ROBÔ` permanecem: são peças
de reposição listadas na Principal.

Se a Automação um dia entrar no Hub, o caminho **não** é reabrir o filtro para
todos — é segmentar por perfil de cliente.

O join é `JOIN`, não `LEFT JOIN`: produto sem tabela de preço não aparece no
catálogo (ADR-004 — a tabela de preços é a fonte oficial).

**Ausência da tabela de preço significa fora de linha** (confirmado em
2026-08-27). Não é lacuna de cadastro: produtos descontinuados saem da tabela e,
por consequência, do catálogo. Entre eles há itens com foto e cadastro no PDM —
tochas S335/S535, refrigeradores LQ1500/LQ2000 — o que pode parecer erro à
primeira vista, mas é o comportamento correto.

`comercial.hub_categorias` (taxonomia do PDM) **não alimenta mais o catálogo**.
Ela tem nomes duplicados em pais diferentes ("Grandes" 4×, "Acessórios de
solda" 6×) porque o `catLookup` do sync indexava por nome, não por slug.

### Agrupamento e ordem — `comercial.hub_categoria_config`

Máquinas no topo, consumíveis e acessórios no fim. A ordem é decisão comercial e
muda com o tempo, então vive numa **tabela**, não num `CASE` na view: mudar a
ordem ou ocultar uma categoria é um `UPDATE`, sem migration nem deploy.

| # | Grupo | Produtos |
|---|---|---|
| 1 | Máquinas | 53 |
| 2 | Automação | — (inativo, ver acima) |
| 3 | Proteção | 18 |
| 4 | Tochas | 39 |
| 5 | Acessórios | 108 |
| 6 | Consumíveis | 207 |
| 7 | Peças *(oculto)* | 135 |

Total: 425 na vitrine + 135 ocultos = **560**.

> **Por que não usar `public.categorias.ordem`:** ela numera **por tabela de
> preço**. Principal e Automação ambas começavam em 0, então LASER e ROBÔS
> apareciam embaralhados no meio das máquinas. Não era ordenação faltando — era
> colisão de numeração.

O `LEFT JOIN` na config é proposital: categoria nova cai em "Outros" no fim, em
vez de sumir do catálogo.

### Navegação em dois níveis

28 categorias não cabem numa linha de chips — cortavam na borda (MÁSCARAS
aparecia pela metade). O front mostra 6 chips de grupo com `flex-wrap` e, abaixo,
as categorias do grupo selecionado. Grupo com categoria única seleciona direto,
sem sub-chip redundante.

### Categorias ocultas

`VISTA EXPLODIDA *` (135 produtos, peças de reposição) tem
`categoria_oculta = true` — vindo da config, não derivado do prefixo do nome.
O grupo "Peças" aparece nos chips com estilo discreto (tracejado, cinza):
acessível por escolha explícita ou por busca de código/nome, sem competir com as
categorias de venda.

---

## Fotos — PDM primeiro, SharePoint pendente

Ordem de prioridade gravada em `hub_produto_anexos`:

| prioridade | origem | renderizável |
|---|---|---|
| 1 | `pdm_produto` — PDM `produtos.imagem_url` | sim |
| 2 | `pdm_bom` — PDM `bom_itens.imagem_url` | sim |
| 90 | `sharepoint` | **não** |

### Por que o SharePoint não renderiza

As URLs estão no formato `:b:` (documento binário) e respondem **302** para o
login da Microsoft. Nunca funcionam como `<img src>`, com nenhuma CSP. São
preservadas no banco com `renderizavel = false` até o caminho definitivo ser
definido — **pendência aberta**.

### O bug que isso corrigiu

`STRING_AGG` sem `ORDER BY` ordena alfabeticamente pela URL. Como
`https://boxersoldasbr…` vem antes de `https://tufbuyfwy…`, o grid escolhia o
link quebrado do SharePoint enquanto o PDP — que ordenava por `ordem` —
escolhia a foto boa. Daí "aparece ícone no catálogo mas funciona ao clicar".

A view agora agrega com `ORDER BY prioridade, ordem, id` e filtra
`renderizavel = true`.

---

## Cobertura real de fotos

Medido em 2026-08-27, após o sync com paginação e prioridade de fonte:

| | |
|---|---|
| SKUs no catálogo | 560 |
| **Com foto exibível** | **91 (16,3%)** — do PDM e da BOM |
| Sem foto em nenhuma fonte | 469 |
| Anexos totais | 498 |

### Por que o painel admin mostra um número maior que o catálogo

Contam universos diferentes, e ambos estão certos:

- **102** — produtos com qualquer anexo foto, sobre os 691 de `hub_produtos`.
  É o acervo total, incluindo fora de linha e Automação. Decidido manter assim.
- **101** — descontando 1 produto cuja única foto é link SharePoint, que não
  renderiza.
- **91** — o que o revendedor vê: só a tabela Principal.

A diferença são produtos fora de linha ou de Automação que ainda têm foto e
cadastro no PDM. **Não é erro de sync.**

**Teto imposto pela origem, não pelo código:** o PDM tem 280 produtos; o
catálogo tem 560. A maior parte dos SKUs do catálogo não existe no PDM. As 1.576
fotos de `bom_itens` são de componentes internos (relés, IGBTs, placas) — servem
para peças de reposição, não para produtos acabados.

Aumentar a cobertura é trabalho de conteúdo: cadastrar no PDM ou migrar os
204 arquivos do SharePoint para o Supabase Storage.

---

## SKU — normalizado em todo match

`UPPER(TRIM(sku))`, com `CHECK` constraint em `hub_produtos`.

Um único espaço sobrando (`'99032 '`) furou o `on_conflict=sku` e criou dois
produtos para o mesmo item. Consolidado na migration
`20260826180000_passo0_normalizar_sku.sql`.

---

## Estoque

`estoque_disponivel = 0` em **100% dos produtos** — o conector ZEN nunca
populou o campo. A view retorna `status_estoque = 'sem_info'` nesse caso e o
front omite o selo, em vez de marcar o catálogo inteiro como indisponível.

Quando o ZEN passar a sincronizar, os valores `disponivel` / `baixo` /
`indisponivel` voltam a valer sozinhos.

---

## Segurança dos anexos

RLS em `hub_produto_anexos`:

| policy | quem | o quê |
|---|---|---|
| `hub_anexos_select_publico` | authenticated | `foto`, `catalogo`, `manual` |
| `hub_anexos_select_interno` | analyst/manager/financial/admin | tudo |

Havia uma policy `hub_anexos_select` com `USING (auth.uid() IS NOT NULL)` que
liberava **todos** os anexos para qualquer usuário logado. Como policies
permissivas se combinam com OR, ela anulava a proteção. Removida.

Verificado com usuário dealer real: `ficha_tecnica`, `fispq` e `certificado`
retornam 0 linhas; 377 de 470 anexos visíveis.

> Filtrar no front (`docs.filter(...)`) **não é controle de acesso** — a query
> trazia os dados e o navegador só escondia. O filtro por `tipo` agora está na
> query e na RLS.
