extends CanvasLayer

const NOTIFICATION_DURATION := 1.75
const FADE_DURATION := 0.35

@onready var _notification_label: Label = $NotificationLabel
@onready var _inventory_panel: PanelContainer = $InventoryPanel
@onready var _slot_label: Label = $InventoryPanel/MarginContainer/VBoxContainer/SlotLabel
@onready var _notification_timer: Timer = $NotificationTimer

var _notification_queue: Array[String] = []
var _showing_notification := false
var _fade_tween: Tween


func _ready() -> void:
	add_to_group("player_feedback_ui")
	_inventory_panel.visible = false
	_notification_label.visible = false
	update_carry_display("")
	update_inventory_display("")


func toggle_inventory_panel() -> void:
	_inventory_panel.visible = not _inventory_panel.visible


func update_inventory_display(item_type: String) -> void:
	var slot_text := "Empty" if item_type.is_empty() else item_type
	_slot_label.text = "Slot 1: %s" % slot_text


func update_carry_display(item_type: String) -> void:
	var label := get_tree().get_first_node_in_group("carry_hud_label")
	if label is Label:
		var display := "Empty" if item_type.is_empty() else item_type
		label.text = "Carrying: %s" % display


func show_notification(message: String) -> void:
	_notification_queue.append(message)
	if not _showing_notification:
		_show_next_notification()


func _show_next_notification() -> void:
	if _notification_queue.is_empty():
		_showing_notification = false
		return

	_showing_notification = true
	var message: String = _notification_queue.pop_front()
	_notification_label.text = message
	_notification_label.visible = true
	_notification_label.modulate.a = 1.0

	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = null

	_notification_timer.stop()
	_notification_timer.wait_time = NOTIFICATION_DURATION
	_notification_timer.start()


func _on_notification_timer_timeout() -> void:
	_fade_tween = create_tween()
	_fade_tween.tween_property(_notification_label, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.tween_callback(_on_notification_fade_finished)


func _on_notification_fade_finished() -> void:
	_notification_label.visible = false
	_show_next_notification()
