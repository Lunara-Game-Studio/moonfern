extends Control

@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var _health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar

var _tree: Node = null
var _pulse_time := 0.0
var _urgent_mode := false


func setup(tree: Node) -> void:
	_tree = tree
	_update_display(0.0)


func on_tree_critical() -> void:
	_urgent_mode = true


func on_tree_fully_corrupted() -> void:
	_urgent_mode = true


func on_tree_healed() -> void:
	_urgent_mode = false
	_pulse_time = 0.0


func _process(delta: float) -> void:
	if _tree == null:
		return
	_update_display(delta)


func _update_display(delta: float) -> void:
	if _tree.is_healed:
		_health_bar.value = 100.0
		_status_label.text = "TREE HEALED"
		_status_label.modulate = Color(0.7, 1.0, 0.75)
		return

	var percent: float = _tree.get_health_percent()
	_health_bar.value = percent

	if _tree.is_fully_corrupted():
		_status_label.text = "TREE FULLY CORRUPTED"
		_pulse_time += delta
		var dim: float = 0.65 + 0.35 * abs(sin(_pulse_time * 4.0))
		_status_label.modulate = Color(0.45 * dim, 0.25 * dim, 0.35 * dim)
	elif _tree.is_critical():
		_status_label.text = "TREE CRITICAL"
		_pulse_time += delta
		var flash: float = 0.75 + 0.25 * abs(sin(_pulse_time * 8.0))
		_status_label.modulate = Color(1.0, 0.35 * flash, 0.45 * flash)
	else:
		_status_label.text = "Tree Health: %d%%" % int(round(percent))
		_status_label.modulate = Color(0.92, 0.9, 0.82)
