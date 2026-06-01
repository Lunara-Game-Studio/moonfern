extends StaticBody2D

var is_healed := false

@onready var _interact_area: Area2D = get_node_or_null("InteractArea")
@onready var _sprite: Sprite2D = $"Tree I"


func _ready() -> void:
	print("HealingTree script ready")
	if _interact_area == null:
		push_error("Tree InteractArea missing")
		return

	print("Tree InteractArea found")
	if not _interact_area.body_entered.is_connected(_on_body_entered):
		_interact_area.body_entered.connect(_on_body_entered)
	if not _interact_area.body_exited.is_connected(_on_body_exited):
		_interact_area.body_exited.connect(_on_body_exited)
	_apply_visual()


func interact(player: Node) -> void:
	if is_healed:
		return

	if player.has_method("consume_carried_item") and player.consume_carried_item("Potion"):
		is_healed = true
		_apply_visual()
		print("Tree healed")
	else:
		print("Need Potion to heal this tree")


func _apply_visual() -> void:
	if is_healed:
		_sprite.modulate = Color(0.85, 1.0, 0.85)
	else:
		_sprite.modulate = Color(0.55, 0.45, 0.5)


func _on_body_entered(body: Node2D) -> void:
	print("Tree area entered by: ", body.name)
	if body.has_method("register_nearby_interactable"):
		print("Tree nearby")
		body.register_nearby_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	print("Tree area exited by: ", body.name)
	if body.has_method("unregister_nearby_interactable"):
		body.unregister_nearby_interactable(self)
