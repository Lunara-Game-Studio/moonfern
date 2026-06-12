extends CanvasLayer

@onready var _shield_label: Label = $MinimalHUD/MarginContainer/VBox/ShieldLabel
@onready var _shield_bar: ProgressBar = $MinimalHUD/MarginContainer/VBox/ShieldBar
@onready var _forest_status_panel: PanelContainer = $ForestStatusPanel
@onready var _tree_labels: Array[Label] = [
	$ForestStatusPanel/MarginContainer/VBox/TreeRows/Tree1Label,
	$ForestStatusPanel/MarginContainer/VBox/TreeRows/Tree2Label,
	$ForestStatusPanel/MarginContainer/VBox/TreeRows/Tree3Label,
	$ForestStatusPanel/MarginContainer/VBox/TreeRows/Tree4Label,
]

var _manager: Node = null


func _ready() -> void:
	add_to_group("forest_shield_hud")
	_forest_status_panel.visible = false


func setup(manager: Node) -> void:
	_manager = manager
	if _manager.has_signal("forest_shield_changed"):
		_manager.forest_shield_changed.connect(_on_forest_shield_changed)
	_refresh_minimal_display()
	_refresh_forest_status_display()


func toggle_forest_status_panel() -> void:
	_forest_status_panel.visible = not _forest_status_panel.visible
	if _forest_status_panel.visible:
		_refresh_forest_status_display()


func _on_forest_shield_changed(_percent: float) -> void:
	print("HUD received shield change: ", _percent)
	_refresh_minimal_display()
	if _forest_status_panel.visible:
		_refresh_forest_status_display()


func _refresh_minimal_display() -> void:
	if _manager == null:
		return
	var shield_percent: float = _manager.get_forest_shield_percent()
	_shield_label.text = "Forest Shield: %d%%" % int(round(shield_percent))
	_shield_bar.value = shield_percent


func _refresh_forest_status_display() -> void:
	if _manager == null:
		return
	var statuses: Array = _manager.get_all_tree_statuses()
	for i in _tree_labels.size():
		if i >= statuses.size():
			continue
		var data: Dictionary = statuses[i]
		var tree_name: String = data.get("display_name", "Tree")
		var health: float = data.get("health_percent", 100.0)
		var status: String = data.get("status_text", "Healthy")
		_tree_labels[i].text = "%s: %d%% — %s" % [tree_name, int(round(health)), status]
		_apply_status_color(_tree_labels[i], status)


func _apply_status_color(label: Label, status: String) -> void:
	match status:
		"Healed":
			label.modulate = Color(0.7, 1.0, 0.75)
		"Stabilized":
			label.modulate = Color(0.65, 0.95, 0.85)
		"Under Attack":
			label.modulate = Color(1.0, 0.55, 0.45)
		"Fully Corrupted":
			label.modulate = Color(0.55, 0.35, 0.45)
		"Critical":
			label.modulate = Color(1.0, 0.45, 0.5)
		"Damaged":
			label.modulate = Color(0.95, 0.8, 0.65)
		"Restored":
			label.modulate = Color(0.75, 0.95, 0.8)
		_:
			label.modulate = Color(0.92, 0.9, 0.82)
