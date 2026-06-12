extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK_TREE }

@export var patrol_speed: float = 80.0
@export var chase_speed: float = 150.0
@export var detection_radius: float = 220.0
@export var lose_interest_radius: float = 320.0
@export var patrol_switch_time: float = 2.0
@export var catch_cooldown: float = 1.0
@export var chase_speed_critical: float = 180.0
@export var chase_speed_fully_corrupted: float = 210.0
@export var detection_bonus_fully_corrupted: float = 40.0
@export var tree_attack_radius: float = 340.0
@export var tree_attack_interval: float = 2.0
@export var tree_attack_move_speed: float = 60.0
@export var attack_tree_path: NodePath = NodePath("../Tree")

var _state: State = State.PATROL
var _base_chase_speed: float = 150.0
var _base_detection_radius: float = 220.0
var _player: CharacterBody2D = null
var _attack_tree: Node2D = null
var _patrol_direction := 1
var _patrol_timer := 0.0
var _catch_cooldown_timer := 0.0
var _tree_attack_timer := 0.0
var _contact_area: Area2D = null


func _ready() -> void:
	add_to_group("gleamwrought")
	print("Gleamwrought script ready")
	_base_chase_speed = chase_speed
	_base_detection_radius = detection_radius
	_patrol_timer = patrol_switch_time
	_tree_attack_timer = tree_attack_interval
	_find_player()
	_find_attack_tree()
	_contact_area = get_node_or_null("Area2D") as Area2D
	if _contact_area:
		if not _contact_area.body_entered.is_connected(_on_contact_body_entered):
			_contact_area.body_entered.connect(_on_contact_body_entered)

	call_deferred("_try_start_attacking_tree")


func _physics_process(delta: float) -> void:
	if _catch_cooldown_timer > 0.0:
		_catch_cooldown_timer -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	if _player == null or not is_instance_valid(_player):
		_find_player()

	if _attack_tree == null or not is_instance_valid(_attack_tree):
		_find_attack_tree()

	_patrol_timer -= delta

	if _player and _get_player_distance() <= detection_radius:
		if _state != State.CHASE:
			_state = State.CHASE
			print("Gleamwrought detected Nyra")
	else:
		if _state == State.CHASE and _get_player_distance() > lose_interest_radius:
			_state = State.PATROL
			print("Gleamwrought lost Nyra")
		elif _should_attack_tree():
			if _state != State.ATTACK_TREE:
				_state = State.ATTACK_TREE
		elif _state == State.ATTACK_TREE and not _should_attack_tree():
			_state = State.PATROL

	match _state:
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK_TREE:
			_process_attack_tree(delta)

	move_and_slide()
	
	if _catch_cooldown_timer <= 0.0 and _contact_area:
		for body in _contact_area.get_overlapping_bodies():
			if body.has_method("on_caught_by_enemy"):
				body.on_caught_by_enemy()
				_catch_cooldown_timer = catch_cooldown
				break


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player == null:
		var found := get_tree().root.find_child("TheWitch", true, false)
		_player = found as CharacterBody2D
	if _player:
		print("Found player: ", _player.name)


func _find_attack_tree() -> void:
	if not attack_tree_path.is_empty():
		_attack_tree = get_node_or_null(attack_tree_path) as Node2D
	if _attack_tree == null:
		var targets := get_tree().get_nodes_in_group("active_corruption_target")
		if not targets.is_empty():
			_attack_tree = targets[0] as Node2D


func _try_start_attacking_tree() -> void:
	if _should_attack_tree():
		_state = State.ATTACK_TREE


func _should_attack_tree() -> bool:
	if _attack_tree == null or not is_instance_valid(_attack_tree):
		return false
	if _attack_tree.has_method("is_healed") and _attack_tree.is_healed():
		return false
	if _attack_tree.has_method("is_fully_charged") and _attack_tree.is_fully_charged:
		return false
	return _get_tree_distance() <= tree_attack_radius


func _get_tree_anchor() -> Vector2:
	if _attack_tree == null:
		return global_position
	return _attack_tree.global_position


func _get_tree_distance() -> float:
	return _get_body_center(self).distance_to(_get_tree_anchor())


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
	if _patrol_timer <= 0.0:
		_patrol_direction *= -1
		_patrol_timer = patrol_switch_time

	if _should_attack_tree():
		_state = State.ATTACK_TREE
		return

	velocity.x = _patrol_direction * patrol_speed


func _process_chase() -> void:
	if _player == null:
		_state = State.PATROL
		velocity.x = _patrol_direction * patrol_speed
		return

	var direction := signf(_get_body_center(_player).x - _get_body_center(self).x)
	if direction != 0.0:
		_patrol_direction = int(direction)
		velocity.x = direction * chase_speed
	else:
		velocity.x = 0.0


func _process_attack_tree(delta: float) -> void:
	if _attack_tree == null:
		_state = State.PATROL
		velocity.x = _patrol_direction * patrol_speed
		return

	var tree_pos := _get_tree_anchor()
	var direction := signf(tree_pos.x - _get_body_center(self).x)
	var distance := _get_tree_distance()

	if distance > 48.0 and direction != 0.0:
		_patrol_direction = int(direction)
		velocity.x = direction * tree_attack_move_speed
	else:
		velocity.x = 0.0
		_tree_attack_timer -= delta
		if _tree_attack_timer <= 0.0:
			_tree_attack_timer = tree_attack_interval
			print("Gleamwrought attacking tree")


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
