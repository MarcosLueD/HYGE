// =============================================================================
// HYGE — validador estático do script (roda fora do Roblox)
//
//   * sintaxe Lua 5.1 (o painel não usa nada exclusivo do Luau)
//   * limite do Luau de 200 locais ativos por função — o chunk principal do
//     painel vive perto disso; estourar = o script nem compila no executor
//   * limite de 200 upvalues por função
//   * globais desconhecidas (erro de digitação vira nil e só explode em jogo)
//
// Uso direto:   node tools/check.js main.lua
// Usado também pelo build.js (exporta analyze()).
// =============================================================================
'use strict';
const fs = require('fs');

const LIMIT_LOCALS = 200;
const LIMIT_UPVALUES = 200;
const WARN_LOCALS = 192;   // avisa antes de estourar

// Globais que o painel pode usar: Roblox, Lua padrão e APIs de executor
// (estas sempre testadas com typeof/pcall antes de usar).
const ALLOWED = new Set(`
  game workspace script Enum Instance Color3 UDim UDim2 Vector2 Vector3 CFrame
  TweenInfo NumberSequence NumberSequenceKeypoint ColorSequence ColorSequenceKeypoint
  NumberRange Rect BrickColor Ray RaycastParams OverlapParams Random DateTime Region3
  PhysicalProperties Font task typeof tick time wait spawn delay warn print error
  assert pcall xpcall ipairs pairs next select type tostring tonumber unpack rawget
  rawset rawequal setmetatable getmetatable math string table os coroutine utf8
  bit32 debug require _G shared
  gethui syn setclipboard writefile readfile isfile makefolder isfolder delfile
`.split(/\s+/).filter(Boolean));

function analyze(code) {
  let luaparse;
  try { luaparse = require('luaparse'); }
  catch (_) { return { skipped: 'luaparse não instalado (rode: npm install)' }; }

  let ast;
  try {
    ast = luaparse.parse(code, { luaVersion: '5.1', locations: true, scope: false, comments: false });
  } catch (e) {
    return { syntax: { line: e.line || 0, message: e.message } };
  }

  const funcs = [];
  const globals = new Map();
  let uniq = 0;

  const newFunc = (name, line, parent) => {
    const f = { name, line, parent, active: 0, maxLocals: 0, maxLine: line, upvals: new Set(), scopes: [] };
    funcs.push(f);
    return f;
  };
  const pushScope = f => f.scopes.push(new Map());
  const popScope = f => { f.active -= f.scopes.pop().size; };
  const declare = (f, name, line) => {
    const s = f.scopes[f.scopes.length - 1];
    s.set(s.has(name) ? name + '#' + (uniq++) : name, true);
    f.active++;
    if (f.active > f.maxLocals) { f.maxLocals = f.active; f.maxLine = line; }
  };
  const resolve = (f, name, line) => {
    for (let cur = f; cur; cur = cur.parent) {
      for (let i = cur.scopes.length - 1; i >= 0; i--) {
        if (cur.scopes[i].has(name)) {
          if (cur !== f) for (let c = f; c && c !== cur; c = c.parent) c.upvals.add(name);
          return;
        }
      }
    }
    if (!globals.has(name)) globals.set(name, line);
  };
  const L = n => (n && n.loc ? n.loc.start.line : 0);

  function walkExpr(f, n) {
    if (!n || typeof n !== 'object') return;
    switch (n.type) {
      case 'Identifier': resolve(f, n.name, L(n)); return;
      case 'FunctionDeclaration': walkFunction(f, n, '<anônima>', false); return;
      case 'MemberExpression': walkExpr(f, n.base); return;
      case 'TableKeyString': walkExpr(f, n.value); return;
      default:
        for (const k of Object.keys(n)) {
          if (k === 'loc' || k === 'range') continue;
          const v = n[k];
          if (Array.isArray(v)) v.forEach(x => walkAny(f, x));
          else if (v && typeof v === 'object' && v.type) walkAny(f, v);
        }
    }
  }
  function walkBlock(f, body) { pushScope(f); body.forEach(s => walkAny(f, s)); popScope(f); }
  function walkFunction(f, n, name, method) {
    const g = newFunc(name, L(n), f);
    pushScope(g);
    if (method) declare(g, 'self', L(n));
    n.parameters.forEach(p => { if (p.type === 'Identifier') declare(g, p.name, L(p)); });
    n.body.forEach(s => walkAny(g, s));
    popScope(g);
  }
  function walkAny(f, n) {
    if (!n || typeof n !== 'object') return;
    switch (n.type) {
      case 'LocalStatement':
        n.init.forEach(e => walkExpr(f, e));
        n.variables.forEach(v => declare(f, v.name, L(v)));
        return;
      case 'FunctionDeclaration': {
        if (n.isLocal && n.identifier) {
          declare(f, n.identifier.name, L(n));
          walkFunction(f, n, n.identifier.name, false);
          return;
        }
        let nm = '<anônima>', method = false;
        if (n.identifier) {
          walkExpr(f, n.identifier);
          if (n.identifier.type === 'Identifier') nm = n.identifier.name;
          else if (n.identifier.type === 'MemberExpression') {
            nm = (n.identifier.base.name || '?') + n.identifier.indexer + n.identifier.identifier.name;
            method = n.identifier.indexer === ':';
          }
        }
        walkFunction(f, n, nm, method);
        return;
      }
      case 'DoStatement': walkBlock(f, n.body); return;
      case 'WhileStatement': walkExpr(f, n.condition); walkBlock(f, n.body); return;
      case 'RepeatStatement':
        pushScope(f); n.body.forEach(s => walkAny(f, s)); walkExpr(f, n.condition); popScope(f); return;
      case 'IfStatement':
        n.clauses.forEach(c => { if (c.condition) walkExpr(f, c.condition); walkBlock(f, c.body); });
        return;
      case 'ForNumericStatement':
        walkExpr(f, n.start); walkExpr(f, n.end); walkExpr(f, n.step);
        pushScope(f); declare(f, n.variable.name, L(n));
        n.body.forEach(s => walkAny(f, s)); popScope(f); return;
      case 'ForGenericStatement':
        n.iterators.forEach(e => walkExpr(f, e));
        pushScope(f); n.variables.forEach(v => declare(f, v.name, L(v)));
        n.body.forEach(s => walkAny(f, s)); popScope(f); return;
      default:
        walkExpr(f, n);
    }
  }

  const main = newFunc('<chunk principal>', 1, null);
  pushScope(main);
  ast.body.forEach(s => walkAny(main, s));

  const byLocals = [...funcs].sort((a, b) => b.maxLocals - a.maxLocals);
  const byUpvals = [...funcs].sort((a, b) => b.upvals.size - a.upvals.size);
  return {
    main: { locals: main.maxLocals, line: main.maxLine },
    topLocals: byLocals.slice(0, 3).map(f => ({ name: f.name, line: f.line, value: f.maxLocals, at: f.maxLine })),
    topUpvals: byUpvals.slice(0, 3).map(f => ({ name: f.name, line: f.line, value: f.upvals.size })),
    overLocals: funcs.filter(f => f.maxLocals > LIMIT_LOCALS).map(f => ({ name: f.name, line: f.line, value: f.maxLocals, at: f.maxLine })),
    overUpvals: funcs.filter(f => f.upvals.size > LIMIT_UPVALUES).map(f => ({ name: f.name, line: f.line, value: f.upvals.size })),
    unknownGlobals: [...globals].filter(([n]) => !ALLOWED.has(n)).map(([name, line]) => ({ name, line })),
  };
}

// Imprime o relatório. 'where(line)' traduz linha do arquivo final -> origem.
function report(r, where = l => 'linha ' + l) {
  if (r.skipped) { console.log('  (validação pulada: ' + r.skipped + ')'); return true; }
  if (r.syntax) { console.log('  ERRO DE SINTAXE em ' + where(r.syntax.line) + '\n    ' + r.syntax.message); return false; }

  let ok = true;
  const m = r.main;
  console.log(`  sintaxe ............ ok`);
  console.log(`  locais no chunk .... ${m.locals}/${LIMIT_LOCALS}` + (m.locals >= WARN_LOCALS ? '  << perto do limite!' : ''));
  if (r.overLocals.length) {
    ok = false;
    r.overLocals.forEach(f => console.log(`  ESTOUROU 200 LOCAIS: ${f.name} (${f.value}) — pico em ${where(f.at)}`));
  }
  if (r.overUpvals.length) {
    ok = false;
    r.overUpvals.forEach(f => console.log(`  ESTOUROU 200 UPVALUES: ${f.name} (${f.value}) em ${where(f.line)}`));
  }
  const u = r.topUpvals[0];
  if (u) console.log(`  maior nº upvalues .. ${u.value} (${u.name}, ${where(u.line)})`);
  if (r.unknownGlobals.length) {
    ok = false;
    console.log('  GLOBAIS DESCONHECIDAS (erro de digitação? local fora de escopo?):');
    r.unknownGlobals.forEach(g => console.log(`    ${g.name}  — ${where(g.line)}`));
  } else {
    console.log('  globais ............ ok');
  }
  return ok;
}

module.exports = { analyze, report };

if (require.main === module) {
  const file = process.argv[2] || 'main.lua';
  const code = fs.readFileSync(file, 'utf8').replace(/^﻿/, '');
  console.log('Validando ' + file);
  const ok = report(analyze(code));
  process.exit(ok ? 0 : 1);
}
