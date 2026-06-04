extends Node

signal forest_shield_changed(percent: float)
signal active_target_changed(index: int, display_name: String)

const TREE_COUNT := 4

@export var tree_1_path: NodePath = ^"../Tree" # Sibling healable tree (Forest Floor / Tree 1).

var _last_shield_percent: float = -1.0
var _tree_entries: Array[Dictionary] = []
var _active_tree_index: int = 0


func _ready() -> void:
	_build_tree_entries()
	_wire_tree_1()
	_mark_tree_under_attack(0)
	call_deferred("_refresh_shield")


func get_active_tree_index() -> int:
	return _active_tree_index


func get_forest_shield_percent() -> float:
	if _tree_entries.is_empty():
		return 100.0

	var total := 0.0
	for entry in _tree_entries:
		total += _get_entry_health_percent(entry)
	return total / float(TREE_COUNT)


func get_tree_status(index: int) -> Dictionary:
	if index < 0 or index >= _tree_entries.size():
		return {}

	var entry: Dictionary = _tree_entries[index]
	return {
		"display_name": entry.get("hud_label", "Tree"),
		"health_percent": _get_entry_health_percent(entry),
		"status_text": _get_entry_status_text(entry),
	}


func get_all_tree_statuses() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for i in TREE_COUNT:
		results.append(get_tree_status(i))
	return results


func _build_tree_entries() -> void:
	_tree_entries = [
		{
			"id": 0,
			"section": "Forest Floor",
			"hud_label": "Forest Floor Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
			"is_active_target": true,
			"under_attack": true,
			"stabilized": false,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 1,
			"section": "Canopy",
			"hud_label": "Canopy Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
			"is_active_target": false,
			"under_attack": false,
			"stabilized": false,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 2,
			"section": "Underground",
			"hud_label": "Underground Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
			"is_active_target": false,
			"under_attack": false,
			"stabilized": false,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 3,
			"section": "Industrial Edge",
			"hud_label": "Industrial Edge Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
			"is_active_target": false,
			"under_attack": false,
			"stabilized": false,
			"damage_blocks": [100, 100, 100, 100],
		},
	]


func _wire_tree_1() -> void:
	var tree := get_node_or_null(tree_1_path)
	if tree == null:
		push_error("ForestShieldManager: Tree 1 not found at %s" % tree_1_path)
		return

	_tree_entries[0]["tree_node"] = tree
	if tree.has_signal("health_changed"):
		tree.health_changed.connect(_on_tree_1_health_changed)
	if tree.has_signal("healed"):
		tree.healed.connect(_on_tree_1_healed)
	if tree.has_signal("stabilized"):
		tree.stabilized.connect(_on_tree_1_stabilized)
	if tree.has_signal("under_attack_changed"):
		tree.under_attack_changed.connect(_on_tree_1_under_attack_changed)


func _on_tree_1_health_changed(_percent: float = 0.0) -> void:
	_refresh_shield()


func _on_tree_1_healed() -> void:
	_refresh_shield()


func _on_tree_1_stabilized() -> void:
	_tree_entries[0]["stabilized"] = true
	_tree_entries[0]["under_attack"] = false
	_advance_active_target(1)


func _on_tree_1_under_attack_changed(is_under_attack: bool) -> void:
	_tree_entries[0]["under_attack"] = is_under_attack and not _tree_entries[0].get("stabilized", false)
	_refresh_shield()


func _advance_active_target(next_index: int) -> void:
	if next_index < 0 or next_index >= TREE_COUNT:
		return

	_active_tree_index = next_index
	for i in TREE_COUNT:
		var entry: Dictionary = _tree_entries[i]
		entry["is_active_target"] = i == next_index
		if i != next_index:
			entry["under_attack"] = false

	var next_entry: Dictionary = _tree_entries[next_index]
	next_entry["under_attack"] = true
	if next_entry.get("tree_node") == null:
		next_entry["placeholder_health_percent"] = 75.0

	var label: String = next_entry.get("hud_label", "Tree")
	active_target_changed.emit(next_index, label)
	_refresh_shield()


func _mark_tree_under_attack(index: int) -> void:
	if index < 0 or index >= _tree_entries.size():
		return
	_tree_entries[index]["under_attack"] = true


func _get_entry_health_percent(entry: Dictionary) -> float:
	var tree: Node = entry.get("tree_node")
	if tree != null and is_instance_valid(tree):
		if tree.has_method("get_health_percent"):
			return tree.get_health_percent()
	return float(entry.get("placeholder_health_percent", 100.0))


func _get_entry_status_text(entry: Dictionary) -> String:
	var tree: Node = entry.get("tree_node")
	if tree != null and is_instance_valid(tree) and tree.has_method("get_tree_status_text"):
		return tree.get_tree_status_text()

	if entry.get("stabilized", false):
		return "Stabilized"
	if entry.get("under_attack", false) and entry.get("is_active_target", false):
		return "Under Attack"
	if entry.get("is_active_target", false):
		return "Damaged"

	var health := float(entry.get("placeholder_health_percent", 100.0))
	if health <= 0.0:
		return "Fully Corrupted"
	if health <= 30.0:
		return "Critical"
	if health < 100.0:
		return "Damaged"
	return "Healthy"


func _refresh_shield() -> void:
	var percent := get_forest_shield_percent()
	if _last_shield_percent >= 0.0 and is_equal_approx(percent, _last_shield_percent):
		# Still refresh HUD when only status text changes.
		forest_shield_changed.emit(percent)
		return
	_last_shield_percent = percent
	forest_shield_changed.emit(percent)
