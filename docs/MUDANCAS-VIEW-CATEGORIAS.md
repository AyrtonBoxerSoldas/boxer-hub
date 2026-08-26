# Mudanças na VIEW hub_v_catalogo

## Data
2026-08-26

## Alteração
A VIEW `comercial.hub_v_catalogo` foi recriada para usar **categorias da tabela de preços** ao invés de categorias do PDM.

## Antes
```sql
-- Categoria vinha de hub_categorias (do PDM)
LEFT JOIN comercial.hub_categorias c ON c.id = p.categoria_id
SELECT ... c.nome AS categoria_nome, c.id AS categoria_id
```

**Resultado:** Categorias como "Tochas", "Máscaras", "Automação/Laser" (do PDM/sistema original)

## Depois
```sql
-- Categoria vem da tabela de preço
JOIN comercial.hub_tabela_preco_itens tpi ON tpi.produto_id = p.id
JOIN comercial.hub_tabela_precos tp ON tp.id = tpi.tabela_preco_id
SELECT ... tp.nome AS categoria_nome, tp.id AS categoria_id
```

**Resultado:** Categorias como "Principal", "Automação" (conforme organizado na tabela de preços)

## Impacto
- ✅ Produtos aparecem na categoria CORRETA (conforme tabela de preços)
- ✅ Um produto pode aparecer em apenas UMA categoria (a da sua tabela de preço)
- ✅ Fotos continuam funcionando normalmente

## Exemplos
| SKU | Antes | Depois |
|-----|-------|--------|
| 100134 | Tochas | Principal |
| 1005025 | Grandes | Principal |
| 7005004 | Máscaras | Principal |
| 99968 | Automação/Laser | Automação |
| 99969 | Automação/Laser | Automação |

## Query SQL Aplicada
```sql
DROP VIEW IF EXISTS comercial.hub_v_catalogo CASCADE;

CREATE OR REPLACE VIEW comercial.hub_v_catalogo AS
SELECT DISTINCT ON (p.id)
  p.id AS produto_id,
  p.sku,
  p.nome,
  p.descricao,
  tp.nome AS categoria_nome,
  tp.id AS categoria_id,
  NULL::uuid AS categoria_pai_id,
  p.estoque_disponivel,
  CASE WHEN p.estoque_disponivel > 0 THEN 'Disponível' ELSE 'Indisponível' END AS status_estoque,
  FALSE AS backorder_disponivel,
  NULL AS previsao_chegada,
  STRING_AGG(DISTINCT a_foto.storage_path, ',') FILTER (WHERE a_foto.id IS NOT NULL) AS foto_paths,
  FALSE AS destaque,
  p.ativo
FROM comercial.hub_produtos p
JOIN comercial.hub_tabela_preco_itens tpi ON tpi.produto_id = p.id
JOIN comercial.hub_tabela_precos tp ON tp.id = tpi.tabela_preco_id
LEFT JOIN comercial.hub_produto_anexos a_foto ON a_foto.produto_id = p.id AND a_foto.tipo = 'foto'
WHERE p.ativo = true AND tp.ativo = true
GROUP BY p.id, p.sku, p.nome, p.descricao, tp.nome, tp.id, p.estoque_disponivel, p.ativo
ORDER BY p.id, tp.id;
```
