extends Node

signal forest_shield_changed(percent: float)
signal tree_charge_changed(percent: float)
signal level_completed
signal forest_shield_collapsed

const TREE_COUNT := 4

@export var tree_1_path: NodePath = ^""
@export var forest_shield: float = 100.0
@export var shield_decay_rate: float = 2.0
@export var attack_decay_multiplier: float = 2.0

var _last_shield_percent: float = -1.0
var _last_charge_percent: float = -1.0
var _tree_entries: Array[Dictionary] = []
var _active_tree_index: int = 0
var _level_complete := false
var _shield_collapsed := false
var _tree_under_attack := false


func _ready() -> void:
	add_to_group("forest_shield_manager")
	_build_tree_entries()
	call_deferred("_wire_tree_1")
	call_deferred("_refresh_displays")


func _process(delta: float) -> void:
	if _level_complete or _shield_collapsed:
		return

	var decay_rate := shield_decay_rate
	if _tree_under_attack:
		decay_rate *= attack_decay_multiplier

	forest_shield = maxf(0.0, forest_shield - decay_rate * delta)

	if forest_shield <= 0.0 and not _shield_collapsed:
		forest_shield = 0.0
		_shield_collapsed = true
		print("Forest Shield collapsed")
		forest_shield_collapsed.emit()

	_refresh_shield()


func get_active_tree_index() -> int:
	return _active_tree_index


func get_forest_shield_percent() -> float:
	return clampf(forest_shield, 0.0, 100.0)


func get_active_tree_charge_percent() -> float:
	if _tree_entries.is_empty():
		return 0.0
	return _get_entry_charge_percent(_tree_entries[_active_tree_index])


func is_level_complete() -> bool:
	return _level_complete


func get_tree_status(index: int) -> Dictionary:
	if index < 0 or index >= _tree_entries.size():
		return {}

	var entry: Dictionary = _tree_entries[index]
	return {
		"display_name": entry.get("hud_label", "Tree"),
		"charge_percent": _get_entry_charge_percent(entry),
		"status_text": _get_entry_status_text(entry),
	}


func get_all_tree_statuses() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for i in TREE_COUNT:
		results.append(get_tree_status(i))
	return results


func take_damage(amount: float) -> void:
	forest_shield = maxf(0.0, forest_shield - amount)
	if forest_shield <= 0.0 and not _shield_collapsed:
		forest_shield = 0.0
		_shield_collapsed = true
		forest_shield_collapsed.emit()
	_refresh_shield()


func _build_tree_entries() -> void:
	_tree_entries = [
		{
			"id": 0,
			"section": "Forest Floor",
			"hud_label": "Forest Floor Tree",
			"tree_node": null,
			"placeholder_charge_percent": 0.0,
			"is_active_target": true,
			"under_attack": false,
			"level_complete": false,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 1,
			"section": "Canopy",
			"hud_label": "Canopy Tree",
			"tree_node": null,
			"placeholder_charge_percent": 0.0,
			"is_active_target": false,
			"under_attack": false,
			"level_complete": false,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 2,
			"section": "Underground",
			"hud_label": "Underground Tree",
			"tree_node": null,
			"placeholder_charge_percent": 0.0,
			"is_active_target": false,
			"under_attack": false,
			"level_complete": false,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 3,
			"section": "Industrial Edge",
			"hud_label": "Industrial Edge Tree",
			"tree_node": null,
			"placeholder_charge_percent": 0.0,
			"is_active_target": false,
			"under_attack": false,
			"level_complete": false,
			"damage_blocks": [100, 100, 100, 100],
		},
	]


func _wire_tree_1() -> void:
	var tree: Node = null
	if not tree_1_path.is_empty():
		tree = get_node_or_null(tree_1_path)
	if tree == null:
		tree = get_tree().get_first_node_in_group("healable_tree")
	if tree == null:
		push_error("ForestShieldManager: Tree 1 not found")
		return

	_tree_entries[0]["tree_node"] = tree
	if tree.has_signal("charge_changed"):
		tree.charge_changed.connect(_on_tree_1_charge_changed)
	elif tree.has_signal("health_changed"):
		tree.health_changed.connect(_on_tree_1_charge_changed)
	if tree.has_signal("healed"):
		tree.healed.connect(_on_tree_1_healed)
	if tree.has_signal("under_attack_changed"):
		tree.under_attack_changed.connect(_on_tree_1_under_attack_changed)


func _on_tree_1_charge_changed(_percent: float = 0.0) -> void:
	_refresh_displays()


func _on_tree_1_healed() -> void:
	_level_complete = true
	_tree_entries[0]["level_complete"] = true
	_tree_entries[0]["under_attack"] = false
	_tree_under_attack = false
	print("Next area unlocked!")
	level_completed.emit()
	_refresh_displays()


func _on_tree_1_under_attack_changed(is_under_attack: bool) -> void:
	if _level_complete:
		_tree_under_attack = false
		return
	_tree_under_attack = is_under_attack
	_tree_entries[0]["under_attack"] = is_under_attack
	_refresh_displays()


func _get_entry_charge_percent(entry: Dictionary) -> float:
	var tree: Node = entry.get("tree_node")
	if tree != null and is_instance_valid(tree):
		if tree.has_method("get_charge_percent"):
			return tree.get_charge_percent()
		if tree.has_method("get_health_percent"):
			return tree.get_health_percent()
	return float(entry.get("placeholder_charge_percent", 0.0))


func _get_entry_status_text(entry: Dictionary) -> String:
	var tree: Node = entry.get("tree_node")
	if tree != null and is_instance_valid(tree) and tree.has_method("get_tree_status_text"):
		return tree.get_tree_status_text()

	if entry.get("level_complete", false):
		return "Fully Charged"
	if entry.get("under_attack", false) and entry.get("is_active_target", false):
		return "Under Attack"
	if entry.get("is_active_target", false):
		var charge := float(entry.get("placeholder_charge_percent", 0.0))
		if charge <= 0.0:
			return "Dormant"
		return "Charging"

	return "Dormant"


func _refresh_displays() -> void:
	_refresh_shield()
	_refresh_tree_charge()


func _refresh_shield() -> void:
	var percent := get_forest_shield_percent()
	if _last_shield_percent >= 0.0 and is_equal_approx(percent, _last_shield_percent):
		forest_shield_changed.emit(percent)
		return
	_last_shield_percent = percent
	forest_shield_changed.emit(percent)


func _refresh_tree_charge() -> void:
	var percent := get_active_tree_charge_percent()
	if _last_charge_percent >= 0.0 and is_equal_approx(percent, _last_charge_percent):
		tree_charge_changed.emit(percent)
		return
	_last_charge_percent = percent
	tree_charge_changed.emit(percent)
