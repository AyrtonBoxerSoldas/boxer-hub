// Importa clientes do Zen (catalog.person.Person) para comercial.hub_clientes.
//
// Regra de negocio (2026-08-27):
//   - Canais: Hibrido, Ecommerce, Varejo — vem de Person.category1
//   - TODOS os cadastros desses canais, independente de data ou de ter comprado
//   - Identificacao na tela: personGroup quando houver, senao o proprio cliente
//   - tags do Zen sao espelhadas; a tag 'blocked' marca hub_clientes.bloqueado
//
// Chame com ?dry=1 para simular: le do Zen, reporta o que faria, nao grava nada.

const { zenGet, normDoc } = require('./_zen');

const HUB_URL = 'https://bmepxcnrsofofoswubuu.supabase.co';

// Grafia exata do Zen — 'Hibrido' nao tem acento la.
const CANAIS = ['Hibrido', 'Ecommerce', 'Varejo'];

module.exports = async function handler(req, res) {
  const SB_SERVICE = process.env.SUPABASE_SERVICE_KEY;
  if (!SB_SERVICE) return res.status(500).json({ error: 'SUPABASE_SERVICE_KEY nao configurada' });

  const hubH = (method) => ({
    'Content-Type': 'application/json',
    'apikey': SB_SERVICE,
    'Authorization': 'Bearer ' + SB_SERVICE,
    'Accept-Profile': 'comercial',
    'Content-Profile': 'comercial',
    'Prefer': method === 'POST'
      ? 'resolution=merge-duplicates,return=representation'
      : 'return=minimal'
  });

  // --- autorizacao: cron secret ou admin/manager ---
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

  const dryRun = req.query?.dry === '1' || req.body?.dry === true;

  try {
    // 1 — Buscar as pessoas dos canais desejados.
    // Uma consulta por canal: o RSQL aceita OR com vírgula, mas filtrar por
    // relacao aninhada (category1.description) nao esta documentado — separar
    // as chamadas e mais previsivel e o custo e baixo (3 chamadas).
    let pessoas = [];
    const porCanal = {};

    for (const canal of CANAIS) {
      let lote = [];
      try {
        lote = await zenGet('/catalog/person/person', {
          q: `category1.description==${canal}`, max: 200
        });
      } catch (e) {
        console.warn(`[ZEN] filtro por canal '${canal}' falhou (${e.message.slice(0, 80)}); usando varredura`);
        lote = null;
      }
      if (lote === null) { porCanal.__fallback = true; break; }
      porCanal[canal] = lote.length;
      pessoas = pessoas.concat(lote);
    }

    // Fallback: se o filtro por relacao nao for suportado, varre e filtra local.
    if (porCanal.__fallback) {
      delete porCanal.__fallback;
      const todas = await zenGet('/catalog/person/person', { max: 200, limite: 50000 });
      console.log(`[ZEN] varredura completa: ${todas.length} pessoas`);
      pessoas = todas.filter(p => CANAIS.includes(canalDe(p)));
      for (const c of CANAIS) porCanal[c] = pessoas.filter(p => canalDe(p) === c).length;
    }

    // dedupe por id (uma pessoa nao deveria repetir, mas o anti-ciclo e barato)
    const vistos = new Set();
    pessoas = pessoas.filter(p => (p?.id && !vistos.has(p.id)) ? vistos.add(p.id) : false);

    console.log(`[ZEN] ${pessoas.length} pessoas nos canais ${CANAIS.join(', ')}`);

    // 2 — Montar os registros do Hub
    const semDoc = [];
    const bodies = [];

    for (const p of pessoas) {
      const doc = normDoc(p.documentNumber);
      if (!doc) { semDoc.push(p.id); continue; }

      const tags = parseTags(p.tags);

      bodies.push({
        erp_cliente_id: String(p.id),
        cnpj: doc,
        razao_social: p.name || '(sem nome)',
        nome_fantasia: p.fantasyName || null,
        inscricao_estadual: p.document2Type === 'BR_INSCRICAO_ESTADUAL'
          ? (p.document2Number || null) : null,
        email_principal: p.email || null,
        telefone: p.phone || null,
        canal: canalDe(p),
        grupo_nome: p.personGroup?.description || p.personGroup?.code || null,
        grupo_erp_id: p.personGroup?.id ?? null,
        cidade: p.city?.name || null,
        uf: p.city?.state?.code || null,
        tags,
        bloqueado: tags.includes('blocked'),
        // bloqueado no Zen entra suspenso; os demais, ativos
        status_cadastro: tags.includes('blocked') ? 'suspenso' : 'ativo',
        ativo: true,
        sincronizado_em: new Date().toISOString()
      });
    }

    const resumo = {
      canais: CANAIS,
      encontrados_por_canal: porCanal,
      total_encontrado: pessoas.length,
      a_gravar: bodies.length,
      ignorados_sem_documento: semDoc.length,
      bloqueados: bodies.filter(b => b.bloqueado).length,
      com_grupo: bodies.filter(b => b.grupo_nome).length,
      sem_grupo: bodies.filter(b => !b.grupo_nome).length,
      grupos_distintos: new Set(bodies.map(b => b.grupo_nome).filter(Boolean)).size,
      dry_run: dryRun
    };

    if (dryRun) {
      console.log('[ZEN] DRY RUN — nada gravado:', JSON.stringify(resumo, null, 2));
      return res.status(200).json({ ok: true, ...resumo, amostra: bodies.slice(0, 3).map(mascarar) });
    }

    // 3 — Upsert por erp_cliente_id (idempotente: pode rodar quantas vezes quiser)
    let gravados = 0;
    const erros = [];
    for (let i = 0; i < bodies.length; i += 200) {
      const lote = bodies.slice(i, i + 200);
      const r = await fetch(HUB_URL + '/rest/v1/hub_clientes?on_conflict=erp_cliente_id', {
        method: 'POST', headers: hubH('POST'), body: JSON.stringify(lote)
      });
      if (r.ok) { gravados += lote.length; }
      else {
        const txt = await r.text();
        console.error(`[ZEN] lote ${i} falhou (${r.status}):`, txt.slice(0, 300));
        erros.push({ lote: i, status: r.status, detalhe: txt.slice(0, 300) });
      }
    }

    console.log('[ZEN] gravados:', gravados, 'de', bodies.length);
    return res.status(200).json({
      ok: erros.length === 0, ...resumo, gravados,
      erros: erros.length ? erros : undefined
    });

  } catch (e) {
    console.error('[ZEN] erro:', e.message);
    return res.status(500).json({ ok: false, erro: e.message });
  }
};

function canalDe(p) {
  return p?.category1?.description || p?.category1?.code || null;
}

// tags vem como string separada por virgula em Person (o schema Compact declara
// array — aceitar as duas formas)
function parseTags(t) {
  if (Array.isArray(t)) return t.map(s => String(s).trim()).filter(Boolean);
  if (typeof t === 'string') return t.split(/[,;]/).map(s => s.trim()).filter(Boolean);
  return [];
}

function mascarar(b) {
  return { ...b, cnpj: '<omitido>', razao_social: '<omitido>', nome_fantasia: '<omitido>',
           email_principal: b.email_principal ? '<omitido>' : null,
           telefone: b.telefone ? '<omitido>' : null };
}
