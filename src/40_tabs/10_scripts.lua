--------------------------------------------------------------------------------
-- v8.0 — ABA SCRIPTS (ícone de terminal do dock)
-- O console de log sai do rodapé da janela e passa a morar aqui, ocupando a
-- aba inteira, com uma linha de comando embaixo (Enter executa, ↑/↓ histórico).
-- A barra flutuante do ";" continua existindo (com autocomplete no Tab).
-- Não é um ScrollingFrame como as outras abas: o console já rola sozinho.
--------------------------------------------------------------------------------
do
    local view = Instance.new("Frame")
    view.Name = "Scripts"
    view.Size = UDim2.new(1, 0, 1, 0)
    view.BackgroundTransparency = 1
    view.Visible = false
    view.Parent = Content
    Tabs.Scripts = view
    V8.ScriptsTab = view

    -- o console (criado em 10_ui/02_console.lua) muda de casa
    ConsoleFrame.Parent = view
    ConsoleFrame.Position = UDim2.new(0, 0, 0, 0)
    ConsoleFrame.Size = UDim2.new(1, 0, 1, -48)
    ConsoleFrame.Visible = true

    local box = CreateInput(view, "comando   ·   Enter executa   ·   ↑/↓ histórico   ·   help lista tudo", 38)
    box.Position = UDim2.new(0, 0, 1, -38)
    box.Size = UDim2.new(1, -112, 0, 38)
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    do
        local p = Instance.new("UIPadding", box)
        p.PaddingLeft = UDim.new(0, 12)
        p.PaddingRight = UDim.new(0, 12)
    end

    local run = CreateButton(view, "EXECUTAR", "Accent", 38)
    run.Position = UDim2.new(1, -104, 1, -38)
    run.Size = UDim2.new(0, 104, 0, 38)

    local histPos = 0
    local function Go()
        local text = box.Text
        box.Text = ""
        histPos = 0
        if text:match("^%s*$") then return end
        if V8.RunCommand then
            V8.RunCommand(text)
        else
            Log("Os comandos ainda não carregaram", "warn")
        end
    end

    box.FocusLost:Connect(function(enter)
        if enter then Go() end
    end)
    run.MouseButton1Click:Connect(Go)

    -- ↑/↓ percorrem o mesmo histórico da barra do ";" (State.CmdHistory)
    Conn.ScriptsHistory = UserInputService.InputBegan:Connect(function(input)
        if not box:IsFocused() then return end
        local hist = State.CmdHistory
        if #hist == 0 then return end
        if input.KeyCode == Enum.KeyCode.Up then
            histPos = math.min(histPos + 1, #hist)
        elseif input.KeyCode == Enum.KeyCode.Down then
            histPos = math.max(histPos - 1, 0)
        else
            return
        end
        box.Text = (histPos == 0) and "" or (hist[#hist - histPos + 1] or "")
        box.CursorPosition = #box.Text + 1
    end)

    -- "Modo compacto" só escondia o console do rodapé, que não existe mais
    if V8.CompactRow then V8.CompactRow.Visible = false end
end
