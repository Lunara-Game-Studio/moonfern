extends CharacterBody2D

enum State { PATROL, CHASE }

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 150.0
@export var detection_radius: float = 220.0
@export var lose_interest_radius: float = 320.0
@export var patrol_switch_time: float = 2.0
@export var catch_cooldown: float = 1.0
@export var chase_speed_critical: float = 180.0
@export var chase_speed_fully_corrupted: float = 210.0
@export var detection_bonus_fully_corrupted: float = 40.0

var _state: State = State.PATROL
var _base_chase_speed: float = 150.0
var _base_detection_radius: float = 220.0
var _player: CharacterBody2D = null
var _patrol_direction := 1
var _patrol_timer := 0.0
var _catch_cooldown_timer := 0.0
var _contact_area: Area2D = null


func _ready() -> void:
	print("Gleamwrought script ready")
	_base_chase_speed = chase_speed
	_base_detection_radius = detection_radius
	_patrol_timer = patrol_switch_time
	_find_player()
	_contact_area = get_node_or_null("Area2D") as Area2D
	if _contact_area:
		if not _contact_area.body_entered.is_connected(_on_contact_body_entered):
			_contact_area.body_entered.connect(_on_contact_body_entered)


func _physics_process(delta: float) -> void:
	if _catch_cooldown_timer > 0.0:
		_catch_cooldown_timer -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	if _player == null or not is_instance_valid(_player):
		_find_player()

	_patrol_timer -= delta
	if _patrol_timer <= 0.0:
		_patrol_direction *= -1
		_patrol_timer = patrol_switch_time

	match _state:
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()

	move_and_slide()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player == null:
		var found := get_tree().root.find_child("TheWitch", true, false)
		_player = found as CharacterBody2D
	if _player:
		print("Found player: ", _player.name)


func _get_body_center(body: Node2D) -> Vector2:
	if body == null:
		return Vector2.ZERO
	var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		return collision.global_position
	return body.global_position


func _get_player_distance() -> float:
	if _player == null:
		return INF
	return _get_body_center(self).distance_to(_get_body_center(_player))


func _process_patrol() -> void:
	if _player and _get_player_distance() <= detection_radius:
		_state = State.CHASE
		print("Gleamwrought detected Nyra")
		return

	velocity.x = _patrol_direction * patrol_speed


func _process_chase() -> void:
	if _player == null:
		_state = State.PATROL
		velocity.x = _patrol_direction * patrol_speed
		return

	var distance := _get_player_distance()
	if distance > lose_interest_radius:
		_state = State.PATROL
		print("Gleamwrought lost Nyra")
		velocity.x = _patrol_direction * patrol_speed
		return

	var direction := signf(_get_body_center(_player).x - _get_body_center(self).x)
	if direction != 0.0:
		_patrol_direction = int(direction)
		velocity.x = direction * chase_speed
	else:
		velocity.x = 0.0


func _on_contact_body_entered(body: Node2D) -> void:
	if _catch_cooldown_timer > 0.0:
		return
	if not body.has_method("on_caught_by_enemy"):
		return

	print("Gleamwrought caught Nyra")
	body.on_caught_by_enemy()
	_catch_cooldown_timer = catch_cooldown


func on_tree_critical() -> void:
	chase_speed = chase_speed_critical
	print("Gleamwrought pressure increased: critical")


func on_tree_fully_corrupted() -> void:
	chase_speed = chase_speed_fully_corrupted
	detection_radius = _base_detection_radius + detection_bonus_fully_corrupted
	print("Gleamwrought pressure increased: fully corrupted")


func on_tree_healed() -> void:
	chase_speed = _base_chase_speed
	detection_radius = _base_detection_radius
	print("Gleamwrought pressure eased: tree healed")


func set_corruption_pressure(level: String) -> void:
	match level:
		"critical":
			on_tree_critical()
		"fully_corrupted":
			on_tree_fully_corrupted()
		_:
			on_tree_healed()
