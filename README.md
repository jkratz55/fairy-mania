# Fairy Mania ✨

A cozy 2D side-scrolling platformer for kids aged 6–10, built with **Godot 4.7** and statically typed GDScript.
Help **Wren** the fairy hop, glide and fly through three worlds to reach the Starlight Castle.

Everything is original: all art is drawn in code with `_draw()`, and all sound effects and music are synthesized
at runtime. There are no imported image or audio files, so there's nothing borrowed from Disney or anyone else.
Wren (copper curls, a daisy clip, a lavender petal dress and butterfly wings) is an original character.

## How to play

| Action | Keyboard | Controller (Xbox / PlayStation) |
|---|---|---|
| Move | Arrow keys / A, D | Left stick / D-pad |
| Jump | Space / Z / K / Up / W | A / ✕ |
| Fly higher / lower | Hold Jump or Up / hold Down | A / ✕ or stick up / stick down |
| Pause | Esc / P | Menu / Options (Start) |
| Menus | Arrows + Enter/Space, Esc to go back | D-pad or stick + A / ✕, B / ○ to go back |
| Fullscreen | F11 | — |

- **Pixie dust:** collect 8 to fill the meter and start flying automatically. While flying, each extra dust adds flight time.
- **Pixie Blooms:** touch one to fill the meter instantly. They regrow, so a flying section can always be retried.
- **Glide:** hold Jump while falling to flutter down slowly.
- **Star blocks:** bump them from below for dust.
- **Critters:** bounce on top of them to turn them into sparkles (+1 dust).
- **Springs:** step or land on them to bounce extra high.

### Kid-friendly by design
- No game over and no lives: Wren has 3 hearts, and a knockout just returns her to the last lantern checkpoint with full hearts.
- Generous controls: coyote time, jump buffering, gliding, soft knockback and invulnerability after a hit.
- Tutorial signs pop up a speech bubble when Wren walks past them.
- Dust comes back after a knockout, and flying over the goal gate still counts.
- The cloud rests in the last level form a stairway, so running out of flight time is never a dead end.

## The levels
1. **Blossom Meadow** (sunny day): the tutorial level, with signs, a first moving platform and an optional sky route.
2. **Glowshroom Woods** (twilight forest): bouncy mushrooms, up-and-down platforms, a cave, and a cliff you fly up.
3. **Starlight Clouds** (night sky): cloud islands, big gaps to fly across, and the Starlight Castle.

## Project layout
```
autoload/        Game (level flow, saves, fades) and Audio (synth SFX + music) singletons
scripts/         Shared classes: LevelData, LevelTheme, Synth, Shapes, Fx
scenes/player/   Player (movement, dust & flight) and FairyArt (code-drawn Wren)
scenes/entities/ Pickups, enemies, hazards, platforms, checkpoint, goal, signs
scenes/level/    Level builder, TileRenderer, parallax Backdrop, Autopilot (dev tool)
scenes/ui/       Title, HUD, pause menu, victory screen
levels/          level_1.tres … level_3.tres (plain-text layouts)
ui/              Global UI theme
```

## Editing levels
Each level is a `LevelData` resource with a text `layout`: one character is one 32×32 tile, and there are 15 rows.
Open a `levels/*.tres` file in the Inspector or any text editor. The legend is also documented at the top of
`scripts/level_data.gd`:

```
.  empty            #  ground              =  one-way platform
P  player start     G  goal gate           C  checkpoint lantern
o  pixie dust       h  heart               *  pixie bloom (instant flight)
?  star block       T  spring              S  sign (text from `signs`, left to right)
g  walking critter  f  flyer (up/down)     b  flyer (left/right)
^  thorns           M  moving platform (left/right)   V  moving platform (up/down)
```
Handy physics numbers: a jump clears **3 tiles up** and about **5 across**, or roughly 9 across with a glide.
A spring launches about 7 tiles up. For an `M` platform, leave a 7-tile gap centred on the `M`.
For a `V` platform, leave a 3-tile gap.

To add a level, create a new `.tres` from an existing one and append its path to `LEVELS` in `autoload/game.gd`.
The `theme` field picks the art style and enemies: `meadow`, `woods` or `sky`.

## Developer shortcuts
Pass these after `--` on the command line:
```
godot --path . -- --level 2                # jump straight into level 2
godot --path . -- --level 3 --column 120   # ...starting at tile column 120
godot --path . -- --level 1 --fly          # ...already flying
godot --headless --path . --fixed-fps 60 -- --level 2 --autoplay --quit-when-done
                                           # a bot plays the level and reports if it finished
```
All three levels pass the autoplay check with zero knockouts.

## Code conventions
- Every declaration is statically typed. `debug/gdscript/warnings/untyped_declaration` is set to **Error**, so untyped
  code will not run.
- Collision layers: 1 world, 2 player, 3 enemies, 4 pickups.
