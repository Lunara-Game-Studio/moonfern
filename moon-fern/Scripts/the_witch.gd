extends CharacterBody2D

const MAX_ITEMS := 1
const DROP_PICKUP_COOLDOWN := 0.3
const DROP_PICKUP_FALLBACK_HALF := 8.0
const PLAYER_COLLISION_FALLBACK_HALF := 16.0

@export var max_speed: float = 520.0
@export var carry_speed_multiplier: float = 0.72
@export var acceleration: float = 2200.0
@export var deceleration: float = 2800.0
@export var air_acceleration: float = 1600.0
@export var air_deceleration: float = 2000.0

@export var jump_velocity: float = -650.0
@export var gravity_multiplier: float = 1.0
@export var fall_gravity_multiplier: float = 1.45
@export var low_jump_multiplier: float = 2.3

@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export var drop_padding: float = 4.0
@export var drop_vertical_tweak: float = 0.0

const HERB_PICKUP_SCENE := preload("res://Scenes/herb_pickup.tscn")
const POTION_PICKUP_SCENE := preload("res://Scenes/potion_pickup.tscn")
const INTERACT_FALLBACK_RADIUS := 100.0

var inventory: Array[String] = []
var carried_item_type: String = ""
var is_carrying := false
var nearby_pickup: Node = null
var nearby_interactable: Node = null
var last_facing_direction := 1
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	print("TheWitch script ready")
	_sync_inventory_feedback()

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	elif _coyote_timer > 0.0:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	if Input.is_action_just_pressed("pickup"):
		print("pickup pressed")
		_try_pickup()

	if Input.is_action_just_pressed("drop"):
		print("drop pressed")
		drop_item()

	if Input.is_action_just_pressed("interact"):
		print("interact pressed")
		_try_interact()

	if Input.is_action_just_pressed("inventory"):
		var ui := _get_feedback_ui()
		if ui and ui.has_method("toggle_inventory_panel"):
			ui.toggle_inventory_panel()

	if Input.is_action_just_pressed("forest_status"):
		var shield_hud := get_tree().get_first_node_in_group("forest_shield_hud")
		if shield_hud and shield_hud.has_method("toggle_forest_status_panel"):
			shield_hud.toggle_forest_status_panel() # M — forest status panel

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	elif _jump_buffer_timer > 0.0:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	_apply_horizontal_movement(delta)
	_apply_gravity(delta)
	_try_jump()

	move_and_slide()


func _apply_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := max_speed * (carry_speed_multiplier if is_carrying else 1.0)

	if direction != 0.0:
		last_facing_direction = int(signf(direction))
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction * target_speed, accel * delta)
	else:
		var decel := deceleration if is_on_floor() else air_deceleration
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return

	var grav_scale := gravity_multiplier
	if velocity.y < 0.0:
		if Input.is_action_pressed("jump"):
			grav_scale = gravity_multiplier
		else:
			grav_scale = low_jump_multiplier
	else:
		grav_scale = fall_gravity_multiplier

	velocity += get_gravity() * grav_scale * delta


func _try_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return

	velocity.y = jump_velocity
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0


func can_pick_up() -> bool:
	return not is_carrying and inventory.size() < MAX_ITEMS


func has_carried_item(item_type: String) -> bool:
	return is_carrying and carried_item_type == item_type


func pick_up_item(item_type: String) -> bool:
	if not can_pick_up():
		print("Inventory full — cannot pick up ", item_type)
		show_notification("Inventory full")
		return false

	carried_item_type = item_type
	is_carrying = true
	inventory = [item_type]
	print("Picked up: ", item_type)
	_sync_inventory_feedback()
	show_notification("Picked up %s" % item_type)
	return true


func consume_carried_item(expected_type: String) -> bool:
	print(
		"Trying to consume: ",
		expected_type,
		", currently carrying: ",
		carried_item_type if is_carrying else "nothing"
	)
	if not has_carried_item(expected_type):
		return false

	carried_item_type = ""
	is_carrying = false
	inventory.clear()
	_sync_inventory_feedback()
	return true


func replace_carried_item(new_item_type: String) -> void:
	if is_carrying:
		push_warning("replace_carried_item called while still carrying something")
		return
	print("Replacing carried item with: ", new_item_type)
	carried_item_type = new_item_type
	is_carrying = true
	inventory = [new_item_type]
	_sync_inventory_feedback()


func give_brewed_item(item_type: String) -> bool:
	if not can_pick_up():
		return false
	carried_item_type = item_type
	is_carrying = true
	inventory = [item_type]
	_sync_inventory_feedback()
	return true


func show_notification(message: String) -> void:
	var ui := _get_feedback_ui()
	if ui and ui.has_method("show_notification"):
		ui.show_notification(message)


func _sync_inventory_feedback() -> void:
	var item_type := carried_item_type if is_carrying else ""
	var ui := _get_feedback_ui()
	if ui == null:
		return
	if ui.has_method("update_carry_display"):
		ui.update_carry_display(item_type)
	if ui.has_method("update_inventory_display"):
		ui.update_inventory_display(item_type)


func _get_feedback_ui() -> Node:
	return get_tree().get_first_node_in_group("player_feedback_ui")


func on_caught_by_enemy() -> void:
	if is_carrying:
		drop_item()
		print("Nyra dropped item after being caught")
	else:
		print("Nyra was caught but had nothing to drop")


func drop_item() -> void:
	if not is_carrying:
		return

	var dropped_type := carried_item_type
	carried_item_type = ""
	is_carrying = false
	inventory.clear()
	nearby_pickup = null
	print("Dropped: ", dropped_type)
	show_notification("Dropped %s" % dropped_type)
	_sync_inventory_feedback()
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
	call_deferred("_refresh_nearby_interactable")


func _refresh_nearby_interactable() -> void:
	var found := _find_interactable_in_range()
	if found:
		nearby_interactable = found
		print("Refreshed active interactable: ", found.name)


func _get_interact_area_center(interact_area: Area2D) -> Vector2:
	var collision := interact_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		return collision.global_position
	return interact_area.global_position


func _is_player_overlapping_area(interact_area: Area2D) -> bool:
	for body in interact_area.get_overlapping_bodies():
		if body == self:
			return true
	return false


func _find_interactable_in_range() -> Node:
	var player_center: Vector2 = _get_player_collision_bounds()["center"]
	var best: Node = null
	var best_distance := INTERACT_FALLBACK_RADIUS

	for node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("interact"):
			continue
		var interact_area := node.get_node_or_null("InteractArea") as Area2D
		if interact_area == null:
			continue
		if not _is_player_overlapping_area(interact_area):
			continue
		var distance := player_center.distance_to(_get_interact_area_center(interact_area))
		if distance <= best_distance:
			best_distance = distance
			best = node

	return best


func _try_pickup() -> void:
	if nearby_pickup == null or not is_instance_valid(nearby_pickup):
		return

	if not can_pick_up():
		print("Inventory full")
		show_notification("Inventory full")
		return

	var item_type := "Unknown"
	if nearby_pickup.has_method("get_item_type"):
		item_type = nearby_pickup.get_item_type()

	if pick_up_item(item_type):
		nearby_pickup.queue_free()
		nearby_pickup = null


func _try_interact() -> void:
	print(
		"Currently carrying: ",
		carried_item_type if is_carrying else "nothing"
	)

	var target := nearby_interactable
	if target != null and is_instance_valid(target):
		var area := target.get_node_or_null("InteractArea") as Area2D
		if area and not _is_player_overlapping_area(area):
			print("Active interactable not in range, searching: ", target.name)
			target = null
	elif target != null:
		target = null

	if target == null:
		target = _find_interactable_in_range()

	if target == null:
		print("No nearby interactable")
		return

	print("Interacting with: ", target.name)
	if target.has_method("interact"):
		target.interact(self)
	else:
		print("Active interactable has no interact() method: ", target.name)
