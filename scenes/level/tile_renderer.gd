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
	_draw_pits(ci, first_column, last_column)
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
		match t.style:
			"moss":
				ci.draw_circle(speck, r + 1.5, Color(t.speck, 0.15), true, -1.0, true)
				ci.draw_circle(speck, r * 0.7, Color(t.speck, 0.8), true, -1.0, true)
			"crystal":
				if i == 0 and Shapes.hash01(x, y, 60) < 0.45:
					ci.draw_circle(speck, r + 3.0, Color(t.speck, 0.12), true, -1.0, true)
					ci.draw_colored_polygon(Shapes.star(speck, r + 1.6, r * 0.5, 4), Color(t.speck, 0.85))
				else:
					ci.draw_circle(speck, r * 0.6, Color(t.top_dark, 0.8), true, -1.0, true)
			"frosting":
				# Rainbow sprinkles baked into the cake.
				var tilt := Vector2.from_angle(Shapes.hash01(x, y, i + 11) * PI) * 2.5
				ci.draw_line(speck - tilt, speck + tilt, t.accents[(x + y + i) % t.accents.size()], 2.0, true)
			"falls":
				ci.draw_colored_polygon(Shapes.ellipse(speck, Vector2(r + 1.5, r * 0.8), Shapes.hash01(x, y, i + 11), 10), t.speck)
			_:
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
		elif t.style == "crystal":
			# Stalactites hang from cave ceilings and overhangs.
			for i: int in 2:
				var tip_x: float = px + 8.0 + 16.0 * float(i) + (Shapes.hash01(x, y, 40 + i) - 0.5) * 6.0
				var tip_len: float = 6.0 + Shapes.hash01(x, y, 50 + i) * 12.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tip_x - 5.0, py + TILE - 2.0), Vector2(tip_x + 5.0, py + TILE - 2.0), Vector2(tip_x, py + TILE + tip_len)]), t.fill_dark)
				ci.draw_circle(Vector2(tip_x, py + TILE + tip_len - 2.0), 1.4, Color(t.speck, 0.8), true, -1.0, true)
		elif t.style == "snow":
			for i: int in 3:
				var tip_x: float = px + 6.0 + 10.0 * float(i) + (Shapes.hash01(x, y, 40 + i) - 0.5) * 4.0
				var tip_len: float = 3.0 + Shapes.hash01(x, y, 50 + i) * 8.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tip_x - 2.5, py + TILE - 2.0), Vector2(tip_x + 2.5, py + TILE - 2.0), Vector2(tip_x, py + TILE + tip_len)]), Color(t.platform, 0.9))
		elif t.style == "leaf":
			# Little roots poke out under overhangs.
			for i: int in 2:
				var root_x: float = px + 7.0 + 16.0 * float(i) + (Shapes.hash01(x, y, 40 + i) - 0.5) * 6.0
				var root_len: float = 5.0 + Shapes.hash01(x, y, 50 + i) * 8.0
				ci.draw_polyline(PackedVector2Array([Vector2(root_x, py + TILE - 2.0), Vector2(root_x + 2.0, py + TILE + root_len * 0.5), Vector2(root_x - 1.0, py + TILE + root_len)]), t.fill_dark, 1.6, true)
		elif t.style == "falls":
			# Trickles of water drip from mossy overhangs.
			for i: int in 2:
				var drip_x: float = px + 8.0 + 16.0 * float(i) + (Shapes.hash01(x, y, 40 + i) - 0.5) * 6.0
				var drip_len: float = 4.0 + Shapes.hash01(x, y, 50 + i) * 9.0
				ci.draw_line(Vector2(drip_x, py + TILE - 2.0), Vector2(drip_x, py + TILE + drip_len), t.top_dark, 2.0, true)
				ci.draw_circle(Vector2(drip_x, py + TILE + drip_len + 2.0), 1.5, Color(0.7, 0.9, 1.0, 0.9), true, -1.0, true)

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
		elif t.style == "sand":
			# Wind ripples in the sand.
			for i: int in 2:
				var ripple_x: float = px + 4.0 + Shapes.hash01(x, y, 20 + i) * 16.0
				ci.draw_line(Vector2(ripple_x, py + 6.0 + 3.0 * float(i)), Vector2(ripple_x + 8.0, py + 5.0 + 3.0 * float(i)), Color(t.top_dark, 0.6), 1.0, true)
		elif t.style == "snow":
			# Snow lies thick on top and sparkles.
			ci.draw_rect(Rect2(px, py + 10.0, TILE, 3.0), t.top)
			ci.draw_rect(Rect2(px, py + 13.0, TILE, 2.0), t.top_dark)
			if Shapes.hash01(x, y, 21) < 0.4:
				ci.draw_colored_polygon(Shapes.star(Vector2(px + 6.0 + Shapes.hash01(x, y, 22) * 20.0, py + 6.0), 2.5, 0.8, 4), Color(t.platform, 0.9))
		elif t.style == "leaf":
			# Fallen leaves scattered on the path.
			for i: int in 3:
				var leaf := Vector2(px + 4.0 + Shapes.hash01(x, y, 20 + i) * 24.0, py + 3.0 + Shapes.hash01(x, y, 30 + i) * 6.0)
				var color: Color = t.accents[int(Shapes.hash01(x, y, 23 + i) * 3.0) % 3]
				ci.draw_colored_polygon(Shapes.ellipse(leaf, Vector2(3.5, 1.8), Shapes.hash01(x, y, 26 + i) * PI, 8), color)
		elif t.style == "frosting":
			# Frosting drips over the side of the cake, topped with sprinkles.
			for i: int in 2:
				var drip_x: float = px + 6.0 + 14.0 * float(i) + Shapes.hash01(x, y, 20 + i) * 6.0
				var drip_len: float = 3.0 + Shapes.hash01(x, y, 30 + i) * 7.0
				ci.draw_rect(Rect2(drip_x - 2.5, py + 10.0, 5.0, drip_len), t.top)
				ci.draw_circle(Vector2(drip_x, py + 10.0 + drip_len), 2.5, t.top, true, -1.0, true)
			for i: int in 3:
				var sprinkle := Vector2(px + 4.0 + Shapes.hash01(x, y, 24 + i) * 24.0, py + 3.0 + Shapes.hash01(x, y, 27 + i) * 4.0)
				var tilt := Vector2.from_angle(Shapes.hash01(x, y, 33 + i) * PI) * 1.8
				ci.draw_line(sprinkle - tilt, sprinkle + tilt, t.accents[(x + i) % t.accents.size()], 1.6, true)


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
		"sand":
			# Wooden dock planks on posts that reach down into the sea.
			if left_end or right_end or x % 3 == 1:
				var post_x: float = px + (8.0 if left_end else (TILE - 14.0 if right_end else 13.0))
				var post_bottom: float = float(_rows * TILE)
				for below: int in range(y + 1, _rows):
					if is_solid(x, below):
						post_bottom = float(below * TILE)
						break
				ci.draw_rect(Rect2(post_x, py + 8.0, 6.0, post_bottom - py - 8.0), t.platform_dark)
				ci.draw_rect(Rect2(post_x + 1.0, py + 8.0, 1.5, post_bottom - py - 8.0), Color(t.platform, 0.5))
			ci.draw_rect(Rect2(x0, py, x1 - x0, 10.0), t.platform)
			ci.draw_rect(Rect2(x0, py + 8.0, x1 - x0, 2.0), t.platform_dark)
			for seam: int in [0, 1]:
				var seam_x: float = px + 10.0 + 12.0 * float(seam)
				if seam_x > x0 and seam_x < x1:
					ci.draw_line(Vector2(seam_x, py + 1.0), Vector2(seam_x, py + 8.0), Color(t.platform_dark, 0.7), 1.0)
			ci.draw_circle(Vector2(px + 5.0, py + 4.0), 0.9, t.platform_dark, true, -1.0, true)
			ci.draw_line(Vector2(x0, py + 1.0), Vector2(x1, py + 1.0), Color(1.0, 1.0, 1.0, 0.25), 1.5)
		"crystal":
			# A ledge of glowing crystal with angled ends.
			var a: float = x0 - (4.0 if left_end else 0.0)
			var b: float = x1 + (4.0 if right_end else 0.0)
			var slab := PackedVector2Array([
				Vector2(a + (5.0 if left_end else 0.0), py), Vector2(b - (5.0 if right_end else 0.0), py),
				Vector2(b, py + 5.0), Vector2(b - (5.0 if right_end else 0.0), py + 11.0),
				Vector2(a + (5.0 if left_end else 0.0), py + 11.0), Vector2(a, py + 5.0)])
			ci.draw_rect(Rect2(x0, py - 6.0, x1 - x0, 22.0), Color(t.platform, 0.08))
			ci.draw_colored_polygon(slab, t.platform)
			ci.draw_line(Vector2(a + 4.0, py + 5.0), Vector2(b - 4.0, py + 5.0), Color(t.platform_dark, 0.6), 1.0)
			ci.draw_line(Vector2(x0, py + 2.0), Vector2(x1, py + 2.0), Color(1.0, 1.0, 1.0, 0.55), 1.5)
			if Shapes.hash01(x, y, 1) < 0.5:
				ci.draw_colored_polygon(Shapes.star(Vector2(px + 8.0 + Shapes.hash01(x, y, 2) * 16.0, py + 3.0), 3.0, 0.9, 4), Color(1.0, 1.0, 1.0, 0.9))
		"snow":
			# An icy ledge with a snow cap and little icicles.
			ci.draw_rect(Rect2(x0, py + 3.0, x1 - x0, 8.0), t.platform)
			ci.draw_rect(Rect2(x0, py + 9.0, x1 - x0, 2.0), t.platform_dark)
			ci.draw_rect(Rect2(x0, py, x1 - x0, 4.0), t.top)
			for i: int in 3:
				ci.draw_circle(Vector2(px + 5.0 + 11.0 * float(i), py + 2.0), 3.0, t.top, true, -1.0, true)
			for i: int in 2:
				var tip_x: float = px + 9.0 + 14.0 * float(i)
				var tip_len: float = 3.0 + Shapes.hash01(x, y, 5 + i) * 6.0
				if tip_x > x0 + 2.0 and tip_x < x1 - 2.0:
					ci.draw_colored_polygon(PackedVector2Array([Vector2(tip_x - 2.0, py + 10.0), Vector2(tip_x + 2.0, py + 10.0), Vector2(tip_x, py + 10.0 + tip_len)]), t.platform)
		"leaf":
			# A tree branch with tufts of autumn leaves.
			ci.draw_rect(Rect2(x0, py + 1.0, x1 - x0, 9.0), t.platform)
			ci.draw_rect(Rect2(x0, py + 7.0, x1 - x0, 3.0), t.platform_dark)
			ci.draw_line(Vector2(x0 + 2.0, py + 4.0), Vector2(x1 - 2.0, py + 4.5), Color(t.platform_dark, 0.6), 1.0)
			if left_end:
				ci.draw_circle(Vector2(px + 5.5, py + 5.5), 4.5, t.platform, true, -1.0, true)
			if right_end:
				ci.draw_circle(Vector2(px + TILE - 5.5, py + 5.5), 4.5, t.platform, true, -1.0, true)
			for i: int in 3:
				var leaf := Vector2(px + 4.0 + 12.0 * float(i), py + 1.0 + Shapes.hash01(x, y, 4 + i) * 2.0)
				ci.draw_colored_polygon(Shapes.ellipse(leaf, Vector2(4.5, 2.2), -0.4 + Shapes.hash01(x, y, 7 + i) * 0.8, 8), t.accents[(x + i) % 3])
			if Shapes.hash01(x, y, 10) < 0.3:
				var apple := Vector2(px + 16.0, py + 15.0)
				ci.draw_line(Vector2(px + 16.0, py + 9.0), apple + Vector2(0.0, -4.0), t.platform_dark, 1.2)
				ci.draw_circle(apple, 4.0, t.accents[0], true, -1.0, true)
				ci.draw_circle(apple + Vector2(-1.5, -1.5), 1.2, Color(1.0, 1.0, 1.0, 0.5), true, -1.0, true)
		"frosting":
			# A wafer cookie with a layer of cream.
			ci.draw_rect(Rect2(x0, py, x1 - x0, 11.0), t.platform)
			ci.draw_rect(Rect2(x0, py + 4.0, x1 - x0, 3.0), Color(1.0, 0.9, 0.95))
			ci.draw_rect(Rect2(x0, py + 9.0, x1 - x0, 2.0), t.platform_dark)
			for k: int in 4:
				var seam_x: float = px + 4.0 + 8.0 * float(k)
				if seam_x > x0 + 1.0 and seam_x < x1 - 1.0:
					ci.draw_line(Vector2(seam_x, py), Vector2(seam_x, py + 4.0), Color(t.platform_dark, 0.7), 1.0)
					ci.draw_line(Vector2(seam_x, py + 7.0), Vector2(seam_x, py + 9.0), Color(t.platform_dark, 0.7), 1.0)
			ci.draw_line(Vector2(x0, py + 1.0), Vector2(x1, py + 1.0), Color(1.0, 1.0, 1.0, 0.4), 1.5)
		"falls":
			# A rainbow bridge.
			var stripes: Array[Color] = [Color(1.0, 0.5, 0.52), Color(1.0, 0.75, 0.4), Color(1.0, 0.93, 0.45), Color(0.55, 0.88, 0.55), Color(0.5, 0.75, 1.0), Color(0.72, 0.58, 1.0)]
			for k: int in stripes.size():
				ci.draw_rect(Rect2(x0, py + 1.7 * float(k), x1 - x0, 1.8), stripes[k])
				if left_end:
					ci.draw_circle(Vector2(x0, py + 1.7 * float(k) + 0.9), 1.2, stripes[k], true, -1.0, true)
				if right_end:
					ci.draw_circle(Vector2(x1, py + 1.7 * float(k) + 0.9), 1.2, stripes[k], true, -1.0, true)
			ci.draw_line(Vector2(x0, py + 0.5), Vector2(x1, py + 0.5), Color(1.0, 1.0, 1.0, 0.6), 1.0)
			if Shapes.hash01(x, y, 1) < 0.4:
				ci.draw_colored_polygon(Shapes.star(Vector2(px + 8.0 + Shapes.hash01(x, y, 2) * 16.0, py - 3.0), 2.5, 0.8, 4), Color(1.0, 1.0, 1.0, 0.9))
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
		"sand":
			if roll < 0.12:
				# Scallop shell.
				var shell: PackedVector2Array = Shapes.dome(base + Vector2(0.0, 2.0), Vector2(5.0, 6.0), 10)
				ci.draw_colored_polygon(shell, accent)
				for i: int in 3:
					ci.draw_line(base + Vector2(0.0, 1.0), base + Vector2(-3.0 + 3.0 * float(i), -3.0), accent.darkened(0.25), 1.0, true)
			elif roll < 0.2:
				var arm: float = Shapes.hash01(x, y, 6) * 0.6
				ci.draw_colored_polygon(Shapes.star(base + Vector2(0.0, -1.0), 5.0, 2.2, 5, -PI / 2.0 + arm), t.accents[0])
				ci.draw_circle(base + Vector2(0.0, -1.0), 1.0, Color(1.0, 0.85, 0.75), true, -1.0, true)
			elif roll < 0.34:
				for i: int in 3:
					var lean: float = -4.0 + 4.0 * float(i)
					ci.draw_line(base, base + Vector2(lean * 1.4, -9.0 + absf(lean) * 0.6), Color(0.62, 0.72, 0.38), 1.5, true)
		"crystal":
			if roll < 0.3:
				# A cluster of glowing crystals.
				ci.draw_circle(base + Vector2(0.0, -6.0), 11.0, Color(accent, 0.14), true, -1.0, true)
				for i: int in 3:
					var lean: float = (-0.45 + 0.45 * float(i))
					var height: float = 7.0 + Shapes.hash01(x, y, 10 + i) * 8.0 + (3.0 if i == 1 else 0.0)
					var dir := Vector2(sin(lean), -cos(lean))
					var side := Vector2(-dir.y, dir.x) * 2.5
					var root := base + Vector2(-3.0 + 3.0 * float(i), 1.0)
					var tip := root + dir * height
					var prism := PackedVector2Array([root - side, root - side + dir * (height - 3.0), tip, root + side + dir * (height - 3.0), root + side])
					ci.draw_colored_polygon(prism, accent)
					ci.draw_line(root, tip, Color(1.0, 1.0, 1.0, 0.45), 1.0, true)
			elif roll < 0.4:
				ci.draw_colored_polygon(Shapes.ellipse(base + Vector2(0.0, -1.0), Vector2(4.0, 2.5), 0.0, 10), t.top_dark)
		"snow":
			if roll < 0.12:
				# Little snowy pine.
				ci.draw_rect(Rect2(base.x - 1.0, base.y - 3.0, 2.0, 3.0), Color(0.45, 0.32, 0.3))
				for tier: int in 3:
					var w: float = 7.0 - 2.0 * float(tier)
					var ty: float = base.y - 3.0 - 5.0 * float(tier)
					ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w, ty), Vector2(base.x, ty - 8.0), Vector2(base.x + w, ty)]), Color(0.22, 0.48, 0.5))
					ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w * 0.4, ty - 4.8), Vector2(base.x, ty - 8.0), Vector2(base.x + w * 0.4, ty - 4.8)]), t.top)
			elif roll < 0.22:
				# Snowdrop flower.
				var head := base + Vector2(2.0, -9.0)
				ci.draw_polyline(PackedVector2Array([base, base + Vector2(0.0, -7.0), head]), Color(0.35, 0.62, 0.45), 1.2, true)
				ci.draw_colored_polygon(Shapes.ellipse(head + Vector2(0.0, 2.5), Vector2(2.0, 3.0), 0.0, 10), Color.WHITE)
				ci.draw_circle(head + Vector2(0.0, 5.0), 0.9, accent, true, -1.0, true)
			elif roll < 0.3:
				ci.draw_colored_polygon(Shapes.star(base + Vector2(0.0, -3.0), 3.5, 1.0, 6), Color(t.platform, 0.95))
		"leaf":
			if roll < 0.1:
				# A little pumpkin.
				for k: int in 3:
					ci.draw_colored_polygon(Shapes.ellipse(base + Vector2(-3.0 + 3.0 * float(k), -4.5), Vector2(3.8, 4.8), 0.0, 12), t.accents[2].darkened(0.1 * float(k % 2)))
				ci.draw_line(base + Vector2(0.0, -9.0), base + Vector2(1.5, -12.0), Color(0.4, 0.55, 0.25), 1.6, true)
			elif roll < 0.2:
				# A spotted toadstool.
				ci.draw_rect(Rect2(base.x - 1.5, base.y - 5.0, 3.0, 5.0), Color(0.97, 0.92, 0.85))
				ci.draw_colored_polygon(Shapes.dome(base + Vector2(0.0, -4.5), Vector2(5.0, 4.5), 10), t.accents[0])
				ci.draw_circle(base + Vector2(-1.5, -6.5), 1.0, Color.WHITE, true, -1.0, true)
			elif roll < 0.34:
				# A pile of leaves.
				for k: int in 4:
					var leaf := base + Vector2(-5.0 + 3.5 * float(k), -2.0 - float(k % 2) * 2.0)
					ci.draw_colored_polygon(Shapes.ellipse(leaf, Vector2(4.0, 2.0), -0.5 + 0.35 * float(k), 8), t.accents[(k + int(roll * 10.0)) % 3])
		"frosting":
			if roll < 0.1:
				var pop: Color = accent
				ci.draw_line(base, base + Vector2(0.0, -10.0), Color(1.0, 0.98, 0.95), 1.6, true)
				ci.draw_circle(base + Vector2(0.0, -13.0), 4.5, pop, true, -1.0, true)
				ci.draw_arc(base + Vector2(0.0, -13.0), 2.5, 0.0, PI * 1.5, 10, Color(1.0, 1.0, 1.0, 0.8), 1.2, true)
			elif roll < 0.24:
				# Gumdrop.
				ci.draw_colored_polygon(Shapes.dome(base + Vector2(0.0, 1.0), Vector2(4.5, 6.0), 10), accent)
				ci.draw_circle(base + Vector2(-1.5, -2.5), 1.0, Color(1.0, 1.0, 1.0, 0.7), true, -1.0, true)
			elif roll < 0.3:
				# Peppermint candy.
				ci.draw_circle(base + Vector2(0.0, -3.5), 4.0, Color.WHITE, true, -1.0, true)
				for k: int in 3:
					var a: float = TAU * float(k) / 3.0
					ci.draw_colored_polygon(PackedVector2Array([base + Vector2(0.0, -3.5), base + Vector2(0.0, -3.5) + Vector2.from_angle(a) * 4.0, base + Vector2(0.0, -3.5) + Vector2.from_angle(a + 0.9) * 4.0]), Color(0.95, 0.3, 0.4))
		"falls":
			if roll < 0.12:
				# A fern.
				for k: int in 5:
					var lean: float = -1.0 + 0.5 * float(k)
					var tip := base + Vector2(lean * 8.0, -9.0 + absf(lean) * 4.0)
					ci.draw_line(base, tip, t.top_dark, 1.6, true)
					ci.draw_circle(tip, 1.4, t.top_dark, true, -1.0, true)
			elif roll < 0.22:
				# A small flower.
				var head := base + Vector2(0.0, -8.0)
				ci.draw_line(base, head, t.top_dark, 1.2, true)
				for k: int in 4:
					ci.draw_circle(head + Vector2.from_angle(TAU * float(k) / 4.0 + 0.4) * 2.2, 1.8, accent, true, -1.0, true)
				ci.draw_circle(head, 1.2, Color(1.0, 0.95, 0.6), true, -1.0, true)
			elif roll < 0.3:
				ci.draw_colored_polygon(Shapes.ellipse(base + Vector2(0.0, -1.5), Vector2(4.5, 2.5), 0.0, 10), t.fill_dark.lightened(0.2))


## Makes bottomless gaps easy to spot: sea water on the beach, a misty crevasse on the peaks,
## a dark chasm in the caves, a plunge pool at the falls and a deep gorge in the candy valley.
## Other themes leave gaps open to the backdrop.
func _draw_pits(ci: CanvasItem, first_column: int, last_column: int) -> void:
	var bottom: float = float(_rows * TILE)
	for x: int in range(first_column, last_column + 1):
		if is_solid(x, _rows - 1):
			continue
		var px: float = float(x * TILE)
		match _theme.style:
			"sand":
				var surface: float = bottom - 76.0
				var water := Color(0.24, 0.62, 0.85)
				ci.draw_rect(Rect2(px, surface, TILE, 76.0), water)
				ci.draw_rect(Rect2(px, surface + 30.0, TILE, 46.0), Color(0.16, 0.45, 0.72))
				for i: int in 2:
					ci.draw_circle(Vector2(px + 8.0 + 16.0 * float(i), surface + 1.0), 7.0, water, true, -1.0, true)
					ci.draw_line(Vector2(px + 3.0 + 16.0 * float(i), surface - 3.0), Vector2(px + 12.0 + 16.0 * float(i), surface - 3.0), Color(1.0, 1.0, 1.0, 0.55), 2.0, true)
				if Shapes.hash01(x, 0, 77) < 0.5:
					ci.draw_line(Vector2(px + 6.0, surface + 18.0), Vector2(px + 20.0, surface + 18.0), Color(1.0, 1.0, 1.0, 0.25), 1.5, true)
			"falls":
				var pool: float = bottom - 70.0
				var foam := Color(1.0, 1.0, 1.0, 0.6)
				ci.draw_rect(Rect2(px, pool, TILE, 70.0), Color(0.3, 0.66, 0.84))
				ci.draw_rect(Rect2(px, pool + 26.0, TILE, 44.0), Color(0.2, 0.5, 0.74))
				for i: int in 3:
					ci.draw_circle(Vector2(px + 5.0 + 11.0 * float(i), pool), 5.0, foam, true, -1.0, true)
				_draw_fade(ci, Rect2(px, pool - 60.0, TILE, 60.0), Color(1.0, 1.0, 1.0, 0.35))
			"frosting":
				_draw_fade(ci, Rect2(px, bottom - 130.0, TILE, 130.0), Color(0.42, 0.22, 0.4))
			"snow":
				_draw_fade(ci, Rect2(px, bottom - 150.0, TILE, 150.0), Color(0.22, 0.27, 0.52))
			"crystal":
				_draw_fade(ci, Rect2(px, bottom - 130.0, TILE, 130.0), Color(0.03, 0.02, 0.08))


## A rectangle that fades from clear at the top to `color` at the bottom.
func _draw_fade(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	var clear := Color(color, 0.0)
	ci.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([clear, clear, color, color]))
