-- Catalogo restrito a tabela de preco Principal (tabela_id = 1)
--
-- Regra de negocio (2026-08-27): Automacao e venda para CLIENTE FINAL, nao para
-- revenda. Esses produtos podem existir na base, mas nao podem ser comprados
-- pelo revendedor no Hub.
--
-- Efeito: saem 23 SKUs exclusivos da Automacao (mesas posicionadoras, tochas
-- roboticas, fontes para robo, lasers LQ, chiller). Os 30 SKUs presentes nas
-- duas tabelas continuam no catalogo, com o preco da Principal.
--
-- Se um dia a Automacao entrar no Hub, o caminho nao e reabrir o filtro para
-- todos: e segmentar por perfil de cliente.

DROP VIEW IF EXISTS comercial.hub_v_catalogo CASCADE;

CREATE VIEW comercial.hub_v_catalogo AS
WITH preco AS (
  SELECT UPPER(TRIM(pp.codigo)) AS sku_norm,
         pc.nome                AS categoria_nome,
         pc.id                  AS categoria_id
    FROM public.produtos   pp
    JOIN public.categorias pc ON pc.id = pp.categoria_id
   WHERE pp.ativo = true
     AND pp.tabela_id = 1
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

-- O grupo Automacao fica sem produtos, mas a config permanece: se a regra
-- mudar, basta reabrir o filtro acima.
UPDATE comercial.hub_categoria_config
   SET ativo = false
 WHERE grupo = 'Automação';
