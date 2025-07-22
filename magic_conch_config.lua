local MagicConch_Config = {}

local VERSION = "1.0"
MagicConch_Config.VERSION = VERSION

local DefaultConfig = {
    enabled = true,
    resoluteMode = false, -- Resolute Mode  
    language = "auto",   -- "auto", "EN", "KO"
    hotkey = Keyboard.KEY_M,
    displayStyle = 0, -- 0: Fortune, 1: Rule-Style
    debugMode = false, -- Debug Mode
    debugHudX = 60,    -- Debug HUD X coordinate (default 60)
    debugHudY = 40,    -- Debug HUD Y coordinate (default 40)
}

local json = nil
pcall(function() json = require("json") end)
if not json then
    json = {
        encode = function(data) return tostring(data) end,
        decode = function(str) return {} end,
    }
end

function MagicConch_Config.Init(mod)
    mod.Config = mod.Config or {}
    for k, v in pairs(DefaultConfig) do
        if mod.Config[k] == nil then
            mod.Config[k] = v
        end
    end
    mod.Config.Version = VERSION
    return mod.Config
end

function MagicConch_Config.Load(mod)
    if mod:HasData() then
        local ok, data = pcall(function() return json.decode(Isaac.LoadModData(mod)) end)
        if ok and type(data) == "table" then
            for k, v in pairs(DefaultConfig) do
                if data[k] ~= nil then
                    mod.Config[k] = data[k]
                end
            end
            return true
        end
    end
    return false
end

function MagicConch_Config.Save(mod)
    Isaac.SaveModData(mod, json.encode(mod.Config))
end

function MagicConch_Config.Reset(mod)
    for k, v in pairs(DefaultConfig) do
        mod.Config[k] = v
    end
    MagicConch_Config.Save(mod)
end

return MagicConch_Config 