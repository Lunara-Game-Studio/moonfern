extends CharacterBody2D

const SPEED := 600.0
const JUMP_VELOCITY := -600.0
const CARRY_SPEED_MULTIPLIER := 0.65
const MAX_ITEMS := 1
const DROP_PICKUP_COOLDOWN := 0.3
const DROP_PICKUP_FALLBACK_HALF := 8.0
const PLAYER_COLLISION_FALLBACK_HALF := 16.0

@export var drop_padding: float = 4.0
@export var drop_vertical_tweak: float = 0.0

const HERB_PICKUP_SCENE := preload("res://Scenes/herb_pickup.tscn")
const POTION_PICKUP_SCENE := preload("res://Scenes/potion_pickup.tscn")

var inventory: Array[String] = []
var carried_item_type: String = ""
var is_carrying := false
var nearby_pickup: Node = null
var nearby_interactable: Node = null
var last_facing_direction := 1

func _ready() -> void:
	print("TheWitch script ready")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("pickup"):
		print("pickup pressed")
		_try_pickup()

	if Input.is_action_just_pressed("drop"):
		print("drop pressed")
		drop_item()

	if Input.is_action_just_pressed("interact"):
		print("interact pressed")
		_try_interact()

	var direction := Input.get_axis("move_left", "move_right")
	var move_speed := SPEED * (CARRY_SPEED_MULTIPLIER if is_carrying else 1.0)
	if direction != 0.0:
		last_facing_direction = int(signf(direction))
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

	move_and_slide()


func can_pick_up() -> bool:
	return not is_carrying and inventory.size() < MAX_ITEMS


func has_carried_item(item_type: String) -> bool:
	return is_carrying and carried_item_type == item_type


func pick_up_item(item_type: String) -> bool:
	if not can_pick_up():
		print("Inventory full — cannot pick up ", item_type)
		return false

	carried_item_type = item_type
	is_carrying = true
	inventory = [item_type]
	print("Picked up: ", item_type)
	return true


func consume_carried_item(expected_type: String) -> bool:
	if not has_carried_item(expected_type):
		return false

	carried_item_type = ""
	is_carrying = false
	inventory.clear()
	return true


func replace_carried_item(new_item_type: String) -> void:
	carried_item_type = new_item_type
	is_carrying = true
	inventory = [new_item_type]


func drop_item() -> void:
	if not is_carrying:
		return

	var dropped_type := carried_item_type
	carried_item_type = ""
	is_carrying = false
	inventory.clear()
	nearby_pickup = null
	print("Dropped: ", dropped_type)
	_spawn_dropped_pickup(dropped_type)


func _get_shape_half_extents(collision: CollisionShape2D, fallback_half: float) -> Vector2:
	if collision == null or collision.shape == null:
		return Vector2(fallback_half, fallback_half)

	var shape := collision.shape
	if shape is RectangleShape2D:
		return shape.size * 0.5
	if shape is CircleShape2D:
		return Vector2(shape.radius, shape.radius)
	if shape is CapsuleShape2D:
		return Vector2(shape.radius, shape.height * 0.5 + shape.radius)

	return Vector2(fallback_half, fallback_half)


func _get_player_collision_bounds() -> Dictionary:
	var body_collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_collision == null:
		var fallback := PLAYER_COLLISION_FALLBACK_HALF
		return {
			"center": global_position,
			"half_width": fallback,
			"half_height": fallback,
		}

	var half_extents := _get_shape_half_extents(body_collision, PLAYER_COLLISION_FALLBACK_HALF)
	return {
		"center": body_collision.global_position,
		"half_width": half_extents.x,
		"half_height": half_extents.y,
	}


func _find_pickup_collision(pickup: Node) -> CollisionShape2D:
	if pickup is CollisionShape2D:
		return pickup
	for child in pickup.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _calculate_dynamic_drop_position(pickup: Node2D) -> Dictionary:
	var player_bounds := _get_player_collision_bounds()
	var item_collision := _find_pickup_collision(pickup)
	var item_half_extents := _get_shape_half_extents(item_collision, DROP_PICKUP_FALLBACK_HALF)

	var player_center: Vector2 = player_bounds["center"]
	var player_half_width: float = player_bounds["half_width"]
	var player_half_height: float = player_bounds["half_height"]
	var item_half_width: float = item_half_extents.x
	var item_half_height: float = item_half_extents.y

	var x_offset := (player_half_width + item_half_width + drop_padding) * last_facing_direction
	var y_offset := player_half_height - item_half_height
	var drop_pos := player_center + Vector2(x_offset, y_offset)
	drop_pos.y += drop_vertical_tweak

	return {
		"position": drop_pos,
		"player_center": player_center,
		"player_half_width": player_half_width,
		"player_half_height": player_half_height,
		"item_half_width": item_half_width,
		"item_half_height": item_half_height,
	}


func _spawn_dropped_pickup(item_type: String) -> void:
	var packed: PackedScene = null
	match item_type:
		"Herb":
			packed = HERB_PICKUP_SCENE
		"Potion":
			packed = POTION_PICKUP_SCENE
		_:
			push_warning("Unknown dropped item type: ", item_type)
			return

	var world_parent := get_parent()
	var pickup: Node2D = packed.instantiate()
	world_parent.add_child(pickup)

	var drop_data := _calculate_dynamic_drop_position(pickup)
	var drop_pos: Vector2 = drop_data["position"]
	pickup.global_position = drop_pos

	if pickup.has_method("enable_pickup_after_delay"):
		pickup.enable_pickup_after_delay(DROP_PICKUP_COOLDOWN)

	print("Player collision center: ", drop_data["player_center"])
	print("Player half width/height: ", drop_data["player_half_width"], " / ", drop_data["player_half_height"])
	print("Item half width/height: ", drop_data["item_half_width"], " / ", drop_data["item_half_height"])
	print("Facing direction: ", last_facing_direction)
	print("Final dynamic drop position: ", drop_pos)
	print("Dropped item global position: ", pickup.global_position)
	print("Spawned dropped item: ", item_type)


func register_nearby_pickup(pickup: Node) -> void:
	nearby_pickup = pickup


func unregister_nearby_pickup(pickup: Node) -> void:
	if nearby_pickup == pickup:
		nearby_pickup = null


func register_nearby_interactable(interactable: Node) -> void:
	nearby_interactable = interactable
	print("Registered interactable: ", interactable.name)


func unregister_nearby_interactable(interactable: Node) -> void:
	if nearby_interactable == interactable:
		nearby_interactable = null
	print("Unregistered interactable: ", interactable.name)


func _try_pickup() -> void:
	if nearby_pickup == null or not is_instance_valid(nearby_pickup):
		return

	if not can_pick_up():
		print("Inventory full")
		return

	var item_type := "Unknown"
	if nearby_pickup.has_method("get_item_type"):
		item_type = nearby_pickup.get_item_type()

	if pick_up_item(item_type):
		nearby_pickup.queue_free()
		nearby_pickup = null


func _try_interact() -> void:
	if nearby_interactable == null or not is_instance_valid(nearby_interactable):
		print("No nearby interactable")
		return

	print("Interacting with: ", nearby_interactable.name)
	if nearby_interactable.has_method("interact"):
		nearby_interactable.interact(self)
