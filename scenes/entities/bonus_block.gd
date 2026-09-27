class_name BonusBlock
extends StaticBody2D
## A star block. Bump it from below to release pixie dust.

const DUST_REWARD: int = 3

var _used: bool = false
var _time: float = 0.0
var _bump_offset: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func bump(player: Player) -> void:
	if _used:
		Audio.sfx("thud")
		return
	_used = true
	player.add_dust(DUST_REWARD)
	Audio.sfx("bump")
	Fx.burst(get_parent(), global_position + Vector2(0.0, -24.0), Color(1.0, 0.9, 0.5), 18, 120.0)
	Fx.popup_text(get_parent(), global_position + Vector2(0.0, -22.0), "+%d" % DUST_REWARD)
	var tween := create_tween()
	tween.tween_property(self, "_bump_offset", -8.0, 0.07)
	tween.tween_property(self, "_bump_offset", 0.0, 0.12)


func _draw() -> void:
	var rect := Rect2(-15.0, -15.0 + _bump_offset, 30.0, 30.0)
	var face: Color = Color(0.74, 0.62, 0.52) if _used else Color(1.0, 0.8, 0.35)
	var edge: Color = Color(0.5, 0.4, 0.35) if _used else Color(0.78, 0.5, 0.18)
	draw_rect(rect.grow(1.0), edge)
	draw_rect(rect, face)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), Color(1.0, 1.0, 1.0, 0.3))
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - 4.0), Vector2(rect.size.x, 4.0)), Color(0.0, 0.0, 0.0, 0.12))
	for corner: Vector2 in [Vector2(-11.0, -11.0), Vector2(11.0, -11.0), Vector2(-11.0, 11.0), Vector2(11.0, 11.0)]:
		draw_circle(corner + Vector2(0.0, _bump_offset), 1.5, edge, true, -1.0, true)
	var center := Vector2(0.0, _bump_offset)
	if _used:
		draw_polyline(Shapes.closed(Shapes.star(center, 8.0, 3.5)), edge, 1.5, true)
	else:
		var pulse: float = 1.0 + 0.1 * sin(_time * 5.0)
		draw_colored_polygon(Shapes.star(center, 9.0 * pulse, 4.0 * pulse), Color(1.0, 1.0, 0.92))
		draw_polyline(Shapes.closed(Shapes.star(center, 9.0 * pulse, 4.0 * pulse)), Color(1.0, 0.6, 0.75), 1.2, true)
