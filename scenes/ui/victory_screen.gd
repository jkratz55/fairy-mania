extends Control
## Shown after the last level: a celebration with fireworks of sparkles.

var _time: float = 0.0
var _firework_timer: float = 0.0

@onready var backdrop: Backdrop = $Backdrop
@onready var fairy: FairyArt = $Fairy
@onready var fireworks: Node2D = $Fireworks
@onready var stats: Label = %Stats
@onready var again_button: Button = %AgainButton
@onready var title_button: Button = %TitleButton


func _ready() -> void:
	var theme_data := LevelTheme.create("sky")
	RenderingServer.set_default_clear_color(theme_data.sky_bottom)
	backdrop.setup(theme_data, true)
	fairy.state = "celebrate"
	stats.text = "You collected %d pixie dust on your journey!" % Game.session_dust
	again_button.pressed.connect(_on_again_pressed)
	title_button.pressed.connect(_on_title_pressed)
	for button: Button in [again_button, title_button]:
		button.focus_entered.connect(Audio.sfx.bind("menu_move", 1.0))
	Audio.play_music("title")
	Audio.sfx("goal")
	again_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	fairy.position.y = 250.0 + sin(_time * 2.0) * 6.0
	_firework_timer -= delta
	if _firework_timer <= 0.0:
		_firework_timer = randf_range(0.35, 0.8)
		var colors: Array[Color] = [Color(1.0, 0.85, 0.4), Color(1.0, 0.6, 0.85), Color(0.6, 0.9, 1.0), Color(0.8, 0.7, 1.0)]
		var at := Vector2(randf_range(40.0, size.x - 40.0), randf_range(30.0, 160.0))
		Fx.burst(fireworks, at, colors.pick_random(), 30, 160.0)
		Audio.sfx("dust", randf_range(0.7, 1.3))


func _on_again_pressed() -> void:
	Audio.sfx("menu_select")
	Game.start_level(0)


func _on_title_pressed() -> void:
	Audio.sfx("menu_select")
	Game.go_to_title()
