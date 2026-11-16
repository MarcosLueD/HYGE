// =============================================================================
// HYGE — relay do chat (Chat › HYGE)
//
// Dois clientes Roblox não conversam direto entre si: este servidor guarda as
// mensagens e cada painel busca as novas a cada poucos segundos (HTTP simples,
// funciona com o request() de qualquer executor).
//
//   node server/chat-relay/server.js          (ou: npm run chat)
//
// Variáveis de ambiente (todas opcionais):
//   PORT            porta HTTP (padrão 8787)
//   HYGE_CHAT_KEY   senha compartilhada; o painel manda em CONFIG.ChatKey
//   TRUST_PROXY=1   atrás de proxy (Render, Railway, nginx): usa o IP do
//                   X-Forwarded-For no limite de envio
//
// Salas: "global" e uma por servidor do Roblox (JobId). Nada vai para disco:
// reiniciou, o histórico some (o painel percebe pelo "boot" e limpa a tela).
// O relay NÃO verifica identidade: nome e UserId vêm do próprio cliente.
// Sem dependências — só Node 18+.
// =============================================================================
'use strict';
const http = require('http');
const crypto = require('crypto');

const PORT = Number(process.env.PORT) || 8787;
const KEY = process.env.HYGE_CHAT_KEY || '';
const TRUST_PROXY = process.env.TRUST_PROXY === '1';

const MAX_TEXT = 200;           // caracteres por mensagem
const KEEP = 100;               // mensagens guardadas por sala
const HISTORY = 30;             // quantas o painel recebe ao entrar
const PRESENCE_MS = 25_000;     // sem poll há 25 s = offline
const ROOM_IDLE_MS = 6 * 3600_000;
const SEND_GAP_MS = 900;        // 1 mensagem por ~1 s (por UserId e por IP)
const MAX_BODY = 4096;

const BOOT = crypto.randomBytes(6).toString('hex');
let seq = 0;
const rooms = new Map();        // 'global' | 'job:<JobId>' -> { msgs: [], last }
const presence = new Map();     // uid -> { uid, name, tag, job, seen }
const lastSend = new Map();     // 'uid:<n>' | 'ip:<addr>' -> ms

// ---- validação ----------------------------------------------------------------
const clean = (v, max) => String(v ?? '')
  .replace(/[\u0000-\u001f\u007f]/g, ' ')
  .trim()
  .slice(0, max);
const uidOf = v => (/^\d{1,20}$/.test(String(v)) ? Number(v) : null);
const jobOf = v => {
  const s = String(v ?? '');
  return /^[A-Za-z0-9-]{1,64}$/.test(s) ? s : null;
};

function room(key) {
  let r = rooms.get(key);
  if (!r) { r = { msgs: [], last: Date.now() }; rooms.set(key, r); }
  return r;
}

function ipOf(req) {
  if (TRUST_PROXY) {
    const fwd = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
    if (fwd) return fwd;
  }
  return req.socket.remoteAddress || '?';
}

function send(res, code, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(code, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0, tooBig = false;
    const chunks = [];
    req.on('data', c => {
      if (tooBig) return;
      size += c.length;
      if (size > MAX_BODY) {
        tooBig = true;
        reject(Object.assign(new Error('corpo grande demais'), { status: 413 }));
        return;
      }
      chunks.push(c);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function prune() {
  const now = Date.now();
  for (const [uid, p] of presence) if (now - p.seen > PRESENCE_MS) presence.delete(uid);
  for (const [k, t] of lastSend) if (now - t > 60_000) lastSend.delete(k);
  for (const [k, r] of rooms) if (k !== 'global' && now - r.last > ROOM_IDLE_MS) rooms.delete(k);
}
setInterval(prune, 10 * 60_000).unref();

// ---- rotas --------------------------------------------------------------------
function poll(url, res) {
  const q = url.searchParams;
  if (KEY && q.get('key') !== KEY) return send(res, 403, { ok: false, error: 'senha do chat incorreta' });
  const uid = uidOf(q.get('uid'));
  const job = jobOf(q.get('job'));
  if (uid === null || !job) return send(res, 400, { ok: false, error: 'uid/job inválidos' });
  const after = Math.max(0, Number(q.get('after')) || 0);

  const now = Date.now();
  presence.set(uid, { uid, name: clean(q.get('name'), 40) || '?', tag: clean(q.get('tag'), 40),
    job, seen: now });

  const pick = (key, roomName) => {
    const r = rooms.get(key);
    if (!r) return [];
    const list = after > 0 ? r.msgs.filter(m => m.seq > after) : r.msgs.slice(-HISTORY);
    return list.map(m => ({ ...m, room: roomName }));
  };
  const messages = pick('global', 'global').concat(pick('job:' + job, 'server'))
    .sort((a, b) => a.seq - b.seq);

  const here = [];
  let online = 0;
  for (const p of presence.values()) {
    if (now - p.seen > PRESENCE_MS) continue;
    online++;
    if (p.job === job) here.push({ uid: p.uid, name: p.name, tag: p.tag });
  }
  send(res, 200, { ok: true, boot: BOOT, seq, messages, here, online });
}

async function post(req, res) {
  let raw;
  try { raw = await readBody(req); }
  catch (e) {
    // responde e só então derruba a conexão (não fica lendo lixo)
    res.once('finish', () => req.destroy());
    res.setHeader('Connection', 'close');
    return send(res, e.status || 400, { ok: false, error: 'mensagem grande demais' });
  }
  let data;
  try { data = JSON.parse(raw); }
  catch (e) { return send(res, 400, { ok: false, error: 'JSON inválido' }); }
  if (!data || typeof data !== 'object') return send(res, 400, { ok: false, error: 'JSON inválido' });
  if (KEY && data.key !== KEY) return send(res, 403, { ok: false, error: 'senha do chat incorreta' });

  const uid = uidOf(data.uid);
  const job = jobOf(data.job);
  const text = clean(data.text, MAX_TEXT);
  const target = data.room === 'global' ? 'global' : 'server';
  if (uid === null || !job) return send(res, 400, { ok: false, error: 'uid/job inválidos' });
  if (!text) return send(res, 400, { ok: false, error: 'mensagem vazia' });

  const now = Date.now();
  const kU = 'uid:' + uid, kI = 'ip:' + ipOf(req);
  if (now - (lastSend.get(kU) || 0) < SEND_GAP_MS || now - (lastSend.get(kI) || 0) < SEND_GAP_MS) {
    return send(res, 429, { ok: false, error: 'devagar: 1 mensagem por segundo' });
  }
  lastSend.set(kU, now);
  lastSend.set(kI, now);

  const r = room(target === 'global' ? 'global' : 'job:' + job);
  const msg = {
    seq: ++seq, uid, name: clean(data.name, 40) || '?', tag: clean(data.tag, 40),
    text, t: Math.floor(now / 1000),
  };
  r.msgs.push(msg);
  if (r.msgs.length > KEEP) r.msgs.splice(0, r.msgs.length - KEEP);
  r.last = now;
  send(res, 200, { ok: true, seq: msg.seq });
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://relay');
    if (req.method === 'GET' && url.pathname === '/') {
      return send(res, 200, { ok: true, service: 'hyge-chat-relay', boot: BOOT });
    }
    if (req.method === 'GET' && url.pathname === '/v1/poll') return poll(url, res);
    if (req.method === 'POST' && url.pathname === '/v1/send') return await post(req, res);
    send(res, 404, { ok: false, error: 'rota desconhecida' });
  } catch (e) {
    send(res, 500, { ok: false, error: 'erro interno' });
  }
});

server.listen(PORT, () => {
  console.log(`HYGE chat relay na porta ${PORT}` + (KEY ? ' (com senha)' : ' (sem senha)'));
});
