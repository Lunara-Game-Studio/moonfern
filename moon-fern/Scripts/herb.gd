extends Area2D

const ITEM_TYPE := "Herb"

var _pickup_enabled := true

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func enable_pickup_after_delay(seconds: float) -> void:
	_pickup_enabled = false
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		_pickup_enabled = true
	)


func get_item_type() -> String:
	return ITEM_TYPE


func _on_body_entered(body: Node2D) -> void:
	if not _pickup_enabled:
		return
	if body.has_method("register_nearby_pickup"):
		body.register_nearby_pickup(self)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("unregister_nearby_pickup"):
		body.unregister_nearby_pickup(self)
