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

Somente `tabela_id IN (1, 2)`. **A tabela 3 é cópia de teste e fica de fora** —
se um dia virar produção, a regra precisa ser explicitada, não deduzida.

O join é `JOIN`, não `LEFT JOIN`: produto sem tabela de preço não aparece no
catálogo (ADR-004 — a tabela de preços é a fonte oficial). Hoje isso exclui
**107 produtos**.

**Ausência da tabela de preço significa fora de linha** (confirmado em
2026-08-27). Não é lacuna de cadastro: produtos descontinuados saem da tabela e,
por consequência, do catálogo. Entre eles há itens com foto e cadastro no PDM —
tochas S335/S535, refrigeradores LQ1500/LQ2000 — o que pode parecer erro à
primeira vista, mas é o comportamento correto.

`comercial.hub_categorias` (taxonomia do PDM) **não alimenta mais o catálogo**.
Ela tem nomes duplicados em pais diferentes ("Grandes" 4×, "Acessórios de
solda" 6×) porque o `catLookup` do sync indexava por nome, não por slug.

### Categorias ocultas

`VISTA EXPLODIDA *` (135 produtos, peças de reposição) tem
`categoria_oculta = true`. Fora dos chips principais; acessível por filtro
explícito ou busca por código/nome.

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
| SKUs no catálogo | 583 |
| **Com foto exibível** | **95 (16,3%)** — 73 do PDM, 28 da BOM |
| Sem foto em nenhuma fonte | 488 |
| Anexos totais | 498 |

### Por que o painel admin mostra 102 e o catálogo 95

Contam universos diferentes, e ambos estão certos:

- **102** — produtos com qualquer anexo foto, sobre os 691 de `hub_produtos`.
  É o acervo total, incluindo fora de linha. Decidido manter assim.
- **101** — descontando 1 produto cuja única foto é link SharePoint, que não
  renderiza.
- **95** — o que o revendedor vê: apenas produtos na tabela de preço.

Os 6 de diferença são produtos fora de linha que ainda têm foto e cadastro no
PDM.

**Teto imposto pela origem, não pelo código:** o PDM tem 280 produtos; o
catálogo tem 583. 422 SKUs não existem no PDM. As 1.576 fotos de `bom_itens`
são de componentes internos (relés, IGBTs, placas) — servem para peças de
reposição, não para produtos acabados.

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
