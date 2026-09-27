class_name PauseMenu
extends CanvasLayer
## Pause with Esc / P / Start (Xbox Menu, PlayStation Options). Fully navigable with a controller.

var enabled: bool = true

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var title_button: Button = %TitleButton


func _ready() -> void:
	hide()
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart_pressed)
	title_button.pressed.connect(_on_title_pressed)
	for button: Button in [resume_button, restart_button, title_button]:
		button.focus_entered.connect(Audio.sfx.bind("menu_move", 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	get_tree().paused = true
	Audio.sfx("pause")
	resume_button.grab_focus.call_deferred()


func close() -> void:
	hide()
	get_tree().paused = false


func _on_restart_pressed() -> void:
	Audio.sfx("menu_select")
	Game.restart_level()


func _on_title_pressed() -> void:
	Audio.sfx("menu_select")
	Game.go_to_title()
