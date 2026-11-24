// Roda Lua de verdade nos testes (fengari = VM Lua 5.3 em JS).
// Cada chamada cria um estado novo: prelude (imitação do Roblox/executor) +
// os arquivos pedidos + o código do teste. O teste Lua usa assert/error;
// qualquer erro vira exceção aqui, com traceback.
'use strict';
const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const { ROOT } = require('./project');

const PRELUDE = fs.readFileSync(path.join(__dirname, 'prelude.lua'), 'utf8');

function source(rel) {
  return { name: rel, code: fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/^﻿/, '') };
}

// chunks: [{ name, code }] ou caminhos relativos à raiz do projeto.
// Devolve o valor (string/number/boolean) que o último chunk retornar.
function runLua(chunks) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  let result;
  for (const c of [{ name: 'prelude.lua', code: PRELUDE }, ...chunks.map(x => (typeof x === 'string' ? source(x) : x))]) {
    lua.lua_getglobal(L, to_luastring('debug'));
    lua.lua_getfield(L, -1, to_luastring('traceback'));
    lua.lua_remove(L, -2);
    const handler = lua.lua_gettop(L);
    if (lauxlib.luaL_loadbuffer(L, to_luastring(c.code), null, to_luastring('@' + c.name)) !== lua.LUA_OK) {
      throw new Error('não compila (' + c.name + '): ' + lua.lua_tojsstring(L, -1));
    }
    if (lua.lua_pcall(L, 0, 1, handler) !== lua.LUA_OK) {
      throw new Error(lua.lua_tojsstring(L, -1));
    }
    result = lua.lua_isnil(L, -1) ? undefined
      : lua.lua_isboolean(L, -1) ? lua.lua_toboolean(L, -1)
      : lua.lua_tojsstring(L, -1);
    lua.lua_settop(L, handler - 1);
  }
  return result;
}

// pedaço de um arquivo entre dois marcadores (inclusive)
function block(rel, begin, end) {
  const text = fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  const i = text.indexOf(begin);
  const j = text.indexOf(end, i);
  if (i < 0 || j < 0) throw new Error(`marcadores ${begin} / ${end} não achados em ${rel}`);
  return text.slice(i, j + end.length);
}

module.exports = { runLua, source, block };
