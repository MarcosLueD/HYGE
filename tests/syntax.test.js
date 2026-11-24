// Etapa 1 — erros de sintaxe e globais desconhecidas cancelam o build
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const B = require('../build');
const { copyProject, fixture, cleanup, capture } = require('./helpers/project');

test.after(cleanup);

function snapshot(root) {
  const read = f => (fs.existsSync(path.join(root, f)) ? fs.readFileSync(path.join(root, f), 'utf8') : null);
  return { main: read('main.lua'), manifest: read('manifest.json') };
}

test('erro de sintaxe numa CÓPIA do projeto: build cancelado e main.lua intacto', () => {
  const root = copyProject('syntax');
  B.run({ root, log: capture() });              // main.lua bom desta cópia
  const before = snapshot(root);

  const target = path.join(root, 'src', '20_features', '00_fly.lua');
  const lines = fs.readFileSync(target, 'utf8').split(/\r?\n/);
  lines.splice(9, 0, 'local quebrado = = 1');  // linha 10 do arquivo
  fs.writeFileSync(target, lines.join('\n'));

  const log = capture();
  const r = B.run({ root, log });
  assert.equal(r.ok, false);
  assert.equal(r.reason, 'check-failed');
  assert.match(log.text(), /ERRO DE SINTAXE em src\/20_features\/00_fly\.lua:10\b/);
  assert.match(log.text(), /Build CANCELADO/);
  assert.deepEqual(snapshot(root), before, 'main.lua ou manifest.json mudou com o build cancelado');
});

test('erro de sintaxe também cancela o --check', () => {
  const root = fixture({ 'src/10_ui/00_x.lua': 'do\n  V8.x = function( end\nend\n' });
  const r = B.run({ root, check: true, log: capture() });
  assert.equal(r.reason, 'check-failed');
  assert.ok(r.analysis.syntax, 'deveria ter acusado sintaxe');
});

test('global desconhecida (erro de digitação) cancela o build e diz onde', () => {
  const root = fixture({ 'src/10_ui/00_typo.lua': 'do\n  V8.n = 1\n  Lgo("oi")\nend\n' });
  const log = capture();
  const r = B.run({ root, log });
  assert.equal(r.reason, 'check-failed');
  assert.deepEqual(r.analysis.unknownGlobals.map(g => g.name), ['Lgo']);
  assert.match(log.text(), /Lgo\s+— src\/10_ui\/00_typo\.lua:3/);
  assert.equal(fs.existsSync(path.join(root, 'main.lua')), false);
});

test('local de outro módulo usada fora de escopo vira global desconhecida', () => {
  // local dentro de um módulo isolado não existe para o módulo seguinte
  const root = fixture({
    'src/10_ui/00_a.lua': 'do\n  local Segredo = 1\n  V8.a = Segredo\nend\n',
    'src/10_ui/01_b.lua': 'do\n  V8.b = Segredo\nend\n',
  });
  const r = B.run({ root, check: true, log: capture() });
  assert.equal(r.reason, 'check-failed');
  assert.deepEqual(r.analysis.unknownGlobals.map(g => g.name), ['Segredo']);
});

test('APIs de executor e do Roblox não contam como globais desconhecidas', () => {
  const root = fixture({
    'src/10_ui/00_ok.lua': 'do\n  if typeof(writefile) == "function" then V8.w = game:GetService("Players") end\n'
      + '  V8.v = Vector3.new(0, 1, 0)\n  task.defer(function() end)\nend\n',
  });
  assert.equal(B.run({ root, check: true, log: capture() }).ok, true);
});
