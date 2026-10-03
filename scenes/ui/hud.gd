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
var _dialogue_tween: Tween
var _dialogue: PanelContainer
var _dialogue_name: Label
var _dialogue_text: Label
## Boss health shown as a row of pips (0 total hides the bar).
var _boss_title: String = ""
var _boss_total: int = 0
var _boss_left: int = 0

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
	_build_dialogue_box()


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


func show_level_complete(dust: int, final_level: bool, headline: String = "Level Complete!", detail: String = "") -> void:
	show_message(headline, 10.0)
	sub_message.text = "You collected %d pixie dust!%s" % [dust, "" if final_level else "\nOn to the next adventure..."]
	if not detail.is_empty():
		sub_message.text = detail + "\n" + sub_message.text
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(sub_message, "modulate:a", 1.0, 0.4)


## A speech box at the bottom of the screen, e.g. the Queen talking.
func show_dialogue(speaker: String, text: String, duration: float = 3.0) -> void:
	_dialogue_name.text = speaker
	_dialogue_text.text = text
	if _dialogue_tween != null:
		_dialogue_tween.kill()
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue, "modulate:a", 1.0, 0.2)
	_dialogue_tween.tween_interval(duration)
	_dialogue_tween.tween_property(_dialogue, "modulate:a", 0.0, 0.4)


func show_boss_bar(title: String, total: int, left: int) -> void:
	_boss_title = title
	_boss_total = total
	_boss_left = left


func set_boss_bar(left: int) -> void:
	_boss_left = left


func hide_boss_bar() -> void:
	_boss_total = 0


func _build_dialogue_box() -> void:
	_dialogue = PanelContainer.new()
	# Sits at the top (under the boss bar) so it never hides the floor Wren is running on.
	_dialogue.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_dialogue.offset_left = -190.0
	_dialogue.offset_right = 190.0
	_dialogue.offset_top = 50.0
	_dialogue.offset_bottom = 96.0
	_dialogue.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialogue.grow_vertical = Control.GROW_DIRECTION_END
	_dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _rounded(Color(0.16, 0.07, 0.24, 0.82), 12)
	style.border_color = Color(0.85, 0.5, 1.0)
	style.set_border_width_all(2)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 8.0
	_dialogue.add_theme_stylebox_override("panel", style)
	_dialogue.modulate.a = 0.0
	add_child(_dialogue)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	_dialogue.add_child(column)
	_dialogue_name = Label.new()
	_dialogue_name.add_theme_font_size_override("font_size", 11)
	_dialogue_name.add_theme_color_override("font_color", Color(0.95, 0.65, 1.0))
	column.add_child(_dialogue_name)
	_dialogue_text = Label.new()
	_dialogue_text.add_theme_font_size_override("font_size", 12)
	_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_dialogue_text)


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

	if _boss_total > 0:
		_draw_boss_bar()

	# Dust counter icon (top right).
	var icon := Vector2(overlay.size.x - 96.0, 24.0)
	overlay.draw_colored_polygon(Shapes.star(icon, 10.0, 3.5, 4, _time), Color(1.0, 0.88, 0.35))
	overlay.draw_colored_polygon(Shapes.star(icon, 5.0, 1.8, 4, _time), Color(1.0, 1.0, 0.92))


## The Magic Mirror's strength: one little mirror per hit left, cracked ones drawn broken.
func _draw_boss_bar() -> void:
	var width: float = 64.0 + 30.0 * float(_boss_total)
	var panel := Rect2(overlay.size.x * 0.5 - width * 0.5, 8.0, width, 36.0)
	overlay.draw_style_box(_panel_style, panel)
	var font: Font = overlay.get_theme_default_font()
	overlay.draw_string(font, Vector2(panel.position.x, panel.position.y + 13.0), _boss_title, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 11, Color(0.95, 0.8, 1.0))
	for i: int in _boss_total:
		var center := Vector2(panel.get_center().x + (float(i) - float(_boss_total - 1) * 0.5) * 26.0, panel.position.y + 25.0)
		var whole: bool = i < _boss_left
		overlay.draw_colored_polygon(Shapes.ellipse(center, Vector2(7.0, 8.5)), Color(1.0, 0.8, 0.38) if whole else Color(0.6, 0.5, 0.45, 0.6))
		overlay.draw_colored_polygon(Shapes.ellipse(center, Vector2(4.8, 6.3)), Color(0.75, 0.4, 1.0) if whole else Color(0.15, 0.1, 0.2))
		if whole:
			overlay.draw_circle(center + Vector2(-1.5, -2.5), 1.4, Color(1.0, 1.0, 1.0, 0.7), true, -1.0, true)
		else:
			overlay.draw_polyline(PackedVector2Array([center + Vector2(-4.0, -5.0), center + Vector2(1.0, -1.0), center + Vector2(-1.0, 2.0), center + Vector2(4.0, 5.0)]), Color(1.0, 1.0, 1.0, 0.8), 1.2, true)
