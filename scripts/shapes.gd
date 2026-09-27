class_name Shapes
extends RefCounted
## Geometry helpers for the code-drawn art (every visual in the game is drawn with _draw()).


static func ellipse(center: Vector2, radius: Vector2, angle: float = 0.0, segments: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in segments:
		var a: float = TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(angle))
	return points


## Upper half of an ellipse with a flat bottom edge (domes, mushroom caps, bug shells).
static func dome(center: Vector2, radius: Vector2, segments: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in segments + 1:
		var a: float = PI + PI * float(i) / float(segments)
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return points


static func star(center: Vector2, outer: float, inner: float, tips: int = 5, angle: float = -PI / 2.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in tips * 2:
		var r: float = outer if i % 2 == 0 else inner
		var a: float = angle + PI * float(i) / float(tips)
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points


static func heart(center: Vector2, size: float, segments: int = 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in segments:
		var t: float = TAU * float(i) / float(segments)
		var s: float = sin(t)
		var x: float = 16.0 * s * s * s
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y) * (size / 16.0))
	return points


## Returns a copy of the polygon with the first point repeated, for drawing outlines.
static func closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	out.append(points[0])
	return out


## Deterministic pseudo-random value in [0, 1] for a grid cell, so decorations never flicker.
static func hash01(x: int, y: int, salt: int = 0) -> float:
	var n: int = x * 374761393 + y * 668265263 + salt * 1442695041
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0
