-- Motor de preco do Hub ligado a BASE MESTRE (schema public).
--
-- Decisao do Andre (2026-08-31): "a tabela de precos e a base de dados mestre".
-- O modelo anterior (hub_clientes.tabela_preco_id -> hub_tabela_preco_itens)
-- mostrava UM preco unico para todo mundo e estava vinculado a 1 de 7.717
-- clientes. Errado: o preco publicado varia por ESTADO e por CANAL de venda.
--
-- Formula extraida do codigo da propria pagina mestre
-- (app.boxersoldas.com.br/tabela-de-precos.html), nao deduzida:
--
--   preco_tabela = pv_sp * mult_4_icms / (1 - mult_total/100)
--   preco_final  = preco_tabela * multiplicador(segmento, classe, porte)
--
-- Validado contra a pagina com dado real: produto 1510026 em SP, Fisica,
-- classe 3 -> tabela R$358,34 e com desconto R$354,75. Bate exatamente.
--
-- Fontes (schema public, somente leitura pelo Hub -- sao a base mestre
-- compartilhada com a pagina de tabela de precos, NAO alterar por aqui):
--   public.produtos       pv_sp, porte, icms, ipi (tabela_id=1 = "Principal")
--   public.estados        mult_4_icms, mult_total por UF
--   public.multiplicadores  valor por segmento x classe x porte [x categoria_grupo]

-- ---------------------------------------------------------------------------
-- Classe comercial: override opcional definido pelo analista/admin.
-- Quando nulo, a classe e derivada pela regra da politica (ver hub_fn_classe).
ALTER TABLE comercial.hub_clientes
  ADD COLUMN IF NOT EXISTS classe_comercial smallint;

COMMENT ON COLUMN comercial.hub_clientes.classe_comercial IS
  'Override da classe comercial (1/2/3) definido pelo analista. Nulo = derivar pela regra da politica.';

-- ---------------------------------------------------------------------------
-- canal (Zen) -> segmento (politica comercial).
-- Confirmado com o Andre em 2026-08-28: Varejo no Zen = FISICA na politica.
CREATE OR REPLACE FUNCTION comercial.hub_fn_segmento(p_canal text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE lower(coalesce(trim(p_canal), ''))
           WHEN 'varejo'    THEN 'Física'
           WHEN 'fisica'    THEN 'Física'
           WHEN 'física'    THEN 'Física'
           WHEN 'hibrido'   THEN 'Híbrido'
           WHEN 'híbrido'   THEN 'Híbrido'
           WHEN 'ecommerce' THEN 'Ecommerce'
           ELSE NULL
         END;
$$;

COMMENT ON FUNCTION comercial.hub_fn_segmento(text) IS
  'Traduz hub_clientes.canal (vocabulario do Zen) para o segmento da politica comercial.';

-- ---------------------------------------------------------------------------
-- Classe comercial segundo a politica de revendas V2 (28/07/2026).
--
--   FISICA    -> depende do VALOR DO PEDIDO ATUAL:
--                > R$20.000 classe 1 | > R$7.000 classe 2 | senao classe 3
--   ECOMMERCE
--   HIBRIDO   -> classe 1 exige ter comprado R$175.000 nos ultimos 3 meses.
--                O Hub ainda nao sincroniza historico de compras do Zen, entao
--                sem override cai na classe 2 (a mais cara). E deliberado:
--                classe 1 e o preco melhor e precisa ser comprovado -- na
--                duvida o sistema nunca concede desconto nao comprovado.
--
-- O valor do pedido usado aqui e o subtotal a PRECO DE TABELA (antes do
-- multiplicador). Usar o preco final criaria circularidade: desconto maior
-- baixa o valor, que baixaria a classe, que reduz o desconto. A preco de
-- tabela a faixa e estavel e monotonica.
CREATE OR REPLACE FUNCTION comercial.hub_fn_classe(p_cliente_id uuid, p_valor_pedido numeric DEFAULT 0)
RETURNS smallint
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
  v_override smallint;
  v_segmento text;
BEGIN
  SELECT c.classe_comercial, comercial.hub_fn_segmento(c.canal)
    INTO v_override, v_segmento
    FROM comercial.hub_clientes c
   WHERE c.id = p_cliente_id;

  IF v_override IS NOT NULL THEN
    RETURN v_override;
  END IF;

  IF v_segmento = 'Física' THEN
    RETURN CASE
             WHEN coalesce(p_valor_pedido, 0) > 20000 THEN 1
             WHEN coalesce(p_valor_pedido, 0) > 7000  THEN 2
             ELSE 3
           END;
  END IF;

  -- Ecommerce / Hibrido sem comprovacao de historico
  RETURN 2;
END $$;

COMMENT ON FUNCTION comercial.hub_fn_classe(uuid, numeric) IS
  'Classe comercial do cliente. Override manual vence; senao aplica a regra da politica V2.';

-- ---------------------------------------------------------------------------
-- Precos de todo o catalogo para um cliente, ja no seu estado e canal.
-- Uma chamada so -- o catalogo precisa de ~560 precos de uma vez.
--
-- p_valor_pedido permite recalcular a faixa conforme o carrinho cresce
-- (Fisica): com 0 devolve o preco publicado (a faixa mais cara).
CREATE OR REPLACE FUNCTION comercial.hub_fn_precos_cliente(
  p_cliente_id   uuid,
  p_valor_pedido numeric DEFAULT 0
)
RETURNS TABLE (
  produto_id    uuid,
  sku           text,
  preco_tabela  numeric,
  preco_final   numeric,
  multiplicador numeric,
  classe        smallint,
  segmento      text,
  uf            text,
  porte         text,
  icms          numeric,
  ipi           numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
  v_uf       text;
  v_segmento text;
  v_classe   smallint;
BEGIN
  IF NOT comercial.hub_pode_acessar_cliente(p_cliente_id) THEN
    RETURN;
  END IF;

  SELECT c.uf, comercial.hub_fn_segmento(c.canal)
    INTO v_uf, v_segmento
    FROM comercial.hub_clientes c
   WHERE c.id = p_cliente_id AND c.ativo = true;

  IF v_uf IS NULL OR v_segmento IS NULL THEN
    RETURN; -- sem UF ou canal nao ha preco publicavel; o front avisa
  END IF;

  v_classe := comercial.hub_fn_classe(p_cliente_id, p_valor_pedido);

  RETURN QUERY
  WITH base AS (
    SELECT hp.id AS produto_id,
           hp.sku::text AS sku,
           pp.pv_sp,
           pp.porte::text AS porte,
           pp.icms,
           pp.ipi,
           vc.categoria_grupo,
           est.mult_4_icms,
           est.mult_total
      FROM comercial.hub_produtos hp
      JOIN public.produtos pp
        ON upper(btrim(pp.codigo)) = upper(btrim(hp.sku))
       AND pp.tabela_id = 1
       AND pp.ativo = true
       AND pp.pv_sp > 0
      LEFT JOIN comercial.hub_v_catalogo vc ON vc.produto_id = hp.id
      CROSS JOIN LATERAL (
        SELECT e.mult_4_icms, e.mult_total
          FROM public.estados e
         WHERE e.uf = v_uf
         LIMIT 1
      ) est
     WHERE hp.ativo = true
  )
  SELECT b.produto_id,
         b.sku,
         round(b.pv_sp * b.mult_4_icms / (1 - b.mult_total / 100), 2)              AS preco_tabela,
         round(b.pv_sp * b.mult_4_icms / (1 - b.mult_total / 100) * m.valor, 2)    AS preco_final,
         m.valor,
         v_classe,
         v_segmento,
         v_uf,
         b.porte,
         b.icms,
         b.ipi
    FROM base b
    CROSS JOIN LATERAL (
      -- multiplicador especifico da categoria vence o generico ("(todos)")
      SELECT mm.valor
        FROM public.multiplicadores mm
       WHERE mm.tabela_id = 1
         AND mm.segmento  = v_segmento
         AND mm.classe    = v_classe
         AND mm.porte     = b.porte
         AND (mm.categoria_grupo IS NULL OR mm.categoria_grupo = b.categoria_grupo)
       ORDER BY mm.categoria_grupo NULLS LAST
       LIMIT 1
    ) m;
END $$;

COMMENT ON FUNCTION comercial.hub_fn_precos_cliente(uuid, numeric) IS
  'Precos do catalogo para um cliente, no seu estado e canal, lidos da base mestre (schema public).';

GRANT EXECUTE ON FUNCTION comercial.hub_fn_segmento(text)        TO authenticated;
GRANT EXECUTE ON FUNCTION comercial.hub_fn_classe(uuid, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION comercial.hub_fn_precos_cliente(uuid, numeric) TO authenticated;

-- ---------------------------------------------------------------------------
-- Preco de UM item, no contrato jsonb que o carrinho ja consome.
-- Passa a ler a base mestre em vez de hub_tabela_preco_itens.
--
-- A versao antiga tinha 3 argumentos; a nova tem 4 (o ultimo com default).
-- Sem remover a antiga, uma chamada com 3 argumentos ficaria ambigua e o
-- Postgres recusaria com "function is not unique".
DROP FUNCTION IF EXISTS comercial.hub_fn_calcular_preco(uuid, uuid, integer);

CREATE OR REPLACE FUNCTION comercial.hub_fn_calcular_preco(
  p_cliente_id uuid,
  p_produto_id uuid,
  p_quantidade integer DEFAULT 1,
  p_valor_pedido numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
  v_row   record;
  v_promo record;
  v_preco numeric(12,2);
BEGIN
  IF NOT comercial.hub_pode_acessar_cliente(p_cliente_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Acesso negado');
  END IF;

  SELECT * INTO v_row
    FROM comercial.hub_fn_precos_cliente(p_cliente_id, p_valor_pedido) f
   WHERE f.produto_id = p_produto_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false,
      'erro', 'Produto sem preco publicado para o estado/canal deste cliente');
  END IF;

  v_preco := v_row.preco_final;

  -- Campanha promocional ativa sobrepoe o preco da tabela.
  SELECT cp.preco_promocional, cp.desconto_percentual
    INTO v_promo
    FROM comercial.hub_campanha_produtos cp
    JOIN comercial.hub_campanhas ca ON ca.id = cp.campanha_id
   WHERE cp.produto_id = p_produto_id
     AND ca.ativo = true
     AND current_date BETWEEN ca.data_inicio AND ca.data_fim
     AND (cp.quantidade_limite IS NULL OR cp.quantidade_vendida < cp.quantidade_limite)
   ORDER BY ca.data_inicio DESC
   LIMIT 1;

  IF FOUND THEN
    IF v_promo.preco_promocional IS NOT NULL THEN
      v_preco := v_promo.preco_promocional;
    ELSIF v_promo.desconto_percentual IS NOT NULL THEN
      v_preco := v_row.preco_final * (1 - v_promo.desconto_percentual / 100);
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'preco_base',  v_row.preco_tabela,
    'preco_final', v_preco,
    'multiplicador', v_row.multiplicador,
    'classe',      v_row.classe,
    'segmento',    v_row.segmento,
    'uf',          v_row.uf,
    'porte',       v_row.porte,
    'ipi',         v_row.ipi,
    'icms',        v_row.icms,
    'em_promocao', FOUND,
    'subtotal',    round(v_preco * p_quantidade, 2)
  );
END $$;

COMMENT ON FUNCTION comercial.hub_fn_calcular_preco(uuid, uuid, integer, numeric) IS
  'Preco de um item para o cliente, lido da base mestre (public.produtos/estados/multiplicadores).';

GRANT EXECUTE ON FUNCTION comercial.hub_fn_calcular_preco(uuid, uuid, integer, numeric) TO authenticated;
