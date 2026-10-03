class_name QueenArt
extends Node2D
## Draws Queen Nightshade, the Evil Fairy Queen, with code: midnight-blue hair piled high under a
## spiky silver crown, a plum star-speckled gown, long violet wings and a crescent-moon wand.
## Same proportions as Wren (the Queen node scales her up). Origin is the body center.

const SKIN := Color(0.88, 0.82, 0.96)
const SKIN_LINE := Color(0.52, 0.4, 0.66)
const HAIR := Color(0.3, 0.27, 0.62)
const HAIR_LINE := Color(0.14, 0.1, 0.3)
const GOWN := Color(0.62, 0.26, 0.74)
const GOWN_DARK := Color(0.44, 0.16, 0.56)
const GOWN_LINE := Color(0.22, 0.06, 0.3)
const CROWN := Color(0.86, 0.88, 0.96)
const GEM := Color(0.85, 0.3, 0.95)
const EYE := Color(0.25, 0.08, 0.3)

## One of: float, cast, hurt, defeated.
var state: String = "float"
var facing: float = -1.0
## 0..1 while she gathers magic for a spell (the wand glows brighter).
var charge: float = 0.0
## Without the mirror her magic is gone: colours fade and her face turns worried.
var powerless: bool = false

var _time: float = 0.0
var _xf: Transform2D = Transform2D.IDENTITY


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var t: float = _time
	var shake: float = sin(t * 60.0) * 1.2 if state == "hurt" else 0.0
	var bob: float = sin(t * 3.0) * 1.5
	_xf = Transform2D(0.0, Vector2(facing, 1.0), 0.0, Vector2(shake, bob))
	var flap: float = 0.5 + 0.5 * sin(t * (10.0 if powerless else 18.0))

	# Dark aura of borrowed power.
	if not powerless:
		var pulse: float = 0.5 + 0.5 * sin(t * 4.0)
		_circle(Vector2(0.0, -2.0), 22.0 + pulse * 3.0, Color(0.95, 0.6, 1.0, 0.14))
		_circle(Vector2(0.0, -2.0), 15.0, Color(1.0, 0.75, 1.0, 0.12))

	# Long pointed wings behind her.
	var shoulder := Vector2(-2.0, -5.0)
	_wing(shoulder, Vector2(-11.0, -12.0), Vector2(12.0, 4.5), -0.85, flap * 0.8 + 0.2, 0.75)
	_wing(shoulder, Vector2(-9.0, 0.0), Vector2(9.0, 3.5), 0.6, flap * 0.8 + 0.2, 0.75)
	_wing(shoulder, Vector2(-10.0, -11.0), Vector2(11.0, 4.0), -0.6, flap, 0.9)
	_wing(shoulder, Vector2(-8.0, 1.0), Vector2(8.0, 3.2), 0.8, flap, 0.9)

	# Flowing gown with a jagged hem that flutters.
	var gown := PackedVector2Array([Vector2(-3.0, -4.0), Vector2(3.5, -4.0), Vector2(8.0, 9.0)])
	for i: int in 7:
		var u: float = float(i) / 6.0
		var x: float = lerpf(8.0, -10.0, u)
		var flutter: float = sin(t * 6.0 + float(i) * 1.3) * 1.2
		gown.append(Vector2(x - flutter, (17.0 if i % 2 == 0 else 13.0) + flutter * 0.5))
	_poly(gown, _tint(GOWN))
	_outline(gown, GOWN_LINE, 1.0)
	for i: int in 4:
		var sparkle := Vector2(-4.0 + float(i) * 3.5, 4.0 + float(i % 2) * 5.0)
		_poly(Shapes.star(sparkle, 1.4, 0.5, 4, t * 1.5 + float(i)), Color(1.0, 0.9, 1.0, 0.7 if not powerless else 0.25))
	_poly(PackedVector2Array([Vector2(-3.5, -6.0), Vector2(4.0, -6.0), Vector2(3.0, 0.0), Vector2(-2.5, 0.0)]), _tint(GOWN_DARK))
	_circle(Vector2(0.5, -4.0), 1.6, _tint(GEM))

	# Wand arm. The wand is raised while casting.
	var hand := Vector2(7.0, -1.0)
	if state == "cast":
		hand = Vector2(8.0, -9.0)
	elif state == "defeated":
		hand = Vector2(5.0, 3.0)
	_line(Vector2(2.0, -5.0), hand, SKIN, 2.0)
	var wand_tip := hand + (Vector2(3.0, -8.0) if state != "defeated" else Vector2(4.0, 5.0))
	_line(hand, wand_tip, Color(0.18, 0.12, 0.24), 1.6)
	var glow: float = 0.0 if powerless else 0.35 + charge * 0.65
	if glow > 0.0:
		_circle(wand_tip, 4.0 + charge * 6.0, Color(0.95, 0.5, 1.0, 0.3 * glow))
	_circle(wand_tip, 2.6, _tint(Color(1.0, 0.85, 0.45)))
	_circle(wand_tip + Vector2(1.2, -0.8), 2.2, Color(0.2, 0.12, 0.3))

	# Head: hair piled high, then the face, a pointed ear and the crown.
	var h := Vector2(1.0, -12.0)
	var hair: Array[Vector3] = [Vector3(-4.5, 0.0, 5.0), Vector3(-6.0, 5.0, 3.8), Vector3(-5.0, 10.0, 3.0), Vector3(0.0, -6.0, 5.0), Vector3(1.0, -11.0, 4.0), Vector3(4.0, -5.0, 3.6)]
	for c: Vector3 in hair:
		_circle(h + Vector2(c.x, c.y), c.z + 1.1, HAIR_LINE)
	_circle(h, 7.0, SKIN_LINE)
	for c: Vector3 in hair:
		_circle(h + Vector2(c.x, c.y), c.z, _tint(HAIR))
	_circle(h, 6.0, SKIN)
	var ear := PackedVector2Array([h + Vector2(-3.0, -0.5), h + Vector2(-9.0, -5.5), h + Vector2(-4.0, 2.5)])
	_poly(ear, SKIN)
	_outline(ear, SKIN_LINE, 0.8)
	_circle(h + Vector2(2.5, -4.6), 2.8, _tint(HAIR))
	_circle(h + Vector2(-1.5, -5.0), 3.2, _tint(HAIR))

	var crown_base: float = h.y - 6.5
	var crown := PackedVector2Array([Vector2(-4.5, crown_base + 2.0), Vector2(-5.5, crown_base - 4.0), Vector2(-2.5, crown_base - 1.0), Vector2(0.0, crown_base - 7.0), Vector2(2.5, crown_base - 1.0), Vector2(5.5, crown_base - 4.0), Vector2(4.5, crown_base + 2.0)])
	for i: int in crown.size():
		crown[i] += Vector2(h.x, 0.0)
	_poly(crown, _tint(CROWN))
	_outline(crown, Color(0.45, 0.45, 0.6), 0.8)
	_circle(Vector2(h.x, crown_base - 0.5), 1.5, _tint(GEM))

	# Face: a stern brow while powerful, worried once the mirror breaks.
	var eye := h + Vector2(3.2, 0.5)
	_poly(Shapes.ellipse(eye, Vector2(1.3, 1.3 if not powerless else 1.8), 0.0, 10), EYE)
	_circle(eye + Vector2(0.4, -0.5), 0.5, Color.WHITE)
	var brow_tilt: float = 1.2 if not powerless else -1.2
	_line(eye + Vector2(-1.8, -2.4 - brow_tilt * 0.5), eye + Vector2(1.8, -2.4 + brow_tilt * 0.5), HAIR_LINE, 1.0)
	_circle(eye + Vector2(-0.8, 1.6), 1.0, Color(0.6, 0.3, 0.7, 0.35))
	var mouth := PackedVector2Array()
	for i: int in 6:
		var u: float = float(i) / 5.0
		var curve: float = (u - 0.5) * (u - 0.5) * 4.0
		var smirk: float = -curve * 1.2 + u * 0.8 if not powerless else curve * 1.2
		mouth.append(h + Vector2(2.6 + u * 2.6, 3.0 + smirk))
	_polyline(mouth, Color(0.5, 0.15, 0.45), 0.9)


func _tint(color: Color) -> Color:
	if not powerless:
		return color
	var grey: float = color.get_luminance()
	return color.lerp(Color(grey, grey, grey * 1.05), 0.65)


func _wing(shoulder: Vector2, center: Vector2, radius: Vector2, angle: float, flap: float, alpha: float) -> void:
	var points: PackedVector2Array = Shapes.ellipse(shoulder + center + Vector2(0.0, 4.0), radius, angle, 16)
	var stretch := Vector2(lerpf(0.4, 1.0, flap), lerpf(0.75, 1.0, flap))
	var inner: Color = _tint(Color(0.55, 0.22, 0.75, alpha))
	var outer: Color = _tint(Color(1.0, 0.6, 0.95, alpha))
	var colors := PackedColorArray()
	for i: int in points.size():
		var offset: Vector2 = points[i] - shoulder
		points[i] = shoulder + offset * stretch
		colors.append(inner.lerp(outer, clampf(offset.length() / 22.0, 0.0, 1.0)))
	var transformed := _xf * points
	draw_polygon(transformed, colors)
	draw_polyline(Shapes.closed(transformed), _tint(Color(1.0, 0.75, 1.0, alpha)), 0.8, true)


func _circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(_xf * center, radius, color, true, -1.0, true)


func _poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(_xf * points, color)


func _outline(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(_xf * Shapes.closed(points), color, width, true)


func _polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(_xf * points, color, width, true)


func _line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(_xf * from, _xf * to, color, width, true)
