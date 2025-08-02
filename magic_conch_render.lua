local MagicConch_Render = {}

local function renderLine(text, x, y, r, g, b)
    Isaac.RenderText(text, x, y, r, g, b, 1)
end

function MagicConch_Render:Render(mod, displayText, displayTimer, MagicConch_Lang, fontObj)
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