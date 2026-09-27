class_name Autopilot
extends Node
## Developer tool: plays a level automatically to smoke-test that it can be finished.
## Run with: godot --path . -- --level 1 --autoplay   (add --headless --fixed-fps 60 for a fast run)
## It is only created when --autoplay is passed, so it never affects normal play.

const TIME_LIMIT: float = 300.0
const TILE: float = 32.0

var level: Level
var _elapsed: float = 0.0
var _next_report: float = 0.0
var _knockouts: int = 0
var _best_column: int = 0
var _done: bool = false


func _ready() -> void:
	process_physics_priority = -100  # Decide input before the player reads it.
	level.player.knocked_out.connect(func() -> void: _knockouts += 1)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var player: Player = level.player
	var column: int = int(player.global_position.x / TILE)
	_best_column = maxi(_best_column, column)

	if level.is_finished():
		_finish("FINISHED", 0)
		return
	if _elapsed >= _next_report:
		_next_report += 5.0
		print("  t=%3ds column %3d/%d (best %d) knockouts=%d dust=%d flying=%s" % [int(_elapsed), column, level.columns, _best_column, _knockouts, player.dust_total, player.is_flying])
	if _elapsed > TIME_LIMIT:
		_finish("TIMED OUT", 1)
		return

	Input.action_press("move_right")
	var want_jump: bool
	if player.is_flying:
		want_jump = player.global_position.y > 100.0
	elif player.is_on_floor():
		want_jump = _should_jump(player, column)
		if want_jump and Input.is_action_pressed("jump"):
			Input.action_release("jump")  # Release for one frame so the next press registers.
			return
	else:
		want_jump = true  # Hold jump in the air: full height, then glide.
	if want_jump:
		Input.action_press("jump")
	else:
		Input.action_release("jump")


func _should_jump(player: Player, column: int) -> bool:
	var ground_row: int = roundi((player.global_position.y + 12.0) / TILE)
	var ahead: int = column + 1
	# Wall, block or thorns right ahead (springs are walked onto).
	for row: int in [ground_row - 1, ground_row - 2]:
		if _cell(ahead, row) in ["#", "?", "^"]:
			return true
	# Gap ahead: jump from near the edge.
	var local_x: float = player.global_position.x - float(column) * TILE
	if local_x > TILE * 0.5 and not _has_floor(ahead, ground_row):
		return true
	# Critters and thorns close ahead.
	for node: Node in level.entities.get_children():
		if node is Walker or node is Flyer or node is Thorns:
			var offset: Vector2 = (node as Node2D).global_position - player.global_position
			if offset.x > 0.0 and offset.x < 64.0 and absf(offset.y) < 48.0:
				return true
	return false


func _has_floor(column: int, ground_row: int) -> bool:
	for row: int in range(ground_row, mini(ground_row + 3, level.rows)):
		if _cell(column, row) in ["#", "=", "M", "V"]:
			return true
	return false


func _cell(column: int, row: int) -> String:
	if column < 0 or column >= level.columns or row < 0 or row >= level.rows:
		return "."
	return level.grid[row][column]


func _finish(result: String, exit_code: int) -> void:
	_done = true
	Input.action_release("move_right")
	Input.action_release("jump")
	print("AUTOPILOT %s: level %d in %ds, best column %d/%d, knockouts=%d, dust=%d" % [result, Game.current_level + 1, int(_elapsed), _best_column, level.columns, _knockouts, level.player.dust_total])
	if exit_code != 0 or OS.get_cmdline_user_args().has("--quit-when-done"):
		get_tree().quit(exit_code)
