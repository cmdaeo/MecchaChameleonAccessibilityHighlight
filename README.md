# Meccha Chameleon Accessibility Highlight

A UE4SS Lua mod for **Meccha Chameleon** that highlights whistled/called characters.

---

## What It Does

When a whistle is triggered in Meccha Chameleon, this mod highlights the corresponding character using one of three visual methods for a short duration. Repeated whistles refresh the highlight timer instead of stacking or duplicating effects.

---

## Requirements

- Meccha Chameleon
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) installed

---

## Installation

1. Install UE4SS for Meccha Chameleon if you haven't already.
2. Extract this mod into your Meccha Chameleon `Mods` folder so the structure looks like:

```
Mods/
└── AccessibilityHighlight/
    ├── Scripts/
    │   └── main.lua
```

3. Launch Meccha Chameleon.

---

## Highlight Modes

Open `Scripts/main.lua` and edit this line near the top:

```lua
local HIGHLIGHT_MODE = "chams"
```

| Mode | Description |
|---|---|
| `"light"` | Spawns a glowing point light above the character's head |
| `"chams"` | Renders the character through walls/objects (X-ray outline) |
| `"box"` | Spawns a solid marker box at the character's location |

Save and restart the game to apply the change.

---

## Configuration

Additional tunables at the top of `main.lua`:

```lua
local WHISTLE_SOUND_KEYWORD = "provoaction"  -- sound cue keyword to detect
local HIGHLIGHT_DURATION_MS = 2500           -- how long the highlight stays active
local WHISTLE_DEBOUNCE_MS = 500              -- minimum time between accepted whistles
```

---

## How It Works

- Hooks `AudioComponent:Play` and checks the sound asset name for the whistle keyword.
- Debounces rapid repeated triggers per character (string-keyed by full object name, not the raw pawn reference, since UE4SS returns a new wrapper object per call).
- Runs a lightweight polling loop (~100ms) to apply/update/clear highlights and expire them after the configured duration.
