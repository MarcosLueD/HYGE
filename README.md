# HYGE Admin Panel v9.2

Painel admin client-side para Roblox (executor ou LocalScript) + script de
servidor para o **seu** jogo: as ações que afetam outros jogadores são pedidas
ao servidor por RemoteEvents, e ele confere cargo, permissão, alvo, argumentos
e limite antes de executar. Instalação: [`docs/SERVIDOR.md`](docs/SERVIDOR.md).

## Rodar sempre a versão mais nova (loader)

Cole o **`loader.lua`** no executor em vez do `main.lua`. Toda vez que roda, ele:

1. lê o **`manifest.json`** do GitHub (versão, build, tamanho e SHA-256 do `main.lua`);
2. se a cópia local (`HYGE/main.lua`) já é esse build, abre ela — nada a baixar;
3. senão baixa o `main.lua` e **confere**: tamanho, SHA-256, build e se compila;
4. só então a cópia anterior vira `HYGE/main.backup.lua` e a nova é guardada;
5. se qualquer passo falhar (sem internet, download cortado ou adulterado, build
   que não compila), abre **a última versão que funcionava** — a cópia local
   ou, se ela também não servir, o backup.

O SHA-256 é calculado no próprio loader (Lua puro), então não depende de
criptografia do executor. O hash é do texto com quebras de linha LF (o Git
guarda LF e o GitHub serve LF, mesmo que no Windows o arquivo fique com CRLF).
Precisa de `game:HttpGet` (ou `request`) e `loadstring`; `writefile`/`readfile`
são opcionais (cópia offline e backup).

Isso só funciona com o `main.lua` **publicado**: depois de `npm run build`,
faça commit e push do `main.lua` **e do `manifest.json`** (o build gera os
dois juntos). O painel aberto confere o manifesto a cada 15 minutos
(Configurações › Ajustes › Atualização) e avisa quando sai um build novo;
**ATUALIZAR AGORA** baixa, confere com o manifesto e troca sem sair do jogo —
arquivo que não bate é recusado e nada é trocado.

## Estrutura

```
HYGE/
├── loader.lua          ← cole ESTE no executor (baixa o main.lua mais novo)
├── main.lua            ← GERADO pelo build. É o arquivo que o loader baixa.
├── manifest.json       ← GERADO junto (versão, build, tamanho, SHA-256)
├── src/                ← código-fonte, dividido por assunto (edite aqui)
│   ├── 00_core/        config, temas, checagem de admin, estado, helpers
│   ├── 10_ui/          janela, toasts, console, topbar/sidebar, fábrica de UI, toggles/keybinds
│   ├── 20_features/    fly, noclip/god/invisível/paredes, ESP, chat spy/fullbright/anti-afk,
│   │                   freecam, drone, ações de moderação/troll + ponte com o servidor
│   │                   (v9.2: V8.Srv), spectate, anti-fall/anti-gravidade, walk on walls,
│   │                   Ctrl + clique TP
│   ├── 30_kit/         widgets v7 (sliders, switches, confirmação), ícones, chips, HUD do drone,
│   │                   rede/disco do executor (v9.1: gravação segura), tempo de jogo +
│   │                   cosméticos (Playtime Shop), pacotes de animação; v9.1: SHA-256,
│   │                   troca segura de perfil
│   ├── 40_tabs/        uma aba por arquivo: home (+ mapa/perfil), dashboard, movement, visuals,
│   │                   players, moderation, server, emotes, settings, shop, scripts, chat,
│   │                   troll, chat HYGE
│   ├── 50_v8/          dock, shell, situações, persistência (config.json), busca global,
│   │                   ilha, automático, celular, missões, atualização; v9.0: perfis,
│   │                   notificações, cor personalizada, macros, diagnóstico, novidades,
│   │                   ajustes organizados (19_settings_nav: sempre o último)
│   └── 90_runtime/     comandos, abrir/fechar/arrastar, teclas, scheduler, eventos, unload, boot
├── server/             ← no SEU jogo (para as ações em outros jogadores)
│   ├── HYGE_AdminServer.server.lua   (ServerScriptService)
│   ├── HYGE_AdminClient.client.lua   (StarterPlayer › StarterPlayerScripts)
│   └── chat-relay/server.js          (relay do Chat HYGE: roda num servidor Node seu)
├── tests/              ← npm test — veja "Testes"
├── docs/SERVIDOR.md    instalação e configuração do servidor (v9.2)
├── docs/TESTES.md      roteiro dos testes que só dá para fazer no Roblox
├── tools/check.js      validador estático (usado pelo build)
├── tools/leaks.js      procura conexões que o Unload não desconectaria (v9.1)
└── build.js            junta src/ → main.lua + manifest.json
```

A ordem do build é a ordem alfabética do caminho — por isso os prefixos
`00_`, `10_`, ... Um módulo pode usar tudo que foi declarado nos anteriores.

## Gerar o main.lua

Precisa do [Node.js](https://nodejs.org). Uma vez só:

```
npm install
```

Depois de editar qualquer coisa em `src/`:

```
npm run build      # valida e grava main.lua
npm run check      # só valida, não grava
```

O build **não grava** o `main.lua` se encontrar:

- erro de sintaxe — mostra `src/arquivo.lua:linha`
- variável global desconhecida (quase sempre erro de digitação ou local fora
  de escopo) — no Roblox isso só explodiria em jogo
- mais de **200 locais** no chunk principal (limite do Luau: o script nem
  carrega). O painel está em ~169. Código novo vai dentro de `do ... end` ou
  pendurado na tabela `V8` — nunca como `local` solto no topo de um módulo.
  Os módulos da v8.1 usam `do local function Build() ... end Build() end`:
  as locais ficam dentro da função e não contam no chunk.

**Módulos isolados (v9.0).** Todo módulo depois de `src/00_core/` que não
declara `local` no topo vai embrulhado em
`V8.Mod("src/arquivo.lua", ini, fim, function() ... end)` (na mesma linha da
primeira linha do arquivo, então as linhas do `main.lua` continuam batendo com
o `src/`). Se ele quebrar ao carregar, só ele falha: o painel abre, o boot
avisa e Configurações › Sistema › Diagnóstico mostra
`src/arquivo.lua:linha`. Módulo com `local` no topo (os de `00_core`, a
fábrica de UI, as features base) continua solto — essas locais são
compartilhadas com os módulos seguintes. O build mostra quantos foram
isolados. No fim do `main.lua` vai `V8.SrcMap`, que o log usa para trocar
`HYGE:12345:` por `src/arquivo.lua:linha` nos erros.

Se o `main.lua` for editado à mão, o build se recusa a sobrescrever (para não
apagar sua mudança). Leve a mudança para `src/` ou use `node build.js --force`.

## Testes

```
npm test
```

Roda `tests/*.test.js` com o test runner do Node (sem dependência extra além do
`fengari`, uma VM Lua em JS que executa o código Lua de verdade):

| Arquivo | O que garante |
|---|---|
| `build.test.js` | o projeto real compila; o `main.lua` e o `manifest.json` do repositório estão atualizados com o `src/`; `main.lua` editado à mão não é sobrescrito |
| `modules.test.js` | todos os `.lua` são achados, a ordem é a do caminho (byte a byte), quem é/não é isolado e as linhas do `main.lua` batem com o `src/` |
| `syntax.test.js` | erro de sintaxe ou global desconhecida numa **cópia** do projeto cancela o build sem tocar no `main.lua` |
| `limits.test.js` | 200 locais / 200 upvalues por função (chunk principal e módulos isolados) |
| `disk.test.js` | gravação segura: queda simulada em **cada** gravação nunca perde a config anterior |
| `integrity.test.js` | SHA-256 em Lua = SHA-256 do Node; o loader recusa download cortado/adulterado/que não compila e abre a versão anterior |
| `profiles.test.js` | perfil inválido não muda nada; erro no meio volta ao estado anterior; Freecam/Drone nunca ligam |
| `server.test.js` | servidor com o Roblox imitado: cargos e permissão por ação (moderador / admin / dono, proteção de cargo), `HYGE_Status`, alvo inexistente / que saiu / sem personagem / você mesmo, argumento inválido ou a mais, limite por ação e geral, registro (sem inundação, sem dados desnecessários), erro interno que não vaza, filtro, entrega do painel |
| `bridge.test.js` | o cliente (v9.2): sem servidor / sem cargo / sem permissão nada é enviado nem simulado e o motivo aparece; os pedidos saem no formato que o servidor aceita; liga/desliga só com a confirmação; servidor v9.1; `HYGE_Status` estranho ou que trava |
| `diag.test.js` | contabilidade de conexões e tarefas; nenhuma conexão persistente fora do `Conn` (`tools/leaks.js`) |

O que só dá para conferir dentro do Roblox está em [`docs/TESTES.md`](docs/TESTES.md).

## Servidor (no seu jogo)

O painel é a interface; quem decide o que vale para os outros jogadores é o
script de servidor. **Passo a passo completo: [`docs/SERVIDOR.md`](docs/SERVIDOR.md).**
Em resumo, no Roblox Studio:

1. **ServerScriptService** › Script: cole `server/HYGE_AdminServer.server.lua`.
2. **StarterPlayer › StarterPlayerScripts** › LocalScript: cole
   `server/HYGE_AdminClient.client.lua` (mostra anúncios e mensagens privadas
   no chat de todos — não dá poder a ninguém).
3. No topo do script de servidor: `CONFIG.AdminIds` (admins), `CONFIG.ModIds`
   (moderadores) e, se quiser, `CONFIG.Permissions` (cargo mínimo de cada
   ação). O dono do jogo já é cargo "dono"; dá para usar ranks de grupo.
4. Opcional: o painel dentro do jogo — LocalScript `HYGE_Panel` em
   **ServerStorage** com o `main.lua`; o servidor entrega só para quem tem
   cargo. **Nunca** ponha o `main.lua` em StarterPlayerScripts (todo jogador
   receberia o painel).

| Roda onde | Funções |
|---|---|
| **LOCAL** (qualquer jogo, sem instalar nada) | Fly, Noclip, God, Invisível, velocidades, Anti-Fall, Anti-Gravidade, Walk on Walls, Ctrl+clique TP, waypoints, ESP, Freecam, Drone, Spectate, Fullbright, Chat Spy, emotes, pacotes de animação, falar no chat, Teleportar até (sem o servidor), Fake Kick/Ban (só na sua tela), Configurações |
| **SERVIDOR** (exige os scripts acima) | Kick, Bring, Freeze/Unfreeze, Ir até (pelo servidor), Anúncio, Mensagem privada, Fling, Spin, Trip, Launch, Force Sit, Scale, Balloon |

Cada pedido é conferido no servidor, do zero: limite geral por jogador →
tem cargo → o cargo permite a ação → limite da ação → formato (argumento a
mais é recusado) → alvo (inteiro, no servidor, não você mesmo, cargo menor
que o seu) → argumentos → ação (texto pelo filtro do Roblox). A resposta
volta só para quem pediu (`HYGE_Result`) e o console do painel mostra o
resultado real (`[SERVIDOR] ✓ Kick: Fulano` ou o motivo da recusa). Tudo vai
para o registro (`shared.HYGE_AUDIT` + Output do servidor), sem o texto de
mensagens privadas, sem o motivo do kick e sem os argumentos recusados.

No painel, cada cartão diz se é **LOCAL** ou **SERVIDOR**, e os botões que
não podem ir dizem o porquê: **(sem servidor)**, **(não é admin)** ou **(sem
permissão)** — nada é simulado. **Início › Servidor** mostra o estado, o seu
cargo e o que está liberado (comando `server`; `server check` reconfere).

> A lógica do servidor e da ponte do cliente tem testes automáticos
> (`tests/server.test.js` e `tests/bridge.test.js`, com o Roblox imitado), mas
> **ainda não foi testada dentro de um jogo**. Antes de publicar, siga o
> roteiro de [`docs/TESTES.md`](docs/TESTES.md) no Studio (*Test › Clients and
> Servers*, 2+ jogadores).

## Navegação (dock)

O dock fica solto no rodapé da tela, sempre visível — é ele que abre o painel.
O ícone ativo mostra o nome ao lado; clicar nele de novo fecha o painel. A
janela (em pé, 460×520) nasce logo acima dele, com o título da seção e o selo
HYGE no topo.

| Ícone | Seção | Dentro da seção |
|---|---|---|
| casinha | Início | Painel (mapa atual, perfil com tempo de jogo, Rejoin / Trocar servidor / Discord) · Servidor |
| pessoa | Personagem | Movimento (Fly, Noclip, Anti-Fall, Anti-Gravidade, WalkSpeed, JumpPower...) · Visual |
| sacola | Playtime Shop | loja paga com tempo de jogo: All, Ranks, Icons, Titles, Effects, Nametags, Bundles |
| máscara | Troll | Walk on Walls + ações no alvo (Fling, Spin... — precisam do servidor) |
| carinha | Emotes | catálogo pesquisável, Playback Speed, andar com o emote, por ID, favoritos |
| pessoas | Jogadores | Lista (busca + ALVO / ESP / TP / SPEC por jogador) · Moderação |
| engrenagem | Configurações | Ajustes (tamanho da GUI, automático, keybinds, temas...) · Console |
| balão | Chat | HYGE (entre usuários do painel, via relay) · Jogo (chat do servidor) |

No alto da tela fica a **ilha** (hora, FPS e ping; clique abre/fecha o painel)
— desliga em Configurações › Ilha no topo.

Prefere a navegação antiga? **Configurações › Navegação › Usar dock de ícones**
desligado volta para a janela larga com sidebar (e a bolinha H para abrir).

### O que a v9.2 trouxe (integração com o servidor do seu jogo)

- **O servidor decide**: as 13 ações em outros jogadores são pedidas por
  RemoteEvent e executadas só depois da validação; a resposta real volta pelo
  `HYGE_Result`.
- **Cargos e permissões**: moderador, admin e dono, com o cargo mínimo de cada
  ação em `CONFIG.Permissions`; ninguém age sobre cargo igual ou maior. O
  painel pergunta o seu cargo (`HYGE_Status`) só para mostrar — cada pedido
  é conferido de novo.
- **Limite geral** por jogador (além do limite por ação), **argumento a mais
  recusado**, alvo que saiu / sem personagem / você mesmo recusado com o
  motivo.
- **Registro** sem inundação (recusa repetida vira uma entrada com contador)
  e sem dados desnecessários; erro inesperado não vaza para o cliente.
- **LOCAL ou SERVIDOR** em cada cartão; botões dizem por que não podem ir.
- **Fim das simulações**: sem servidor, Bring não move mais o alvo só na sua
  tela, Freeze não mexe mais no personagem dele no seu cliente e o anúncio
  não aparece mais "só no seu chat". Spin/Balloon só mostram ON confirmados.
- Mensagem privada num lugar só (Moderação, Chat e HUD do Spectate);
  "Teleportar até" passa pelo servidor quando ele está instalado.
- Opcional: o servidor entrega o painel (ServerStorage) só para quem tem cargo.
- Guia de instalação: [`docs/SERVIDOR.md`](docs/SERVIDOR.md).

### O que a v9.1 trouxe (estabilidade)

- **Config sem perda**: gravação com temporário + backup; arquivo estragado é
  detectado ao abrir e dá para recuperar (veja *Config em disco*).
- **Atualização conferida**: `manifest.json` com SHA-256; o loader e o
  ATUALIZAR AGORA recusam download cortado/adulterado/que não compila e abrem
  a última versão que funcionava.
- **Troca de perfil segura**: o perfil é validado antes; se algo falhar no
  meio, o painel volta ao que estava. As preferências são aplicadas antes e
  separadas das funções; Freecam e Drone nunca ligam pelo perfil.
- **Servidor auditado**: argumentos validados por ação, limite por ação,
  registro de ações e recusas, filtro obrigatório.
- **Diagnóstico de memória e conexões**: conexões criadas/encerradas/ativas por
  módulo, tarefas pendentes, monitor de respawn e conferência do Unload
  (`CLEAN` ou o que sobrou). Rodar o script de novo agora descarrega o painel
  anterior de verdade (antes ele ficava rodando junto).
- **Shift Lock do Roblox bloqueado** (opção em Comportamento): o Shift não
  prende mais o mouse no centro.
- **Testes automáticos** (`npm test`).

### O que a v9.0 trouxe

- **Configurações organizadas**: categorias no topo (Tudo · Geral · Teclas ·
  Visual · Dados · Sistema) e busca dentro dos ajustes, sem acento. A busca
  global (Ctrl+K) também acha os ajustes e os perfis.
- **Favoritos**: estrela em toda linha de função; as marcadas são as Ações
  rápidas da Home (até 12). Comando `fav [função]`.
- **Perfis** (Configurações › Dados): o painel inteiro salvo com um nome —
  tema, teclas, macros, velocidades, ESP, favoritos, ajustes e funções ligadas.
  **JOGO** faz o perfil abrir sozinho neste jogo. Em `HYGE/profiles.json`.
  Comando `perfil list | save | use | del | jogo`.
- **Notificações**: sino na ilha do topo com os últimos 60 avisos; o número
  conta só o que pede atenção. **Não perturbe** e tempo dos avisos (50–200%).
  Comando `notif [limpar|dnd]`.
- **Macros de teclado** (Configurações › Teclas): tecla → qualquer comando da
  barra, vários com `&&` (`fly on && flyspeed 150`).
- **Temas** Rosa, Laranja, Meia-noite e **cor personalizada** (matiz +
  intensidade, com prévia).
- **Diagnóstico** (Configurações › Sistema): recursos do executor, boot,
  módulos mais lentos, memória, últimos erros e COPIAR RELATÓRIO. Comando `diag`.
- **Salva sozinho**: a config vai para o disco a cada 30 s quando algo muda
  (antes, só ao descarregar o painel).
- **Mais estável**: módulos isolados (veja "Gerar o main.lua"); a lista de
  amigos não segura mais a abertura do painel.
- Cartão de **novidades** na primeira abertura de cada versão (comando
  `novidades` ou Configurações › Sobre).

### O que a v8.2 trouxe

- **Personagem › Pacote de animação**: cole o ID ou o link de um pacote do
  catálogo (`roblox.com/bundles/<ID>/...`). O painel lê as animações dele
  (lista de itens pelo `AssetService` do Roblox ou pelo catálogo público via
  HTTP; cada item aberto pelo `game:GetObjects`) e guarda na config. **USAR**
  troca as animações do seu personagem (andar, correr, pular, parado, cair,
  escalar, nadar) mexendo no script `Animate` — os outros jogadores veem.
  **VOO** põe o pacote no Fly. **VOLTAR AO NORMAL** devolve as animações do
  jogo. Já vêm na lista: Super Gogeta DBZ e Endless Aura. Só R15, só em jogo
  com o `Animate` padrão; o pacote no personagem volta sozinho no respawn.
  Comando: `pack list | add <id> | use <nome> | fly <nome> | off`.
- **Fly por ID de pacote**: `CONFIG.FlyPackBundle` (padrão: Super Gogeta DBZ).
  `FlyPackMoveSlot`/`FlyPackIdleSlot` escolhem qual animação do pacote toca
  voando e parado (padrão: fall e idle).
- **Celular**: em **Configurações › Celular e toque**, botões na tela — FLY
  liga/desliga; com o voo ligado aparecem SUBIR, DESCER e 2x. O analógico
  dirige o voo seguindo a câmera (controle no PC também). Em tela baixa a
  janela fica mais curta para caber acima do dock, e o dock encolhe se não
  couber na largura.
- **Playtime Shop › Missões de hoje**: 5 missões que zeram à meia-noite (30 min
  com o painel aberto, voar 10 min, 5 emotes, salvar 1 waypoint, usar um pacote
  de animação) e **bônus diário** que cresce com dias seguidos (10 → 40 no 7º
  dia). Completa, aparece RESGATAR. Comando: `missoes [resgatar]`.
- **Ctrl + clique TP** (Personagem › Teleporte): leva até o ponto embaixo do
  mouse. Pode ligar sozinho em Configurações › Automático.
- **Waypoints por jogo**: cada jogo (PlaceId) tem a sua lista. A config antiga
  (lista única) fica com o primeiro jogo em que a v8.2 for aberta.
- **Atualização**: veja "Rodar sempre a versão mais nova" no topo. Comando:
  `update` (confere) e `update now` (instala).

### O que cada seção nova faz (v8.1)

- **Início › Trocar servidor** lê a lista pública de servidores do jogo
  (`games.roblox.com`, pelo HTTP do executor) e entra num com vaga. Sem HTTP,
  faz um Teleport comum — o Roblox escolhe e pode cair no mesmo. **Discord**
  copia `CONFIG.Discord` (no topo do script); vazio, ele avisa em vez de copiar.
- **Playtime Shop**: 1 ponto por minuto com o HYGE aberto, salvo em
  `HYGE/playtime.json` a cada minuto (e no unload). Tudo é visual: rank, ícone
  e título aparecem no perfil da Home e no Chat HYGE; **Effects e Nametags são
  criados pelo seu cliente no seu personagem — só você vê**. Sem `writefile`, o
  tempo vale só para a sessão.
- **Personagem**: Anti-Fall desliga tombo/ragdoll, corta a velocidade de queda
  antes do impacto e devolve você ao último chão se cair no void. Anti-Gravidade
  baixa `workspace.Gravity` no seu cliente (só a sua física muda).
- **Fly (v8.1.2)**: voa com um pacote do catálogo (v8.2: o marcado como VOO;
  padrão Super Gogeta DBZ — Fall voando, Idle parado),
  lido do catálogo pelo `game:GetObjects` do executor. Se não der (executor sem
  essa função, Roblox recusando o pacote no jogo, personagem R6), usa o nadar do
  próprio personagem; em R6, a pose do painel (só você vê). Troca em Personagem ›
  Velocidades › Animação do voo. Animação sua (só em jogo seu):
  `CONFIG.FlyAnimR15`.
- **Troll › Walk on Walls**: anda em paredes e tetos (WASD segue a câmera, Space
  pula). Os outros veem você na parede. As ações no alvo continuam dependendo
  dos Remotes de `server/`.
- **Emotes**: os "Padrão" vêm do script Animate do seu personagem e sempre
  tocam. O resto do catálogo são emotes publicados pela Roblox (R15): os IDs
  não foram conferidos um a um em jogo — o que não carregar é avisado no console
  e marcado na lista.
- **Jogadores › ESP** numa linha mostra o ESP só dos marcados (liga o ESP se
  estiver desligado; desmarcar o último devolve como estava).
- **Configurações**: a tecla do painel agora é remapeável; **Automático** liga
  funções sozinho ao carregar; **Reconectar se cair** tenta entrar de novo
  quando aparece a tela de erro.

## Chat HYGE (relay)

Clientes do Roblox não conversam direto entre si, então o Chat HYGE passa por
um servidor pequeno seu: `server/chat-relay/server.js` (Node 18+, sem
dependências).

```
npm run chat                      # porta 8787
PORT=8080 HYGE_CHAT_KEY=senha npm run chat
```

Hospede onde quiser (VPS, Render, Railway, Fly.io — atrás de proxy use
`TRUST_PROXY=1`) e cole a URL em **Chat › HYGE › Conexão** ou em
`CONFIG.ChatRelay`. Com senha, coloque a mesma em `CONFIG.ChatKey`.

- Salas: **Este servidor** (mesmo JobId) e **Global**. Guarda as últimas 100
  mensagens por sala, só na memória; reiniciou, o histórico some.
- Limites: 200 caracteres, 1 mensagem por segundo (por UserId e por IP).
- **O relay não verifica identidade**: nome e UserId vêm do cliente. Use um
  relay seu e, se for público, com senha.
- O painel precisa de `request()` do executor para enviar; só com
  `game:HttpGet` ele lê mas não envia (e avisa).

## Teclas padrão

| Tecla | Ação |
|---|---|
| `B` | abre/fecha o painel (remapeável em Configurações › Keybinds) |
| `;` | barra de comandos (`help` lista tudo) |
| `Ctrl+K` | busca global |
| `Keypad 1–6` | situações (Moderação, Caça, Observação, Movimento, Stealth, Limpeza) |
| `F` `N` `E` `C` `G` | fly, noclip, ESP, freecam, drone |

Tudo remapeável em **Ajustes**. Com freecam/drone/fly ligados, as teclas que
eles usam para se mover (WASD, E/Q, Space, Ctrl, Shift) não disparam atalhos.
v9.0.1: o **Shift Lock do Roblox** fica bloqueado (o Shift não prende mais o
mouse no centro) — dá para religar em Configurações › Comportamento.
v9.0: **Macros** (Configurações › Teclas) ligam qualquer tecla livre a um
comando da barra.

Janela perdida fora da tela: comando `center` ou **Ajustes › Sistema ›
Centralizar janela**.

## Config em disco

`HYGE/config.json` (pasta do executor) guarda keybinds (inclusive a tecla do
painel), tema, escala, velocidades e gravidade, opções de ESP, waypoints (v8.2:
por jogo, em `wpplaces`), emotes favoritos, funções automáticas, endereço do
Chat HYGE, a última situação, a posição da janela, (v8.2) os pacotes de
animação já lidos e (v9.0) favoritos, macros, cor personalizada, Não perturbe
e a última versão vista. **v9.0: salva sozinho a cada 30 s quando algo muda**
(com "Salvar automaticamente" ligado); se o arquivo existir mas estiver
ilegível, o automático espera você salvar na mão. Os perfis ficam em
`HYGE/profiles.json`. O tempo de jogo, os itens da Playtime Shop e o progresso das
missões ficam à parte, em `HYGE/playtime.json`. Executor sem `writefile`/`readfile`: use
**Exportar/Importar** pelo clipboard em Ajustes.

**v9.1 — backup e recuperação.** Executor não tem "renomear", então não dá
para trocar o arquivo de forma atômica; a estratégia é nunca ficar sem uma
cópia boa. Cada gravação (config, perfis e tempo de jogo):

1. grava a versão nova inteira em `<nome>.tmp` e relê para conferir;
2. se a versão atual for válida, ela vira `<nome>.backup.json` (conferida) — um
   arquivo estragado nunca apaga um backup bom;
3. grava o principal e confere;
4. apaga o `.tmp`.

Caiu no meio de qualquer passo? Sempre sobra o principal válido, ou o `.tmp`
(a versão nova completa), ou o backup (a anterior). Ao abrir, a config
estragada é detectada: o painel **pergunta se quer recuperar** (e o salvamento
automático fica parado até lá, para não gravar por cima). Também dá para
voltar ao backup quando quiser — desfaz o último salvamento ou um RESETAR —
em **Configuração em disco › RECUPERAR BACKUP** ou com o comando `recover`
(`recover perfis` para os perfis). Perfis e tempo de jogo estragados voltam
sozinhos do backup. O arquivo estragado fica em `<nome>.corrupt.json`.

## Versão anterior

A v7.0 era um `main.lua` único. Para recuperar aquele arquivo, use o
histórico de versões do OneDrive (botão direito no `main.lua` › *Histórico de
versões*).
