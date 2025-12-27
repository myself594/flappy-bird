extends Control

signal joystick_input(direction: Vector2)

@export var max_distance: float = 60.0
@export var deadzone: float = 0.2

var is_pressed: bool = false
var touch_index: int = -1
var center_pos: Vector2 = Vector2.ZERO
var current_output: Vector2 = Vector2.ZERO

@onready var base: ColorRect = $Base
@onready var knob: ColorRect = $Base/Knob

func _ready() -> void:
	center_pos = base.size / 2

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if is_point_inside(event.position) and not is_pressed:
			is_pressed = true
			touch_index = event.index
			update_knob(event.position)
	else:
		if event.index == touch_index:
			reset_knob()

func handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_index and is_pressed:
		update_knob(event.position)

func is_point_inside(point: Vector2) -> bool:
	var local_point = point - global_position
	return Rect2(Vector2.ZERO, size).has_point(local_point)

func update_knob(touch_pos: Vector2) -> void:
	var local_pos = touch_pos - base.global_position - center_pos
	var distance = local_pos.length()

	if distance > max_distance:
		local_pos = local_pos.normalized() * max_distance

	knob.position = local_pos + center_pos - knob.size / 2

	# Calculate output
	var output = local_pos / max_distance
	if output.length() < deadzone:
		output = Vector2.ZERO

	current_output = output
	joystick_input.emit(output)

func reset_knob() -> void:
	is_pressed = false
	touch_index = -1
	knob.position = center_pos - knob.size / 2
	current_output = Vector2.ZERO
	joystick_input.emit(Vector2.ZERO)

func get_output() -> Vector2:
	return current_output
