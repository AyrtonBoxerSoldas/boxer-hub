-- Campos necessarios para espelhar catalog.person.Person do Zen
--
-- Descobertos em 2026-08-27 via api/zen-explorar contra o ambiente real:
--   category1   = canal do cliente (Hibrido, Ecommerce, Varejo, Revenda, ...)
--   personGroup = grupo/rede (CASA DA LUVA, WL SOROCABA, LEROY MERLIN, ...)
--   tags        = string livre; 'blocked' ja e usada no Zen

ALTER TABLE comercial.hub_clientes
  ADD COLUMN IF NOT EXISTS grupo_nome    text,
  ADD COLUMN IF NOT EXISTS grupo_erp_id  integer,
  ADD COLUMN IF NOT EXISTS tags          text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS bloqueado     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS cidade        text,
  ADD COLUMN IF NOT EXISTS uf            text,
  ADD COLUMN IF NOT EXISTS sincronizado_em timestamptz;

COMMENT ON COLUMN comercial.hub_clientes.grupo_nome IS
  'personGroup do Zen. Quando existe, e por ele que o cliente e identificado na tela.';
COMMENT ON COLUMN comercial.hub_clientes.tags IS
  'Tags espelhadas do Zen (imported, customer, blocked, mercadolivre...). Usadas para sinalizar situacao do cliente.';
COMMENT ON COLUMN comercial.hub_clientes.bloqueado IS
  'Derivado da tag "blocked" no Zen. Bloqueado ve o catalogo mas nao fecha pedido.';

-- Nome de exibicao: grupo quando houver, senao o proprio cliente.
-- Coluna gerada — nao ha como a tela e o back divergirem na regra.
ALTER TABLE comercial.hub_clientes
  DROP COLUMN IF EXISTS nome_exibicao;
ALTER TABLE comercial.hub_clientes
  ADD COLUMN nome_exibicao text
  GENERATED ALWAYS AS (
    COALESCE(NULLIF(TRIM(grupo_nome), ''),
             NULLIF(TRIM(nome_fantasia), ''),
             razao_social)
  ) STORED;

-- CNPJ so digitos. O Zen entrega com mascara ('##.###.###/####-##') e o Hub
-- ja tinha os dois formatos convivendo — e a chave de casamento, entao precisa
-- ser canonica dos dois lados.
UPDATE comercial.hub_clientes
   SET cnpj = REGEXP_REPLACE(cnpj, '\D', '', 'g')
 WHERE cnpj IS DISTINCT FROM REGEXP_REPLACE(cnpj, '\D', '', 'g');

ALTER TABLE comercial.hub_clientes
  DROP CONSTRAINT IF EXISTS hub_clientes_cnpj_digitos;
ALTER TABLE comercial.hub_clientes
  ADD CONSTRAINT hub_clientes_cnpj_digitos
  CHECK (cnpj IS NULL OR cnpj ~ '^\d{11,14}$');

CREATE INDEX IF NOT EXISTS idx_hub_clientes_erp      ON comercial.hub_clientes (erp_cliente_id);
CREATE INDEX IF NOT EXISTS idx_hub_clientes_grupo    ON comercial.hub_clientes (grupo_nome);
CREATE INDEX IF NOT EXISTS idx_hub_clientes_canal    ON comercial.hub_clientes (canal);
CREATE INDEX IF NOT EXISTS idx_hub_clientes_tags     ON comercial.hub_clientes USING gin (tags);

-- erp_cliente_id e a chave do upsert do conector
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_clientes_erp
  ON comercial.hub_clientes (erp_cliente_id)
  WHERE erp_cliente_id IS NOT NULL;
