class_name Hud
extends CanvasLayer
## Hearts, the pixie dust / flight meter, the dust counter and big friendly messages.

var _player: Player
var _time: float = 0.0
var _panel_style: StyleBoxFlat
var _bar_back_style: StyleBoxFlat
var _bar_fill_style: StyleBoxFlat
var _message_tween: Tween
var _title_tween: Tween

@onready var overlay: Control = $Overlay
@onready var dust_label: Label = $Overlay/DustLabel
@onready var fly_label: Label = $Overlay/FlyLabel
@onready var message: Label = $Message
@onready var sub_message: Label = $SubMessage
@onready var title_card: VBoxContainer = $TitleCard
@onready var level_number: Label = $TitleCard/LevelNumber
@onready var level_title: Label = $TitleCard/LevelTitle
@onready var level_subtitle: Label = $TitleCard/LevelSubtitle


func _ready() -> void:
	overlay.draw.connect(_draw_overlay)
	_panel_style = _rounded(Color(0.25, 0.12, 0.35, 0.4), 14)
	_bar_back_style = _rounded(Color(0.1, 0.05, 0.15, 0.55), 6)
	_bar_fill_style = _rounded(Color(1.0, 0.86, 0.35), 6)
	message.modulate.a = 0.0
	sub_message.modulate.a = 0.0
	title_card.modulate.a = 0.0
	fly_label.visible = false


func bind_player(player: Player) -> void:
	_player = player


func _process(delta: float) -> void:
	_time += delta
	if _player == null:
		return
	dust_label.text = str(_player.dust_total)
	fly_label.visible = _player.is_flying
	fly_label.modulate.a = 0.7 + 0.3 * sin(_time * 8.0)
	overlay.queue_redraw()


func show_message(text: String, duration: float = 1.5) -> void:
	message.text = text
	message.pivot_offset = message.size * 0.5
	_hide_title_card()
	if _message_tween != null:
		_message_tween.kill()
	_message_tween = create_tween()
	message.scale = Vector2(0.6, 0.6)
	message.modulate.a = 1.0
	_message_tween.tween_property(message, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(message, "modulate:a", 0.0, 0.3)


func show_level_title(number_text: String, title: String, subtitle: String) -> void:
	level_number.text = number_text
	level_title.text = title
	level_subtitle.text = subtitle
	_title_tween = create_tween()
	_title_tween.tween_property(title_card, "modulate:a", 1.0, 0.4)
	_title_tween.tween_interval(2.4)
	_title_tween.tween_property(title_card, "modulate:a", 0.0, 0.6)


func _hide_title_card() -> void:
	if _title_tween != null and _title_tween.is_running():
		_title_tween.kill()
		_title_tween = create_tween()
		_title_tween.tween_property(title_card, "modulate:a", 0.0, 0.2)


func show_level_complete(dust: int, final_level: bool) -> void:
	show_message("Level Complete!", 10.0)
	sub_message.text = "You collected %d pixie dust!%s" % [dust, "" if final_level else "\nOn to the next adventure..."]
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(sub_message, "modulate:a", 1.0, 0.4)


func _rounded(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style


func _draw_overlay() -> void:
	if _player == null:
		return
	overlay.draw_style_box(_panel_style, Rect2(8.0, 8.0, 180.0, 58.0))

	# Hearts.
	for i: int in _player.max_hearts:
		var center := Vector2(28.0 + float(i) * 26.0, 24.0)
		var full: bool = i < _player.hearts
		var beat: float = 1.0 + (0.08 * maxf(0.0, sin(_time * 6.0)) if full and _player.hearts == 1 else 0.0)
		overlay.draw_colored_polygon(Shapes.heart(center + Vector2(0.0, 1.5), 9.0 * beat), Color(0.2, 0.05, 0.15, 0.5))
		overlay.draw_colored_polygon(Shapes.heart(center, 9.0 * beat), Color(1.0, 0.38, 0.55) if full else Color(1.0, 1.0, 1.0, 0.22))
		if full:
			overlay.draw_circle(center + Vector2(-3.5, -3.0), 2.0, Color(1.0, 1.0, 1.0, 0.65), true, -1.0, true)

	# Pixie dust meter: fills with dust, then shows remaining flight time.
	var star_center := Vector2(26.0, 49.0)
	var spin: float = _time * (4.0 if _player.is_flying else 1.0)
	overlay.draw_colored_polygon(Shapes.star(star_center, 9.0, 3.2, 4, spin), Color(1.0, 0.88, 0.35))
	overlay.draw_colored_polygon(Shapes.star(star_center, 4.5, 1.6, 4, spin), Color(1.0, 1.0, 0.92))
	var bar := Rect2(40.0, 43.0, 138.0, 12.0)
	overlay.draw_style_box(_bar_back_style, bar)
	var ratio: float = clampf(_player.dust_meter_ratio(), 0.0, 1.0)
	if ratio > 0.0:
		var fill_color := Color(1.0, 0.86, 0.35)
		if _player.is_flying:
			fill_color = Color(1.0, 0.6, 0.85).lerp(Color(1.0, 0.9, 0.45), 0.5 + 0.5 * sin(_time * 6.0))
			if _player.flight_time_left < Player.FLIGHT_WARNING_TIME and fmod(_time, 0.3) < 0.15:
				fill_color = Color(1.0, 1.0, 1.0)
		_bar_fill_style.bg_color = fill_color
		overlay.draw_style_box(_bar_fill_style, Rect2(bar.position, Vector2(maxf(bar.size.x * ratio, 12.0), bar.size.y)))
	if not _player.is_flying:
		for i: int in range(1, Player.DUST_FOR_FLIGHT):
			var x: float = bar.position.x + bar.size.x * float(i) / float(Player.DUST_FOR_FLIGHT)
			overlay.draw_line(Vector2(x, bar.position.y + 3.0), Vector2(x, bar.end.y - 3.0), Color(1.0, 1.0, 1.0, 0.3), 1.0)

	# Dust counter icon (top right).
	var icon := Vector2(overlay.size.x - 96.0, 24.0)
	overlay.draw_colored_polygon(Shapes.star(icon, 10.0, 3.5, 4, _time), Color(1.0, 0.88, 0.35))
	overlay.draw_colored_polygon(Shapes.star(icon, 5.0, 1.8, 4, _time), Color(1.0, 1.0, 0.92))
