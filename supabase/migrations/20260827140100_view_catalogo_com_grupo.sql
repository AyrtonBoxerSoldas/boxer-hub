-- hub_v_catalogo passa a expor grupo e ordem vindos de hub_categoria_config.
--
-- categoria_oculta deixa de ser derivada do prefixo 'VISTA EXPLODIDA%' e passa
-- a vir da configuracao — assim ocultar uma categoria nova nao exige migration.
-- LEFT JOIN na config: categoria nova aparece no fim, em "Outros", em vez de
-- sumir do catalogo.

-- CREATE OR REPLACE nao permite inserir coluna no meio da lista; e preciso
-- recriar. Nada depende desta view (o front consulta via PostgREST).
DROP VIEW IF EXISTS comercial.hub_v_catalogo CASCADE;

CREATE VIEW comercial.hub_v_catalogo AS
WITH preco AS (
  SELECT DISTINCT ON (UPPER(TRIM(pp.codigo)))
         UPPER(TRIM(pp.codigo)) AS sku_norm,
         pc.nome                AS categoria_nome,
         pc.id                  AS categoria_id,
         pp.tabela_id
    FROM public.produtos   pp
    JOIN public.categorias pc ON pc.id = pp.categoria_id
   WHERE pp.ativo = true
     AND pp.tabela_id IN (1, 2)
   ORDER BY UPPER(TRIM(pp.codigo)), pp.tabela_id
),
fotos AS (
  SELECT produto_id,
         STRING_AGG(storage_path, ',' ORDER BY prioridade, ordem, id) AS foto_paths,
         COUNT(*)                                                     AS foto_count
    FROM comercial.hub_produto_anexos
   WHERE tipo = 'foto'
     AND renderizavel = true
   GROUP BY produto_id
),
estoque_sync AS (
  SELECT EXISTS (
           SELECT 1 FROM comercial.hub_produtos WHERE estoque_disponivel > 0
         ) AS tem_dado
)
SELECT
  p.id                AS produto_id,
  p.sku,
  p.nome,
  p.descricao,
  p.ncm,
  p.unidade,
  p.peso_bruto,
  p.ficha_tecnica,
  p.o_que_acompanha,

  pr.categoria_nome,
  pr.categoria_id,
  COALESCE(cc.grupo, 'Outros')     AS categoria_grupo,
  COALESCE(cc.grupo_ordem, 99)     AS categoria_grupo_ordem,
  COALESCE(cc.ordem, 99)           AS categoria_ordem,
  COALESCE(cc.oculta, false)       AS categoria_oculta,

  p.estoque_disponivel,
  CASE
    WHEN NOT es.tem_dado                                      THEN 'sem_info'
    WHEN p.estoque_disponivel IS NULL                         THEN 'sem_info'
    WHEN p.estoque_disponivel > COALESCE(p.estoque_minimo, 0) THEN 'disponivel'
    WHEN p.estoque_disponivel > 0                             THEN 'baixo'
    ELSE 'indisponivel'
  END AS status_estoque,

  false               AS backorder_disponivel,
  p.previsao_chegada,
  f.foto_paths,
  COALESCE(f.foto_count, 0) AS foto_count,
  p.destaque,
  p.ativo
FROM comercial.hub_produtos p
CROSS JOIN estoque_sync es
JOIN preco pr ON pr.sku_norm = UPPER(TRIM(p.sku))
LEFT JOIN comercial.hub_categoria_config cc
       ON cc.categoria_nome = pr.categoria_nome AND cc.ativo = true
LEFT JOIN fotos f ON f.produto_id = p.id
WHERE p.ativo = true;

GRANT SELECT ON comercial.hub_v_catalogo TO anon, authenticated;
