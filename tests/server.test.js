// Etapa 5 — auditoria do servidor (server/HYGE_AdminServer.server.lua) com o
// Roblox imitado. NÃO substitui o teste no Studio (docs/TESTES.md): aqui
// conferimos a lógica de permissão/validação; lá, o comportamento real.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { runLua, source } = require('./helpers/lua');

const SERVER = 'server/HYGE_AdminServer.server.lua';
// patch: dá para mudar o CONFIG do script por substituição de texto
function server(patch = s => s) {
  const s = source(SERVER);
  return { name: SERVER, code: patch(s.code) };
}
const run = (code, patch) => runLua(['tests/helpers/roblox_server.lua', server(patch), { name: 'teste.lua', code: `
  OWNER = AddPlayer("Dono", 1)            -- dono do jogo = admin
  BOB = AddPlayer("Bob", 200)             -- jogador comum
  CAROL = AddPlayer("Carol", 300)         -- jogador comum
  ${code}` }]);

// ---- a matriz do plano -------------------------------------------------------
test('admin autorizado: ação permitida (e registrada)', () => {
  run(`
    Call("AdminKick", OWNER, BOB.UserId, "spam")
    assert(BOB.kicked == "[f]spam", "não kickou: " .. tostring(BOB.kicked))
    assert(NotesFor(OWNER):find("✓ Kick: Bob"))
    local a = LastAudit()
    assert(a.ok and a.action == "kick" and a.by == 1 and a.target == 200)
  `);
});

test('jogador comum: ação recusada em TODOS os 13 remotes', () => {
  run(`
    local names = { "AdminKick", "AdminPull", "AdminFreeze", "AdminTeleport", "AdminAnnounce",
      "AdminWhisper", "AdminFling", "AdminSpin", "AdminTrip", "AdminLaunch", "AdminSit",
      "AdminScale", "AdminBalloon" }
    for _, n in ipairs(names) do
      assert(REMOTES[n], "remote não criado: " .. n)
      -- até mandando "sou admin" junto: o servidor não lê autorização do cliente
      Call(n, BOB, CAROL.UserId, "tiny", { admin = true, isAdmin = true })
      local a = LastAudit()
      assert(a.ok == false and a.action == n and a.reason == "não é admin", n)
    end
    assert(CAROL.kicked == nil and CAROL.Character.scale == nil)
    assert(#REMOTES.AdminAnnounce.sent == 0)
    assert(NotesFor(BOB) == "", "recusa de não-admin não deve virar resposta")
    assert(Said(WARNS, "RECUSADO Bob"), "recusa não foi para o Output")
  `);
});

test('alvo inexistente: ação recusada', () => {
  run(`
    Call("AdminKick", OWNER, 999999, "x")
    assert(LastAudit().ok == false and LastAudit().reason:find("alvo"))
    assert(NotesFor(OWNER):find("não está no servidor"))
  `);
});

for (const [name, call] of [
  ['UserId como texto', 'Call("AdminKick", OWNER, "200")'],
  ['UserId quebrado (1.5)', 'Call("AdminFreeze", OWNER, 200.5, true)'],
  ['UserId negativo', 'Call("AdminSit", OWNER, -200)'],
  ['UserId NaN', 'Call("AdminSit", OWNER, 0/0)'],
  ['motivo do kick é tabela', 'Call("AdminKick", OWNER, 200, { "x" })'],
  ['freeze com texto em vez de booleano', 'Call("AdminFreeze", OWNER, 200, "sim")'],
  ['spin com número', 'Call("AdminSpin", OWNER, 200, 1)'],
  ['scale com modo inventado', 'Call("AdminScale", OWNER, 200, "huge")'],
  ['scale com tabela', 'Call("AdminScale", OWNER, 200, { tiny = true })'],
  ['anúncio vazio', 'Call("AdminAnnounce", OWNER, "   ")'],
  ['anúncio que não é texto', 'Call("AdminAnnounce", OWNER, 42)'],
  ['mensagem privada gigante (100 KB)', 'Call("AdminWhisper", OWNER, 200, string.rep("a", 100000))'],
  ['bytes que não são UTF-8', 'Call("AdminAnnounce", OWNER, "oi \\255\\254")'],
]) {
  test(`argumento inválido (${name}): ação recusada`, () => {
    run(`
      ${call}
      local a = LastAudit()
      assert(a and a.ok == false, "não recusou")
      assert(BOB.kicked == nil and BOB.Character.scale == nil, "fez a ação")
      assert(BOB.Character.HumanoidRootPart == nil or true)
      assert(#REMOTES.AdminAnnounce.sent == 0, "anunciou")
      for _, s in ipairs(REMOTES.AdminWhisper.sent) do assert(s.args[1] == "HYGE", "mensagem entregue") end
      assert(#FILTERED == 0, "texto inválido chegou a ir para o filtro")
    `);
  });
}

test('muitas requisições: limite da ação aplicado, e volta depois do tempo', () => {
  run(`
    Call("AdminAnnounce", OWNER, "um")
    Call("AdminAnnounce", OWNER, "dois")             -- logo em seguida
    assert(#REMOTES.AdminAnnounce.sent == 1, "passou do limite")
    assert(LastAudit().ok == false and LastAudit().reason:find("limite"))
    assert(NotesFor(OWNER):find("espere"))
    -- outra ação não é bloqueada pelo limite do anúncio
    Call("AdminSit", OWNER, BOB.UserId)
    assert(LastAudit().ok and LastAudit().action == "sit")
    CLOCK = CLOCK + 5.1
    Call("AdminAnnounce", OWNER, "três")
    assert(#REMOTES.AdminAnnounce.sent == 2)
    -- 50 kicks seguidos: só o primeiro passa
    local p = {}
    for i = 1, 50 do p[i] = AddPlayer("Alvo" .. i, 1000 + i) end
    for i = 1, 50 do Call("AdminKick", OWNER, 1000 + i) end
    local kicked = 0
    for i = 1, 50 do if p[i].kicked then kicked = kicked + 1 end end
    assert(kicked == 1, kicked .. " kicks passaram")
  `);
});

test('texto recusado pelo filtro: mensagem NÃO é enviada', () => {
  run(`
    FILTER = "error"
    Call("AdminAnnounce", OWNER, "oi pessoal")
    assert(#REMOTES.AdminAnnounce.sent == 0)
    assert(NotesFor(OWNER):find("nada foi enviado"))
    CLOCK = CLOCK + 10
    FILTER = "hash"                                  -- filtro censurou tudo
    Call("AdminAnnounce", OWNER, "palavrão")
    assert(#REMOTES.AdminAnnounce.sent == 0, "mandou ######## para todos")
    Call("AdminWhisper", OWNER, BOB.UserId, "palavrão")
    for _, s in ipairs(REMOTES.AdminWhisper.sent) do assert(s.to ~= BOB, "mensagem censurada entregue") end
  `);
});

test('mensagens passam pelo filtro com o contexto certo (público x privado)', () => {
  run(`
    Call("AdminAnnounce", OWNER, "olá")
    local f = FILTERED[1]
    assert(f.ctx == "PublicChat" and f.from == 1 and f.to == "all")
    assert(REMOTES.AdminAnnounce.sent[1].args[2] == "[f]olá", "anúncio sem filtro")
    Call("AdminWhisper", OWNER, BOB.UserId, "segredo")
    f = FILTERED[2]
    assert(f.ctx == "PrivateChat" and f.to == 200, "filtro privado tem que ser para o destinatário")
    local got
    for _, s in ipairs(REMOTES.AdminWhisper.sent) do if s.to == BOB then got = s.args[2] end end
    assert(got == "[f]segredo")
  `);
});

test('texto longo é cortado em 200 caracteres sem partir caractere UTF-8', () => {
  run(`
    Call("AdminAnnounce", OWNER, string.rep("ç", 300))
    local sent = REMOTES.AdminAnnounce.sent[1].args[2]:sub(4)   -- tira o "[f]" do filtro falso
    assert(utf8.len(sent) == 200, "tamanho " .. tostring(utf8.len(sent)))
  `);
});

test('admin não age sobre outro admin (ProtectAdmins)', () => {
  run(`
    local other = AddPlayer("Moderador", 555)
    Call("AdminKick", OWNER, 555, "x")
    assert(other.kicked == nil)
    assert(LastAudit().reason == "alvo é admin")
    assert(NotesFor(OWNER):find("também é admin"))
  `, s => s.replace('-- 123456789,', '555,'));
});

test('admin por grupo; consulta ao grupo falhou = NÃO é admin', () => {
  run(`
    local mod = AddPlayer("Mod", 700, { ranks = { [77] = 255 } })
    local fora = AddPlayer("Fora", 701, { rankError = true })
    Call("AdminSit", mod, BOB.UserId)
    assert(LastAudit().ok, "rank 255 do grupo deveria ser admin")
    Call("AdminSit", fora, BOB.UserId)
    assert(LastAudit().ok == false and LastAudit().reason == "não é admin")
  `, s => s.replace(/GroupId\s*=\s*0,/, 'GroupId       = 77,'));
});

test('Studio: jogadores de teste com UserId negativo funcionam (admin -1 age sobre -2)', () => {
  run(`
    local p1 = AddPlayer("Player1", -1)
    local p2 = AddPlayer("Player2", -2)
    Call("AdminSit", p1, -2)
    assert(LastAudit().ok and LastAudit().action == "sit", tostring(LastAudit().reason))
    Call("AdminSit", p2, -1)                       -- Player2 não está em AdminIds
    assert(LastAudit().ok == false and LastAudit().reason == "não é admin")
  `, s => s.replace('-- 123456789,', '-1,'));
});

test('motivo vazio no kick usa o padrão (o painel manda "" com o campo vazio)', () => {
  run(`
    Call("AdminKick", OWNER, BOB.UserId, "")
    assert(BOB.kicked == "[f]Removido por um admin", tostring(BOB.kicked))
  `);
});

test('registro guarda no máximo AuditSize entradas', () => {
  run(`
    for i = 1, 260 do Call("AdminSit", BOB, CAROL.UserId) end
    assert(#shared.HYGE_AUDIT == 200, #shared.HYGE_AUDIT)
    -- e o Output não é inundado: a mesma recusa sai 1x a cada 10 s
    local n = 0 for _, w in ipairs(WARNS) do if w:find("RECUSADO Bob") then n = n + 1 end end
    assert(n == 1, n .. " avisos repetidos")
  `);
});

test('ações de troll ligam e desligam (spin / balloon) e o balão se desliga sozinho', () => {
  run(`
    Call("AdminSpin", OWNER, BOB.UserId, true)
    local root = BOB.Character:FindFirstChild("HumanoidRootPart")
    assert(root:FindFirstChild("HYGE_Spin"), "spin não criou a constraint")
    CLOCK = CLOCK + 1
    Call("AdminSpin", OWNER, BOB.UserId, false)
    assert(root:FindFirstChild("HYGE_Spin") == nil, "spin não desligou")
    Call("AdminBalloon", OWNER, BOB.UserId)        -- nil = liga
    assert(root:FindFirstChild("HYGE_Balloon"))
    TASK_FLUSH()                                   -- passou o BalloonMax
    assert(root:FindFirstChild("HYGE_Balloon") == nil, "balão não desligou sozinho")
  `);
});
