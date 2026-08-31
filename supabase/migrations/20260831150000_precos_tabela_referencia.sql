-- Preco de tabela (sem desconto) para quem nao esta atuando por uma revenda.
--
-- Representante e funcionario nao tem cliente_id, entao nao existe "o preco
-- deles". Ate agora a vitrine ficava sem preco nenhum para eles, o que era uma
-- regressao. Andre (2026-08-31): "podem ficar com preco de tabela, sem
-- desconto" -- e, quando escolherem uma revenda, passam a ver o preco dela
-- pelas regras da politica.
--
-- Dealer NAO chama esta funcao: ele tem que ver o preco praticado com ele, nao
-- a tabela cheia. Por isso o guard por tipo de usuario.
--
-- p_uf existe porque o preco de tabela ja varia por estado (ICMS). SP e o
-- default por ser a referencia -- pv_sp e literalmente o preco base em SP.

CREATE OR REPLACE FUNCTION comercial.hub_fn_precos_tabela(p_uf text DEFAULT 'SP')
RETURNS TABLE (
  produto_id   uuid,
  sku          text,
  preco_tabela numeric,
  icms         numeric,
  ipi          numeric,
  porte        text,
  uf           text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
  v_uf   text := upper(coalesce(nullif(btrim(p_uf), ''), 'SP'));
  v_tipo text := comercial.hub_user_tipo();
BEGIN
  IF v_tipo IS NULL OR v_tipo = 'cliente' THEN
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.estados e WHERE e.uf = v_uf) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT hp.id,
         hp.sku::text,
         round(pp.pv_sp * est.mult_4_icms / (1 - est.mult_total / 100), 2),
         pp.icms,
         pp.ipi,
         pp.porte::text,
         v_uf
    FROM comercial.hub_produtos hp
    JOIN public.produtos pp
      ON upper(btrim(pp.codigo)) = upper(btrim(hp.sku))
     AND pp.tabela_id = 1
     AND pp.ativo = true
     AND pp.pv_sp > 0
    CROSS JOIN LATERAL (
      SELECT e.mult_4_icms, e.mult_total FROM public.estados e WHERE e.uf = v_uf LIMIT 1
    ) est
   WHERE hp.ativo = true;
END $$;

COMMENT ON FUNCTION comercial.hub_fn_precos_tabela(text) IS
  'Preco de tabela por UF, sem multiplicador de classe. Para representante/funcionario sem revenda selecionada. Dealer nao acessa.';

GRANT EXECUTE ON FUNCTION comercial.hub_fn_precos_tabela(text) TO authenticated;
