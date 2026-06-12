extends Node2D

@export var tree_path: NodePath = ^"Tree"
@export var enemy_path: NodePath = ^"Gleamwrought"
@export var hud_path: NodePath = ^"CorruptionHUD/HUDPanel"
@export var forest_shield_manager_path: NodePath = ^"ForestShieldManager"
@export var forest_shield_hud_path: NodePath = ^"ForestShieldHUD"


func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	var tree := get_tree().get_first_node_in_group("healable_tree")
	var enemy := get_node_or_null(enemy_path)
	var hud := get_node_or_null(hud_path)

	if tree == null:
		push_error("CorruptionFeedback: Tree not found")
		return
	if hud == null:
		push_error("CorruptionFeedback: HUD not found")
		return

	if hud.has_method("setup"):
		hud.setup(tree)

	var shield_manager := get_node_or_null(forest_shield_manager_path)
	var shield_hud := get_node_or_null(forest_shield_hud_path)
	if shield_manager == null:
		push_warning("CorruptionFeedback: ForestShieldManager not found")
	elif shield_hud and shield_hud.has_method("setup"):
		shield_hud.setup(shield_manager)

	if tree.has_signal("became_critical"):
		tree.became_critical.connect(_on_tree_critical.bind(enemy, hud))
	if tree.has_signal("became_fully_corrupted"):
		tree.became_fully_corrupted.connect(_on_tree_fully_corrupted.bind(enemy, hud))
	if tree.has_signal("healed"):
		tree.healed.connect(_on_tree_healed.bind(enemy, hud))
	if tree.has_signal("stabilized"):
		tree.stabilized.connect(_on_tree_stabilized)
	if tree.has_signal("under_attack_changed"):
		tree.under_attack_changed.connect(_on_tree_under_attack_changed)

	if shield_manager and shield_manager.has_signal("active_target_changed"):
		shield_manager.active_target_changed.connect(_on_active_target_changed)


func _notify_player(message: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_notification"):
		player.show_notification(message)


func _on_tree_critical(_enemy: Node, hud: Node) -> void:
	_notify_player("Tree critical!")
	if hud.has_method("on_tree_critical"):
		hud.on_tree_critical()
	_apply_enemy_pressure("critical")


func _on_tree_fully_corrupted(_enemy: Node, hud: Node) -> void:
	_notify_player("Tree fully corrupted!")
	if hud.has_method("on_tree_fully_corrupted"):
		hud.on_tree_fully_corrupted()
	_apply_enemy_pressure("fully_corrupted")


func _on_tree_healed(_enemy: Node, hud: Node) -> void:
	# Full-heal toast is shown by healing_tree when potion brings health to 100%.
	if hud.has_method("on_tree_healed"):
		hud.on_tree_healed()
	_apply_enemy_pressure("healed")


func _on_tree_stabilized() -> void:
	_apply_enemy_pressure("healed")


func _on_tree_under_attack_changed(is_under_attack: bool) -> void:
	if is_under_attack:
		_notify_player("Tree under attack!")


func _on_active_target_changed(_index: int, display_name: String) -> void:
	_notify_player("%s is under attack!" % display_name)


func _apply_enemy_pressure(level: String) -> void:
	for node in get_tree().get_nodes_in_group("gleamwrought"):
		if node.has_method("set_corruption_pressure"):
			node.set_corruption_pressure(level)
