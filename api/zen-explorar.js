// Endpoint de DIAGNOSTICO — le a API Zen e reporta a estrutura encontrada.
// Nao escreve nada, em lugar nenhum.
//
// Existe para responder, com dado real, o que a especificacao OpenAPI nao diz:
//   - qual o formato de documentNumber (com ou sem mascara)
//   - onde vive o canal de venda (Hibrido / Ecommerce / Varejo)
//   - o que ha em category1..5, personGroup e tags
//   - se a sintaxe RSQL do filtro funciona como esperado
//
// Depois que essas perguntas estiverem respondidas, este arquivo pode sair.

const { zenAuth, zenGet, ZEN_BASE, ZEN_TENANT, normDoc } = require('./_zen');

const HUB_URL = 'https://bmepxcnrsofofoswubuu.supabase.co';

module.exports = async function handler(req, res) {
  const SB_SERVICE = process.env.SUPABASE_SERVICE_KEY;

  // Mesma politica do sync-pdm: cron secret ou admin/manager autenticado
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
      { headers: { apikey: SB_SERVICE, Authorization: 'Bearer ' + SB_SERVICE, 'Accept-Profile': 'comercial' } }
    );
    const perfis = await perfilRes.json();
    if (!perfis?.[0] || !['admin', 'manager'].includes(perfis[0].role)) {
      return res.status(403).json({ error: 'Apenas admin ou manager' });
    }
  } else {
    return res.status(401).json({ error: 'Autenticacao necessaria' });
  }

  const achados = { base: ZEN_BASE, tenant: ZEN_TENANT };

  try {
    // 1 — a autenticacao funciona?
    await zenAuth();
    achados.auth = 'ok';
    console.log('[ZEN] autenticado em', ZEN_BASE, 'tenant', ZEN_TENANT);

    // 2 — amostra de Person, para ver a forma real do registro
    const amostra = await zenGet('/catalog/person/person', { max: 50, limite: 50 });
    achados.amostra_qtd = amostra.length;

    if (amostra.length) {
      achados.campos_presentes = [...new Set(amostra.flatMap(p => Object.keys(p)))].sort();

      // formato do documento: com mascara ou so digitos?
      const docs = amostra.filter(p => p.documentNumber).map(p => p.documentNumber);
      achados.documento = {
        exemplos_mascarados: docs.slice(0, 3).map(d => d.replace(/\d/g, '#')),
        tem_mascara: docs.some(d => /\D/.test(d)),
        tamanhos: [...new Set(docs.map(d => d.length))].sort((a, b) => a - b),
        tipos: [...new Set(amostra.map(p => p.documentType).filter(Boolean))]
      };

      // ONDE VIVE O CANAL DE VENDA? Olhar category1..5, personGroup e tags.
      const categorias = {};
      for (const n of [1, 2, 3, 4, 5]) {
        const vals = amostra.map(p => p[`category${n}`]).filter(Boolean)
          .map(c => c.description || c.code || c.name || JSON.stringify(c));
        if (vals.length) categorias[`category${n}`] = [...new Set(vals)].slice(0, 15);
      }
      achados.categorias = categorias;

      achados.personGroup = [...new Set(
        amostra.map(p => p.personGroup).filter(Boolean)
               .map(g => g.description || g.code || JSON.stringify(g))
      )].slice(0, 15);

      achados.tags = [...new Set(amostra.flatMap(p => {
        const t = p.tags;
        return Array.isArray(t) ? t : (typeof t === 'string' && t ? t.split(/[,;]/) : []);
      }).map(s => String(s).trim()).filter(Boolean))].slice(0, 25);

      achados.tem_personSalesperson = amostra.filter(p => p.personSalesperson).length;
      achados.tipos = [...new Set(amostra.map(p => p.type).filter(Boolean))];

      // uma Person completa, com identificadores removidos — so a forma importa
      const ex = { ...amostra.find(p => p.type === 'CORPORATION') || amostra[0] };
      for (const c of ['documentNumber', 'document2Number', 'email', 'phone', 'name', 'fantasyName',
                       'street', 'number', 'complement', 'zipcode']) {
        if (ex[c]) ex[c] = '<omitido>';
      }
      achados.exemplo_estrutura = ex;
    }

    // 3 — a sintaxe RSQL responde como esperado?
    try {
      const rsqlTeste = await zenGet('/catalog/person/person',
        { q: 'type==CORPORATION', max: 5, limite: 5 });
      achados.rsql = {
        funciona: true,
        retornou: rsqlTeste.length,
        so_corporation: rsqlTeste.every(p => p.type === 'CORPORATION')
      };
    } catch (e) {
      achados.rsql = { funciona: false, erro: e.message.slice(0, 200) };
    }

    // 4 — grupos e categorias cadastrados (a lista completa, nao so a da amostra)
    for (const [rotulo, caminho] of [
      ['personGroups_cadastrados', '/catalog/person/personGroup'],
      ['categorias_cadastradas',   '/catalog/category']
    ]) {
      try {
        const linhas = await zenGet(caminho, { max: 100, limite: 200 });
        achados[rotulo] = linhas.map(g => g.description || g.code || g.name).filter(Boolean).slice(0, 60);
      } catch (e) {
        achados[rotulo] = 'erro: ' + e.message.slice(0, 120);
      }
    }

    // 5 — endereco de entrega: personShipping vem embutido no Person? e
    // personAddress e endpoint relacionado a parte?
    try {
      const comEndereco = amostra.find(p => p.street || p.personShipping || p.zipcode) || amostra[0];
      achados.endereco = {
        campos_no_person: Object.keys(comEndereco).filter(k =>
          /address|shipping|street|zip|endereco|entrega/i.test(k)),
        tem_personShipping: !!comEndereco.personShipping,
        personShipping_forma: comEndereco.personShipping
          ? Object.keys(comEndereco.personShipping) : null
      };
      if (comEndereco?.id) {
        try {
          const enderecos = await zenGet('/catalog/person/personAddress',
            { q: `person.id==${comEndereco.id}`, max: 10, limite: 10 });
          achados.endereco.personAddress_relacionado = {
            encontrados: enderecos.length,
            campos: enderecos.length ? Object.keys(enderecos[0]) : [],
            tipos: [...new Set(enderecos.map(e => e.type || e.addressType || e.description).filter(Boolean))]
          };
        } catch (e) {
          achados.endereco.personAddress_relacionado = { erro: e.message.slice(0, 150) };
        }
      }
    } catch (e) {
      achados.endereco = { erro: e.message.slice(0, 150) };
    }

    console.log('[ZEN] achados:', JSON.stringify(achados, null, 2));
    return res.status(200).json({ ok: true, ...achados });

  } catch (e) {
    console.error('[ZEN] erro:', e.message);
    return res.status(500).json({ ok: false, erro: e.message, achados });
  }
};
