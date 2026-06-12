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

	if tree.has_signal("healed"):
		tree.healed.connect(_on_tree_healed.bind(enemy, hud))
	if tree.has_signal("under_attack_changed"):
		tree.under_attack_changed.connect(_on_tree_under_attack_changed)


func _notify_player(message: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("show_notification"):
		player.show_notification(message)


func _on_tree_healed(_enemy: Node, hud: Node) -> void:
	if hud.has_method("on_tree_healed"):
		hud.on_tree_healed()
	_apply_enemy_pressure("healed")
	_notify_player("Next area unlocked!")


func _on_tree_under_attack_changed(is_under_attack: bool) -> void:
	if is_under_attack:
		_notify_player("Tree under attack!")


func _apply_enemy_pressure(level: String) -> void:
	for node in get_tree().get_nodes_in_group("gleamwrought"):
		if node.has_method("set_corruption_pressure"):
			node.set_corruption_pressure(level)
