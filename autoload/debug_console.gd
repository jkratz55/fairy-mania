extends CanvasLayer
## Developer console: press ~ (the key left of 1) to open it, then type `help`.
## The game pauses while it is open. It only exists in debug builds (the editor and debug exports),
## so players of a release build can never open it by accident.
## Commands can also run at startup: `godot --path . -- --console "god on; level 3 40"`.

const MAX_LINES: int = 300
const MAX_HISTORY: int = 50
const PANEL_HEIGHT: float = 176.0
const COLOR_ECHO: String = "#b9a6e8"
const COLOR_OK: String = "#9df0b4"
const COLOR_ERROR: String = "#ff8fa8"
const COLOR_NAME: String = "#ffd76e"


class Command:
	var usage: String
	var description: String
	## Called with the words typed after the command name.
	var run: Callable

	func _init(p_usage: String, p_description: String, p_run: Callable) -> void:
		usage = p_usage
		description = p_description
		run = p_run


var _commands: Dictionary[String, Command] = {}
var _aliases: Dictionary[String, String] = {}
var _history: PackedStringArray = PackedStringArray()
var _history_index: int = 0
var _was_paused: bool = false
var _previous_focus: Control
var _show_fps: bool = false

var _panel: PanelContainer
var _output: RichTextLabel
var _line: LineEdit
var _status: Label


func _ready() -> void:
	layer = 110  # Above the scene fade, so it stays readable during level changes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build():
		set_process(false)
		set_process_input(false)
		return
	_build_ui()
	_register_commands()
	_print("Fairy Mania debug console. Type [color=%s]help[/color] for a list of commands." % COLOR_NAME)
	_run_startup_commands()


func _process(_delta: float) -> void:
	var flags: PackedStringArray = PackedStringArray()
	if Game.debug_invincible:
		flags.append("GOD")
	if Game.debug_infinite_flight:
		flags.append("INFINITE FLIGHT")
	if not is_equal_approx(Engine.time_scale, 1.0):
		flags.append("SPEED x%.2f" % Engine.time_scale)
	if _show_fps:
		flags.append("%d FPS" % Engine.get_frames_per_second())
	_status.text = "  ".join(flags)
	_status.visible = not flags.is_empty()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		if is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_UP:
			_browse_history(-1)
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			_browse_history(1)
			get_viewport().set_input_as_handled()
		KEY_TAB:
			_complete()
			get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _panel != null and _panel.visible


func open() -> void:
	if is_open():
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	_previous_focus = get_viewport().gui_get_focus_owner()
	_panel.show()
	_line.clear()
	_line.grab_focus()
	_line.edit()


func close() -> void:
	if not is_open():
		return
	_panel.hide()
	_line.release_focus()
	get_tree().paused = _was_paused
	if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null


## Runs one console line, e.g. "level 3 40".
func execute(line: String) -> void:
	var words: PackedStringArray = line.strip_edges().split(" ", false)
	if words.is_empty():
		return
	var command_name: String = words[0].to_lower()
	command_name = _aliases.get(command_name, command_name)
	if not _commands.has(command_name):
		_error("Unknown command '%s'. Type help for a list." % _escape(words[0]))
		return
	_commands[command_name].run.call(words.slice(1))


# --- Commands -----------------------------------------------------------------

func _register_commands() -> void:
	_add("help", "help [command]", "List commands, or explain one.", _cmd_help)
	_add("levels", "levels", "List every level and whether it is unlocked.", _cmd_levels)
	_add("level", "level <number> [column]", "Warp to a level, optionally starting at a tile column.", _cmd_level, ["warp", "lvl"])
	_add("restart", "restart", "Restart the current level.", _cmd_restart)
	_add("next", "next", "Finish the current level and go on to the next one.", _cmd_next, ["skip"])
	_add("title", "title", "Go back to the title screen.", _cmd_title)
	_add("god", "god [on|off]", "Toggle invincibility: no damage, and pits float you back up.", _cmd_god, ["invincible"])
	_add("fly", "fly", "Fill the dust meter and start flying.", _cmd_fly)
	_add("infiniteflight", "infiniteflight [on|off]", "Toggle flight that never runs out.", _cmd_infinite_flight, ["ifly"])
	_add("dust", "dust <amount>", "Give Wren pixie dust.", _cmd_dust)
	_add("hearts", "hearts [amount]", "Set Wren's hearts (full if no amount).", _cmd_hearts, ["heal"])
	_add("goto", "goto <column>", "Teleport to a tile column in this level.", _cmd_goto, ["tp"])
	_add("kill", "kill", "Knock Wren out (respawns at the last lantern).", _cmd_kill)
	_add("unlock", "unlock <count|all>", "Set how many levels are unlocked (saved).", _cmd_unlock)
	_add("speed", "speed <multiplier>", "Change the game speed (1 is normal, 0.25 to 4).", _cmd_speed)
	_add("mute", "mute [on|off]", "Toggle all sound.", _cmd_mute)
	_add("fps", "fps [on|off]", "Toggle the frames-per-second readout.", _cmd_fps)
	_add("clear", "clear", "Clear the console.", _cmd_clear, ["cls"])
	_add("close", "close", "Close the console (or press ~ / Esc).", _cmd_close, ["exit"])


func _add(command_name: String, usage: String, description: String, run: Callable, aliases: Array[String] = []) -> void:
	_commands[command_name] = Command.new(usage, description, run)
	for alias: String in aliases:
		_aliases[alias] = command_name


func _cmd_help(args: PackedStringArray) -> void:
	if not args.is_empty():
		var command_name: String = args[0].to_lower()
		command_name = _aliases.get(command_name, command_name)
		if not _commands.has(command_name):
			_error("Unknown command '%s'." % _escape(args[0]))
			return
		var command: Command = _commands[command_name]
		_print("[color=%s]%s[/color]  %s" % [COLOR_NAME, command.usage, command.description])
		var aliases: PackedStringArray = PackedStringArray()
		for alias: String in _aliases:
			if _aliases[alias] == command_name:
				aliases.append(alias)
		if not aliases.is_empty():
			_print("  also: " + ", ".join(aliases))
		return
	for command_name: String in _commands:
		var command: Command = _commands[command_name]
		_print("[color=%s]%s[/color]  %s" % [COLOR_NAME, command.usage, command.description])
	_print("Up/Down: history   Tab: complete   ~ or Esc: close")


func _cmd_levels(_args: PackedStringArray) -> void:
	for i: int in Game.level_count():
		var data := load(Game.LEVELS[i]) as LevelData
		var notes: String = "" if Game.is_level_unlocked(i) else "  locked"
		if _level() != null and i == Game.current_level:
			notes += "  <- you are here"
		_print("%d. %s (%s)%s" % [i + 1, data.title, data.theme, notes])


func _cmd_level(args: PackedStringArray) -> void:
	if args.is_empty() or not args[0].is_valid_int():
		_error("Usage: level <1-%d> [column]" % Game.level_count())
		return
	var number: int = args[0].to_int()
	if number < 1 or number > Game.level_count():
		_error("There are only %d levels." % Game.level_count())
		return
	if args.size() > 1:
		if not args[1].is_valid_int():
			_error("The column must be a whole number.")
			return
		Game.debug_start_column = maxi(args[1].to_int(), 0)
	_ok("Warping to level %d..." % number)
	_was_paused = false
	close()
	Game.start_level(number - 1)


func _cmd_restart(_args: PackedStringArray) -> void:
	if _require_level() == null:
		return
	_was_paused = false
	close()
	Game.restart_level()


func _cmd_next(_args: PackedStringArray) -> void:
	var level: Level = _require_level()
	if level == null:
		return
	if level.is_finished():
		_error("This level is already finished.")
		return
	_was_paused = false
	close()
	Game.complete_level(level.player.dust_total)


func _cmd_title(_args: PackedStringArray) -> void:
	_was_paused = false
	close()
	Game.go_to_title()


func _cmd_god(args: PackedStringArray) -> void:
	var value: Variant = _parse_toggle(args, Game.debug_invincible)
	if value == null:
		return
	Game.debug_invincible = value
	_ok("Invincibility %s." % _on_off(Game.debug_invincible))


func _cmd_fly(_args: PackedStringArray) -> void:
	var player: Player = _require_player()
	if player == null:
		return
	player.fill_dust_meter()
	_ok("Fly, Wren, fly!")


func _cmd_infinite_flight(args: PackedStringArray) -> void:
	var value: Variant = _parse_toggle(args, Game.debug_infinite_flight)
	if value == null:
		return
	Game.debug_infinite_flight = value
	_ok("Infinite flight %s." % _on_off(Game.debug_infinite_flight))
	var player: Player = _player()
	if Game.debug_infinite_flight and player != null and not player.is_flying:
		_print("Use fly to take off.")


func _cmd_dust(args: PackedStringArray) -> void:
	var player: Player = _require_player()
	if player == null:
		return
	if args.is_empty() or not args[0].is_valid_int() or args[0].to_int() < 1:
		_error("Usage: dust <amount>")
		return
	player.add_dust(args[0].to_int())
	_ok("Added %d dust (total %d)." % [args[0].to_int(), player.dust_total])


func _cmd_hearts(args: PackedStringArray) -> void:
	var player: Player = _require_player()
	if player == null:
		return
	var amount: int = player.max_hearts
	if not args.is_empty():
		if not args[0].is_valid_int():
			_error("Usage: hearts [1-%d]" % player.max_hearts)
			return
		amount = clampi(args[0].to_int(), 1, player.max_hearts)
	player.hearts = amount
	_ok("Hearts set to %d." % amount)


func _cmd_goto(args: PackedStringArray) -> void:
	var level: Level = _require_level()
	if level == null:
		return
	if args.is_empty() or not args[0].is_valid_int():
		_error("Usage: goto <0-%d>" % (level.columns - 1))
		return
	var column: int = clampi(args[0].to_int(), 0, level.columns - 1)
	level.player.global_position = level.standing_position(column)
	level.player.velocity = Vector2.ZERO
	level.player.camera.reset_smoothing()
	_ok("Teleported to column %d." % column)


func _cmd_kill(_args: PackedStringArray) -> void:
	var player: Player = _require_player()
	if player == null:
		return
	if player.is_knocked_out():
		_error("Wren is already knocked out.")
		return
	player.knock_out()
	_ok("Oops!")


func _cmd_unlock(args: PackedStringArray) -> void:
	if args.is_empty():
		_error("Usage: unlock <count|all>")
		return
	var count: int
	if args[0].to_lower() == "all":
		count = Game.level_count()
	elif args[0].is_valid_int():
		count = args[0].to_int()
	else:
		_error("Usage: unlock <count|all>")
		return
	Game.unlock_levels(count)
	_ok("%d of %d levels unlocked. Reopen the title screen's level menu to see it." % [Game.unlocked_levels, Game.level_count()])


func _cmd_speed(args: PackedStringArray) -> void:
	if args.is_empty() or not args[0].is_valid_float():
		_error("Usage: speed <0.25-4>")
		return
	Engine.time_scale = clampf(args[0].to_float(), 0.25, 4.0)
	_ok("Game speed x%.2f." % Engine.time_scale)


func _cmd_mute(args: PackedStringArray) -> void:
	var master: int = AudioServer.get_bus_index("Master")
	var value: Variant = _parse_toggle(args, AudioServer.is_bus_mute(master))
	if value == null:
		return
	AudioServer.set_bus_mute(master, value)
	_ok("Sound %s." % ("muted" if AudioServer.is_bus_mute(master) else "on"))


func _cmd_fps(args: PackedStringArray) -> void:
	var value: Variant = _parse_toggle(args, _show_fps)
	if value == null:
		return
	_show_fps = value
	_ok("FPS readout %s." % _on_off(_show_fps))


func _cmd_clear(_args: PackedStringArray) -> void:
	_output.clear()


func _cmd_close(_args: PackedStringArray) -> void:
	close()


# --- Helpers ------------------------------------------------------------------

func _level() -> Level:
	return get_tree().current_scene as Level


func _player() -> Player:
	var level: Level = _level()
	return level.player if level != null else null


func _require_level() -> Level:
	var level: Level = _level()
	if level == null or level.player == null:
		_error("Start a level first (try: level 1).")
		return null
	return level


func _require_player() -> Player:
	var level: Level = _require_level()
	return level.player if level != null else null


## Returns true/false for "on"/"off" (or flips `current` when no word is given), or null if invalid.
func _parse_toggle(args: PackedStringArray, current: bool) -> Variant:
	if args.is_empty():
		return not current
	match args[0].to_lower():
		"on", "1", "true", "yes":
			return true
		"off", "0", "false", "no":
			return false
	_error("Expected on or off.")
	return null


func _on_off(value: bool) -> String:
	return "on" if value else "off"


func _on_submitted(text: String) -> void:
	_line.clear()
	var line: String = text.strip_edges()
	if line.is_empty():
		return
	_echo(line)
	if _history.is_empty() or _history[_history.size() - 1] != line:
		_history.append(line)
		if _history.size() > MAX_HISTORY:
			_history.remove_at(0)
	_history_index = _history.size()
	execute(line)


## Runs the `;`-separated commands passed with `-- --console "..."` once the first scene is up.
func _run_startup_commands() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--console")
	if index < 0 or index + 1 >= args.size():
		return
	for i: int in 3:
		await get_tree().process_frame
	for line: String in args[index + 1].split(";", false):
		_echo(line.strip_edges())
		execute(line)


func _echo(line: String) -> void:
	_print("[color=%s]> %s[/color]" % [COLOR_ECHO, _escape(line)])


func _browse_history(step: int) -> void:
	if _history.is_empty():
		return
	_history_index = clampi(_history_index + step, 0, _history.size())
	_line.text = _history[_history_index] if _history_index < _history.size() else ""
	_line.caret_column = _line.text.length()


func _complete() -> void:
	var typed: String = _line.text.strip_edges().to_lower()
	if typed.is_empty() or typed.contains(" "):
		return
	var matches: PackedStringArray = PackedStringArray()
	for command_name: String in _commands:
		if command_name.begins_with(typed):
			matches.append(command_name)
	if matches.size() == 1:
		_line.text = matches[0] + " "
		_line.caret_column = _line.text.length()
	elif matches.size() > 1:
		_print("  ".join(matches))


func _print(bbcode: String) -> void:
	print_rich("[console] " + bbcode)
	_output.append_text(bbcode + "\n")
	while _output.get_paragraph_count() > MAX_LINES:
		_output.remove_paragraph(0)


func _ok(text: String) -> void:
	_print("[color=%s]%s[/color]" % [COLOR_OK, text])


func _error(text: String) -> void:
	_print("[color=%s]%s[/color]" % [COLOR_ERROR, text])


func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


func _build_ui() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "Liberation Mono", "Monospace"])

	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 6)
	_status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_status.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_status.add_theme_font_override("font", font)
	_status.add_theme_font_size_override("font_size", 9)
	_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_status.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.2))
	_status.add_theme_constant_override("outline_size", 4)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.visible = false
	add_child(_status)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_bottom = PANEL_HEIGHT
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.05, 0.14, 0.93)
	background.border_width_bottom = 2
	background.border_color = Color(0.96, 0.45, 0.7)
	background.content_margin_left = 6.0
	background.content_margin_right = 6.0
	background.content_margin_top = 4.0
	background.content_margin_bottom = 4.0
	_panel.add_theme_stylebox_override("panel", background)
	_panel.visible = false
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_panel.add_child(column)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.focus_mode = Control.FOCUS_NONE
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_font_override("normal_font", font)
	_output.add_theme_font_size_override("normal_font_size", 9)
	_output.add_theme_color_override("default_color", Color(0.93, 0.9, 0.98))
	_output.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	column.add_child(_output)

	_line = LineEdit.new()
	_line.placeholder_text = "Type a command (help for a list)"
	_line.keep_editing_on_text_submit = true
	_line.context_menu_enabled = false
	_line.add_theme_font_override("font", font)
	_line.add_theme_font_size_override("font_size", 10)
	_line.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_line.add_theme_color_override("font_placeholder_color", Color(0.7, 0.65, 0.8, 0.6))
	_line.add_theme_color_override("caret_color", Color(1.0, 0.85, 0.45))
	var field := StyleBoxFlat.new()
	field.bg_color = Color(0.16, 0.1, 0.25)
	field.set_corner_radius_all(3)
	field.content_margin_left = 6.0
	field.content_margin_right = 6.0
	field.content_margin_top = 2.0
	field.content_margin_bottom = 2.0
	for state: String in ["normal", "focus", "read_only"]:
		_line.add_theme_stylebox_override(state, field)
	_line.text_submitted.connect(_on_submitted)
	column.add_child(_line)
