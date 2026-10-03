class_name Walker
extends CharacterBody2D
## A slow walking critter that turns around at walls and ledges.
## Its look depends on the level theme: ladybug (meadow), shroomlet (woods), crab (beach),
## crystal snail (caves), penguin chick (peaks), acorn buddy (orchard), gummy bear (candy),
## frog (falls) or grumble-cloud (sky).

const SPEED: float = 38.0
const GRAVITY: float = 900.0

var theme: LevelTheme
var direction: float = -1.0

var _time: float = 0.0
var _defeated: bool = false
var _flatten: float = 1.0
var _tint: Color = Color.WHITE

@onready var hitbox: EnemyHitbox = $Hitbox
@onready var ledge_ray: RayCast2D = $LedgeRay


func _ready() -> void:
	if theme == null:
		theme = LevelTheme.create("meadow")
	hitbox.stomped.connect(_on_stomped)
	_time = randf() * 10.0
	_tint = theme.accents[randi() % theme.accents.size()]


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _defeated:
		return
	velocity.x = direction * SPEED
	velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
	move_and_slide()
	if is_on_wall():
		direction = -direction
	elif is_on_floor():
		ledge_ray.position.x = direction * 12.0
		ledge_ray.force_raycast_update()
		if not ledge_ray.is_colliding():
			direction = -direction
	if global_position.y > 2000.0:
		queue_free()


func _on_stomped(player: Player) -> void:
	if _defeated:
		return
	_defeated = true
	hitbox.active = false
	collision_layer = 0
	collision_mask = 0
	player.stomp_bounce()
	player.add_dust(1)
	Audio.sfx("stomp")
	Fx.burst(get_parent(), global_position, theme.accents[0], 18, 120.0)
	Fx.popup_text(get_parent(), global_position, "+1")
	var tween := create_tween()
	tween.tween_property(self, "_flatten", 0.2, 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _draw() -> void:
	# Squash from the feet (y = +8) when stomped.
	draw_set_transform(Vector2(0.0, 8.0 * (1.0 - _flatten)), 0.0, Vector2(2.0 - _flatten, _flatten))
	var step: float = sin(_time * 10.0)
	match theme.id:
		"woods":
			_draw_shroomlet(step)
		"beach":
			_draw_crab(step)
		"caves":
			_draw_snail(step)
		"peaks":
			_draw_penguin(step)
		"orchard":
			_draw_acorn(step)
		"candy":
			_draw_gummy_bear(step)
		"falls":
			_draw_frog()
		"sky":
			_draw_grumble_cloud(step)
		_:
			_draw_ladybug(step)


func _draw_ladybug(step: float) -> void:
	var f: float = direction
	var dark := Color(0.22, 0.14, 0.22)
	for i: int in 3:
		var lx: float = -6.0 + 6.0 * float(i)
		var swing: float = step * 2.0 * (1.0 if i % 2 == 0 else -1.0)
		draw_line(Vector2(lx, 3.0), Vector2(lx + swing, 8.0), dark, 1.6, true)
	var head := Vector2(f * 10.0, 1.0)
	draw_line(head + Vector2(-f * 1.0, -3.0), head + Vector2(f * 2.0, -8.0), dark, 1.2, true)
	draw_circle(head + Vector2(f * 2.0, -8.0), 1.4, dark, true, -1.0, true)
	draw_circle(head, 5.0, dark, true, -1.0, true)
	var shell: PackedVector2Array = Shapes.dome(Vector2(-f, 4.0), Vector2(11.0, 11.0))
	draw_colored_polygon(shell, Color(0.93, 0.27, 0.3))
	draw_polyline(Shapes.closed(shell), Color(0.5, 0.1, 0.15), 1.2, true)
	draw_line(Vector2(-f, -6.5), Vector2(-f, 4.0), Color(0.4, 0.08, 0.12), 1.2, true)
	for spot: Vector3 in [Vector3(-6.0, -1.0, 2.2), Vector3(3.5, -2.5, 2.0), Vector3(-2.5, -5.0, 1.5), Vector3(5.5, 1.5, 1.4)]:
		draw_circle(Vector2(spot.x, spot.y), spot.z, dark, true, -1.0, true)
	draw_circle(Vector2(-4.0, -4.0), 2.2, Color(1.0, 1.0, 1.0, 0.35), true, -1.0, true)
	var eye := head + Vector2(f * 2.0, -0.5)
	draw_circle(eye, 2.0, Color.WHITE, true, -1.0, true)
	draw_circle(eye + Vector2(f * 0.7, 0.3), 1.0, dark, true, -1.0, true)


func _draw_shroomlet(step: float) -> void:
	var f: float = direction
	var cream := Color(0.97, 0.9, 0.8)
	draw_circle(Vector2(0.0, -2.0), 16.0, Color(theme.accents[1], 0.12), true, -1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(-4.0 + step * 1.5, 7.0), Vector2(3.2, 1.8)), Color(0.8, 0.7, 0.62))
	draw_colored_polygon(Shapes.ellipse(Vector2(4.0 - step * 1.5, 7.0), Vector2(3.2, 1.8)), Color(0.8, 0.7, 0.62))
	draw_rect(Rect2(-6.0, -1.0, 12.0, 7.0), cream)
	draw_circle(Vector2(0.0, 5.0), 6.0, cream, true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 1.5 + side * 2.6, 2.0)
		draw_colored_polygon(Shapes.ellipse(eye, Vector2(1.0, 1.6), 0.0, 8), Color(0.2, 0.12, 0.25))
	draw_circle(Vector2(f * 1.5, 5.0), 1.0, Color(1.0, 0.5, 0.6, 0.7), true, -1.0, true)
	var cap: PackedVector2Array = Shapes.dome(Vector2(0.0, 0.5), Vector2(13.0, 11.0))
	draw_colored_polygon(cap, theme.platform)
	draw_polyline(Shapes.closed(cap), theme.platform_dark, 1.2, true)
	for spot: Vector3 in [Vector3(-6.0, -4.0, 2.2), Vector3(1.0, -7.0, 2.4), Vector3(7.0, -3.0, 1.8)]:
		draw_circle(Vector2(spot.x, spot.y), spot.z, Color(1.0, 0.95, 0.95), true, -1.0, true)


func _draw_crab(step: float) -> void:
	var f: float = direction
	var shell := Color(0.95, 0.42, 0.32)
	var dark := Color(0.6, 0.2, 0.18)
	for side: float in [-1.0, 1.0]:
		for i: int in 3:
			var swing: float = step * 1.8 * (1.0 if (i % 2 == 0) == (side > 0.0) else -1.0)
			var hip := Vector2(side * (4.0 + 2.5 * float(i)), 3.0)
			draw_polyline(PackedVector2Array([hip, hip + Vector2(side * 4.0, -1.0 + swing * 0.5), hip + Vector2(side * 5.0 + swing, 5.0)]), dark, 1.6, true)
		# Claws wave a little as the crab scuttles.
		var claw := Vector2(side * 13.0, -4.0 + step * side * 1.2)
		draw_line(Vector2(side * 8.0, 0.0), claw, shell, 2.5, true)
		draw_circle(claw, 4.0, shell, true, -1.0, true)
		draw_colored_polygon(PackedVector2Array([claw, claw + Vector2(side * 5.0, -3.5), claw + Vector2(side * 5.0, 0.5)]), Color(1.0, 0.9, 0.75))
	var body: PackedVector2Array = Shapes.ellipse(Vector2(0.0, 0.0), Vector2(10.0, 7.0))
	draw_colored_polygon(body, shell)
	draw_polyline(Shapes.closed(body), dark, 1.2, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(0.0, 3.0), Vector2(6.0, 3.0)), Color(1.0, 0.75, 0.6))
	draw_circle(Vector2(-3.0, -3.5), 2.0, Color(1.0, 1.0, 1.0, 0.35), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(side * 3.5 + f * 1.0, -12.0)
		draw_line(Vector2(side * 3.0, -5.0), eye, dark, 1.4, true)
		draw_circle(eye, 2.4, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.8, 0.3), 1.2, Color(0.2, 0.12, 0.2), true, -1.0, true)
	draw_arc(Vector2(f * 1.0, 0.5), 2.5, 0.3, PI - 0.3, 8, dark, 1.0, true)


func _draw_snail(step: float) -> void:
	var f: float = direction
	var gem: Color = theme.accents[3]
	var skin := Color(0.62, 0.86, 0.82)
	draw_circle(Vector2(0.0, -2.0), 16.0, Color(theme.accents[0], 0.1), true, -1.0, true)
	# Soft foot that stretches as it slides.
	draw_colored_polygon(Shapes.ellipse(Vector2(f * 2.0, 5.0), Vector2(11.0 + step * 0.8, 3.5)), skin)
	var head := Vector2(f * 9.0, 0.5)
	draw_circle(head, 4.5, skin, true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var stalk_tip := head + Vector2(f * 2.0 + side * 2.0, -8.0 + side * 0.5)
		draw_line(head + Vector2(side * 1.2, -2.0), stalk_tip, skin.darkened(0.2), 1.4, true)
		draw_circle(stalk_tip, 1.7, Color.WHITE, true, -1.0, true)
		draw_circle(stalk_tip + Vector2(f * 0.6, 0.2), 0.9, Color(0.18, 0.12, 0.25), true, -1.0, true)
	draw_circle(head + Vector2(f * 2.2, 1.6), 1.0, Color(1.0, 0.5, 0.6, 0.7), true, -1.0, true)
	# A shell made of faceted crystal.
	var center := Vector2(-f * 2.5, -3.0)
	var outer: PackedVector2Array = Shapes.ellipse(center, Vector2(9.0, 9.0), PI / 6.0, 6)
	draw_colored_polygon(outer, gem)
	draw_polyline(Shapes.closed(outer), gem.darkened(0.35), 1.2, true)
	draw_colored_polygon(Shapes.ellipse(center, Vector2(5.0, 5.0), 0.0, 6), gem.lightened(0.3))
	for i: int in 3:
		var a: float = PI / 6.0 + TAU * float(i) / 3.0
		draw_line(center, center + Vector2(cos(a), sin(a)) * 9.0, Color(gem.darkened(0.2), 0.7), 1.0, true)
	draw_colored_polygon(Shapes.star(center + Vector2(-3.0, -3.0), 2.6, 0.8, 4), Color(1.0, 1.0, 1.0, 0.9))


func _draw_penguin(step: float) -> void:
	var f: float = direction
	var navy := Color(0.2, 0.25, 0.4)
	var orange := Color(1.0, 0.65, 0.25)
	var waddle: float = step * 0.12
	draw_set_transform(Vector2(0.0, 8.0 * (1.0 - _flatten)), waddle, Vector2(2.0 - _flatten, _flatten))
	draw_colored_polygon(Shapes.ellipse(Vector2(-3.5, 8.0), Vector2(3.0, 1.6)), orange)
	draw_colored_polygon(Shapes.ellipse(Vector2(3.5, 8.0), Vector2(3.0, 1.6)), orange)
	for side: float in [-1.0, 1.0]:
		draw_colored_polygon(Shapes.ellipse(Vector2(side * 8.5, 0.0), Vector2(2.5, 6.0), side * (0.4 + absf(step) * 0.3), 10), navy)
	draw_colored_polygon(Shapes.ellipse(Vector2(0.0, -1.0), Vector2(8.5, 10.0)), navy)
	draw_colored_polygon(Shapes.ellipse(Vector2(f * 1.5, 1.5), Vector2(5.5, 7.0)), Color(0.98, 0.98, 1.0))
	# Cosy scarf.
	var scarf: Color = theme.accents[1]
	draw_rect(Rect2(-7.5, -5.0, 15.0, 3.0), scarf)
	draw_colored_polygon(PackedVector2Array([Vector2(-f * 4.0, -3.0), Vector2(-f * 7.0, 4.0), Vector2(-f * 3.0, 3.0)]), scarf.darkened(0.15))
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 1.5 + side * 3.0, -8.0)
		draw_circle(eye, 1.9, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.6, 0.2), 1.0, Color(0.1, 0.1, 0.2), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(f * 2.0, -6.5), Vector2(f * 7.0, -5.0), Vector2(f * 2.0, -3.8)]), orange)
	draw_circle(Vector2(-3.0, -10.0), 1.8, Color(1.0, 1.0, 1.0, 0.25), true, -1.0, true)


func _draw_acorn(step: float) -> void:
	var f: float = direction
	var dark := Color(0.3, 0.18, 0.14)
	draw_colored_polygon(Shapes.ellipse(Vector2(-3.5 + step * 1.5, 8.0), Vector2(3.0, 1.6)), Color(0.45, 0.28, 0.2))
	draw_colored_polygon(Shapes.ellipse(Vector2(3.5 - step * 1.5, 8.0), Vector2(3.0, 1.6)), Color(0.45, 0.28, 0.2))
	var nut: PackedVector2Array = Shapes.ellipse(Vector2(0.0, 1.0), Vector2(8.5, 8.0))
	draw_colored_polygon(nut, Color(0.82, 0.56, 0.32))
	draw_polyline(Shapes.closed(nut), Color(0.55, 0.34, 0.2), 1.2, true)
	draw_circle(Vector2(-f * 4.0, 3.0), 2.0, Color(1.0, 1.0, 1.0, 0.25), true, -1.0, true)
	# Bumpy cap with a little stem.
	var cap: PackedVector2Array = Shapes.dome(Vector2(0.0, -2.0), Vector2(10.5, 7.5))
	draw_colored_polygon(cap, Color(0.55, 0.37, 0.24))
	draw_polyline(Shapes.closed(cap), Color(0.38, 0.24, 0.16), 1.2, true)
	for dot: Vector2 in [Vector2(-6.0, -4.0), Vector2(-2.0, -6.5), Vector2(2.5, -6.5), Vector2(6.5, -4.0), Vector2(0.0, -3.5), Vector2(-4.0, -3.0), Vector2(4.0, -3.0)]:
		draw_circle(dot, 1.0, Color(0.42, 0.27, 0.18), true, -1.0, true)
	draw_line(Vector2(0.0, -9.0), Vector2(f * 2.0, -13.0), Color(0.42, 0.27, 0.18), 2.2, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 1.5 + side * 3.0, 1.5)
		draw_circle(eye, 1.9, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.6, 0.3), 1.0, dark, true, -1.0, true)
		draw_circle(Vector2(f * 1.5 + side * 5.0, 4.5), 1.1, Color(1.0, 0.5, 0.45, 0.6), true, -1.0, true)
	draw_arc(Vector2(f * 1.5, 4.5), 1.8, 0.3, PI - 0.3, 8, dark, 1.0, true)


func _draw_gummy_bear(step: float) -> void:
	var f: float = direction
	var jelly: Color = _tint
	var edge: Color = jelly.darkened(0.3)
	var wobble: float = 1.0 + step * 0.04
	draw_set_transform(Vector2(0.0, 8.0 * (1.0 - _flatten)), 0.0, Vector2((2.0 - _flatten) / wobble, _flatten * wobble))
	draw_colored_polygon(Shapes.ellipse(Vector2(-4.0, 7.0 - maxf(step, 0.0) * 1.5), Vector2(3.0, 2.2)), jelly)
	draw_colored_polygon(Shapes.ellipse(Vector2(4.0, 7.0 - maxf(-step, 0.0) * 1.5), Vector2(3.0, 2.2)), jelly)
	var body: PackedVector2Array = Shapes.ellipse(Vector2(0.0, 2.0), Vector2(7.0, 6.5))
	draw_colored_polygon(body, jelly)
	draw_polyline(Shapes.closed(body), edge, 1.0, true)
	for side: float in [-1.0, 1.0]:
		draw_colored_polygon(Shapes.ellipse(Vector2(side * 7.0, 1.0), Vector2(2.2, 3.2), side * 0.5, 10), jelly)
		draw_circle(Vector2(side * 4.5, -11.0), 2.6, jelly, true, -1.0, true)
	draw_circle(Vector2(0.0, -6.0), 6.2, jelly, true, -1.0, true)
	draw_arc(Vector2(0.0, -6.0), 6.2, PI * 0.85, TAU + PI * 0.15, 16, edge, 1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(0.0, 3.0), Vector2(3.5, 3.5)), Color(1.0, 1.0, 1.0, 0.25))
	draw_circle(Vector2(-3.0, -9.0), 1.6, Color(1.0, 1.0, 1.0, 0.6), true, -1.0, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(f * 1.5, -4.0), Vector2(2.4, 1.8)), jelly.lightened(0.3))
	draw_circle(Vector2(f * 2.0, -5.0), 0.9, Color(0.2, 0.12, 0.2), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(f * 1.0 + side * 2.6, -7.5), 1.1, Color(0.2, 0.12, 0.2), true, -1.0, true)


func _draw_frog() -> void:
	var f: float = direction
	var skin := Color(0.45, 0.8, 0.4)
	var dark := Color(0.25, 0.52, 0.3)
	# Little hops as it goes.
	var hop: float = absf(sin(_time * 6.0)) * 3.0
	draw_set_transform(Vector2(0.0, 8.0 * (1.0 - _flatten) - hop * _flatten), 0.0, Vector2(2.0 - _flatten, _flatten))
	for side: float in [-1.0, 1.0]:
		draw_colored_polygon(Shapes.ellipse(Vector2(side * 7.0, 5.0 + hop * 0.3), Vector2(4.5, 3.0), side * 0.3, 12), dark)
		draw_colored_polygon(Shapes.ellipse(Vector2(side * 9.0, 8.0 + hop * 0.6), Vector2(3.0, 1.4)), dark)
	var body: PackedVector2Array = Shapes.ellipse(Vector2(0.0, 1.5), Vector2(10.0, 7.0))
	draw_colored_polygon(body, skin)
	draw_polyline(Shapes.closed(body), dark, 1.2, true)
	draw_colored_polygon(Shapes.ellipse(Vector2(f * 1.0, 4.0), Vector2(6.0, 3.5)), Color(0.85, 0.95, 0.7))
	for spot: Vector2 in [Vector2(-5.0, -2.0), Vector2(-1.0, -4.0)]:
		draw_circle(Vector2(spot.x * -f, spot.y), 1.3, dark, true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 2.0 + side * 4.0, -6.0)
		draw_circle(eye, 3.6, skin, true, -1.0, true)
		draw_circle(eye, 2.6, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.8, 0.3), 1.4, Color(0.12, 0.12, 0.2), true, -1.0, true)
	draw_arc(Vector2(f * 2.0, -0.5), 4.5, 0.4, PI - 0.4, 10, dark, 1.2, true)
	draw_circle(Vector2(f * 2.0 - 6.0, 0.5), 1.2, Color(1.0, 0.55, 0.6, 0.6), true, -1.0, true)
	draw_circle(Vector2(f * 2.0 + 6.0, 0.5), 1.2, Color(1.0, 0.55, 0.6, 0.6), true, -1.0, true)


func _draw_grumble_cloud(step: float) -> void:
	var f: float = direction
	var puffs: Array[Vector3] = [Vector3(-6.0, 2.0, 6.0), Vector3(0.0, -2.0, 8.0), Vector3(6.0, 2.0, 6.0), Vector3(0.0, 3.0, 7.0)]
	draw_colored_polygon(Shapes.ellipse(Vector2(-4.0, 8.5 + step), Vector2(2.5, 1.5)), Color(0.35, 0.35, 0.55))
	draw_colored_polygon(Shapes.ellipse(Vector2(4.0, 8.5 - step), Vector2(2.5, 1.5)), Color(0.35, 0.35, 0.55))
	for p: Vector3 in puffs:
		draw_circle(Vector2(p.x, p.y), p.z + 1.3, Color(0.36, 0.36, 0.6), true, -1.0, true)
	for p: Vector3 in puffs:
		draw_circle(Vector2(p.x, p.y), p.z, Color(0.66, 0.68, 0.88), true, -1.0, true)
	draw_circle(Vector2(-2.0, -5.0), 3.0, Color(1.0, 1.0, 1.0, 0.35), true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var eye := Vector2(f * 2.0 + side * 3.0, 1.0)
		draw_circle(eye, 2.0, Color.WHITE, true, -1.0, true)
		draw_circle(eye + Vector2(f * 0.6, 0.4), 1.0, Color(0.2, 0.15, 0.3), true, -1.0, true)
		draw_line(eye + Vector2(-2.0, -3.2 + side * f * 0.8), eye + Vector2(2.0, -3.2 - side * f * 0.8), Color(0.3, 0.28, 0.5), 1.2, true)
