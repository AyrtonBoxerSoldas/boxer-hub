-- Passo 2 — Prioridade de fonte para fotos
--
-- Regra de negocio: PDM sempre primeiro. SharePoint so depois, e enquanto
-- o caminho correto nao for definido ele nao pode ir para o <img>.
--
-- Motivo tecnico: os links do SharePoint estao no formato ":b:" (documento
-- binario) e respondem 302 para o login da Microsoft. Nunca renderizam como
-- imagem. Sao preservados no banco, mas marcados como nao-renderizaveis.

ALTER TABLE comercial.hub_produto_anexos
  ADD COLUMN IF NOT EXISTS origem       text,
  ADD COLUMN IF NOT EXISTS prioridade   smallint NOT NULL DEFAULT 99,
  ADD COLUMN IF NOT EXISTS renderizavel boolean  NOT NULL DEFAULT true;

COMMENT ON COLUMN comercial.hub_produto_anexos.origem IS
  'pdm_produto | pdm_bom | sharepoint | upload';
COMMENT ON COLUMN comercial.hub_produto_anexos.prioridade IS
  '1=PDM produtos.imagem_url, 2=PDM bom_itens.imagem_url, 90=SharePoint (pendente)';
COMMENT ON COLUMN comercial.hub_produto_anexos.renderizavel IS
  'false = URL nao serve como <img src>. Fica no banco mas fora do catalogo.';

-- Classificar o que ja existe.
-- ordem=0 foi gravado pelo sync a partir de produtos.imagem_url;
-- ordem=1 veio dos documentos Artworks (SharePoint).
UPDATE comercial.hub_produto_anexos
   SET origem = CASE
         WHEN storage_path ILIKE '%sharepoint.com%'  THEN 'sharepoint'
         WHEN storage_path ILIKE '%supabase.co%'
              AND ordem = 0                          THEN 'pdm_produto'
         WHEN storage_path ILIKE '%supabase.co%'     THEN 'pdm_bom'
         ELSE 'upload'
       END,
       prioridade = CASE
         WHEN storage_path ILIKE '%sharepoint.com%'  THEN 90
         WHEN storage_path ILIKE '%supabase.co%'
              AND ordem = 0                          THEN 1
         WHEN storage_path ILIKE '%supabase.co%'     THEN 2
         ELSE 50
       END,
       renderizavel = (storage_path NOT ILIKE '%sharepoint.com%');

CREATE INDEX IF NOT EXISTS idx_hub_anexos_foto_prio
  ON comercial.hub_produto_anexos (produto_id, prioridade, ordem)
  WHERE tipo = 'foto' AND renderizavel = true;
