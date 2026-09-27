extends Control
## Title screen: play, pick an unlocked level, or quit. Works with mouse, keyboard and controller.

var _time: float = 0.0
var _fairy_home: Vector2

@onready var backdrop: Backdrop = $Backdrop
@onready var fairy: FairyArt = $Fairy
@onready var main_menu: VBoxContainer = %MainMenu
@onready var level_menu: VBoxContainer = %LevelMenu
@onready var play_button: Button = %PlayButton
@onready var levels_button: Button = %LevelsButton
@onready var quit_button: Button = %QuitButton
@onready var back_button: Button = %BackButton
@onready var level_buttons: Array[Button] = [%Level1Button, %Level2Button, %Level3Button]


func _ready() -> void:
	var theme_data := LevelTheme.create("meadow")
	RenderingServer.set_default_clear_color(theme_data.sky_bottom)
	backdrop.setup(theme_data, true)
	fairy.state = "fly"
	_fairy_home = fairy.position
	_add_fairy_sparkles()
	Audio.play_music("title")

	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_show_level_menu)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	back_button.pressed.connect(_show_main_menu)
	quit_button.visible = not OS.has_feature("web")
	for i: int in level_buttons.size():
		var button: Button = level_buttons[i]
		var data := load(Game.LEVELS[i]) as LevelData
		var unlocked: bool = Game.is_level_unlocked(i)
		button.text = "%d. %s" % [i + 1, data.title] if unlocked else "%d. (locked)" % (i + 1)
		button.disabled = not unlocked
		button.pressed.connect(_on_level_pressed.bind(i))
	for button: Button in [play_button, levels_button, quit_button, back_button] + level_buttons:
		button.focus_entered.connect(Audio.sfx.bind("menu_move", 1.0))
	_show_main_menu()


func _process(delta: float) -> void:
	_time += delta
	fairy.position = _fairy_home + Vector2(sin(_time * 0.8) * 28.0, sin(_time * 1.6) * 10.0)
	fairy.facing = 1.0 if cos(_time * 0.8) >= 0.0 else -1.0


func _unhandled_input(event: InputEvent) -> void:
	if level_menu.visible and event.is_action_pressed("ui_cancel"):
		_show_main_menu()
		get_viewport().set_input_as_handled()


func _show_main_menu() -> void:
	level_menu.hide()
	main_menu.show()
	_focus.call_deferred(play_button)


func _show_level_menu() -> void:
	Audio.sfx("menu_select")
	main_menu.hide()
	level_menu.show()
	_focus.call_deferred(level_buttons[0])


func _focus(button: Button) -> void:
	if is_inside_tree():
		button.grab_focus()


func _on_play_pressed() -> void:
	Audio.sfx("menu_select")
	Game.start_level(0)


func _on_level_pressed(index: int) -> void:
	Audio.sfx("menu_select")
	Game.start_level(index)


func _add_fairy_sparkles() -> void:
	var particles := CPUParticles2D.new()
	particles.texture = Fx.soft_texture()
	particles.amount = 40
	particles.lifetime = 1.2
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 6.0
	particles.direction = Vector2.DOWN
	particles.gravity = Vector2(0.0, 40.0)
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 30.0
	particles.scale_amount_min = 0.1
	particles.scale_amount_max = 0.35
	particles.color = Color(1.0, 0.9, 0.6)
	particles.color_ramp = Fx.fade_ramp()
	particles.hue_variation_min = -0.1
	particles.hue_variation_max = 0.1
	particles.show_behind_parent = true
	fairy.add_child(particles)
