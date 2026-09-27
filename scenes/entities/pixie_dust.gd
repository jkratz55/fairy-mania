class_name PixieDust
extends Area2D
## A twinkling pinch of pixie dust. Collect 8 to fly; while flying, each one adds flight time.
## Dust comes back when Wren respawns, so a flying section can always be retried.

var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	add_to_group("respawnable")
	body_entered.connect(_on_body_entered)
	_time = randf() * TAU


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0.0, sin(_time * 3.0) * 2.5)
	var pulse: float = 0.85 + 0.15 * sin(_time * 6.0)
	draw_circle(c, 11.0 * pulse, Color(1.0, 0.92, 0.55, 0.16), true, -1.0, true)
	draw_circle(c, 6.5 * pulse, Color(1.0, 0.95, 0.7, 0.3), true, -1.0, true)
	draw_colored_polygon(Shapes.star(c, 7.5 * pulse, 2.4, 4, _time * 1.2), Color(1.0, 0.86, 0.32))
	draw_colored_polygon(Shapes.star(c, 4.0 * pulse, 1.3, 4, _time * 1.2), Color(1.0, 1.0, 0.9))
	for i: int in 2:
		var a: float = _time * 2.0 + PI * float(i)
		draw_circle(c + Vector2(cos(a) * 9.0, sin(a) * 4.0), 1.0, Color(1.0, 1.0, 1.0, 0.8), true, -1.0, true)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or _collected:
		return
	_collected = true
	player.add_dust(1)
	Audio.sfx("dust", randf_range(0.95, 1.12))
	Fx.burst(get_parent(), global_position, Color(1.0, 0.9, 0.5), 8, 70.0)
	hide()
	set_deferred("monitoring", false)


func restore() -> void:
	if not _collected:
		return
	_collected = false
	show()
	set_deferred("monitoring", true)
