class_name Level
extends Node2D
## Builds a level from a LevelData text layout, then runs it:
## spawning, checkpoints, gentle respawns (no game over) and the goal.

const TILE: int = 32
const HALF_TILE: int = 16
const PLATFORM_THICKNESS: float = 10.0

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const DUST_SCENE: PackedScene = preload("res://scenes/entities/pixie_dust.tscn")
const HEART_SCENE: PackedScene = preload("res://scenes/entities/heart_pickup.tscn")
const BLOOM_SCENE: PackedScene = preload("res://scenes/entities/pixie_bloom.tscn")
const BLOCK_SCENE: PackedScene = preload("res://scenes/entities/bonus_block.tscn")
const WALKER_SCENE: PackedScene = preload("res://scenes/entities/walker.tscn")
const FLYER_SCENE: PackedScene = preload("res://scenes/entities/flyer.tscn")
const THORNS_SCENE: PackedScene = preload("res://scenes/entities/thorns.tscn")
const PLATFORM_SCENE: PackedScene = preload("res://scenes/entities/moving_platform.tscn")
const BOUNCER_SCENE: PackedScene = preload("res://scenes/entities/bouncer.tscn")
const CHECKPOINT_SCENE: PackedScene = preload("res://scenes/entities/checkpoint.tscn")
const GOAL_SCENE: PackedScene = preload("res://scenes/entities/goal.tscn")
const SIGN_SCENE: PackedScene = preload("res://scenes/entities/hint_sign.tscn")

## Leave empty to use the level chosen in the Game autoload.
@export var data: LevelData

var theme: LevelTheme
var grid: Array[String] = []
var columns: int = 0
var rows: int = 0
var player: Player
var respawn_point: Vector2 = Vector2.ZERO

var _finished: bool = false
var _respawning: bool = false

@onready var backdrop: Backdrop = $Backdrop
@onready var terrain: StaticBody2D = $Terrain
@onready var tiles: TileRenderer = $Tiles
@onready var entities: Node2D = $Entities
@onready var hud: Hud = $Hud
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	if data == null:
		data = Game.get_level_data()
	theme = LevelTheme.create(data.theme)
	RenderingServer.set_default_clear_color(theme.sky_bottom)
	_parse_layout(data.layout)
	backdrop.setup(theme)
	tiles.build(grid, theme)
	_build_collision()
	var start: Vector2 = _spawn_entities()
	_spawn_player(start)
	hud.bind_player(player)
	hud.show_level_title("Level %d" % (Game.current_level + 1), data.title, data.subtitle)
	Audio.play_music(data.music)


# --- Building ----------------------------------------------------------------

func _parse_layout(text: String) -> void:
	grid.clear()
	for raw_line: String in text.split("\n"):
		var line: String = raw_line.strip_edges(false, true).replace(" ", ".")
		if line.is_empty() and grid.is_empty():
			continue
		grid.append(line)
	while not grid.is_empty() and grid[grid.size() - 1].is_empty():
		grid.pop_back()
	rows = grid.size()
	columns = 0
	for line: String in grid:
		columns = maxi(columns, line.length())
	for i: int in rows:
		grid[i] = grid[i].rpad(columns, ".")


func _row_runs(y: int, tile: String) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var x: int = 0
	while x < columns:
		if grid[y][x] == tile:
			var start: int = x
			while x < columns and grid[y][x] == tile:
				x += 1
			runs.append(Vector2i(start, x - 1))
		else:
			x += 1
	return runs


## Merges solid tiles into as few rectangles as possible (row runs stacked vertically).
func _build_collision() -> void:
	var open_rects: Dictionary[Vector2i, Rect2i] = {}
	var rects: Array[Rect2i] = []
	for y: int in rows:
		var next_open: Dictionary[Vector2i, Rect2i] = {}
		for run: Vector2i in _row_runs(y, "#"):
			if open_rects.has(run):
				var grown: Rect2i = open_rects[run]
				grown.size.y += 1
				next_open[run] = grown
			else:
				next_open[run] = Rect2i(run.x, y, run.y - run.x + 1, 1)
		for run: Vector2i in open_rects.keys():
			if not next_open.has(run):
				rects.append(open_rects[run])
		open_rects = next_open
	rects.append_array(open_rects.values())

	for rect: Rect2i in rects:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(rect.size * TILE)
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = (Vector2(rect.position) + Vector2(rect.size) * 0.5) * TILE
		terrain.add_child(collider)

	for y: int in rows:
		for run: Vector2i in _row_runs(y, "="):
			var shape := RectangleShape2D.new()
			shape.size = Vector2(float((run.y - run.x + 1) * TILE), PLATFORM_THICKNESS)
			var collider := CollisionShape2D.new()
			collider.shape = shape
			collider.one_way_collision = true
			collider.position = Vector2(float(run.x + run.y + 1) * 0.5 * TILE, float(y * TILE) + PLATFORM_THICKNESS * 0.5)
			terrain.add_child(collider)


## Spawns everything in the layout (column by column, so signs are numbered left to right).
## Returns the player start position.
func _spawn_entities() -> Vector2:
	var start := Vector2(64.0, 64.0)
	var sign_index: int = 0
	for x: int in columns:
		for y: int in rows:
			var center := Vector2(x * TILE + HALF_TILE, y * TILE + HALF_TILE)
			match grid[y][x]:
				"P":
					start = center + Vector2(0.0, 4.0)
				"o":
					_spawn(DUST_SCENE, center)
				"h":
					_spawn(HEART_SCENE, center)
				"*":
					_spawn(BLOOM_SCENE, center)
				"?":
					_spawn(BLOCK_SCENE, center)
				"^":
					_spawn(THORNS_SCENE, center)
				"T":
					_spawn(BOUNCER_SCENE, center)
				"g":
					_spawn(WALKER_SCENE, center + Vector2(0.0, 8.0))
				"f", "b":
					var flyer := FLYER_SCENE.instantiate() as Flyer
					flyer.pattern = "horizontal" if grid[y][x] == "b" else "vertical"
					_add_entity(flyer, center)
				"M", "V":
					var platform := PLATFORM_SCENE.instantiate() as MovingPlatform
					platform.axis = Vector2.RIGHT if grid[y][x] == "M" else Vector2.UP
					platform.distance = 64.0
					_add_entity(platform, center)
				"C":
					var checkpoint := _spawn(CHECKPOINT_SCENE, center) as Checkpoint
					checkpoint.activated.connect(_on_checkpoint_activated)
				"G":
					var goal := _spawn(GOAL_SCENE, center) as Goal
					goal.reached.connect(_on_goal_reached)
				"S":
					var hint := SIGN_SCENE.instantiate() as HintSign
					hint.text = data.signs[sign_index] if sign_index < data.signs.size() else "..."
					sign_index += 1
					_add_entity(hint, center)
	return start


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	var node := scene.instantiate() as Node2D
	_add_entity(node, at)
	return node


func _add_entity(node: Node2D, at: Vector2) -> void:
	node.position = at
	if "theme" in node:
		node.set("theme", theme)
	entities.add_child(node)


func _spawn_player(start: Vector2) -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.position = start
	if Game.debug_start_column >= 0:
		player.position = standing_position(Game.debug_start_column)
		Game.debug_start_column = -1
	player.level_bounds = Rect2(0.0, 0.0, float(columns * TILE), float(rows * TILE))
	entities.add_child(player)
	var camera: Camera2D = player.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = columns * TILE
	camera.limit_bottom = rows * TILE
	camera.reset_smoothing()
	respawn_point = player.position
	player.knocked_out.connect(_on_player_knocked_out)
	player.flight_started.connect(_on_flight_started)
	if Game.debug_start_flying:
		Game.debug_start_flying = false
		player.fill_dust_meter.call_deferred()
	if OS.get_cmdline_user_args().has("--autoplay"):
		var autopilot := Autopilot.new()
		autopilot.level = self
		add_child(autopilot)


func is_finished() -> bool:
	return _finished


## Where Wren would stand on the highest floor in a column (debug spawns and the console's `goto`).
func standing_position(column: int) -> Vector2:
	var x: int = clampi(column, 0, columns - 1)
	for y: int in range(1, rows):
		if grid[y][x] in ["#", "="] and grid[y - 1][x] not in ["#", "="]:
			return Vector2(x * TILE + HALF_TILE, y * TILE - 12)
	return Vector2(x * TILE + HALF_TILE, 32.0)


# --- Level events -------------------------------------------------------------

func _on_checkpoint_activated(checkpoint: Checkpoint) -> void:
	respawn_point = checkpoint.spawn_position()
	hud.show_message("Checkpoint!", 1.2)


func _on_flight_started() -> void:
	hud.show_message("Fly, Wren, fly!", 1.4)


func _on_player_knocked_out() -> void:
	if _respawning:
		return
	_respawning = true
	hud.show_message("Oops! Try again!", 1.5)
	await get_tree().create_timer(1.5, false).timeout
	# Bring back collected dust so flying sections can always be retried.
	for node: Node in get_tree().get_nodes_in_group("respawnable"):
		node.call("restore")
	player.respawn(respawn_point)
	_respawning = false


func _on_goal_reached() -> void:
	if _finished or player.is_knocked_out():
		return
	_finished = true
	pause_menu.enabled = false
	player.celebrate()
	Audio.stop_music()
	Audio.sfx("goal")
	hud.show_level_complete(player.dust_total, Game.current_level + 1 >= Game.level_count())
	await get_tree().create_timer(3.5).timeout
	Game.complete_level(player.dust_total)
