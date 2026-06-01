extends StaticBody2D

@onready var _interact_area: Area2D = get_node_or_null("InteractArea")


func _ready() -> void:
	add_to_group("interactable")
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
	if not player.has_method("has_carried_item"):
		_notify(player, "Need Herb to brew")
		return

	if player.has_carried_item("Potion"):
		print("Already carrying Potion")
		return

	if player.has_carried_item("Herb"):
		if player.consume_carried_item("Herb"):
			player.replace_carried_item("Potion")
			_on_potion_brewed(player)
			print("Cauldron received carried Herb")
			print("Brewed Potion from Herb")
			print("Now carrying: Potion")
		else:
			_notify(player, "Need Herb to brew")
		return

	if player.is_carrying:
		_notify(player, "Need Herb to brew")
		return

	var dropped_herb := _find_dropped_herb_in_area()
	if dropped_herb:
		dropped_herb.queue_free()
		if player.has_method("give_brewed_item") and player.give_brewed_item("Potion"):
			_on_potion_brewed(player)
			print("Cauldron consumed dropped Herb")
			print("Brewed Potion from dropped Herb")
			print("Now carrying: Potion")
		else:
			_notify(player, "Need Herb to brew")
		return

	_notify(player, "Need Herb to brew")


func _on_potion_brewed(player: Node) -> void:
	_notify(player, "Potion brewed!")
	_notify(player, "Potion added to inventory")


func _notify(player: Node, message: String) -> void:
	if player.has_method("show_notification"):
		player.show_notification(message)


func _get_interact_bounds() -> Rect2:
	var collision := _interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return Rect2()
	if collision.shape is RectangleShape2D:
		var shape := collision.shape as RectangleShape2D
		var half := shape.size * 0.5
		return Rect2(collision.global_position - half, shape.size)
	return Rect2()


func _pickup_in_interact_bounds(pickup: Node2D) -> bool:
	var bounds := _get_interact_bounds()
	if bounds.size == Vector2.ZERO:
		return false
	var collision := pickup.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var pos: Vector2 = collision.global_position if collision else pickup.global_position
	return bounds.has_point(pos)


func _find_dropped_herb_in_area() -> Node:
	for node in get_tree().get_nodes_in_group("herb_pickup"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		if not node.has_method("get_item_type") or node.get_item_type() != "Herb":
			continue
		if _pickup_in_interact_bounds(node as Node2D):
			return node
	return null


func _on_body_entered(body: Node2D) -> void:
	print("Cauldron area entered by: ", body.name)
	var player := _resolve_player(body)
	if player:
		print("Cauldron nearby")
		player.register_nearby_interactable(self)


func _on_body_exited(body: Node2D) -> void:
	print("Cauldron area exited by: ", body.name)
	var player := _resolve_player(body)
	if player:
		player.unregister_nearby_interactable(self)


func _resolve_player(node: Node) -> Node:
	if node == null:
		return null
	if node.is_in_group("player") and node is CharacterBody2D:
		return node
	var parent := node.get_parent()
	if parent and parent.is_in_group("player") and parent is CharacterBody2D:
		return parent
	return null
