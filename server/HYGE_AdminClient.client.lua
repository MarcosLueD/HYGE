--[[
================================================================================
    HYGE ADMIN — CLIENTE DE TODOS OS JOGADORES (v9.2)

    Onde colocar:  StarterPlayer > StarterPlayerScripts > LocalScript
    Par dele:      server/HYGE_AdminServer.server.lua (ServerScriptService)
    Passo a passo: docs/SERVIDOR.md

    Mostra no chat de QUALQUER jogador (não só de quem tem o painel):
      * anúncios do admin (AdminAnnounce)
      * mensagens privadas do admin (AdminWhisper)
    O texto já chega filtrado pelo servidor. Aqui ele só é escapado para o
    RichText do chat (ninguém injeta cor/tamanho com "<font ...>").

    Este script NÃO é o painel e não dá poder nenhum: só escuta o que o
    servidor manda. Ele pode ficar em StarterPlayerScripts para todo mundo.
    O painel (main.lua) NUNCA vai em StarterPlayerScripts — todo jogador o
    receberia. Para ter o painel dentro do jogo, use o LocalScript HYGE_Panel
    em ServerStorage: o servidor entrega só para quem tem cargo.
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
local StarterGui        = game:GetService("StarterGui")

local ANNOUNCE_COLOR = "#FFB43C"
local WHISPER_COLOR  = "#3CDCEB"

local function Escape(s)
    return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        :gsub("\"", "&quot;"):gsub("'", "&apos;"))
end

local function Show(prefix, body, hex)
    -- chat novo (TextChatService)
    local ok = pcall(function()
        if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
            error("chat legado")
        end
        local channels = TextChatService:WaitForChild("TextChannels", 5)
        local ch = channels and (channels:FindFirstChild("RBXSystem")
            or channels:FindFirstChild("RBXGeneral"))
        if not ch then error("sem canal") end
        ch:DisplaySystemMessage(('<font color="%s"><b>%s</b></font> %s')
            :format(hex, Escape(prefix), Escape(body)))
    end)
    if ok then return end
    -- chat legado
    pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = prefix .. " " .. tostring(body),
            Color = Color3.fromHex(hex),
            Font = Enum.Font.GothamBold,
        })
    end)
end

local announce = ReplicatedStorage:WaitForChild("AdminAnnounce", 15)
if announce then
    announce.OnClientEvent:Connect(function(fromName, text)
        Show("[ANÚNCIO] " .. tostring(fromName) .. ":", text, ANNOUNCE_COLOR)
    end)
end

local whisper = ReplicatedStorage:WaitForChild("AdminWhisper", 15)
if whisper then
    whisper.OnClientEvent:Connect(function(fromName, text)
        -- "HYGE" = confirmação do servidor v9.1 para o painel do admin (a v9.2
        -- responde pelo HYGE_Result); o painel mostra no console dele
        if fromName == "HYGE" then return end
        Show("[PRIVADO de " .. tostring(fromName) .. "]", text, WHISPER_COLOR)
    end)
end
