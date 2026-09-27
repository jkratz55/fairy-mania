class_name HintSign
extends Area2D
## A little wooden sign. Walk up to it and a speech bubble with a tip appears.

var text: String = ""

var _time: float = 0.0
var _player_near: bool = false
var _bubble: PanelContainer


func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void: _player_near = _player_near or body is Player)
	body_exited.connect(func(body: Node2D) -> void: _player_near = _player_near and body is not Player)
	_build_bubble()


func _process(delta: float) -> void:
	_time += delta
	var target: float = 1.0 if _player_near else 0.0
	_bubble.modulate.a = move_toward(_bubble.modulate.a, target, delta * 5.0)
	_bubble.visible = _bubble.modulate.a > 0.01
	_bubble.position = Vector2(-_bubble.size.x * 0.5, -30.0 - _bubble.size.y + (1.0 - _bubble.modulate.a) * 6.0)
	queue_redraw()


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.98, 0.93, 0.96)
	style.border_color = Color(0.62, 0.45, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8.0)
	_bubble.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(190.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.35, 0.2, 0.45))
	label.add_theme_constant_override("outline_size", 0)
	_bubble.add_child(label)
	_bubble.z_index = 30
	_bubble.modulate.a = 0.0
	_bubble.visible = false
	add_child(_bubble)


func _draw() -> void:
	var wood := Color(0.82, 0.6, 0.38)
	var wood_dark := Color(0.55, 0.36, 0.22)
	draw_rect(Rect2(-2.0, -2.0, 4.0, 18.0), wood_dark)
	var board := Rect2(-13.0, -16.0, 26.0, 16.0)
	draw_rect(board, wood)
	draw_rect(board, wood_dark, false, 1.5)
	for i: int in 2:
		draw_line(Vector2(-8.0, -11.0 + 6.0 * float(i)), Vector2(8.0, -11.0 + 6.0 * float(i)), wood_dark, 1.2, true)
	if not _player_near:
		var y: float = -26.0 + sin(_time * 3.0) * 2.0
		draw_circle(Vector2(0.0, y), 6.0, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(-3.0, y + 4.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(0.6, 0.4, 0.8))
