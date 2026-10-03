class_name MagicBolt
extends Area2D
## A slow spinning star of the Queen's magic. It hurts Wren and pops when it touches her.
## Bolts fly through walls and platforms and fade away after a few seconds.

const RADIUS: float = 7.0
const LIFETIME: float = 5.0

var velocity: Vector2 = Vector2.ZERO

var _age: float = 0.0


func _ready() -> void:
	add_to_group("magic_bolts")
	collision_layer = 4
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	z_index = 12
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	position += velocity * delta
	if _age > LIFETIME:
		pop()
	queue_redraw()


func pop() -> void:
	Fx.burst(get_parent(), global_position, Color(0.9, 0.5, 1.0), 8, 70.0)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or player.is_knocked_out():
		return
	player.hurt(global_position)
	pop()


func _draw() -> void:
	var fade: float = clampf((LIFETIME - _age) / 0.5, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(_age * 12.0)
	# A short sparkly tail behind it.
	var back: Vector2 = -velocity.normalized()
	for i: int in 3:
		draw_circle(back * (6.0 + 5.0 * float(i)), 4.0 - float(i), Color(0.85, 0.45, 1.0, (0.35 - 0.1 * float(i)) * fade), true, -1.0, true)
	draw_circle(Vector2.ZERO, RADIUS + 4.0 + pulse * 2.0, Color(0.7, 0.3, 1.0, 0.25 * fade), true, -1.0, true)
	draw_colored_polygon(Shapes.star(Vector2.ZERO, RADIUS + 1.5, 3.5, 5, _age * 6.0), Color(0.85, 0.45, 1.0, fade))
	draw_colored_polygon(Shapes.star(Vector2.ZERO, 4.0, 1.8, 5, _age * 6.0), Color(1.0, 0.9, 1.0, fade))
