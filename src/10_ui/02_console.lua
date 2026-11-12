--------------------------------------------------------------------------------
-- CONSOLE / LOG  (categorias, filtro, limpar, copiar — incremental)
--------------------------------------------------------------------------------
do
ConsoleFrame = Instance.new("Frame")
ConsoleFrame.Name = "Console"
ConsoleFrame.Size = UDim2.new(1, -184, 0, 130)
ConsoleFrame.Position = UDim2.new(0, 172, 1, -142)
ConsoleFrame.BackgroundColor3 = THEME.Console
ConsoleFrame.BorderSizePixel = 0
ConsoleFrame.Parent = Window
Paint(ConsoleFrame, "BackgroundColor3", "Console")
Instance.new("UICorner", ConsoleFrame).CornerRadius = UDim.new(0, 10)

local consoleStroke = Instance.new("UIStroke", ConsoleFrame)
consoleStroke.Transparency = 0.75
Paint(consoleStroke, "Color", "Line")

local LogBar = Instance.new("Frame")
LogBar.Size = UDim2.new(1, -16, 0, 22)
LogBar.Position = UDim2.new(0, 8, 0, 6)
LogBar.BackgroundTransparency = 1
LogBar.Parent = ConsoleFrame

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -14, 1, -36)
LogScroll.Position = UDim2.new(0, 8, 0, 30)
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 3
LogScroll.ScrollingDirection = Enum.ScrollingDirection.Y
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.Parent = ConsoleFrame
Paint(LogScroll, "ScrollBarImageColor3", "Accent")

local logLayout = Instance.new("UIListLayout", LogScroll)
logLayout.Padding = UDim.new(0, 1)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- categorias: chave interna -> { rótulo, cor do tema }
local LOG_CAT = {
    info   = { "INFO",  "Dim"     },
    ok     = { "OK",    "Success" },
    warn   = { "AVISO", "Warning" },
    error  = { "ERRO",  "Danger"  },
    action = { "AÇÃO",  "Accent2" },
}
local LOG_ORDER = { "info", "ok", "warn", "error", "action" }

local LogEntries, logLabels, logSeq = {}, {}, 0
local LogFilter = "all"
local logChips = {}

local function LogPasses(e) return LogFilter == "all" or LogFilter == e.cat end

local function MakeLogLine(e)
    local meta = LOG_CAT[e.cat] or LOG_CAT.info
    logSeq = logSeq + 1
    local line = Instance.new("TextLabel")
    line.Size = UDim2.new(1, -6, 0, 17)
    line.BackgroundTransparency = 1
    line.Text = string.format("[%s] %-5s  %s", e.time, meta[1], e.msg)
    line.TextColor3 = THEME[meta[2]]
    line.Font = Enum.Font.Code
    line.TextSize = 12
    line.TextXAlignment = Enum.TextXAlignment.Left
    line.TextTruncate = Enum.TextTruncate.AtEnd
    line.LayoutOrder = logSeq
    line.Parent = LogScroll
    -- v8.0: linhas de log NÃO entram no registry de tema (cada Log() somava uma
    -- entrada que nunca saía — vazamento com Chat Spy ligado). O ApplyTheme
    -- redesenha o log inteiro com RenderLog(nil), que já usa as cores novas.
    table.insert(logLabels, line)
end

RenderLog = function(entry)
    if entry then
        if LogPasses(entry) then MakeLogLine(entry) end
    else
        for _, l in ipairs(logLabels) do if l then l:Destroy() end end
        logLabels = {}
        for _, e in ipairs(LogEntries) do
            if LogPasses(e) then MakeLogLine(e) end
        end
    end
    while #logLabels > SET.MaxLog do
        local first = table.remove(logLabels, 1)
        if first then first:Destroy() end
    end
    LogScroll.CanvasPosition = Vector2.new(0, math.max(0, LogScroll.AbsoluteCanvasSize.Y))
end

ClearLog = function()
    LogEntries = {}
    RenderLog(nil)
end

Log = function(msg, kind)
    kind = kind or "info"
    if not LOG_CAT[kind] then kind = "info" end
    -- v8.0: a opção "Registrar no console" existia mas nunca era lida.
    -- Desligada, só os ERROS continuam chegando no console.
    if SET.ShowLogs == false and kind ~= "error" then return end
    local entry = { time = os.date("%H:%M:%S"), cat = kind, msg = tostring(msg) }
    table.insert(LogEntries, entry)
    while #LogEntries > math.max(SET.MaxLog, 10) do table.remove(LogEntries, 1) end
    RenderLog(entry)
    print("[HYGE] " .. entry.msg)
end

-- chips de filtro + ações do console
do
    local function Chip(text, filter, order, colorKey)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 58, 0, 22)
        b.Position = UDim2.new(0, 46 + (order - 1) * 62, 0, 0)
        b.BackgroundColor3 = THEME[colorKey]
        b.BackgroundTransparency = 0.8
        b.Text = text
        b.TextColor3 = THEME[colorKey]
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = LogBar
        Paint(b, "BackgroundColor3", colorKey)
        Paint(b, "TextColor3", colorKey)
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        local cs = Instance.new("UIStroke", b)
        cs.Color = THEME[colorKey]
        cs.Transparency = 1
        logChips[filter] = { btn = b, stroke = cs }
        b.MouseButton1Click:Connect(function()
            LogFilter = filter
            for f, chip in pairs(logChips) do
                local on = (f == filter)
                chip.btn.BackgroundTransparency = on and 0.45 or 0.85
                chip.stroke.Transparency = on and 0.3 or 1
            end
            RenderLog(nil)
        end)
        return b
    end

    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(0, 42, 0, 22)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "LOGS"
    logTitle.TextColor3 = THEME.Text
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextSize = 12
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = LogBar
    Paint(logTitle, "TextColor3", "Text")

    Chip("TUDO", "all", 1, "Text")
    for i, cat in ipairs(LOG_ORDER) do
        Chip(LOG_CAT[cat][1], cat, i + 1, LOG_CAT[cat][2])
    end
    logChips.all.btn.BackgroundTransparency = 0.45
    logChips.all.stroke.Transparency = 0.3

    local function MiniBtn(text, offset, colorKey, fn)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, 0)
        b.Position = UDim2.new(1, -offset, 0, 1)
        b.Size = UDim2.new(0, 66, 0, 22)
        b.BackgroundColor3 = THEME.Btn
        b.Text = "  " .. text
        b.TextColor3 = THEME[colorKey]
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.AutoButtonColor = false
        b.Parent = LogBar
        Paint(b, "BackgroundColor3", "Btn")
        Paint(b, "TextColor3", colorKey)
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        if Icon then
            local ic = Icon(b, (text == "LIMPAR") and "trash" or "copy", THEME[colorKey], 12)
            ic.Position = UDim2.new(0, 8, 0.5, -6)
            b.Text = "     " .. text
        end
        b.MouseButton1Click:Connect(fn)
        return b
    end

    MiniBtn("COPIAR", 72, "Accent", function()
        local out = {}
        for _, e in ipairs(LogEntries) do
            local meta = LOG_CAT[e.cat] or LOG_CAT.info
            table.insert(out, string.format("[%s] %s  %s", e.time, meta[1], e.msg))
        end
        local text = table.concat(out, "\n")
        if setclipboard then
            setclipboard(text)
            Toast("Log copiado (" .. #LogEntries .. " linhas)", "ok", 1.6)
        else
            print(text)
            Toast("Executor sem setclipboard — log jogado no output", "warn")
        end
    end)

    MiniBtn("LIMPAR", 2, "Warning", function() ClearLog() end)
end
end

