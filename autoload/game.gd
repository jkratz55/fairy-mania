extends Node
## Global game flow: level order, saved progress and fade transitions between scenes.

const LEVELS: Array[String] = [
	"res://levels/level_1.tres",
	"res://levels/level_2.tres",
	"res://levels/level_3.tres",
	"res://levels/level_4.tres",
	"res://levels/level_5.tres",
	"res://levels/level_6.tres",
	"res://levels/level_7.tres",
	"res://levels/level_8.tres",
	"res://levels/level_9.tres",
]
const LEVEL_SCENE: String = "res://scenes/level/level.tscn"
const TITLE_SCENE: String = "res://scenes/ui/title_screen.tscn"
const VICTORY_SCENE: String = "res://scenes/ui/victory_screen.tscn"
const SAVE_PATH: String = "user://progress.cfg"
const FADE_TIME: float = 0.35

var current_level: int = 0
var unlocked_levels: int = 1
## Pixie dust collected during this play session (shown on the victory screen).
var session_dust: int = 0
## Debug helper: start the next level at this tile column (set with `-- --column N`).
var debug_start_column: int = -1
## Debug helper: start the next level already flying (set with `-- --fly`).
var debug_start_flying: bool = false
## Debug cheat (console `god`): Wren takes no damage and floats back up out of pits.
var debug_invincible: bool = false
## Debug cheat (console `infiniteflight`): flight never runs out.
var debug_infinite_flight: bool = false

var _fade_rect: ColorRect
var _transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_progress()
	_build_fade_layer()
	_apply_command_line.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)


func get_level_data() -> LevelData:
	return load(LEVELS[current_level]) as LevelData


func level_count() -> int:
	return LEVELS.size()


func is_level_unlocked(index: int) -> bool:
	return index < unlocked_levels


## Sets how many levels are unlocked and saves it (used by the debug console).
func unlock_levels(count: int) -> void:
	unlocked_levels = clampi(count, 1, LEVELS.size())
	_save_progress()


func start_level(index: int) -> void:
	current_level = clampi(index, 0, LEVELS.size() - 1)
	if current_level == 0:
		session_dust = 0
	change_scene(LEVEL_SCENE)


func restart_level() -> void:
	change_scene(LEVEL_SCENE)


func complete_level(dust: int) -> void:
	session_dust += dust
	unlocked_levels = clampi(maxi(unlocked_levels, current_level + 2), 1, LEVELS.size())
	_save_progress()
	if current_level + 1 < LEVELS.size():
		start_level(current_level + 1)
	else:
		change_scene(VICTORY_SCENE)


func go_to_title() -> void:
	change_scene(TITLE_SCENE)


func change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	var fade_out := create_tween()
	fade_out.tween_property(_fade_rect, "color:a", 1.0, FADE_TIME)
	await fade_out.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "color:a", 0.0, FADE_TIME)
	_transitioning = false


func _build_fade_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.16, 0.1, 0.25, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)


## Developer shortcuts: `godot -- --level 2 --column 40 --fly` jumps straight into a level.
func _apply_command_line() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var level: int = -1
	debug_start_flying = args.has("--fly")
	for i: int in args.size() - 1:
		if args[i] == "--level":
			level = int(args[i + 1]) - 1
		elif args[i] == "--column":
			debug_start_column = int(args[i + 1])
	if level >= 0:
		current_level = clampi(level, 0, LEVELS.size() - 1)
		get_tree().change_scene_to_file(LEVEL_SCENE)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		unlocked_levels = clampi(int(config.get_value("progress", "unlocked_levels", 1)), 1, LEVELS.size())


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "unlocked_levels", unlocked_levels)
	config.save(SAVE_PATH)
