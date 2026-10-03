class_name MagicMirror
extends Area2D
## The Evil Fairy Queen's Magic Mirror, where all her power comes from. Wren can't hurt the Queen,
## but every touch cracks the mirror, and after HITS_TO_BREAK touches it shatters.
## Origin is the bottom of the stand (it sits on the floor tile below its layout cell).

signal cracked(hits: int)
signal shattered

const HITS_TO_BREAK: int = 3
const WIDTH: float = 44.0
const HEIGHT: float = 92.0
## After a crack a magic bubble protects the mirror for a while, so Wren has to dodge
## the Queen's spells and come back for the next hit.
const RECOVER_TIME: float = 4.0

var hits: int = 0
## Which way the arena is (-1 = left). Touching the mirror always pushes Wren that way,
## even if she sneaks around its back.
var arena_side: float = -1.0
## The Queen, so the mirror can draw the stream of magic it sends her.
var queen: Node2D

var _time: float = 0.0
var _recover: float = 0.0
## Stops the bubble from bouncing Wren again while she is still flying away.
var _bounce_cooldown: float = 0.0
var _flash: float = 0.0


func _ready() -> void:
	add_to_group("magic_mirror")
	collision_layer = 8
	collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, HEIGHT - 16.0)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0.0, -HEIGHT * 0.5 - 6.0)
	add_child(collider)


func is_broken() -> bool:
	return hits >= HITS_TO_BREAK


func glass_center() -> Vector2:
	return global_position + Vector2(0.0, -HEIGHT * 0.5 - 8.0)


func _physics_process(delta: float) -> void:
	_time += delta
	_recover = maxf(_recover - delta, 0.0)
	_bounce_cooldown = maxf(_bounce_cooldown - delta, 0.0)
	_flash = maxf(_flash - delta * 2.5, 0.0)
	queue_redraw()
	if is_broken() or _bounce_cooldown > 0.0:
		return
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.is_knocked_out():
			continue
		var push_from: Vector2 = player.global_position - Vector2(arena_side * 10.0, 0.0)
		_bounce_cooldown = 0.5
		if _recover > 0.0:
			# The protective bubble just bounces Wren off.
			player.bounce_back(push_from)
			Audio.sfx("shield")
		else:
			# The crack blasts Wren off her feet (and out of the air) and well back from the mirror,
			# so she has to get past the Queen again for the next hit.
			player.end_flight()
			player.bounce_back(push_from, 2.6)
			crack()
		return


## Cracks the mirror once (Wren touching it, or the debug console's `crack`).
func crack() -> void:
	if is_broken():
		return
	hits += 1
	_recover = RECOVER_TIME
	_flash = 1.0
	if is_broken():
		Audio.sfx("mirror_shatter")
		for color: Color in [Color(0.8, 0.9, 1.0), Color(0.9, 0.5, 1.0), Color(1.0, 1.0, 1.0)]:
			Fx.burst(get_parent(), glass_center(), color, 26, 220.0)
		shattered.emit()
	else:
		Audio.sfx("mirror_crack")
		Fx.burst(get_parent(), glass_center(), Color(0.85, 0.75, 1.0), 16, 140.0)
		cracked.emit(hits)


func _draw() -> void:
	var center := Vector2(0.0, -HEIGHT * 0.5 - 8.0)
	var radius := Vector2(WIDTH * 0.5, HEIGHT * 0.5 - 6.0)
	var gold := Color(1.0, 0.8, 0.38)
	var gold_dark := Color(0.7, 0.48, 0.2)

	# The stream of magic flowing to the Queen.
	if queen != null and is_instance_valid(queen) and not is_broken():
		var target: Vector2 = queen.global_position - global_position
		var stream := PackedVector2Array()
		for i: int in 17:
			var u: float = float(i) / 16.0
			var along: Vector2 = center.lerp(target, u)
			var side: Vector2 = (target - center).normalized().orthogonal()
			stream.append(along + side * sin(u * 12.0 - _time * 6.0) * 5.0 * sin(u * PI))
		draw_polyline(stream, Color(0.85, 0.45, 1.0, 0.22), 5.0, true)
		draw_polyline(stream, Color(1.0, 0.8, 1.0, 0.45), 1.5, true)

	# Glow of power around the glass.
	if not is_broken():
		var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
		draw_colored_polygon(Shapes.ellipse(center, radius + Vector2(10.0, 10.0) * (0.8 + pulse * 0.4), 0.0, 28), Color(0.7, 0.3, 1.0, 0.16))

	# Stand with clawed gold feet.
	draw_rect(Rect2(-4.0, -12.0, 8.0, 12.0), gold_dark)
	draw_colored_polygon(PackedVector2Array([Vector2(-16.0, 0.0), Vector2(16.0, 0.0), Vector2(8.0, -6.0), Vector2(-8.0, -6.0)]), gold)

	# Frame and glass.
	draw_colored_polygon(Shapes.ellipse(center, radius + Vector2(5.0, 5.0), 0.0, 32), gold)
	draw_polyline(Shapes.closed(Shapes.ellipse(center, radius + Vector2(5.0, 5.0), 0.0, 32)), gold_dark, 1.5, true)
	if is_broken():
		draw_colored_polygon(Shapes.ellipse(center, radius, 0.0, 32), Color(0.12, 0.08, 0.18))
		# A few jagged shards still stuck in the frame.
		for i: int in 6:
			var a: float = TAU * float(i) / 6.0 + 0.3
			var edge: Vector2 = center + Vector2(cos(a) * radius.x, sin(a) * radius.y)
			var inward: Vector2 = (center - edge) * (0.25 + 0.15 * float(i % 2))
			draw_colored_polygon(PackedVector2Array([edge + inward.orthogonal() * 0.3, edge + inward, edge - inward.orthogonal() * 0.3]), Color(0.75, 0.85, 1.0, 0.8))
	else:
		draw_colored_polygon(Shapes.ellipse(center, radius, 0.0, 32), Color(0.24, 0.12, 0.38))
		# Swirling dark magic inside the glass.
		for k: int in 3:
			var swirl := PackedVector2Array()
			for i: int in 24:
				var u: float = float(i) / 23.0
				var a: float = u * TAU * 1.2 + _time * (1.0 + 0.4 * float(k)) + float(k) * 2.1
				swirl.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y) * (0.85 - u * 0.75))
			draw_polyline(swirl, Color(0.85, 0.5, 1.0, 0.45), 2.0, true)
		draw_colored_polygon(Shapes.ellipse(center + Vector2(-8.0, -18.0), Vector2(4.0, 12.0), 0.35, 14), Color(1.0, 1.0, 1.0, 0.25))
		_draw_cracks(center, radius)
		if _flash > 0.0:
			draw_colored_polygon(Shapes.ellipse(center, radius, 0.0, 32), Color(1.0, 1.0, 1.0, _flash * 0.8))
		if _recover > 0.0:
			# A shimmering bubble while the mirror is protected (it fades out just before it pops).
			var fade: float = clampf(_recover / 0.6, 0.0, 1.0)
			var bubble: PackedVector2Array = Shapes.ellipse(center, radius + Vector2(14.0, 16.0) + Vector2.ONE * sin(_time * 5.0) * 1.5, 0.0, 32)
			draw_colored_polygon(bubble, Color(0.8, 0.6, 1.0, 0.18 * fade))
			draw_polyline(Shapes.closed(bubble), Color(1.0, 0.85, 1.0, 0.7 * fade), 2.0, true)
			draw_arc(center + Vector2(-12.0, -24.0), 10.0, PI * 1.1, PI * 1.5, 8, Color(1.0, 1.0, 1.0, 0.6 * fade), 2.0, true)
	# A gold crescent moon crest on top.
	var crest := center + Vector2(0.0, -radius.y - 9.0)
	draw_circle(crest, 7.0, gold, true, -1.0, true)
	draw_circle(crest + Vector2(3.0, -2.0), 6.0, Color(0.24, 0.12, 0.38) if not is_broken() else Color(0.12, 0.08, 0.18), true, -1.0, true)


## Each hit adds a starburst of cracks from a different spot on the glass.
func _draw_cracks(center: Vector2, radius: Vector2) -> void:
	var impacts: Array[Vector2] = [Vector2(-0.3, -0.25), Vector2(0.35, 0.2), Vector2(-0.1, 0.45)]
	for hit: int in mini(hits, impacts.size()):
		var origin: Vector2 = center + impacts[hit] * radius
		for ray: int in 6:
			var a: float = TAU * float(ray) / 6.0 + float(hit) * 0.7
			var length: float = 10.0 + Shapes.hash01(hit, ray, 31) * 14.0
			var bend: float = (Shapes.hash01(hit, ray, 32) - 0.5) * 0.8
			var mid: Vector2 = origin + Vector2.from_angle(a) * length * 0.5
			var tip: Vector2 = origin + Vector2.from_angle(a + bend) * length
			draw_polyline(PackedVector2Array([origin, mid, tip]), Color(1.0, 1.0, 1.0, 0.85), 1.2, true)
		draw_circle(origin, 2.0, Color(1.0, 1.0, 1.0, 0.9), true, -1.0, true)
