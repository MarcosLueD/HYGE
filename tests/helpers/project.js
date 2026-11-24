// Projetos de teste em pastas temporárias: nada aqui toca no src/ de verdade.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const tmpRoots = [];

function tmpDir(tag) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'hyge-' + tag + '-'));
  tmpRoots.push(d);
  return d;
}

function writeTree(root, files) {
  for (const [rel, text] of Object.entries(files)) {
    const p = path.join(root, rel);
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, text);
  }
  return root;
}

// projeto mínimo: um núcleo que define V8 (os módulos isolados usam V8.Mod)
const CORE = 'local V8 = {}\nV8.Mod = function(name, a, b, fn) fn() end\n';
function fixture(files, tag = 'fx') {
  return writeTree(tmpDir(tag), { 'src/00_core/00_state.lua': CORE, ...files });
}

// cópia do src/ real (+ main.lua e manifest.json, se existirem)
function copyProject(tag = 'copy') {
  const dst = tmpDir(tag);
  fs.cpSync(path.join(ROOT, 'src'), path.join(dst, 'src'), { recursive: true });
  for (const f of ['main.lua', 'manifest.json']) {
    const p = path.join(ROOT, f);
    if (fs.existsSync(p)) fs.copyFileSync(p, path.join(dst, f));
  }
  return dst;
}

function cleanup() {
  while (tmpRoots.length) {
    try { fs.rmSync(tmpRoots.pop(), { recursive: true, force: true }); } catch (_) { /* ok */ }
  }
}

// log que guarda as linhas (para conferir mensagens sem poluir a saída)
function capture() {
  const lines = [];
  const log = (...a) => lines.push(a.join(' '));
  log.lines = lines;
  log.text = () => lines.join('\n');
  return log;
}

module.exports = { ROOT, tmpDir, writeTree, fixture, copyProject, cleanup, capture, CORE };
