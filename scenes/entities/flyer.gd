class_name Flyer
extends Node2D
## A flying critter that drifts in a gentle pattern.
## Bumblebee (meadow), glow-moth (woods) or sleepy owl (sky).

var theme: LevelTheme
## "vertical" bobs up and down; "horizontal" patrols left and right.
var pattern: String = "vertical"

var _origin: Vector2
var _time: float = 0.0
var _facing: float = -1.0
var _defeated: bool = false
var _flatten: float = 1.0

@onready var hitbox: EnemyHitbox = $Hitbox


func _ready() -> void:
	if theme == null:
		theme = LevelTheme.create("meadow")
	_origin = position
	_time = randf() * TAU
	hitbox.stomped.connect(_on_stomped)


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _defeated:
		return
	var previous: Vector2 = position
	if pattern == "horizontal":
		position = _origin + Vector2(sin(_time * 0.8) * 80.0, sin(_time * 3.0) * 4.0)
	else:
		position = _origin + Vector2(sin(_time * 1.1) * 6.0, sin(_time * 1.6) * 40.0)
	if pattern == "horizontal" and absf(position.x - previous.x) > 0.05:
		_facing = signf(position.x - previous.x)


func _on_stomped(player: Player) -> void:
	if _defeated:
		return
	_defeated = true
	hitbox.active = false
	player.stomp_bounce()
	player.add_dust(1)
	Audio.sfx("stomp")
	Fx.burst(get_parent(), global_position, theme.accents[1], 18, 120.0)
	Fx.popup_text(get_parent(), global_position, "+1")
	var tween := create_tween()
	tween.tween_property(self, "_flatten", 0.2, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2.0 - _flatten, _flatten))
	var flap: float = absf(sin(_time * 30.0))
	match theme.id:
		"woods":
			_draw_moth(flap)
		"sky":
			_draw_owl(flap)
		_:
			_draw_bee(flap)


func _draw_bee(flap: float) -> void:
	var f: float = _facing
	var dark := Color(0.2, 0.14, 0.18)
	draw_colored_polygon(Shapes.ellipse(Vector2(-f * 2.0, -8.0), Vector2(5.0, 3.5 * (0.3 + flap)), -f * 0.4, 12), Color(1.0, 1.0, 1.0, 0.75))
	draw_colored_polygon(PackedVector2Array([Vector2(-f * 8.0, -1.5), Vector2(-f * 13.0, 0.5), Vector2(-f * 8.0, 2.0)]), dark)
	var body: PackedVector2Array = Shapes.ellipse(Vector2.ZERO, Vector2(9.5, 7.0))
	draw_colored_polygon(body, Color(1.0, 0.83, 0.25))
	draw_line(Vector2(-f * 1.0, -6.5), Vector2(-f * 1.0, 6.5), dark, 2.6, true)
	draw_line(Vector2(-f * 5.0, -5.5), Vector2(-f * 5.0, 5.5), dark, 2.6, true)
	draw_polyline(Shapes.closed(body), Color(0.6, 0.4, 0.1), 1.0, true)
	draw_line(Vector2(f * 5.0, -5.0), Vector2(f * 8.0, -10.0), dark, 1.1, true)
	draw_circle(Vector2(f * 8.0, -10.0), 1.3, dark, true, -1.0, true)
	draw_circle(Vector2(f * 5.0, -1.5), 1.9, dark, true, -1.0, true)
	draw_circle(Vector2(f * 5.5, -2.2), 0.6, Color.WHITE, true, -1.0, true)
	draw_circle(Vector2(f * 3.5, 2.5), 1.3, Color(1.0, 0.5, 0.4, 0.6), true, -1.0, true)


func _draw_moth(_flap: float) -> void:
	var slow_flap: float = 0.4 + 0.6 * absf(sin(_time * 8.0))
	draw_circle(Vector2.ZERO, 17.0, Color(theme.accents[0], 0.12), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var wing: PackedVector2Array = Shapes.ellipse(Vector2(side * 7.0, -2.0), Vector2(8.0 * slow_flap, 6.5), side * 0.3, 14)
		draw_colored_polygon(wing, Color(0.78, 0.68, 0.98))
		draw_polyline(Shapes.closed(wing), Color(0.5, 0.4, 0.75), 1.0, true)
		draw_circle(Vector2(side * 7.0 * slow_flap, -2.0), 2.4, theme.accents[0], true, -1.0, true)
		draw_colored_polygon(Shapes.ellipse(Vector2(side * 5.0, 5.0), Vector2(4.5 * slow_flap, 3.5), side * -0.4, 10), Color(0.7, 0.6, 0.92))
		draw_line(Vector2(side * 1.0, -6.0), Vector2(side * 4.0, -11.0), Color(0.9, 0.85, 1.0), 1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(0.0, 1.0), Vector2(3.5, 7.0)), Color(0.95, 0.9, 1.0))
	draw_circle(Vector2(-1.5, -3.0), 1.1, Color(0.2, 0.12, 0.3), true, -1.0, true)
	draw_circle(Vector2(1.5, -3.0), 1.1, Color(0.2, 0.12, 0.3), true, -1.0, true)


func _draw_owl(flap: float) -> void:
	var f: float = _facing
	var body_color := Color(0.52, 0.46, 0.7)
	for side: float in [-1.0, 1.0]:
		draw_colored_polygon(Shapes.ellipse(Vector2(side * 9.0, 0.0), Vector2(4.0, 7.0 * (0.4 + flap * 0.6)), side * 0.3, 12), Color(0.4, 0.34, 0.58))
		draw_colored_polygon(PackedVector2Array([Vector2(side * 3.0, -7.0), Vector2(side * 8.0, -13.0), Vector2(side * 8.0, -5.0)]), body_color)
	draw_circle(Vector2.ZERO, 9.0, body_color, true, -1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(0.0, 3.5), Vector2(6.0, 5.0)), Color(0.85, 0.8, 0.95))
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(side * 3.6, -2.0)
		draw_circle(eye, 3.4, Color(1.0, 0.85, 0.35), true, -1.0, true)
		draw_circle(eye, 2.5, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.8, 0.2), 1.4, Color(0.18, 0.12, 0.25), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-1.4, 0.8), Vector2(1.4, 0.8), Vector2(0.0, 3.4)]), Color(1.0, 0.65, 0.3))
