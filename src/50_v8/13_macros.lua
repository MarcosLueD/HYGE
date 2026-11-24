--------------------------------------------------------------------------------
-- v9.0 — MACROS DE TECLADO (Configurações › Teclas › Macros de teclado)
-- Uma tecla roda qualquer comando da barra (;) — "tp joao", "sit caça",
-- "flyspeed 200", "theme rosa"... Vários de uma vez: separe com &&
-- ("fly on && flyspeed 150"). Até 12 macros, salvas em SET.Macros
-- ({ key = "H", cmd = "..." }) na config e nos perfis.
-- A tecla não pode ser de outra coisa (painel, barra, busca, função,
-- situação); ao dar a tecla de uma macro para uma função, a macro perde a
-- tecla (com aviso). Com Fly/Freecam/Drone/Walk on Walls ligados, as teclas
-- de movimento deles não disparam macro.
-- O handler global de teclas (90_runtime/03_input.lua) chama V8.Macro.HandleKey.
-- Tudo dentro de Build(): zero locais novos no chunk principal.
--------------------------------------------------------------------------------
do
    local function Build()
        V8.Macro = { Max = 12 }
        local M = V8.Macro
        local function List()
            if type(SET.Macros) ~= "table" then SET.Macros = {} end
            return SET.Macros
        end
        List()

        local function KC(name)
            if type(name) ~= "string" then return nil end
            local ok, kc = pcall(function() return Enum.KeyCode[name] end)
            return ok and kc or nil
        end

        -- de quem é esta tecla? (nil = livre). 'except' = índice da macro que
        -- está pedindo (ela não conflita consigo mesma)
        M.Owner = function(kc, except)
            if kc == CONFIG.PanelKey then return "abrir o painel" end
            if kc == CONFIG.ConsoleKey then return "barra de comandos" end
            if kc == CONFIG.SearchKey and not CONFIG.SearchCtrl then return "busca global" end
            if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Return
                or kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Tab
                or kc == Enum.KeyCode.Slash then
                return "uso do Roblox"
            end
            for id, k in pairs(Keybinds) do
                if k == kc then return (Toggles[id] and Toggles[id].label or id) end
            end
            if V8.Sit then
                for n, k in pairs(V8.Sit.Keys) do
                    if k == kc then return "situação " .. n end
                end
            end
            for i, m in ipairs(List()) do
                if i ~= except and m.key == kc.Name then return "macro " .. i end
            end
            return nil
        end

        -- outra coisa pegou esta tecla: a macro que tinha ela fica sem tecla
        M.Release = function(kc)
            for i, m in ipairs(List()) do
                if m.key == kc.Name then
                    m.key = nil
                    Log("[" .. KeyName(kc) .. "] estava na macro " .. i .. " ('" .. tostring(m.cmd)
                        .. "') — ela ficou sem tecla", "warn")
                    Toast("Macro " .. i .. " perdeu a tecla " .. KeyName(kc), "warn", 3)
                end
            end
            if M.Render then pcall(M.Render) end
        end

        M.Run = function(m)
            local n = 0
            for part in (tostring(m.cmd or "") .. "&&"):gmatch("(.-)&&") do
                if part:match("%S") and V8.RunCommand then
                    V8.RunCommand(part)
                    n = n + 1
                end
            end
            return n
        end

        M.HandleKey = function(input)
            local kc = input.KeyCode
            for _, m in ipairs(List()) do
                if m.key == kc.Name and type(m.cmd) == "string" and m.cmd:match("%S") then
                    -- WASD do fly/freecam/drone: a tecla está ocupada movendo
                    if V8.KeyBusy and V8.KeyBusy(kc, nil) then return false end
                    M.Run(m)
                    return true
                end
            end
            return false
        end

        ----------------------------------------------------------------------------
        -- Ajustes › Macros de teclado
        ----------------------------------------------------------------------------
        local card = CreateCard(Tabs.Settings, "MACROS DE TECLADO", 1)
        SubLabel(card, "Uma tecla roda qualquer comando da barra (;). Exemplos: tp joao · "
            .. "sit caça · flyspeed 200 · theme rosa. Vários comandos: separe com && "
            .. "(fly on && flyspeed 150). Clique na tecla e aperte; Backspace tira.", -1)

        local list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
        list.BackgroundTransparency = 1
        list.LayoutOrder = 1
        list.Parent = card
        do
            local l = Instance.new("UIListLayout", list)
            l.Padding = UDim.new(0, 6)
            l.SortOrder = Enum.SortOrder.LayoutOrder
        end
        local empty = SubLabel(card, "Nenhuma macro ainda.", 2)

        local bAdd = CreateButton(card, "+ NOVA MACRO", "Success", 32)
        bAdd.LayoutOrder = 3

        local function Capture(i, btn)
            Drop("MacroCapture")
            if StopCapture then pcall(StopCapture) end
            capturing = "macro"
            btn.Text = "aperte..."
            Toast("Aperte a tecla da macro " .. i .. " (Backspace tira)", nil, 3)
            Conn.MacroCapture = UserInputService.InputBegan:Connect(function(input)
                if capturing ~= "macro" then
                    Drop("MacroCapture")
                    return
                end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                local kc = input.KeyCode
                if kc == Enum.KeyCode.Unknown then return end
                Drop("MacroCapture")
                -- solta depois deste evento: senão o handler global já roda a macro
                task.defer(function() if capturing == "macro" then capturing = nil end end)
                local m = List()[i]
                if not m then return end
                if kc == Enum.KeyCode.Backspace then
                    m.key = nil
                    Log("Macro " .. i .. " sem tecla", "action")
                else
                    local owner = M.Owner(kc, i)
                    if owner then
                        Toast("[" .. KeyName(kc) .. "] já é de " .. owner .. " — escolha outra", "warn", 3)
                    else
                        m.key = kc.Name
                        Log("Macro " .. i .. " = [" .. KeyName(kc) .. "] " .. tostring(m.cmd), "ok")
                    end
                end
                pcall(M.Render)
            end)
        end

        M.Render = function()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            local all = List()
            empty.Visible = (#all == 0)
            for i, m in ipairs(all) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 42)
                row.BackgroundTransparency = 1
                row.LayoutOrder = i
                row.Parent = list
                V8.Cell(row, 0)

                local kb = Instance.new("TextButton")
                kb.AnchorPoint = Vector2.new(0, 0.5)
                kb.Position = UDim2.new(0, 0, 0.5, 0)
                kb.Size = UDim2.new(0, 70, 0, 28)
                kb.BackgroundColor3 = THEME.Btn
                kb.Text = m.key and KeyName(KC(m.key)) or "tecla"
                kb.TextColor3 = m.key and THEME.Accent2 or THEME.Dim
                kb.Font = Enum.Font.GothamBold
                kb.TextSize = 12
                kb.AutoButtonColor = false
                kb.Parent = row
                Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 7)
                do
                    local st = Instance.new("UIStroke", kb)
                    st.Transparency = 0.6
                    st.Color = THEME.Accent
                end
                kb.MouseButton1Click:Connect(function() Capture(i, kb) end)

                local box = Instance.new("TextBox")
                box.AnchorPoint = Vector2.new(0, 0.5)
                box.Position = UDim2.new(0, 80, 0.5, 0)
                box.Size = UDim2.new(1, -160, 0, 28)
                box.BackgroundColor3 = THEME.Btn
                box.Text = tostring(m.cmd or "")
                box.PlaceholderText = "comando (ex.: tp joao)"
                box.PlaceholderColor3 = THEME.Dim
                box.TextColor3 = THEME.Text
                box.Font = Enum.Font.Code
                box.TextSize = 12
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.ClearTextOnFocus = false
                box.Parent = row
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
                do
                    local p = Instance.new("UIPadding", box)
                    p.PaddingLeft = UDim.new(0, 8)
                    p.PaddingRight = UDim.new(0, 8)
                end
                box.FocusLost:Connect(function()
                    local t = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
                    if t ~= m.cmd then
                        m.cmd = t
                        Log("Macro " .. i .. ": " .. (t ~= "" and t or "(vazia)"), "action")
                    end
                end)

                local function IconBtn(kind, colorKey, x)
                    local b = Instance.new("TextButton")
                    b.AnchorPoint = Vector2.new(1, 0.5)
                    b.Position = UDim2.new(1, x, 0.5, 0)
                    b.Size = UDim2.new(0, 30, 0, 28)
                    b.BackgroundColor3 = THEME.Btn
                    b.Text = ""
                    b.AutoButtonColor = false
                    b.Parent = row
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
                    local ic = Icon(b, kind, THEME[colorKey], 13)
                    ic.AnchorPoint = Vector2.new(0.5, 0.5)
                    ic.Position = UDim2.new(0.5, 0, 0.5, 0)
                    return b
                end
                -- roda esta macro agora (para testar sem precisar da tecla)
                local run = IconBtn("play", "Success", -36)
                run.MouseButton1Click:Connect(function()
                    if not (m.cmd or ""):match("%S") then
                        Toast("Escreva o comando da macro " .. i .. " antes", "warn", 2)
                        return
                    end
                    M.Run(m)
                end)
                local del = IconBtn("trash", "Danger", 0)
                del.MouseButton1Click:Connect(function()
                    table.remove(List(), i)
                    Log("Macro " .. i .. " apagada", "action")
                    pcall(M.Render)
                end)
            end
            bAdd.Visible = (#all < M.Max)
        end

        bAdd.MouseButton1Click:Connect(function()
            local all = List()
            if #all >= M.Max then
                Toast("Limite de " .. M.Max .. " macros", "warn", 2)
                return
            end
            table.insert(all, { cmd = "" })
            pcall(M.Render)
            Toast("Macro " .. #all .. " criada: escreva o comando e escolha a tecla", "ok", 3)
        end)

        V8.Renders = V8.Renders or {}
        table.insert(V8.Renders, function() pcall(M.Render) end)
        M.Render()
    end
    Build()
end
