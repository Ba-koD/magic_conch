# MagicConch Language and Translation Add/Modify Guide

## 📑 Table of Contents

- [MagicConch Language and Translation Add/Modify Guide](#magicconch-language-and-translation-addmodify-guide)
  - [1. Add/Modify Languages (Code, Name, Font, etc.)](#1-addmodify-languages-code-name-font-etc)
  - [2. Add/Modify Translation Strings](#2-addmodify-translation-strings)
  - [3. Notes for Adding/Modifying Strings](#3-notes-for-addingmodifying-strings)
  - [4. Example: Adding a New Message](#4-example-adding-a-new-message)
  - [Summary](#summary)

---

## 1. Add/Modify Languages (Code, Name, Font, etc.)

Add or modify language tables in the `LANGUAGE_MAP` array in `magic_conch_lang.lua`.

```lua
local LANGUAGE_MAP = {
    { code = "EN", options = "en", name = "English", font = "resources/font/EnglishFont.fnt" },
    { code = "KR", options = "kr", name = "Korean", font = "resources/font/Kkubulim.fnt" },
    { code = "JP", options = "jp", name = "Japanese", font = "resources/font/JapaneseFont.fnt" }, -- Example addition
    -- Add more as needed
}
```

- **code**: Language code (uppercase, e.g., "EN", "KR", "JP")
- **options**: String matching the game's Options.Language value (e.g., "en", "kr", "jp")
- **name**: Language name to display in the UI (e.g., "English", "Korean", "Japanese")
- **font**: Font path to use for this language

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

- **EN, KR, JP** etc. must match the `code` in LANGUAGE_MAP.
- **text**: The actual string to display.
- **type**: Message type (e.g., "neutral", "positive", "negative").

---

## 3. Notes for Adding/Modifying Strings

- When you add a code to LANGUAGE_MAP, you must also add a corresponding table to MagicConchStrings.
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

1. Add/modify language info in LANGUAGE_MAP.
2. Add/modify translation strings in MagicConchStrings (code must match).
3. Use the same message keys for all languages.
4. Manage font paths in LANGUAGE_MAP as well.

# ToDo

- How to make fonts