// Upload de documento cadastral pelo proprio cliente (Meu Cadastro).
//
// Corrige bug achado na auditoria de 2026-08-31: cadastro.html chamava
// uploadDoc() que so mostrava "Upload em desenvolvimento" e nao subia nada.
//
// Mesmo padrao de api/upload-foto.js (upload mediado por service_role, bucket
// garantido de forma idempotente), mas aqui o bucket e PRIVADO -- documento
// cadastral nao e material publico -- e quem pode chamar e o proprio dono do
// cadastro (tipo 'cliente'), nao so admin.
const HUB_URL = 'https://bmepxcnrsofofoswubuu.supabase.co';
const BUCKET = 'hub-documentos-cadastrais';

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const SB_SERVICE = process.env.SUPABASE_SERVICE_KEY;
  if (!SB_SERVICE) return res.status(500).json({ error: 'SUPABASE_SERVICE_KEY nao configurada' });

  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'Token necessario' });

  function hubH(method) {
    return {
      'Content-Type': 'application/json',
      'apikey': SB_SERVICE,
      'Authorization': 'Bearer ' + SB_SERVICE,
      'Accept-Profile': 'comercial',
      'Content-Profile': 'comercial',
      'Prefer': method === 'POST' ? 'return=representation' : 'return=minimal'
    };
  }

  try {
    const userRes = await fetch(HUB_URL + '/auth/v1/user', {
      headers: { 'Authorization': authHeader, 'apikey': SB_SERVICE }
    });
    const caller = await userRes.json();
    if (!caller?.id) return res.status(401).json({ error: 'Token invalido' });

    const perfilRes = await fetch(
      HUB_URL + '/rest/v1/hub_perfis?user_id=eq.' + caller.id + '&ativo=eq.true&select=tipo,cliente_id',
      { headers: hubH('GET') }
    );
    const perfis = await perfilRes.json();
    const perfil = perfis?.[0];

    // So o proprio cliente sobe documento do seu cadastro por aqui -- upload
    // em nome de terceiros (representante, admin) fica para quando existir
    // essa necessidade real; hoje so cadastro.html chama este endpoint.
    if (!perfil || perfil.tipo !== 'cliente' || !perfil.cliente_id) {
      return res.status(403).json({ error: 'Apenas o proprio cliente pode enviar documento do seu cadastro' });
    }

    const { tipo, filename, base64, content_type } = req.body;
    if (!tipo || !filename || !base64) {
      return res.status(400).json({ error: 'tipo, filename e base64 sao obrigatorios' });
    }

    // Garante o bucket (idempotente) -- privado, ninguem le sem passar pela API
    await fetch(HUB_URL + '/storage/v1/bucket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + SB_SERVICE, 'apikey': SB_SERVICE },
      body: JSON.stringify({ id: BUCKET, name: BUCKET, public: false })
    }).catch(() => {});

    const buffer = Buffer.from(base64, 'base64');
    const safeName = filename.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = perfil.cliente_id + '/' + Date.now() + '-' + safeName;

    const uploadRes = await fetch(HUB_URL + '/storage/v1/object/' + BUCKET + '/' + storagePath, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + SB_SERVICE,
        'apikey': SB_SERVICE,
        'Content-Type': content_type || 'application/octet-stream',
        'x-upsert': 'true'
      },
      body: buffer
    });

    if (!uploadRes.ok) {
      return res.status(500).json({ error: 'Erro no upload: ' + await uploadRes.text() });
    }

    const docRes = await fetch(HUB_URL + '/rest/v1/hub_documentos_cadastrais', {
      method: 'POST',
      headers: hubH('POST'),
      body: JSON.stringify({
        cliente_id: perfil.cliente_id,
        tipo,
        nome: safeName,
        storage_path: BUCKET + '/' + storagePath,
        status: 'pendente'
      })
    });

    if (!docRes.ok) {
      return res.status(500).json({ error: 'Erro ao registrar documento: ' + await docRes.text() });
    }

    const doc = await docRes.json();
    return res.status(200).json({ ok: true, documento: doc[0] });

  } catch (e) {
    console.error('[upload-documento-cadastro] erro:', e);
    return res.status(500).json({ error: e.message });
  }
};
