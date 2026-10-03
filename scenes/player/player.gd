class_name Player
extends CharacterBody2D
## Wren the fairy. Runs, jumps and glides; with a full pixie dust meter she can fly.
## Kid-friendly tuning: generous coyote time, jump buffering, gliding and soft knockback.

signal knocked_out
signal flight_started
signal flight_ended

const RUN_SPEED: float = 170.0
const GROUND_ACCEL: float = 1300.0
const GROUND_FRICTION: float = 1500.0
const AIR_ACCEL: float = 950.0
const AIR_FRICTION: float = 450.0
const GRAVITY: float = 1150.0
const LOW_JUMP_GRAVITY_SCALE: float = 2.2
const JUMP_VELOCITY: float = -520.0
const STOMP_BOUNCE_VELOCITY: float = -380.0
const STOMP_BOUNCE_HELD_VELOCITY: float = -520.0
const MAX_FALL_SPEED: float = 560.0
const GLIDE_FALL_SPEED: float = 95.0
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.14
const FLY_SPEED_X: float = 190.0
const FLY_SPEED_Y: float = 170.0
const FLY_ACCEL: float = 900.0
const DUST_FOR_FLIGHT: int = 8
const FLIGHT_TIME: float = 7.0
const FLIGHT_BONUS_PER_DUST: float = 1.0
const FLIGHT_MAX_TIME: float = 10.0
const FLIGHT_WARNING_TIME: float = 2.0
const INVULNERABLE_TIME: float = 1.5
const HURT_STUN_TIME: float = 0.3
const CAMERA_LOOK_AHEAD: float = 40.0

var max_hearts: int = 3
var hearts: int = 3
var dust_meter: int = 0
var dust_total: int = 0
var is_flying: bool = false
var flight_time_left: float = 0.0
var controls_enabled: bool = true
## The playable area. Set by the level; falling below it knocks Wren out.
var level_bounds: Rect2 = Rect2(0.0, 0.0, 100000.0, 100000.0)

var _facing: float = 1.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invulnerable_timer: float = 0.0
var _stun_timer: float = 0.0
var _knocked_out: bool = false
var _celebrating: bool = false
var _gliding: bool = false
## Springs launch at full height even if jump isn't held.
var _spring_rise: bool = false
var _was_on_floor: bool = true
var _trail: CPUParticles2D
var _flight_sparkles: CPUParticles2D

@onready var art: FairyArt = $Art
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_trail = _make_sparkles(10, Color(1.0, 0.92, 0.6), 0.6)
	_flight_sparkles = _make_sparkles(40, Color(1.0, 0.75, 0.9), 0.9)
	_flight_sparkles.emitting = false


func _physics_process(delta: float) -> void:
	if _knocked_out:
		return
	_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)
	_stun_timer = maxf(_stun_timer - delta, 0.0)

	var input_dir: float = 0.0
	if controls_enabled and _stun_timer <= 0.0:
		input_dir = Input.get_axis("move_left", "move_right")
	if absf(input_dir) > 0.1:
		_facing = signf(input_dir)

	if is_flying:
		_process_flight(delta, input_dir)
	else:
		_process_platforming(delta, input_dir)

	move_and_slide()
	_check_head_bumps()
	_keep_in_bounds()

	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor:
		art.squash(Vector2(1.25, 0.78))
	_was_on_floor = on_floor
	_update_visuals(delta, on_floor)


func _process_platforming(delta: float, input_dir: float) -> void:
	var on_floor: bool = is_on_floor()
	var rate: float
	if on_floor:
		rate = GROUND_ACCEL if input_dir != 0.0 else GROUND_FRICTION
	else:
		rate = AIR_ACCEL if input_dir != 0.0 else AIR_FRICTION
	velocity.x = move_toward(velocity.x, input_dir * RUN_SPEED, rate * delta)

	_coyote_timer = COYOTE_TIME if on_floor else _coyote_timer - delta
	if controls_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_jump()

	var jump_held: bool = controls_enabled and Input.is_action_pressed("jump")
	var gravity: float = GRAVITY
	if velocity.y >= 0.0:
		_spring_rise = false
	if velocity.y < 0.0 and not jump_held and not _spring_rise:
		gravity *= LOW_JUMP_GRAVITY_SCALE
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)

	# Holding jump while falling lets Wren flutter down gently.
	_gliding = jump_held and not on_floor and velocity.y > 0.0
	if _gliding and velocity.y > GLIDE_FALL_SPEED:
		velocity.y = move_toward(velocity.y, GLIDE_FALL_SPEED, 2400.0 * delta)


func _process_flight(delta: float, input_dir: float) -> void:
	velocity.x = move_toward(velocity.x, input_dir * FLY_SPEED_X, FLY_ACCEL * delta)
	var vertical: float = 0.0
	if controls_enabled:
		if Input.is_action_pressed("jump") or Input.is_action_pressed("move_up"):
			vertical = -1.0
		elif Input.is_action_pressed("move_down"):
			vertical = 1.0
	velocity.y = move_toward(velocity.y, vertical * FLY_SPEED_Y, FLY_ACCEL * delta)
	_gliding = false
	if controls_enabled and not Game.debug_infinite_flight:
		flight_time_left -= delta
		if flight_time_left <= 0.0:
			end_flight()


func _jump() -> void:
	# Never weaken a spring or stomp bounce that is already launching Wren upward.
	velocity.y = minf(velocity.y, JUMP_VELOCITY)
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	art.squash(Vector2(0.75, 1.3))
	Audio.sfx("jump")


func _check_head_bumps() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_normal().y > 0.6:
			var block := collision.get_collider() as BonusBlock
			if block != null:
				block.bump(self)


func _keep_in_bounds() -> void:
	var min_x: float = level_bounds.position.x + 8.0
	var max_x: float = level_bounds.end.x - 8.0
	if global_position.x < min_x:
		global_position.x = min_x
		velocity.x = maxf(velocity.x, 0.0)
	elif global_position.x > max_x:
		global_position.x = max_x
		velocity.x = minf(velocity.x, 0.0)
	if global_position.y < level_bounds.position.y + 14.0:
		global_position.y = level_bounds.position.y + 14.0
		velocity.y = maxf(velocity.y, 0.0)
	if global_position.y > level_bounds.end.y + 48.0:
		if Game.debug_invincible:
			# Debug safety net: pop back up and fly instead of being knocked out.
			global_position.y = level_bounds.end.y - 64.0
			fill_dust_meter()
			velocity.y = -FLY_SPEED_Y * 2.0
		else:
			knock_out()


func _update_visuals(delta: float, on_floor: bool) -> void:
	var state: String
	if _celebrating:
		state = "celebrate"
	elif is_flying:
		state = "fly"
	elif not on_floor:
		if _gliding:
			state = "glide"
		else:
			state = "jump" if velocity.y < 0.0 else "fall"
	else:
		state = "run" if absf(velocity.x) > 20.0 else "idle"
	art.state = state
	art.facing = _facing
	art.flight_warning = is_flying and flight_time_left < FLIGHT_WARNING_TIME
	var blinking: bool = _invulnerable_timer > 0.0 and fmod(_invulnerable_timer, 0.16) < 0.08
	art.modulate.a = 0.35 if blinking else 1.0
	_trail.emitting = not on_floor or absf(velocity.x) > 60.0
	_flight_sparkles.emitting = is_flying
	camera.offset.x = lerpf(camera.offset.x, _facing * CAMERA_LOOK_AHEAD, 2.0 * delta)


# --- Pixie dust & flight ---------------------------------------------------

func add_dust(amount: int) -> void:
	dust_total += amount
	if is_flying:
		flight_time_left = minf(flight_time_left + FLIGHT_BONUS_PER_DUST * amount, FLIGHT_MAX_TIME)
		return
	dust_meter = mini(dust_meter + amount, DUST_FOR_FLIGHT)
	if dust_meter >= DUST_FOR_FLIGHT:
		start_flight()


## Pixie blooms fill the meter instantly.
func fill_dust_meter() -> void:
	if is_flying:
		flight_time_left = FLIGHT_MAX_TIME
	else:
		dust_meter = DUST_FOR_FLIGHT
		start_flight()


func start_flight() -> void:
	if is_flying:
		return
	is_flying = true
	flight_time_left = FLIGHT_TIME
	velocity.y = minf(velocity.y, -120.0)
	Audio.sfx("fly")
	flight_started.emit()


func end_flight(silent: bool = false) -> void:
	if not is_flying:
		return
	is_flying = false
	flight_time_left = 0.0
	dust_meter = 0
	if not silent:
		Audio.sfx("fly_end")
	flight_ended.emit()


func dust_meter_ratio() -> float:
	if is_flying:
		return flight_time_left / FLIGHT_MAX_TIME
	return float(dust_meter) / float(DUST_FOR_FLIGHT)


# --- Enemies, damage & health ---------------------------------------------

## True when Wren is coming down on top of something at `target_y`.
func can_stomp(target_y: float) -> bool:
	return not _knocked_out and velocity.y > -40.0 and global_position.y < target_y - 6.0


func stomp_bounce() -> void:
	var held: bool = controls_enabled and Input.is_action_pressed("jump")
	velocity.y = STOMP_BOUNCE_HELD_VELOCITY if held else STOMP_BOUNCE_VELOCITY
	_invulnerable_timer = maxf(_invulnerable_timer, 0.15)
	art.squash(Vector2(0.8, 1.25))


func spring(strength: float) -> void:
	if is_flying:
		return
	velocity.y = strength
	_spring_rise = true
	_coyote_timer = 0.0
	art.squash(Vector2(0.7, 1.4))


func hurt(from: Vector2) -> void:
	if _knocked_out or _invulnerable_timer > 0.0 or not controls_enabled or Game.debug_invincible:
		return
	hearts -= 1
	if hearts <= 0:
		knock_out()
		return
	_invulnerable_timer = INVULNERABLE_TIME
	_stun_timer = HURT_STUN_TIME
	var away: float = signf(global_position.x - from.x)
	if away == 0.0:
		away = -_facing
	velocity = Vector2(away * 170.0, -280.0)
	Audio.sfx("hurt")


func heal(amount: int = 1) -> void:
	hearts = mini(hearts + amount, max_hearts)


func knock_out() -> void:
	if _knocked_out:
		return
	_knocked_out = true
	end_flight(true)
	velocity = Vector2.ZERO
	_trail.emitting = false
	_flight_sparkles.emitting = false
	Audio.sfx("oops")
	art.play_knockout()
	knocked_out.emit()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	hearts = max_hearts
	_knocked_out = false
	_invulnerable_timer = 1.0
	_stun_timer = 0.0
	art.reset()
	camera.reset_smoothing()


func celebrate() -> void:
	_celebrating = true
	controls_enabled = false
	velocity.x = 0.0


func is_knocked_out() -> bool:
	return _knocked_out


func _make_sparkles(amount: int, color: Color, lifetime: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = Fx.soft_texture()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	particles.direction = Vector2.DOWN
	particles.spread = 60.0
	particles.gravity = Vector2(0.0, 30.0)
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 25.0
	particles.scale_amount_min = 0.15
	particles.scale_amount_max = 0.45
	particles.color = color
	particles.color_ramp = Fx.fade_ramp()
	particles.hue_variation_min = -0.08
	particles.hue_variation_max = 0.08
	particles.show_behind_parent = true
	add_child(particles)
	return particles
