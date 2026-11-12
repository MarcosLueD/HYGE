--------------------------------------------------------------------------------
-- TOASTS  (ícone, categoria, barra de duração, fechar, limite de 4)
--------------------------------------------------------------------------------
do
local ToastHolder = Instance.new("Frame")
ToastHolder.Name = "Toasts"
ToastHolder.AnchorPoint = Vector2.new(1, 0)
ToastHolder.Position = UDim2.new(1, -18, 0, 18)
ToastHolder.Size = UDim2.new(0, 310, 1, -36)
ToastHolder.BackgroundTransparency = 1
ToastHolder.Parent = Gui

local toastLayout = Instance.new("UIListLayout", ToastHolder)
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local ToastList = {}
local TOAST_META = {
    info   = { icon = "i", key = "Accent"  },
    ok     = { icon = "+", key = "Success" },
    warn   = { icon = "!", key = "Warning" },
    error  = { icon = "x", key = "Danger"  },
    action = { icon = ">", key = "Accent2" },
}

local function KillToast(card)
    for i = #ToastList, 1, -1 do
        if ToastList[i] == card then table.remove(ToastList, i) end
    end
    if not card or not card.Parent then return end
    local out = TweenInfo.new(0.16)
    for _, d in ipairs(card:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            TweenService:Create(d, out, { TextTransparency = 1 }):Play()
        elseif d:IsA("Frame") then
            TweenService:Create(d, out, { BackgroundTransparency = 1 }):Play()
        elseif d:IsA("UIStroke") then
            TweenService:Create(d, out, { Transparency = 1 }):Play()
        end
    end
    TweenService:Create(card, out, { BackgroundTransparency = 1 }):Play()
    task.delay(0.2, function() if card then card:Destroy() end end)
end

Toast = function(text, kind, duration)
    if not SET.Toasts then return end
    local meta = TOAST_META[kind or "info"] or TOAST_META.info
    duration = duration or 2.6

    -- limite de toasts simultâneos: derruba os mais antigos
    while #ToastList >= 4 do
        local old = table.remove(ToastList, 1)
        if old then KillToast(old) end
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = THEME.Card
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = ToastHolder
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    table.insert(ToastList, card)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = THEME[meta.key]
    stroke.Transparency = 1

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 20, 0, 20)
    badge.Position = UDim2.new(0, 10, 0, 10)
    badge.BackgroundColor3 = THEME[meta.key]
    badge.BackgroundTransparency = 0.15
    badge.Text = meta.icon
    badge.TextColor3 = Color3.new(0, 0, 0)
    badge.Font = Enum.Font.GothamBlack
    badge.TextSize = 12
    badge.Parent = card
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0, 38, 0, 10)
    label.Size = UDim2.new(1, -62, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.Text
    label.TextTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -8, 0, 8)
    close.Size = UDim2.new(0, 18, 0, 18)
    close.BackgroundTransparency = 1
    close.Text = "x"
    close.TextColor3 = THEME.Dim
    close.TextTransparency = 1
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.AutoButtonColor = false
    close.Parent = card

    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0, 1)
    barBg.Position = UDim2.new(0, 10, 1, -6)
    barBg.Size = UDim2.new(1, -20, 0, 2)
    barBg.BackgroundColor3 = THEME.Track
    barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel = 0
    barBg.Parent = card
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = THEME[meta.key]
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local pad = Instance.new("UIPadding", card)
    pad.PaddingBottom = UDim.new(0, 16)

    local t = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(card, t, { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(label, t, { TextTransparency = 0 }):Play()
    TweenService:Create(close, t, { TextTransparency = 0.3 }):Play()
    TweenService:Create(stroke, t, { Transparency = 0.4 }):Play()
    TweenService:Create(barBg, t, { BackgroundTransparency = 0.6 }):Play()
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 1, 0) }):Play()

    close.MouseButton1Click:Connect(function() KillToast(card) end)
    task.delay(duration, function() KillToast(card) end)
end
end

