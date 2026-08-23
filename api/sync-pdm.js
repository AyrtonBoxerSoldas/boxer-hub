const HUB_URL = 'https://bmepxcnrsofofoswubuu.supabase.co';
const PDM_URL = 'https://tufbuyfwysowgkxsvjmh.supabase.co';

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const SB_SERVICE = process.env.SUPABASE_SERVICE_KEY;
  const PDM_SERVICE = process.env.PDM_SERVICE_KEY;

  if (!SB_SERVICE) return res.status(500).json({ error: 'SUPABASE_SERVICE_KEY nao configurada' });
  if (!PDM_SERVICE) return res.status(500).json({ error: 'PDM_SERVICE_KEY nao configurada' });

  const cronSecret = req.headers['x-cron-secret'];
  const authHeader = req.headers.authorization;

  if (cronSecret) {
    if (!process.env.CRON_SECRET || cronSecret !== process.env.CRON_SECRET) {
      return res.status(401).json({ error: 'CRON_SECRET invalido' });
    }
  } else if (authHeader) {
    const userRes = await fetch(HUB_URL + '/auth/v1/user', {
      headers: { 'Authorization': authHeader, 'apikey': SB_SERVICE }
    });
    const caller = await userRes.json();
    if (!caller?.id) return res.status(401).json({ error: 'Token invalido' });

    const perfilRes = await fetch(
      HUB_URL + '/rest/v1/hub_perfis?user_id=eq.' + caller.id + '&ativo=eq.true&select=role',
      { headers: hubH('GET') }
    );
    const perfis = await perfilRes.json();
    if (!perfis?.[0] || !['admin', 'manager'].includes(perfis[0].role)) {
      return res.status(403).json({ error: 'Apenas admin ou manager pode sincronizar' });
    }
  } else {
    return res.status(401).json({ error: 'Autenticacao necessaria' });
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

  const pdmH = {
    'apikey': PDM_SERVICE,
    'Authorization': 'Bearer ' + PDM_SERVICE
  };

  try {
    // 1 — Produtos ativos do PDM
    const prodRes = await fetch(PDM_URL + '/rest/v1/produtos?status=eq.Ativo&select=*&order=codigo', { headers: pdmH });
    if (!prodRes.ok) throw new Error('Erro ao buscar produtos PDM: ' + prodRes.status);
    const pdmProdutos = await prodRes.json();

    // 2 — Documentos ativos do PDM
    const docRes = await fetch(PDM_URL + '/rest/v1/documentos?ativo=eq.true&select=id,produto_id,nome,tipo,arquivo_url,revisao', { headers: pdmH });
    if (!docRes.ok) throw new Error('Erro ao buscar documentos PDM: ' + docRes.status);
    const pdmDocs = await docRes.json();

    // 3 — Sincronizar categorias
    const catSet = new Set();
    const subMap = {};
    pdmProdutos.forEach(p => {
      if (p.categoria) {
        catSet.add(p.categoria);
        if (p.subcategoria) {
          if (!subMap[p.categoria]) subMap[p.categoria] = new Set();
          subMap[p.categoria].add(p.subcategoria);
        }
      }
    });

    const catBodies = [...catSet].map(nome => ({ nome, slug: slugify(nome), ativo: true }));
    let categorias = [];
    if (catBodies.length > 0) {
      const catRes = await fetch(HUB_URL + '/rest/v1/hub_categorias?on_conflict=slug', {
        method: 'POST',
        headers: { ...hubH('POST'), 'Prefer': 'resolution=merge-duplicates,return=representation' },
        body: JSON.stringify(catBodies)
      });
      if (!catRes.ok) throw new Error('Erro ao upsertar categorias: ' + await catRes.text());
      categorias = await catRes.json();
    }

    const catLookup = {};
    categorias.forEach(c => catLookup[c.nome] = c.id);

    const subBodies = [];
    Object.entries(subMap).forEach(([cat, subs]) => {
      const paiId = catLookup[cat];
      if (paiId) {
        [...subs].forEach(sub => {
          subBodies.push({
            nome: sub,
            slug: slugify(cat + '-' + sub),
            categoria_pai_id: paiId,
            ativo: true
          });
        });
      }
    });

    let subcategorias = [];
    if (subBodies.length > 0) {
      const subRes = await fetch(HUB_URL + '/rest/v1/hub_categorias?on_conflict=slug', {
        method: 'POST',
        headers: { ...hubH('POST'), 'Prefer': 'resolution=merge-duplicates,return=representation' },
        body: JSON.stringify(subBodies)
      });
      if (!subRes.ok) throw new Error('Erro ao upsertar subcategorias: ' + await subRes.text());
      subcategorias = await subRes.json();
    }

    subcategorias.forEach(c => catLookup[c.nome] = c.id);

    // 4 — Sincronizar produtos
    const pdmIdToSku = {};
    pdmProdutos.forEach(p => pdmIdToSku[p.id] = p.codigo);

    const prodBodies = pdmProdutos.map(p => {
      const ft = {};
      if (p.processos_solda) ft.processos_solda = p.processos_solda;
      if (p.tensao_entrada) ft.tensao_entrada = p.tensao_entrada;
      if (p.ciclo_trabalho) ft.ciclo_trabalho = p.ciclo_trabalho;
      if (p.tensao_vazio) ft.tensao_vazio = p.tensao_vazio;
      if (p.bitola_arame_eletrodo) ft.bitola_arame_eletrodo = p.bitola_arame_eletrodo;
      if (p.ca_numero) ft.ca_numero = p.ca_numero;
      if (p.ca_validade) ft.ca_validade = p.ca_validade;
      if (p.recursos_diferenciais) ft.recursos_diferenciais = p.recursos_diferenciais;

      const catId = catLookup[p.subcategoria] || catLookup[p.categoria] || null;

      return {
        sku: p.codigo,
        nome: p.nome,
        descricao: p.descricao_detalhada || p.descricao || null,
        ncm: p.ncm || null,
        categoria_id: catId,
        ficha_tecnica: Object.keys(ft).length > 0 ? ft : null,
        o_que_acompanha: parseOQueAcompanha(p.recursos_diferenciais),
        erp_produto_id: p.codigo,
        ativo: true,
        atualizado_em: new Date().toISOString()
      };
    });

    let hubProdutos = [];
    for (let i = 0; i < prodBodies.length; i += 200) {
      const batch = prodBodies.slice(i, i + 200);
      const pRes = await fetch(HUB_URL + '/rest/v1/hub_produtos?on_conflict=sku', {
        method: 'POST',
        headers: { ...hubH('POST'), 'Prefer': 'resolution=merge-duplicates,return=representation' },
        body: JSON.stringify(batch)
      });
      if (!pRes.ok) throw new Error('Erro ao upsertar produtos (batch ' + i + '): ' + await pRes.text());
      hubProdutos = hubProdutos.concat(await pRes.json());
    }

    const skuToHubId = {};
    hubProdutos.forEach(p => skuToHubId[p.sku] = p.id);

    // 5 — Sincronizar anexos
    // Limpar TODOS anexos dos produtos sincronizados (por produto_id)
    for (let i = 0; i < hubProdutos.length; i += 50) {
      const ids = hubProdutos.slice(i, i + 50).map(p => p.id).join(',');
      await fetch(HUB_URL + '/rest/v1/hub_produto_anexos?produto_id=in.(' + ids + ')', {
        method: 'DELETE', headers: hubH('DELETE')
      });
    }

    const TIPO_MAP = {
      'Artworks': 'foto',
      'Ficha Técnica': 'ficha_tecnica',
      'Vista Explodida': 'catalogo',
      'Manual do Usuário': 'manual',
      'Desenho Técnico': 'ficha_tecnica',
      'Outro': 'catalogo'
    };

    const anexoBodies = [];

    pdmProdutos.forEach(p => {
      if (p.imagem_url && skuToHubId[p.codigo]) {
        anexoBodies.push({
          produto_id: skuToHubId[p.codigo],
          tipo: 'foto',
          storage_path: p.imagem_url,
          nome: p.nome,
          alt_text: p.nome,
          ordem: 0
        });
      }
    });

    pdmDocs.forEach(d => {
      const sku = pdmIdToSku[d.produto_id];
      const hubId = sku ? skuToHubId[sku] : null;
      if (hubId && d.arquivo_url) {
        anexoBodies.push({
          produto_id: hubId,
          tipo: TIPO_MAP[d.tipo] || 'catalogo',
          storage_path: d.arquivo_url,
          nome: d.nome + (d.revisao && d.revisao !== 'Rev.00' ? ' (' + d.revisao + ')' : ''),
          alt_text: null,
          ordem: d.tipo === 'Artworks' ? 1 : 10
        });
      }
    });

    let anexosCount = 0;
    const anexoErrors = [];
    for (let i = 0; i < anexoBodies.length; i += 50) {
      const batch = anexoBodies.slice(i, i + 50);
      const aRes = await fetch(HUB_URL + '/rest/v1/hub_produto_anexos', {
        method: 'POST',
        headers: hubH('POST'),
        body: JSON.stringify(batch)
      });
      if (aRes.ok) {
        anexosCount += batch.length;
      } else {
        const errText = await aRes.text();
        console.error('Batch anexos ' + i + ' falhou (' + aRes.status + '):', errText);
        anexoErrors.push({ batch: i, status: aRes.status, detail: errText.substring(0, 300) });
      }
    }

    return res.status(200).json({
      ok: true,
      produtos_sincronizados: hubProdutos.length,
      categorias: categorias.length,
      subcategorias: subcategorias.length,
      anexos_sincronizados: anexosCount,
      anexos_total_tentados: anexoBodies.length,
      anexo_errors: anexoErrors.length > 0 ? anexoErrors : undefined,
      timestamp: new Date().toISOString()
    });

  } catch (e) {
    console.error('Erro no sync PDM:', e);
    return res.status(500).json({ error: e.message });
  }
};

function slugify(text) {
  return text.toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function parseOQueAcompanha(recursos) {
  if (!recursos) return null;
  const match = recursos.match(/[Aa]companha[:\s]*([\s\S]*?)(?:\n\n|[Ff]un[çc][õo]es|$)/);
  if (!match) return null;
  const items = match[1].split(/[•\n]/)
    .map(s => s.replace(/^[\s\-]+/, '').trim())
    .filter(s => s.length > 2);
  return items.length > 0 ? items : null;
}
