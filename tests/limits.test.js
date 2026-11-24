// Etapa 1 — limites do Luau: 200 locais e 200 upvalues por função
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const B = require('../build');
const { ROOT, fixture, cleanup, capture } = require('./helpers/project');

test.after(cleanup);

const locals = (n, prefix = 'L') =>
  Array.from({ length: n }, (_, i) => `local ${prefix}${i} = ${i}`).join('\n') + '\n';

// o núcleo do fixture já declara 1 local (V8)
test('chunk principal com 200 locais passa', () => {
  const root = fixture({ 'src/00_core/01_many.lua': locals(199) });
  const r = B.run({ root, check: true, log: capture() });
  assert.equal(r.ok, true);
  assert.equal(r.analysis.main.locals, 200);
});

test('chunk principal com 201 locais é recusado (não compila no executor)', () => {
  const root = fixture({ 'src/00_core/01_many.lua': locals(200) });
  const log = capture();
  const r = B.run({ root, log });
  assert.equal(r.reason, 'check-failed');
  assert.equal(r.analysis.main.locals, 201);
  assert.match(log.text(), /ESTOUROU 200 LOCAIS: <chunk principal> \(201\)/);
  assert.match(log.text(), /pico em src\/00_core\/01_many\.lua:200/);
});

test('perto do limite (>= 192) dá aviso, mas passa', () => {
  const root = fixture({ 'src/00_core/01_many.lua': locals(191) });
  const log = capture();
  assert.equal(B.run({ root, check: true, log }).ok, true);
  assert.match(log.text(), /192\/200  << perto do limite!/);
});

test('o limite vale também dentro de um módulo isolado (função própria)', () => {
  const body = 'do\n' + locals(201, 'M') + 'V8.m = M0\nend\n';
  const root = fixture({ 'src/10_ui/00_big.lua': body });
  const r = B.run({ root, check: true, log: capture() });
  assert.equal(r.reason, 'check-failed');
  assert.ok(r.analysis.overLocals.some(f => f.value === 201));
});

test('locais em blocos irmãos não se somam (o escopo fecha)', () => {
  const body = 'do\n' + locals(150, 'A') + 'V8.a = A0\nend\ndo\n' + locals(150, 'B') + 'V8.b = B0\nend\n';
  const root = fixture({ 'src/10_ui/00_blocks.lua': body });
  assert.equal(B.run({ root, check: true, log: capture() }).ok, true);
});

const sum = (n, prefix) => Array.from({ length: n }, (_, i) => `${prefix}${i}`).join(' + ');

test('upvalues são contados por função (150 passa)', () => {
  const root = fixture({
    'src/00_core/01_up.lua': locals(150, 'U') + 'V8.f = function() return ' + sum(150, 'U') + ' end\n',
  });
  const r = B.run({ root, check: true, log: capture() });
  assert.equal(r.ok, true);
  assert.equal(r.analysis.topUpvals[0].value, 150);
});

test('mais de 200 upvalues numa função é recusado', () => {
  // os 201 locais ficam em 2 blocos de uma função externa (nenhum bloco passa
  // de 200 locais); a função interna enxerga os 201 = 201 upvalues
  const outer = 'V8.g = function()\n'
    + 'local a = {}\ndo\n' + locals(101, 'A')
    + '  do\n' + locals(100, 'B')
    + '    a.f = function() return ' + sum(101, 'A') + ' + ' + sum(100, 'B') + ' end\n'
    + '  end\nend\nreturn a\nend\n';
  const log = capture();
  const r = B.run({ root: fixture({ 'src/00_core/01_up.lua': outer }), check: true, log });
  assert.equal(r.reason, 'check-failed');
  assert.ok(r.analysis.overUpvals.some(f => f.value === 201), log.text());
});

test('o projeto real tem folga no chunk principal', () => {
  const r = B.run({ root: ROOT, check: true, log: capture() });
  assert.ok(r.analysis.main.locals < 200, `chunk principal com ${r.analysis.main.locals} locais`);
});
