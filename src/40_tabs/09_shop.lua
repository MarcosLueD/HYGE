--------------------------------------------------------------------------------
-- v8.0 — ABA SHOP (ícone de sacola do dock)
-- Ainda não existe loja no HYGE: a aba só avisa. Nada aqui é clicável nem
-- finge vender/desbloquear alguma coisa.
--------------------------------------------------------------------------------
do
    local tab = CreateTab("Shop")
    local card = CreateCard(tab, "SHOP", 1)

    local big = Instance.new("TextLabel")
    big.Size = UDim2.new(1, 0, 0, 34)
    big.BackgroundTransparency = 1
    big.Text = "Em breve"
    big.TextColor3 = THEME.Text
    big.Font = Enum.Font.GothamBold
    big.TextSize = 24
    big.TextXAlignment = Enum.TextXAlignment.Left
    big.LayoutOrder = 1
    big.Parent = card
    Paint(big, "TextColor3", "Text")

    SubLabel(card, "A loja ainda não existe no HYGE. Quando ela entrar, os itens "
        .. "aparecem aqui — por enquanto não há nada para comprar ou desbloquear.", 2)
end
