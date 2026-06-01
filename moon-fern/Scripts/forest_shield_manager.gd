extends Node

signal forest_shield_changed(percent: float)

const TREE_COUNT := 4

@export var tree_1_path: NodePath = ^"../Tree" # Sibling healable tree (Forest Floor / Tree 1).

var _last_shield_percent: float = -1.0
var _tree_entries: Array[Dictionary] = []


func _ready() -> void:
	_build_tree_entries()
	_wire_tree_1()
	call_deferred("_refresh_shield")


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
			# Future: per-tree corruption blocks (not interactive yet).
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 1,
			"section": "Canopy",
			"hud_label": "Canopy Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 2,
			"section": "Underground",
			"hud_label": "Underground Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
			"damage_blocks": [100, 100, 100, 100],
		},
		{
			"id": 3,
			"section": "Industrial Edge",
			"hud_label": "Industrial Edge Tree",
			"tree_node": null,
			"placeholder_health_percent": 100.0,
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


func _on_tree_1_health_changed(_percent: float = 0.0) -> void:
	_refresh_shield()


func _on_tree_1_healed() -> void:
	_refresh_shield()


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
	return "Healthy"


func _refresh_shield() -> void:
	var percent := get_forest_shield_percent()
	if _last_shield_percent >= 0.0 and is_equal_approx(percent, _last_shield_percent):
		return
	_last_shield_percent = percent
	forest_shield_changed.emit(percent)
