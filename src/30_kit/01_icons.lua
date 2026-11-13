--------------------------------------------------------------------------------
-- ÍCONES VETORIAIS
-- Sem asset: cada ícone é um punhado de Frames posicionados numa grade 24x24 e
-- escalados. shape = { x, y, w, h, rot, corner, outline }
--------------------------------------------------------------------------------
do
    local S = {
        -- v8.0: casinha em contorno (telhado em ^, paredes, chão e porta)
        home   = { {0.5,6.5,13.5,2,-43,1}, {10,6.5,13.5,2,43,1}, {5,11,2,11,0,1},
                   {17,11,2,11,0,1}, {5,20,14,2,0,1}, {10,15,4,7,0,1,1} },
        run    = { {13,1,6,6,0,3}, {6,7,3,10,-25,2}, {12,9,3,11,20,2}, {3,12,9,3,15,2} },
        eye    = { {2,6,20,12,0,6,1}, {9,9,6,6,0,3} },
        -- v8.0: duas pessoas em contorno (a de trás menor, sem se cruzarem)
        users  = { {3,3,8,8,0,4,1}, {1,13,12,9,0,5,1}, {14,4,7,7,0,4,1},
                   {15,14,8,8,0,4,1} },
        shield = { {4,3,16,10,0,3}, {7,10,10,10,45,3} },
        server = { {3,4,18,5,0,2,1}, {3,11,18,5,0,2,1}, {3,18,18,4,0,2,1} },
        smile  = { {2,2,20,20,0,10,1}, {7,8,3,3,0,2}, {14,8,3,3,0,2}, {7,15,10,3,0,2} },
        gear   = { {4,4,16,16,0,8,1}, {10,1,4,5,0,1}, {10,18,4,5,0,1}, {1,10,5,4,0,1},
                   {18,10,5,4,0,1} },
        bolt   = { {8,2,4,12,18,1}, {12,10,4,12,18,1} },
        ghost  = { {6,6,12,12,45,2,1} },
        cam    = { {2,7,15,11,0,3,1}, {16,9,7,7,25,2} },
        up     = { {11,5,3,16,0,1}, {7,7,9,3,-45,1}, {13,7,9,3,45,1} },
        circle = { {3,3,18,18,0,9,1} },
        sun    = { {7,7,10,10,0,5}, {11,1,2,5,0,1}, {11,18,2,5,0,1}, {1,11,5,2,0,1},
                   {18,11,5,2,0,1} },
        signal = { {3,15,3,6,0,1}, {8,11,3,10,0,1}, {13,7,3,14,0,1}, {18,3,3,18,0,1} },
        box    = { {3,6,18,14,0,3,1}, {3,6,18,4,0,1} },
        clip   = { {5,3,14,18,0,3,1}, {9,1,6,4,0,1} },
        wifi   = { {3,7,18,18,0,9,1}, {7,11,10,10,0,5,1}, {10,17,4,4,0,2} },
        clock  = { {3,3,18,18,0,9,1}, {11,7,2,6,0,1}, {12,11,6,2,0,1} },
        copy   = { {2,2,13,13,0,3,1}, {9,9,13,13,0,3,1} },
        power  = { {3,6,18,16,0,9,1}, {11,1,2,10,0,1} },
        trash  = { {5,6,14,15,0,3,1}, {3,3,18,3,0,1} },
        dot    = { {8,8,8,8,0,4} },
        -- v8: ícones do shell novo (dock do mockup)
        code   = { {2,7,9,3,45,1}, {2,14,9,3,-45,1},
                   {13,7,9,3,-45,1}, {13,14,9,3,45,1} },
        music  = { {4,15,8,7,0,4}, {10,3,3,15,0,1}, {10,3,9,4,0,2} },
        cloud  = { {3,12,18,8,0,4}, {7,6,10,9,0,5}, {13,9,8,8,0,4} },
        mic    = { {9,2,6,11,0,3}, {5,10,14,8,0,4,1}, {11,17,2,4,0,1},
                   {8,21,8,2,0,1} },
        check  = { {4,12,9,3,45,1}, {9,7,13,3,-45,1} },
        dots   = { {2,10,4,4,0,2}, {10,10,4,4,0,2}, {18,10,4,4,0,2} },
        search = { {3,3,15,15,0,7,1}, {15,15,7,3,45,1} },
        -- v8.0: dock de 8 seções
        user     = { {8,2,8,8,0,4,1}, {4,13,16,9,0,6,1} },
        bag      = { {4,8,16,14,0,3,1}, {8,4,2,6,0,1}, {14,4,2,6,0,1}, {8,3,8,2,0,1} },
        terminal = { {2,4,20,16,0,3,1}, {5,8.5,6,2,35,1}, {5,11.5,6,2,-35,1},
                     {12,14,6,2,0,1} },
        grid     = { {3,3,8,8,0,2,1}, {13,3,8,8,0,2,1}, {3,13,8,8,0,2,1},
                     {13,13,8,8,0,2,1} },
        chat     = { {2,3,20,15,0,7,1}, {5,16,3,6,25,1} },
    }

    Icon = function(parent, kind, color, size, order)
        size = size or 18
        local k = size / 24
        local root = Instance.new("Frame")
        root.Name = "Icon"
        root.Size = UDim2.new(0, size, 0, size)
        root.BackgroundTransparency = 1
        root.LayoutOrder = order or 1
        root.Parent = parent
        for _, s in ipairs(S[kind] or S.dot) do
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.new(0, (s[1] + s[3] * 0.5) * k, 0, (s[2] + s[4] * 0.5) * k)
            f.Size = UDim2.new(0, s[3] * k, 0, s[4] * k)
            f.Rotation = s[5] or 0
            f.BorderSizePixel = 0
            f.BackgroundColor3 = color
            f.Parent = root
            if (s[6] or 0) > 0 then
                Instance.new("UICorner", f).CornerRadius = UDim.new(0, math.max(1, s[6] * k))
            end
            if s[7] == 1 then
                f.BackgroundTransparency = 1
                local st = Instance.new("UIStroke", f)
                st.Thickness = math.max(1, 2 * k)
                st.Color = color
            end
        end
        return root
    end

    -- repinta um ícone inteiro (usado no estado ativo da sidebar)
    IconTint = function(root, color)
        if not root then return end
        for _, f in ipairs(root:GetChildren()) do
            if f:IsA("Frame") then
                f.BackgroundColor3 = color
                local st = f:FindFirstChildOfClass("UIStroke")
                if st then st.Color = color end
            end
        end
    end
end
