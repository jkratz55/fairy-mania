class_name Fx
extends RefCounted
## Small one-shot visual effects: sparkle bursts and floating text.

static var _soft_texture: GradientTexture2D


## A soft round dot used by all particle effects.
static func soft_texture() -> GradientTexture2D:
	if _soft_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient.add_point(0.35, Color(1.0, 1.0, 1.0, 0.85))
		_soft_texture = GradientTexture2D.new()
		_soft_texture.gradient = gradient
		_soft_texture.fill = GradientTexture2D.FILL_RADIAL
		_soft_texture.fill_from = Vector2(0.5, 0.5)
		_soft_texture.fill_to = Vector2(1.0, 0.5)
		_soft_texture.width = 16
		_soft_texture.height = 16
	return _soft_texture


static func fade_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	return ramp


static func burst(parent: Node, at: Vector2, color: Color, amount: int = 14, speed: float = 110.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var particles := CPUParticles2D.new()
	particles.texture = soft_texture()
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = amount
	particles.lifetime = 0.7
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0.0, 140.0)
	particles.damping_min = 40.0
	particles.damping_max = 80.0
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.8
	particles.color = color
	particles.color_ramp = fade_ramp()
	particles.hue_variation_min = -0.04
	particles.hue_variation_max = 0.04
	particles.z_index = 15
	particles.position = at
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func popup_text(parent: Node, at: Vector2, text: String, color: Color = Color(1.0, 0.95, 0.6)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.35))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(80.0, 20.0)
	label.position = at - Vector2(40.0, 24.0)
	label.z_index = 20
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 26.0, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)
