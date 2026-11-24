--------------------------------------------------------------------------------
-- v9.1 — SHA-256 (integridade da atualização)
-- A atualização do painel (50_v8/09_update.lua) confere o main.lua baixado
-- contra o manifest.json do repositório antes de trocar qualquer coisa.
-- Lua puro + bit32 (FIPS 180-4): não depende de criptografia do executor.
-- O bloco entre os marcadores é CÓPIA EXATA do que está no loader.lua — o
-- tests/integrity.test.js confere as duas cópias e compara com o SHA-256 do
-- Node. Mudou aqui, mude lá.
--------------------------------------------------------------------------------
do
-- [sha256:begin]
local Sha256
do
    local band, bxor, bnot = bit32.band, bit32.bxor, bit32.bnot
    local rrotate, rshift = bit32.rrotate, bit32.rshift
    local byte, char, rep, fmt = string.byte, string.char, string.rep, string.format
    local MOD = 4294967296
    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }
    local function be32(n)
        return char(band(rshift(n, 24), 255), band(rshift(n, 16), 255), band(rshift(n, 8), 255), band(n, 255))
    end
    -- hex minúsculo do SHA-256 dos bytes de msg
    Sha256 = function(msg)
        local len = #msg
        local hi = math.floor(len * 8 / MOD)
        local lo = len * 8 - hi * MOD
        msg = msg .. "\128" .. rep("\0", (55 - len) % 64) .. be32(hi) .. be32(lo)
        local H1, H2, H3, H4 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
        local H5, H6, H7, H8 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        local w = {}
        for i = 1, #msg, 64 do
            for j = 1, 16 do
                local p = i + (j - 1) * 4
                local a, b, c, d = byte(msg, p, p + 3)
                w[j] = ((a * 256 + b) * 256 + c) * 256 + d
            end
            for j = 17, 64 do
                local x, y = w[j - 15], w[j - 2]
                local s0 = bxor(rrotate(x, 7), rrotate(x, 18), rshift(x, 3))
                local s1 = bxor(rrotate(y, 17), rrotate(y, 19), rshift(y, 10))
                w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % MOD
            end
            local a, b, c, d, e, f, g, h = H1, H2, H3, H4, H5, H6, H7, H8
            for j = 1, 64 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local t1 = (h + S1 + ch + K[j] + w[j]) % MOD
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                h, g, f, e = g, f, e, (d + t1) % MOD
                d, c, b, a = c, b, a, (t1 + S0 + maj) % MOD
            end
            H1, H2, H3, H4 = (H1 + a) % MOD, (H2 + b) % MOD, (H3 + c) % MOD, (H4 + d) % MOD
            H5, H6, H7, H8 = (H5 + e) % MOD, (H6 + f) % MOD, (H7 + g) % MOD, (H8 + h) % MOD
        end
        -- em metades de 16 bits: "%08x" com número >= 2^31 quebra em Lua de
        -- inteiro 32 bits (e assim o mesmo código roda em qualquer Lua)
        local out = {}
        for i, v in ipairs({ H1, H2, H3, H4, H5, H6, H7, H8 }) do
            out[i] = fmt("%04x%04x", math.floor(v / 65536), v % 65536)
        end
        return table.concat(out)
    end
end
-- [sha256:end]
    V8.Sha256 = Sha256

    -- confere um main.lua baixado contra o manifest.json do repositório.
    -- Devolve true ou false + motivo. O hash é do texto com quebras LF (o
    -- GitHub serve LF; o build calcula igual).
    V8.VerifyBuild = function(src, man)
        if type(src) ~= "string" or #src == 0 then return false, "arquivo vazio" end
        if type(man) ~= "table" or type(man.sha256) ~= "string" or type(man.size) ~= "number" then
            return false, "manifesto inválido"
        end
        local lf = src:gsub("\r\n", "\n")
        if #lf ~= man.size then
            return false, "incompleto (" .. #lf .. " de " .. tostring(man.size) .. " bytes)"
        end
        if Sha256(lf) ~= man.sha256:lower() then return false, "SHA-256 não confere" end
        local build = src:match("%-%- build: (%x+)")
        if man.build and build ~= man.build then return false, "build diferente do manifesto" end
        return true
    end
end
