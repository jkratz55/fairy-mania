class_name Flyer
extends Node2D
## A flying critter that drifts in a gentle pattern.
## Bumblebee (meadow), glow-moth (woods), seagull (beach), cave bat (caves),
## snowflake sprite (peaks), maple-leaf sprite (orchard), flying bonbon (candy),
## dragonfly (falls) or sleepy owl (sky).

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
		"beach":
			_draw_gull()
		"caves":
			_draw_bat()
		"peaks":
			_draw_snowflake()
		"orchard":
			_draw_maple_leaf()
		"candy":
			_draw_bonbon(flap)
		"falls":
			_draw_dragonfly()
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


func _draw_gull() -> void:
	var f: float = _facing
	var beat: float = sin(_time * 7.0)
	var grey := Color(0.7, 0.74, 0.82)
	for side: float in [-1.0, 1.0]:
		# Gull wings bend at the elbow; the far wing is drawn a little darker.
		var shade: Color = grey if side > 0.0 else grey.darkened(0.12)
		var shoulder := Vector2(side * 2.0, -2.0)
		var elbow := shoulder + Vector2(side * 7.0, -4.0 - beat * 5.0)
		var tip := elbow + Vector2(side * 8.0, 3.0 - beat * 6.0)
		draw_colored_polygon(PackedVector2Array([shoulder + Vector2(0.0, 3.0), shoulder, elbow, tip, elbow + Vector2(0.0, 3.0)]), shade)
		draw_line(elbow, tip, Color(0.3, 0.3, 0.38), 1.6, true)
	draw_colored_polygon(Shapes.ellipse(Vector2.ZERO, Vector2(9.0, 5.5)), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(-f * 8.0, -1.0), Vector2(-f * 13.0, -3.0), Vector2(-f * 12.0, 2.0)]), grey)
	draw_circle(Vector2(f * 7.0, -3.0), 4.5, Color.WHITE, true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(f * 10.5, -3.5), Vector2(f * 15.0, -2.0), Vector2(f * 10.5, -1.0)]), Color(1.0, 0.8, 0.25))
	draw_circle(Vector2(f * 8.0, -4.5), 1.1, Color(0.15, 0.12, 0.2), true, -1.0, true)


func _draw_bat() -> void:
	var f: float = _facing
	var flap: float = sin(_time * 12.0)
	var body := Color(0.45, 0.32, 0.62)
	var wing := Color(0.36, 0.24, 0.52)
	draw_circle(Vector2.ZERO, 16.0, Color(theme.accents[1], 0.1), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var lift: float = flap * 7.0
		var points := PackedVector2Array([Vector2(side * 5.0, -3.0), Vector2(side * 12.0, -7.0 - lift), Vector2(side * 18.0, -2.0 - lift * 0.6)])
		# Scalloped trailing edge.
		points.append(Vector2(side * 15.0, 2.0 - lift * 0.3))
		points.append(Vector2(side * 12.0, 0.0 - lift * 0.3))
		points.append(Vector2(side * 9.0, 3.0))
		points.append(Vector2(side * 5.0, 3.0))
		draw_colored_polygon(points, wing)
		draw_colored_polygon(PackedVector2Array([Vector2(side * 2.0, -6.0), Vector2(side * 6.0, -12.0), Vector2(side * 6.0, -4.0)]), body)
	draw_circle(Vector2.ZERO, 7.5, body, true, -1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(0.0, 2.5), Vector2(4.5, 3.5)), Color(0.7, 0.58, 0.85))
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 1.0 + side * 2.8, -2.0)
		draw_circle(eye, 2.3, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.7, 0.3), 1.2, Color(0.15, 0.1, 0.25), true, -1.0, true)
	draw_circle(Vector2(f * 1.0 - 4.5, 1.5), 1.0, Color(1.0, 0.55, 0.75, 0.7), true, -1.0, true)
	draw_circle(Vector2(f * 1.0 + 4.5, 1.5), 1.0, Color(1.0, 0.55, 0.75, 0.7), true, -1.0, true)


func _draw_snowflake() -> void:
	var ice := Color(0.8, 0.93, 1.0)
	draw_circle(Vector2.ZERO, 18.0, Color(theme.accents[0], 0.12), true, -1.0, true)
	var spin: float = _time * 0.8
	for i: int in 6:
		var dir := Vector2.from_angle(spin + TAU * float(i) / 6.0)
		var tip: Vector2 = dir * 15.0
		draw_line(Vector2.ZERO, tip, ice, 2.4, true)
		for branch: float in [0.5, 0.75]:
			var at: Vector2 = dir * 15.0 * branch
			draw_line(at, at + dir.rotated(0.8) * 4.5, ice, 1.6, true)
			draw_line(at, at + dir.rotated(-0.8) * 4.5, ice, 1.6, true)
		draw_circle(tip, 1.8, Color.WHITE, true, -1.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(0.92, 0.97, 1.0), true, -1.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(0.55, 0.75, 0.95), false, 1.2, true)
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(side * 2.4, -1.0), 1.2, Color(0.15, 0.15, 0.3), true, -1.0, true)
		draw_circle(Vector2(side * 4.0, 1.8), 1.0, Color(1.0, 0.6, 0.72, 0.7), true, -1.0, true)
	draw_arc(Vector2(0.0, 1.0), 1.8, 0.3, PI - 0.3, 8, Color(0.15, 0.15, 0.3), 1.0, true)


func _draw_maple_leaf() -> void:
	# Sways like a leaf drifting on the breeze.
	draw_set_transform(Vector2.ZERO, sin(_time * 2.2) * 0.35, Vector2(2.0 - _flatten, _flatten))
	var leaf: Color = theme.accents[2]
	draw_line(Vector2(0.0, 6.0), Vector2(1.0, 15.0), theme.platform_dark, 1.8, true)
	var shape: PackedVector2Array = Shapes.star(Vector2(0.0, -1.0), 14.0, 7.0, 5)
	draw_colored_polygon(shape, leaf)
	draw_polyline(Shapes.closed(shape), leaf.darkened(0.3), 1.2, true)
	for i: int in 5:
		var a: float = -PI / 2.0 + TAU * float(i) / 5.0
		draw_line(Vector2(0.0, -1.0), Vector2(0.0, -1.0) + Vector2.from_angle(a) * 11.0, Color(leaf.darkened(0.2), 0.7), 1.0, true)
	draw_circle(Vector2(0.0, 0.0), 5.5, leaf.lightened(0.15), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(side * 2.4, -1.0), 1.4, Color(0.25, 0.14, 0.12), true, -1.0, true)
		draw_circle(Vector2(side * 4.0, 1.8), 1.0, Color(1.0, 0.45, 0.4, 0.7), true, -1.0, true)
	draw_arc(Vector2(0.0, 1.0), 1.6, 0.3, PI - 0.3, 8, Color(0.25, 0.14, 0.12), 1.0, true)


func _draw_bonbon(flap: float) -> void:
	var f: float = _facing
	var wrapper: Color = theme.accents[0]
	var flutter: float = 0.4 + flap * 0.6
	draw_circle(Vector2.ZERO, 16.0, Color(theme.accents[1], 0.1), true, -1.0, true)
	# The twisted wrapper ends flap like little wings.
	for side: float in [-1.0, 1.0]:
		var twist := Vector2(side * 9.0, 0.0)
		draw_colored_polygon(PackedVector2Array([twist, twist + Vector2(side * 9.0, -7.0 * flutter), twist + Vector2(side * 7.0, 0.0), twist + Vector2(side * 9.0, 7.0 * flutter)]), theme.accents[1])
		draw_circle(twist, 2.0, theme.accents[1].darkened(0.2), true, -1.0, true)
	var body: PackedVector2Array = Shapes.ellipse(Vector2.ZERO, Vector2(9.5, 8.0))
	draw_colored_polygon(body, wrapper)
	for k: int in 3:
		var x: float = -5.0 + 5.0 * float(k)
		draw_line(Vector2(x + 2.0, -7.0), Vector2(x - 2.0, 7.0), Color(1.0, 1.0, 1.0, 0.55), 1.6, true)
	draw_polyline(Shapes.closed(body), wrapper.darkened(0.3), 1.2, true)
	draw_circle(Vector2(-4.0, -4.0), 1.8, Color(1.0, 1.0, 1.0, 0.6), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 1.5 + side * 3.0, -0.5)
		draw_circle(eye, 2.0, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.6, 0.3), 1.0, Color(0.25, 0.12, 0.25), true, -1.0, true)
	draw_arc(Vector2(f * 1.5, 3.0), 1.6, 0.3, PI - 0.3, 8, Color(0.25, 0.12, 0.25), 1.0, true)


func _draw_dragonfly() -> void:
	var f: float = _facing
	var body := Color(0.3, 0.7, 0.85)
	var beat: float = sin(_time * 40.0)
	for side: float in [-1.0, 1.0]:
		for k: int in 2:
			var root := Vector2(f * (2.0 - 4.0 * float(k)), -2.0)
			var wing: PackedVector2Array = Shapes.ellipse(root + Vector2(f * -2.0 * float(k), -6.0 * side - beat * 1.5 * side), Vector2(9.0, 2.6), -f * (0.25 + 0.15 * float(k)) * side, 12)
			draw_colored_polygon(wing, Color(0.85, 0.95, 1.0, 0.55))
			draw_polyline(Shapes.closed(wing), Color(0.6, 0.8, 0.95, 0.8), 1.0, true)
	# A long tail made of little segments.
	for i: int in 5:
		draw_circle(Vector2(-f * (4.0 + 3.2 * float(i)), 0.5 + float(i) * 0.3), 2.4 - float(i) * 0.25, body.darkened(0.08 * float(i % 2)), true, -1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(f * 1.0, 0.0), Vector2(5.0, 3.6)), body)
	draw_circle(Vector2(f * 6.5, -1.0), 4.0, body.lightened(0.2), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 7.5, -1.0 + side * 2.2)
		draw_circle(eye, 2.2, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.6, 0.0), 1.1, Color(0.12, 0.15, 0.25), true, -1.0, true)


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
