# HYGE v9.2 — roteiro de testes antes do lançamento

O `npm test` cobre o que dá para conferir fora do Roblox (build, gravação
segura, loader, troca de perfil, lógica do servidor, ponte do cliente com o
servidor, contabilidade de conexões). Este roteiro é o resto: o que só dá para
ver **dentro do Roblox**. Instalação do servidor: [`SERVIDOR.md`](SERVIDOR.md).

Marque cada linha só depois de ver o resultado com os próprios olhos. Se algo
falhar, copie o relatório de **Configurações › Sistema › Diagnóstico ›
COPIAR RELATÓRIO** e anote junto.

Antes de começar:

- [ ] `npm test` passou (todas as linhas com ✔)
- [ ] `npm run build` rodou e o `main.lua` **e** o `manifest.json` foram para o GitHub no mesmo commit

---

## 1. Servidor — Roblox Studio, *Test › Clients and Servers*

**Preparação:** um lugar de teste seu, com `HYGE_AdminServer.server.lua` em
ServerScriptService e `HYGE_AdminClient.client.lua` em
StarterPlayerScripts. Em `CONFIG.AdminIds` do servidor, coloque **só** o
UserId que vai ser o Player1 (no Studio os jogadores de teste têm UserIds
negativos: rode uma vez, veja no Output, `print(game.Players.Player1.UserId)`
na barra de comandos do servidor, e coloque esse número). Inicie com
**3 jogadores**. O painel roda no Player1 (LocalScript `HYGE_Panel` em
ServerStorage — item 16 —, um LocalScript de teste com o `main.lua` ou o
executor do Studio).

Para ver o registro: na barra de comandos do **servidor**,
`for _, e in ipairs(shared.HYGE_AUDIT) do print(e.ok, e.name, e.action, e.reason, e.count) end`

| # | Situação | Como fazer | Resultado esperado | ✓ |
|---|---|---|---|---|
| 1 | Admin autorizado | Player1: kick no Player3 pela aba Moderação | Player3 sai com o motivo filtrado; console do painel: `pedido enviado` e depois `[SERVIDOR] ✓ Kick: Player3`; registro: `true Player1 kick` | [ ] |
| 2 | Jogador comum | Player2, barra de comandos do **cliente** dele: `game.ReplicatedStorage.AdminKick:FireServer(<UserId do Player1>, "x")` | Nada acontece; Output do servidor: `RECUSADO Player2 ... não é admin`; registro: `false Player2 AdminKick não é admin` | [ ] |
| 3 | Jogador comum em todos os remotes | Repita o 2 com `AdminAnnounce:FireServer("oi")`, `AdminFling`, `AdminScale:FireServer(id, "giant")` | Tudo recusado, ninguém é afetado, nenhum anúncio aparece | [ ] |
| 4 | Alvo inexistente | Player1 (cliente): `game.ReplicatedStorage.AdminSit:FireServer(123)` | Console do painel: `jogador não está no servidor`; registro: `alvo inválido` | [ ] |
| 5 | Argumento inválido | Player1: `AdminScale:FireServer(<id Player2>, "huge")`, `AdminFreeze:FireServer(<id Player2>, "sim")` e `AdminSit:FireServer(<id Player2>, "extra")` | Recusados (`argumento inválido` / `argumentos a mais`); Player2 não muda | [ ] |
| 6 | Muitas requisições | Player1: anúncio duas vezes seguidas (menos de 5 s) | Só o primeiro aparece; painel: `espere ...s`; registro: `limite da ação` | [ ] |
| 7 | Limite por ação | Logo depois do 6, Player1 faz Sit no Player2 | Funciona (o limite do anúncio não bloqueia outra ação) | [ ] |
| 8 | Texto recusado pelo filtro | Player1: anúncio com uma palavra que o filtro do Roblox bloqueia inteira | **No Studio o filtro não filtra** (devolve o texto igual). Este item só vale num servidor publicado: a mensagem toda censurada **não** é enviada e o painel mostra `o filtro do Roblox bloqueou a mensagem` | [ ] |
| 9 | Mensagem privada | Player1: mensagem para o Player2 | Só o Player2 vê `[PRIVADO de Player1]`; Player3 não vê nada | [ ] |
| 10 | Cargo protegido | Coloque o UserId do Player2 em `AdminIds` também, reinicie; Player1 tenta kick no Player2 | Recusado: `Player2 tem cargo igual ou maior` | [ ] |
| 11 | Troll | Player1: Spin ON/OFF, Balloon ON (espere 20 s), Fling, Launch, Trip no Player3 | Cada um funciona; SPIN/BALLOON só mostram ON depois da confirmação; o balão desliga sozinho em 20 s e o botão volta a OFF | [ ] |
| 12 | Moderador (v9.2) | Tire o Player2 de `AdminIds`, ponha em `ModIds`, reinicie; painel no Player2 | Início › Servidor: `seu cargo: moderador · 5/13`; Kick/Freeze/Bring/privado funcionam; Fling/Anúncio mostram **(sem permissão)** e, chamados pela barra do cliente, o servidor recusa (`sem permissão`) | [ ] |
| 13 | Estado no painel (v9.2) | Player1: Início › Servidor | `HYGE 9.2 instalado · seu cargo: admin`; as 13 ações `[LIBERADA]`; cartões com **SERVIDOR** e **LOCAL** | [ ] |
| 14 | Sem o servidor (v9.2) | Desabilite o `HYGE_AdminServer` e rode de novo | Botões de servidor mostram **(sem servidor)**; clicar explica onde instalar; Bring não move ninguém, Freeze não congela, Anúncio não aparece no seu chat; Teleportar até continua (local) | [ ] |
| 15 | Limite geral (v9.2) | Player1 (cliente): `for i = 1, 40 do game.ReplicatedStorage.AdminSit:FireServer(<id Player2>) task.wait(0.3) end` | Os primeiros ~30 passam; depois, um aviso `muitos pedidos seguidos` e o resto recusado; 10 s parado volta | [ ] |
| 16 | Painel entregue (v9.2) | LocalScript `HYGE_Panel` com o `main.lua` em ServerStorage; `AdminIds = { -1 }` | O Player1 recebe o painel (PlayerGui › HYGE_PanelHost); Player2 e Player3 **não** recebem; registro: `true Player1 panel` | [ ] |
| 17 | Você mesmo (v9.2) | Player1 (cliente): `game.ReplicatedStorage.AdminKick:FireServer(<UserId do Player1>)` | Recusado: `não vale em você mesmo` | [ ] |

---

## 2. Testes gerais (Etapa 7)

| # | Teste | Como fazer | O que verificar | ✓ |
|---|---|---|---|---|
| 1 | Primeira abertura | Apague a pasta `HYGE/` do executor e rode o `loader.lua` | Abre sem erro; cartão de boas-vindas; Diagnóstico: Modules todos OK, 0 erros | [ ] |
| 2 | Internet desligada | Rode o loader uma vez online; desligue a internet (ou bloqueie o GitHub) e rode de novo | Abre; console: `abrindo a cópia local — manifesto: ...` | [ ] |
| 3 | Executor limitado | Rode num executor sem `writefile` ou sem `request` | Diagnóstico › Executor mostra o que falta (`NÃO`); Configuração em disco avisa que não salva; nada finge que funcionou | [ ] |
| 4 | Configuração corrompida | Com o painel fechado, abra `HYGE/config.json` e apague metade do texto. Rode de novo | O painel pergunta se quer recuperar do backup; SIM volta a config anterior; o estragado fica em `config.corrupt.json` | [ ] |
| 5 | Configuração vazia | Igual ao 4, mas deixe `config.json` com 0 bytes | Mesmo comportamento do 4 | [ ] |
| 6 | Perfis corrompidos | Estrague `HYGE/profiles.json` | Os perfis voltam sozinhos do backup; log: `recuperados do backup` | [ ] |
| 7 | Troca de perfil | Salve 2 perfis bem diferentes (tema, teclas, funções). Alterne com USAR | Tudo troca de uma vez; Freecam/Drone nunca ligam sozinhos; Diagnóstico › Config: `Último perfil: ... aplicado` | [ ] |
| 8 | Perfil inválido | Em `profiles.json`, troque uma velocidade por `-5` (ou `"scale": 999`) e recarregue | USAR esse perfil: `Perfil inválido — nada mudou`; o painel fica exatamente como estava | [ ] |
| 9 | Respawn | Ligue Fly, Noclip, ESP; morra 3 vezes | As funções voltam; Diagnóstico › Connections › Respawn mostra números **estáveis** (sem `cresce a cada respawn`) | [ ] |
| 10 | Fechar painel | Abra e feche o painel 20 vezes; depois DESCARREGAR PAINEL | Console: `[HYGE] Unload: CLEAN — ... 0 ativas; tarefas: ... 0 rodando`; nenhum `tarefa rodou depois do unload` nos segundos seguintes | [ ] |
| 11 | Unload registrado | Rode o painel de novo depois do 10 | Diagnóstico › Unload: `Último (...): CLEAN` | [ ] |
| 12 | Rodar duas vezes | Com o painel aberto, rode o script de novo (sem descarregar) | Fica só **um** painel; apertar a tecla do painel abre/fecha uma vez só; Fly não acelera em dobro | [ ] |
| 13 | Atualização | Publique um build novo; no painel aberto, Ajustes › Atualização › VERIFICAR e ATUALIZAR AGORA | Avisa a versão nova; atualiza sem sair do jogo; a config continua | [ ] |
| 14 | Atualização inválida | Publique um `manifest.json` com o `sha256` errado (ou um `main.lua` cortado) e rode o loader | Console: `download recusado: SHA-256 não confere` (ou `incompleto`); abre a versão anterior; `HYGE/main.lua` não muda | [ ] |
| 15 | Tela pequena | Janela do Roblox bem pequena e no celular | Dá para abrir, rolar e usar todas as seções; a janela não fica presa fora da tela (`center` resolve) | [ ] |
| 16 | Múltiplos jogadores | Item 1 deste roteiro inteiro | Servidor valida permissões | [ ] |
| 17 | Shift Lock | Num jogo que libera Shift Lock: aperte Shift andando e voando | O mouse não prende no centro; desligando a opção em Comportamento, o Shift Lock volta | [ ] |

---

## Limites conhecidos

- O lint de vazamento (`tools/leaks.js`) olha conexões em serviços,
  `LocalPlayer`, `Camera`, `workspace` e no personagem por `Char()/Hum()/Root()`.
  Conexão num objeto do personagem guardado numa variável local não é
  detectada; ela morre com o personagem no respawn.
- "Tarefas pendentes" conta `task.delay`/`task.defer` agendados que ainda não
  rodaram (inclusive toasts e animações curtas). O que importa no Unload é
  `rodando` = 0 e nenhum aviso `tarefa rodou depois do unload`.
- No Studio o filtro de texto não filtra; o item 8 do servidor só vale num
  servidor publicado.
