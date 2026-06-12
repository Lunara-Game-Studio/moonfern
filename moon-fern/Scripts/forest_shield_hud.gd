extends CanvasLayer

@onready var _shield_label: Label = $MinimalHUD/MarginContainer/VBox/ShieldLabel
@onready var _shield_bar: ProgressBar = $MinimalHUD/MarginContainer/VBox/ShieldBar
@onready var _charge_label: Label = $MinimalHUD/MarginContainer/VBox/ChargeLabel
@onready var _charge_bar: ProgressBar = $MinimalHUD/MarginContainer/VBox/ChargeBar
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
	if _manager.has_signal("tree_charge_changed"):
		_manager.tree_charge_changed.connect(_on_tree_charge_changed)
	if _manager.has_signal("forest_shield_collapsed"):
		_manager.forest_shield_collapsed.connect(_on_forest_shield_collapsed)
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


func _on_tree_charge_changed(_percent: float) -> void:
	_refresh_minimal_display()
	if _forest_status_panel.visible:
		_refresh_forest_status_display()


func _on_forest_shield_collapsed() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_notification"):
		player.show_notification("Forest Shield collapsed")


func _refresh_minimal_display() -> void:
	if _manager == null:
		return
	var shield_percent: float = _manager.get_forest_shield_percent()
	_shield_label.text = "Forest Shield: %d%%" % int(round(shield_percent))
	_shield_bar.value = shield_percent

	var charge_percent: float = 0.0
	if _manager.has_method("get_active_tree_charge_percent"):
		charge_percent = _manager.get_active_tree_charge_percent()
	_charge_label.text = "Tree Charge: %d%%" % int(round(charge_percent))
	_charge_bar.value = charge_percent


func _refresh_forest_status_display() -> void:
	if _manager == null:
		return
	var statuses: Array = _manager.get_all_tree_statuses()
	for i in _tree_labels.size():
		if i >= statuses.size():
			continue
		var data: Dictionary = statuses[i]
		var tree_name: String = data.get("display_name", "Tree")
		var charge: float = data.get("charge_percent", 0.0)
		var status: String = data.get("status_text", "Dormant")
		_tree_labels[i].text = "%s: %d%% — %s" % [tree_name, int(round(charge)), status]
		_apply_status_color(_tree_labels[i], status)


func _apply_status_color(label: Label, status: String) -> void:
	match status:
		"Fully Charged":
			label.modulate = Color(0.7, 1.0, 0.75)
		"Charging":
			label.modulate = Color(0.75, 0.95, 0.8)
		"Under Attack":
			label.modulate = Color(1.0, 0.55, 0.45)
		"Dormant":
			label.modulate = Color(0.55, 0.5, 0.55)
		_:
			label.modulate = Color(0.92, 0.9, 0.82)
