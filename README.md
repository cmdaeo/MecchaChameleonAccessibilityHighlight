# Meccha Chameleon Accessibility Highlight

An accessibility mod that makes whistled/called characters easier to spot by
highlighting them with a visible marker - useful for players with visual
tracking difficulties, colorblindness, or anyone who simply struggles to
locate their character/companion in busy scenes.

## What It Does

When someone whistles, the
mod highlights that character using one of three visual methods for a short
duration. Repeated whistles refresh the highlight timer instead of stacking
or duplicating effects.

## Installation

1. Make sure [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) is installed for
   your game.
2. Copy the `AccessibilityHighlight` folder into your game's `Mods` directory.
3. Launch the game.

## Highlight Modes

Open `main.lua` and edit this line near the top of the file:

```lua
local HIGHLIGHT_MODE = "chams"
```

Choose one of:

| Mode | Description |
|---|---|
| `"light"` | Spawns a bright point light above the character's head |
| `"chams"` | Makes the character render through walls/objects (X-ray style outline) |
| `"box"` | Spawns a solid marker box at the character's location |

Save the file and reload the mod (or restart the game) for the change to
take effect.

## How It Works

- The mod listens for a specific whistle/call sound cue.
- When detected, the corresponding character is highlighted using the mode
  you selected above.
- The highlight automatically clears after **2.5 seconds** unless the
  character is whistled at again, in which case the timer resets.
- Whistling again within **0.5 seconds** of a previous whistle is ignored
  (debounced), so rapidly repeating the whistle input does not spawn
  duplicate lights/boxes or reapply the highlight redundantly.

## Customization

All of the following can be edited at the top of `main.lua`:

```lua
local HIGHLIGHT_MODE = "chams"        -- "light" | "chams" | "box"
local WHISTLE_SOUND_KEYWORD = "provoaction"  -- sound name keyword to detect
local HIGHLIGHT_DURATION_MS = 2500    -- how long the highlight stays active
local WHISTLE_DEBOUNCE_MS = 500       -- minimum time between accepted whistles
```

- Increase `HIGHLIGHT_DURATION_MS` if you want the highlight to stay visible
  longer after whistling.
- Increase `WHISTLE_DEBOUNCE_MS` if you notice any duplicate highlight
  behavior with a particular game's sound setup.

## Troubleshooting

- **Nothing highlights when I whistle**: Check the UE4SS console/log for
  `[AccessibilityHighlight]` messages. The sound cue name may differ from
  `"provoaction"` in your specific game - you'll need to find the correct
  sound name and update `WHISTLE_SOUND_KEYWORD` accordingly.
- **Highlight doesn't disappear**: Confirm the character pawn is still valid
  in-game; if a character is removed/despawned while highlighted, the mod
  cleans up its highlight automatically on the next check cycle (every
  ~100ms).
- **"chams" mode doesn't seem visible through walls**: Some games use custom
  post-process materials that don't render the custom depth stencil by
  default - this may require an additional post-process material setup
  specific to that game, which is outside the scope of this mod's base logic.
