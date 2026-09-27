class_name Thorns
extends Area2D
## Prickly thorns (brambles, glow-thorns or storm crystals depending on the theme). Ouch!

var theme: LevelTheme


func _ready() -> void:
	if theme == null:
		theme = LevelTheme.create("meadow")


func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position + Vector2(0.0, 12.0))


func _draw() -> void:
	draw_rect(Rect2(-16.0, 10.0, 32.0, 6.0), theme.hazard.darkened(0.25))
	draw_circle(Vector2(-12.0, 12.0), 4.0, theme.hazard.darkened(0.25), true, -1.0, true)
	draw_circle(Vector2(12.0, 12.0), 4.0, theme.hazard.darkened(0.25), true, -1.0, true)
	for thorn: Vector2 in [Vector2(-10.0, 13.0), Vector2(0.0, 18.0), Vector2(10.0, 13.0)]:
		var base_y: float = 12.0
		var tip := Vector2(thorn.x, base_y - thorn.y)
		var spike := PackedVector2Array([Vector2(thorn.x - 5.5, base_y), tip, Vector2(thorn.x + 5.5, base_y)])
		draw_colored_polygon(spike, theme.hazard)
		draw_polyline(Shapes.closed(spike), theme.hazard.darkened(0.35), 1.0, true)
		var glint := PackedVector2Array([tip, tip + Vector2(-1.8, 5.0), tip + Vector2(1.8, 5.0)])
		draw_colored_polygon(glint, theme.hazard_tip)
