-- Prepara hub_pedidos para o push do pedido ao ZEN (decisao ja registrada em
-- docs/INTEGRACAO-ZEN-HUB.md: "Zen dono a partir da submissao"). So a coluna
-- por enquanto -- o conector de escrita (push-pedido) so entra depois de
-- confirmar contra o ambiente real qual workflow/saleProfile usar.
ALTER TABLE comercial.hub_pedidos
  ADD COLUMN IF NOT EXISTS erp_pedido_id       text,
  ADD COLUMN IF NOT EXISTS erp_tipo            text,
  ADD COLUMN IF NOT EXISTS erp_workflow_status text,
  ADD COLUMN IF NOT EXISTS erp_sincronizado_em timestamptz;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'hub_pedidos_erp_tipo_check') THEN
    ALTER TABLE comercial.hub_pedidos
      ADD CONSTRAINT hub_pedidos_erp_tipo_check
      CHECK (erp_tipo IS NULL OR erp_tipo IN ('quote', 'sale'));
  END IF;
END $$;

COMMENT ON COLUMN comercial.hub_pedidos.erp_pedido_id IS
  'id do Quote/Sale correspondente no ZEN. Nulo ate o push ser implementado.';
COMMENT ON COLUMN comercial.hub_pedidos.erp_workflow_status IS
  'Etapa de negocio como vem do workflow do ZEN (ex: Aguardando Limite) -- nao confundir com hub_pedidos.status.';
