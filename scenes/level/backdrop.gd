class_name Backdrop
extends Node2D
## A sky gradient plus parallax layers, all drawn in code, for each environment.
## Layer content is drawn in a repeating strip of STRIP_WIDTH pixels.

const STRIP_WIDTH: float = 1024.0


class Layer extends Node2D:
	var kind: String = ""
	var theme: LevelTheme
	var animated: bool = false
	var _time: float = 0.0

	func _process(delta: float) -> void:
		if animated:
			_time += delta
			queue_redraw()

	func _draw() -> void:
		Backdrop.draw_layer(self, kind, theme, _time)


## `drift` makes the layers scroll by themselves (used on menus, where there is no camera movement).
func setup(theme: LevelTheme, drift: bool = false) -> void:
	_add_sky(theme)
	match theme.id:
		"woods":
			_add_layer("woods_far", 0.1, theme, drift)
			_add_layer("woods_mid", 0.3, theme, drift)
			_add_layer("woods_near", 0.5, theme, drift, true)
		"sky":
			_add_layer("sky_far", 0.05, theme, drift, true)
			_add_layer("sky_banks", 0.15, theme, drift)
			_add_layer("sky_mid", 0.3, theme, drift)
			_add_layer("sky_wisps", 0.5, theme, drift, false, -10.0)
		_:
			_add_layer("meadow_far", 0.1, theme, drift)
			_add_layer("meadow_clouds", 0.15, theme, drift, false, -8.0)
			_add_layer("meadow_mid", 0.3, theme, drift)
			_add_layer("meadow_near", 0.5, theme, drift)


func _add_sky(theme: LevelTheme) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -100
	add_child(layer)
	var gradient := Gradient.new()
	gradient.set_color(0, theme.sky_top)
	gradient.set_color(1, theme.sky_bottom)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 8
	texture.height = 128
	var rect := TextureRect.new()
	rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)


func _add_layer(kind: String, factor: float, theme: LevelTheme, drift: bool, animated: bool = false, autoscroll: float = 0.0) -> void:
	var parallax := Parallax2D.new()
	parallax.scroll_scale = Vector2(factor, factor * 0.35)
	parallax.repeat_size = Vector2(STRIP_WIDTH, 0.0)
	parallax.repeat_times = 3
	parallax.autoscroll = Vector2(autoscroll - (60.0 * factor if drift else 0.0), 0.0)
	add_child(parallax)
	var layer := Layer.new()
	layer.kind = kind
	layer.theme = theme
	layer.animated = animated
	parallax.add_child(layer)


## A seamless wavy hill band: sine waves with whole-number cycles across the strip.
static func hill_polygon(base_y: float, amplitude: float, waves: Vector3, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps: int = 64
	for i: int in steps + 1:
		var u: float = float(i) / float(steps)
		var y: float = base_y
		y += sin(u * TAU * waves.x + phase) * amplitude
		y += sin(u * TAU * waves.y + phase * 2.0) * amplitude * 0.5
		y += sin(u * TAU * waves.z + phase * 3.0) * amplitude * 0.25
		points.append(Vector2(u * STRIP_WIDTH, y))
	points.append(Vector2(STRIP_WIDTH, 900.0))
	points.append(Vector2(0.0, 900.0))
	return points


static func hill_height(x: float, base_y: float, amplitude: float, waves: Vector3, phase: float) -> float:
	var u: float = x / STRIP_WIDTH
	return base_y + sin(u * TAU * waves.x + phase) * amplitude + sin(u * TAU * waves.y + phase * 2.0) * amplitude * 0.5 + sin(u * TAU * waves.z + phase * 3.0) * amplitude * 0.25


static func cloud(ci: CanvasItem, at: Vector2, size: float, color: Color) -> void:
	var puffs: Array[Vector3] = [Vector3(-1.0, 0.2, 0.55), Vector3(-0.35, -0.25, 0.75), Vector3(0.4, -0.1, 0.65), Vector3(1.0, 0.25, 0.5), Vector3(0.0, 0.3, 0.6)]
	for p: Vector3 in puffs:
		ci.draw_circle(at + Vector2(p.x, p.y) * size, p.z * size, color, true, -1.0, true)


static func draw_layer(ci: CanvasItem, kind: String, theme: LevelTheme, time: float) -> void:
	match kind:
		"meadow_far":
			ci.draw_circle(Vector2(780.0, 70.0), 44.0, Color(1.0, 0.97, 0.8, 0.3), true, -1.0, true)
			ci.draw_circle(Vector2(780.0, 70.0), 28.0, Color(1.0, 0.96, 0.75), true, -1.0, true)
			ci.draw_colored_polygon(hill_polygon(200.0, 22.0, Vector3(2.0, 5.0, 9.0), 0.4), Color(0.66, 0.84, 0.82))
		"meadow_clouds":
			for c: Vector3 in [Vector3(120.0, 70.0, 26.0), Vector3(420.0, 40.0, 20.0), Vector3(690.0, 110.0, 30.0), Vector3(930.0, 55.0, 18.0)]:
				cloud(ci, Vector2(c.x, c.y), c.z, Color(1.0, 1.0, 1.0, 0.92))
		"meadow_mid":
			var waves := Vector3(3.0, 4.0, 11.0)
			ci.draw_colored_polygon(hill_polygon(236.0, 18.0, waves, 1.3), Color(0.58, 0.82, 0.48))
			for i: int in 7:
				var tx: float = 60.0 + float(i) * 146.0
				var ty: float = hill_height(tx, 236.0, 18.0, waves, 1.3)
				ci.draw_rect(Rect2(tx - 3.0, ty - 22.0, 6.0, 24.0), Color(0.55, 0.4, 0.3))
				for puff: Vector3 in [Vector3(0.0, -34.0, 15.0), Vector3(-10.0, -26.0, 11.0), Vector3(10.0, -26.0, 11.0)]:
					ci.draw_circle(Vector2(tx + puff.x, ty + puff.y), puff.z, Color(0.42, 0.7, 0.38), true, -1.0, true)
		"meadow_near":
			var waves := Vector3(4.0, 7.0, 13.0)
			ci.draw_colored_polygon(hill_polygon(262.0, 12.0, waves, 2.1), Color(0.44, 0.72, 0.38))
			for i: int in 40:
				var fx: float = float(i) * 25.6 + 8.0
				var fy: float = hill_height(fx, 262.0, 12.0, waves, 2.1) + 8.0 + Shapes.hash01(i, 1, 2) * 20.0
				ci.draw_circle(Vector2(fx, fy), 2.2, theme.accents[i % theme.accents.size()], true, -1.0, true)
		"woods_far":
			ci.draw_circle(Vector2(820.0, 80.0), 40.0, Color(1.0, 0.95, 0.85, 0.15), true, -1.0, true)
			ci.draw_circle(Vector2(820.0, 80.0), 24.0, Color(1.0, 0.96, 0.88), true, -1.0, true)
			ci.draw_circle(Vector2(812.0, 74.0), 5.0, Color(0.92, 0.88, 0.85), true, -1.0, true)
			var far_color := Color(0.2, 0.14, 0.36)
			for i: int in 12:
				var tx: float = float(i) * 85.3 + Shapes.hash01(i, 0, 1) * 30.0
				var height: float = 120.0 + Shapes.hash01(i, 0, 2) * 80.0
				ci.draw_rect(Rect2(tx - 6.0, 260.0 - height, 12.0, height + 600.0), far_color)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 30.0, 280.0 - height * 0.6), Vector2(tx, 240.0 - height), Vector2(tx + 30.0, 280.0 - height * 0.6)]), far_color)
			ci.draw_rect(Rect2(0.0, 240.0, STRIP_WIDTH, 700.0), far_color)
		"woods_mid":
			var trunk := Color(0.26, 0.17, 0.36)
			for i: int in 6:
				var tx: float = float(i) * 170.0 + 40.0
				ci.draw_rect(Rect2(tx, 60.0, 22.0, 800.0), trunk)
			for i: int in 5:
				var mx: float = float(i) * 205.0 + 120.0
				var my: float = 250.0 - Shapes.hash01(i, 5, 5) * 40.0
				var glow: Color = theme.accents[i % theme.accents.size()]
				ci.draw_circle(Vector2(mx, my - 20.0), 46.0, Color(glow, 0.12), true, -1.0, true)
				ci.draw_rect(Rect2(mx - 6.0, my - 20.0, 12.0, 700.0), Color(0.5, 0.42, 0.58))
				ci.draw_colored_polygon(Shapes.dome(Vector2(mx, my - 18.0), Vector2(32.0, 26.0)), glow.darkened(0.35))
				for s: int in 3:
					ci.draw_circle(Vector2(mx - 14.0 + float(s) * 14.0, my - 30.0 + float(s % 2) * 6.0), 3.0, Color(1.0, 1.0, 1.0, 0.5), true, -1.0, true)
			ci.draw_rect(Rect2(0.0, 262.0, STRIP_WIDTH, 700.0), Color(0.2, 0.13, 0.28))
		"woods_near":
			var fern := Color(0.14, 0.1, 0.22)
			for i: int in 18:
				var fx: float = float(i) * 57.0 + Shapes.hash01(i, 9, 9) * 20.0
				for k: int in 5:
					var lean: float = -1.0 + 0.5 * float(k)
					ci.draw_line(Vector2(fx, 300.0), Vector2(fx + lean * 22.0, 262.0 + absf(lean) * 16.0), fern, 5.0, true)
			ci.draw_rect(Rect2(0.0, 290.0, STRIP_WIDTH, 700.0), fern)
			for i: int in 26:
				var base := Vector2(Shapes.hash01(i, 3, 1) * STRIP_WIDTH, 40.0 + Shapes.hash01(i, 3, 2) * 220.0)
				var drift := Vector2(sin(time * 0.6 + float(i)) * 22.0, cos(time * 0.8 + float(i) * 1.3) * 14.0)
				var glow: float = 0.5 + 0.5 * sin(time * 2.5 + float(i) * 2.0)
				ci.draw_circle(base + drift, 6.0, Color(1.0, 0.95, 0.5, 0.15 * glow), true, -1.0, true)
				ci.draw_circle(base + drift, 1.8, Color(1.0, 0.98, 0.7, 0.4 + 0.6 * glow), true, -1.0, true)
		"sky_far":
			for i: int in 80:
				var star_pos := Vector2(Shapes.hash01(i, 7, 1) * STRIP_WIDTH, Shapes.hash01(i, 7, 2) * 230.0)
				var twinkle: float = 0.5 + 0.5 * sin(time * (1.0 + Shapes.hash01(i, 7, 3) * 3.0) + float(i))
				var r: float = 0.8 + Shapes.hash01(i, 7, 4) * 1.4
				ci.draw_circle(star_pos, r, Color(1.0, 1.0, 0.9, 0.3 + 0.7 * twinkle), true, -1.0, true)
			ci.draw_circle(Vector2(760.0, 70.0), 36.0, Color(1.0, 0.95, 0.8, 0.12), true, -1.0, true)
			ci.draw_circle(Vector2(760.0, 70.0), 22.0, Color(1.0, 0.95, 0.8), true, -1.0, true)
			ci.draw_circle(Vector2(770.0, 63.0), 19.0, theme.sky_top.lerp(theme.sky_bottom, 0.12), true, -1.0, true)
			# Starlight Castle on the horizon.
			var castle := Color(0.4, 0.33, 0.6)
			var cx: float = 420.0
			ci.draw_rect(Rect2(cx - 40.0, 180.0, 80.0, 80.0), castle)
			for tower: Vector3 in [Vector3(-44.0, 150.0, 16.0), Vector3(0.0, 130.0, 20.0), Vector3(44.0, 150.0, 16.0)]:
				ci.draw_rect(Rect2(cx + tower.x - tower.z * 0.5, tower.y, tower.z, 120.0), castle)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + tower.x - tower.z * 0.7, tower.y), Vector2(cx + tower.x, tower.y - 26.0), Vector2(cx + tower.x + tower.z * 0.7, tower.y)]), Color(0.55, 0.42, 0.75))
				ci.draw_circle(Vector2(cx + tower.x, tower.y + 14.0), 2.5, Color(1.0, 0.88, 0.5), true, -1.0, true)
			ci.draw_rect(Rect2(cx - 6.0, 230.0, 12.0, 30.0), Color(1.0, 0.85, 0.5, 0.8))
		"sky_banks":
			for i: int in 9:
				cloud(ci, Vector2(float(i) * 120.0 + 30.0, 262.0 + Shapes.hash01(i, 2, 2) * 20.0), 44.0 + Shapes.hash01(i, 2, 3) * 20.0, Color(1.0, 0.76, 0.82, 0.85))
			ci.draw_rect(Rect2(0.0, 280.0, STRIP_WIDTH, 700.0), Color(1.0, 0.76, 0.82, 0.85))
		"sky_mid":
			for i: int in 7:
				cloud(ci, Vector2(float(i) * 150.0 + 70.0, 300.0 + Shapes.hash01(i, 4, 2) * 16.0), 40.0 + Shapes.hash01(i, 4, 3) * 16.0, Color(0.82, 0.76, 0.98))
			ci.draw_rect(Rect2(0.0, 312.0, STRIP_WIDTH, 700.0), Color(0.82, 0.76, 0.98))
		"sky_wisps":
			for c: Vector3 in [Vector3(80.0, 120.0, 14.0), Vector3(380.0, 60.0, 11.0), Vector3(640.0, 150.0, 16.0), Vector3(900.0, 90.0, 12.0)]:
				cloud(ci, Vector2(c.x, c.y), c.z, Color(1.0, 1.0, 1.0, 0.55))
