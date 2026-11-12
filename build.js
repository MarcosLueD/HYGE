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
for (const f of files) {
  let text = fs.readFileSync(f, 'utf8').replace(/^﻿/, '');
  text = toCRLF(text);
  if (!text.endsWith('\r\n')) text += '\r\n';
  const n = text.split('\r\n').length - 1;
  map.push({ file: rel(f), from: line, to: line + n - 1 });
  line += n;
  body += text;
}

const version = (body.match(/Version\s*=\s*"([^"]+)"/) || [])[1] || '?';
const banner = [
  '-- =============================================================================',
  `-- HYGE ${version} — ARQUIVO GERADO, NÃO EDITE AQUI.`,
  '-- Fonte: src/   ·   gerar de novo: npm run build  (ou: node build.js)',
  `-- build: ${hash(body)}`,
  '-- =============================================================================',
  '',
].join('\r\n');
const BANNER_LINES = banner.split('\r\n').length - 1;

// linha do corpo -> "src/arquivo.lua:linha"
const where = l => {
  const m = map.find(x => l >= x.from && l <= x.to);
  return m ? `${m.file}:${l - m.from + 1}` : `linha ${l}`;
};

// ---- valida --------------------------------------------------------------------
console.log(`HYGE ${version} — ${files.length} módulos, ${line - 1} linhas`);
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
