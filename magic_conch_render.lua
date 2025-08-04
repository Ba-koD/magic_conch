local MagicConch_Render = {}

-- Magic Conch icon sprite (initialized like hit counter mod)
local conchSprite = Sprite()
local spriteLoaded = false

local function renderLine(text, x, y, r, g, b)
    Isaac.RenderText(text, x, y, r, g, b, 1)
end

-- Initialize sprite loading (similar to hit counter mod)
local function initSprite()
    if not spriteLoaded then
        -- Try to load a basic collectible sprite and replace with our texture
        local success = pcall(function()
            conchSprite:Load("gfx/005.100_collectible.anm2", true)
            conchSprite:ReplaceSpritesheet(1, "gfx/MagicConch.png")
            conchSprite:LoadGraphics()
            conchSprite:SetFrame("Idle", 0)
            conchSprite.Color = Color(1, 1, 1, 0.8) -- Slightly transparent like hit counter
        end)
        
        if success then
            spriteLoaded = true
        end
    end
end

-- Render room attempts counter
function MagicConch_Render:RenderRoomAttempts(mod)
    if not mod or not mod.Config then return end
    
    -- Initialize sprite if not done yet
    initSprite()
    
    -- Get usage data
    local currentUsage = 0
    local maxAttempts = mod.Config.attemptsPerRoom or 0
    
    -- Try to get usage count from mod's gameState if available
    if mod.GetCurrentRoomUsage then
        local success, usage = pcall(function() return mod.GetCurrentRoomUsage() end)
        if success then
            currentUsage = usage or 0
        end
    end
    
    -- Hardcoded position as requested
    local iconX = 430
    local iconY = 265
    local textX = iconX + 10
    local textY = iconY - 17
    
    -- Render Magic Conch icon (like hit counter mod)
    if spriteLoaded and conchSprite:IsLoaded() then
        conchSprite.Scale = Vector(0.5, 0.5) -- Scale down to reasonable size
        conchSprite:Render(Vector(iconX, iconY))
    end
    
    -- Create usage text with faded color (dim gray)
    local usageText
    if maxAttempts == 0 then
        -- Unlimited usage - show infinity as text
        usageText = tostring(currentUsage) .. "/INF"
    else
        usageText = tostring(currentUsage) .. "/" .. tostring(maxAttempts)
    end
    
    -- Render text with faded color (R=0.6, G=0.6, B=0.6 for dimmed appearance)
    Isaac.RenderText(usageText, textX, textY, 0.6, 0.6, 0.6, 1)
end

function MagicConch_Render:Render(mod, displayText, displayTimer, MagicConch_Lang, fontObj)
    -- Always render room attempts counter (as requested - no toggle option)
    self:RenderRoomAttempts(mod)
    
    if mod and mod.Config and mod.Config.debugMode then
        local x = mod.Config.debugHudX
        local y = mod.Config.debugHudY
        local lineH = 18
        renderLine("=== MagicConch Debug ===", x, y, 255, 255, 0); y = y + lineH
        renderLine("Enabled: " .. tostring(mod.Config.enabled), x, y, 1, 1, 1); y = y + lineH
        renderLine("DisplayStyle: " .. tostring(mod.Config.displayStyle), x, y, 1, 1, 1); y = y + lineH
        renderLine("Hotkey: " .. tostring(self:HotkeyToString(mod.Config.hotkey)), x, y, 1, 1, 1); y = y + lineH
        renderLine("displayText: " .. tostring(displayText), x, y, 1, 1, 1); y = y + lineH
        renderLine("displayTimer: " .. tostring(displayTimer), x, y, 1, 1, 1); y = y + lineH
        renderLine("Language: " .. tostring(MagicConch_Lang.getLanguageTable(mod.Config).name), x, y, 1, 1, 1); y = y + lineH
        renderLine("Options.Language: " .. tostring(Options.Language), x, y, 1, 1, 1); y = y + lineH
        renderLine("fontObj.fontPath: " .. tostring(fontObj.fontPath), x, y, 1, 1, 1); y = y + lineH
    end
end

local KeyboardToString = {}
if Keyboard then
    for key, num in pairs(Keyboard) do
        local keyString = key
        local _, keyEnd = string.find(keyString, "KEY_")
        keyString = string.sub(keyString, (keyEnd) + 1)
        keyString = string.gsub(keyString, "_", " ")
        KeyboardToString[num] = keyString
    end
end

function MagicConch_Render:HotkeyToString(hotkey)
    if KeyboardToString[hotkey] then
        return KeyboardToString[hotkey]
    end
    return tostring(hotkey)
end

return MagicConch_Render