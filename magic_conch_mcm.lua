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

    -- Delete Mode
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function() return mod.Config.deleteMode end,
        Display = function() return "Delete Mode: " .. (mod.Config.deleteMode and "ON" or "OFF") end,
        Info = {"Delete items/pickups when receiving negative answers."},
        OnChange = function(b) 
            mod.Config.deleteMode = b
            if mod.Config.debugMode then
                Isaac.ConsoleOutput("Delete Mode Changed to: " .. tostring(b))
            end
        end,
    })

    -- Attempts per Room
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.attemptsPerRoom end,
        Minimum = 0,
        Maximum = 10,
        Display = function() 
            local attempts = mod.Config.attemptsPerRoom
            if attempts == 0 then
                return "Attempts per Room: Unlimited"
            else
                return "Attempts per Room: " .. tostring(attempts)
            end
        end,
        OnChange = function(n) 
            mod.Config.attemptsPerRoom = n 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Number of times you can use Magic Conch per room.", "Set to 0 for unlimited usage."},
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
            MagicConch_Config.Save(mod)
        end,
        Info = {"Select the output language. (Default: Auto)"},
    })

    -- Forced Reply Mode (0: None, 1: Positive, 2: Neutral, 3: Negative)
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            local map = { None = 0, Positive = 1, Neutral = 2, Negative = 3 }
            local v = mod.Config.forcedReply or "None"
            return map[v] or 0
        end,
        Minimum = 0,
        Maximum = 3,
        Display = function()
            local names = { [0] = "None", [1] = "Positive", [2] = "Neutral", [3] = "Negative" }
            local idx = 0
            local map = { None = 0, Positive = 1, Neutral = 2, Negative = 3 }
            if mod.Config.forcedReply and map[mod.Config.forcedReply] ~= nil then
                idx = map[mod.Config.forcedReply]
            end
            return "Forced Reply: " .. names[idx]
        end,
        OnChange = function(n)
            local names = { [0] = "None", [1] = "Positive", [2] = "Neutral", [3] = "Negative" }
            mod.Config.forcedReply = names[n] or "None"
            MagicConch_Config.Save(mod)
        end,
        Info = {"Force the reply type.", "None: Random as usual", "Positive/Neutral/Negative: Always output selected type."},
    })

    -- Key Binding (including Popup)
    ModConfigMenu.AddSetting(category, "General", {
        Type = ModConfigMenu.OptionType.KEYBIND_KEYBOARD,
        CurrentSetting = function() return mod.Config.hotkey end,
        Display = function()
            local key = "None"
            if mod.Config.hotkey > -1 then
                if InputHelper and InputHelper.KeyboardToString[mod.Config.hotkey] then
                    key = InputHelper.KeyboardToString[mod.Config.hotkey]
                else
                    local MagicConch_Render = include("magic_conch_render")
                    key = MagicConch_Render:HotkeyToString(mod.Config.hotkey)
                end
            end
            return "Hotkey: " .. key
        end,
        OnChange = function(newKey)
            if newKey == -1 then
                return
            end
            mod.Config.hotkey = newKey
            MagicConch_Config.Save(mod)
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

    -- Probabilities Category
    ModConfigMenu.AddSpace(category, "Probabilities")
    ModConfigMenu.AddText(category, "Probabilities", "--- Probability Settings ---")

    -- Helper function to calculate Neutral based on Pos/Neg
    local function updateNeutral(mod)
        if not mod.Config.chances then
            mod.Config.chances = { positive = 40, neutral = 20, negative = 40 }
        end
        
        local pos = mod.Config.chances.positive
        local neg = mod.Config.chances.negative
        
        -- Calculate Neutral
        local neu = 100 - pos - neg
        -- Safety clamp
        if neu < 0 then neu = 0 end
        
        mod.Config.chances.neutral = neu
    end

    -- Positive Chance
    ModConfigMenu.AddSetting(category, "Probabilities", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.chances.positive end,
        Minimum = 0,
        Maximum = 100,
        Display = function() 
            return "Positive Chance: " .. mod.Config.chances.positive .. "%" 
        end,
        OnChange = function(n)
            mod.Config.chances.positive = n
            
            -- If Pos + Neg > 100, decrease Neg
            local neg = mod.Config.chances.negative
            if n + neg > 100 then
                mod.Config.chances.negative = 100 - n
            end
            
            updateNeutral(mod)
            MagicConch_Config.Save(mod)
        end,
        Info = {"Probability of getting a Positive answer."},
    })

    -- Negative Chance (Now Adjustable)
    ModConfigMenu.AddSetting(category, "Probabilities", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.chances.negative end,
        Minimum = 0,
        Maximum = 100,
        Display = function() 
            return "Negative Chance: " .. mod.Config.chances.negative .. "%" 
        end,
        OnChange = function(n)
            mod.Config.chances.negative = n
            
            -- If Pos + Neg > 100, decrease Pos
            local pos = mod.Config.chances.positive
            if pos + n > 100 then
                mod.Config.chances.positive = 100 - n
            end
            
            updateNeutral(mod)
            MagicConch_Config.Save(mod)
        end,
        Info = {"Probability of getting a Negative answer."},
    })

    -- Neutral Chance (Read Only, Calculated)
    ModConfigMenu.AddSetting(category, "Probabilities", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.chances.neutral end,
        Minimum = 0,
        Maximum = 100,
        Display = function() 
            return "Neutral Chance: " .. mod.Config.chances.neutral .. "%" 
        end,
        OnChange = function(n)
            -- Read only, revert changes
            updateNeutral(mod)
        end,
        Info = {"Probability of getting a Neutral answer.", "Calculated automatically: 100 - Positive - Negative"},
    })
    
    -- Timing Category
    ModConfigMenu.AddSpace(category, "Timing")
    ModConfigMenu.AddText(category, "Timing", "--- Timing Settings ---")
    
    -- Shake Duration
    ModConfigMenu.AddSetting(category, "Timing", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return math.floor(mod.Config.timing.shake / 5) end,
        Minimum = 1,
        Maximum = 12,
        ModifyBy = 1,
        Display = function()
            local frames = mod.Config.timing.shake
            local seconds = math.floor(frames / 30 * 10) / 10
            return "Screen Shake: " .. frames .. " frames (" .. seconds .. "s)"
        end,
        OnChange = function(n) 
            mod.Config.timing.shake = n * 5 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Duration of screen shake effect when activated.", "Adjusts in 5 frame increments."},
    })
    
    -- Wait Duration
    ModConfigMenu.AddSetting(category, "Timing", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return math.floor(mod.Config.timing.wait / 5) end,
        Minimum = 1,
        Maximum = 36,
        ModifyBy = 1,
        Display = function()
            local frames = mod.Config.timing.wait
            local seconds = math.floor(frames / 30 * 10) / 10
            return "Wait Time: " .. frames .. " frames (" .. seconds .. "s)"
        end,
        OnChange = function(n) 
            mod.Config.timing.wait = n * 5 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Time to wait before showing the answer text.", "Adjusts in 5 frame increments."},
    })
    
    -- Display Duration
    ModConfigMenu.AddSetting(category, "Timing", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return math.floor(mod.Config.timing.display / 5) end,
        Minimum = 6,
        Maximum = 60,
        ModifyBy = 1,
        Display = function()
            local frames = mod.Config.timing.display
            local seconds = math.floor(frames / 30 * 10) / 10
            return "Display Time: " .. frames .. " frames (" .. seconds .. "s)"
        end,
        OnChange = function(n) 
            mod.Config.timing.display = n * 5 
            MagicConch_Config.Save(mod)
        end,
        Info = {"How long the answer text stays visible.", "Adjusts in 5 frame increments."},
    })
    
    -- Cooldown Duration
    ModConfigMenu.AddSetting(category, "Timing", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return math.floor(mod.Config.timing.cooldown / 5) end,
        Minimum = 0,
        Maximum = 36,
        ModifyBy = 1,
        Display = function()
            local frames = mod.Config.timing.cooldown
            if frames == 0 then
                return "Cooldown: None"
            else
                local seconds = math.floor(frames / 30 * 10) / 10
                return "Cooldown: " .. frames .. " frames (" .. seconds .. "s)"
            end
        end,
        OnChange = function(n) 
            mod.Config.timing.cooldown = n * 5 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Cooldown time before you can use Magic Conch again.", "Set to 0 for no cooldown.", "Adjusts in 5 frame increments."},
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
            local t = {"Fortune Machine Style", "Item-like Style"}
            return "Display Style: " .. t[(mod.Config.displayStyle) + 1]
        end,
        OnChange = function(n) 
            mod.Config.displayStyle = n 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Fortune Machine: Shows text like fortune teller machine", "Item-like: Shows main text with type subtitle like item pickup"},
    })

    -- Icon Position (X)
    ModConfigMenu.AddSetting(category, "Display", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.iconX end,
        Minimum = 0,
        Maximum = 800,
        ModifyBy = 5,
        Display = function()
            return "Icon X: " .. tostring(mod.Config.iconX)
        end,
        OnChange = function(n)
            mod.Config.iconX = n
            MagicConch_Config.Save(mod)
        end,
        Info = {"Set the X position of the Magic Conch icon.", "Text position follows icon X automatically."},
    })

    -- Icon Position (Y)
    ModConfigMenu.AddSetting(category, "Display", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.iconY end,
        Minimum = 0,
        Maximum = 450,
        ModifyBy = 5,
        Display = function()
            return "Icon Y: " .. tostring(mod.Config.iconY)
        end,
        OnChange = function(n)
            mod.Config.iconY = n
            MagicConch_Config.Save(mod)
        end,
        Info = {"Set the Y position of the Magic Conch icon.", "Text position is offset from the icon and does not need a separate setting."},
    })

    -- Debug Category
    ModConfigMenu.AddSpace(category, "Debug")
    ModConfigMenu.AddText(category, "Debug", "--- Debug Info ---")
    ModConfigMenu.AddSetting(category, "Debug", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function() return mod.Config.debugMode end,
        Display = function() return "Debug Mode: " .. (mod.Config.debugMode and "ON" or "OFF") end,
        OnChange = function(b) 
            mod.Config.debugMode = b 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Enable debug output for font loading and rendering."},
    })
    ModConfigMenu.AddSetting(category, "Debug", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.debugHudX end,
        Minimum = 0,
        Maximum = 800,
        Display = function() return "Debug HUD X: " .. tostring(mod.Config.debugHudX) end,
        OnChange = function(n) 
            mod.Config.debugHudX = n 
            MagicConch_Config.Save(mod)
        end,
        Info = {"Set the X position of the debug HUD."},
    })
    ModConfigMenu.AddSetting(category, "Debug", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function() return mod.Config.debugHudY end,
        Minimum = 0,
        Maximum = 450,
        Display = function() return "Debug HUD Y: " .. tostring(mod.Config.debugHudY) end,
        OnChange = function(n) 
            mod.Config.debugHudY = n 
            MagicConch_Config.Save(mod)
        end,
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