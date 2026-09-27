class_name HeartPickup
extends Area2D
## Restores one heart.

var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	add_to_group("respawnable")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0.0, sin(_time * 2.5) * 3.0 - 2.0)
	var beat: float = 1.0 + 0.08 * maxf(0.0, sin(_time * 7.0))
	draw_circle(c, 14.0, Color(1.0, 0.6, 0.75, 0.18), true, -1.0, true)
	var heart: PackedVector2Array = Shapes.heart(c, 10.0 * beat)
	draw_colored_polygon(heart, Color(1.0, 0.38, 0.55))
	draw_polyline(Shapes.closed(heart), Color(0.7, 0.15, 0.35), 1.2, true)
	draw_circle(c + Vector2(-4.0, -3.0), 2.4, Color(1.0, 1.0, 1.0, 0.7), true, -1.0, true)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or _collected:
		return
	_collected = true
	player.heal(1)
	Audio.sfx("heart")
	Fx.burst(get_parent(), global_position, Color(1.0, 0.5, 0.7), 14, 90.0)
	hide()
	set_deferred("monitoring", false)


func restore() -> void:
	if not _collected:
		return
	_collected = false
	show()
	set_deferred("monitoring", true)
