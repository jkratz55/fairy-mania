class_name EnemyHitbox
extends Area2D
## Touching this hurts the player, unless the player lands on top of it (a stomp).

signal stomped(player: Player)

@export var stompable: bool = true
var active: bool = true


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player == null:
			continue
		if stompable and player.can_stomp(global_position.y):
			stomped.emit(player)
			return
		player.hurt(global_position)
