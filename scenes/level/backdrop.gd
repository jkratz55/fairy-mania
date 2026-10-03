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
		"beach":
			_add_layer("beach_far", 0.05, theme, drift, true)
			_add_layer("beach_clouds", 0.12, theme, drift, false, -8.0)
			_add_layer("beach_isles", 0.2, theme, drift)
			_add_layer("beach_waves", 0.3, theme, drift, true)
			_add_layer("beach_dunes", 0.5, theme, drift)
		"caves":
			_add_layer("caves_far", 0.1, theme, drift)
			_add_layer("caves_mid", 0.25, theme, drift, true)
			_add_layer("caves_near", 0.45, theme, drift, true)
		"peaks":
			_add_layer("peaks_far", 0.05, theme, drift)
			_add_layer("peaks_clouds", 0.1, theme, drift, false, -6.0)
			_add_layer("peaks_mid", 0.25, theme, drift)
			_add_layer("peaks_near", 0.45, theme, drift)
			_add_layer("peaks_snow", 0.6, theme, drift, true)
		"orchard":
			_add_layer("orchard_far", 0.05, theme, drift, true)
			_add_layer("orchard_clouds", 0.12, theme, drift, false, -8.0)
			_add_layer("orchard_mid", 0.3, theme, drift)
			_add_layer("orchard_near", 0.5, theme, drift)
			_add_layer("orchard_leaves", 0.65, theme, drift, true)
		"candy":
			_add_layer("candy_far", 0.05, theme, drift)
			_add_layer("candy_clouds", 0.12, theme, drift, false, -8.0)
			_add_layer("candy_mid", 0.3, theme, drift)
			_add_layer("candy_near", 0.5, theme, drift)
		"falls":
			_add_layer("falls_far", 0.05, theme, drift, true)
			_add_layer("falls_clouds", 0.12, theme, drift, false, -6.0)
			_add_layer("falls_mid", 0.25, theme, drift, true)
			_add_layer("falls_near", 0.5, theme, drift, true)
		"castle":
			_add_layer("castle_far", 0.1, theme, drift, true)
			_add_layer("castle_mid", 0.3, theme, drift)
			_add_layer("castle_near", 0.55, theme, drift, true)
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


## A mountain with a jagged snow cap. Drawn again one strip over when it crosses the strip edge.
static func mountain(ci: CanvasItem, peak: Vector2, half_width: float, base_y: float, color: Color, snow: Color) -> void:
	for shift: float in [-STRIP_WIDTH, 0.0, STRIP_WIDTH]:
		var p := peak + Vector2(shift, 0.0)
		if p.x + half_width < 0.0 or p.x - half_width > STRIP_WIDTH:
			continue
		ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - half_width, base_y), p, Vector2(p.x + half_width, base_y)]), color)
		var cap: float = 0.32
		var left := p.lerp(Vector2(p.x - half_width, base_y), cap)
		var right := p.lerp(Vector2(p.x + half_width, base_y), cap)
		var dip: float = (base_y - p.y) * 0.06
		ci.draw_colored_polygon(PackedVector2Array([left, p, right, right.lerp(left, 0.25) + Vector2(0.0, dip), right.lerp(left, 0.5) - Vector2(0.0, dip), right.lerp(left, 0.75) + Vector2(0.0, dip)]), snow)


static func pine(ci: CanvasItem, base: Vector2, height: float, color: Color, snow: Color) -> void:
	ci.draw_rect(Rect2(base.x - height * 0.05, base.y - height * 0.15, height * 0.1, height * 0.15), Color(0.4, 0.3, 0.32))
	for tier: int in 3:
		var w: float = height * (0.38 - 0.09 * float(tier))
		var y: float = base.y - height * (0.12 + 0.27 * float(tier))
		var top := Vector2(base.x, y - height * 0.42)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w, y), top, Vector2(base.x + w, y)]), color)
		ci.draw_colored_polygon(PackedVector2Array([top.lerp(Vector2(base.x - w, y), 0.4), top, top.lerp(Vector2(base.x + w, y), 0.4)]), snow)


static func palm(ci: CanvasItem, base: Vector2, height: float, lean: float) -> void:
	var trunk := PackedVector2Array()
	for i: int in 7:
		var u: float = float(i) / 6.0
		trunk.append(base + Vector2(lean * u * u * height * 0.4, -u * height))
	ci.draw_polyline(trunk, Color(0.62, 0.45, 0.32), 5.0, true)
	var crown: Vector2 = trunk[trunk.size() - 1]
	for i: int in 6:
		var a: float = -PI + PI * float(i) / 5.0 + 0.15 * lean
		var tip := crown + Vector2(cos(a) * 26.0, sin(a) * 10.0 + 10.0)
		ci.draw_colored_polygon(Shapes.ellipse(crown.lerp(tip, 0.5), Vector2(15.0, 3.5), a + PI * 0.05, 12), Color(0.3, 0.62, 0.42))
	for i: int in 2:
		ci.draw_circle(crown + Vector2(-3.0 + 6.0 * float(i), 4.0), 3.0, Color(0.5, 0.36, 0.25), true, -1.0, true)


## A round fruit tree in autumn colors.
static func fruit_tree(ci: CanvasItem, base: Vector2, size: float, leaves: Color, fruit: Color) -> void:
	ci.draw_rect(Rect2(base.x - size * 0.12, base.y - size * 0.9, size * 0.24, size * 0.9), Color(0.5, 0.34, 0.26))
	for puff: Vector3 in [Vector3(0.0, -1.55, 0.62), Vector3(-0.5, -1.1, 0.5), Vector3(0.5, -1.1, 0.5)]:
		ci.draw_circle(base + Vector2(puff.x, puff.y) * size, puff.z * size, leaves, true, -1.0, true)
	for apple: Vector2 in [Vector2(-0.45, -1.05), Vector2(0.2, -1.6), Vector2(0.55, -1.0), Vector2(-0.1, -1.25)]:
		ci.draw_circle(base + apple * size, size * 0.09, fruit, true, -1.0, true)


## A lollipop on a stick with a swirl of two colors.
static func lollipop(ci: CanvasItem, base: Vector2, height: float, color: Color) -> void:
	var radius: float = height * 0.28
	var center := base + Vector2(0.0, -height + radius)
	ci.draw_rect(Rect2(base.x - 2.0, center.y, 4.0, base.y - center.y), Color(0.98, 0.97, 0.94))
	ci.draw_circle(center, radius, Color(1.0, 0.98, 0.96), true, -1.0, true)
	var swirl := PackedVector2Array()
	for i: int in 40:
		var u: float = float(i) / 39.0
		swirl.append(center + Vector2.from_angle(u * TAU * 2.5) * radius * u)
	ci.draw_polyline(swirl, color, radius * 0.32, true)


## A falling sheet of water with stripes that slide downwards.
static func waterfall(ci: CanvasItem, rect: Rect2, time: float, color: Color) -> void:
	ci.draw_rect(rect, color)
	var lanes: int = maxi(2, int(rect.size.x / 7.0))
	for lane: int in lanes:
		var x: float = rect.position.x + (float(lane) + 0.5) * rect.size.x / float(lanes)
		var speed: float = 60.0 + 30.0 * Shapes.hash01(lane, int(rect.position.x), 1)
		var offset: float = fmod(time * speed + Shapes.hash01(lane, int(rect.position.x), 2) * 40.0, 40.0)
		var y: float = rect.position.y - 40.0 + offset
		while y < rect.end.y:
			var y0: float = maxf(y, rect.position.y)
			var y1: float = minf(y + 16.0, rect.end.y)
			if y1 > y0:
				ci.draw_line(Vector2(x, y0), Vector2(x, y1), Color(1.0, 1.0, 1.0, 0.45), 1.5)
			y += 40.0
	for i: int in 4:
		var puff: float = 0.5 + 0.5 * sin(time * 3.0 + float(i) * 1.7)
		ci.draw_circle(Vector2(rect.position.x + rect.size.x * (float(i) + 0.5) / 4.0, rect.end.y), rect.size.x * 0.25 + 3.0 * puff, Color(1.0, 1.0, 1.0, 0.7), true, -1.0, true)


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
		"beach_far":
			ci.draw_circle(Vector2(300.0, 80.0), 52.0, Color(1.0, 0.95, 0.75, 0.25), true, -1.0, true)
			ci.draw_circle(Vector2(300.0, 80.0), 32.0, Color(1.0, 0.93, 0.6), true, -1.0, true)
			ci.draw_rect(Rect2(0.0, 205.0, STRIP_WIDTH, 700.0), Color(0.3, 0.68, 0.88))
			ci.draw_line(Vector2(0.0, 205.0), Vector2(STRIP_WIDTH, 205.0), Color(0.75, 0.92, 1.0), 2.0)
			# The sun's reflection shimmers on the water.
			for i: int in 34:
				var wave_pos := Vector2(Shapes.hash01(i, 11, 1) * STRIP_WIDTH, 212.0 + Shapes.hash01(i, 11, 2) * 60.0)
				var near_sun: bool = i < 10
				if near_sun:
					wave_pos.x = 300.0 + (Shapes.hash01(i, 11, 3) - 0.5) * 60.0
				var shimmer: float = 0.5 + 0.5 * sin(time * 2.0 + float(i) * 1.7)
				var length: float = 6.0 + Shapes.hash01(i, 11, 4) * 10.0
				ci.draw_line(wave_pos, wave_pos + Vector2(length, 0.0), Color(1.0, 1.0, 0.92, (0.6 if near_sun else 0.35) * shimmer), 1.5, true)
		"beach_clouds":
			for c: Vector3 in [Vector3(80.0, 60.0, 22.0), Vector3(520.0, 100.0, 26.0), Vector3(800.0, 45.0, 18.0)]:
				cloud(ci, Vector2(c.x, c.y), c.z, Color(1.0, 1.0, 1.0, 0.9))
		"beach_isles":
			var isle := Color(0.36, 0.62, 0.6)
			ci.draw_colored_polygon(Shapes.dome(Vector2(160.0, 212.0), Vector2(90.0, 26.0)), isle)
			ci.draw_colored_polygon(Shapes.dome(Vector2(700.0, 214.0), Vector2(130.0, 34.0)), isle)
			ci.draw_colored_polygon(Shapes.dome(Vector2(820.0, 214.0), Vector2(60.0, 18.0)), isle.darkened(0.08))
			# Striped lighthouse on the big island.
			var lx: float = 690.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(lx - 9.0, 184.0), Vector2(lx - 6.0, 134.0), Vector2(lx + 6.0, 134.0), Vector2(lx + 9.0, 184.0)]), Color(0.98, 0.96, 0.92))
			for band: int in 3:
				var y0: float = 140.0 + 15.0 * float(band)
				ci.draw_rect(Rect2(lx - 7.0 - float(band), y0, 14.0 + 2.0 * float(band), 6.0), Color(0.92, 0.38, 0.4))
			ci.draw_circle(Vector2(lx, 128.0), 14.0, Color(1.0, 0.95, 0.6, 0.3), true, -1.0, true)
			ci.draw_rect(Rect2(lx - 5.0, 124.0, 10.0, 10.0), Color(1.0, 0.92, 0.55))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(lx - 8.0, 124.0), Vector2(lx, 115.0), Vector2(lx + 8.0, 124.0)]), Color(0.92, 0.38, 0.4))
			# A little sailboat.
			ci.draw_colored_polygon(PackedVector2Array([Vector2(420.0, 226.0), Vector2(452.0, 226.0), Vector2(446.0, 234.0), Vector2(426.0, 234.0)]), Color(0.75, 0.45, 0.35))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(437.0, 224.0), Vector2(437.0, 194.0), Vector2(452.0, 222.0)]), Color(1.0, 1.0, 0.97))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(434.0, 224.0), Vector2(434.0, 202.0), Vector2(423.0, 222.0)]), Color(1.0, 0.8, 0.5))
		"beach_waves":
			var waves := Vector3(6.0, 10.0, 17.0)
			var phase: float = sin(time * 0.8) * 0.15
			ci.draw_colored_polygon(hill_polygon(258.0, 4.0, waves, 0.5 + phase), Color(0.38, 0.78, 0.9))
			for i: int in 24:
				var fx: float = float(i) * 42.7 + 10.0 + sin(time * 0.9 + float(i)) * 4.0
				var fy: float = hill_height(fx, 258.0, 4.0, waves, 0.5 + phase)
				ci.draw_line(Vector2(fx, fy + 2.0), Vector2(fx + 14.0, fy + 2.0), Color(1.0, 1.0, 1.0, 0.6), 2.0, true)
		"beach_dunes":
			var waves := Vector3(3.0, 5.0, 11.0)
			ci.draw_colored_polygon(hill_polygon(282.0, 12.0, waves, 1.1), Color(0.98, 0.84, 0.6))
			for i: int in 5:
				var tx: float = 90.0 + float(i) * 205.0 + Shapes.hash01(i, 13, 1) * 40.0
				var ty: float = hill_height(tx, 282.0, 12.0, waves, 1.1) + 4.0
				palm(ci, Vector2(tx, ty), 64.0 + Shapes.hash01(i, 13, 2) * 24.0, -1.0 if i % 2 == 0 else 1.0)
		"caves_far":
			var rock := Color(0.1, 0.08, 0.2)
			ci.draw_rect(Rect2(0.0, -400.0, STRIP_WIDTH, 440.0), rock)
			for i: int in 16:
				var sx: float = float(i) * 64.0 + 32.0
				var length: float = 40.0 + Shapes.hash01(i, 21, 1) * 80.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(sx - 30.0, 38.0), Vector2(sx + 30.0, 38.0), Vector2(sx + 2.0, 38.0 + length)]), rock)
			ci.draw_rect(Rect2(0.0, 250.0, STRIP_WIDTH, 700.0), rock)
			for i: int in 12:
				var gx: float = float(i) * 85.3 + 20.0
				var height: float = 30.0 + Shapes.hash01(i, 22, 1) * 70.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(gx - 26.0, 252.0), Vector2(gx, 252.0 - height), Vector2(gx + 26.0, 252.0)]), rock)
		"caves_mid":
			var rock := Color(0.15, 0.11, 0.27)
			# Pillars where stalactites and stalagmites have met.
			for i: int in 4:
				var cx: float = float(i) * 256.0 + 90.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 40.0, -300.0), Vector2(cx + 40.0, -300.0), Vector2(cx + 10.0, 150.0), Vector2(cx + 40.0, 600.0), Vector2(cx - 40.0, 600.0), Vector2(cx - 10.0, 150.0)]), rock)
			ci.draw_rect(Rect2(0.0, 272.0, STRIP_WIDTH, 700.0), rock)
			for i: int in 6:
				var gx: float = float(i) * 170.7 + 60.0
				var gy: float = 274.0
				var glow: Color = theme.accents[i % theme.accents.size()]
				var pulse: float = 0.75 + 0.25 * sin(time * 1.5 + float(i) * 1.9)
				ci.draw_circle(Vector2(gx, gy - 10.0), 30.0, Color(glow, 0.07 * pulse), true, -1.0, true)
				for k: int in 3:
					var lean: float = -0.4 + 0.4 * float(k)
					var height: float = 24.0 if k == 1 else 15.0
					var dir := Vector2(sin(lean), -cos(lean))
					var side := Vector2(-dir.y, dir.x) * 4.5
					var root := Vector2(gx - 7.0 + 7.0 * float(k), gy)
					ci.draw_colored_polygon(PackedVector2Array([root - side, root - side + dir * (height - 5.0), root + dir * height, root + side + dir * (height - 5.0), root + side]), glow.darkened(0.55))
		"caves_near":
			for i: int in 30:
				var start := Vector2(Shapes.hash01(i, 23, 1) * STRIP_WIDTH, Shapes.hash01(i, 23, 2) * 300.0)
				var rise: float = fmod(start.y - time * (8.0 + Shapes.hash01(i, 23, 3) * 10.0), 300.0)
				if rise < 0.0:
					rise += 300.0
				var mote := Vector2(start.x + sin(time * 0.7 + float(i)) * 12.0, 20.0 + rise)
				var glow: Color = theme.accents[i % theme.accents.size()]
				var flicker: float = 0.5 + 0.5 * sin(time * 2.2 + float(i) * 1.3)
				ci.draw_circle(mote, 5.0, Color(glow, 0.12 * flicker), true, -1.0, true)
				ci.draw_circle(mote, 1.5, Color(glow, 0.4 + 0.5 * flicker), true, -1.0, true)
		"peaks_far":
			ci.draw_circle(Vector2(640.0, 90.0), 46.0, Color(1.0, 0.95, 0.85, 0.25), true, -1.0, true)
			ci.draw_circle(Vector2(640.0, 90.0), 26.0, Color(1.0, 0.97, 0.88), true, -1.0, true)
			var far := Color(0.66, 0.68, 0.9)
			for m: Vector3 in [Vector3(80.0, 90.0, 150.0), Vector3(300.0, 60.0, 170.0), Vector3(520.0, 110.0, 130.0), Vector3(760.0, 50.0, 180.0), Vector3(960.0, 100.0, 140.0)]:
				mountain(ci, Vector2(m.x, m.y), m.z, 240.0, far, Color(0.96, 0.96, 1.0))
			ci.draw_rect(Rect2(0.0, 238.0, STRIP_WIDTH, 700.0), far)
		"peaks_clouds":
			for c: Vector3 in [Vector3(150.0, 110.0, 16.0), Vector3(470.0, 70.0, 12.0), Vector3(820.0, 130.0, 18.0)]:
				cloud(ci, Vector2(c.x, c.y), c.z, Color(1.0, 1.0, 1.0, 0.7))
		"peaks_mid":
			var mid := Color(0.5, 0.56, 0.8)
			for m: Vector3 in [Vector3(190.0, 130.0, 140.0), Vector3(450.0, 150.0, 120.0), Vector3(690.0, 120.0, 150.0), Vector3(930.0, 145.0, 120.0)]:
				mountain(ci, Vector2(m.x, m.y), m.z, 270.0, mid, Color(0.93, 0.95, 1.0))
			ci.draw_rect(Rect2(0.0, 268.0, STRIP_WIDTH, 700.0), mid)
		"peaks_near":
			var waves := Vector3(3.0, 5.0, 9.0)
			ci.draw_colored_polygon(hill_polygon(282.0, 14.0, waves, 0.7), Color(0.86, 0.9, 0.99))
			for i: int in 14:
				var tx: float = float(i) * 73.1 + Shapes.hash01(i, 31, 1) * 30.0
				var ty: float = hill_height(tx, 282.0, 14.0, waves, 0.7) + 6.0
				pine(ci, Vector2(tx, ty), 40.0 + Shapes.hash01(i, 31, 2) * 34.0, Color(0.25, 0.42, 0.52), Color(0.95, 0.97, 1.0))
		"peaks_snow":
			for i: int in 60:
				var start := Vector2(Shapes.hash01(i, 33, 1) * STRIP_WIDTH, Shapes.hash01(i, 33, 2) * 360.0)
				var fall: float = fmod(start.y + time * (18.0 + Shapes.hash01(i, 33, 3) * 22.0), 360.0)
				var flake := Vector2(start.x + sin(time * 0.9 + float(i) * 2.1) * 14.0, fall - 20.0)
				ci.draw_circle(flake, 1.2 + Shapes.hash01(i, 33, 4) * 1.6, Color(1.0, 1.0, 1.0, 0.8), true, -1.0, true)
		"orchard_far":
			ci.draw_circle(Vector2(260.0, 150.0), 70.0, Color(1.0, 0.9, 0.6, 0.25), true, -1.0, true)
			ci.draw_circle(Vector2(260.0, 150.0), 38.0, Color(1.0, 0.88, 0.55), true, -1.0, true)
			var far_waves := Vector3(2.0, 4.0, 7.0)
			ci.draw_colored_polygon(hill_polygon(214.0, 20.0, far_waves, 0.9), Color(0.78, 0.6, 0.66))
			# A little barn and a windmill on the far hill.
			var bx: float = 640.0
			var by: float = hill_height(bx, 214.0, 20.0, far_waves, 0.9) + 4.0
			ci.draw_rect(Rect2(bx - 18.0, by - 22.0, 36.0, 22.0), Color(0.8, 0.42, 0.42))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 22.0, by - 22.0), Vector2(bx, by - 38.0), Vector2(bx + 22.0, by - 22.0)]), Color(0.62, 0.32, 0.36))
			ci.draw_rect(Rect2(bx - 5.0, by - 12.0, 10.0, 12.0), Color(0.98, 0.9, 0.8))
			var wx: float = 760.0
			var wy: float = hill_height(wx, 214.0, 20.0, far_waves, 0.9) + 4.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(wx - 8.0, wy), Vector2(wx - 4.0, wy - 44.0), Vector2(wx + 4.0, wy - 44.0), Vector2(wx + 8.0, wy)]), Color(0.92, 0.85, 0.78))
			var hub := Vector2(wx, wy - 44.0)
			for i: int in 4:
				var dir := Vector2.from_angle(time * 0.8 + TAU * float(i) / 4.0)
				ci.draw_line(hub, hub + dir * 26.0, Color(0.6, 0.45, 0.4), 2.0, true)
				ci.draw_colored_polygon(PackedVector2Array([hub + dir * 8.0, hub + dir * 26.0, hub + dir * 26.0 + dir.orthogonal() * 7.0, hub + dir * 8.0 + dir.orthogonal() * 7.0]), Color(1.0, 0.97, 0.92, 0.9))
			ci.draw_circle(hub, 3.0, Color(0.6, 0.45, 0.4), true, -1.0, true)
		"orchard_clouds":
			for c: Vector3 in [Vector3(100.0, 60.0, 22.0), Vector3(470.0, 90.0, 26.0), Vector3(880.0, 50.0, 20.0)]:
				cloud(ci, Vector2(c.x, c.y), c.z, Color(1.0, 0.96, 0.9, 0.9))
		"orchard_mid":
			var waves := Vector3(3.0, 5.0, 11.0)
			ci.draw_colored_polygon(hill_polygon(240.0, 16.0, waves, 0.6), Color(0.88, 0.68, 0.42))
			var leaves: Array[Color] = [Color(0.95, 0.55, 0.22), Color(0.98, 0.76, 0.3), Color(0.85, 0.33, 0.25), Color(0.62, 0.66, 0.3)]
			for i: int in 8:
				var tx: float = 50.0 + float(i) * 128.0 + Shapes.hash01(i, 41, 1) * 30.0
				var ty: float = hill_height(tx, 240.0, 16.0, waves, 0.6) + 4.0
				fruit_tree(ci, Vector2(tx, ty), 26.0 + Shapes.hash01(i, 41, 2) * 8.0, leaves[i % leaves.size()], Color(0.9, 0.2, 0.22))
		"orchard_near":
			var waves := Vector3(4.0, 7.0, 13.0)
			ci.draw_colored_polygon(hill_polygon(268.0, 10.0, waves, 1.7), Color(0.8, 0.52, 0.3))
			var wood := Color(0.6, 0.4, 0.3)
			var rail := PackedVector2Array()
			for i: int in 33:
				var fx: float = float(i) * 32.0
				var fy: float = hill_height(fx, 268.0, 10.0, waves, 1.7)
				rail.append(Vector2(fx, fy - 10.0))
				if i % 2 == 0:
					ci.draw_rect(Rect2(fx - 2.5, fy - 18.0, 5.0, 20.0), wood)
			ci.draw_polyline(rail, wood, 3.0, true)
			for i: int in 6:
				var px: float = 80.0 + float(i) * 170.0 + Shapes.hash01(i, 43, 1) * 50.0
				var py: float = hill_height(px, 268.0, 10.0, waves, 1.7) + 2.0
				# Pumpkins resting in the grass.
				for k: int in 3:
					ci.draw_colored_polygon(Shapes.ellipse(Vector2(px - 4.0 + 4.0 * float(k), py - 6.0), Vector2(5.0, 6.5)), Color(0.98, 0.56, 0.2).darkened(0.08 * float(k % 2)))
				ci.draw_line(Vector2(px, py - 12.0), Vector2(px + 2.0, py - 16.0), Color(0.4, 0.55, 0.25), 2.0, true)
		"orchard_leaves":
			for i: int in 26:
				var start := Vector2(Shapes.hash01(i, 45, 1) * STRIP_WIDTH, Shapes.hash01(i, 45, 2) * 360.0)
				var fall: float = fmod(start.y + time * (16.0 + Shapes.hash01(i, 45, 3) * 18.0), 360.0)
				var leaf := Vector2(start.x + sin(time * 1.1 + float(i) * 2.3) * 24.0, fall - 20.0)
				var spin: float = time * 1.6 + float(i)
				ci.draw_colored_polygon(Shapes.ellipse(leaf, Vector2(4.0, 2.0 + absf(sin(spin)) * 1.2), spin, 10), theme.accents[i % 3])
		"candy_far":
			ci.draw_circle(Vector2(720.0, 80.0), 50.0, Color(1.0, 1.0, 0.9, 0.3), true, -1.0, true)
			ci.draw_circle(Vector2(720.0, 80.0), 30.0, Color(1.0, 0.98, 0.88), true, -1.0, true)
			# Ice-cream mountains with drippy edges.
			var flavors: Array[Color] = [Color(0.8, 0.94, 0.86), Color(1.0, 0.8, 0.87), Color(1.0, 0.95, 0.84), Color(0.8, 0.82, 1.0)]
			for i: int in 5:
				var mx: float = 100.0 + float(i) * 210.0
				var height: float = 70.0 + Shapes.hash01(i, 51, 1) * 50.0
				var flavor: Color = flavors[i % flavors.size()]
				ci.draw_colored_polygon(Shapes.dome(Vector2(mx, 240.0), Vector2(120.0, height)), flavor)
				for k: int in 7:
					var dx: float = -84.0 + 28.0 * float(k)
					var edge: float = 240.0 - height * sqrt(maxf(0.0, 1.0 - (dx / 120.0) * (dx / 120.0))) * 0.45
					ci.draw_circle(Vector2(mx + dx, edge), 12.0, flavor.darkened(0.06), true, -1.0, true)
			ci.draw_rect(Rect2(0.0, 238.0, STRIP_WIDTH, 700.0), Color(0.93, 0.78, 0.9))
		"candy_clouds":
			var puffs: Array[Vector3] = [Vector3(110.0, 60.0, 24.0), Vector3(420.0, 100.0, 20.0), Vector3(650.0, 45.0, 18.0), Vector3(900.0, 110.0, 26.0)]
			for i: int in puffs.size():
				var fluff: Color = Color(1.0, 0.82, 0.92, 0.92) if i % 2 == 0 else Color(0.82, 0.9, 1.0, 0.92)
				cloud(ci, Vector2(puffs[i].x, puffs[i].y), puffs[i].z, fluff)
		"candy_mid":
			var waves := Vector3(3.0, 6.0, 11.0)
			ci.draw_colored_polygon(hill_polygon(246.0, 16.0, waves, 0.3), Color(0.97, 0.66, 0.8))
			for i: int in 6:
				var lx: float = 70.0 + float(i) * 170.0 + Shapes.hash01(i, 53, 1) * 40.0
				if absf(lx - 600.0) < 70.0:
					continue
				var ly: float = hill_height(lx, 246.0, 16.0, waves, 0.3) + 4.0
				lollipop(ci, Vector2(lx, ly), 54.0 + Shapes.hash01(i, 53, 2) * 24.0, theme.accents[i % theme.accents.size()])
			# A gingerbread cottage with frosting on the roof.
			var gx: float = 600.0
			var gy: float = hill_height(gx, 246.0, 16.0, waves, 0.3) + 6.0
			ci.draw_rect(Rect2(gx - 24.0, gy - 30.0, 48.0, 30.0), Color(0.72, 0.46, 0.3))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(gx - 30.0, gy - 28.0), Vector2(gx, gy - 54.0), Vector2(gx + 30.0, gy - 28.0)]), Color(0.6, 0.36, 0.24))
			for k: int in 5:
				ci.draw_circle(Vector2(gx - 24.0 + 12.0 * float(k), gy - 28.0), 4.0, Color(1.0, 0.98, 0.96), true, -1.0, true)
			ci.draw_rect(Rect2(gx - 6.0, gy - 16.0, 12.0, 16.0), Color(1.0, 0.55, 0.7))
			ci.draw_circle(Vector2(gx - 15.0, gy - 18.0), 4.0, theme.accents[2], true, -1.0, true)
			ci.draw_circle(Vector2(gx + 15.0, gy - 18.0), 4.0, theme.accents[1], true, -1.0, true)
		"candy_near":
			var waves := Vector3(4.0, 7.0, 13.0)
			ci.draw_colored_polygon(hill_polygon(272.0, 10.0, waves, 1.4), Color(0.62, 0.88, 0.76))
			for i: int in 9:
				var cx: float = 40.0 + float(i) * 113.0 + Shapes.hash01(i, 55, 1) * 30.0
				var cy: float = hill_height(cx, 272.0, 10.0, waves, 1.4) + 4.0
				if i % 3 == 0:
					# Candy cane.
					var cane := PackedVector2Array([Vector2(cx, cy), Vector2(cx, cy - 30.0)])
					for k: int in 7:
						cane.append(Vector2(cx + 7.0, cy - 30.0) + Vector2.from_angle(PI + PI * float(k) / 6.0) * 7.0)
					ci.draw_polyline(cane, Color(1.0, 0.98, 0.96), 5.0, true)
					for k: int in 4:
						var sy: float = cy - 4.0 - 8.0 * float(k)
						ci.draw_line(Vector2(cx - 2.5, sy), Vector2(cx + 2.5, sy - 3.0), Color(0.92, 0.25, 0.35), 2.5, true)
				else:
					# Gumdrop.
					var drop: Color = theme.accents[i % theme.accents.size()]
					ci.draw_colored_polygon(Shapes.dome(Vector2(cx, cy), Vector2(10.0, 12.0)), drop)
					ci.draw_circle(Vector2(cx - 3.0, cy - 7.0), 2.0, Color(1.0, 1.0, 1.0, 0.6), true, -1.0, true)
		"falls_far":
			# A soft rainbow behind the cliffs.
			var bands: Array[Color] = [Color(1.0, 0.5, 0.52), Color(1.0, 0.72, 0.4), Color(1.0, 0.92, 0.45), Color(0.55, 0.88, 0.55), Color(0.5, 0.75, 1.0), Color(0.72, 0.58, 1.0)]
			for b: int in bands.size():
				ci.draw_arc(Vector2(380.0, 250.0), 200.0 - 7.0 * float(b), PI, TAU, 48, Color(bands[b], 0.35), 7.0, true)
			var cliff := Color(0.6, 0.72, 0.82)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0.0, 900.0), Vector2(0.0, 180.0), Vector2(120.0, 170.0), Vector2(260.0, 196.0), Vector2(430.0, 150.0), Vector2(600.0, 176.0), Vector2(760.0, 140.0), Vector2(900.0, 186.0), Vector2(STRIP_WIDTH, 180.0), Vector2(STRIP_WIDTH, 900.0)]), cliff)
			for f: Vector3 in [Vector3(180.0, 186.0, 10.0), Vector3(470.0, 156.0, 14.0), Vector3(800.0, 152.0, 12.0)]:
				waterfall(ci, Rect2(f.x, f.y, f.z, 250.0 - f.y), time, Color(0.82, 0.94, 1.0))
			ci.draw_rect(Rect2(0.0, 248.0, STRIP_WIDTH, 700.0), cliff.darkened(0.05))
		"falls_clouds":
			for c: Vector3 in [Vector3(90.0, 70.0, 20.0), Vector3(560.0, 50.0, 24.0), Vector3(860.0, 95.0, 18.0)]:
				cloud(ci, Vector2(c.x, c.y), c.z, Color(1.0, 1.0, 1.0, 0.85))
		"falls_mid":
			var rock := Color(0.44, 0.58, 0.64)
			var moss := Color(0.4, 0.72, 0.5)
			for c: Vector3 in [Vector3(140.0, 190.0, 110.0), Vector3(520.0, 160.0, 140.0), Vector3(870.0, 200.0, 100.0)]:
				var top: float = c.y
				ci.draw_rect(Rect2(c.x - c.z * 0.5, top, c.z, 700.0), rock)
				ci.draw_rect(Rect2(c.x - c.z * 0.5 - 4.0, top - 4.0, c.z + 8.0, 10.0), moss)
				for k: int in 4:
					ci.draw_circle(Vector2(c.x - c.z * 0.5 + c.z * float(k) / 3.0, top - 2.0), 9.0, moss, true, -1.0, true)
				waterfall(ci, Rect2(c.x - 10.0, top + 4.0, 20.0, 290.0 - top), time, Color(0.72, 0.9, 1.0))
			ci.draw_rect(Rect2(0.0, 286.0, STRIP_WIDTH, 700.0), Color(0.4, 0.66, 0.78))
		"falls_near":
			var river := Color(0.42, 0.74, 0.88)
			ci.draw_rect(Rect2(0.0, 300.0, STRIP_WIDTH, 700.0), river)
			for i: int in 20:
				var rx: float = fmod(Shapes.hash01(i, 61, 1) * STRIP_WIDTH + time * 20.0, STRIP_WIDTH)
				var ry: float = 306.0 + Shapes.hash01(i, 61, 2) * 40.0
				ci.draw_line(Vector2(rx, ry), Vector2(rx + 12.0, ry), Color(1.0, 1.0, 1.0, 0.45), 1.5, true)
			for i: int in 14:
				var reed_x: float = float(i) * 73.0 + Shapes.hash01(i, 63, 1) * 30.0
				var sway: float = sin(time * 1.4 + float(i)) * 2.0
				for k: int in 3:
					var tip := Vector2(reed_x - 5.0 + 5.0 * float(k) + sway, 272.0 + float(k % 2) * 8.0)
					ci.draw_line(Vector2(reed_x - 2.0 + 2.0 * float(k), 304.0), tip, Color(0.3, 0.55, 0.38), 2.0, true)
					if k == 1:
						ci.draw_colored_polygon(Shapes.ellipse(tip + Vector2(0.0, 5.0), Vector2(2.0, 5.0)), Color(0.5, 0.36, 0.28))
			for i: int in 16:
				var start := Vector2(Shapes.hash01(i, 65, 1) * STRIP_WIDTH, Shapes.hash01(i, 65, 2) * 300.0)
				var rise: float = fmod(start.y - time * 12.0, 300.0)
				if rise < 0.0:
					rise += 300.0
				var sparkle: float = 0.5 + 0.5 * sin(time * 2.0 + float(i) * 1.7)
				ci.draw_circle(Vector2(start.x + sin(time + float(i)) * 10.0, rise), 1.6, Color(1.0, 1.0, 1.0, 0.3 + 0.5 * sparkle), true, -1.0, true)
		"castle_far":
			# The great hall's back wall, with tall arched windows onto the night sky.
			var wall := Color(0.2, 0.15, 0.32)
			ci.draw_rect(Rect2(0.0, -400.0, STRIP_WIDTH, 1300.0), wall)
			for i: int in 4:
				var wx: float = 128.0 + 256.0 * float(i)
				var window := Rect2(wx - 44.0, 40.0, 88.0, 170.0)
				ci.draw_colored_polygon(Shapes.dome(Vector2(wx, window.position.y + 2.0), Vector2(48.0, 48.0)), Color(0.32, 0.25, 0.46))
				ci.draw_rect(window.grow(4.0), Color(0.32, 0.25, 0.46))
				ci.draw_colored_polygon(Shapes.dome(Vector2(wx, window.position.y + 2.0), Vector2(44.0, 44.0)), Color(0.12, 0.12, 0.34))
				ci.draw_rect(window, Color(0.12, 0.12, 0.34))
				for s: int in 7:
					var star := Vector2(wx - 36.0 + Shapes.hash01(i, s, 71) * 72.0, 10.0 + Shapes.hash01(i, s, 72) * 190.0)
					var twinkle: float = 0.5 + 0.5 * sin(time * (1.5 + Shapes.hash01(i, s, 73) * 2.0) + float(s))
					ci.draw_circle(star, 1.2, Color(1.0, 1.0, 0.9, 0.3 + 0.7 * twinkle), true, -1.0, true)
				if i == 1:
					ci.draw_circle(Vector2(wx + 10.0, 70.0), 16.0, Color(1.0, 0.95, 0.8), true, -1.0, true)
					ci.draw_circle(Vector2(wx + 17.0, 64.0), 14.0, Color(0.12, 0.12, 0.34), true, -1.0, true)
				# Window frame and panes.
				ci.draw_line(Vector2(wx, window.position.y - 40.0), Vector2(wx, window.end.y), Color(0.32, 0.25, 0.46), 4.0)
				ci.draw_line(Vector2(window.position.x, 120.0), Vector2(window.end.x, 120.0), Color(0.32, 0.25, 0.46), 4.0)
			ci.draw_rect(Rect2(0.0, 230.0, STRIP_WIDTH, 700.0), wall.darkened(0.15))
		"castle_mid":
			var stone := Color(0.27, 0.21, 0.4)
			for i: int in 4:
				var px: float = 64.0 + 256.0 * float(i)
				ci.draw_rect(Rect2(px - 22.0, -400.0, 44.0, 1300.0), stone)
				ci.draw_rect(Rect2(px - 28.0, 230.0, 56.0, 10.0), stone.lightened(0.1))
				ci.draw_rect(Rect2(px - 3.0, -400.0, 6.0, 1300.0), Color(1.0, 1.0, 1.0, 0.05))
				# A royal banner with a gold crescent moon.
				var bx: float = px + 128.0
				var banner := PackedVector2Array([Vector2(bx - 20.0, 30.0), Vector2(bx + 20.0, 30.0), Vector2(bx + 20.0, 150.0), Vector2(bx, 135.0), Vector2(bx - 20.0, 150.0)])
				ci.draw_rect(Rect2(bx - 26.0, 26.0, 52.0, 5.0), theme.accents[0].darkened(0.3))
				ci.draw_colored_polygon(banner, Color(0.45, 0.18, 0.5))
				ci.draw_polyline(Shapes.closed(banner), theme.accents[0].darkened(0.2), 2.0, true)
				ci.draw_circle(Vector2(bx, 80.0), 11.0, theme.accents[0], true, -1.0, true)
				ci.draw_circle(Vector2(bx + 5.0, 76.0), 10.0, Color(0.45, 0.18, 0.5), true, -1.0, true)
			ci.draw_rect(Rect2(0.0, 262.0, STRIP_WIDTH, 700.0), Color(0.18, 0.13, 0.27))
		"castle_near":
			# Drifting motes of the Queen's magic.
			for i: int in 24:
				var start := Vector2(Shapes.hash01(i, 75, 1) * STRIP_WIDTH, Shapes.hash01(i, 75, 2) * 300.0)
				var rise: float = fmod(start.y - time * (10.0 + Shapes.hash01(i, 75, 3) * 12.0), 300.0)
				if rise < 0.0:
					rise += 300.0
				var mote := Vector2(start.x + sin(time * 0.8 + float(i)) * 14.0, 10.0 + rise)
				var glow: Color = theme.accents[1 + i % 3]
				var flicker: float = 0.5 + 0.5 * sin(time * 2.0 + float(i) * 1.7)
				ci.draw_circle(mote, 5.0, Color(glow, 0.1 * flicker), true, -1.0, true)
				ci.draw_circle(mote, 1.4, Color(glow, 0.35 + 0.5 * flicker), true, -1.0, true)
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
