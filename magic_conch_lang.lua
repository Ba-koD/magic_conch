---@class MagicConchLang
---@field LANGUAGE_MAP table
---@field getLanguageTable fun(config: table): table
---@field getRandomString fun(config: table): table

---@type MagicConchLang
local LANGUAGE_MAP = {
    { code = "EN", options = "en", name = "English", font = "gfx/font/Kkubulim.fnt" },
    { code = "KR", options = "kr", name = "Korean", font = "gfx/font/Kkubulim.fnt" },
    -- Add more languages here
    -- Font Feature will be added later
}

-- Translation strings for Magic Conch mod
-- @param language string Language code (e.g. "EN" or "KR")
-- @return table MagicConchStrings table (e.g. { text = "Maybe someday.", type = "neutral" })
local MagicConchStrings = {
    EN = { -- English Translations (8:8:4 ratio, 20 total)
    -- Positive responses (8 total)
    Yes = {text = "Yes.", type = "positive"},
    Absolutely = {text = "Absolutely.", type = "positive"},
    Definitely = {text = "Definitely.", type = "positive"},
    OfCourse = {text = "Of course.", type = "positive"},
    FollowTheConch = {text = "Follow the conch.", type = "positive"},
    ConchKnowsAll = {text = "The conch knows everything.", type = "positive"},
    YouMay = {text = "You may.", type = "positive"},
    Proceed = {text = "Proceed.", type = "positive"},

    -- Negative responses (8 total)
    Nothing = {text = "Do nothing.", type = "negative"},
    Neither = {text = "Neither.", type = "negative"},
    IDontThinkSo = {text = "I don't think so.", type = "negative"},
    No = {text = "No.", type = "negative"},
    DontEvenAsk = {text = "Don't even ask.", type = "negative"},
    NotToday = {text = "Not today.", type = "negative"},
    Forbidden = {text = "Forbidden.", type = "negative"},
    Impossible = {text = "Impossible.", type = "negative"},

    -- Neutral responses (4 total)
    AskAgainLater = {text = "Ask again later.", type = "neutral"},
    UncertainTimes = {text = "Uncertain times.", type = "neutral"},
    MaybeSomeday = {text = "Maybe someday.", type = "neutral"},
    TryAgain = {text = "Try again.", type = "neutral"},
    },
    KR = { -- Korean Translations (8:8:4 ratio for 20 total)
    -- Positive responses (8 total)
    Yes = {text = "좋아.", type = "positive"},
    Absolutely = {text = "물론.", type = "positive"},
    Definitely = {text = "확실해.", type = "positive"},
    OfCourse = {text = "당연하지.", type = "positive"},
    FollowTheConch = {text = "소라고동을 따라.", type = "positive"},
    ConchKnowsAll = {text = "소라고동은 모든 걸 알아.", type = "positive"},
    YouMay = {text = "해도 돼.", type = "positive"},
    Proceed = {text = "진행해.", type = "positive"},
    
    -- Negative responses (8 total)
    Nothing = {text = "가만있어.", type = "negative"},
    Neither = {text = "다 안 돼.", type = "negative"},
    IDontThinkSo = {text = "그것도 안 돼.", type = "negative"},
    No = {text = "안 돼.", type = "negative"},
    DontEvenAsk = {text = "묻지도 마.", type = "negative"},
    NotToday = {text = "오늘은 절대 안 돼.", type = "negative"},
    Forbidden = {text = "금지야.", type = "negative"},
    Impossible = {text = "불가능해.", type = "negative"},
    
    -- Neutral responses (4 total)
    AskAgainLater = {text = "나중에 다시 물어봐.", type = "neutral"},
    UncertainTimes = {text = "불분명한 시기야.", type = "neutral"},
    MaybeSomeday = {text = "언젠가는 하겠지.", type = "neutral"},
    TryAgain = {text = "다시 한 번 물어봐.", type = "neutral"},
    },
    -- Add more translations here
}

-- Get Language Table from Config and Options
-- @param config table Config table (e.g. MagicConch.Config)
-- @return table Language table (e.g. { code = "EN", options = "en", name = "English" })
local function getLanguageTable(config)
    local result = LANGUAGE_MAP[1] -- Default: first language (EN)
    
    -- If config.language is not "Auto", use it directly
    if config and config.language and config.language ~= "Auto" then
        for _, lang in ipairs(LANGUAGE_MAP) do
            if lang.code == config.language then
                result = lang
                break
            end
        end
    -- If config.language is "Auto" or not set, use Options.Language
    elseif Options and Options.Language then
        for _, lang in ipairs(LANGUAGE_MAP) do
            if Options.Language == lang.options then
                result = lang
                break
            end
        end
    end
    
    return result
end

-- Random string from the language table
-- @param config table Config table (e.g. MagicConch.Config)
-- @return table { text = "...", type = "..." }
local function getRandomString(config)
    local langTable = getLanguageTable(config)
    local strings = MagicConchStrings[langTable.code]

    local pool = {}
    for _, v in pairs(strings) do
        table.insert(pool, v)
    end

    if #pool == 0 then
        return nil
    end

    local idx = math.random(1, #pool)
    return pool[idx]
end

return {
    LANGUAGE_MAP = LANGUAGE_MAP,
    getLanguageTable = getLanguageTable,
    getRandomString = getRandomString,
} 