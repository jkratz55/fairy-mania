class_name FairyArt
extends Node2D
## Draws Wren the fairy with code: copper curls, a daisy clip, a lavender petal dress
## and iridescent butterfly wings. Origin is the body center; feet rest at y = +12.

const SKIN := Color(1.0, 0.86, 0.75)
const SKIN_LINE := Color(0.66, 0.42, 0.36)
const HAIR := Color(0.88, 0.45, 0.26)
const HAIR_LINE := Color(0.55, 0.24, 0.16)
const DRESS := Color(0.78, 0.58, 0.97)
const DRESS_DARK := Color(0.6, 0.4, 0.86)
const DRESS_LINE := Color(0.42, 0.26, 0.6)
const SHOES := Color(0.45, 0.25, 0.5)
const EYE := Color(0.2, 0.14, 0.3)

## One of: idle, run, jump, fall, glide, fly, celebrate.
var state: String = "idle"
var facing: float = 1.0
var flight_warning: bool = false

var _time: float = 0.0
var _squash: Vector2 = Vector2.ONE
var _xf: Transform2D = Transform2D.IDENTITY


func _process(delta: float) -> void:
	_time += delta
	_squash = _squash.lerp(Vector2.ONE, minf(1.0, 12.0 * delta))
	queue_redraw()


func squash(amount: Vector2) -> void:
	_squash = amount


func play_knockout() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "rotation", TAU * 2.0, 0.9)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.9)
	tween.tween_property(self, "modulate:a", 0.0, 0.9)


func reset() -> void:
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	_squash = Vector2.ONE


func _draw() -> void:
	_xf = Transform2D(0.0, Vector2(facing * _squash.x, _squash.y), 0.0, Vector2(0.0, 12.0 * (1.0 - _squash.y)))
	var t: float = _time
	var bob: float = 0.0
	var flap_speed: float = 7.0
	match state:
		"idle":
			bob = sin(t * 3.0)
			flap_speed = 6.0
		"run":
			bob = -absf(sin(t * 14.0)) * 1.5
			flap_speed = 10.0
		"jump", "fall":
			flap_speed = 18.0
		"glide":
			flap_speed = 28.0
		"fly":
			bob = sin(t * 5.0) * 1.5
			flap_speed = 30.0
		"celebrate":
			bob = -absf(sin(t * 6.0)) * 4.0
			flap_speed = 24.0
	var flap: float = 0.5 + 0.5 * sin(t * flap_speed)
	var airborne: bool = state in ["jump", "fall", "glide", "fly"]

	# Soft glow aura (golden while flying).
	if state == "fly":
		var aura := Color(1.0, 0.85, 0.45, 0.22 + 0.08 * sin(t * 8.0))
		_circle(Vector2(0.0, -2.0 + bob), 18.0, aura)
		_circle(Vector2(0.0, -2.0 + bob), 11.0, aura)
	else:
		_circle(Vector2(0.0, -2.0 + bob), 12.0, Color(1.0, 0.95, 0.75, 0.07))

	# Wings (all behind the body): a far pair and a near pair, flapping from the shoulder.
	var wing_alpha: float = 0.6
	if flight_warning and fmod(t, 0.3) < 0.15:
		wing_alpha = 0.2
	var shoulder := Vector2(-2.0, -4.0 + bob)
	_wing(shoulder, Vector2(-10.0, -11.0), Vector2(9.0, 5.5), -0.75, flap * 0.8 + 0.2, wing_alpha * 0.8)
	_wing(shoulder, Vector2(-8.0, -1.0), Vector2(6.0, 3.8), 0.55, flap * 0.8 + 0.2, wing_alpha * 0.8)
	_wing(shoulder, Vector2(-9.0, -10.0), Vector2(8.5, 5.0), -0.55, flap, wing_alpha)
	_wing(shoulder, Vector2(-7.0, 0.0), Vector2(5.5, 3.5), 0.7, flap, wing_alpha)

	# Legs and shoes.
	var hip := Vector2(0.0, 6.0 + bob)
	var swing: float = sin(t * 14.0) * 3.0 if state == "run" else 0.0
	var foot_y: float = 10.0 + bob if airborne else 12.0
	var tuck: float = -2.0 if airborne else 0.0
	for side: float in [-1.0, 1.0]:
		var foot := Vector2(side * 1.8 + tuck + swing * side, foot_y)
		_line(hip + Vector2(side * 1.6, 0.0), foot, SKIN, 2.2)
		_circle(foot + Vector2(0.8, 0.2), 1.9, SHOES)

	# Petal dress.
	var d := Vector2(0.0, bob)
	var skirt := PackedVector2Array([
		Vector2(-3.0, -3.0), Vector2(3.0, -3.0), Vector2(7.5, 5.0), Vector2(5.0, 8.0),
		Vector2(2.5, 6.5), Vector2(0.0, 8.5), Vector2(-2.5, 6.5), Vector2(-5.0, 8.0), Vector2(-7.5, 5.0),
	])
	for i: int in skirt.size():
		skirt[i] += d
	_poly(skirt, DRESS)
	_outline(skirt, DRESS_LINE, 1.0)
	var petal_line := Color(1.0, 0.9, 1.0, 0.55)
	_line(d + Vector2(0.0, -2.0), d + Vector2(0.0, 7.5), petal_line, 1.0)
	_line(d + Vector2(-1.5, -2.0), d + Vector2(-4.5, 6.5), petal_line, 1.0)
	_line(d + Vector2(1.5, -2.0), d + Vector2(4.5, 6.5), petal_line, 1.0)
	_circle(d + Vector2(0.5, -4.5), 3.8, DRESS_DARK)

	# Arm (pose depends on state).
	var hand := Vector2(4.5, 1.0)
	match state:
		"run":
			hand = Vector2(4.0 - swing * 0.6, 0.5)
		"jump", "glide":
			hand = Vector2(5.5, -6.0)
		"fly":
			hand = Vector2(7.0, -4.0)
		"celebrate":
			hand = Vector2(3.0 + sin(t * 12.0) * 1.5, -12.0)
	_line(d + Vector2(1.5, -4.5), d + hand, SKIN, 2.0)
	_circle(d + hand, 1.4, SKIN)

	# Head: hair outline pass, hair, face, pointy ear, fringe.
	var h := Vector2(1.0, -11.0 + bob)
	var back_hair: Array[Vector3] = [
		Vector3(-4.5, -1.0, 5.0), Vector3(-2.0, -5.0, 4.4), Vector3(2.0, -5.5, 4.2),
		Vector3(5.5, -3.0, 3.4), Vector3(-6.0, 3.0, 3.6), Vector3(-4.0, 5.0, 2.8),
	]
	for c: Vector3 in back_hair:
		_circle(h + Vector2(c.x, c.y), c.z + 1.1, HAIR_LINE)
	_circle(h, 7.3, SKIN_LINE)
	for c: Vector3 in back_hair:
		_circle(h + Vector2(c.x, c.y), c.z, HAIR)
	_circle(h, 6.3, SKIN)
	var ear := PackedVector2Array([h + Vector2(-3.0, -0.5), h + Vector2(-8.0, -4.5), h + Vector2(-4.0, 2.5)])
	_poly(ear, SKIN)
	_outline(ear, SKIN_LINE, 0.8)
	_circle(h + Vector2(0.5, -5.0), 3.6, HAIR)
	_circle(h + Vector2(4.0, -4.2), 2.8, HAIR)
	_circle(h + Vector2(-3.0, -4.5), 3.0, HAIR)

	# Daisy hair clip.
	var clip := h + Vector2(-3.5, -6.8)
	for i: int in 5:
		var a: float = TAU * float(i) / 5.0 + t * 0.5
		_circle(clip + Vector2(cos(a), sin(a)) * 1.9, 1.5, Color(1.0, 0.97, 0.95))
	_circle(clip, 1.2, Color(1.0, 0.82, 0.3))

	# Face: eye (with blink), blush, smile.
	var eye := h + Vector2(3.2, 0.3)
	if fmod(t, 3.7) < 0.12:
		_line(eye + Vector2(-1.2, 0.0), eye + Vector2(1.2, 0.0), EYE, 1.0)
	else:
		_poly(Shapes.ellipse(eye, Vector2(1.2, 1.8), 0.0, 10), EYE)
		_circle(eye + Vector2(0.4, -0.7), 0.55, Color.WHITE)
	_circle(h + Vector2(2.0, 2.8), 1.5, Color(1.0, 0.5, 0.6, 0.5))
	var smile := PackedVector2Array()
	for i: int in 6:
		var a: float = lerpf(0.35, 2.6, float(i) / 5.0)
		smile.append(h + Vector2(4.2, 2.0) + Vector2(cos(a), sin(a)) * 1.3)
	_polyline(smile, Color(0.6, 0.25, 0.3), 0.8)



func _wing(shoulder: Vector2, center: Vector2, radius: Vector2, angle: float, flap: float, alpha: float) -> void:
	var points: PackedVector2Array = Shapes.ellipse(shoulder + center + Vector2(0.0, 4.0), radius, angle, 16)
	var stretch := Vector2(lerpf(0.35, 1.0, flap), lerpf(0.75, 1.0, flap))
	var colors := PackedColorArray()
	for i: int in points.size():
		var offset: Vector2 = points[i] - shoulder
		points[i] = shoulder + offset * stretch
		var tip: float = clampf(offset.length() / 18.0, 0.0, 1.0)
		colors.append(Color(1.0, 0.82, 0.96, alpha).lerp(Color(0.7, 0.95, 1.0, alpha), tip))
	var transformed := _xf * points
	draw_polygon(transformed, colors)
	draw_polyline(Shapes.closed(transformed), Color(1.0, 1.0, 1.0, alpha * 0.9), 0.8, true)


func _circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(_xf * center, radius * (absf(_xf.x.x) + absf(_xf.y.y)) * 0.5, color, true, -1.0, true)


func _poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(_xf * points, color)


func _outline(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(_xf * Shapes.closed(points), color, width, true)


func _polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(_xf * points, color, width, true)


func _line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(_xf * from, _xf * to, color, width, true)
