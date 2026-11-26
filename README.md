# Driftwood

A castaway survival game that looks like a lost Game Boy Color cartridge.
Homage to Survival Kids (Konami, 1999), with Link's Awakening's island, Harvest Moon's
daily rhythm and Valheim's build-and-progress loop.

Godot 4.7, GDScript.

## Run

```sh
godot --path .            # play
godot -e --path .         # editor
```

## Controls

| | Keyboard | Controller |
|---|---|---|
| Move | Arrows / WASD | D-pad / left stick |
| A (interact, or use the item on A) | Z / Space / J | A |
| B (use the item on B) | X / K | B |
| Start (bag, merge, book, map, system) | Enter / Esc | Start |

## The game

You wash up with nothing. Shake palms, open coconuts, merge sticks and stones into tools.
Build a home inside a workbench's reach, sleep under a roof to wake Rested, farm through
four seasons, tame a goat, a hen and a monkey called Bo. Cut through the jungle, break
the boulders, take a torch into the cave and beat the guardian for copper. Raft out to
the ruins and to Wren the hermit. Then choose how it ends: light the beacon, fix the
radio, sail away, or stay.

- 4 meters: health, hunger, water, fatigue. Hunger or water at 0 drains health.
- 26 merges to discover; cooking and boiling on fires; a kiln smelts copper.
- 12-minute days, 7-day seasons, weather (rain waters crops and douses open fires).
- 3 save slots; saving happens when you sleep, or with SAVE AND QUIT.
- Collapse and you wake at your bed the next morning; your bag waits where you fell.

## Game Boy Color rules

The screen is 256x144 (a widescreen GBC), integer scaled. Art follows real hardware limits,
checked by `tools/palette_checker.gd`:

- every colour is 15-bit (each channel 0-31), defined in `art_source/palettes.gd`
- each 8x8 background cell uses one 4-colour palette
- each 8x8 sprite cell uses 3 colours from one sprite palette, plus transparent
- shading is dither, never alpha; night is an ordered dither too
- seasons and the look picker are palette swaps

## Where things live

| Folder | What |
|---|---|
| `art_source/` | All art as text pixel grids, plus palettes |
| `data/` | Items, recipes, things, build pieces, maps (text, diffable) |
| `systems/` | Pure game rules: inventory, meters, clock, merging, building, save |
| `scenes/world/` | The island: world, player, creatures, interactions, cooking, farming, endings |
| `ui/` | Status bar, menus, dialogue, overlays |
| `core/` | Autoloads: Game, Settings, Sound, ScreenFader, GameInput, LcdEffect |
| `tools/` | Bakers for art and audio, art preview, palette checker |

## Art and audio pipeline

Art and music are drawn and written as text, so every pixel and note shows in a diff.

```sh
godot --headless --path . -s tools/bake_art.gd        # text -> art/*.png, then palette check
godot --headless --path . -s tools/bake_audio.gd      # synthesise sounds and music -> audio/
godot --headless --path . -s tools/preview_art.gd     # every sprite on one sheet -> build/art_sheet.png
godot --headless --path . --import                    # let Godot import new files
```

## Test

```sh
godot --headless --path . tests/smoke_test.tscn   # 79 checks: rules, scenes, and that every ending is reachable
godot --headless --path . tests/soak_test.tscn    # random button mashing across the island
godot --path . tests/capture.tscn                 # screenshots to build/captures (opens a window)
```

Tests run as scenes, not with `-s`, so the autoloads exist when they compile.
