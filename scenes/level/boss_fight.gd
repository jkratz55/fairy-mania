class_name BossFight
extends Node
## Runs the final battle. When Wren walks into the arena the camera locks, the boss music starts
## and Queen Nightshade attacks. Wren can't hurt the Queen; she has to touch the Magic Mirror
## behind her. Cracks stay even after a knockout, so every try makes progress.
## When the mirror shatters, the Queen loses her power and flies away, and the castle brightens.

const SPEAKER: String = "Queen Nightshade"
## The castle is dim while the Queen's spell is on it.
const GLOOM := Color(0.7, 0.64, 0.86)

var level: Level
var queen: FairyQueen
var mirror: MagicMirror
## Left edge of the arena in pixels.
var arena_left: float = 0.0

var _fighting: bool = false
var _met_before: bool = false
var _won: bool = false
var _gloom: CanvasModulate


func _ready() -> void:
	# She flies anywhere between the arena's left edge and the mirror, staying above the floor.
	var floor_y: float = level.standing_position(int(arena_left / Level.TILE) + 2).y + 12.0
	queen.player = level.player
	queen.mirror = mirror
	queen.guard_point = queen.global_position
	queen.arena = Rect2(arena_left + 24.0, 40.0, mirror.global_position.x - 64.0 - arena_left, floor_y - 76.0)
	mirror.queen = queen
	mirror.arena_side = signf(queen.global_position.x - mirror.global_position.x)
	mirror.cracked.connect(_on_mirror_cracked)
	mirror.shattered.connect(_on_mirror_shattered)
	level.player.knocked_out.connect(_on_player_knocked_out)
	level.respawned.connect(_on_player_respawned)
	queen.fled.connect(_on_queen_fled)
	_gloom = CanvasModulate.new()
	_gloom.color = GLOOM
	level.add_child(_gloom)


func _physics_process(_delta: float) -> void:
	var player: Player = level.player
	if _fighting or _won or player.is_knocked_out():
		return
	if player.global_position.x > arena_left + 48.0:
		_begin()


func _begin() -> void:
	_fighting = true
	_lock_arena(true)
	Audio.play_music("boss")
	level.hud.show_boss_bar("Magic Mirror", MagicMirror.HITS_TO_BREAK, MagicMirror.HITS_TO_BREAK - mirror.hits)
	queen.begin()
	if _met_before:
		level.hud.show_dialogue(SPEAKER, ["Back again? My mirror will never break!", "You again? Ha! Try and catch me!"].pick_random(), 2.5)
		return
	_met_before = true
	level.hud.show_dialogue(SPEAKER, "So, little Wren, you made it to MY castle!", 2.6)
	await get_tree().create_timer(3.2, false).timeout
	if _fighting and mirror.hits == 0:
		level.hud.show_dialogue(SPEAKER, "As long as my Magic Mirror shines, nobody can stop me! Ha ha ha!", 3.0)


## Keeps the camera (and Wren) inside the arena during the fight.
func _lock_arena(locked: bool) -> void:
	var player: Player = level.player
	var full := Rect2(0.0, 0.0, float(level.columns * Level.TILE), float(level.rows * Level.TILE))
	player.camera.limit_left = int(arena_left) if locked else 0
	player.level_bounds = Rect2(arena_left, 0.0, full.end.x - arena_left, full.size.y) if locked else full


func _clear_bolts() -> void:
	for bolt: Node in get_tree().get_nodes_in_group("magic_bolts"):
		(bolt as MagicBolt).pop()


func _on_mirror_cracked(hits: int) -> void:
	_clear_bolts()
	queen.on_mirror_cracked(hits)
	level.hud.set_boss_bar(MagicMirror.HITS_TO_BREAK - hits)
	level.hud.show_message("Crack!", 0.8)
	var lines: Array[String] = ["My mirror! Get away from it!", "No, no, NO! Leave my mirror alone!"]
	level.hud.show_dialogue(SPEAKER, lines[clampi(hits - 1, 0, lines.size() - 1)], 2.4)


func _on_mirror_shattered() -> void:
	_won = true
	_fighting = false
	_clear_bolts()
	level.hud.set_boss_bar(0)
	level.hud.show_message("The mirror broke!", 1.6)
	queen.lose_power()
	level.player.controls_enabled = false
	Audio.stop_music()
	await get_tree().create_timer(1.0, false).timeout
	level.hud.show_dialogue(SPEAKER, "My magic... it's all gone! You haven't seen the last of... oh, bother.", 3.6)


func _on_queen_fled() -> void:
	level.hud.hide_boss_bar()
	# The Queen's spell lifts and the castle fills with light again.
	var tween := create_tween()
	tween.tween_property(_gloom, "color", Color.WHITE, 2.0)
	var view: Rect2 = level.get_viewport().get_canvas_transform().affine_inverse() * level.get_viewport().get_visible_rect()
	for i: int in 8:
		var at := Vector2(randf_range(view.position.x + 40.0, view.end.x - 40.0), randf_range(view.position.y + 40.0, view.end.y - 120.0))
		Fx.burst(level.entities, at, [Color(1.0, 0.85, 0.4), Color(1.0, 0.6, 0.85), Color(0.6, 0.9, 1.0)].pick_random(), 24, 150.0)
	Audio.sfx("bloom")
	level.player.controls_enabled = true
	level.complete("You saved the fairy world!", "The Magic Mirror is broken and the Queen's spell is gone.")


func _on_player_knocked_out() -> void:
	if _won:
		return
	_fighting = false
	queen.reset()
	_clear_bolts()


func _on_player_respawned() -> void:
	if _won:
		return
	_lock_arena(false)
	level.hud.hide_boss_bar()
	Audio.play_music(level.data.music)
