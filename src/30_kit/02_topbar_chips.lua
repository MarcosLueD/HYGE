--------------------------------------------------------------------------------
-- CHIPS DA TOP BAR
-- Substitui a linha de texto "FPS ... • PING ..." por chips com ícone.
-- Reaproveita o mesmo Every(0.5) que já existia (nenhum loop novo): o scheduler
-- chama SetChips() em vez de escrever em Stat.Text.
--------------------------------------------------------------------------------
do
    Stat.Visible = false

    local row = Instance.new("Frame")
    row.Name = "StatChips"
    row.AnchorPoint = Vector2.new(1, 0.5)
    row.Position = UDim2.new(1, -92, 0.5, 0)
    row.Size = UDim2.new(0, 620, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = TopBar

    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 18)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local L = {}

    local function Chip(kind, iconColor, order)
        local holder = Instance.new("Frame")
        holder.AutomaticSize = Enum.AutomaticSize.X
        holder.Size = UDim2.new(0, 0, 0, 24)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = order
        holder.Parent = row

        local h = Instance.new("UIListLayout", holder)
        h.FillDirection = Enum.FillDirection.Horizontal
        h.VerticalAlignment = Enum.VerticalAlignment.Center
        h.Padding = UDim.new(0, 7)
        h.SortOrder = Enum.SortOrder.LayoutOrder

        Icon(holder, kind, iconColor, 16, 1)

        local t = Instance.new("TextLabel")
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Size = UDim2.new(0, 0, 0, 20)
        t.BackgroundTransparency = 1
        t.Text = "—"
        t.TextColor3 = THEME.Text
        t.Font = Enum.Font.GothamMedium
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.LayoutOrder = 2
        t.Parent = holder
        Paint(t, "TextColor3", "Text")
        return t
    end

    L.fps     = Chip("signal", THEME.Success, 1)
    L.ping    = Chip("signal", THEME.Accent2, 2)
    L.players = Chip("users",  THEME.Accent,  3)
    L.name    = Chip("clip",   THEME.Dim,     4)
    L.watch   = Chip("eye",    THEME.Warning, 5)
    L.watch.Parent.Visible = false

    -- chamado pelo scheduler existente
    SetChips = function(fps, ping, np, maxp, pname, watching)
        L.fps.Text = "FPS " .. fps
        L.fps.TextColor3 = (fps >= 50 and THEME.Text) or (fps >= 30 and THEME.Warning)
            or THEME.Danger
        L.ping.Text = "PING " .. ping .. "ms"
        L.players.Text = np .. "/" .. maxp .. " jogadores"
        L.name.Text = pname
        if watching then
            L.watch.Text = "ASSISTINDO " .. watching
            L.watch.Parent.Visible = true
        else
            L.watch.Parent.Visible = false
        end
    end
end
