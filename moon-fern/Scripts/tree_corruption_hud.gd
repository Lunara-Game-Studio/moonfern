extends Control

# Legacy panel kept for corruption_feedback wiring; hidden during gameplay.
# Tree state feedback is shown via toasts and the Forest Shield HUD.

var _tree: Node = null


func setup(tree: Node) -> void:
	_tree = tree
	visible = false


func on_tree_critical() -> void:
	pass


func on_tree_fully_corrupted() -> void:
	pass


func on_tree_healed() -> void:
	pass
