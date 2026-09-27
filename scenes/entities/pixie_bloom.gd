class_name PixieBloom
extends Area2D
## A magic flower that fills the pixie dust meter instantly. It closes after use and regrows.

const REGROW_TIME: float = 4.0

var _time: float = 0.0
var _cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player != null and not player.is_knocked_out():
			player.fill_dust_meter()
			_cooldown = REGROW_TIME
			Audio.sfx("bloom")
			Fx.burst(get_parent(), global_position + Vector2(0.0, -4.0), Color(1.0, 0.7, 0.9), 24, 150.0)
			return


func _draw() -> void:
	var openness: float = clampf(1.0 - _cooldown / REGROW_TIME, 0.0, 1.0)
	var ready_to_use: bool = _cooldown <= 0.0
	var head := Vector2(0.0, -4.0 + sin(_time * 2.0) * 1.0)
	# Stem and leaves.
	draw_line(Vector2(0.0, 16.0), head, Color(0.3, 0.65, 0.35), 3.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(-6.0, 9.0), Vector2(6.0, 2.5), -0.5, 12), Color(0.35, 0.75, 0.4))
	draw_colored_polygon(Shapes.ellipse(Vector2(6.0, 11.0), Vector2(5.0, 2.2), 0.5, 12), Color(0.35, 0.75, 0.4))
	if ready_to_use:
		var pulse: float = 0.5 + 0.5 * sin(_time * 4.0)
		draw_circle(head, 22.0 + pulse * 3.0, Color(1.0, 0.8, 0.95, 0.15), true, -1.0, true)
		draw_circle(head, 15.0, Color(1.0, 0.9, 0.6, 0.2), true, -1.0, true)
	# Petals open as the bloom regrows.
	var petal_length: float = lerpf(3.0, 9.0, openness)
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0 + _time * 0.4
		var petal_center := head + Vector2(cos(a), sin(a)) * petal_length * 0.8
		var color := Color(1.0, 0.62, 0.85).lerp(Color(1.0, 0.85, 0.5), float(i % 2))
		draw_colored_polygon(Shapes.ellipse(petal_center, Vector2(petal_length, 4.2), a, 12), color)
	draw_circle(head, 4.5, Color(1.0, 0.92, 0.45), true, -1.0, true)
	if ready_to_use:
		draw_colored_polygon(Shapes.star(head, 4.0, 1.5, 4, _time * 2.0), Color(1.0, 1.0, 0.95))
