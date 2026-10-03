# Fairy Mania ✨

A cozy 2D side-scrolling platformer for kids aged 6–10, built with **Godot 4.7** and statically typed GDScript.
Help **Wren** the fairy hop, glide and fly through nine worlds to reach the Starlight Castle.

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
- Every big flying gap has rest spots below (docks, crystal ledges, ice ledges, branches, wafers, rainbow bridges,
  cloud rests) spaced as a stairway, so running out of flight time is never a dead end.

## The levels
1. **Blossom Meadow** (sunny day): the tutorial level, with signs, a first moving platform and an optional sky route.
2. **Glowshroom Woods** (twilight forest): bouncy mushrooms, up-and-down platforms, a cave, and a cliff you fly up.
3. **Seashell Shore** (sunny beach): hop over the waves, cross piers and a drifting raft, spring up a sea cliff with
   a clam shell, and fly over the open sea.
4. **Crystal Caverns** (underground): low tunnels, an elevator pit, glowing crystal ledges and a deep chasm to fly
   across, then a spring up to the high gallery.
5. **Frosty Peaks** (snowy mountain): the ground climbs higher and higher, a snow-cushion spring up the cliff, and a
   flight over the Icy Gorge to the summit.
6. **Applewood Orchard** (autumn afternoon): hop up apple-tree branches, bounce on a pumpkin into the old apple tree,
   ride a lift and a log, then fly over the orchard valley.
7. **Sugarplum Valley** (candy land): candy-corn spikes, a marshmallow spring up the layer cake, gumdrop pillars over
   a gorge, and a flight across Sugarplum Gorge.
8. **Rainbow Falls** (waterfalls): lily pads over plunge pools, a bubble spring up the tall cliff, and a flight across
   the Great Waterfall on the way up to the clouds.
9. **Starlight Clouds** (night sky): cloud islands, big gaps to fly across, and the Starlight Castle.

## Project layout
```
autoload/        Game (level flow, saves, fades) and Audio (synth SFX + music) singletons
scripts/         Shared classes: LevelData, LevelTheme, Synth, Shapes, Fx
scenes/player/   Player (movement, dust & flight) and FairyArt (code-drawn Wren)
scenes/entities/ Pickups, enemies, hazards, platforms, checkpoint, goal, signs
scenes/level/    Level builder, TileRenderer, parallax Backdrop, Autopilot (dev tool)
scenes/ui/       Title, HUD, pause menu, victory screen
levels/          level_1.tres … level_9.tres (plain-text layouts)
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
The `theme` field picks the art style, enemies and music: `meadow`, `woods`, `beach`, `caves`, `peaks`, `orchard`,
`candy`, `falls` or `sky`.
The title screen's level menu is built from `LEVELS`, so new levels show up there automatically.

## Developer shortcuts
Pass these after `--` on the command line:
```
godot --path . -- --level 2                # jump straight into level 2
godot --path . -- --level 9 --column 120   # ...starting at tile column 120
godot --path . -- --level 1 --fly          # ...already flying
godot --headless --path . --fixed-fps 60 -- --level 2 --autoplay --quit-when-done
                                           # a bot plays the level and reports if it finished
```
All nine levels pass the autoplay check. The bot prints the column of any knockout, which helps when tuning a level.
Level 2 occasionally gets one knockout because its critters start at random positions.

### Debug console
In debug builds (running from the editor or a debug export), press **~** (the key left of 1) to open the console.
The game pauses while it is open. Release exports don't include it, so players can't open it by accident.
Type `help` to see every command. Up/Down scroll through history, Tab completes a command name, and ~ or Esc closes it.

| Command | What it does |
|---|---|
| `levels` | List the levels and which ones are unlocked |
| `level <n> [column]` (`warp`) | Warp to a level, optionally starting at a tile column |
| `restart`, `next` (`skip`), `title` | Restart, finish the level and go on, or return to the title screen |
| `god [on\|off]` | Invincibility: no damage, and falling into a pit floats Wren back up flying |
| `fly`, `infiniteflight [on\|off]` | Take off now, or make flight never run out |
| `dust <n>`, `hearts [n]` (`heal`) | Give pixie dust, or set hearts (full if no number) |
| `goto <column>` (`tp`) | Teleport to a tile column in the current level |
| `kill` | Knock Wren out (she respawns at the last lantern) |
| `unlock <count\|all>` | Set how many levels are unlocked (saved) |
| `speed <x>`, `mute`, `fps` | Game speed (0.25 to 4), mute all sound, frames-per-second readout |
| `clear`, `close` | Clear or close the console |

Active cheats (GOD, INFINITE FLIGHT, speed, FPS) are shown in the bottom-right corner while the console is closed.
Commands can also run at startup, separated by `;`:
```
godot --path . -- --console "god on; infiniteflight on; level 5 120"
```

## Code conventions
- Every declaration is statically typed. `debug/gdscript/warnings/untyped_declaration` is set to **Error**, so untyped
  code will not run.
- Collision layers: 1 world, 2 player, 3 enemies, 4 pickups.
