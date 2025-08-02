# MagicConch 언어 및 번역 추가/수정 방법

## 📑 목차

- [MagicConch 언어 및 번역 추가/수정 방법](#magicconch-언어-및-번역-추가수정-방법)
  - [1. 언어(코드, 이름, 폰트 등) 추가/수정](#1-언어코드-이름-폰트-등-추가수정)
  - [2. 번역 문장 추가/수정](#2-번역-문장-추가수정)
  - [3. 문장 추가/수정 시 주의사항](#3-문장-추가수정-시-주의사항)
  - [4. 예시: 새로운 문장 추가](#4-예시-새로운-문장-추가)
  - [요약](#요약)
- [Magic Conch API 가이드](#magic-conch-api-가이드)
  - [개요](#개요)
  - [API 접근 방법](#api-접근-방법)
  - [API 함수들](#api-함수들)
  - [사용 팁](#사용-팁)
  - [주의사항](#주의사항)

---

## 1. 언어(코드, 이름, 폰트 등) 추가/수정

`magic_conch_lang.lua`의 `LANGUAGE_MAP` 배열에 새로운 언어 테이블을 추가하거나, 기존 값을 수정하면 됩니다.

```lua
local LANGUAGE_MAP = {
    { code = "EN", options = "en", name = "English", font = "gfx/font/EnglishFont.fnt" },
    { code = "KR", options = "kr", name = "Korean", font = "gfx/font/Kkubulim.fnt" },
    { code = "JP", options = "jp", name = "Japanese", font = "gfx/font/JapaneseFont.fnt" }, -- 추가 예시
    -- 필요시 더 추가
}
```

- **code**: 언어 코드(대문자, 예: "EN", "KR", "JP")
- **options**: 게임 Options.Language 값과 매칭되는 문자열(예: "en", "kr", "jp")
- **name**: UI에 표시될 언어 이름(예: "English", "Korean", "Japanese")
- **font**: 해당 언어에 사용할 폰트 경로 (추후 구현 예정)

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

- **EN, KR, JP** 등은 `LANGUAGE_MAP`의 `code`와 반드시 일치해야 함
- **text**: 실제로 표시될 문장
- **type**: 문장 타입(예: "neutral", "positive", "negative") __**2:2:1 비율 추천**__

---

## 3. 문장 추가/수정 시 주의사항

- `LANGUAGE_MAP`에 `code`를 추가하면, `MagicConchStrings`에도 동일한 `code`로 번역 테이블을 추가해야 함
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

1. `LANGUAGE_MAP`에 언어 정보 추가/수정
2. `MagicConchStrings`에 번역 문장 추가/수정 (`code` 일치 필수)
3. 문장 키는 모든 언어에서 동일하게 맞추는 것이 좋음
4. 폰트 경로 등도 `LANGUAGE_MAP`에서 관리

---

## Magic Conch API 가이드

### 📋 개요

Magic Conch는 다른 모드들이 Magic Conch의 기능을 활용할 수 있도록 API를 제공합니다. 다른 모드에서 Magic Conch를 실행하거나, 결과를 받아서 처리할 수 있습니다.

### 🔧 API 접근 방법

```lua
-- Magic Conch API 사용 가능 여부 확인
if MagicConch and MagicConch.API then
    -- API 사용 가능
    local version = MagicConch.API.Version
    local config = MagicConch.API.Config
else
    -- Magic Conch가 로드되지 않음
    Isaac.ConsoleOutput("Magic Conch API를 찾을 수 없습니다")
end
```

### 📚 API 함수들

#### 1. RegisterCallback(callback, modName)

다른 모드가 Magic Conch의 결과를 받을 수 있도록 콜백을 등록합니다.

**입력:**
- `callback` (function): 결과를 받을 함수
- `modName` (string, 선택사항): 모드 이름

**출력:**
- `boolean`: 성공 여부

**콜백 결과 구조:**
콜백 함수가 받는 `result` 테이블에는 다음 정보가 포함됩니다:
- `text` (string): Magic Conch가 출력한 텍스트 (예: "좋아.", "안 돼.")
- `type` (string): 결과 타입
  - `"positive"`: 긍정적 결과 (Isaac 행복 표정 + 천사 소리)
  - `"negative"`: 부정적 결과 (Isaac 화난 표정 + 화면 흔들림 + Resolute Mode 시 아이템 제거)
  - `"neutral"`: 중립적 결과 (Isaac "흠..." 소리)
- `timestamp` (number): 결과가 생성된 게임 프레임 번호
- `displayStyle` (string): 표시 스타일 (`"Fortune"` 또는 `"Item"`)

**콜백 함수가 받는 result 구조:**
```lua
{
    text = "Magic Conch의 답변",
    type = "positive/negative/neutral",
    timestamp = 12345,  -- 게임 프레임 카운트
    displayStyle = 0    -- 0: Fortune Machine Style, 1: Item-like Style
}
```

**예시:**
```lua
local function handleResult(result)
    Isaac.ConsoleOutput("Magic Conch 결과: " .. result.text)
    Isaac.ConsoleOutput("타입: " .. result.type)
    Isaac.ConsoleOutput("시간: " .. result.timestamp)
    Isaac.ConsoleOutput("표시 스타일: " .. result.displayStyle)
end

-- 콜백 등록
local success = MagicConch.API.RegisterCallback(handleResult, "내 모드")
if success then
    Isaac.ConsoleOutput("콜백 등록 성공!")
end
```

#### 2. TriggerMagicConch(modName)

Magic Conch를 실행합니다.

**입력:**
- `modName` (string, 선택사항): 호출한 모드 이름

**출력:**
```lua
{
    success = true/false,
    reason = "실행 결과 메시지",
    estimatedTime = 150, -- 완료까지 남은 프레임 수
    pendingResult = {    -- success가 true일 때만
        text = "곧 표시될 답변",
        type = "positive/negative/neutral",
        willDisplayIn = 90 -- 표시까지 남은 프레임 수
    }
}
```

**예시:**
```lua
local result = MagicConch.API.TriggerMagicConch("내 모드")
if result.success then
    Isaac.ConsoleOutput("Magic Conch 실행 성공!")
    Isaac.ConsoleOutput("답변: " .. result.pendingResult.text)
    Isaac.ConsoleOutput(math.floor(result.estimatedTime / 30) .. "초 후 완료")
else
    Isaac.ConsoleOutput("실행 실패: " .. result.reason)
    if result.estimatedTime > 0 then
        Isaac.ConsoleOutput(math.floor(result.estimatedTime / 30) .. "초 후 재시도")
    end
end
```

#### 3. Version (속성)

Magic Conch의 버전 정보를 반환합니다.

**타입:** `string`

**예시:**
```lua
Isaac.ConsoleOutput("Magic Conch 버전: " .. MagicConch.API.Version)
```

#### 4. Config (속성)

Magic Conch의 현재 설정을 반환합니다. (읽기 전용)

**타입:** `table`

**예시:**
```lua
local config = MagicConch.API.Config
if config then
    Isaac.ConsoleOutput("활성화: " .. tostring(config.enabled))
    Isaac.ConsoleOutput("언어: " .. config.language)
    Isaac.ConsoleOutput("표시 스타일: " .. config.displayStyle)
    Isaac.ConsoleOutput("Resolute Mode: " .. tostring(config.resoluteMode))
end
```

### 💡 사용 팁

#### 게임 시작 시 API 등록
```lua
YourMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
    if MagicConch and MagicConch.API then
        MagicConch.API.RegisterCallback(yourCallbackFunction, "Your Mod Name")
        Isaac.ConsoleOutput("Magic Conch API 연결 완료!")
    end
end)
```

#### 특정 상황에서 자동 실행
```lua
-- 보스 처치 시 Magic Conch 자동 실행
YourMod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
    if entity:IsBoss() and MagicConch and MagicConch.API then
        local result = MagicConch.API.TriggerMagicConch("Your Mod (Boss Kill)")
        if result.success then
            Isaac.ConsoleOutput("보스 처치! Magic Conch 자동 실행")
        end
    end
end)
```

#### 타입별 특수 효과 구현
```lua
local function handleMagicConchResult(result)
    local player = Isaac.GetPlayer(0)
    
    if result.type == "positive" then
        -- 긍정적 결과: 체력 회복
        player:AddHearts(2)
        Isaac.ConsoleOutput("✨ 좋은 결과! 체력 회복")
    elseif result.type == "negative" then
        -- 부정적 결과: 저주 추가
        local game = Game()
        game:GetLevel():AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
        Isaac.ConsoleOutput("💀 나쁜 결과! 어둠의 저주")
    else
        -- 중립적 결과: 특별한 효과 없음
        Isaac.ConsoleOutput("😐 평범한 결과...")
    end
end
```

#### 스팸 방지 처리
```lua
local lastTriggerTime = 0
local function triggerWithCooldown()
    local currentTime = Game():GetFrameCount()
    if currentTime - lastTriggerTime < 60 then -- 2초 쿨다운
        Isaac.ConsoleOutput("너무 빠른 실행, 잠시 후 다시 시도하세요")
        return
    end
    
    local result = MagicConch.API.TriggerMagicConch("Your Mod")
    if result.success then
        lastTriggerTime = currentTime
    end
end
```

### ⚠️ 주의사항

1. **API 사용 전 항상 존재 여부 확인**
   - `MagicConch`와 `MagicConch.API`가 모두 존재하는지 확인하세요

2. **TriggerMagicConch 남용 방지**
   - 내장 스팸 방지 기능이 있지만, 적절한 쿨다운을 구현하세요
   - 너무 자주 호출하면 사용자 경험에 방해가 될 수 있습니다

3. **Config는 읽기 전용**
   - Config 객체를 직접 수정하지 마세요
   - 설정 변경은 MCM을 통해서만 가능합니다

4. **게임 상태 고려**
   - Magic Conch가 이미 실행 중일 때는 `TriggerMagicConch`가 실패할 수 있습니다
   - `displaying` 상태에서는 새로운 입력이 즉시 가능합니다

### 🎮 Magic Conch 동작 방식

1. **🐚 사용**: Isaac이 Magic Conch를 들어올림 (MagicConch.png 이미지 사용)
2. **🎰 시작**: 슬롯머신 소리 + 화면 흔들림
3. **⏳ 대기**: 잠시 긴장감 조성
4. **📝 표시**: 답변 텍스트 표시 + 타입별 효과
5. **😴 쿨다운**: 설정 가능한 쿨다운 시간

**타입별 효과:**
- **Positive**: 천사 소리 + Isaac 행복한 얼굴
- **Negative**: Isaac 찡그린 얼굴 + 화면 흔들림 + (Resolute Mode 시 아이템 삭제)
- **Neutral**: "흠..." 소리

---

## 추가예정

- 폰트 제작 방법