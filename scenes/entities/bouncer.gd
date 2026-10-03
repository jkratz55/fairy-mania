class_name Bouncer
extends Area2D
## A springy pad. Step or land on it to bounce extra high!
## Looks like a flower (meadow), a glowing mushroom (woods), a clam shell (beach),
## a crystal pad (caves), a snow cushion (peaks), a pumpkin (orchard), a marshmallow (candy),
## a water bubble (falls) or a star spring (sky).

const STRENGTH: float = -760.0

var theme: LevelTheme
var _time: float = 0.0
var _boing: float = 0.0


func _ready() -> void:
	if theme == null:
		theme = LevelTheme.create("meadow")


func _physics_process(delta: float) -> void:
	_time += delta
	_boing = move_toward(_boing, 0.0, delta * 3.0)
	queue_redraw()
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.velocity.y >= 0.0 and player.global_position.y < global_position.y + 8.0 and not player.is_flying:
			player.spring(STRENGTH)
			_boing = 1.0
			Audio.sfx("spring")
			Fx.burst(get_parent(), global_position + Vector2(0.0, -4.0), theme.accents[0], 10, 80.0)


func _draw() -> void:
	# Springy wobble after a bounce.
	var squash: float = 1.0 - sin(_boing * PI * 3.0) * _boing * 0.35
	var top_y: float = lerpf(16.0, 0.0, squash)
	var coil := PackedVector2Array()
	for i: int in 7:
		var y: float = lerpf(16.0, top_y, float(i) / 6.0)
		coil.append(Vector2(-5.0 if i % 2 == 0 else 5.0, y))
	var pad := Vector2(0.0, top_y)
	match theme.style:
		"moss":
			draw_circle(pad, 20.0, Color(theme.accents[0], 0.15), true, -1.0, true)
			draw_rect(Rect2(-4.0, top_y, 8.0, 16.0 - top_y), Color(0.9, 0.85, 0.8))
			var cap: PackedVector2Array = Shapes.dome(pad + Vector2(0.0, 2.0), Vector2(15.0, 10.0 * squash))
			draw_colored_polygon(cap, theme.accents[0])
			draw_polyline(Shapes.closed(cap), theme.top_dark, 1.2, true)
			for spot: Vector2 in [Vector2(-7.0, -2.0), Vector2(2.0, -6.0), Vector2(8.0, -1.0)]:
				draw_circle(pad + Vector2(spot.x, spot.y * squash), 1.8, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)
		"sand":
			draw_polyline(coil, Color(0.55, 0.45, 0.4), 2.5, true)
			var shell: Color = theme.accents[0]
			var base_shell: PackedVector2Array = Shapes.ellipse(Vector2(0.0, 14.0), Vector2(14.0, 3.5), 0.0, 16)
			draw_colored_polygon(base_shell, shell.darkened(0.15))
			var fan: PackedVector2Array = Shapes.dome(pad + Vector2(0.0, 2.0), Vector2(14.0, 11.0 * squash), 14)
			draw_colored_polygon(fan, shell)
			draw_polyline(Shapes.closed(fan), shell.darkened(0.3), 1.2, true)
			for i: int in 5:
				var a: float = PI + PI * (float(i) + 1.0) / 6.0
				draw_line(pad + Vector2(0.0, 2.0), pad + Vector2(0.0, 2.0) + Vector2(cos(a) * 12.0, sin(a) * 9.5 * squash), shell.darkened(0.2), 1.0, true)
			draw_circle(pad + Vector2(0.0, 1.0), 3.0, Color(1.0, 0.98, 0.95), true, -1.0, true)
		"crystal":
			draw_polyline(coil, Color(0.5, 0.45, 0.7), 2.5, true)
			var gem: Color = theme.accents[0]
			var glow: float = 0.15 + 0.1 * sin(_time * 3.0)
			draw_circle(pad + Vector2(0.0, -3.0), 20.0, Color(gem, glow), true, -1.0, true)
			var diamond := PackedVector2Array([pad + Vector2(-14.0, -3.0), pad + Vector2(-7.0, -9.0 * squash), pad + Vector2(7.0, -9.0 * squash), pad + Vector2(14.0, -3.0), pad + Vector2(0.0, 5.0)])
			draw_colored_polygon(diamond, gem)
			draw_polyline(Shapes.closed(diamond), gem.darkened(0.4), 1.2, true)
			draw_line(pad + Vector2(-14.0, -3.0), pad + Vector2(14.0, -3.0), Color(gem.darkened(0.25), 0.8), 1.0, true)
			draw_colored_polygon(Shapes.star(pad + Vector2(-4.0, -6.0 * squash), 3.0, 0.9, 4), Color.WHITE)
		"snow":
			draw_polyline(coil, Color(0.6, 0.75, 0.9), 2.5, true)
			var cushion: PackedVector2Array = Shapes.ellipse(pad + Vector2(0.0, -1.0), Vector2(15.0, 6.5 * squash + 1.0), 0.0, 20)
			draw_colored_polygon(cushion, theme.top)
			draw_polyline(Shapes.closed(cushion), theme.top_dark, 1.2, true)
			for i: int in 3:
				draw_circle(pad + Vector2(-8.0 + 8.0 * float(i), -5.0 * squash), 4.0, theme.top, true, -1.0, true)
			draw_colored_polygon(Shapes.star(pad + Vector2(0.0, -2.0), 4.0, 1.2, 6), theme.platform_dark)
		"leaf":
			draw_polyline(coil, Color(0.4, 0.58, 0.28), 2.5, true)
			var pumpkin: Color = theme.accents[2]
			for k: int in [0, 2, 1]:
				var lobe: PackedVector2Array = Shapes.ellipse(pad + Vector2(-7.0 + 7.0 * float(k), -2.0), Vector2(7.5, 8.0 * squash + 1.0), 0.0, 16)
				draw_colored_polygon(lobe, pumpkin.darkened(0.12 if k != 1 else 0.0))
				draw_polyline(Shapes.closed(lobe), pumpkin.darkened(0.35), 1.0, true)
			var stem_top := pad + Vector2(1.5, -10.0 * squash - 5.0)
			draw_line(pad + Vector2(0.0, -8.0 * squash), stem_top, Color(0.42, 0.52, 0.25), 3.0, true)
			draw_colored_polygon(Shapes.ellipse(stem_top + Vector2(5.0, 2.0), Vector2(4.5, 2.0), 0.4, 10), Color(0.48, 0.66, 0.3))
			draw_circle(pad + Vector2(-3.0, -5.0 * squash), 1.6, Color(1.0, 1.0, 1.0, 0.4), true, -1.0, true)
		"frosting":
			draw_polyline(coil, theme.accents[0], 2.5, true)
			var puff: PackedVector2Array = Shapes.ellipse(pad + Vector2(0.0, -2.0), Vector2(14.0, 7.0 * squash + 2.0), 0.0, 20)
			draw_rect(Rect2(-14.0, pad.y - 2.0, 28.0, 6.0), Color(0.96, 0.93, 0.95))
			draw_colored_polygon(puff, Color(1.0, 0.98, 1.0))
			draw_polyline(Shapes.closed(puff), Color(0.88, 0.8, 0.88), 1.2, true)
			draw_arc(pad + Vector2(0.0, -2.0), 5.0, 0.0, PI * 1.6, 14, theme.accents[0], 2.0, true)
			draw_circle(pad + Vector2(-6.0, -4.0 * squash), 1.8, Color(1.0, 1.0, 1.0, 0.9), true, -1.0, true)
		"falls":
			draw_colored_polygon(Shapes.ellipse(Vector2(0.0, 14.0), Vector2(13.0, 3.5), 0.0, 16), theme.fill_dark)
			draw_line(Vector2(0.0, 14.0), pad, Color(0.7, 0.9, 1.0, 0.8), 6.0, true)
			var bubble_center := pad + Vector2(0.0, -6.0 * squash)
			var bubble: PackedVector2Array = Shapes.ellipse(bubble_center, Vector2(12.0 + (1.0 - squash) * 6.0, 9.0 * squash + 1.0), 0.0, 20)
			draw_colored_polygon(bubble, Color(0.6, 0.86, 1.0, 0.55))
			draw_polyline(Shapes.closed(bubble), Color(0.85, 0.96, 1.0), 1.5, true)
			draw_circle(bubble_center + Vector2(-5.0, -3.0 * squash), 2.5, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)
		"cloud":
			draw_polyline(coil, Color(0.8, 0.8, 0.95), 2.5, true)
			var star: PackedVector2Array = Shapes.star(pad + Vector2(0.0, -4.0), 11.0, 5.0)
			draw_colored_polygon(star, theme.platform)
			draw_polyline(Shapes.closed(star), theme.platform_dark, 1.2, true)
		_:
			draw_polyline(coil, Color(0.3, 0.6, 0.3), 2.5, true)
			var petals: PackedVector2Array = Shapes.ellipse(pad, Vector2(15.0, 5.0), 0.0, 18)
			draw_colored_polygon(petals, Color(1.0, 0.55, 0.7))
			draw_polyline(Shapes.closed(petals), Color(0.8, 0.3, 0.5), 1.2, true)
			draw_colored_polygon(Shapes.ellipse(pad + Vector2(0.0, -1.0), Vector2(7.0, 2.5), 0.0, 12), Color(1.0, 0.9, 0.45))
	# A little arrow hint that bobs above the spring.
	var hint_y: float = top_y - 16.0 + sin(_time * 4.0) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(-4.0, hint_y + 3.0), Vector2(0.0, hint_y - 2.0), Vector2(4.0, hint_y + 3.0)]), Color(1.0, 1.0, 1.0, 0.6))
