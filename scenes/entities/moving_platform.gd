class_name MovingPlatform
extends AnimatableBody2D
## A three-tile platform that glides back and forth. Wren can jump up through it from below.

const WIDTH: float = 96.0

@export var axis: Vector2 = Vector2.RIGHT
@export var distance: float = 64.0
@export var period: float = 5.0

var theme: LevelTheme
var _origin: Vector2
var _time: float = 0.0


func _ready() -> void:
	if theme == null:
		theme = LevelTheme.create("meadow")
	_origin = position


func _physics_process(delta: float) -> void:
	_time += delta
	position = _origin + axis * sin(_time * TAU / period) * distance


func _draw() -> void:
	var rect := Rect2(-WIDTH * 0.5, -16.0, WIDTH, 12.0)
	var radius: float = 6.0
	# Pill shape: left cap (bottom -> left -> top), then right cap (top -> right -> bottom).
	var body := PackedVector2Array()
	var left_center := Vector2(rect.position.x + radius, rect.position.y + radius)
	var right_center := Vector2(rect.end.x - radius, rect.position.y + radius)
	for i: int in 9:
		var a: float = PI * 0.5 + PI * float(i) / 8.0
		body.append(left_center + Vector2(cos(a), sin(a)) * radius)
	for i: int in 9:
		var a: float = -PI * 0.5 + PI * float(i) / 8.0
		body.append(right_center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(body, theme.platform)
	draw_polyline(Shapes.closed(body), theme.platform_dark, 1.5, true)
	draw_line(Vector2(rect.position.x + 6.0, rect.position.y + 3.0), Vector2(rect.end.x - 6.0, rect.position.y + 3.0), Color(1.0, 1.0, 1.0, 0.45), 2.0, true)
	match theme.style:
		"cloud":
			for i: int in 4:
				draw_colored_polygon(Shapes.star(Vector2(-33.0 + 22.0 * float(i), -9.0), 3.5, 1.5), theme.platform_dark)
		"moss":
			for i: int in 5:
				draw_circle(Vector2(-36.0 + 18.0 * float(i), -9.0), 2.0, Color(1.0, 0.95, 0.95), true, -1.0, true)
		_:
			for i: int in 3:
				var x: float = -32.0 + 32.0 * float(i)
				draw_line(Vector2(x, -13.0), Vector2(x, -6.0), theme.platform_dark, 1.5, true)
			draw_colored_polygon(Shapes.ellipse(Vector2(-44.0, -17.0), Vector2(6.0, 2.5), -0.5, 10), Color(0.4, 0.75, 0.35))
