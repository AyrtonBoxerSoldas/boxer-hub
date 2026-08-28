const HUB_URL = 'https://bmepxcnrsofofoswubuu.supabase.co';
const FUP_URL = 'https://agtzfllruggjbscuwdyi.supabase.co';
// Anon key do projeto FUP — publica por definicao (protegida por RLS), pode
// ficar no codigo do servidor. O que NAO pode viajar e o login (FUP_EMAIL/
// FUP_SENHA), que abre acesso de authenticated e libera as linhas na RLS.
const FUP_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFndHpmbGxydWdnamJzY3V3ZHlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NDQyMTcsImV4cCI6MjA5NzEyMDIxN30.A-u9ezGh7c921sf-L8Q6XVgUjU412mAAdkcID1Ajk8g';

async function loginFup(email, senha) {
  const r = await fetch(FUP_URL + '/auth/v1/token?grant_type=password', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'apikey': FUP_ANON },
    body: JSON.stringify({ email, password: senha })
  });
  const data = await r.json();
  if (!r.ok || !data.access_token) throw new Error('Falha ao autenticar no FUP: ' + (data.error_description || r.status));
  return data.access_token;
}

async function fupSelect(token, table, select) {
  const r = await fetch(`${FUP_URL}/rest/v1/${table}?select=${select}&limit=1`, {
    headers: { apikey: FUP_ANON, Authorization: 'Bearer ' + token }
  });
  if (!r.ok) throw new Error(`Erro ao buscar ${table}: ${r.status} ${await r.text()}`);
  const rows = await r.json();
  return rows[0] || null;
}

module.exports = async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const SB_SERVICE = process.env.SUPABASE_SERVICE_KEY;
  const fupEmail = process.env.FUP_EMAIL;
  const fupSenha = process.env.FUP_SENHA;

  if (!SB_SERVICE) return res.status(500).json({ error: 'SUPABASE_SERVICE_KEY nao configurada' });
  if (!fupEmail || !fupSenha) return res.status(500).json({ error: 'FUP_EMAIL/FUP_SENHA nao configurados' });

  // Qualquer usuario autenticado do Hub pode ver a previsao de disponibilidade —
  // nao ha restricao por role, so exige estar logado.
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'Autenticacao necessaria' });

  const userRes = await fetch(HUB_URL + '/auth/v1/user', {
    headers: { 'Authorization': authHeader, 'apikey': SB_SERVICE }
  });
  const caller = await userRes.json();
  if (!caller?.id) return res.status(401).json({ error: 'Token invalido' });

  try {
    const fupToken = await loginFup(fupEmail, fupSenha);

    const [dashboard, sales2] = await Promise.all([
      fupSelect(fupToken, 'dashboard_data', 'all_data,reservas_map,boxer_data,last_update'),
      fupSelect(fupToken, 'sales2_data', 'enderecos_map,status_map,last_update_enderecos,last_update_status')
    ]);

    const porCodigo = {};
    (dashboard?.all_data || []).forEach(item => {
      if (!item?.codigo) return;
      porCodigo[item.codigo] = porCodigo[item.codigo] || [];
      porCodigo[item.codigo].push(item);
    });

    return res.status(200).json({
      ok: true,
      disponibilidade: {
        porCodigo,
        reservasMap: dashboard?.reservas_map || {},
        boxerData: dashboard?.boxer_data || [],
        lastUpdate: dashboard?.last_update || null
      },
      enderecosStatus: {
        enderecosMap: sales2?.enderecos_map || {},
        statusMap: sales2?.status_map || {},
        lastUpdateEnderecos: sales2?.last_update_enderecos || null,
        lastUpdateStatus: sales2?.last_update_status || null
      }
    });
  } catch (e) {
    console.error('Erro ao buscar disponibilidade FUP:', e);
    return res.status(502).json({ error: e.message });
  }
};
