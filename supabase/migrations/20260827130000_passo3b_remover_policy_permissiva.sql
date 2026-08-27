-- Passo 3b — Remover a policy que anulava a protecao das fichas tecnicas.
--
-- 'hub_anexos_select' usava USING (auth.uid() IS NOT NULL): qualquer usuario
-- autenticado lia TODOS os anexos. Como policies PERMISSIVE se combinam com OR,
-- ela tornava inuteis as policies criadas no passo 3 — um dealer continuaria
-- vendo ficha_tecnica, fispq e certificado.
--
-- Cobertura de leitura apos esta migration:
--   hub_anexos_select_publico  -> authenticated: foto, catalogo, manual
--   hub_anexos_select_interno  -> analyst/manager/financial/admin: tudo
-- Escrita (admin insert/update/delete) permanece inalterada.

DROP POLICY IF EXISTS hub_anexos_select ON comercial.hub_produto_anexos;
