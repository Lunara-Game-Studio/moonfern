extends Node2D

signal health_changed(percent: float)
signal became_critical
signal became_fully_corrupted
signal healed

@export var max_tree_health: float = 100.0
@export var current_tree_health: float = 100.0
@export var corruption_rate: float = 5.0
@export var critical_threshold: float = 30.0
@export var health_debug_interval: float = 5.0
@export var healing_amount_per_potion: float = 25.0

var is_healed := false
var _was_critical := false
var _was_fully_corrupted := false
var _health_debug_timer := 0.0
var _pulse_time := 0.0

# Future: optional per-tree damage blocks (not interactive in this branch).
var damage_blocks: Array[int] = [100, 100, 100, 100]

@onready var _interact_area: Area2D = get_node_or_null("InteractArea")
@onready var _sprite: Sprite2D = $"Tree I"


func _ready() -> void:
	add_to_group("interactable")
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

	current_tree_health = clampf(current_tree_health, 0.0, max_tree_health)
	_health_debug_timer = health_debug_interval
	_apply_visual()
	health_changed.emit(get_health_percent())


func _process(delta: float) -> void:
	if is_healed:
		return

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
	)


func get_tree_status_text() -> String:
	if is_healed:
		return "Healed"
	if is_fully_corrupted():
		return "Fully Corrupted"
	if is_critical():
		return "Critical"
	if is_restored():
		return "Restored"
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
