# Changelog

## v8.0

### Estrutura
- O `main.lua` de ~9.000 linhas virou 47 módulos em `src/`, agrupados por
  assunto. O `main.lua` continua existindo como arquivo único (gerado pelo
  `build.js`), então o jeito de rodar no executor não muda.
- `build.js` + `tools/check.js`: cada build valida sintaxe, o limite de 200
  locais do Luau, o limite de upvalues e globais desconhecidas, e aponta o
  erro como `src/arquivo.lua:linha`. Build com erro não grava nada.
- O build se recusa a sobrescrever um `main.lua` editado à mão.

### Novidades
- **Script de servidor** (`server/`): cria e valida os 13 RemoteEvents
  (kick, bring, freeze, goto, anúncio, mensagem privada, fling, spin, trip,
  launch, sit, scale, balloon). Admin checado no servidor, cooldown, proteção
  entre admins, texto filtrado pelo Roblox, confirmação real no console do
  painel. Script cliente para todos verem anúncios e mensagens privadas.
- **Catálogo único de Remotes** (`V8.RemoteInfo`): aba Server lista os 13
  agrupados (antes 6), e o tile da Home, o comando `server` e Ajustes › Sobre
  leem da mesma lista.
- **Lista de jogadores e ESP em tempo real**: quem entra aparece na aba
  Players na hora; quem sai some da lista, do ESP (inclusive o tracer), da
  seleção e do spectate. Tempo no servidor preenchido para quem entra depois
  do painel abrir.
- **Freecam refeito**: sem a câmera "rolar" de lado, o personagem não anda
  junto, mouse livre com o painel aberto, scroll muda a velocidade.
- **Janela sempre alcançável**: arrastar fica preso dentro da tela, a posição
  é salva na config, e há `center` / Ajustes › Sistema › Centralizar janela.
  Reencaixa sozinha se a resolução mudar.
- **Chat Spy** funciona em jogos com TextChatService (o chat atual do Roblox;
  antes ficava mudo nesses jogos).
- Rodapé de atalhos da Home mostra as teclas reais (antes era texto fixo).
- O painel registra no console os anúncios que voltam do servidor.

### Correções
- Subir com `E` no freecam/drone ligava/desligava o ESP: teclas de movimento
  agora são ignoradas pelos atalhos enquanto o modo que as usa está ligado.
- Fly, freecam e drone se mexiam com as letras digitadas no chat/console.
- "Registrar no console" (Ajustes) não fazia nada; agora, desligado, só erros
  aparecem.
- Cada linha de log criava uma entrada permanente no registry de tema
  (vazamento com Chat Spy ligado). Também há faxina periódica das entradas de
  listas que se redesenham.
- Keybind podia ser colocado na tecla do console, da busca ou de uma situação
  e nunca disparar; agora o painel recusa ou avisa quem perdeu a tecla.
- Restaurar padrões voltava para o tema Roxo; agora volta para o padrão da v8
  (`CONFIG.DefaultTheme = "Azul"`). A lógica de restaurar existia duplicada.
- Comandos `sit`/`search`/`save`/`loadcfg` registravam erros como INFO.
- Comando `theme` não listava o tema Azul.
- Texto dos waypoints dizia que não eram salvos (são, desde a fase 1 da v8).
- Captura de keybind em andamento não era encerrada no Unload.
