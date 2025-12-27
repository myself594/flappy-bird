extends Control

signal button_pressed
signal button_released

@export var button_action: String = ""

var is_pressed: bool = false
var touch_index: int = -1

@onready var background: ColorRect = $Background
@onready var label: Label = $Background/Label

var normal_color: Color = Color(0.3, 0.3, 0.3, 0.7)
var pressed_color: Color = Color(0.5, 0.5, 0.5, 0.9)

func _ready() -> void:
	background.color = normal_color

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch(event)

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if is_point_inside(event.position) and not is_pressed:
			is_pressed = true
			touch_index = event.index
			background.color = pressed_color
			button_pressed.emit()
	else:
		if event.index == touch_index:
			is_pressed = false
			touch_index = -1
			background.color = normal_color
			button_released.emit()

func is_point_inside(point: Vector2) -> bool:
	var local_point = point - global_position
	return Rect2(Vector2.ZERO, size).has_point(local_point)

func is_button_pressed() -> bool:
	return is_pressed

func set_label_text(text: String) -> void:
	label.text = text
