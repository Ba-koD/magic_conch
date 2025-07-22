local MagicConch_Config = include("magic_conch_config")
local MagicConch_MCM = include("magic_conch_mcm")
local MagicConchStrings = include("translations")
local MagicConch_Render = include("magic_conch_render")

MagicConch = MagicConch or RegisterMod("Magic Conch", 1)
MagicConch_Config.Init(MagicConch)
local game = Game()

Isaac.ConsoleOutput("Magic Conch v" .. MagicConch_Config.VERSION .. " initializing...\n")

local displayText = nil
local displayTimer = 0
local DISPLAY_DURATION = 90 -- 1.5 seconds (based on 60 frames)

local function getCurrentLanguage()
    if MagicConch.Config.language == "EN" or MagicConch.Config.language == "KO" then
        return MagicConch.Config.language
    end
    if Options.Language and Options.Language == "ko_kr" then
        return "KO"
    end
    return "EN"
end

local function getRandomString()
    local lang = getCurrentLanguage()
    local pool = {}
    for k, v in pairs(MagicConchStrings[lang]) do
        table.insert(pool, v.text)
    end
    local idx = math.random(1, #pool)
    return pool[idx]
end

local function removeAllPickupsInRoom()
    local room = game:GetRoom()
    local entities = Isaac.GetRoomEntities()
    for _, ent in ipairs(entities) do
        if ent.Type == EntityType.ENTITY_PICKUP or ent.Type == EntityType.ENTITY_SLOT then
            ent:Remove()
        end
        if ent.Type == EntityType.ENTITY_PICKUP and ent.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            ent:Remove()
        end
    end
end

function MagicConch:OnHotkeyInput()
    if not MagicConch.Config.enabled then return end
    local input = Input.IsButtonTriggered(MagicConch.Config.hotkey or Keyboard.KEY_M, 0)
    if input then
        game:ShakeScreen(5)
        SFXManager():Play(SoundEffect.SOUND_FORTUNE_COOKIE, 1.0, 0, false, 1.0)
        local str = getRandomString()
        displayText = str
        displayTimer = DISPLAY_DURATION
        if MagicConch.Config.resoluteMode then
            removeAllPickupsInRoom()
        end
    end
end

function MagicConch:OnUpdate()
    if displayTimer > 0 then
        displayTimer = displayTimer - 1
        if displayTimer == 0 then
            displayText = nil
        end
    end
end

function MagicConch:OnRender()
    MagicConch_Render:Render(MagicConch, displayText, displayTimer, getCurrentLanguage)
end

function MagicConch:OnGameStart(isSave)
    MagicConch_Config.Load(MagicConch)
    MagicConch_MCM.Setup(MagicConch)
    Isaac.ConsoleOutput("Magic Conch v" .. MagicConch_Config.VERSION .. " loaded!\n")
end

function MagicConch:OnGameExit()
    MagicConch_Config.Save(MagicConch)
    Isaac.ConsoleOutput("Magic Conch v" .. MagicConch_Config.VERSION .. " settings saved.\n")
end

MagicConch:AddCallback(ModCallbacks.MC_POST_UPDATE, function() MagicConch:OnHotkeyInput() end)
MagicConch:AddCallback(ModCallbacks.MC_POST_UPDATE, function() MagicConch:OnUpdate() end)
MagicConch:AddCallback(ModCallbacks.MC_POST_RENDER, function() MagicConch:OnRender() end)
MagicConch:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MagicConch.OnGameStart)
MagicConch:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, MagicConch.OnGameExit)

return MagicConch