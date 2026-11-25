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

Keys: arrows/WASD move, Z/Space = A (interact), X = B, Enter = Start. Controllers work too.

## Game Boy Color rules

The screen is 256x144 (a widescreen GBC), integer scaled. Art follows real hardware limits,
checked by `tools/palette_checker.gd`:

- every colour is 15-bit (each channel 0-31), defined in `art_source/palettes.gd`
- each 8x8 background cell uses one 4-colour palette
- each 8x8 sprite cell uses 3 colours from one sprite palette, plus transparent
- shading is dither, never alpha

## Art pipeline

Look-book art is drawn as text in `art_source/` so every pixel shows in a diff.

```sh
godot --headless --path . -s tools/bake_art.gd        # text -> art/*.png, then palette check
godot --headless --path . -s tools/make_look_book.gd  # mockups -> build/look_book/
godot --headless --path . --import                    # let Godot import new PNGs
```

## Test

```sh
godot --headless --path . -s tests/smoke_test.gd
```
