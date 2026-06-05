extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "TheWitch":
		var new_scene = load("res://Scenes/underground_forest.tscn").instantiate()
		print(new_scene)
		get_parent().get_parent().get_node("Base forest").queue_free()
		get_parent().get_parent().add_child(new_scene)
		body.global_position = Vector2(600, 100)
