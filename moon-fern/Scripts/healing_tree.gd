extends Node2D

signal charge_changed(percent: float)
signal healed
signal under_attack_changed(is_under_attack: bool)

@export var max_tree_charge: float = 100.0
@export var current_tree_charge: float = 0.0
@export var charge_amount_per_potion: float = 25.0
@export var charge_debug_interval: float = 5.0

var is_fully_charged := false
var _charge_debug_timer := 0.0
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

	current_tree_charge = clampf(current_tree_charge, 0.0, max_tree_charge)
	is_fully_charged = current_tree_charge >= max_tree_charge
	_charge_debug_timer = charge_debug_interval
	_apply_visual()
	charge_changed.emit(get_charge_percent())


func _setup_attack_area() -> void:
	if _attack_area == null:
		push_warning("Tree AttackArea missing — enemy attacks will not be detected")
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
	_update_under_attack_state()
	_pulse_time += delta
	_apply_visual()

	_charge_debug_timer -= delta
	if _charge_debug_timer <= 0.0:
		_charge_debug_timer = charge_debug_interval
		print("Tree charge: ", snappedf(current_tree_charge, 0.1))


func get_charge_percent() -> float:
	if max_tree_charge <= 0.0:
		return 0.0
	return clampf((current_tree_charge / max_tree_charge) * 100.0, 0.0, 100.0)


func get_health_percent() -> float:
	return get_charge_percent()


func is_healed() -> bool:
	return is_fully_charged


func is_under_attack() -> bool:
	return _is_under_attack and not is_fully_charged


func get_tree_status_text() -> String:
	if is_fully_charged:
		return "Fully Charged"
	if is_under_attack():
		return "Under Attack"
	if current_tree_charge <= 0.0:
		return "Dormant"
	return "Charging"


func interact(player: Node) -> void:
	if is_fully_charged:
		print("Tree is already fully charged")
		return

	if player.has_method("has_carried_item") and player.has_carried_item("Potion"):
		if player.consume_carried_item("Potion"):
			_apply_potion_charge(player)
			print("Tree charged from carried Potion")
		else:
			_notify(player, "Need Potion to charge this tree")
		return

	if player.has_method("has_carried_item") and player.has_carried_item("Herb"):
		_notify(player, "Need Potion to charge this tree")
		return

	if player.is_carrying:
		_notify(player, "Need Potion to charge this tree")
		return

	var dropped_potion := _find_dropped_potion_in_area()
	if dropped_potion:
		dropped_potion.queue_free()
		_apply_potion_charge(player)
		print("Tree consumed dropped Potion")
		return

	_notify(player, "Need Potion to charge this tree")


func _notify(player: Node, message: String) -> void:
	if player.has_method("show_notification"):
		player.show_notification(message)


func _apply_potion_charge(player: Node) -> void:
	var before_percent: float = get_charge_percent()

	current_tree_charge = minf(
		max_tree_charge,
		current_tree_charge + charge_amount_per_potion
	)
	current_tree_charge = clampf(current_tree_charge, 0.0, max_tree_charge)

	var after_percent: float = get_charge_percent()
	var gained_percent: int = maxi(0, int(round(after_percent - before_percent)))

	_apply_visual()
	charge_changed.emit(after_percent)

	if current_tree_charge >= max_tree_charge:
		is_fully_charged = true
		current_tree_charge = max_tree_charge
		print("Tree fully charged")
		_notify(player, "Tree fully healed!")
		healed.emit()
		charge_changed.emit(get_charge_percent())
		remove_from_group("active_corruption_target")
		return

	print("Tree charge increased")
	print("Tree charge: %d%%" % int(round(after_percent)))
	_notify(player, "Tree charge +%d%%" % gained_percent)


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
	if is_fully_charged:
		_sprite.modulate = Color(0.85, 1.0, 0.85)
	elif is_under_attack():
		var stress: float = 0.9 + 0.1 * abs(sin(_pulse_time * 5.0))
		_sprite.modulate = Color(0.65 * stress, 0.5 * stress, 0.55 * stress)
	elif current_tree_charge <= 0.0:
		var dim: float = 0.7 + 0.3 * abs(sin(_pulse_time * 4.0))
		_sprite.modulate = Color(0.25 * dim, 0.2 * dim, 0.3 * dim)
	else:
		var progress: float = get_charge_percent() / 100.0
		_sprite.modulate = Color(
			lerpf(0.35, 0.75, progress),
			lerpf(0.3, 0.95, progress),
			lerpf(0.35, 0.8, progress)
		)


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
