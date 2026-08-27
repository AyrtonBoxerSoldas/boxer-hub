-- Passo 3 — Fichas tecnicas fora do alcance do cliente
--
-- Ate agora o filtro existia apenas no front (catalogo.html escondia os
-- documentos na renderizacao), mas a query trazia 'select=*'. Qualquer
-- revendedor via as 93 fichas tecnicas na aba Network do navegador.
-- Esconder no JS nao e controle de acesso.
--
-- Regra: dealer e representante veem apenas foto, catalogo e manual.
-- Funcionario Boxer (analyst/manager/financial/admin) ve tudo.

ALTER TABLE comercial.hub_produto_anexos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS hub_anexos_select_publico  ON comercial.hub_produto_anexos;
DROP POLICY IF EXISTS hub_anexos_select_interno  ON comercial.hub_produto_anexos;

-- Cliente / representante: somente tipos publicos
CREATE POLICY hub_anexos_select_publico
  ON comercial.hub_produto_anexos
  FOR SELECT
  TO authenticated
  USING (
    tipo IN ('foto', 'catalogo', 'manual')
  );

-- Funcionario Boxer: acesso completo (inclui ficha_tecnica, fispq, certificado)
CREATE POLICY hub_anexos_select_interno
  ON comercial.hub_produto_anexos
  FOR SELECT
  TO authenticated
  USING (
    comercial.hub_user_role() IN ('analyst', 'manager', 'financial', 'admin')
  );
