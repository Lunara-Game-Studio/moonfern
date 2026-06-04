extends Node2D

signal health_changed(percent: float)
signal became_critical
signal became_fully_corrupted
signal healed
signal stabilized
signal under_attack_changed(is_under_attack: bool)

@export var max_tree_health: float = 100.0
@export var current_tree_health: float = 100.0
@export var corruption_rate: float = 5.0
@export var critical_threshold: float = 30.0
@export var health_debug_interval: float = 5.0
@export var healing_amount_per_potion: float = 25.0

var is_healed := false
var is_stabilized := false
var _was_critical := false
var _was_fully_corrupted := false
var _health_debug_timer := 0.0
var _pulse_time := 0.0
var _is_under_attack := false
var _attackers_nearby := 0

# Future: optional per-tree damage blocks (not interactive in this branch).
var damage_blocks: Array[int] = [100, 100, 100, 100]

@onready var _interact_area: Area2D = get_node_or_null("InteractArea")
@onready var _attack_area: Area2D = get_node_or_null("AttackArea")
@onready var _sprite: Sprite2D = $"Tree I"


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("active_corruption_target")
	print("HealingTree script ready")
	if _interact_area == null:
		push_error("Tree InteractArea missing")
		return

	print("Tree InteractArea found")
	_interact_area.monitoring = true
	_interact_area.monitorable = true
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	if not _interact_area.body_entered.is_connected(_on_body_entered):
		_interact_area.body_entered.connect(_on_body_entered)
	if not _interact_area.body_exited.is_connected(_on_body_exited):
		_interact_area.body_exited.connect(_on_body_exited)

	_setup_attack_area()

	current_tree_health = clampf(current_tree_health, 0.0, max_tree_health)
	_health_debug_timer = health_debug_interval
	_apply_visual()
	health_changed.emit(get_health_percent())


func _setup_attack_area() -> void:
	if _attack_area == null:
		push_warning("Tree AttackArea missing — corruption will not trigger from enemies")
		return

	_attack_area.monitoring = true
	_attack_area.monitorable = false
	_attack_area.collision_layer = 0
	_attack_area.collision_mask = 1
	if not _attack_area.body_entered.is_connected(_on_attack_body_entered):
		_attack_area.body_entered.connect(_on_attack_body_entered)
	if not _attack_area.body_exited.is_connected(_on_attack_body_exited):
		_attack_area.body_exited.connect(_on_attack_body_exited)


func _process(delta: float) -> void:
	if is_healed:
		return

	_update_under_attack_state()

	if not is_stabilized and _is_under_attack:
		_tick_corruption(delta)

	_pulse_time += delta
	_apply_visual()

	_health_debug_timer -= delta
	if _health_debug_timer <= 0.0:
		_health_debug_timer = health_debug_interval
		print("Tree health: ", snappedf(current_tree_health, 0.1))


func get_health_percent() -> float:
	if max_tree_health <= 0.0:
		return 0.0
	return clampf((current_tree_health / max_tree_health) * 100.0, 0.0, 100.0)


func is_critical() -> bool:
	return not is_healed and current_tree_health <= critical_threshold and current_tree_health > 0.0


func is_fully_corrupted() -> bool:
	return not is_healed and current_tree_health <= 0.0


func is_restored() -> bool:
	return (
		not is_healed
		and not is_fully_corrupted()
		and not is_critical()
		and get_health_percent() < 100.0
		and not is_stabilized
	)


func is_under_attack() -> bool:
	return _is_under_attack and not is_stabilized and not is_healed


func get_tree_status_text() -> String:
	if is_healed:
		return "Healed"
	if is_stabilized:
		return "Stabilized"
	if is_under_attack():
		return "Under Attack"
	if is_fully_corrupted():
		return "Fully Corrupted"
	if is_critical():
		return "Critical"
	if is_restored():
		return "Restored"
	if get_health_percent() < 100.0:
		return "Damaged"
	return "Healthy"


func _tick_corruption(delta: float) -> void:
	if current_tree_health <= 0.0:
		return

	current_tree_health = maxf(0.0, current_tree_health - corruption_rate * delta)
	_check_corruption_transitions()
	health_changed.emit(get_health_percent())


func _check_corruption_transitions() -> void:
	if not _was_critical and is_critical():
		_was_critical = true
		print("Tree is critically corrupted")
		became_critical.emit()

	if not _was_fully_corrupted and is_fully_corrupted():
		_was_fully_corrupted = true
		print("Tree has fully corrupted")
		print("TODO: Corruption should strengthen The Gleamwrought later")
		became_fully_corrupted.emit()


func interact(player: Node) -> void:
	if is_healed:
		print("Tree is already healed")
		return

	if player.has_method("has_carried_item") and player.has_carried_item("Potion"):
		if player.consume_carried_item("Potion"):
			_apply_potion_heal(player)
			print("Tree healed from carried Potion")
		else:
			_notify(player, "Need Potion to heal this tree")
		return

	if player.has_method("has_carried_item") and player.has_carried_item("Herb"):
		_notify(player, "Need Potion to heal this tree")
		return

	if player.is_carrying:
		_notify(player, "Need Potion to heal this tree")
		return

	var dropped_potion := _find_dropped_potion_in_area()
	if dropped_potion:
		dropped_potion.queue_free()
		_apply_potion_heal(player)
		print("Tree consumed dropped Potion")
		return

	_notify(player, "Need Potion to heal this tree")


func _notify(player: Node, message: String) -> void:
	if player.has_method("show_notification"):
		player.show_notification(message)


func _apply_potion_heal(player: Node) -> void:
	var was_fully_corrupted := is_fully_corrupted()
	var before_percent: float = get_health_percent()

	current_tree_health = minf(
		max_tree_health,
		current_tree_health + healing_amount_per_potion
	)
	current_tree_health = clampf(current_tree_health, 0.0, max_tree_health)

	var after_percent: float = get_health_percent()
	var gained_percent: int = maxi(0, int(round(after_percent - before_percent)))

	_apply_visual()
	health_changed.emit(after_percent)

	if current_tree_health >= max_tree_health:
		is_healed = true
		current_tree_health = max_tree_health
		print("Tree fully healed")
		_notify(player, "Tree fully healed!")
		healed.emit()
		health_changed.emit(get_health_percent())
		return

	is_healed = false
	print("Tree partially restored")
	print("Tree health: %d%%" % int(round(after_percent)))
	if was_fully_corrupted:
		print("Restored part of fully corrupted tree")
	_notify(player, "Tree restored +%d%%" % gained_percent)

	if not is_stabilized:
		is_stabilized = true
		remove_from_group("active_corruption_target")
		print("Tree stabilized")
		stabilized.emit()
		_notify(player, "Tree stabilized!")
		health_changed.emit(get_health_percent())


func _get_interact_bounds() -> Rect2:
	var collision := _interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return Rect2()
	if collision.shape is RectangleShape2D:
		var shape := collision.shape as RectangleShape2D
		var half := shape.size * 0.5
		return Rect2(collision.global_position - half, shape.size)
	return Rect2()


func _pickup_in_interact_bounds(pickup: Node2D) -> bool:
	var bounds := _get_interact_bounds()
	if bounds.size == Vector2.ZERO:
		return false
	var collision := pickup.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var pos: Vector2 = collision.global_position if collision else pickup.global_position
	return bounds.has_point(pos)


func _find_dropped_potion_in_area() -> Node:
	for node in get_tree().get_nodes_in_group("potion_pickup"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		if not node.has_method("get_item_type") or node.get_item_type() != "Potion":
			continue
		if _pickup_in_interact_bounds(node as Node2D):
			return node
	return null


func _apply_visual() -> void:
	if is_healed:
		_sprite.modulate = Color(0.85, 1.0, 0.85)
	elif is_stabilized:
		_sprite.modulate = Color(0.72, 0.95, 0.82)
	elif is_under_attack():
		var stress: float = 0.9 + 0.1 * abs(sin(_pulse_time * 5.0))
		_sprite.modulate = Color(0.65 * stress, 0.5 * stress, 0.55 * stress)
	elif is_fully_corrupted():
		var dim: float = 0.7 + 0.3 * abs(sin(_pulse_time * 4.0))
		_sprite.modulate = Color(0.25 * dim, 0.2 * dim, 0.3 * dim)
	elif is_critical():
		var flash: float = 0.85 + 0.15 * abs(sin(_pulse_time * 8.0))
		_sprite.modulate = Color(0.75 * flash, 0.35 * flash, 0.55 * flash)
	else:
		_sprite.modulate = Color(0.55, 0.45, 0.5)


func _on_body_entered(body: Node2D) -> void:
	print("Tree area entered by: ", body.name)
	var player := _resolve_player(body)
	if player:
		print("Tree nearby")
		player.register_nearby_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	print("Tree area exited by: ", body.name)
	var player := _resolve_player(body)
	if player:
		player.unregister_nearby_interactable(self)


func _resolve_player(node: Node) -> Node:
	if node == null:
		return null
	if node.is_in_group("player") and node is CharacterBody2D:
		return node
	var parent := node.get_parent()
	if parent and parent.is_in_group("player") and parent is CharacterBody2D:
		return parent
	return null


func _update_under_attack_state() -> void:
	var was_attack := _is_under_attack
	if _attack_area:
		_is_under_attack = _count_gleamwrought_in_attack_area() > 0
	else:
		_is_under_attack = _attackers_nearby > 0

	if _is_under_attack == was_attack:
		return

	if _is_under_attack:
		print("Tree under attack")
	else:
		print("Tree no longer under attack")
	under_attack_changed.emit(_is_under_attack)


func _count_gleamwrought_in_attack_area() -> int:
	var count := 0
	for body in _attack_area.get_overlapping_bodies():
		if _is_gleamwrought_body(body):
			count += 1
	return count


func _is_gleamwrought_body(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("gleamwrought"):
		return true
	var parent := body.get_parent()
	return parent != null and parent.is_in_group("gleamwrought")


func _on_attack_body_entered(body: Node2D) -> void:
	if not _is_gleamwrought_body(body):
		return
	_attackers_nearby += 1
	_update_under_attack_state()


func _on_attack_body_exited(body: Node2D) -> void:
	if not _is_gleamwrought_body(body):
		return
	_attackers_nearby = maxi(0, _attackers_nearby - 1)
	_update_under_attack_state()
