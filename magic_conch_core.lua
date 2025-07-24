---@class MagicConch
local MagicConch_Config = include("magic_conch_config")
local MagicConch_Lang = include("magic_conch_lang")
local MagicConch_MCM = include("magic_conch_mcm")
local MagicConch_Render = include("magic_conch_render")

MagicConch = RegisterMod("Magic Conch", 1)
MagicConch_Config.Init(MagicConch)

MagicConch.printDebug = function(text)
    Isaac.ConsoleOutput("[MagicConch][DEBUG] " .. tostring(text) .. "\n")
end

MagicConch.printError = function(text)
    Isaac.ConsoleOutput("[MagicConch][ERROR] " .. tostring(text) .. "\n")
end

MagicConch.print = function(text)
    Isaac.ConsoleOutput("[MagicConch] " .. tostring(text) .. "\n")
end

-- All callbacks, functions, and data are managed in core
local displayText = nil
local displayTimer = 0
local pendingDisplay = nil
local pendingTimer = 0
local DISPLAY_DURATION = 90 -- 3 seconds
local DISPLAY_DELAY = 60   -- 2 seconds

local game = Game() -- Game instance
local sfxManager = SFXManager() -- SFXManager instance
local fontObj = { font = Font(), fontPath = nil }

-- Load font for the current language
local function loadCurrentLanguageFont(config)
    local langTable = MagicConch_Lang.getLanguageTable(config)
    local fontPath = langTable.font
    if fontObj.font and fontObj.fontPath == fontPath then
        return fontObj
    end
    local ok, err = pcall(function() fontObj.font:Load(fontPath) end)
    if ok then
        fontObj.fontPath = fontPath
        MagicConch.printDebug("Font loaded: " .. tostring(fontPath))
        MagicConch.printDebug("Font path: " .. tostring(fontObj.fontPath))
        return fontObj
    else
        MagicConch.printDebug("Font load failed: " .. tostring(err))
        MagicConch.printDebug("Font path: " .. tostring(fontObj.fontPath))
        fontObj.font = nil
        fontObj.fontPath = nil
        return fontObj
    end
end

function MagicConch:OnHotkeyInput()
    if not MagicConch.Config.enabled then return end
    if displayTimer > 0 or pendingTimer > 0 then return end

    local input = Input.IsButtonTriggered(MagicConch.Config.hotkey, 0)
    if input then
        game:ShakeScreen(5)
        sfxManager:Play(SoundEffect.SOUND_FORTUNE_COOKIE, 1.0, 0, false, 1.0)
        pendingDisplay = MagicConch_Lang.getRandomString(MagicConch.Config).text
        pendingTimer = DISPLAY_DELAY
    end
end

function MagicConch:OnUpdate()
    if pendingTimer > 0 then
        pendingTimer = pendingTimer - 1
        if pendingTimer == 0 then
            displayText = pendingDisplay
            displayTimer = DISPLAY_DURATION
            pendingDisplay = nil
        end
    elseif displayTimer > 0 then
        displayTimer = displayTimer - 1
        if displayTimer == 0 then
            displayText = nil
        end
    end
end

function MagicConch:OnRender()
    MagicConch_Render:Render(MagicConch, displayText, displayTimer, MagicConch_Lang, fontObj, MagicConch.Config)
end

function MagicConch:OnGameStart(isSave)
    MagicConch_Config.Load(MagicConch)
    MagicConch_MCM.Setup(MagicConch, MagicConch_Lang, MagicConch_Config)
    MagicConch.print("Magic Conch v" .. MagicConch_Config.VERSION .. " loaded!")
    loadCurrentLanguageFont(MagicConch.Config)
end

function MagicConch:OnGameExit()
    MagicConch_Config.Save(MagicConch)
    MagicConch.print("Magic Conch v" .. MagicConch_Config.VERSION .. " settings saved.")
end

function MagicConch:ReloadFont()
    MagicConch.printDebug("ReloadFont called - Language: " .. tostring(MagicConch.Config.language))
    loadCurrentLanguageFont(MagicConch.Config)
    MagicConch.printDebug("ReloadFont completed - Font path: " .. tostring(fontObj.fontPath))
end

MagicConch:AddCallback(ModCallbacks.MC_POST_UPDATE, function() MagicConch:OnHotkeyInput() end)
MagicConch:AddCallback(ModCallbacks.MC_POST_UPDATE, function() MagicConch:OnUpdate() end)
MagicConch:AddCallback(ModCallbacks.MC_POST_RENDER, function() MagicConch:OnRender() end)
MagicConch:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MagicConch.OnGameStart)
MagicConch:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, MagicConch.OnGameExit)

return MagicConch