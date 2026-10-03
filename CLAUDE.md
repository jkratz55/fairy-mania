# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Fairy Mania is a 2D platformer for kids aged 6–10, made with **Godot 4.7** (`/Applications/Godot.app/Contents/MacOS/Godot`).
Wren the fairy plays through 9 themed worlds, and level 10 is a boss battle against the Evil Fairy Queen.

## Hard rules
- **Statically typed GDScript only.** `untyped_declaration` is set to Error, so untyped code won't run. Also avoid `:=` on
  values that are Variant (for example `dict.get()` or `array.pick_random()`). Declare the type explicitly instead.
- **No imported assets.** All art is drawn with `_draw()` and all audio is synthesized at runtime (`scripts/synth.gd`).
  Never add image or audio files, and keep characters original (nothing from Disney or anyone else).
- **Keyboard and controller.** Every input action uses device -1. Gameplay must stay kid-friendly: no game over, 3
  hearts, respawn at the last lantern, and dust that comes back after a knockout.

## Commands
There is no build step or unit-test suite. Verification is done by running the game headless with the autoplay bot.
```
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path . --quit                       # compile check: prints SCRIPT ERROR lines on failure
$G --headless --path . --import                     # REQUIRED after adding a new class_name script
$G --path . -- --level 3 --column 40 --fly          # jump into a level / tile column / already flying
$G --headless --path . --fixed-fps 60 -- --level 7 --autoplay --quit-when-done   # "test" one level
$G --path . -- --console "god on; level 10 40"      # run debug-console commands at startup (`;`-separated)
```
- **Autoplay** (`scenes/level/autopilot.gd`): a bot that holds right and jumps. It prints
  `AUTOPILOT FINISHED ... knockouts=N` and `knockout at column X, row Y`. Run a new or changed level several times,
  because critters start at random phases. Known results: level 2 sometimes gets 1 knockout, and the bot usually
  takes about 1 knockout in the boss fight.
- **Screenshots** need a non-headless run:
  `$G --path . --write-movie <dir>/f.png --fixed-fps 30 --quit-after 75 -- --level N --column X`, then read the last PNG.
  `--console "...; wait 3; ..."` (`wait` only works in startup scripts) lets you script a state before capturing.
- **Debug console:** press **~** in debug builds to open it (`autoload/debug_console.gd`). It has warps, god mode,
  infinite flight, `crack` for the boss mirror, and more. It is compiled out of release exports by
  `OS.is_debug_build()`, and the game pauses while it is open.

## Architecture
**Autoloads** (`project.godot`):
- **`Game`** (`autoload/game.gd`) owns the level order (the `LEVELS` array), saved progress (`user://progress.cfg`,
  which stores only an unlocked-level count), scene fades, command-line debug flags, and the cheat flags that
  persist across scenes (`debug_invincible`, `debug_infinite_flight`). The title screen's level menu is built from
  `LEVELS`.
- **`Audio`** renders `Synth.SONGS` on worker threads at startup and plays the SFX defined in `_build_sound_effects()`.
  Every song needs a lead and a bass line that both add up to the same number of beats (each existing song uses 32).
- **`DebugConsole`.**

**Levels are data, not scenes.** Each `levels/level_N.tres` is a `LevelData` resource:
- `layout` is a 15-row text grid, one character per 32 px tile. The legend is in `scripts/level_data.gd` and the
  README.
- `theme` picks a `LevelTheme`, and `music` names a song in `Synth.SONGS`.
- `signs` holds the hint texts, assigned to `S` cells from left to right.

`scenes/level/level.gd` parses the layout at runtime:
- It merges `#` cells into collision rectangles and turns `=` into one-way platforms.
- It spawns the entities, and `_add_entity` injects `theme` into any node that has a `theme` property.
- It handles checkpoints, respawns (emitting `respawned`), and `complete()`.

`TileRenderer` draws the terrain in 16-column chunks so off-screen chunks are culled. `Backdrop` builds `Parallax2D`
layers that repeat a 1024 px strip.

**Themes are spread across many files.** A theme id from `LevelTheme.create()` (palette plus `style`) is switched on
in all of these:
- `Backdrop.setup` and `draw_layer`;
- `TileRenderer` (specks, ground edges, platforms, decorations, `_draw_pits`);
- `Walker`, `Flyer`, `Bouncer`, `MovingPlatform`.

Adding a theme means adding a case in each of them. Otherwise the theme falls back to the meadow art. Also add the id
to the `@export_enum` in `level_data.gd`, add a song, and register the `.tres` in `Game.LEVELS`.

**Boss level:**
- A layout containing `Q` (the Queen), `R` (the mirror, whose stand sits on the floor below its cell) and `|` (the
  arena's left edge) makes `Level` create a `BossFight` (`scenes/level/boss_fight.gd`).
- `BossFight` locks the camera and `player.level_bounds`, wires the mirror's signals to the Queen
  (`scenes/entities/fairy_queen.gd`), shows the HUD boss bar and dialogue (`Hud.show_boss_bar`,
  `Hud.show_dialogue`), and resets the fight when `Level.respawned` fires.
- Mirror cracks persist across knockouts. Wren can't damage the Queen; only `MagicBolt` calls `player.hurt`.
- Boss entities are built in code (no `.tscn`).

**Player** (`scenes/player/player.gd`):
- Wren is drawn by `FairyArt`.
- Damage goes through `hurt()`, and non-damaging pushes go through `bounce_back(from, strength)`.
- Flight starts automatically when the dust meter reaches 8, or when Wren touches a Pixie Bloom.
- Falling below `level_bounds` causes a knockout.

Collision layers: 1 world, 2 player, 3 enemies (bit value 4), 4 pickups (bit value 8).

## Level design numbers
- **Jumps:** a jump clears 3 tiles up and about 5 across, or about 9 across with a glide.
- **Springs** (`T`) launch about 7 tiles up.
- **Moving platforms:** `M` needs a 7-tile gap centered on it. `V` needs a 3-tile gap, with the `V` one row above
  the floor surface.
- **Flight:** one flight covers about 40 tiles, so keep gaps after a bloom at about 33 tiles or less, and put
  stairway rest ledges underneath.
- **Autoplay quirks to design around:**
  - The bot always glides, so it lands about 8 tiles past an edge. Lanterns, blooms and thorns placed near landing
    spots get skipped or landed on.
  - It only moves right, so put springs flush against the wall they climb.
  - It flies at about row 3, so don't put flyers there.
