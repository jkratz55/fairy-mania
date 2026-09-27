class_name Goal
extends Area2D
## The Moonflower Gate at the end of every level: a flowering arch around a swirling portal.
## Its trigger zone reaches all the way up the screen, so flying over the gate still counts.

signal reached

var _time: float = 0.0
var _reached: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _reached or body is not Player:
		return
	_reached = true
	for i: int in 3:
		Fx.burst(get_parent(), global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-60.0, -10.0)), Color(1.0, 0.8, 0.95), 26, 180.0)
	reached.emit()


func _draw() -> void:
	var portal_center := Vector2(0.0, -30.0)
	# A soft beam of light rising into the sky, so kids can spot the goal while flying.
	var beam := PackedVector2Array([Vector2(-20.0, -60.0), Vector2(20.0, -60.0), Vector2(30.0, -700.0), Vector2(-30.0, -700.0)])
	var beam_alpha: float = 0.1 + 0.04 * sin(_time * 2.0)
	draw_polygon(beam, PackedColorArray([Color(1.0, 0.95, 0.8, beam_alpha), Color(1.0, 0.95, 0.8, beam_alpha), Color(1.0, 0.9, 1.0, 0.0), Color(1.0, 0.9, 1.0, 0.0)]))
	# Glowing portal with drifting rings.
	draw_circle(portal_center, 44.0, Color(1.0, 0.9, 0.7, 0.12), true, -1.0, true)
	draw_colored_polygon(Shapes.ellipse(portal_center, Vector2(20.0, 38.0), 0.0, 28), Color(0.75, 0.6, 1.0, 0.55))
	for i: int in 4:
		var phase: float = fmod(_time * 0.6 + float(i) * 0.25, 1.0)
		var ring: PackedVector2Array = Shapes.ellipse(portal_center, Vector2(20.0, 38.0) * (1.0 - phase), 0.0, 24)
		draw_polyline(Shapes.closed(ring), Color(1.0, 0.95, 1.0, 0.6 * phase), 1.5, true)
	# Vine arch.
	var vine := Color(0.3, 0.62, 0.35)
	var arch := PackedVector2Array()
	for i: int in 21:
		var a: float = PI + PI * float(i) / 20.0
		arch.append(Vector2(0.0, -46.0) + Vector2(cos(a) * 24.0, sin(a) * 26.0))
	draw_line(Vector2(-24.0, 16.0), Vector2(-24.0, -46.0), vine, 4.0, true)
	draw_line(Vector2(24.0, 16.0), Vector2(24.0, -46.0), vine, 4.0, true)
	draw_polyline(arch, vine, 4.0, true)
	# Flowers along the arch and posts.
	var colors: Array[Color] = [Color(1.0, 0.6, 0.8), Color(1.0, 0.95, 0.6), Color(0.8, 0.7, 1.0), Color(1.0, 1.0, 1.0)]
	var spots := PackedVector2Array([Vector2(-24.0, 8.0), Vector2(24.0, -4.0), Vector2(-24.0, -20.0), Vector2(24.0, -30.0), Vector2(-24.0, -42.0)])
	for i: int in range(0, 21, 4):
		spots.append(arch[i])
	for i: int in spots.size():
		var p: Vector2 = spots[i]
		var sway: float = sin(_time * 2.0 + float(i)) * 0.3
		for k: int in 5:
			var a: float = TAU * float(k) / 5.0 + sway
			draw_circle(p + Vector2(cos(a), sin(a)) * 3.2, 2.6, colors[i % colors.size()], true, -1.0, true)
		draw_circle(p, 1.8, Color(1.0, 0.85, 0.35), true, -1.0, true)
	# Twinkles.
	for i: int in 5:
		var a: float = _time * 0.8 + TAU * float(i) / 5.0
		var twinkle := portal_center + Vector2(cos(a) * 30.0, sin(a * 1.3) * 44.0)
		draw_colored_polygon(Shapes.star(twinkle, 3.5, 1.2, 4, _time), Color(1.0, 1.0, 0.9, 0.8))
