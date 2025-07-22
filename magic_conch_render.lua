local MagicConch_Render = {}

local game = Game()

local font = Font()
local fontLoaded = false
local currentFontPath = nil

-- 1. When the module is loaded (when the script is first executed)
local function tryLoadFont(fontPath)
    if fontLoaded and currentFontPath == fontPath then return end
    local ok, err = pcall(function() font:Load(fontPath) end)
    if ok then
        fontLoaded = true
        currentFontPath = fontPath
    else
        fontLoaded = false
        Isaac.ConsoleOutput("[MagicConch][DEBUG] Font load failed: " .. tostring(err) .. "\\n")
    end
end

-- Load the font only once at the initial loading point
tryLoadFont("resources/font/Kkubulim.fnt")

-- 2. Load the font again in the game start callback
function MagicConch_Render:OnGameStart()
    tryLoadFont("resources/font/Kkubulim.fnt")
end

if ModCallbacks and Mod then
    Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function() MagicConch_Render:OnGameStart() end)
end

local function renderLine(text, x, y, r, g, b)
    Isaac.RenderText(text, x, y, r or 1, g or 1, b or 1, 1)
end

local function RenderRuleStyleText(font, text, x, y, r, g, b, a, center)
    if not text then return end
    local str = tostring(text)
    local width = font:GetStringWidth(str)
    if center then
        x = x - (width / 2)
    end
    local screenW = Isaac.GetScreenWidth()
    local screenH = Isaac.GetScreenHeight()
    if (x + width) > screenW then
        x = x - ((x + width) - screenW)
    end
    if (y + 13) > screenH then
        y = y - ((y + 13) - screenH)
    end
    font:DrawStringUTF8(str, x, y, KColor(r, g, b, a), 0, true)
end

function MagicConch_Render:Render(mod, displayText, displayTimer, getCurrentLanguage)
    if mod and mod.Config and mod.Config.debugMode then
        local x = mod.Config.debugHudX or 60
        local y = mod.Config.debugHudY or 40
        local lineH = 18
        renderLine("=== MagicConch Debug ===", x, y, 255, 255, 0); y = y + lineH
        renderLine("Enabled: " .. tostring(mod.Config.enabled), x, y, 1, 1, 1); y = y + lineH
        renderLine("DisplayStyle: " .. tostring(mod.Config.displayStyle), x, y, 1, 1, 1); y = y + lineH
        renderLine("Hotkey: " .. tostring(self:HotkeyToString(mod.Config.hotkey)), x, y, 1, 1, 1); y = y + lineH
        renderLine("displayText: " .. tostring(displayText), x, y, 1, 1, 1); y = y + lineH
        renderLine("displayTimer: " .. tostring(displayTimer), x, y, 1, 1, 1); y = y + lineH
        renderLine("Language: " .. tostring(getCurrentLanguage()), x, y, 1, 1, 1); y = y + lineH
    end

    if fontLoaded and displayText then
        local screenW = Isaac.GetScreenWidth()
        local screenH = Isaac.GetScreenHeight()
        local x = screenW / 2
        local y = screenH - 60
        font:DrawStringUTF8(displayText, x, y, KColor(1,1,1,1), 0, true)
        -- 한글 테스트
        font:DrawStringUTF8("테스트: 한글출력", 100, 100, KColor(1,1,1,1), 0, false)
    end
end

local KeyboardToString = {}
if Keyboard then
    for key, num in pairs(Keyboard) do
        local keyString = key
        local _, keyEnd = string.find(keyString, "KEY_")
        keyString = string.sub(keyString, (keyEnd or 3) + 1)
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