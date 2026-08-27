-- Passo 0 — Normalizacao de SKU (fundacao)
-- O SKU e a chave de tres operacoes: join da categoria comercial,
-- match de fotos do PDM e o on_conflict do sync. Precisa ser normalizado
-- ANTES de qualquer uma delas.

-- 0a. Consolidar o SKU duplicado por espaco em branco ('99032 ' vs '99032').
--     O espaco furou o on_conflict=sku e criou dois produtos para o mesmo item.
DO $$
DECLARE
  v_sujo  uuid;
  v_limpo uuid;
BEGIN
  SELECT id INTO v_sujo  FROM comercial.hub_produtos WHERE sku = '99032 ';
  SELECT id INTO v_limpo FROM comercial.hub_produtos WHERE sku = '99032';

  IF v_sujo IS NULL THEN
    RETURN;
  END IF;

  -- Se so existe o sujo, basta limpar o valor
  IF v_limpo IS NULL THEN
    UPDATE comercial.hub_produtos SET sku = '99032' WHERE id = v_sujo;
    RETURN;
  END IF;

  -- Precos: apagar os que colidiriam com o canonico, mover o resto
  DELETE FROM comercial.hub_tabela_preco_itens t
   WHERE t.produto_id = v_sujo
     AND EXISTS (
       SELECT 1 FROM comercial.hub_tabela_preco_itens x
        WHERE x.produto_id = v_limpo
          AND x.tabela_preco_id = t.tabela_preco_id
     );
  UPDATE comercial.hub_tabela_preco_itens SET produto_id = v_limpo WHERE produto_id = v_sujo;

  UPDATE comercial.hub_produto_anexos SET produto_id = v_limpo WHERE produto_id = v_sujo;
  UPDATE comercial.hub_pedido_itens   SET produto_id = v_limpo WHERE produto_id = v_sujo;

  IF to_regclass('comercial.hub_campanha_produtos') IS NOT NULL THEN
    EXECUTE format(
      'UPDATE comercial.hub_campanha_produtos SET produto_id = %L WHERE produto_id = %L',
      v_limpo, v_sujo
    );
  END IF;

  DELETE FROM comercial.hub_produtos WHERE id = v_sujo;
END $$;

-- 0b. Normalizar todos os SKUs existentes
UPDATE comercial.hub_produtos
   SET sku = UPPER(TRIM(sku))
 WHERE sku IS DISTINCT FROM UPPER(TRIM(sku));

-- 0c. Impedir que SKU sujo volte a entrar
ALTER TABLE comercial.hub_produtos
  DROP CONSTRAINT IF EXISTS hub_produtos_sku_normalizado;
ALTER TABLE comercial.hub_produtos
  ADD CONSTRAINT hub_produtos_sku_normalizado
  CHECK (sku = UPPER(TRIM(sku)));

-- 0d. Indices para o join por SKU normalizado (hub <-> tabela de preco)
CREATE INDEX IF NOT EXISTS idx_hub_produtos_sku_norm
  ON comercial.hub_produtos (UPPER(TRIM(sku)));

CREATE INDEX IF NOT EXISTS idx_precos_produtos_codigo_norm
  ON public.produtos (UPPER(TRIM(codigo)));
