local MagicConch_MCM = {}

function MagicConch_MCM.Setup(mod, MagicConch_Lang, MagicConch_Config)
    if not ModConfigMenu then return end
    local category = "Magic Conch v" .. mod.Config.Version
    ModConfigMenu.RemoveCategory(category)

    ModConfigMenu.AddSpace(category, "General")
    ModConfigMenu.AddText(category, "General", "--- Magic Conch Options ---")

    -- Mode Enabled
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function() return mod.Config.enabled end,
        Display = function() return "Mode Enabled: " .. (mod.Config.enabled and "ON" or "OFF") end,
        Info = {"Enable Magic Conch mode."},
        OnChange = function(b) mod.Config.enabled = b end,
    })

    -- Resolute Mode
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function() return mod.Config.resoluteMode end,
        Display = function() return "Resolute Mode: " .. (mod.Config.resoluteMode and "ON" or "OFF") end,
        Info = {"Delete items/pickups when receiving negative answers."},
        OnChange = function(b) mod.Config.resoluteMode = b end,
    })

    -- Language Selection (0:Auto, 1:EN, 2:KR ...)
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            local lang = mod.Config.language
            for i, langObj in ipairs(MagicConch_Lang.LANGUAGE_MAP) do
                if lang == langObj.code then
                    return i
                end
            end
            return 0 -- 0: Auto
        end,
        Minimum = 0,
        Maximum = #MagicConch_Lang.LANGUAGE_MAP,
        Display = function()
            local idx = 0
            local lang = mod.Config.language
            for i, langObj in ipairs(MagicConch_Lang.LANGUAGE_MAP) do
                if lang == langObj.code then
                    idx = i
                    break
                end
            end
            if idx == 0 then
                local langTable = MagicConch_Lang.getLanguageTable(mod.Config)
                return "Language: Auto(" .. langTable.name .. ")"
            else
                return "Language: " .. MagicConch_Lang.LANGUAGE_MAP[idx].name
            end
        end,
        OnChange = function(n)
            if n == 0 then
                mod.Config.language = "Auto"
            else
                mod.Config.language = MagicConch_Lang.LANGUAGE_MAP[n].code
            end
            -- Reload font when language changes
            mod:ReloadFont()
        end,
        Info = {"Select the output language. (Default: Auto)"},
    })

    -- Key Binding (including Popup)
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
        CurrentSetting = function() return mod.Config.hotkey end,
        Display = function()
            local key = "None"
            if InputHelper and InputHelper.KeyboardToString[mod.Config.hotkey] then
                key = InputHelper.KeyboardToString[mod.Config.hotkey]
            end
            return "Hotkey: " .. key
        end,
        OnChange = function(newKey)
            mod.Config.hotkey = newKey
        end,
        PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL,
        PopupWidth = 280,
        Popup = function()
            local currentValue = mod.Config.hotkey
            local keepSettingString = ""
            if currentValue and currentValue > -1 and InputHelper and InputHelper.KeyboardToString[currentValue] then
                local currentSettingString = InputHelper.KeyboardToString[currentValue]
                keepSettingString =
                    'This setting is currently set to "' ..
                    currentSettingString .. '.$newlinePress this button to keep it unchanged.$newline$newline'
            end
            return "Press a button on your keyboard to change this setting.$newline$newline" ..
                keepSettingString .. "Press ESCAPE to go back and clear this setting."
        end,
        Info = {"Press a button on your keyboard to change this setting."},
    })

    -- Display Category
    ModConfigMenu.AddSpace(category, "Display")
    ModConfigMenu.AddText(category, "Display", "--- Display Options ---")
    ModConfigMenu.AddSetting(category, "Display", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.displayStyle end,
        Minimum = 0,
        Maximum = 1,
        Display = function()
            local t = {"Fortune Machine Text", "Rule-Style"}
            return "Display Style: " .. t[(mod.Config.displayStyle) + 1]
        end,
        OnChange = function(n) mod.Config.displayStyle = n end,
        Info = {"Choose how to display the answer text."},
    })

    -- Debug Category
    ModConfigMenu.AddSpace(category, "Debug")
    ModConfigMenu.AddText(category, "Debug", "--- Debug Info ---")
    ModConfigMenu.AddSetting(category, "Debug", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function() return mod.Config.debugMode end,
        Display = function() return "Debug Mode: " .. (mod.Config.debugMode and "ON" or "OFF") end,
        OnChange = function(b) mod.Config.debugMode = b end,
        Info = {"Enable debug output for font loading and rendering."},
    })
    ModConfigMenu.AddSetting(category, "Debug", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.debugHudX end,
        Minimum = 0,
        Maximum = 800,
        Display = function() return "Debug HUD X: " .. tostring(mod.Config.debugHudX) end,
        OnChange = function(n) mod.Config.debugHudX = n end,
        Info = {"Set the X position of the debug HUD."},
    })
    ModConfigMenu.AddSetting(category, "Debug", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.debugHudY end,
        Minimum = 0,
        Maximum = 450,
        Display = function() return "Debug HUD Y: " .. tostring(mod.Config.debugHudY) end,
        OnChange = function(n) mod.Config.debugHudY = n end,
        Info = {"Set the Y position of the debug HUD."},
    })

    -- Reset Button
    ModConfigMenu.AddSpace(category, "General")
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function() return false end,
        Display = function() return "Reset Settings" end,
        OnChange = function(b)
            if b then
                MagicConch_Config.Reset(mod)
                return false
            end
        end,
        Info = {"Reset settings to default values."},
    })
end

return MagicConch_MCM 