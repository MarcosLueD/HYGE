# HYGE v9.2 — integração com o servidor do seu jogo

O painel roda no cliente. Tudo o que ele faz **no seu personagem, na sua
câmera ou na sua tela** funciona em qualquer jogo, sem instalar nada. Tudo o
que **mexe em outro jogador** (kick, bring, freeze, anúncio, mensagem privada,
troll) o cliente não pode fazer sozinho: o painel **pede** ao script de
servidor por RemoteEvents, e o servidor confere e decide.

Este guia é para quem é dono do jogo (ou do grupo) e vai instalar os scripts
no Roblox Studio.

## As peças

| Arquivo | Onde vai no Studio | Para quem | O que faz |
|---|---|---|---|
| `server/HYGE_AdminServer.server.lua` | **ServerScriptService** › Script | o servidor | cria os Remotes, valida cada pedido, executa, responde e registra |
| `server/HYGE_AdminClient.client.lua` | **StarterPlayer › StarterPlayerScripts** › LocalScript | todos os jogadores | mostra no chat os anúncios e as mensagens privadas que o servidor manda. Não dá poder nenhum |
| `main.lua` (o painel) | executor **ou** ServerStorage › LocalScript `HYGE_Panel` (opcional) | só staff | a interface. Em ServerStorage, o servidor entrega só para quem tem cargo |

> **Nunca ponha o `main.lua` em StarterPlayerScripts nem em StarterGui.** Tudo
> que está lá é copiado para **todos** os jogadores: todo mundo receberia o
> painel com Fly, Noclip, ESP etc. As ações em outros jogadores continuariam
> bloqueadas pelo servidor, mas as funções locais ficariam liberadas para
> qualquer um.

## Instalação

### 1. ServerScriptService (obrigatório)

1. No Explorer do Studio, botão direito em **ServerScriptService** › *Insert
   Object* › **Script** (o comum — **não** LocalScript nem ModuleScript).
2. Renomeie para `HYGE_AdminServer`.
3. Apague o conteúdo e cole o arquivo `server/HYGE_AdminServer.server.lua`
   inteiro.
4. Confira que o script está **habilitado** (`Enabled` marcado).

Ao rodar, o Output do servidor mostra:

```
[HYGE] servidor 9.2 pronto — 13 Remotes de ação, 1 admin(s) e 0 moderador(es) por UserId
```

Ele cria sozinho, em **ReplicatedStorage**, os 13 RemoteEvents de ação
(`AdminKick`, `AdminPull`, `AdminFreeze`, `AdminTeleport`, `AdminAnnounce`,
`AdminWhisper`, `AdminFling`, `AdminSpin`, `AdminTrip`, `AdminLaunch`,
`AdminSit`, `AdminScale`, `AdminBalloon`), o RemoteEvent `HYGE_Result`
(respostas) e a RemoteFunction `HYGE_Status` (o painel pergunta o seu cargo).
Não crie nada disso à mão.

### 2. StarterPlayerScripts (recomendado)

1. **StarterPlayer › StarterPlayerScripts** › *Insert Object* › **LocalScript**.
2. Renomeie para `HYGE_AdminClient` e cole `server/HYGE_AdminClient.client.lua`.

Sem ele, os anúncios e as mensagens privadas só aparecem para quem tem o
painel aberto. Com ele, aparecem no chat de todos (já filtrados pelo servidor).

### 3. Quem tem cargo (obrigatório)

No topo do script de servidor, em `CONFIG`:

```lua
AdminIds = {        -- cargo 2 (admin)
    123456789,      -- o seu UserId
},
ModIds = {          -- cargo 1 (moderador)
    987654321,
},
```

- O seu UserId aparece no painel em **Início › Servidor › COPIAR MEU USERID**
  (ou no seu perfil do Roblox: o número do link `roblox.com/users/<ID>/profile`).
- O **dono do jogo** (conta pessoal) já é cargo 3 (dono) com `OwnerIsAdmin = true`.
- Jogo de **grupo**: `GroupId = <id do grupo>`; `GroupMinRank` é o rank mínimo
  para admin (255 = dono do grupo) e `GroupModRank` o rank mínimo para
  moderador (0 = desligado). Se a consulta ao grupo falhar (Roblox fora do
  ar), a pessoa fica **sem** cargo pelo grupo — nunca com.

O `CONFIG.AdminIds` **do painel** (`src/00_core/01_config.lua`) só decide quem
consegue **abrir** o painel naquele cliente. Quem pode agir nos outros é
decidido **só** pelo `CONFIG` do servidor.

### 4. O painel dentro do jogo (opcional)

Se você não usa executor e quer o painel no próprio jogo:

1. **ServerStorage** › *Insert Object* › **LocalScript**, com o nome
   `HYGE_Panel` (o mesmo de `CONFIG.PanelScript`).
2. Cole o `main.lua` inteiro dentro dele.

Quando alguém com cargo ≥ `CONFIG.PanelMinLevel` (padrão: 1, moderador) entra,
o servidor copia esse LocalScript para o `PlayerGui` dele, dentro de uma
ScreenGui `HYGE_PanelHost` com `ResetOnSpawn = false`. O ServerStorage não é
enviado para os clientes: quem não tem cargo nunca recebe o código do painel.
A entrega vai para o registro (`panel`).

Num LocalScript comum não existem as funções de executor: sem `writefile` a
config vale só para a sessão (use Exportar/Importar), e o ATUALIZAR AGORA não
funciona — atualize colando o `main.lua` novo no `HYGE_Panel`.

### 5. Publicar

*File › Publish to Roblox*. Não precisa ligar nada em *Game Settings ›
Security*: RemoteEvents não usam HTTP nem API Services.

## Configuração

Tudo no `CONFIG` do topo de `HYGE_AdminServer`.

### Cargos e permissões

| Cargo | Nível | Quem |
|---|---|---|
| jogador | 0 | todo mundo. Pedido recusado e **sem resposta** |
| moderador | 1 | `ModIds`, ou rank ≥ `GroupModRank` |
| admin | 2 | `AdminIds`, ou rank ≥ `GroupMinRank` |
| dono | 3 | o dono do jogo (`OwnerIsAdmin`) |

`CONFIG.Permissions` diz o cargo mínimo de cada ação. O padrão:

| Ação | Remote | Cargo mínimo |
|---|---|---|
| Kick, Freeze/Unfreeze, Bring, Ir até, Mensagem privada | `AdminKick`, `AdminFreeze`, `AdminPull`, `AdminTeleport`, `AdminWhisper` | 1 (moderador) |
| Anúncio para todos | `AdminAnnounce` | 2 (admin) |
| Fling, Spin, Trip, Launch, Force Sit, Scale, Balloon | `AdminFling` … `AdminBalloon` | 2 (admin) |

Use `3` para deixar uma ação só para o dono. Uma ação que não estiver na lista
pede cargo 2; um valor inválido (ex.: `7`) fica só para o dono e o Output avisa.

`ProtectAdmins = true`: ninguém age sobre alguém do **mesmo cargo ou acima**
nas ações de kick, freeze e troll. O dono age sobre admins; admin não age
sobre outro admin; moderador não age sobre admin.

### Limites de uso

| Chave | Padrão | O que é |
|---|---|---|
| `Cooldown` | 0.25 s | intervalo mínimo entre duas vezes a **mesma** ação do mesmo jogador |
| `Cooldowns` | kick 1 s, anúncio 5 s, privado 1 s, scale/fling/launch 1 s | o mesmo, por ação |
| `RateLimit` | 30 pedidos em 10 s | limite **geral** por jogador, somando todos os Remotes do HYGE (inclusive `HYGE_Status`). Estourou: tudo é recusado até passar 10 s **sem** pedidos; staff recebe um aviso (uma vez) |
| `MaxText` | 200 | caracteres de anúncio, mensagem e motivo (corta sem partir acento) |
| `AuditSize` | 200 | entradas guardadas no registro |

### Outras

`PanelScript` / `PanelMinLevel` (entrega do painel, acima) e os números do
troll (`FlingPower`, `LaunchPower`, `SpinSpeed`, `BalloonSpeed`, `BalloonMax`,
`TripTime`, `Scale`).

## Como cada pedido é conferido

O painel manda só o mínimo (o UserId do alvo e, quando a ação tem, um
argumento). **Quem pediu** é o jogador que o Roblox entrega ao servidor no
`OnServerEvent` — nada que o cliente mande sobre si mesmo é lido. Para cada
pedido, nesta ordem:

1. **limite geral** (`RateLimit`) — passou, recusa sem resposta;
2. **tem cargo?** — jogador comum: recusa **sem resposta**;
3. **o cargo permite a ação?** (`Permissions`);
4. **limite da ação** (`Cooldown`/`Cooldowns`) — a tentativa conta mesmo se
   o resto for inválido;
5. **formato** — argumento a mais é recusado (`nil` no fim não conta);
6. **alvo** — UserId inteiro de alguém **neste** servidor; não pode ser você
   mesmo em kick, bring e ir até; cargo igual ou maior é protegido;
7. **argumentos** — tipo e valores aceitos (booleano, um dos modos do
   `Scale`, texto UTF-8 válido até `MaxText`);
8. **a ação** — texto passa pelo filtro do Roblox; se o filtro falhar ou
   censurar tudo, nada é enviado. Alvo sem personagem: recusado com o motivo.

O `HYGE_Status` só **informa** o painel (para ele mostrar o que está
liberado). Ele não autoriza nada: o pedido de ação passa por essa lista do
zero.

Toda resposta vai pelo `HYGE_Result`, só para quem pediu:
`{ action, ok, message, code, target, state }`, com `code` = `ok`, `perm`,
`cooldown`, `args`, `target`, `protected`, `failed`, `rate` ou `internal`.
Erro inesperado no servidor chega ao painel só como "erro interno"; o detalhe
(linha, nome de objeto) fica no Output do servidor.

## O que aparece no painel

- Cada cartão diz onde aquilo roda: **LOCAL** (seu cliente, qualquer jogo) ou
  **SERVIDOR** (exige os scripts deste guia), com o estado atual.
- Botões que exigem o servidor mostram o motivo quando não podem ir:
  **(sem servidor)** — os Remotes não existem neste jogo; **(não é admin)** —
  o servidor respondeu que você não tem cargo; **(sem permissão)** — o seu
  cargo não pode aquela ação. Clicar explica no console o que fazer. Nada é
  simulado na sua tela.
- Depois de pedir, o console mostra `pedido enviado; aguardando o servidor` e,
  em seguida, a resposta real: `[SERVIDOR] ✓ Kick: Fulano` ou
  `[SERVIDOR] ✗ Kick: espere 0.6s`. Sem resposta em 6 s, o painel avisa.
- SPIN e BALLOON só mostram ON depois que o servidor confirma.
- **Teleportar até** é a exceção: sem servidor ele move só o seu personagem
  (funciona em qualquer jogo); com o servidor e permissão, o servidor move
  (fica no registro).
- **Início › Servidor**: estado da integração, o seu cargo, cada ação com
  `[LIBERADA]`, `[SEM PERMISSÃO]`, `[NÃO É ADMIN]`, `[AUSENTE]` ou
  `[ENCONTRADO]` (existe, mas o servidor não confirmou), o botão
  **RECONFERIR SERVIDOR**, o seu UserId e o resumo desta instalação. O mesmo na
  barra de comandos: `server` (e `server check` para reconferir).

| Estado no painel | O que quer dizer |
|---|---|
| não instalado neste jogo | nenhum dos Remotes existe |
| instalado · seu cargo: … | o servidor v9.2 respondeu |
| instalado, mas NÃO reconhece você como admin | seu UserId não está em `AdminIds`/`ModIds` |
| sem o HYGE_Status | servidor v9.1 (ou Remotes de outro sistema com os mesmos nomes): os pedidos vão e o servidor valida, mas o painel não sabe o seu cargo e não recebe resposta estruturada |
| HYGE_Status sem resposta | o script de servidor está parado, com erro ou o limite geral foi atingido |

## Registro (auditoria)

Ações aceitas **e** recusadas vão para o Output do servidor e para
`shared.HYGE_AUDIT` (as últimas `AuditSize`). Para ver no Studio, na barra de
comandos do **servidor**:

```lua
for _, e in ipairs(shared.HYGE_AUDIT) do print(e.ok, e.name, e.action, e.target, e.reason, e.count) end
```

| Campo | Conteúdo |
|---|---|
| `ok` | `true` aceita, `false` recusada |
| `by`, `name` | UserId e nome de quem pediu |
| `action` | aceita: `kick`, `bring`, `freeze`, `spin on`, `panel`…; recusada: o nome do Remote |
| `target` | UserId do alvo (aceitas) |
| `reason` | motivo da recusa (`não é admin`, `sem permissão (cargo moderador)`, `limite da ação (1s)`, `argumentos demais`, `alvo protegido`, `falhou: alvo sem personagem`, `erro interno`, `excesso de pedidos`…) |
| `count`, `last` | a mesma recusa repetida com menos de 10 s de intervalo vira **uma** entrada com contador — quem martela um Remote não empurra o resto do registro para fora |
| `extra` | só o texto de anúncios (público, já filtrado) e o modo do Scale |
| `time` | `os.time()` |

O que **não** é guardado: o texto de mensagens privadas, o motivo do kick, os
argumentos que o cliente mandou (só "argumento 2 inválido") e detalhes de erro
interno (esses ficam só no Output). O registro fica na memória do servidor:
ele some quando o servidor fecha. Para guardar de vez, leia
`shared.HYGE_AUDIT` de outro script seu e grave onde quiser (DataStore, por
exemplo).

## Testar no Studio

No Studio, os jogadores de teste têm UserId **negativo** (Player1 = -1,
Player2 = -2...) e não são o dono do jogo. Para testar:

1. Em `AdminIds` do servidor, ponha `-1` (só para o teste — tire antes de
   publicar).
2. *Test › Clients and Servers*, com 2 ou 3 jogadores.
3. O painel no Player1: pelo `HYGE_Panel` em ServerStorage, ou colando o
   `main.lua` num LocalScript de teste.

O roteiro completo do que conferir está em [`TESTES.md`](TESTES.md), seção 1.
No Studio o filtro de texto não filtra (devolve o mesmo texto): o teste do
filtro só vale num servidor publicado.

## Atualizar da v9.1

1. Copie os seus `AdminIds` (e o resto do `CONFIG` que você mudou).
2. Substitua **o script inteiro** pelo da v9.2 e cole de volta o que copiou.
3. O `HYGE_AdminClient` não precisa mudar (pode atualizar só pelos comentários).

Os nomes dos 13 Remotes são os mesmos. O painel v9.2 funciona com o servidor
v9.1 (estado "sem o HYGE_Status"), e o painel v9.1 manda o Bring com um
argumento a mais que o servidor v9.2 recusa — atualize os dois.

## Problemas comuns

| Sintoma | Causa provável |
|---|---|
| Botões com **(sem servidor)** com o script instalado | script desabilitado, no lugar errado (tem de ser ServerScriptService, Script comum) ou com erro (veja o Output do servidor). Se o painel abriu antes de o servidor criar os Remotes: **RECONFERIR SERVIDOR** |
| **(não é admin)** | seu UserId não está em `AdminIds`/`ModIds`. No Studio, o UserId é negativo |
| **(sem permissão)** | o seu cargo é menor que o de `Permissions` para aquela ação |
| `alvo protegido` / `cargo igual ou maior` | `ProtectAdmins`: o alvo tem o seu cargo ou maior |
| `espere 0.6s` | limite da ação (`Cooldowns`) |
| `muitos pedidos seguidos` | limite geral (`RateLimit`): pare de pedir por 10 s |
| `o servidor não respondeu em 6 s` | script de servidor parado ou com erro, ou um servidor v9.1 |
| `erro interno no servidor` | erro inesperado: o detalhe está no Output do **servidor** |
| anúncio não aparece para os outros | falta o `HYGE_AdminClient` em StarterPlayerScripts |
| `o filtro do Roblox bloqueou a mensagem` | o filtro censurou o texto inteiro; nada foi enviado |
