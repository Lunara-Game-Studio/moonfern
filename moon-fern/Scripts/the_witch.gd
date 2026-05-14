extends CharacterBody2D


const SPEED = 600.0
const JUMP_VELOCITY = -600.0
const MAX_ITEMS = 1 # we don't want the player to be able to carry more

var full_inventory = false
var inventory = []

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	
	
	
# Adding items to inventory
# Max one item in inventory
func add_item(item_name):
	if inventory.size() >= MAX_ITEMS:
		return
	inventory.append(item_name)
	full_inventory = true
	print(inventory) # for debugging
