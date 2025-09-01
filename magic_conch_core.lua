---@class MagicConch
local MagicConch_Config = include("magic_conch_config")
local MagicConch_Lang = include("magic_conch_lang")
local MagicConch_MCM = include("magic_conch_mcm")
local MagicConch_Render = include("magic_conch_render")
local MagicConch_API = include("magic_conch_api")

MagicConch = RegisterMod("Magic Conch", 1)
MagicConch_Config.Init(MagicConch)

MagicConch.printDebug = function(text)
    if MagicConch.Config.debugMode then
        Isaac.ConsoleOutput("[MagicConch][DEBUG] " .. tostring(text) .. "\n")
    end
end

MagicConch.printError = function(text)
    Isaac.ConsoleOutput("[MagicConch][ERROR] " .. tostring(text) .. "\n")
end

MagicConch.print = function(text)
    Isaac.ConsoleOutput("[MagicConch] " .. tostring(text) .. "\n")
end

-- API module will be initialized after game start

local fontObj = { font = Font(), fontPath = nil }

local gameState = {
    state = "idle", -- "idle", "shaking", "waiting", "displaying", "cooldown"
    timer = 0,
    lastInputTime = 0,
    canInput = true,
    pendingText = nil,
    pendingType = nil,
    -- API Fields
    lastResult = nil,
    lastResultTime = 0,
    callbacks = {},
    -- Room usage tracking
    -- { [roomKey] = { count = number, lastType = string|nil, lastResponse = string|nil } }
    roomUsageCount = {},
    currentRoomKey = nil
}

local function getTiming()
    return MagicConch.Config.timing
end

-- Get completely unique room key using Isaac's built-in unique identifiers
local function getCurrentRoomKey()
    local level = Game():GetLevel()
    local room = Game():GetRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    
    -- Use multiple unique identifiers to create absolutely unique key
    local decorationSeed = room:GetDecorationSeed()  -- Unique decoration seed for this room
    local spawnSeed = room:GetSpawnSeed()            -- Unique spawn seed for this room
    local roomIndex = level:GetCurrentRoomIndex()    -- Room index
    local stage = level:GetStage()                   -- Stage number
    local stageType = level:GetStageType()           -- Stage type
    
    -- Create absolutely unique key using seeds
    return tostring(stage) .. "_" .. tostring(stageType) .. "_" .. tostring(roomIndex) .. "_" .. tostring(decorationSeed) .. "_" .. tostring(spawnSeed)
end

-- Get current room usage count
local function getCurrentRoomUsage()
    local roomKey = getCurrentRoomKey()
    local entry = gameState.roomUsageCount[roomKey]
    if type(entry) == "table" then
        return entry.count or 0
    end
    -- Backward compatibility if a plain number was stored previously
    return entry or 0
end

-- Get current room last result type (if any)
local function getCurrentRoomLastType()
    local roomKey = getCurrentRoomKey()
    local entry = gameState.roomUsageCount[roomKey]
    if type(entry) == "table" then
        return entry.lastType
    end
    return nil
end

-- Get current room last response text (if any)
local function getCurrentRoomLastResponse()
    local roomKey = getCurrentRoomKey()
    local entry = gameState.roomUsageCount[roomKey]
    if type(entry) == "table" then
        return entry.lastResponse
    end
    return nil
end

-- Check if we can use Magic Conch in current room
local function canUseMagicConchInRoom()
    local maxAttempts = MagicConch.Config.attemptsPerRoom
    -- 0 means unlimited usage
    if maxAttempts == 0 then
        return true
    end
    local currentUsage = getCurrentRoomUsage()
    return currentUsage < maxAttempts
end

-- Increment room usage count
local function incrementRoomUsage()
    local roomKey = getCurrentRoomKey()
    local entry = gameState.roomUsageCount[roomKey]
    if type(entry) ~= "table" then
        entry = { count = tonumber(entry) or 0, lastType = nil }
    end
    entry.count = (entry.count or 0) + 1
    gameState.roomUsageCount[roomKey] = entry
    gameState.currentRoomKey = roomKey
end

-- Remove all pickups and items in the current room (Delete Mode)
local function removeAllPickupsAndItems()
    local room = Game():GetRoom()
    local removedCount = 0
    
    -- Remove all pickups (coins, keys, bombs, hearts, cards, etc.)
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        local entityType = entity.Type
        
        -- Remove pickups
        if entityType == EntityType.ENTITY_PICKUP then
            entity:Remove()
            removedCount = removedCount + 1
        -- Remove collectible items
        elseif entityType == EntityType.ENTITY_COLLECTIBLE then
            entity:Remove()
            removedCount = removedCount + 1
        -- Remove slot machines, beggars, etc.
        elseif entityType == EntityType.ENTITY_SLOT then
            entity:Remove()
            removedCount = removedCount + 1
        -- Remove shop items
        elseif entityType == EntityType.ENTITY_SHOPKEEPER then
            entity:Remove()
            removedCount = removedCount + 1
        end
    end
    
    -- Remove special grid entities (poop with items, etc.)
    for i = 0, room:GetGridSize() - 1 do
        local gridEntity = room:GetGridEntity(i)
        if gridEntity then
            local gridType = gridEntity:GetType()
            -- Remove grid entities that might contain items
            if gridType == GridEntityType.GRID_POOP or 
               gridType == GridEntityType.GRID_TNT or
               gridType == GridEntityType.GRID_FIREPLACE then
                gridEntity:Destroy(true)
                removedCount = removedCount + 1
            end
        end
    end
    
    return removedCount
end

-- Load font for the current language
local function loadCurrentLanguageFont(config)
    local langTable = MagicConch_Lang.getLanguageTable(config)
    local fontPath = langTable.font
    
    -- Exception handling if font is nil
    if fontPath == nil then
        fontObj.font = nil
        fontObj.fontPath = nil
        return fontObj
    end
    
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

local function resetGameState()
    gameState.state = "idle"
    gameState.timer = 0
    gameState.canInput = true
    gameState.pendingText = nil
    gameState.pendingType = nil
    gameState.lastInputTime = 0
end

-- Reset room usage count (for new games and new levels)
local function resetRoomUsageCount()
    gameState.roomUsageCount = {}
    gameState.currentRoomKey = nil
    if MagicConch.Config.debugMode then
        MagicConch.printDebug("Room usage count reset")
    end
end

local stateHandlers = {
    idle = function()
    end,
    
    shaking = function()
        local timing = getTiming()
        gameState.timer = gameState.timer + 1
        
        if gameState.timer >= timing.shake then
            gameState.state = "waiting"
            gameState.timer = 0
        end
    end,
    
    waiting = function()
        local timing = getTiming()
        gameState.timer = gameState.timer + 1
        
        if gameState.timer >= timing.wait then
            local hud = Game():GetHUD()
            if gameState.pendingText and gameState.pendingType then
                -- Display text
                if MagicConch.Config.displayStyle == 0 then
                    hud:ShowFortuneText(gameState.pendingText)
                else
                    local typeText = "[" .. gameState.pendingType .. "]"
                    hud:ShowItemText(gameState.pendingText, typeText)
                end
                
                -- Save result and execute callback
                local result = {
                    text = gameState.pendingText,
                    type = gameState.pendingType,
                    timestamp = Game():GetFrameCount(),
                    displayStyle = MagicConch.Config.displayStyle
                }
                gameState.lastResult = result
                gameState.lastResultTime = result.timestamp
                -- Update per-room lastType when result is finalized
                do
                    local roomKey = gameState.currentRoomKey or getCurrentRoomKey()
                    local entry = gameState.roomUsageCount[roomKey]
                    if type(entry) ~= "table" then
                        entry = { count = tonumber(entry) or 0, lastType = nil }
                    end
                    entry.lastType = result.type
                    entry.lastResponse = result.text
                    gameState.roomUsageCount[roomKey] = entry
                end
                
                -- Execute registered callbacks
                if MagicConch.Config.debugMode then
                    MagicConch.printDebug("About to execute callbacks with result: " .. result.text .. " (" .. result.type .. ")")
                end
                MagicConch_API.ExecuteCallbacks(result)
                
                -- Type-based effects
                local player = Isaac.GetPlayer(0)
                if player then
                    if gameState.pendingType == "negative" then
                        -- Isaac makes disgusted face and sound (like bad pills)
                        -- Show sad/disgusted face animation
                        player:AnimateSad()
                        -- Add brief screen shake for emphasis
                        Game():ShakeScreen(3)
                        
                        if MagicConch.Config.debugMode then
                            MagicConch.printDebug("Negative result: Applied Isaac disgusted effects")
                        end
                        
                        -- Delete Mode: Remove pickups and items if enabled
                        if MagicConch.Config.deleteMode then
                            local removedCount = removeAllPickupsAndItems()
                            if MagicConch.Config.debugMode then
                                MagicConch.printDebug("Delete Mode: Removed " .. removedCount .. " entities")
                            end
                        end
                        
                    elseif gameState.pendingType == "positive" then
                        -- Isaac shows happy face and angel room item sound
                        local sfxManager = SFXManager()
                        sfxManager:Play(SoundEffect.SOUND_HOLY)
                        player:AnimateHappy()
                        
                        if MagicConch.Config.debugMode then
                            MagicConch.printDebug("Positive result: Applied Isaac happy effects with angel sound")
                        end
                        
                    elseif gameState.pendingType == "neutral" then
                        -- Isaac makes a thoughtful "hmm" sound
                        local sfxManager = SFXManager()
                        sfxManager:Play(SoundEffect.SOUND_DERP)
                        
                        if MagicConch.Config.debugMode then
                            MagicConch.printDebug("Neutral result: Applied Isaac thoughtful sound")
                        end
                    end
                end
            end
            
            gameState.state = "displaying"
            gameState.timer = 0
            gameState.canInput = true  -- Allow new input during display
        end
    end,
    
    displaying = function()
        local timing = getTiming()
        gameState.timer = gameState.timer + 1
        
        if gameState.timer >= timing.display then
            gameState.state = "cooldown"
            gameState.timer = 0
        end
    end,
    
    cooldown = function()
        local timing = getTiming()
        gameState.timer = gameState.timer + 1
        
        -- If cooldown is 0, wait for at least 1 frame
        local minCooldown = math.max(timing.cooldown, 1)
        
        if gameState.timer >= minCooldown then
            gameState.state = "idle"
            gameState.timer = 0
            gameState.canInput = true
            gameState.pendingText = nil
            gameState.pendingType = nil
        end
    end
}

function MagicConch:OnHotkeyInput()
    if not MagicConch.Config.enabled then return end
    if not gameState.canInput then return end
    -- Allow input during idle or displaying states
    if gameState.state ~= "idle" and gameState.state ~= "displaying" then return end

    local input = Input.IsButtonTriggered(MagicConch.Config.hotkey, 0)
    if input then
        -- Check room usage limit only when key is pressed
        if not canUseMagicConchInRoom() then
            -- Play error buzz sound when limit is reached
            local sfxManager = SFXManager()
            sfxManager:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.5) -- Lower volume for feedback
            
            if MagicConch.Config.debugMode then
                local currentUsage = getCurrentRoomUsage()
                local maxAttempts = MagicConch.Config.attemptsPerRoom
                MagicConch.printDebug("Room usage limit reached: " .. currentUsage .. "/" .. maxAttempts .. " - Error sound played")
            end
            return
        end
        
        -- Additional safety check: check if state is usable
        if (gameState.state == "idle" or gameState.state == "displaying") and gameState.canInput then
            -- Execute Magic Conch sequence first
            local success = MagicConch_API.ExecuteMagicConchSequence("hotkey")
            
            -- Only increment room usage if execution was successful
            if success then
                incrementRoomUsage()
                if MagicConch.Config.debugMode then
                    local currentUsage = getCurrentRoomUsage()
                    local maxAttempts = MagicConch.Config.attemptsPerRoom
                    MagicConch.printDebug("Magic Conch executed successfully, usage: " .. currentUsage .. "/" .. maxAttempts)
                end
            else
                if MagicConch.Config.debugMode then
                    MagicConch.printDebug("Magic Conch execution failed, usage count unchanged")
                end
            end
        end
    end
end

function MagicConch:OnUpdate()
    local handler = stateHandlers[gameState.state]
    if handler then
        handler()
    end
end

function MagicConch:OnRender()
    -- Always render (for room attempts counter)
    MagicConch_Render:Render(MagicConch, nil, 0, MagicConch_Lang, fontObj)
end

-- ReloadFont
function MagicConch:ReloadFont()
    loadCurrentLanguageFont(self.Config)
end

-- Public function to get current room usage (for render module)
function MagicConch:GetCurrentRoomUsage()
    return getCurrentRoomUsage()
end

-- Public function to get current room last result type
function MagicConch:GetCurrentRoomLastType()
    return getCurrentRoomLastType()
end

-- Public function to expose current state (for render gating)
function MagicConch:GetState()
    return gameState.state
end

-- Public function to get current room last response text
function MagicConch:GetCurrentRoomLastResponse()
    return getCurrentRoomLastResponse()
end

function MagicConch:OnGameStart(isSave)
    MagicConch_Config.Load(MagicConch)
    -- Load runtime (persist across reloads), but reset for brand new runs
    local runtime = MagicConch_Config.LoadRuntime(MagicConch)
    if isSave then
        -- Continue existing run: restore roomUsageCount and currentRoomKey
        if type(runtime) == "table" then
            if type(runtime.roomUsageCount) == "table" then
                gameState.roomUsageCount = runtime.roomUsageCount
            end
            if type(runtime.currentRoomKey) == "string" then
                gameState.currentRoomKey = runtime.currentRoomKey
            end
        end
    else
        -- New run: ensure runtime is reset
        gameState.roomUsageCount = {}
        gameState.currentRoomKey = nil
        MagicConch_Config.SaveRuntime(MagicConch, { roomUsageCount = {}, currentRoomKey = nil })
    end
    MagicConch_MCM.Setup(MagicConch, MagicConch_Lang, MagicConch_Config)
    
    -- Initialize API module
    MagicConch_API.Init(MagicConch, gameState, getTiming, MagicConch_Lang, MagicConch_Config)
    
    loadCurrentLanguageFont(MagicConch.Config)
    resetGameState()
    
    -- Only reset on brand new game; for continue, keep loaded runtime
    if not isSave then
        resetRoomUsageCount()
    end
    
    -- Initialize current room key
    gameState.currentRoomKey = getCurrentRoomKey()
    
    -- API interface immediately created
    if not MagicConch.API then
        MagicConch.API = MagicConch_API.CreateInterface()
        
        -- API 준비 상태 확인
        if MagicConch.API.IsReady() then
            MagicConch.print("Magic Conch API is ready!")
        else
            MagicConch.printError("Magic Conch API initialization failed!")
        end
    end
    
    MagicConch.print("Magic Conch v" .. MagicConch_Config.VERSION .. " loaded!")
end

function MagicConch:OnNewRoom()
    resetGameState()
    -- Update current room key when entering new room
    gameState.currentRoomKey = getCurrentRoomKey()
    -- Persist runtime after room change
    MagicConch_Config.SaveRuntime(MagicConch, { roomUsageCount = gameState.roomUsageCount, currentRoomKey = gameState.currentRoomKey })
end

function MagicConch:OnNewLevel()
    -- Reset room usage count when entering new level (floor)
    resetRoomUsageCount()
    resetGameState()
    MagicConch_Config.SaveRuntime(MagicConch, { roomUsageCount = gameState.roomUsageCount, currentRoomKey = gameState.currentRoomKey })
    
    if MagicConch.Config.debugMode then
        local level = Game():GetLevel()
        local stage = level:GetStage()
        local stageType = level:GetStageType()
        MagicConch.printDebug("New level started - Stage: " .. stage .. ", Type: " .. stageType)
    end
end

function MagicConch:OnGameExit()
    MagicConch_Config.Save(MagicConch)
    -- Save runtime so data persists across reload/continue
    MagicConch_Config.SaveRuntime(MagicConch, { roomUsageCount = gameState.roomUsageCount, currentRoomKey = gameState.currentRoomKey })
end

-- Callbacks
MagicConch:AddCallback(ModCallbacks.MC_POST_UPDATE, MagicConch.OnHotkeyInput)
MagicConch:AddCallback(ModCallbacks.MC_POST_UPDATE, MagicConch.OnUpdate)
MagicConch:AddCallback(ModCallbacks.MC_POST_RENDER, MagicConch.OnRender)
MagicConch:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MagicConch.OnGameStart)
MagicConch:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, MagicConch.OnNewLevel)
MagicConch:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MagicConch.OnNewRoom)
MagicConch:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, MagicConch.OnGameExit)

-- API interface will be created after initialization
MagicConch.API = nil

-- API initialization flag to prevent duplicate initialization
local apiInitialized = false

return MagicConch