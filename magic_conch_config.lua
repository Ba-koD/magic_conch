---@class MagicConchConfig
---@field Init fun(mod: table): table
---@field Load fun(mod: table): boolean
---@field Save fun(mod: table)
---@field Reset fun(mod: table)
local MagicConch_Config = {}

local VERSION = "1.0" -- Version of the mod
MagicConch_Config.VERSION = VERSION

-- Default Config
local DefaultConfig = {
    enabled = true,
    resoluteMode = false, -- Resolute Mode  
    language = "Auto",   -- "Auto", "EN", "KR" (edit in magic_conch_lang.lua)
    hotkey = Keyboard.KEY_N,
    displayStyle = 1, -- 0: Fortune Machine Style, 1: Item-like Style
    debugMode = false, -- Debug Mode
    debugHudX = 60,    -- Debug HUD X coordinate (default 60)
    debugHudY = 40,    -- Debug HUD Y coordinate (default 40)
    
    -- Timing Settings (in frames, 30fps)
    timing = {
        shake = 15,        -- Screen Shake (0.5s)
        wait = 45,         -- Wait Time (1.5s)
        display = 60,     -- Display Time (2s)
        cooldown = 0      -- Cooldown (0s)
    }
}

-- JSON library for saving and loading config
local json = nil
pcall(function() json = require("json") end)
if not json then
    json = {
        encode = function(data) return tostring(data) end,
        decode = function(str) return {} end,
    }
end

-- Initialize the config table
---@param mod table
---@return table
function MagicConch_Config.Init(mod)
    mod.Config = {}
    for k, v in pairs(DefaultConfig) do
        if mod.Config[k] == nil then
            mod.Config[k] = v
        end
    end
    mod.Config.Version = VERSION
    return mod.Config
end

-- Load the config
---@param mod table
---@return boolean
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

-- Save the config
function MagicConch_Config.Save(mod)
    Isaac.SaveModData(mod, json.encode(mod.Config))
end

-- Reset the config
function MagicConch_Config.Reset(mod)
    for k, v in pairs(DefaultConfig) do
        mod.Config[k] = v
    end
    MagicConch_Config.Save(mod)
end

---@type MagicConchConfig
return MagicConch_Config