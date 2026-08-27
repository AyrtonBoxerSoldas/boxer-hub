-- Passo 1 — Catalogo orientado pela categoria comercial da tabela de preco
--
-- Fonte da categoria: public.produtos.categoria_id -> public.categorias.nome
-- (tabela de precos, schema public do mesmo projeto).
-- Tabelas consideradas: 1 = Principal, 2 = Automacao.
-- A tabela 3 ("Revendas Teste") e copia de teste e fica de fora.
--
-- Efeitos:
--  * o JOIN (nao LEFT JOIN) remove os 107 produtos sem tabela de preco;
--  * comercial.hub_categorias (taxonomia do PDM, com nomes duplicados)
--    deixa de alimentar o catalogo;
--  * fotos passam a ser agregadas por prioridade de fonte, nao alfabeticamente.

DROP VIEW IF EXISTS comercial.hub_v_catalogo CASCADE;

CREATE VIEW comercial.hub_v_catalogo AS
WITH preco AS (
  -- Um SKU pode estar em mais de uma tabela; Principal (1) tem precedencia.
  SELECT DISTINCT ON (UPPER(TRIM(pp.codigo)))
         UPPER(TRIM(pp.codigo)) AS sku_norm,
         pc.nome                AS categoria_nome,
         pc.id                  AS categoria_id,
         pc.ordem               AS categoria_ordem,
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
  -- Avaliado uma unica vez: o conector ZEN ja populou estoque alguma vez?
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
  pr.categoria_ordem,
  -- Vista explodida = pecas de reposicao. Fora dos chips de navegacao,
  -- acessivel apenas por filtro explicito ou busca.
  (pr.categoria_nome LIKE 'VISTA EXPLODIDA%') AS categoria_oculta,

  p.estoque_disponivel,
  -- O conector ZEN ainda nao popula estoque (0 em 100% dos produtos).
  -- 'sem_info' evita marcar todo o catalogo como indisponivel em vermelho.
  CASE
    WHEN NOT es.tem_dado                                  THEN 'sem_info'
    WHEN p.estoque_disponivel IS NULL                     THEN 'sem_info'
    WHEN p.estoque_disponivel > COALESCE(p.estoque_minimo, 0) THEN 'disponivel'
    WHEN p.estoque_disponivel > 0                         THEN 'baixo'
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
LEFT JOIN fotos f ON f.produto_id = p.id
WHERE p.ativo = true;

GRANT SELECT ON comercial.hub_v_catalogo TO anon, authenticated;
