// =============================================================================
// HYGE — procura de vazamentos (estático, roda fora do Roblox)
//
// Conexão em objeto que vive mais que o painel (serviços, LocalPlayer, Camera,
// workspace, o próprio personagem) precisa ir para Conn.Nome = ...:Connect():
// é por lá que o Unload desconecta tudo. Guardada em outro lugar (ou em lugar
// nenhum), ela continua rodando depois que o painel fecha.
//
// Conexões de elementos da própria GUI não entram: somem com o Gui:Destroy().
// Exceção consciente: comentário "-- conn:ok <motivo>" na linha da conexão.
//
//   node tools/leaks.js            lista o que achou no src/
// Usado também por tests/leaks.test.js.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const luaparse = require('luaparse');

// raízes que sobrevivem ao Gui:Destroy()
const PERSISTENT = new Set(`
  game workspace Players UserInputService RunService ReplicatedStorage StarterGui
  Lighting TeleportService Stats GuiService TweenService TextChatService SoundService
  LocalPlayer Camera Char Hum Root
`.split(/\s+/).filter(Boolean));

// identificador na raiz de a.b:c().d (ou o nome da função em Char():...)
function rootName(n) {
  while (n) {
    if (n.type === 'Identifier') return n.name;
    if (n.type === 'MemberExpression' || n.type === 'IndexExpression') n = n.base;
    else if (n.type === 'CallExpression' || n.type === 'StringCallExpression' || n.type === 'TableCallExpression') n = n.base;
    else return null;
  }
  return null;
}

const isConnCall = n => n && n.type === 'CallExpression' && n.base.type === 'MemberExpression'
  && n.base.indexer === ':' && (n.base.identifier.name === 'Connect' || n.base.identifier.name === 'Once');

// devolve [{ file, line, root, code }]
function scanText(file, text) {
  const ast = luaparse.parse(text, { luaVersion: '5.1', locations: true, comments: false });
  const lines = text.split(/\r?\n/);
  const stored = new Set();   // nós de :Connect() que foram parar em Conn.X / Conn["X"]
  const found = [];

  const visit = (n, parent) => {
    if (!n || typeof n !== 'object') return;
    if (Array.isArray(n)) { n.forEach(x => visit(x, parent)); return; }
    if (n.type === 'AssignmentStatement') {
      n.variables.forEach((v, i) => {
        const tgt = v.type === 'MemberExpression' || v.type === 'IndexExpression' ? v.base : null;
        if (tgt && tgt.type === 'Identifier' && tgt.name === 'Conn' && isConnCall(n.init[i])) stored.add(n.init[i]);
      });
    }
    if (isConnCall(n) && !stored.has(n)) {
      const root = rootName(n.base.base);
      const line = n.loc.start.line;
      if (PERSISTENT.has(root) && !/--\s*conn:ok/.test(lines[line - 1] || '')) {
        found.push({ file, line, root, code: (lines[line - 1] || '').trim() });
      }
    }
    for (const k of Object.keys(n)) {
      if (k === 'loc' || k === 'range') continue;
      const v = n[k];
      if (v && typeof v === 'object') visit(v, n);
    }
  };
  // primeiro marca as que foram guardadas (AssignmentStatement vem antes dos
  // filhos na visita, então a ordem já resolve)
  visit(ast.body, null);
  return found;
}

function scanDir(root) {
  const out = [];
  const walk = d => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.lua')) {
        const rel = path.relative(root, p).split(path.sep).join('/');
        out.push(...scanText(rel, fs.readFileSync(p, 'utf8')));
      }
    }
  };
  walk(path.join(root, 'src'));
  return out;
}

module.exports = { scanText, scanDir, PERSISTENT };

if (require.main === module) {
  const found = scanDir(path.resolve(__dirname, '..'));
  if (!found.length) { console.log('Nenhuma conexão persistente fora do Conn.'); process.exit(0); }
  console.log(found.length + ' conexão(ões) persistente(s) fora do Conn (o Unload não desconecta):');
  for (const f of found) console.log(`  ${f.file}:${f.line}  [${f.root}]  ${f.code}`);
  process.exit(1);
}
