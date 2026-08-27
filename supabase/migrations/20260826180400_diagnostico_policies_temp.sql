-- Funcao TEMPORARIA de diagnostico de RLS.
-- Removida pela migration seguinte. Existe apenas para inspecionar as policies
-- ja existentes antes de confiar na protecao das fichas tecnicas.
CREATE OR REPLACE FUNCTION comercial.hub_debug_policies()
RETURNS TABLE (tabela text, policy_nome text, cmd text, permissiva text, papeis text, expressao text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT p.tablename::text,
         p.policyname::text,
         p.cmd::text,
         p.permissive::text,
         array_to_string(p.roles, ','),
         COALESCE(p.qual, '')
    FROM pg_policies p
   WHERE p.schemaname = 'comercial'
     AND p.tablename IN ('hub_produto_anexos', 'hub_produtos')
   ORDER BY p.tablename, p.policyname;
$$;

REVOKE ALL ON FUNCTION comercial.hub_debug_policies() FROM PUBLIC, anon, authenticated;
