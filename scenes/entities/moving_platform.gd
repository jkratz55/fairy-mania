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
		"sand":
			# A little raft: planks lashed together with rope.
			for i: int in 5:
				var x: float = -36.0 + 18.0 * float(i)
				draw_line(Vector2(x, -15.0), Vector2(x, -5.0), theme.platform_dark, 1.2, true)
			for x: float in [-28.0, 28.0]:
				draw_rect(Rect2(x - 2.5, -16.0, 5.0, 12.0), Color(0.9, 0.82, 0.62))
			draw_colored_polygon(Shapes.star(Vector2(0.0, -10.0), 3.5, 1.5), theme.accents[0])
		"crystal":
			for i: int in 4:
				var x: float = -33.0 + 22.0 * float(i)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 4.0, -10.0), Vector2(x, -14.0), Vector2(x + 4.0, -10.0), Vector2(x, -6.0)]), theme.accents[i % theme.accents.size()])
		"snow":
			draw_rect(Rect2(-WIDTH * 0.5 + 4.0, -17.0, WIDTH - 8.0, 4.0), theme.top)
			for i: int in 6:
				draw_circle(Vector2(-40.0 + 16.0 * float(i), -16.0), 3.5, theme.top, true, -1.0, true)
			for i: int in 5:
				var x: float = -32.0 + 16.0 * float(i)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 2.0, -5.0), Vector2(x + 2.0, -5.0), Vector2(x, 1.0 + float(i % 2) * 3.0)]), theme.platform)
		"leaf":
			for i: int in 6:
				var leaf := Vector2(-40.0 + 16.0 * float(i), -16.0 + float(i % 2))
				draw_colored_polygon(Shapes.ellipse(leaf, Vector2(5.0, 2.4), -0.4 + 0.25 * float(i), 8), theme.accents[i % 3])
			draw_circle(Vector2(30.0, -2.0), 4.0, theme.accents[0], true, -1.0, true)
			draw_line(Vector2(30.0, -6.0), Vector2(31.0, -9.0), theme.platform_dark, 1.2, true)
		"frosting":
			draw_rect(Rect2(-WIDTH * 0.5 + 3.0, -12.0, WIDTH - 6.0, 3.0), Color(1.0, 0.9, 0.95))
			for i: int in 7:
				var at := Vector2(-36.0 + 12.0 * float(i), -15.0 + float(i % 2) * 1.5)
				var tilt := Vector2.from_angle(float(i) * 1.3) * 2.0
				draw_line(at - tilt, at + tilt, theme.accents[i % theme.accents.size()], 1.6, true)
		"falls":
			# A floating lily pad with a flower.
			var pad: PackedVector2Array = Shapes.ellipse(Vector2(0.0, -11.0), Vector2(WIDTH * 0.5 + 2.0, 7.0), 0.0, 28)
			draw_colored_polygon(pad, theme.platform)
			draw_polyline(Shapes.closed(pad), theme.platform_dark, 1.5, true)
			draw_colored_polygon(PackedVector2Array([Vector2(8.0, -11.0), Vector2(30.0, -18.0), Vector2(36.0, -15.0)]), theme.platform_dark)
			for i: int in 5:
				draw_line(Vector2(-4.0, -11.0), Vector2(-4.0, -11.0) + Vector2.from_angle(PI * 0.3 + PI * 0.35 * float(i)) * Vector2(40.0, 6.0), Color(theme.platform_dark, 0.6), 1.0, true)
			for i: int in 5:
				draw_colored_polygon(Shapes.ellipse(Vector2(-26.0, -16.0) + Vector2.from_angle(TAU * float(i) / 5.0) * 3.5, Vector2(3.0, 2.0), TAU * float(i) / 5.0, 8), Color(1.0, 0.72, 0.85))
			draw_circle(Vector2(-26.0, -16.0), 2.0, Color(1.0, 0.92, 0.5), true, -1.0, true)
		_:
			for i: int in 3:
				var x: float = -32.0 + 32.0 * float(i)
				draw_line(Vector2(x, -13.0), Vector2(x, -6.0), theme.platform_dark, 1.5, true)
			draw_colored_polygon(Shapes.ellipse(Vector2(-44.0, -17.0), Vector2(6.0, 2.5), -0.5, 10), Color(0.4, 0.75, 0.35))
