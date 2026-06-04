extends Camera2D

@export var base_offset := Vector2(209, 265)
@export var camera_down_lookahead := 100.0
@export var camera_horizontal_lookahead := 45.0
@export var camera_offset_lerp_speed := 8.0
@export var fall_velocity_threshold := 40.0

var _player: CharacterBody2D = null


func _ready() -> void:
	position_smoothing_enabled = true
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	_player = get_parent() as CharacterBody2D
	position = base_offset


func _physics_process(delta: float) -> void:
	if _player == null:
		return

	var target := base_offset

	if not _player.is_on_floor() and _player.velocity.y > fall_velocity_threshold:
		var fall_strength := clampf(_player.velocity.y / 500.0, 0.35, 1.0)
		target.y += camera_down_lookahead * fall_strength

	if absf(_player.velocity.x) > 20.0:
		var move_strength := clampf(absf(_player.velocity.x) / 400.0, 0.35, 1.0)
		target.x += signf(_player.velocity.x) * camera_horizontal_lookahead * move_strength
	else:
		target.x += float(_player.last_facing_direction) * camera_horizontal_lookahead * 0.35

	position = position.lerp(target, clampf(camera_offset_lerp_speed * delta, 0.0, 1.0))
