# MagicConch 언어 및 번역 추가/수정 방법

## 📑 목차

- [MagicConch 언어 및 번역 추가/수정 방법](#magicconch-언어-및-번역-추가수정-방법)
  - [1. 언어(코드, 이름, 폰트 등) 추가/수정](#1-언어코드-이름-폰트-등-추가수정)
  - [2. 번역 문장 추가/수정](#2-번역-문장-추가수정)
  - [3. 문장 추가/수정 시 주의사항](#3-문장-추가수정-시-주의사항)
  - [4. 예시: 새로운 문장 추가](#4-예시-새로운-문장-추가)
  - [요약](#요약)

---

## 1. 언어(코드, 이름, 폰트 등) 추가/수정

`magic_conch_lang.lua`의 `LANGUAGE_MAP` 배열에 새로운 언어 테이블을 추가하거나, 기존 값을 수정하면 됩니다.

```lua
local LANGUAGE_MAP = {
    { code = "EN", options = "en", name = "English", font = "resources/font/EnglishFont.fnt" },
    { code = "KR", options = "kr", name = "Korean", font = "resources/font/Kkubulim.fnt" },
    { code = "JP", options = "jp", name = "Japanese", font = "resources/font/JapaneseFont.fnt" }, -- 추가 예시
    -- 필요시 더 추가
}
```

- **code**: 언어 코드(대문자, 예: "EN", "KR", "JP")
- **options**: 게임 Options.Language 값과 매칭되는 문자열(예: "en", "kr", "jp")
- **name**: UI에 표시될 언어 이름(예: "English", "Korean", "Japanese")
- **font**: 해당 언어에 사용할 폰트 경로

---

## 2. 번역 문장 추가/수정

`MagicConchStrings` 테이블에서 각 언어 코드에 해당하는 테이블에 문장을 추가/수정하면 됩니다.

```lua
local MagicConchStrings = {
    EN = {
        MaybeSomeday = {text = "Maybe someday.", type = "neutral"},
        -- ...생략...
    },
    KR = {
        MaybeSomeday = {text = "언젠가는 하겠죠.", type = "neutral"},
        -- ...생략...
    },
    JP = { -- 추가 예시
        MaybeSomeday = {text = "いつかきっと。", type = "neutral"},
        Nothing = {text = "なにもありません。", type = "negative"},
        -- 필요시 더 추가
    }
}
```

- **EN, KR, JP** 등은 LANGUAGE_MAP의 code와 반드시 일치해야 함
- **text**: 실제로 표시될 문장
- **type**: 문장 타입(예: "neutral", "positive", "negative")

---

## 3. 문장 추가/수정 시 주의사항

- LANGUAGE_MAP에 code를 추가하면, MagicConchStrings에도 동일한 code로 번역 테이블을 추가해야 함
- 문장 키(예: MaybeSomeday, Nothing 등)는 모든 언어에서 동일하게 맞추는 것이 좋음
- 새로운 문장 추가 시, 모든 언어에 해당 키를 추가하는 것이 권장됨

---

## 4. 예시: 새로운 문장 추가

```lua
-- 모든 언어에 동일한 키로 추가
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

## 요약

1. LANGUAGE_MAP에 언어 정보 추가/수정
2. MagicConchStrings에 번역 문장 추가/수정 (code 일치 필수)
3. 문장 키는 모든 언어에서 동일하게 맞추는 것이 좋음
4. 폰트 경로 등도 LANGUAGE_MAP에서 관리

## 추가예정

- 폰트 제작 방법