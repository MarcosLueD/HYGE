// =============================================================================
// HYGE — build
//
// Junta todos os src/**/*.lua em ordem alfabética do caminho (os prefixos
// numéricos 00_, 10_, ... definem a ordem) e grava o main.lua — o arquivo
// único que vai para o executor / LocalScript.
//
//   node build.js            valida e grava main.lua
//   node build.js --check    só valida, não grava nada
//   node build.js --force    grava mesmo se o main.lua tiver sido editado à mão
//
// Por que um arquivo só: executores rodam um script por vez e o painel depende
// de locais compartilhadas entre as partes (o Luau não tem "import" aqui).
// Cuidado com o limite de 200 locais no chunk principal — o build avisa.
//
// v9.0 — MÓDULOS ISOLADOS: todo módulo depois de src/00_core que não declara
// 'local' no topo vai embrulhado em V8.Mod("src/arquivo.lua", ini, fim,
// function() ... end). Se ele der erro ao carregar, só ele falha: o resto do
// painel abre e o boot avisa qual módulo (e qual linha do src/) quebrou.
// O wrapper entra na MESMA linha da primeira linha do arquivo, então as linhas
// do main.lua continuam batendo com o src/. No fim do arquivo vai o mapa
// V8.SrcMap (linha do main.lua -> src/arquivo.lua:linha) para os erros do log.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { analyze, report } = require('./tools/check');

const ROOT = __dirname;
const SRC = path.join(ROOT, 'src');
const OUT = path.join(ROOT, 'main.lua');
const args = new Set(process.argv.slice(2));
const BANNER_LINES = 5;   // linhas do cabeçalho gerado (conferido abaixo)

let luaparse = null;
try { luaparse = require('luaparse'); } catch (_) { /* sem isolamento: o check avisa */ }

// pode embrulhar? Só módulo sem 'local' no topo (os 'local' do topo são
// compartilhados com os módulos seguintes — dentro de uma função sumiriam)
function canWrap(relPath, text) {
  if (!luaparse || relPath.startsWith('src/00_core/')) return false;
  let ast;
  try { ast = luaparse.parse(text, { luaVersion: '5.1' }); } catch (_) { return false; }
  if (!ast.body.length) return false;
  return !ast.body.some(s => s.type === 'LocalStatement'
    || (s.type === 'FunctionDeclaration' && s.isLocal)
    || s.type === 'ReturnStatement');
}

function listLua(dir) {
  let out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out = out.concat(listLua(p));
    else if (e.name.endsWith('.lua')) out.push(p);
  }
  return out;
}

const rel = p => path.relative(ROOT, p).split(path.sep).join('/');
const hash = s => crypto.createHash('sha1').update(s).digest('hex').slice(0, 12);
const toCRLF = s => s.replace(/\r?\n/g, '\r\n');

// ---- junta os módulos --------------------------------------------------------
// comparação simples por código (localeCompare pode ignorar "_" e "/")
const files = listLua(SRC).sort((a, b) => (rel(a) < rel(b) ? -1 : rel(a) > rel(b) ? 1 : 0));
if (!files.length) { console.error('Nenhum .lua em src/'); process.exit(1); }

const map = [];   // { file, from, to } em linhas do corpo (1-based)
let body = '';
let line = 1;
let wrapped = 0;
for (const f of files) {
  let text = fs.readFileSync(f, 'utf8').replace(/^﻿/, '');
  text = toCRLF(text);
  if (!text.endsWith('\r\n')) text += '\r\n';
  let n = text.split('\r\n').length - 1;
  if (canWrap(rel(f), text)) {
    // ini/fim em linhas do main.lua (corpo + cabeçalho)
    const ini = line + BANNER_LINES, fim = line + n - 1 + BANNER_LINES;
    text = `V8.Mod("${rel(f)}", ${ini}, ${fim}, function() ` + text + 'end)\r\n';
    n += 1;
    wrapped++;
  }
  map.push({ file: rel(f), from: line, to: line + n - 1 });
  line += n;
  body += text;
}
// v9.0: mapa de linhas para o painel traduzir "HYGE:1234:" em "src/x.lua:12:"
// (vai no fim: não empurra nenhuma linha dos módulos)
body += 'V8.SrcMap = { ' + map.map(m => `{ "${m.file}", ${m.from + BANNER_LINES}, ${m.to + BANNER_LINES} }`).join(', ') + ' }\r\n';
line += 1;

const version = (body.match(/Version\s*=\s*"([^"]+)"/) || [])[1] || '?';
const banner = [
  '-- =============================================================================',
  `-- HYGE ${version} — ARQUIVO GERADO, NÃO EDITE AQUI.`,
  '-- Fonte: src/   ·   gerar de novo: npm run build  (ou: node build.js)',
  `-- build: ${hash(body)}`,
  '-- =============================================================================',
  '',
].join('\r\n');
if (banner.split('\r\n').length - 1 !== BANNER_LINES) {
  console.error('build.js: o cabeçalho mudou de tamanho — ajuste BANNER_LINES');
  process.exit(1);
}

// linha do corpo -> "src/arquivo.lua:linha"
const where = l => {
  const m = map.find(x => l >= x.from && l <= x.to);
  return m ? `${m.file}:${l - m.from + 1}` : `linha ${l}`;
};

// ---- valida --------------------------------------------------------------------
console.log(`HYGE ${version} — ${files.length} módulos (${wrapped} isolados), ${line - 1} linhas`);
if (!luaparse) console.log('  (luaparse ausente: módulos NÃO isolados — rode npm install)');
const ok = report(analyze(body), where);
if (!ok) {
  console.log('\nBuild CANCELADO: main.lua não foi alterado.');
  process.exit(1);
}
if (args.has('--check')) { console.log('\nOK (--check: nada gravado)'); process.exit(0); }

// ---- protege edição manual no main.lua ----------------------------------------
if (fs.existsSync(OUT) && !args.has('--force')) {
  // normaliza: um clone com LF (git autocrlf / Linux) não é "edição à mão"
  const cur = toCRLF(fs.readFileSync(OUT, 'utf8'));
  const m = cur.match(/^-- build: ([0-9a-f]{12})/m);
  const curBody = cur.split('\r\n').slice(BANNER_LINES).join('\r\n');
  if (!m) {
    console.log('\nmain.lua não tem o cabeçalho do build (foi substituído à mão?).');
    console.log('Passe as mudanças para src/ ou rode: node build.js --force');
    process.exit(1);
  }
  if (hash(curBody) !== m[1]) {
    console.log('\nmain.lua foi EDITADO À MÃO depois do último build.');
    console.log('Leve a mudança para o módulo certo em src/ ou rode: node build.js --force');
    process.exit(1);
  }
}

fs.writeFileSync(OUT, banner + body);
console.log(`\nmain.lua gravado (${(Buffer.byteLength(banner + body) / 1024).toFixed(0)} KB, build ${hash(body)})`);
