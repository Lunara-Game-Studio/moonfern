extends Node2D

@export var tree_path: NodePath = ^"Tree"
@export var enemy_path: NodePath = ^"Gleamwrought"
@export var hud_path: NodePath = ^"CorruptionHUD/HUDPanel"


func _ready() -> void:
	var tree := get_node_or_null(tree_path)
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

	if tree.has_signal("became_critical"):
		tree.became_critical.connect(_on_tree_critical.bind(enemy, hud))
	if tree.has_signal("became_fully_corrupted"):
		tree.became_fully_corrupted.connect(_on_tree_fully_corrupted.bind(enemy, hud))
	if tree.has_signal("healed"):
		tree.healed.connect(_on_tree_healed.bind(enemy, hud))


func _on_tree_critical(enemy: Node, hud: Node) -> void:
	if hud.has_method("on_tree_critical"):
		hud.on_tree_critical()
	if enemy and enemy.has_method("on_tree_critical"):
		enemy.on_tree_critical()


func _on_tree_fully_corrupted(enemy: Node, hud: Node) -> void:
	if hud.has_method("on_tree_fully_corrupted"):
		hud.on_tree_fully_corrupted()
	if enemy and enemy.has_method("on_tree_fully_corrupted"):
		enemy.on_tree_fully_corrupted()


func _on_tree_healed(enemy: Node, hud: Node) -> void:
	if hud.has_method("on_tree_healed"):
		hud.on_tree_healed()
	if enemy and enemy.has_method("on_tree_healed"):
		enemy.on_tree_healed()
