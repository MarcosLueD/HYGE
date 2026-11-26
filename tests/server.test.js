// Servidor (server/HYGE_AdminServer.server.lua) com o Roblox imitado.
// NÃO substitui o teste no Studio (docs/TESTES.md): aqui conferimos a lógica
// de cargo/permissão/validação/limite/registro; lá, o comportamento real.
'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { runLua, source } = require('./helpers/lua');

const SERVER = 'server/HYGE_AdminServer.server.lua';
// patch: muda o CONFIG do script por substituição de texto
const server = (patch = s => s) => ({ name: SERVER, code: patch(source(SERVER).code) });
const run = (code, patch) => runLua(['tests/helpers/roblox_server.lua', server(patch), { name: 'teste.lua', code: `
  OWNER = AddPlayer("Dono", 1)            -- dono do jogo = cargo 3
  BOB = AddPlayer("Bob", 200)             -- jogador comum
  CAROL = AddPlayer("Carol", 300)         -- jogador comum
  ${code}` }]);

// troca que não acha o texto falha (senão o teste passaria por engano)
const sub = (from, to) => s => {
  const out = s.replace(from, to);
  if (out === s) throw new Error('patch não achou no servidor: ' + from);
  return out;
};
const ADMINS = (...ids) => sub('-- 123456789,', ids.join(', ') + ',');
const MODS = (...ids) => sub('-- 987654321,', ids.join(', ') + ',');
const both = (...fs) => s => fs.reduce((acc, f) => f(acc), s);

const ACTIONS = ['AdminKick', 'AdminPull', 'AdminFreeze', 'AdminTeleport', 'AdminAnnounce',
  'AdminWhisper', 'AdminFling', 'AdminSpin', 'AdminTrip', 'AdminLaunch', 'AdminSit',
  'AdminScale', 'AdminBalloon'];
const LUA_ACTIONS = '{ ' + ACTIONS.map(a => `"${a}"`).join(', ') + ' }';

// ---- permissão: quem pode -----------------------------------------------------
test('admin autorizado: ação permitida (e registrada)', () => {
  run(`
    Call("AdminKick", OWNER, BOB.UserId, "spam")
    assert(BOB.kicked == "[f]spam", "não kickou: " .. tostring(BOB.kicked))
    assert(NotesFor(OWNER):find("✓ Kick: Bob"))
    local a = LastAudit()
    assert(a.ok and a.action == "kick" and a.by == 1 and a.target == 200)
  `);
});

test('jogador comum: ação recusada em TODOS os 13 remotes (e sem resposta)', () => {
  run(`
    for _, n in ipairs(${LUA_ACTIONS}) do
      assert(REMOTES[n], "remote não criado: " .. n)
      -- até mandando "sou admin" junto: o servidor não lê autorização do cliente
      Call(n, BOB, CAROL.UserId, "tiny", { admin = true, isAdmin = true, level = 3 })
      local a = LastAudit()
      assert(a.ok == false and a.action == n and a.reason == "não é admin", n)
    end
    assert(CAROL.kicked == nil and CAROL.Character.scale == nil)
    assert(#REMOTES.AdminAnnounce.sent == 0)
    assert(NotesFor(BOB) == "", "recusa de não-admin não deve virar resposta")
    assert(Said(WARNS, "RECUSADO Bob"), "recusa não foi para o Output")
  `);
});

test('cargos: moderador usa a moderação, mas não troll nem anúncio', () => {
  run(`
    local MOD = AddPlayer("Mod", 400)
    Call("AdminKick", MOD, BOB.UserId)
    assert(BOB.kicked, "moderador deveria poder kickar")
    Call("AdminFling", MOD, CAROL.UserId)
    local a = LastAudit()
    assert(a.ok == false and a.reason:find("sem permissão"), tostring(a.reason))
    local r = LastResult(MOD)
    assert(r.ok == false and r.code == "perm" and r.message:find("moderador"), r.message)
    Call("AdminAnnounce", MOD, "oi")
    assert(#REMOTES.AdminAnnounce.sent == 0, "moderador anunciou")
    assert(LastResult(MOD).code == "perm")
  `, MODS(400));
});

test('cargos: ninguém age sobre cargo igual ou maior; o dono age sobre admin', () => {
  run(`
    local A1, A2 = AddPlayer("Adm1", 555), AddPlayer("Adm2", 556)
    local MOD = AddPlayer("Mod", 400)
    Call("AdminKick", A1, 556, "x")                 -- admin x admin
    assert(A2.kicked == nil)
    assert(LastAudit().reason:find("alvo protegido"), LastAudit().reason)
    assert(LastResult(A1).code == "protected" and NotesFor(A1):find("cargo igual ou maior"))
    Call("AdminFreeze", MOD, 555, true)             -- moderador x admin
    assert(A1.Character:FindFirstChild("HumanoidRootPart").Anchored == false, "moderador congelou um admin")
    assert(LastResult(MOD).code == "protected")
    Call("AdminFreeze", A1, 400, true)              -- admin x moderador: pode
    assert(MOD.Character:FindFirstChild("HumanoidRootPart").Anchored == true)
    Call("AdminKick", OWNER, 556, "x")              -- dono x admin: pode
    assert(A2.kicked, "o dono deveria poder kickar um admin")
  `, both(ADMINS(555, 556), MODS(400)));
});

test('CONFIG.Permissions vale, e valor inválido fica só para o dono', () => {
  run(`
    local A, MOD = AddPlayer("Adm", 555), AddPlayer("Mod", 400)
    Call("AdminKick", MOD, BOB.UserId)
    assert(BOB.kicked == nil and LastResult(MOD).code == "perm", "kick agora é só admin")
    Call("AdminSit", A, CAROL.UserId)
    assert(LastResult(A).code == "perm", "Sit = 7 é inválido: só o dono")
    Call("AdminSit", OWNER, CAROL.UserId)
    assert(LastAudit().ok and LastAudit().action == "sit")
    assert(Said(WARNS, "AdminSit = 7 é inválido"), "não avisou do CONFIG inválido")
  `, both(ADMINS(555), MODS(400), sub('AdminKick     = 1,', 'AdminKick     = 2,'),
          sub('AdminSit      = 2,', 'AdminSit      = 7,')));
});

test('admin por grupo; consulta ao grupo falhou = sem cargo', () => {
  run(`
    local mod = AddPlayer("Mod", 700, { ranks = { [77] = 255 } })
    local fora = AddPlayer("Fora", 701, { rankError = true })
    local baixo = AddPlayer("Baixo", 702, { ranks = { [77] = 100 } })
    Call("AdminSit", mod, BOB.UserId)
    assert(LastAudit().ok, "rank 255 do grupo deveria ser admin")
    Call("AdminSit", fora, BOB.UserId)
    assert(LastAudit().ok == false and LastAudit().reason == "não é admin")
    -- GroupModRank = 100: moderador (kick sim, troll não)
    Call("AdminKick", baixo, CAROL.UserId)
    assert(CAROL.kicked, "rank 100 deveria ser moderador")
    Call("AdminSit", baixo, BOB.UserId)
    assert(LastResult(baixo).code == "perm")
  `, both(sub(/GroupId\s*=\s*0,/, 'GroupId       = 77,'), sub(/GroupModRank\s*=\s*0,/, 'GroupModRank  = 100,')));
});

test('Studio: jogadores de teste com UserId negativo funcionam (admin -1 age sobre -2)', () => {
  run(`
    local p1 = AddPlayer("Player1", -1)
    local p2 = AddPlayer("Player2", -2)
    Call("AdminSit", p1, -2)
    assert(LastAudit().ok and LastAudit().action == "sit", tostring(LastAudit().reason))
    Call("AdminSit", p2, -1)                       -- Player2 não está em AdminIds
    assert(LastAudit().ok == false and LastAudit().reason == "não é admin")
  `, ADMINS(-1));
});

// ---- HYGE_Status (o painel pergunta o cargo) ------------------------------------
test('HYGE_Status: cargo e ações liberadas; quem não tem cargo não recebe a lista', () => {
  run(`
    local MOD = AddPlayer("Mod", 400)
    local s = Ask(OWNER)
    assert(s.hyge == "9.2" and s.level == 3 and s.role == "dono")
    for _, n in ipairs(${LUA_ACTIONS}) do assert(s.actions[n], "dono sem " .. n) end
    assert(s.cooldowns.AdminKick == 1 and s.cooldowns.AdminAnnounce == 5 and s.maxText == 200)
    local m = Ask(MOD)
    assert(m.level == 1 and m.role == "moderador")
    assert(m.actions.AdminKick and m.actions.AdminWhisper and not m.actions.AdminFling and not m.actions.AdminAnnounce)
    -- jogador comum: só versão e cargo 0, mesmo mandando "sou admin"
    local b = Ask(BOB, { level = 3, admin = true })
    assert(b.level == 0 and b.role == "jogador")
    assert(b.actions == nil and b.cooldowns == nil and b.maxText == nil, "lista vazou para quem não tem cargo")
  `, MODS(400));
});

test('HYGE_Status também conta no limite geral (e para de responder)', () => {
  run(`
    for i = 1, 30 do assert(Ask(BOB), "parou cedo: " .. i) end
    assert(Ask(BOB) == nil, "respondeu acima do limite")
    assert(LastAudit().reason == "excesso de pedidos")
    CLOCK = CLOCK + 5
    assert(Ask(BOB) == nil, "insistir durante o bloqueio tem que manter o bloqueio")
    CLOCK = CLOCK + 10.5
    assert(Ask(BOB), "não voltou depois de uma janela sem pedidos")
  `);
});

// ---- alvo ------------------------------------------------------------------------
test('alvo inexistente: ação recusada', () => {
  run(`
    Call("AdminKick", OWNER, 999999, "x")
    assert(LastAudit().ok == false and LastAudit().reason:find("alvo"))
    assert(NotesFor(OWNER):find("não está no servidor"))
    assert(LastResult(OWNER).code == "target")
  `);
});

test('alvo ausente: saiu do servidor, está sem personagem, ou é você mesmo', () => {
  run(`
    local bobId = BOB.UserId
    RemovePlayer(BOB)                              -- saiu entre o clique e o pedido
    Call("AdminKick", OWNER, bobId)
    assert(BOB.kicked == nil and LastResult(OWNER).code == "target")

    local DAN = AddPlayer("Dan", 401, { noCharacter = true })
    CLOCK = CLOCK + 2
    for _, n in ipairs({ "AdminSit", "AdminFling", "AdminFreeze", "AdminScale" }) do
      Call(n, OWNER, 401, n == "AdminScale" and "tiny" or nil)
      local r = LastResult(OWNER)
      assert(r.ok == false and r.code == "failed" and r.message:find("sem personagem"), n .. ": " .. tostring(r.message))
      assert(LastAudit().ok == false and LastAudit().reason == "falhou: alvo sem personagem", n)
    end

    CLOCK = CLOCK + 2
    Call("AdminPull", OWNER, OWNER.UserId)
    assert(LastResult(OWNER).message:find("não vale em você mesmo"))
    Call("AdminKick", OWNER, OWNER.UserId)
    assert(OWNER.kicked == nil and LastResult(OWNER).code == "target")
  `);
});

// ---- argumentos ------------------------------------------------------------------
for (const [name, call] of [
  ['UserId como texto', 'Call("AdminKick", OWNER, "200")'],
  ['UserId quebrado (1.5)', 'Call("AdminFreeze", OWNER, 200.5, true)'],
  ['UserId negativo', 'Call("AdminSit", OWNER, -200)'],
  ['UserId NaN', 'Call("AdminSit", OWNER, 0/0)'],
  ['UserId infinito', 'Call("AdminSit", OWNER, math.huge)'],
  ['motivo do kick é tabela', 'Call("AdminKick", OWNER, 200, { "x" })'],
  ['freeze com texto em vez de booleano', 'Call("AdminFreeze", OWNER, 200, "sim")'],
  ['spin com número', 'Call("AdminSpin", OWNER, 200, 1)'],
  ['scale com modo inventado', 'Call("AdminScale", OWNER, 200, "huge")'],
  ['scale com tabela', 'Call("AdminScale", OWNER, 200, { tiny = true })'],
  ['anúncio vazio', 'Call("AdminAnnounce", OWNER, "   ")'],
  ['anúncio que não é texto', 'Call("AdminAnnounce", OWNER, 42)'],
  ['mensagem privada gigante (100 KB)', 'Call("AdminWhisper", OWNER, 200, string.rep("a", 100000))'],
  ['bytes que não são UTF-8', 'Call("AdminAnnounce", OWNER, "oi \\255\\254")'],
  ['argumento a mais (sit com texto)', 'Call("AdminSit", OWNER, 200, "extra")'],
  ['argumento a mais (bring no formato da v9.1)', 'Call("AdminPull", OWNER, 200, "selected")'],
  ['argumento a mais (anúncio com 2 textos)', 'Call("AdminAnnounce", OWNER, "oi", "de novo")'],
]) {
  test(`argumento inválido (${name}): ação recusada`, () => {
    run(`
      ${call}
      local a = LastAudit()
      assert(a and a.ok == false, "não recusou")
      assert(BOB.kicked == nil and BOB.Character.scale == nil and BOB.Character.pivoted == nil, "fez a ação")
      assert(BOB.Character:FindFirstChild("HumanoidRootPart").Anchored == false, "congelou")
      assert(#REMOTES.AdminAnnounce.sent == 0, "anunciou")
      assert(#REMOTES.AdminWhisper.sent == 0, "mensagem entregue")
      assert(#FILTERED == 0, "texto inválido chegou a ir para o filtro")
      local r = LastResult(OWNER)
      assert(r and r.ok == false and (r.code == "args" or r.code == "target"), "o painel não soube o motivo")
    `);
  });
}

test('nil no fim não conta como argumento a mais', () => {
  run(`
    Call("AdminSit", OWNER, BOB.UserId, nil, nil)
    assert(LastAudit().ok and LastAudit().action == "sit", tostring(LastAudit().reason))
    CLOCK = CLOCK + 2
    Call("AdminKick", OWNER, BOB.UserId, nil)      -- motivo vazio = padrão
    assert(BOB.kicked == "[f]Removido por um admin", tostring(BOB.kicked))
  `);
});

test('motivo vazio no kick usa o padrão (o painel manda "" com o campo vazio)', () => {
  run(`
    Call("AdminKick", OWNER, BOB.UserId, "")
    assert(BOB.kicked == "[f]Removido por um admin", tostring(BOB.kicked))
  `);
});

// ---- limites de uso --------------------------------------------------------------
test('muitas requisições: limite da ação aplicado, e volta depois do tempo', () => {
  run(`
    Call("AdminAnnounce", OWNER, "um")
    Call("AdminAnnounce", OWNER, "dois")             -- logo em seguida
    assert(#REMOTES.AdminAnnounce.sent == 1, "passou do limite")
    assert(LastAudit().ok == false and LastAudit().reason:find("limite"))
    assert(NotesFor(OWNER):find("espere") and LastResult(OWNER).code == "cooldown")
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

test('limite geral por jogador: ações diferentes somam; volta quando a janela vira', () => {
  run(`
    local sits = function()
      local n = 0
      for _, e in ipairs(shared.HYGE_AUDIT) do if e.ok and e.action == "sit" then n = n + 1 end end
      return n
    end
    -- 30 pedidos em 9 s, cada um fora do limite da própria ação
    for i = 1, 30 do Call("AdminSit", OWNER, BOB.UserId) CLOCK = CLOCK + 0.3 end
    assert(sits() == 30, sits())
    local before = #ResultsFor(OWNER)
    Call("AdminSpin", OWNER, BOB.UserId, true)       -- 31º, outra ação
    assert(LastAudit().reason == "excesso de pedidos")
    assert(BOB.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("HYGE_Spin") == nil, "girou acima do limite")
    assert(#ResultsFor(OWNER) == before + 1 and LastResult(OWNER).code == "rate", "staff recebe UM aviso")
    for i = 1, 5 do Call("AdminSit", OWNER, BOB.UserId) end
    assert(#ResultsFor(OWNER) == before + 1, "o aviso não se repete a cada pedido")
    assert(sits() == 30)
    CLOCK = CLOCK + 10.5
    Call("AdminSit", OWNER, BOB.UserId)
    assert(sits() == 31, "não voltou depois de uma janela sem pedidos")
  `);
});

test('jogador comum martelando os Remotes não apaga o registro do admin', () => {
  run(`
    Call("AdminKick", OWNER, CAROL.UserId, "x")
    for i = 1, 1000 do
      local n = (${LUA_ACTIONS})[(i % 13) + 1]
      Call(n, BOB, OWNER.UserId, "lixo " .. i)
      CLOCK = CLOCK + 0.05
    end
    local kept, total = false, 0
    for _, e in ipairs(shared.HYGE_AUDIT) do
      if e.ok and e.action == "kick" and e.target == 300 then kept = true end
      if e.by == 200 then total = total + e.count end
    end
    assert(kept, "o kick do admin sumiu do registro")
    assert(#shared.HYGE_AUDIT <= 30, #shared.HYGE_AUDIT .. " entradas")
    assert(total == 1000, "recusas contadas: " .. total)
    local warns = 0 for _, w in ipairs(WARNS) do if w:find("RECUSADO Bob") then warns = warns + 1 end end
    assert(warns <= 26, warns .. " avisos no Output")
    assert(OWNER.kicked == nil)
  `);
});

test('registro guarda no máximo AuditSize entradas', () => {
  run(`
    for i = 1, 260 do Call("AdminSit", OWNER, BOB.UserId) CLOCK = CLOCK + 0.5 end
    assert(#shared.HYGE_AUDIT == 200, #shared.HYGE_AUDIT)
    -- e a mesma recusa repetida vira uma entrada só, com contador
    for i = 1, 25 do Call("AdminSit", BOB, CAROL.UserId) end
    local a = LastAudit()
    assert(a.ok == false and a.reason == "não é admin" and a.count == 25, tostring(a.count))
    local n = 0 for _, w in ipairs(WARNS) do if w:find("RECUSADO Bob") then n = n + 1 end end
    assert(n == 1, n .. " avisos repetidos")
  `);
});

// ---- texto e filtro --------------------------------------------------------------
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
    assert(NotesFor(OWNER):find("Mensagem entregue para Bob"))
  `);
});

test('texto longo é cortado em 200 caracteres sem partir caractere UTF-8', () => {
  run(`
    Call("AdminAnnounce", OWNER, string.rep("ç", 300))
    local sent = REMOTES.AdminAnnounce.sent[1].args[2]:sub(4)   -- tira o "[f]" do filtro falso
    assert(utf8.len(sent) == 200, "tamanho " .. tostring(utf8.len(sent)))
  `);
});

// ---- registro sem dados desnecessários --------------------------------------------
test('erro inesperado: o painel recebe só "erro interno"; o detalhe fica no Output', () => {
  run(`
    BOB.Character.PivotTo = function() error("Workspace.MapaSecreto.Porta:42: quebrou") end
    Call("AdminPull", OWNER, BOB.UserId)
    local r = LastResult(OWNER)
    assert(r.ok == false and r.code == "internal" and r.message:find("erro interno"))
    assert(not r.message:find("MapaSecreto"), "detalhe interno foi para o cliente")
    assert(LastAudit().reason == "erro interno")
    assert(not AuditText():find("MapaSecreto"), "detalhe interno foi para o registro")
    assert(Said(WARNS, "MapaSecreto"), "o detalhe tem que ficar no Output do servidor")
  `);
});

test('registro não guarda mensagem privada, motivo do kick nem argumento recusado', () => {
  run(`
    Call("AdminWhisper", OWNER, BOB.UserId, "segredo-123")
    Call("AdminKick", OWNER, CAROL.UserId, "motivo-xyz")
    CLOCK = CLOCK + 2
    Call("AdminScale", OWNER, BOB.UserId, "senha-abc")
    Call("AdminAnnounce", OWNER, "oi geral")
    local t = AuditText()
    assert(not t:find("segredo"), "texto da mensagem privada no registro")
    assert(not t:find("motivo%-xyz"), "motivo do kick no registro")
    assert(not t:find("senha"), "argumento recusado no registro")
    assert(t:find("%[f%]oi geral"), "anúncio (público, já filtrado) deveria estar")
    for _, e in ipairs(shared.HYGE_AUDIT) do
      for k in pairs(e) do
        assert(({ ok=1, by=1, name=1, action=1, target=1, extra=1, reason=1, time=1, count=1, last=1 })[k],
          "campo inesperado no registro: " .. k)
      end
    end
  `);
});

// ---- respostas e troll ------------------------------------------------------------
test('resposta estruturada: ação, ok, alvo e estado de liga/desliga', () => {
  run(`
    Call("AdminSpin", OWNER, BOB.UserId, true)
    local r = LastResult(OWNER)
    assert(r.action == "AdminSpin" and r.ok == true and r.code == "ok" and r.target == 200 and r.state == true)
    CLOCK = CLOCK + 1
    Call("AdminFreeze", OWNER, BOB.UserId, false)
    r = LastResult(OWNER)
    assert(r.action == "AdminFreeze" and r.state == false and r.message == "Unfreeze: Bob", r.message)
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
    assert(LastResult(OWNER).state == true)
    TASK_FLUSH()                                   -- passou o BalloonMax
    assert(root:FindFirstChild("HYGE_Balloon") == nil, "balão não desligou sozinho")
    local r = LastResult(OWNER)
    assert(r.state == false and r.message:find("desligou sozinho"), "o painel não soube que desligou")
  `);
});

// ---- painel entregue pelo servidor --------------------------------------------------
const PANEL = `
  local ls = Instance.new("LocalScript")
  ls.Name = "HYGE_Panel"
  ls.Parent = ServerStorage
`;
test('painel em ServerStorage: entregue só para quem tem cargo', () => {
  run(`
    ${PANEL}
    local MOD = AddPlayer("Mod", 400)
    local DAVE = AddPlayer("Dave", 402)
    local host = MOD:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HYGE_PanelHost")
    assert(host and host.ResetOnSpawn == false, "moderador não recebeu o painel")
    assert(host:FindFirstChild("HYGE_Panel").clonedFrom == ls, "não é a cópia do LocalScript")
    assert(DAVE:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HYGE_PanelHost") == nil, "jogador comum recebeu o painel")
    assert(LastAudit().ok and LastAudit().action == "panel" and LastAudit().by == 400)
  `, MODS(400));
});

test('painel: PanelMinLevel e LocalScript errado/ausente', () => {
  run(`
    local MOD = AddPlayer("Mod", 400)              -- ainda sem LocalScript: nada
    assert(MOD:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HYGE_PanelHost") == nil)
    ${PANEL}
    local MOD2 = AddPlayer("Mod2", 403)            -- PanelMinLevel = 2: moderador não recebe
    assert(MOD2:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HYGE_PanelHost") == nil)
    local A = AddPlayer("Adm", 555)
    assert(A:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HYGE_PanelHost"), "admin não recebeu")
    ls.Name = "outro"
    local s = Instance.new("Script") s.Name = "HYGE_Panel" s.Parent = ServerStorage
    local A2 = AddPlayer("Adm2", 556)
    assert(A2:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HYGE_PanelHost") == nil, "entregou um Script")
    assert(Said(WARNS, "não é LocalScript"))
  `, both(ADMINS(555, 556), MODS(400, 403), s => s.replace('PanelMinLevel = 1,', 'PanelMinLevel = 2,')));
});
