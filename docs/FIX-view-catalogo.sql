-- FIX: Recriar view hub_v_catalogo para retornar foto_paths corretamente
-- Problema: VIEW estava retornando foto_paths: null mesmo com fotos no banco
-- Solução: Agregar fotos corretamente com string_agg

DROP VIEW IF EXISTS comercial.hub_v_catalogo CASCADE;

CREATE OR REPLACE VIEW comercial.hub_v_catalogo AS
SELECT
  p.id AS produto_id,
  p.sku,
  p.nome,
  p.descricao,
  c.nome AS categoria_nome,
  c.id AS categoria_id,
  c.categoria_pai_id,
  p.estoque_disponivel,
  CASE
    WHEN p.estoque_disponivel > 0 THEN 'Disponível'
    WHEN p.estoque_disponivel = 0 THEN 'Fora de Estoque'
    ELSE 'Indisponível'
  END AS status_estoque,
  FALSE AS backorder_disponivel,
  NULL AS previsao_chegada,
  -- FIX: Agregar foto_paths corretamente
  STRING_AGG(DISTINCT a_foto.storage_path, ',') FILTER (WHERE a_foto.id IS NOT NULL) AS foto_paths,
  FALSE AS destaque
FROM comercial.hub_produtos p
LEFT JOIN comercial.hub_categorias c ON c.id = p.categoria_id
LEFT JOIN comercial.hub_produto_anexos a_foto ON a_foto.produto_id = p.id AND a_foto.tipo = 'foto'
WHERE p.ativo = true
GROUP BY p.id, p.sku, p.nome, p.descricao, c.nome, c.id, c.categoria_pai_id, p.estoque_disponivel
ORDER BY p.sku ASC;

-- Verificar que a view está retornando fotos
SELECT COUNT(*) as total_produtos,
       COUNT(CASE WHEN foto_paths IS NOT NULL THEN 1 END) as com_fotos
FROM comercial.hub_v_catalogo;
