--------------------------------------------------------------------------------
-- TOP BAR / SIDEBAR / CONTENT
--------------------------------------------------------------------------------
local TopBar, Stat, CloseBtn, MinBtn, Sidebar, Content  -- usados fora do bloco
do
TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 56)
TopBar.BackgroundColor3 = THEME.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = Window
Paint(TopBar, "BackgroundColor3", "Sidebar")
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 16)
topFix.Position = UDim2.new(0, 0, 1, -16)
topFix.BackgroundColor3 = THEME.Sidebar
topFix.BorderSizePixel = 0
topFix.Parent = TopBar
Paint(topFix, "BackgroundColor3", "Sidebar")

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 30, 0, 30)
Logo.Position = UDim2.new(0, 16, 0.5, -15)
Logo.BackgroundColor3 = THEME.Accent
Logo.BorderSizePixel = 0
Logo.Parent = TopBar
Paint(Logo, "BackgroundColor3", "Accent")
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 9)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "H"
logoText.TextColor3 = Color3.new(0, 0, 0)
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 17
logoText.Parent = Logo

-- Com LogoId preenchido a caixa vira a imagem da marca (fundo some)
if CONFIG.LogoId ~= "" then
    Logo.BackgroundTransparency = 1
    logoText.Visible = false
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, 6, 1, 6)
    img.Position = UDim2.new(0, -3, 0, -3)
    img.BackgroundTransparency = 1
    img.Image = CONFIG.LogoId
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = Logo
end

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 220, 1, 0)
Title.Position = UDim2.new(0, 56, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "HYGE"
Title.TextColor3 = THEME.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar
Paint(Title, "TextColor3", "Text")

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 60, 0, 18)
Version.Position = UDim2.new(0, 116, 0.5, -8)
Version.BackgroundColor3 = THEME.Btn
Version.Text = CONFIG.Version
Version.TextColor3 = THEME.Accent
Version.Font = Enum.Font.GothamBold
Version.TextSize = 11
Version.Size = UDim2.new(0, 40, 0, 18)
Version.Parent = TopBar
Paint(Version, "BackgroundColor3", "Btn")
Paint(Version, "TextColor3", "Accent")
Instance.new("UICorner", Version).CornerRadius = UDim.new(0, 5)

Stat = Instance.new("TextLabel")
Stat.Size = UDim2.new(0, 400, 1, 0)
Stat.Position = UDim2.new(1, -500, 0, 0)
Stat.BackgroundTransparency = 1
Stat.TextColor3 = THEME.Dim
Stat.Font = Enum.Font.Code
Stat.TextSize = 12
Stat.TextXAlignment = Enum.TextXAlignment.Right
Stat.Text = "..."
Stat.Parent = TopBar
Paint(Stat, "TextColor3", "Dim")

local function WindowButton(symbol, order, colorKey)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30)
    b.Position = UDim2.new(1, -16 - (order * 36), 0.5, -15)
    b.BackgroundColor3 = THEME.Btn
    b.Text = symbol
    b.TextColor3 = THEME.Dim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.AutoButtonColor = false
    b.Parent = TopBar
    Paint(b, "BackgroundColor3", "Btn")
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = THEME[colorKey or "Accent"], TextColor3 = Color3.new(0, 0, 0) }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = THEME.Btn, TextColor3 = THEME.Dim }):Play()
    end)
    return b
end

CloseBtn = WindowButton("X", 1, "Danger")
MinBtn   = WindowButton("—", 2, "Accent")

--------------------------------------------------------------------------------
-- SIDEBAR
--------------------------------------------------------------------------------
Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 164, 1, -56)
Sidebar.Position = UDim2.new(0, 0, 0, 56)
Sidebar.BackgroundColor3 = THEME.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window
Paint(Sidebar, "BackgroundColor3", "Sidebar")

local sidePad = Instance.new("UIPadding", Sidebar)
sidePad.PaddingTop = UDim.new(0, 10)
sidePad.PaddingLeft = UDim.new(0, 10)
sidePad.PaddingRight = UDim.new(0, 10)

local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.Padding = UDim.new(0, 5)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -184, 1, -214)
Content.Position = UDim2.new(0, 172, 0, 64)
Content.BackgroundTransparency = 1
Content.Parent = Window
end

