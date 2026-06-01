extends StaticBody2D

@onready var _interact_area: Area2D = get_node_or_null("InteractArea")


func _ready() -> void:
	print("Cauldron script ready")
	if _interact_area == null:
		push_error("Cauldron InteractArea missing")
		return

	print("Cauldron InteractArea found")
	if not _interact_area.body_entered.is_connected(_on_body_entered):
		_interact_area.body_entered.connect(_on_body_entered)
	if not _interact_area.body_exited.is_connected(_on_body_exited):
		_interact_area.body_exited.connect(_on_body_exited)


func interact(player: Node) -> void:
	if player.has_method("has_carried_item") and player.has_carried_item("Herb"):
		if player.consume_carried_item("Herb"):
			player.replace_carried_item("Potion")
			print("Brewed Potion from Herb")
	else:
		print("Need Herb to brew")


func _on_body_entered(body: Node2D) -> void:
	print("Cauldron area entered by: ", body.name)
	if body.has_method("register_nearby_interactable"):
		print("Cauldron nearby")
		body.register_nearby_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	print("Cauldron area exited by: ", body.name)
	if body.has_method("unregister_nearby_interactable"):
		body.unregister_nearby_interactable(self)
