class_name FairyQueen
extends Node2D
## Queen Nightshade, the Evil Fairy Queen. She flies like Wren, guards her Magic Mirror and
## shoots slow stars of magic at Wren. Wren can't hurt her: touching her shield just bounces
## Wren away. Every few spells she swoops across the arena, leaving the mirror unguarded.
## The BossFight sets her up and tells her when the mirror cracks or breaks.

signal fled

const SCALE: float = 1.6
const SHIELD_RADIUS: float = 26.0
const ACCEL: float = 520.0
const GUARD_SPEED: float = 95.0
const SWOOP_SPEED: float = 240.0
const CHARGE_TIME: float = 0.7
const STUN_TIME: float = 1.2
const SWOOP_HOLD_TIME: float = 1.6
const SPELLS_BEFORE_SWOOP: int = 3
## Per phase (mirror cracks so far): time between spells and bolt speed. Gentle for young players.
const SPELL_GAPS: Array[float] = [2.6, 2.2, 1.9]
const BOLT_SPEEDS: Array[float] = [115.0, 130.0, 145.0]

## The world rectangle she may fly in.
var arena: Rect2
## Where she hovers in front of the mirror.
var guard_point: Vector2
var mirror: MagicMirror
var player: Player
## Mirror cracks so far: higher phases cast faster and fancier spells.
var phase: int = 0

var _state: String = "idle"
var _velocity: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _state_time: float = 0.0
var _spell_timer: float = 2.0
var _charging: bool = false
var _charge_time: float = 0.0
var _spells_since_swoop: int = 0
var _spell_count: int = 0
var _swoop_target: Vector2
var _shield_cooldown: float = 0.0
var _art: QueenArt
var _shield: Area2D


func _ready() -> void:
	_art = QueenArt.new()
	_art.scale = Vector2(SCALE, SCALE)
	add_child(_art)
	_shield = Area2D.new()
	_shield.collision_layer = 4
	_shield.collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = SHIELD_RADIUS
	var collider := CollisionShape2D.new()
	collider.shape = shape
	_shield.add_child(collider)
	add_child(_shield)
	z_index = 5


## Starts (or resumes) the battle.
func begin() -> void:
	if _state == "idle":
		_set_state("guard")
		_spell_timer = 2.0


## Stops attacking and floats back to the mirror (Wren was knocked out).
func reset() -> void:
	if _state == "defeated":
		return
	_set_state("idle")
	_charging = false
	_art.charge = 0.0
	_art.state = "float"


func on_mirror_cracked(hits: int) -> void:
	phase = clampi(hits, 0, SPELL_GAPS.size() - 1)
	_charging = false
	_art.charge = 0.0
	_set_state("stunned")


func lose_power() -> void:
	_charging = false
	_art.charge = 0.0
	_art.powerless = true
	_art.state = "hurt"
	_set_state("defeated")
	var tween := create_tween()
	tween.tween_interval(2.6)
	tween.tween_callback(func() -> void:
		_art.state = "defeated"
		Audio.sfx("queen_flee"))
	tween.tween_property(self, "position", position + Vector2(260.0, -420.0), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0.35, 0.35), 2.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 2.2)
	tween.tween_callback(fled.emit)


func is_defeated() -> bool:
	return _state == "defeated"


func _set_state(state: String) -> void:
	_state = state
	_state_time = 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	_state_time += delta
	_shield_cooldown = maxf(_shield_cooldown - delta, 0.0)
	if _state == "defeated":
		return
	var target: Vector2 = _target_position()
	var speed: float = SWOOP_SPEED if _state in ["swoop_out", "swoop_back"] else GUARD_SPEED
	var desired: Vector2 = ((target - global_position) * 3.0).limit_length(speed)
	_velocity = _velocity.move_toward(desired, ACCEL * delta)
	global_position += _velocity * delta
	global_position = global_position.clamp(arena.position, arena.end)
	if player != null:
		_art.facing = signf(player.global_position.x - global_position.x) if absf(player.global_position.x - global_position.x) > 4.0 else _art.facing
	_update_state(delta)
	_check_shield()


func _target_position() -> Vector2:
	match _state:
		"swoop_out", "swoop_hold":
			return _swoop_target
		"guard":
			if player != null and mirror != null and absf(player.global_position.x - mirror.global_position.x) < 7.0 * 32.0:
				# Wren is close to the mirror: get in her way.
				var block_y: float = clampf(player.global_position.y - 8.0, arena.position.y + 24.0, arena.end.y - 24.0)
				return Vector2(mirror.global_position.x - 4.0 * 32.0, block_y)
			return guard_point + Vector2(sin(_time * 0.7) * 40.0, sin(_time * 1.3) * 48.0)
	return guard_point + Vector2(0.0, sin(_time * 1.3) * 10.0)


func _update_state(delta: float) -> void:
	match _state:
		"idle":
			_art.state = "float"
		"stunned":
			_art.state = "hurt"
			if _state_time > STUN_TIME:
				_art.state = "float"
				_spell_timer = 0.3
				_set_state("guard")
		"guard":
			_tick_spells(delta)
			if _spells_since_swoop >= SPELLS_BEFORE_SWOOP and not _charging:
				_spells_since_swoop = 0
				_start_swoop()
		"swoop_out":
			if global_position.distance_to(_swoop_target) < 20.0:
				_set_state("swoop_hold")
		"swoop_hold":
			if _state_time > SWOOP_HOLD_TIME * 0.4 and _state_time - delta <= SWOOP_HOLD_TIME * 0.4:
				_fire_aimed(BOLT_SPEEDS[phase])
				Audio.sfx("magic_shot")
			if _state_time > SWOOP_HOLD_TIME:
				_set_state("swoop_back")
		"swoop_back":
			if global_position.distance_to(guard_point) < 40.0:
				_spell_timer = SPELL_GAPS[phase] * 0.6
				_set_state("guard")


func _start_swoop() -> void:
	# Fly across to the far side of the arena, at about Wren's height.
	var height: float = player.global_position.y - 40.0 if player != null else guard_point.y
	_swoop_target = Vector2(arena.position.x + 80.0, clampf(height, arena.position.y + 40.0, arena.end.y - 60.0))
	_set_state("swoop_out")
	_art.state = "float"


func _tick_spells(delta: float) -> void:
	if _charging:
		_charge_time += delta
		_art.charge = clampf(_charge_time / CHARGE_TIME, 0.0, 1.0)
		if _charge_time >= CHARGE_TIME:
			_charging = false
			_art.charge = 0.0
			_art.state = "float"
			_cast()
		return
	_spell_timer -= delta
	if _spell_timer <= 0.0 and player != null and not player.is_knocked_out():
		_charging = true
		_charge_time = 0.0
		_art.state = "cast"
		Audio.sfx("magic_charge")


func _cast() -> void:
	var speed: float = BOLT_SPEEDS[phase]
	_spell_count += 1
	match phase:
		0:
			_fire_aimed(speed)
		1:
			if _spell_count % 2 == 0:
				_fire_spread(speed, 3, 0.32)
			else:
				_fire_aimed(speed)
		_:
			if _spell_count % 3 == 0:
				_fire_ring(speed * 0.75, 8)
			else:
				_fire_spread(speed, 3, 0.3)
	Audio.sfx("magic_shot")
	_spell_timer = SPELL_GAPS[phase]
	_spells_since_swoop += 1


func _wand_position() -> Vector2:
	return global_position + Vector2(_art.facing * 14.0, -14.0)


func _aim() -> Vector2:
	if player == null:
		return Vector2.LEFT
	return (player.global_position - _wand_position()).normalized()


func _fire_aimed(speed: float) -> void:
	_spawn_bolt(_aim() * speed)


func _fire_spread(speed: float, count: int, gap: float) -> void:
	var center: Vector2 = _aim()
	for i: int in count:
		_spawn_bolt(center.rotated((float(i) - float(count - 1) * 0.5) * gap) * speed)


func _fire_ring(speed: float, count: int) -> void:
	var offset: float = randf() * TAU
	for i: int in count:
		_spawn_bolt(Vector2.from_angle(offset + TAU * float(i) / float(count)) * speed)


func _spawn_bolt(velocity: Vector2) -> void:
	var bolt := MagicBolt.new()
	bolt.velocity = velocity
	bolt.position = get_parent().to_local(_wand_position())
	get_parent().add_child(bolt)
	Fx.burst(get_parent(), bolt.position, Color(0.9, 0.55, 1.0), 6, 60.0)


## Her shield gently bounces Wren away. Wren can't hurt her, and the shield doesn't hurt Wren.
func _check_shield() -> void:
	if _shield_cooldown > 0.0:
		return
	for body: Node2D in _shield.get_overlapping_bodies():
		var touched := body as Player
		if touched != null and not touched.is_knocked_out():
			touched.bounce_back(global_position)
			_shield_cooldown = 0.4
			Audio.sfx("shield")
			Fx.burst(get_parent(), global_position.lerp(touched.global_position, 0.6), Color(0.85, 0.6, 1.0), 10, 90.0)
			Fx.popup_text(get_parent(), global_position + Vector2(0.0, -40.0), ["Hmph!", "Ha!", "Too slow!", "Nope!"].pick_random(), Color(0.95, 0.75, 1.0))
			return
