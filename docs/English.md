# MagicConch Language and Translation Add/Modify Guide

## 📑 Table of Contents

- [MagicConch Language and Translation Add/Modify Guide](#magicconch-language-and-translation-addmodify-guide)
  - [1. Add/Modify Languages (Code, Name, Font, etc.)](#1-addmodify-languages-code-name-font-etc)
  - [2. Add/Modify Translation Strings](#2-addmodify-translation-strings)
  - [3. Notes for Adding/Modifying Strings](#3-notes-for-addingmodifying-strings)
  - [4. Example: Adding a New Message](#4-example-adding-a-new-message)
  - [Summary](#summary)
- [Magic Conch API Guide](#magic-conch-api-guide)
  - [Overview](#overview)
  - [API Access Method](#api-access-method)
  - [API Functions](#api-functions)
  - [Usage Tips](#usage-tips)
  - [Precautions](#precautions)

---

## 1. Add/Modify Languages (Code, Name, Font, etc.)

Add or modify language tables in the `LANGUAGE_MAP` array in `magic_conch_lang.lua`.

```lua
local LANGUAGE_MAP = {
    { code = "EN", options = "en", name = "English", font = "gfx/font/EnglishFont.fnt" },
    { code = "KR", options = "kr", name = "Korean", font = "gfx/font/Kkubulim.fnt" },
    { code = "JP", options = "jp", name = "Japanese", font = "gfx/font/JapaneseFont.fnt" }, -- Example addition
    -- Add more as needed
}
```

- **code**: Language code (uppercase, e.g., "EN", "KR", "JP")
- **options**: String matching the game's Options.Language value (e.g., "en", "kr", "jp")
- **name**: Language name to display in the UI (e.g., "English", "Korean", "Japanese")
- **font**: Font path to use for this language (Implement Soon)

---

## 2. Add/Modify Translation Strings

Add or modify translation strings in the `MagicConchStrings` table for each language code.

```lua
local MagicConchStrings = {
    EN = {
        MaybeSomeday = {text = "Maybe someday.", type = "neutral"},
        -- ...etc...
    },
    KR = {
        MaybeSomeday = {text = "언젠가는 하겠죠.", type = "neutral"},
        -- ...etc...
    },
    JP = { -- Example addition
        MaybeSomeday = {text = "いつかきっと。", type = "neutral"},
        Nothing = {text = "なにもありません。", type = "negative"},
        -- Add more as needed
    }
}
```

- **EN, KR, JP** etc. must match the `code` in `LANGUAGE_MAP`.
- **text**: The actual string to display.
- **type**: Message type (e.g., "neutral", "positive", "negative"). __**2:2:1 ratio recommendation**__

---

## 3. Notes for Adding/Modifying Strings

- When you add a `code` to `LANGUAGE_MAP`, you must also add a corresponding table to `MagicConchStrings`.
- It is recommended to keep the same message keys (e.g., MaybeSomeday, Nothing, etc.) across all languages.
- When adding a new message, add the same key to all languages for consistency.

---

## 4. Example: Adding a New Message

```lua
-- Add the same key to all languages
EN = {
    ...,
    NewMessage = {text = "This is a new message.", type = "neutral"},
}
KR = {
    ...,
    NewMessage = {text = "이것은 새로운 메시지입니다.", type = "neutral"},
}
JP = {
    ...,
    NewMessage = {text = "これは新しいメッセージです。", type = "neutral"},
}
```

---

## Summary

1. Add/modify language info in `LANGUAGE_MAP`.
2. Add/modify translation strings in `MagicConchStrings` (`code` must match).
3. Use the same message keys for all languages.
4. Manage font paths in `LANGUAGE_MAP` as well.

---

## Magic Conch API Guide

### 📋 Overview

Magic Conch provides an API that allows other mods to utilize Magic Conch functionality. Other mods can execute Magic Conch or receive and process results.

### 🔧 API Access Method

```lua
-- Check if Magic Conch API is available
if MagicConch and MagicConch.API then
    -- API is available
    local version = MagicConch.API.Version
    local config = MagicConch.API.Config
else
    -- Magic Conch is not loaded
    Isaac.ConsoleOutput("Magic Conch API not found")
end
```

### 📚 API Functions

#### 1. RegisterCallback(callback, modName)

Register a callback to receive Magic Conch results from other mods.

**Input:**
- `callback` (function): Function to receive the result
- `modName` (string, optional): Mod name

**Output:**
- `boolean`: Success or failure

**Callback Result Structure:**
The `result` table received by the callback function contains the following information:
- `text` (string): The text output by Magic Conch (e.g., "Yes.", "No.")
- `type` (string): Result type
  - `"positive"`: Positive result (Isaac happy face + angel sound)
  - `"negative"`: Negative result (Isaac angry face + screen shake + item removal in Resolute Mode)
  - `"neutral"`: Neutral result (Isaac "hmm..." sound)
- `timestamp` (number): The game frame number when the result was generated
- `displayStyle` (string): Display style (`"Fortune"` or `"Item"`)

**Result structure received by callback function:**
```lua
{
    text = "Magic Conch's answer",
    type = "positive/negative/neutral",
    timestamp = 12345,  -- Game frame count
    displayStyle = 0    -- 0: Fortune Machine Style, 1: Item-like Style
}
```

**Example:**
```lua
local function handleResult(result)
    Isaac.ConsoleOutput("Magic Conch Result: " .. result.text)
    Isaac.ConsoleOutput("Type: " .. result.type)
    Isaac.ConsoleOutput("Time: " .. result.timestamp)
    Isaac.ConsoleOutput("Display Style: " .. result.displayStyle)
end

-- Register callback
local success = MagicConch.API.RegisterCallback(handleResult, "My Mod")
if success then
    Isaac.ConsoleOutput("Callback registered successfully!")
end
```

#### 2. TriggerMagicConch(modName)

Execute Magic Conch.

**Input:**
- `modName` (string, optional): Name of the calling mod

**Output:**
```lua
{
    success = true/false,
    reason = "Execution result message",
    estimatedTime = 150, -- Frames remaining until completion
    pendingResult = {    -- Only when success is true
        text = "Answer to be displayed soon",
        type = "positive/negative/neutral",
        willDisplayIn = 90 -- Frames remaining until display
    }
}
```

**Example:**
```lua
local result = MagicConch.API.TriggerMagicConch("My Mod")
if result.success then
    Isaac.ConsoleOutput("Magic Conch execution successful!")
    Isaac.ConsoleOutput("Answer: " .. result.pendingResult.text)
    Isaac.ConsoleOutput("Complete in " .. math.floor(result.estimatedTime / 30) .. " seconds")
else
    Isaac.ConsoleOutput("Execution failed: " .. result.reason)
    if result.estimatedTime > 0 then
        Isaac.ConsoleOutput("Retry in " .. math.floor(result.estimatedTime / 30) .. " seconds")
    end
end
```

#### 3. Version (Property)

Returns Magic Conch's version information.

**Type:** `string`

**Example:**
```lua
Isaac.ConsoleOutput("Magic Conch Version: " .. MagicConch.API.Version)
```

#### 4. Config (Property)

Returns Magic Conch's current configuration. (Read-only)

**Type:** `table`

**Example:**
```lua
local config = MagicConch.API.Config
if config then
    Isaac.ConsoleOutput("Enabled: " .. tostring(config.enabled))
    Isaac.ConsoleOutput("Language: " .. config.language)
    Isaac.ConsoleOutput("Display Style: " .. config.displayStyle)
    Isaac.ConsoleOutput("Resolute Mode: " .. tostring(config.resoluteMode))
end
```

### 💡 Usage Tips

#### Register API on Game Start
```lua
YourMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    if MagicConch and MagicConch.API then
        MagicConch.API.RegisterCallback(yourCallbackFunction, "Your Mod Name")
        Isaac.ConsoleOutput("Magic Conch API connected!")
    end
end)
```

#### Auto-execute in Specific Situations
```lua
-- Auto-execute Magic Conch when boss is killed
YourMod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
    if entity:IsBoss() and MagicConch and MagicConch.API then
        local result = MagicConch.API.TriggerMagicConch("Your Mod (Boss Kill)")
        if result.success then
            Isaac.ConsoleOutput("Boss defeated! Magic Conch auto-executed")
        end
    end
end)
```

#### Implement Type-specific Special Effects
```lua
local function handleMagicConchResult(result)
    local player = Isaac.GetPlayer(0)
    
    if result.type == "positive" then
        -- Positive result: heal health
        player:AddHearts(2)
        Isaac.ConsoleOutput("✨ Good result! Health restored")
    elseif result.type == "negative" then
        -- Negative result: add curse
        local game = Game()
        game:GetLevel():AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
        Isaac.ConsoleOutput("💀 Bad result! Curse of Darkness")
    else
        -- Neutral result: no special effect
        Isaac.ConsoleOutput("😐 Neutral result...")
    end
end
```

#### Spam Prevention Handling
```lua
local lastTriggerTime = 0
local function triggerWithCooldown()
    local currentTime = Game():GetFrameCount()
    if currentTime - lastTriggerTime < 60 then -- 2 second cooldown
        Isaac.ConsoleOutput("Too frequent execution, please try again later")
        return
    end
    
    local result = MagicConch.API.TriggerMagicConch("Your Mod")
    if result.success then
        lastTriggerTime = currentTime
    end
end
```

### ⚠️ Precautions

1. **Always check for API existence before use**
   - Verify that both `MagicConch` and `MagicConch.API` exist

2. **Avoid abusing TriggerMagicConch**
   - Built-in spam prevention exists, but implement appropriate cooldowns
   - Too frequent calls can harm user experience

3. **Config is read-only**
   - Do not directly modify the Config object
   - Settings can only be changed through MCM

4. **Consider game state**
   - `TriggerMagicConch` may fail when Magic Conch is already running
   - New input is immediately available during `displaying` state

### 🎮 Magic Conch Operation

1. **🐚 Use**: Isaac lifts up the Magic Conch (uses MagicConch.png image)
2. **🎰 Start**: Slot machine sound + screen shake
3. **⏳ Wait**: Brief tension building
4. **📝 Display**: Answer text display + type-based effects
5. **😴 Cooldown**: Configurable cooldown time

**Type-based Effects:**
- **Positive**: Angel sound + Isaac happy face
- **Negative**: Isaac disgusted face + screen shake + (item removal in Resolute Mode)
- **Neutral**: "Hmm..." sound

---

# ToDo

- How to make fonts