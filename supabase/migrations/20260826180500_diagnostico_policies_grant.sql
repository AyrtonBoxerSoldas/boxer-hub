-- O REVOKE ... FROM PUBLIC da migration anterior tambem removeu o acesso do
-- service_role (que herda de PUBLIC). Concede de volta apenas a ele.
GRANT EXECUTE ON FUNCTION comercial.hub_debug_policies() TO service_role;
