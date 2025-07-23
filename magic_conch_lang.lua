---@class MagicConchLang
---@field LANGUAGE_MAP table
---@field getLanguageTable fun(config: table): table
---@field getRandomString fun(config: table): table

---@type MagicConchLang
local LANGUAGE_MAP = {
    { code = "EN", options = "en", name = "English", font = "resources/font/EnglishFont.fnt" },
    { code = "KR", options = "kr", name = "Korean", font = "resources/font/Kkubulim.fnt" },
    -- Add more languages here
}

-- Translation strings for Magic Conch mod
-- @param language string Language code (e.g. "EN" or "KR")
-- @return table MagicConchStrings table (e.g. { text = "Maybe someday.", type = "neutral" })
local MagicConchStrings = {
    EN = { -- English translations
        MaybeSomeday = {text = "Maybe someday.", type = "neutral"},
        Nothing = {text = "Nothing.", type = "negative"},
        Neither = {text = "Neither.", type = "negative"},
        IDontThinkSo = {text = "I don't think so.", type = "negative"},
        Yes = {text = "Yes.", type = "positive"},
        TryAgain = {text = "Try asking again.", type = "neutral"},
        No = {text = "No.", type = "negative"},
    },
    KR = { -- Korean translations
        MaybeSomeday = {text = "언젠가는 하겠죠.", type = "neutral"},
        Nothing = {text = "가만있어요.", type = "negative"},
        Neither = {text = "다 안 돼요.", type = "negative"},
        IDontThinkSo = {text = "그것도 안 돼요.", type = "negative"},
        Yes = {text = "좋아요.", type = "positive"},
        TryAgain = {text = "다시 한 번 물어봐요.", type = "neutral"},
        No = {text = "안 돼요.", type = "negative"},
    }
    -- Add more translations here
}

-- Get Language Table from Config and Options
-- @param config table Config table (e.g. MagicConch.Config)
-- @return table Language table (e.g. { code = "EN", options = "en", name = "English" })
local function getLanguageTable(config)
    local result = LANGUAGE_MAP[1]
    if config and config.language then
        for _, lang in ipairs(LANGUAGE_MAP) do
            if lang.code == config.language then
                result = lang
            end
        end
    end
    if Options and Options.Language then
        for _, lang in ipairs(LANGUAGE_MAP) do
            if Options.Language == lang.options then
                result = lang
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