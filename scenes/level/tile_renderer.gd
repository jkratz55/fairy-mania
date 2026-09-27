class_name TileRenderer
extends Node2D
## Draws the level terrain ("#" ground and "=" platforms) with code.
## Split into 16-column chunks so off-screen chunks are culled by the renderer.

const TILE: int = 32
const CHUNK_COLUMNS: int = 16

var _grid: Array[String] = []
var _theme: LevelTheme
var _columns: int = 0
var _rows: int = 0


class Chunk extends Node2D:
	var renderer: TileRenderer
	var first_column: int = 0
	var last_column: int = 0

	func _draw() -> void:
		renderer.draw_chunk(self, first_column, last_column)


func build(grid: Array[String], theme: LevelTheme) -> void:
	_grid = grid
	_theme = theme
	_rows = grid.size()
	_columns = grid[0].length() if _rows > 0 else 0
	for start: int in range(0, _columns, CHUNK_COLUMNS):
		var chunk := Chunk.new()
		chunk.renderer = self
		chunk.first_column = start
		chunk.last_column = mini(start + CHUNK_COLUMNS, _columns) - 1
		add_child(chunk)


func cell(x: int, y: int) -> String:
	if y < 0 or _rows == 0:
		return "."
	return _grid[mini(y, _rows - 1)][clampi(x, 0, _columns - 1)]


func is_solid(x: int, y: int) -> bool:
	return cell(x, y) == "#"


func draw_chunk(ci: CanvasItem, first_column: int, last_column: int) -> void:
	for x: int in range(first_column, last_column + 1):
		for y: int in _rows:
			match _grid[y][x]:
				"#":
					if _theme.style == "cloud":
						_draw_cloud(ci, x, y)
					else:
						_draw_earth(ci, x, y)
				"=":
					_draw_platform(ci, x, y)
	# Decorations go on top so they can overlap neighbouring tiles.
	for x: int in range(first_column, last_column + 1):
		for y: int in _rows:
			if _grid[y][x] == "#" and not is_solid(x, y - 1) and cell(x, y - 1) != "=":
				_draw_decor(ci, x, y)


func _draw_earth(ci: CanvasItem, x: int, y: int) -> void:
	var px: float = float(x * TILE)
	var py: float = float(y * TILE)
	var t: LevelTheme = _theme
	var top_open: bool = not is_solid(x, y - 1)
	var left_open: bool = not is_solid(x - 1, y)
	var right_open: bool = not is_solid(x + 1, y)
	var bottom_open: bool = not is_solid(x, y + 1)
	ci.draw_rect(Rect2(px, py, TILE, TILE), t.fill)

	# Deeper tiles are slightly darker.
	var depth: int = 0
	while depth < 3 and is_solid(x, y - depth - 1):
		depth += 1
	if depth > 0:
		ci.draw_rect(Rect2(px, py, TILE, TILE), Color(t.fill_dark, 0.22 * float(depth)))

	for i: int in 3:
		var speck := Vector2(px + 4.0 + Shapes.hash01(x, y, i) * 24.0, py + 4.0 + Shapes.hash01(x, y, i + 7) * 24.0)
		if top_open and speck.y < py + 15.0:
			continue
		var r: float = 1.2 + Shapes.hash01(x, y, i + 3) * 1.6
		if t.style == "moss":
			ci.draw_circle(speck, r + 1.5, Color(t.speck, 0.15), true, -1.0, true)
			ci.draw_circle(speck, r * 0.7, Color(t.speck, 0.8), true, -1.0, true)
		else:
			ci.draw_circle(speck, r, t.speck, true, -1.0, true)

	if left_open:
		ci.draw_rect(Rect2(px, py, 3.0, TILE), t.fill_dark)
	if right_open:
		ci.draw_rect(Rect2(px + TILE - 3.0, py, 3.0, TILE), t.fill_dark)
	if bottom_open:
		ci.draw_rect(Rect2(px, py + TILE - 4.0, TILE, 4.0), t.fill_dark)
		if t.style == "moss":
			for i: int in 2:
				var drip_x: float = px + 6.0 + Shapes.hash01(x, y, 40 + i) * 20.0
				var drip_len: float = 4.0 + Shapes.hash01(x, y, 50 + i) * 8.0
				ci.draw_line(Vector2(drip_x, py + TILE - 2.0), Vector2(drip_x, py + TILE + drip_len), t.top_dark, 2.0, true)
				ci.draw_circle(Vector2(drip_x, py + TILE + drip_len), 1.8, Color(t.speck, 0.7), true, -1.0, true)

	if top_open:
		ci.draw_rect(Rect2(px, py, TILE, 10.0), t.top)
		ci.draw_rect(Rect2(px, py + 10.0, TILE, 3.0), t.top_dark)
		for i: int in 3:
			ci.draw_circle(Vector2(px + 5.0 + 11.0 * float(i), py + 4.0), 5.5, t.top, true, -1.0, true)
		if left_open:
			ci.draw_circle(Vector2(px + 1.0, py + 6.0), 6.0, t.top, true, -1.0, true)
		if right_open:
			ci.draw_circle(Vector2(px + TILE - 1.0, py + 6.0), 6.0, t.top, true, -1.0, true)
		ci.draw_line(Vector2(px, py + 1.0), Vector2(px + TILE, py + 1.0), Color(1.0, 1.0, 1.0, 0.18), 2.0)
		if t.style == "moss":
			for i: int in 2:
				var drip_x: float = px + 5.0 + Shapes.hash01(x, y, 20 + i) * 22.0
				var drip_len: float = 2.0 + Shapes.hash01(x, y, 30 + i) * 5.0
				ci.draw_line(Vector2(drip_x, py + 10.0), Vector2(drip_x, py + 12.0 + drip_len), t.top_dark, 3.0, true)
				ci.draw_circle(Vector2(drip_x, py + 12.0 + drip_len), 1.6, t.top_dark, true, -1.0, true)


func _draw_cloud(ci: CanvasItem, x: int, y: int) -> void:
	var px: float = float(x * TILE)
	var py: float = float(y * TILE)
	var t: LevelTheme = _theme
	var top_open: bool = not is_solid(x, y - 1)
	var left_open: bool = not is_solid(x - 1, y)
	var right_open: bool = not is_solid(x + 1, y)
	var bottom_open: bool = not is_solid(x, y + 1)
	ci.draw_rect(Rect2(px, py, TILE, TILE), t.fill)
	var depth: int = 0
	while depth < 3 and is_solid(x, y - depth - 1):
		depth += 1
	if depth > 0:
		ci.draw_rect(Rect2(px, py, TILE, TILE), Color(t.fill_dark, 0.25 * float(depth)))
	if bottom_open:
		for i: int in 3:
			ci.draw_circle(Vector2(px + 5.0 + 11.0 * float(i), py + TILE - 5.0), 7.0, t.fill_dark, true, -1.0, true)
	if left_open:
		for i: int in 2:
			ci.draw_circle(Vector2(px + 3.0, py + 9.0 + 14.0 * float(i)), 7.5, t.fill.lerp(t.fill_dark, 0.3 + 0.3 * float(i)), true, -1.0, true)
	if right_open:
		for i: int in 2:
			ci.draw_circle(Vector2(px + TILE - 3.0, py + 9.0 + 14.0 * float(i)), 7.5, t.fill.lerp(t.fill_dark, 0.3 + 0.3 * float(i)), true, -1.0, true)
	if top_open:
		ci.draw_circle(Vector2(px + 6.0, py + 7.0), 8.0, t.top, true, -1.0, true)
		ci.draw_circle(Vector2(px + 17.0, py + 4.0), 9.0, t.top, true, -1.0, true)
		ci.draw_circle(Vector2(px + 28.0, py + 7.0), 8.0, t.top, true, -1.0, true)
		ci.draw_rect(Rect2(px, py + 7.0, TILE, 6.0), t.top)
	if Shapes.hash01(x, y, 9) < 0.3 and not top_open:
		var c := Vector2(px + 8.0 + Shapes.hash01(x, y, 10) * 16.0, py + 8.0 + Shapes.hash01(x, y, 11) * 16.0)
		ci.draw_colored_polygon(Shapes.star(c, 3.0, 1.1, 4), Color(t.speck, 0.8))


func _draw_platform(ci: CanvasItem, x: int, y: int) -> void:
	var px: float = float(x * TILE)
	var py: float = float(y * TILE)
	var t: LevelTheme = _theme
	var left_end: bool = cell(x - 1, y) != "="
	var right_end: bool = cell(x + 1, y) != "="
	var x0: float = px + (5.0 if left_end else 0.0)
	var x1: float = px + TILE - (5.0 if right_end else 0.0)
	match t.style:
		"moss":
			# Mushroom-cap ledge with cream gills underneath.
			ci.draw_rect(Rect2(x0, py + 9.0, x1 - x0, 3.0), Color(0.96, 0.88, 0.82))
			ci.draw_rect(Rect2(x0, py, x1 - x0, 10.0), t.platform)
			if left_end:
				ci.draw_circle(Vector2(px + 6.0, py + 6.0), 6.0, t.platform, true, -1.0, true)
			if right_end:
				ci.draw_circle(Vector2(px + TILE - 6.0, py + 6.0), 6.0, t.platform, true, -1.0, true)
			ci.draw_circle(Vector2(px + 10.0 + Shapes.hash01(x, y, 1) * 12.0, py + 4.0), 2.2, Color(1.0, 0.95, 0.95), true, -1.0, true)
			ci.draw_line(Vector2(x0, py + 1.0), Vector2(x1, py + 1.0), Color(1.0, 1.0, 1.0, 0.3), 1.5)
		"cloud":
			# Golden star-bridge.
			ci.draw_rect(Rect2(x0, py + 1.0, x1 - x0, 9.0), t.platform)
			ci.draw_rect(Rect2(x0, py + 8.0, x1 - x0, 2.0), t.platform_dark)
			if left_end:
				ci.draw_circle(Vector2(px + 5.5, py + 5.5), 5.0, t.platform, true, -1.0, true)
			if right_end:
				ci.draw_circle(Vector2(px + TILE - 5.5, py + 5.5), 5.0, t.platform, true, -1.0, true)
			ci.draw_colored_polygon(Shapes.star(Vector2(px + 16.0, py + 5.0), 3.0, 1.2), Color(1.0, 1.0, 0.9))
			ci.draw_line(Vector2(x0, py + 2.0), Vector2(x1, py + 2.0), Color(1.0, 1.0, 1.0, 0.5), 1.5)
		_:
			# Wooden plank with a leaf at the ends.
			ci.draw_rect(Rect2(x0, py, x1 - x0, 10.0), t.platform)
			ci.draw_rect(Rect2(x0, py + 8.0, x1 - x0, 2.0), t.platform_dark)
			ci.draw_line(Vector2(x0, py + 4.5), Vector2(x1, py + 4.5), Color(t.platform_dark, 0.5), 1.0)
			ci.draw_circle(Vector2(px + 16.0, py + 5.0), 1.2, t.platform_dark, true, -1.0, true)
			if left_end:
				ci.draw_circle(Vector2(px + 5.0, py + 5.0), 5.0, t.platform, true, -1.0, true)
				ci.draw_colored_polygon(Shapes.ellipse(Vector2(px + 2.0, py - 1.0), Vector2(6.0, 2.5), -0.6, 10), t.top)
			if right_end:
				ci.draw_circle(Vector2(px + TILE - 5.0, py + 5.0), 5.0, t.platform, true, -1.0, true)
				ci.draw_colored_polygon(Shapes.ellipse(Vector2(px + TILE - 2.0, py - 1.0), Vector2(6.0, 2.5), 0.6, 10), t.top)


func _draw_decor(ci: CanvasItem, x: int, y: int) -> void:
	var roll: float = Shapes.hash01(x, y, 99)
	if roll > 0.5:
		return
	var t: LevelTheme = _theme
	var base := Vector2(float(x * TILE) + 6.0 + Shapes.hash01(x, y, 5) * 20.0, float(y * TILE) + 1.0)
	var accent: Color = t.accents[int(Shapes.hash01(x, y, 3) * 100.0) % t.accents.size()]
	match t.style:
		"grass":
			if roll < 0.22:
				var head := base + Vector2(0.0, -10.0)
				ci.draw_line(base, head, t.top_dark, 1.5, true)
				for i: int in 5:
					var a: float = TAU * float(i) / 5.0
					ci.draw_circle(head + Vector2(cos(a), sin(a)) * 2.6, 2.2, accent, true, -1.0, true)
				ci.draw_circle(head, 1.5, Color(1.0, 0.85, 0.3), true, -1.0, true)
			else:
				for i: int in 3:
					var lean: float = -3.0 + 3.0 * float(i)
					ci.draw_line(base, base + Vector2(lean, -5.0 - float(i % 2) * 3.0), t.top_dark, 1.5, true)
		"moss":
			if roll < 0.25:
				ci.draw_circle(base + Vector2(0.0, -5.0), 8.0, Color(accent, 0.2), true, -1.0, true)
				ci.draw_rect(Rect2(base.x - 1.5, base.y - 5.0, 3.0, 5.0), Color(0.95, 0.9, 0.85))
				ci.draw_colored_polygon(Shapes.dome(base + Vector2(0.0, -4.5), Vector2(5.0, 4.5), 10), accent)
			else:
				for i: int in 3:
					var lean: float = -4.0 + 4.0 * float(i)
					ci.draw_line(base, base + Vector2(lean, -7.0 + absf(lean) * 0.4), t.top_dark, 2.0, true)
		"cloud":
			if roll < 0.2:
				ci.draw_colored_polygon(Shapes.star(base + Vector2(0.0, -12.0), 3.5, 1.2, 4), Color(accent, 0.9))
