// Boxer Hub — Funcoes compartilhadas
// Todas as paginas incluem este arquivo: <script src="hub.js"></script>

const SB_URL  = 'https://bmepxcnrsofofoswubuu.supabase.co';
const SB_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtZXB4Y25yc29mb2Zvc3d1YnV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3MTczNzMsImV4cCI6MjA5NTI5MzM3M30.S55ouFczRYlUYNFf5PotYKXBPT5idypTSmbzR-x2Pk0';

let SESSION = null;

// === SUPABASE FETCH ===

async function sb(path, method = 'GET', body = null) {
  const hdrs = {
    'Content-Type': 'application/json',
    'apikey': SB_ANON,
    'Authorization': 'Bearer ' + (SESSION?.access_token || SB_ANON),
    'Accept-Profile': 'comercial',
    'Content-Profile': 'comercial'
  };
  if (method === 'POST') hdrs['Prefer'] = 'return=representation';
  if (method === 'PATCH') hdrs['Prefer'] = 'return=minimal';

  const opts = { method, headers: hdrs };
  if (body) opts.body = JSON.stringify(body);

  const r = await fetch(SB_URL + '/rest/v1' + path, opts);
  if (!r.ok) {
    const e = await r.text();
    throw new Error(e);
  }
  return (method === 'GET' || method === 'POST') ? r.json() : r;
}

async function sbRpc(fn, params = {}) {
  const r = await fetch(SB_URL + '/rest/v1/rpc/' + fn, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SB_ANON,
      'Authorization': 'Bearer ' + (SESSION?.access_token || SB_ANON),
      'Content-Profile': 'comercial'
    },
    body: JSON.stringify(params)
  });
  if (!r.ok) {
    const e = await r.text();
    throw new Error(e);
  }
  return r.json();
}

// === AUTH ===

async function doLogin() {
  const email = document.getElementById('loginEmail').value.trim();
  const pass = document.getElementById('loginPass').value;
  const errEl = document.getElementById('loginErr');

  if (!email || !pass) {
    showLoginErr('Preencha todos os campos');
    return;
  }
  hideLoginErr();

  try {
    const res = await fetch(SB_URL + '/auth/v1/token?grant_type=password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': SB_ANON },
      body: JSON.stringify({ email, password: pass })
    });
    const data = await res.json();

    if (data.error || !data.access_token) {
      showLoginErr('Email ou senha incorretos');
      return;
    }

    SESSION = data;
    sessionStorage.setItem('hub_session', JSON.stringify(data));
    onLoginSuccess();
  } catch (e) {
    showLoginErr('Erro de conexao. Tente novamente.');
  }
}

function doLogout() {
  SESSION = null;
  sessionStorage.removeItem('hub_session');
  window.location.href = 'index.html';
}

function restoreSession() {
  const saved = sessionStorage.getItem('hub_session');
  if (!saved) return false;

  try {
    SESSION = JSON.parse(saved);
    if (!SESSION?.access_token) { SESSION = null; return false; }

    const payload = JSON.parse(atob(SESSION.access_token.split('.')[1]));
    if (payload.exp * 1000 < Date.now()) {
      return tryRefresh();
    }

    const timeLeft = payload.exp * 1000 - Date.now();
    if (timeLeft < 5 * 60 * 1000) tryRefresh();

    scheduleRefresh();
    return true;
  } catch {
    SESSION = null;
    return false;
  }
}

async function tryRefresh() {
  if (!SESSION?.refresh_token) return false;
  try {
    const res = await fetch(SB_URL + '/auth/v1/token?grant_type=refresh_token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'apikey': SB_ANON },
      body: JSON.stringify({ refresh_token: SESSION.refresh_token })
    });
    const data = await res.json();
    if (data.error || !data.access_token) return false;

    SESSION = data;
    sessionStorage.setItem('hub_session', JSON.stringify(data));
    scheduleRefresh();
    return true;
  } catch {
    return false;
  }
}

function scheduleRefresh() {
  if (!SESSION?.access_token) return;
  try {
    const payload = JSON.parse(atob(SESSION.access_token.split('.')[1]));
    const refreshIn = Math.max((payload.exp * 1000 - Date.now()) - 5 * 60 * 1000, 60000);
    setTimeout(tryRefresh, refreshIn);
  } catch {}
}

function requireAuth() {
  if (!restoreSession()) {
    window.location.href = 'index.html';
    return false;
  }
  return true;
}

function getUserEmail() {
  return SESSION?.user?.email || '';
}

function getUserId() {
  return SESSION?.user?.id || '';
}

// === LOGIN UI HELPERS ===

function showLoginErr(msg) {
  const el = document.getElementById('loginErr');
  if (el) { el.textContent = msg; el.style.display = 'block'; }
}

function hideLoginErr() {
  const el = document.getElementById('loginErr');
  if (el) el.style.display = 'none';
}

// === PERFIL ===

let PERFIL = null;

async function loadPerfil() {
  if (!SESSION) return null;
  try {
    const rows = await sb('/hub_perfis?user_id=eq.' + getUserId() + '&ativo=eq.true&select=*');
    PERFIL = rows[0] || null;
    return PERFIL;
  } catch {
    return null;
  }
}

function getUserRole() { return PERFIL?.role || ''; }
function getUserTipo() { return PERFIL?.tipo || ''; }
function getUserNome() { return PERFIL?.nome || getUserEmail(); }
function getUserClienteId() { return PERFIL?.cliente_id || null; }
function getUserRepresentanteId() { return PERFIL?.representante_id || null; }

// === TOPBAR ===

function renderTopbar(titulo) {
  const html = `
    <div class="topbar">
      <div class="topbar-left">
        <svg width="32" height="32" viewBox="0 0 200 200">
          <rect x="10" y="10" width="180" height="180" rx="30" fill="#e30613"/>
          <line x1="30" y1="30" x2="82" y2="95" stroke="#fff" stroke-width="10" stroke-linecap="round"/>
          <polygon points="100,38 108,80 145,55 118,88 158,92 120,105 148,138 108,118 100,162 92,118 52,138 80,105 42,92 82,88 55,55 92,80" fill="#fff"/>
        </svg>
        <h1>${titulo}</h1>
      </div>
      <div class="topbar-right">
        <span class="notif-badge" id="notifBadge" onclick="window.location.href='index.html'" style="display:none" title="Notificacoes pendentes"></span>
        <span class="user-badge"><strong id="userName"></strong></span>
        <span class="logout-btn" onclick="doLogout()">Sair</span>
      </div>
    </div>`;

  document.body.insertAdjacentHTML('afterbegin', html);
  document.getElementById('userName').textContent = getUserNome();
  loadNotifCount();
}

async function loadNotifCount() {
  try {
    const rows = await sb('/hub_v_notif_pendentes?select=id&limit=1', 'GET');
    const badge = document.getElementById('notifBadge');
    if (badge && rows.length > 0) {
      badge.style.display = 'inline-block';
    }
  } catch {}
}

// === TOAST ===

function toast(msg, tipo = 'success') {
  const d = document.createElement('div');
  d.className = 'toast toast-' + tipo;
  d.textContent = msg;
  document.body.appendChild(d);
  setTimeout(() => d.remove(), 3500);
}

// === MODAL ===

function openModal(html) {
  document.getElementById('modalContent').innerHTML = html;
  document.getElementById('modalOverlay').classList.add('show');
}

function closeModal() {
  document.getElementById('modalOverlay').classList.remove('show');
}

// === UTILS ===

function fmtMoeda(v) {
  return (v || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function fmtData(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('pt-BR');
}

function fmtCnpj(c) {
  if (!c) return '—';
  return c.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
}

function debounce(fn, ms = 300) {
  let t;
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
}
