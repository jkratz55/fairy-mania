class_name Walker
extends CharacterBody2D
## A slow walking critter that turns around at walls and ledges.
## Its look depends on the level theme: ladybug (meadow), shroomlet (woods) or grumble-cloud (sky).

const SPEED: float = 38.0
const GRAVITY: float = 900.0

var theme: LevelTheme
var direction: float = -1.0

var _time: float = 0.0
var _defeated: bool = false
var _flatten: float = 1.0

@onready var hitbox: EnemyHitbox = $Hitbox
@onready var ledge_ray: RayCast2D = $LedgeRay


func _ready() -> void:
	if theme == null:
		theme = LevelTheme.create("meadow")
	hitbox.stomped.connect(_on_stomped)
	_time = randf() * 10.0


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
