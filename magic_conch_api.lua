-- ========================================
-- Magic Conch API Module
-- Provides interface for other mods to interact with Magic Conch
-- ========================================

local MagicConch_API = {}

-- Internal references (will be set by core module)
local MagicConch = nil
local gameState = nil
local getTiming = nil
local MagicConch_Lang = nil
local MagicConch_Config = nil

-- Initialize API with references from core module
function MagicConch_API.Init(magicConchMod, gameStateRef, getTimingFunc, langModule, configModule)
    MagicConch = magicConchMod
    gameState = gameStateRef
    getTiming = getTimingFunc
    MagicConch_Lang = langModule
    MagicConch_Config = configModule
end

-- Check if Magic Conch is available
local function isAvailable()
    return gameState.canInput and gameState.state == "idle" and MagicConch.Config.enabled
end

-- Execute Magic Conch sequence (shared between hotkey and API trigger)
-- @param triggerSource string - Source of trigger (e.g., "hotkey", "API: ModName")
-- @return boolean - Success or failure
local function executeMagicConchSequence(triggerSource)
    local currentTime = Game():GetFrameCount()
    
    -- Spam protection
    if currentTime - gameState.lastInputTime < 10 then 
        MagicConch.printDebug("Spam protection triggered (" .. triggerSource .. ")")
        return false
    end
    
    gameState.lastInputTime = currentTime
    gameState.canInput = false
    
    -- Get random answer
    local randomData = MagicConch_Lang.getRandomString(MagicConch.Config)
    if not randomData then
        MagicConch.printError("Failed to get random string")
        gameState.canInput = true
        return false
    end
    
    -- Set pending data
    gameState.pendingText = randomData.text
    gameState.pendingType = randomData.type
    
    -- Start sequence with slot machine sound and Magic Conch holding animation
    local sfxManager = SFXManager()
    sfxManager:Play(SoundEffect.SOUND_COIN_SLOT)
    Game():ShakeScreen(5)
    
    -- Show Magic Conch holding animation with custom sprite
    local player = Isaac.GetPlayer(0)
    if player then
        -- Create custom sprite for Magic Conch using Isaac's basic collectible
        local sprite = Sprite()
        
        -- Try the most basic approach - use Isaac's default collectible animation
        local loadSuccess = pcall(function()
            sprite:Load("gfx/005.100_collectible.anm2", true)
            sprite:ReplaceSpritesheet(1, "gfx/MagicConch.png")
            sprite:LoadGraphics()
            sprite:SetFrame("Idle", 0)
            sprite:Update()
        end)
        
        if not loadSuccess then
            -- Ultimate fallback - empty sprite
            sprite = Sprite()
            if MagicConch.Config.debugMode then
                MagicConch.printDebug("Using empty sprite as fallback")
            end
        else
            if MagicConch.Config.debugMode then
                MagicConch.printDebug("Successfully loaded Isaac collectible with Magic Conch texture")
            end
        end
        
        -- Animate holding the Magic Conch
        player:AnimatePickup(sprite, false, "Pickup")
        
        if MagicConch.Config.debugMode then
            MagicConch.printDebug("Magic Conch pickup animation started")
        end
    end
    
    gameState.state = "shaking"
    gameState.timer = 0
    
    if MagicConch.Config.debugMode then
        MagicConch.printDebug("Started Magic Conch sequence (" .. triggerSource .. "): " .. gameState.pendingText)
    end
    
    return true
end

-- Execute callback function (internal use)
local function executeCallbacks(result)
    for i, callbackData in ipairs(gameState.callbacks) do
        local ok, err = pcall(callbackData.func, result)
        if not ok then
            MagicConch.printError("Callback error for " .. callbackData.modName .. ": " .. tostring(err))
        end
    end
end

-- ===== Public API Functions =====

-- Register callback to receive Magic Conch results from other mods
-- @param callback function(result) - Function to receive the result
-- @param modName string - Mod name (optional)
-- @return boolean - Success or failure
--
-- Output/Debug Messages:
-- - Success: "Callback registered for: [modName]" (debug log)
-- - Error: "RegisterCallback: callback must be a function" (error log)
function MagicConch_API.RegisterCallback(callback, modName)
    if type(callback) ~= "function" then
        MagicConch.printError("RegisterCallback: callback must be a function")
        return false
    end
    
    local callbackData = {
        func = callback,
        modName = modName,
        registeredTime = Game():GetFrameCount()
    }
    
    table.insert(gameState.callbacks, callbackData)
    MagicConch.printDebug("Callback registered for: " .. callbackData.modName)
    return true
end

-- Trigger Magic Conch (programming style)
-- @param modName string - Mod name that called this function
-- @return table - Result information
function MagicConch_API.TriggerMagicConch(modName)
    local result = {
        success = false,
        reason = "",
        estimatedTime = 0,
        pendingResult = nil
    }
    
    if not isAvailable() then
        if not MagicConch.Config.enabled then
            result.reason = "Magic Conch is disabled"
        elseif gameState.state ~= "idle" then
            result.reason = "Magic Conch is busy (state: " .. gameState.state .. ")"
            -- Calculate remaining time until completion
            local timing = getTiming()
            if gameState.state == "shaking" then
                result.estimatedTime = timing.shake - gameState.timer + timing.wait + timing.display
            elseif gameState.state == "waiting" then
                result.estimatedTime = timing.wait - gameState.timer + timing.display
            elseif gameState.state == "displaying" then
                result.estimatedTime = timing.display - gameState.timer
            elseif gameState.state == "cooldown" then
                result.estimatedTime = timing.cooldown - gameState.timer
            end
        else
            result.reason = "Magic Conch is not ready"
        end
        
        MagicConch.printDebug("TriggerMagicConch failed: " .. result.reason .. " (called by " .. (modName) .. ")")
        return result
    end
    
    -- Execute Magic Conch
    local triggerSource = "API: " .. (modName)
    local executeSuccess = executeMagicConchSequence(triggerSource)
    
    if not executeSuccess then
        result.reason = "Failed to execute Magic Conch sequence"
        return result
    end
    
    -- Set success information
    result.success = true
    result.reason = "Magic Conch activated successfully"
    local timing = getTiming()
    result.estimatedTime = timing.shake + timing.wait + timing.display
    result.pendingResult = {
        text = randomData.text,
        type = randomData.type,
        willDisplayIn = timing.shake + timing.wait
    }
    
    MagicConch.printDebug("Magic Conch triggered by: " .. (modName))
    return result
end

-- Execute registered callbacks (called by core module)
function MagicConch_API.ExecuteCallbacks(result)
    executeCallbacks(result)
end

-- Execute Magic Conch sequence (called by core module for hotkey)
function MagicConch_API.ExecuteMagicConchSequence(triggerSource)
    return executeMagicConchSequence(triggerSource)
end

-- Create public API interface
function MagicConch_API.CreateInterface()
    return {
        -- Register callback: Allow other mods to receive Magic Conch results
        -- Input: callback (function), modName (string, optional)
        -- Output: boolean (success or failure)
        RegisterCallback = function(callback, modName) 
            return MagicConch_API.RegisterCallback(callback, modName) 
        end,
        
        -- Trigger Magic Conch: Execute Magic Conch programmatically
        -- Input: modName (string, optional)
        -- Output: table { success, reason, estimatedTime, pendingResult }
        TriggerMagicConch = function(modName) 
            return MagicConch_API.TriggerMagicConch(modName) 
        end,
        
        -- Version information
        Version = MagicConch_Config and MagicConch_Config.VERSION,
        
        -- Config information (read-only)
        Config = MagicConch.Config
    }
end

return MagicConch_API