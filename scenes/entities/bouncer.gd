class_name Bouncer
extends Area2D
## A springy pad. Step or land on it to bounce extra high!
## Looks like a flower (meadow), a glowing mushroom (woods) or a star spring (sky).

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
