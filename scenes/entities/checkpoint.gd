class_name Checkpoint
extends Area2D
## A fairy lantern. Touch it to light it - if Wren gets knocked out she comes back here.

signal activated(checkpoint: Checkpoint)

var is_active: bool = false
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func spawn_position() -> Vector2:
	return global_position + Vector2(0.0, 4.0)


func _on_body_entered(body: Node2D) -> void:
	if is_active or body is not Player:
		return
	is_active = true
	Audio.sfx("checkpoint")
	Fx.burst(get_parent(), global_position + Vector2(0.0, -14.0), Color(1.0, 0.85, 0.45), 20, 110.0)
	activated.emit(self)


func _draw() -> void:
	var wood := Color(0.55, 0.36, 0.24)
	draw_line(Vector2(0.0, 16.0), Vector2(0.0, -24.0), wood, 3.0, true)
	draw_line(Vector2(0.0, -24.0), Vector2(8.0, -24.0), wood, 2.5, true)
	var lantern := Vector2(8.0, -14.0 + sin(_time * 2.0) * 0.8)
	if is_active:
		var flicker: float = 0.85 + 0.15 * sin(_time * 11.0) * sin(_time * 7.0)
		draw_circle(lantern, 22.0 * flicker, Color(1.0, 0.85, 0.45, 0.18), true, -1.0, true)
		draw_circle(lantern, 12.0 * flicker, Color(1.0, 0.9, 0.55, 0.3), true, -1.0, true)
	draw_line(Vector2(8.0, -24.0), lantern + Vector2(0.0, -6.0), Color(0.4, 0.3, 0.3), 1.0, true)
	var glass := Rect2(lantern + Vector2(-5.0, -6.0), Vector2(10.0, 12.0))
	var glass_color: Color = Color(1.0, 0.88, 0.5) if is_active else Color(0.6, 0.65, 0.8, 0.7)
	draw_rect(glass, glass_color)
	draw_rect(glass, Color(0.35, 0.25, 0.3), false, 1.5)
	draw_colored_polygon(PackedVector2Array([lantern + Vector2(-7.0, -6.0), lantern + Vector2(0.0, -11.0), lantern + Vector2(7.0, -6.0)]), Color(0.45, 0.3, 0.45))
	draw_rect(Rect2(lantern + Vector2(-6.0, 6.0), Vector2(12.0, 2.5)), Color(0.45, 0.3, 0.45))
	if is_active:
		draw_colored_polygon(Shapes.ellipse(lantern + Vector2(0.0, 1.0), Vector2(2.0, 3.5 + sin(_time * 13.0) * 0.6), 0.0, 10), Color(1.0, 0.6, 0.3))
