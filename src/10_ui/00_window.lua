--------------------------------------------------------------------------------
-- GUI RAIZ
--------------------------------------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "HYGE_PANEL"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = GuiParent

-- alguns executores exigem protect_gui pra UI não ser limpa
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(Gui) end
end)

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 920, 0, 600)
Window.Position = UDim2.new(0.5, -460, 0.5, -300)
Window.BackgroundColor3 = THEME.Main
Window.BorderSizePixel = 0
Window.Visible = false
Window.Parent = Gui
Paint(Window, "BackgroundColor3", "Main")
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 16)

local WindowScale = Instance.new("UIScale", Window)
WindowScale.Scale = CONFIG.UiScale

local winStroke = Instance.new("UIStroke", Window)
winStroke.Thickness = 1.4
winStroke.Transparency = 0.55
Paint(winStroke, "Color", "Accent")

local winShadow = Instance.new("ImageLabel")
winShadow.Name = "Shadow"
winShadow.AnchorPoint = Vector2.new(0.5, 0.5)
winShadow.Position = UDim2.new(0.5, 0, 0.5, 4)
winShadow.Size = UDim2.new(1, 56, 1, 56)
winShadow.BackgroundTransparency = 1
winShadow.Image = "rbxassetid://6014261993"
winShadow.ImageColor3 = Color3.new(0, 0, 0)
winShadow.ImageTransparency = 0.35
winShadow.ScaleType = Enum.ScaleType.Slice
winShadow.SliceCenter = Rect.new(49, 49, 450, 450)
winShadow.ZIndex = -1
winShadow.Parent = Window

