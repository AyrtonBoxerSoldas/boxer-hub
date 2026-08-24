const HUB_URL = 'https://bmepxcnrsofofoswubuu.supabase.co';
const BUCKET = 'hub-fotos';

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const SB_SERVICE = process.env.SUPABASE_SERVICE_KEY;
  if (!SB_SERVICE) return res.status(500).json({ error: 'SUPABASE_SERVICE_KEY nao configurada' });

  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'Token necessario' });

  const userRes = await fetch(HUB_URL + '/auth/v1/user', {
    headers: { 'Authorization': authHeader, 'apikey': SB_SERVICE }
  });
  const caller = await userRes.json();
  if (!caller?.id) return res.status(401).json({ error: 'Token invalido' });

  const perfilRes = await fetch(
    HUB_URL + '/rest/v1/hub_perfis?user_id=eq.' + caller.id + '&ativo=eq.true&select=role',
    {
      headers: {
        'apikey': SB_SERVICE,
        'Authorization': 'Bearer ' + SB_SERVICE,
        'Accept-Profile': 'comercial',
        'Content-Profile': 'comercial'
      }
    }
  );
  const perfis = await perfilRes.json();
  if (!perfis?.[0] || !['admin', 'manager', 'analyst'].includes(perfis[0].role)) {
    return res.status(403).json({ error: 'Sem permissao' });
  }

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

  const { action } = req.body;

  try {
    if (action === 'delete') {
      const { anexo_id } = req.body;
      if (!anexo_id) return res.status(400).json({ error: 'anexo_id obrigatorio' });

      const getRes = await fetch(
        HUB_URL + '/rest/v1/hub_produto_anexos?id=eq.' + anexo_id + '&select=storage_path',
        { headers: hubH('GET') }
      );
      const anexos = await getRes.json();

      if (anexos?.[0]?.storage_path?.includes('/' + BUCKET + '/')) {
        const storagePath = anexos[0].storage_path.split('/' + BUCKET + '/')[1];
        if (storagePath) {
          await fetch(HUB_URL + '/storage/v1/object/' + BUCKET + '/' + storagePath, {
            method: 'DELETE',
            headers: { 'Authorization': 'Bearer ' + SB_SERVICE, 'apikey': SB_SERVICE }
          }).catch(() => {});
        }
      }

      await fetch(HUB_URL + '/rest/v1/hub_produto_anexos?id=eq.' + anexo_id, {
        method: 'DELETE', headers: hubH('DELETE')
      });

      return res.status(200).json({ ok: true });
    }

    // Upload
    const { produto_id, filename, base64, content_type } = req.body;
    if (!produto_id || !base64 || !filename) {
      return res.status(400).json({ error: 'produto_id, filename e base64 obrigatorios' });
    }

    // Ensure bucket exists (idempotent)
    await fetch(HUB_URL + '/storage/v1/bucket', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + SB_SERVICE,
        'apikey': SB_SERVICE
      },
      body: JSON.stringify({ id: BUCKET, name: BUCKET, public: true })
    }).catch(() => {});

    const buffer = Buffer.from(base64, 'base64');
    const safeName = filename.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = produto_id + '/' + Date.now() + '-' + safeName;

    const uploadRes = await fetch(HUB_URL + '/storage/v1/object/' + BUCKET + '/' + storagePath, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + SB_SERVICE,
        'apikey': SB_SERVICE,
        'Content-Type': content_type || 'image/jpeg',
        'x-upsert': 'true'
      },
      body: buffer
    });

    if (!uploadRes.ok) {
      return res.status(500).json({ error: 'Erro no upload: ' + await uploadRes.text() });
    }

    const publicUrl = HUB_URL + '/storage/v1/object/public/' + BUCKET + '/' + storagePath;

    const anexoRes = await fetch(HUB_URL + '/rest/v1/hub_produto_anexos', {
      method: 'POST',
      headers: hubH('POST'),
      body: JSON.stringify({
        produto_id,
        tipo: 'foto',
        storage_path: publicUrl,
        nome: safeName,
        alt_text: safeName.replace(/\.[^.]+$/, ''),
        ordem: 5
      })
    });

    if (!anexoRes.ok) {
      return res.status(500).json({ error: 'Erro ao criar anexo: ' + await anexoRes.text() });
    }

    const anexo = await anexoRes.json();
    return res.status(200).json({ ok: true, anexo: anexo[0], url: publicUrl });

  } catch (e) {
    console.error('Erro no upload-foto:', e);
    return res.status(500).json({ error: e.message });
  }
};
