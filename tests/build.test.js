// Etapa 1 — o build do projeto de verdade e a proteção do main.lua
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const B = require('../build');
const { ROOT, copyProject, cleanup, capture } = require('./helpers/project');

test.after(cleanup);

test('o projeto real passa na validação (--check)', () => {
  const log = capture();
  const r = B.run({ root: ROOT, check: true, log });
  assert.equal(r.ok, true, log.text());
  assert.equal(r.reason, 'checked');
  assert.ok(r.assembled.files.length > 50, 'achou poucos módulos');
});

test('o build é determinístico (mesma entrada, mesmo build id)', () => {
  const a = B.assemble(ROOT);
  const b = B.assemble(ROOT);
  assert.equal(a.buildId, b.buildId);
  assert.equal(a.text, b.text);
});

test('o main.lua do repositório está atualizado com o src/', () => {
  const a = B.assemble(ROOT);
  const cur = fs.readFileSync(path.join(ROOT, 'main.lua'), 'utf8');
  assert.ok(B.toLF(cur) === B.toLF(a.text),
    'main.lua desatualizado: rode "npm run build" e faça commit do main.lua junto');
});

test('o manifest.json bate com o main.lua (versão, build, tamanho, SHA-256)', () => {
  const man = JSON.parse(fs.readFileSync(path.join(ROOT, 'manifest.json'), 'utf8'));
  const cur = fs.readFileSync(path.join(ROOT, 'main.lua'), 'utf8');
  const { size, sha256 } = B.integrity(cur);
  assert.equal(man.file, 'main.lua');
  assert.equal(man.eol, 'lf');
  assert.equal(man.size, size);
  assert.equal(man.sha256, sha256);
  assert.equal(man.build, (cur.match(/-- build: ([0-9a-f]{12})/) || [])[1]);
  assert.equal(man.version, (cur.match(/Version\s*=\s*"([^"]+)"/) || [])[1]);
});

test('o hash ignora CRLF x LF (o GitHub serve LF)', () => {
  const crlf = 'a\r\nb\r\n';
  assert.deepEqual(B.integrity(crlf), B.integrity('a\nb\n'));
});

test('grava main.lua + manifest.json numa cópia e regrava sem reclamar', () => {
  const root = copyProject('write');
  const r1 = B.run({ root, log: capture() });
  assert.equal(r1.reason, 'written');
  const man = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'));
  assert.equal(man.sha256, B.integrity(fs.readFileSync(path.join(root, 'main.lua'), 'utf8')).sha256);
  // segunda vez: o main.lua é o do build anterior, não uma edição à mão
  const r2 = B.run({ root, log: capture() });
  assert.equal(r2.reason, 'written');
});

test('main.lua editado à mão NÃO é sobrescrito (só com --force)', () => {
  const root = copyProject('manual');
  B.run({ root, log: capture() });
  const out = path.join(root, 'main.lua');
  const edited = fs.readFileSync(out, 'utf8').replace('-- HYGE', '-- HYGE (mexido à mão)').concat('\r\n-- extra\r\n');
  fs.writeFileSync(out, edited);
  const manBefore = fs.readFileSync(path.join(root, 'manifest.json'), 'utf8');

  const log = capture();
  const r = B.run({ root, log });
  assert.equal(r.ok, false);
  assert.equal(r.reason, 'manual-edit');
  assert.match(log.text(), /EDITADO À MÃO/);
  assert.equal(fs.readFileSync(out, 'utf8'), edited, 'o main.lua editado foi alterado');
  assert.equal(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'), manBefore);

  const f = B.run({ root, force: true, log: capture() });
  assert.equal(f.reason, 'written');
  assert.notEqual(fs.readFileSync(out, 'utf8'), edited);
});

test('main.lua sem o cabeçalho do build não é sobrescrito', () => {
  const root = copyProject('noheader');
  const out = path.join(root, 'main.lua');
  fs.writeFileSync(out, 'print("colado à mão")\n');
  const r = B.run({ root, log: capture() });
  assert.equal(r.reason, 'no-header');
  assert.equal(fs.readFileSync(out, 'utf8'), 'print("colado à mão")\n');
});

test('um clone com LF não conta como edição à mão', () => {
  const root = copyProject('lf');
  B.run({ root, log: capture() });
  const out = path.join(root, 'main.lua');
  fs.writeFileSync(out, B.toLF(fs.readFileSync(out, 'utf8')));
  assert.equal(B.manualEditState(out), null);
  assert.equal(B.run({ root, log: capture() }).reason, 'written');
});
