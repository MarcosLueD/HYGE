// =============================================================================
// HYGE — build
//
// Junta todos os src/**/*.lua em ordem alfabética do caminho (os prefixos
// numéricos 00_, 10_, ... definem a ordem) e grava o main.lua — o arquivo
// único que vai para o executor / LocalScript.
//
//   node build.js            valida e grava main.lua (+ manifest.json)
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
//
// v9.1 — MANIFESTO: junto com o main.lua vai o manifest.json (versão, build,
// tamanho e SHA-256). O loader e a atualização do painel só trocam a cópia
// local se o arquivo baixado bater com ele. O hash é do texto com quebras de
// linha LF: o Git guarda LF e o GitHub serve LF, mesmo que aqui o arquivo
// fique com CRLF.
//
// As funções ficam exportadas para os testes (tests/*.test.js).
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { analyze, report } = require('./tools/check');

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

const hash = s => crypto.createHash('sha1').update(s).digest('hex').slice(0, 12);
const toCRLF = s => s.replace(/\r?\n/g, '\r\n');
const toLF = s => s.replace(/\r\n/g, '\n');

// SHA-256 (hex) e tamanho em bytes do texto com quebras de linha LF
function integrity(text) {
  const lf = Buffer.from(toLF(text), 'utf8');
  return { size: lf.length, sha256: crypto.createHash('sha256').update(lf).digest('hex') };
}

// comparação simples por código (localeCompare pode ignorar "_" e "/")
const byPath = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// ---- junta os módulos --------------------------------------------------------
// Devolve tudo o que o build calcula, sem gravar nada.
function assemble(root) {
  const SRC = path.join(root, 'src');
  const rel = p => path.relative(root, p).split(path.sep).join('/');
  const files = fs.existsSync(SRC) ? listLua(SRC).map(rel).sort(byPath) : [];
  if (!files.length) throw new Error('Nenhum .lua em src/');

  const map = [];   // { file, from, to } em linhas do corpo (1-based)
  const wrappedFiles = [];
  let body = '';
  let line = 1;
  for (const f of files) {
    let text = fs.readFileSync(path.join(root, f), 'utf8').replace(/^﻿/, '');
    text = toCRLF(text);
    if (!text.endsWith('\r\n')) text += '\r\n';
    let n = text.split('\r\n').length - 1;
    if (canWrap(f, text)) {
      // ini/fim em linhas do main.lua (corpo + cabeçalho)
      const ini = line + BANNER_LINES, fim = line + n - 1 + BANNER_LINES;
      text = `V8.Mod("${f}", ${ini}, ${fim}, function() ` + text + 'end)\r\n';
      n += 1;
      wrappedFiles.push(f);
    }
    map.push({ file: f, from: line, to: line + n - 1 });
    line += n;
    body += text;
  }
  // v9.0: mapa de linhas para o painel traduzir "HYGE:1234:" em "src/x.lua:12:"
  // (vai no fim: não empurra nenhuma linha dos módulos)
  body += 'V8.SrcMap = { ' + map.map(m => `{ "${m.file}", ${m.from + BANNER_LINES}, ${m.to + BANNER_LINES} }`).join(', ') + ' }\r\n';
  line += 1;

  const version = (body.match(/Version\s*=\s*"([^"]+)"/) || [])[1] || '?';
  const buildId = hash(body);
  const banner = [
    '-- =============================================================================',
    `-- HYGE ${version} — ARQUIVO GERADO, NÃO EDITE AQUI.`,
    '-- Fonte: src/   ·   gerar de novo: npm run build  (ou: node build.js)',
    `-- build: ${buildId}`,
    '-- =============================================================================',
    '',
  ].join('\r\n');
  if (banner.split('\r\n').length - 1 !== BANNER_LINES) {
    throw new Error('build.js: o cabeçalho mudou de tamanho — ajuste BANNER_LINES');
  }

  // linha do corpo -> "src/arquivo.lua:linha"
  const where = l => {
    const m = map.find(x => l >= x.from && l <= x.to);
    return m ? `${m.file}:${l - m.from + 1}` : `linha ${l}`;
  };

  return { files, map, wrappedFiles, body, banner, text: banner + body, version, buildId,
           lines: line - 1, where };
}

function manifestFor(a) {
  const { size, sha256 } = integrity(a.text);
  return { version: a.version, build: a.buildId, file: 'main.lua', size, sha256, eol: 'lf' };
}

// main.lua foi mexido à mão depois do último build?
//   null = pode sobrescrever · 'no-header' · 'edited'
function manualEditState(outPath) {
  if (!fs.existsSync(outPath)) return null;
  // normaliza: um clone com LF (git autocrlf / Linux) não é "edição à mão"
  const cur = toCRLF(fs.readFileSync(outPath, 'utf8'));
  const m = cur.match(/^-- build: ([0-9a-f]{12})/m);
  if (!m) return 'no-header';
  const curBody = cur.split('\r\n').slice(BANNER_LINES).join('\r\n');
  return hash(curBody) === m[1] ? null : 'edited';
}

// Roda o build inteiro. Devolve { ok, reason, assembled, analysis }.
//   reason: 'check-failed' | 'manual-edit' | 'no-header' | 'checked' | 'written'
function run({ root = __dirname, check = false, force = false, log = console.log } = {}) {
  const OUT = path.join(root, 'main.lua');
  const MANIFEST = path.join(root, 'manifest.json');

  const a = assemble(root);
  log(`HYGE ${a.version} — ${a.files.length} módulos (${a.wrappedFiles.length} isolados), ${a.lines} linhas`);
  if (!luaparse) log('  (luaparse ausente: módulos NÃO isolados — rode npm install)');

  const analysis = analyze(a.body);
  if (!report(analysis, a.where, log)) {
    log('\nBuild CANCELADO: main.lua não foi alterado.');
    return { ok: false, reason: 'check-failed', assembled: a, analysis };
  }
  if (check) {
    log('\nOK (--check: nada gravado)');
    return { ok: true, reason: 'checked', assembled: a, analysis };
  }

  // ---- protege edição manual no main.lua --------------------------------------
  if (!force) {
    const state = manualEditState(OUT);
    if (state === 'no-header') {
      log('\nmain.lua não tem o cabeçalho do build (foi substituído à mão?).');
      log('Passe as mudanças para src/ ou rode: node build.js --force');
      return { ok: false, reason: 'no-header', assembled: a, analysis };
    }
    if (state === 'edited') {
      log('\nmain.lua foi EDITADO À MÃO depois do último build.');
      log('Leve a mudança para o módulo certo em src/ ou rode: node build.js --force');
      return { ok: false, reason: 'manual-edit', assembled: a, analysis };
    }
  }

  // main.lua primeiro: se o manifesto não chegar a ser gravado, ele fica
  // desencontrado e o loader recusa (nunca o contrário)
  fs.writeFileSync(OUT, a.text);
  const man = manifestFor(a);
  fs.writeFileSync(MANIFEST, JSON.stringify(man, null, 2) + '\n');
  log(`\nmain.lua gravado (${(Buffer.byteLength(a.text) / 1024).toFixed(0)} KB, build ${a.buildId})`);
  log(`manifest.json: ${man.size} bytes, sha256 ${man.sha256.slice(0, 16)}…`);
  return { ok: true, reason: 'written', assembled: a, analysis, manifest: man };
}

module.exports = { BANNER_LINES, canWrap, listLua, assemble, manifestFor, integrity,
                   manualEditState, run, toLF, toCRLF };

if (require.main === module) {
  const args = new Set(process.argv.slice(2));
  let r;
  try {
    r = run({ check: args.has('--check'), force: args.has('--force') });
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
  process.exit(r.ok ? 0 : 1);
}
