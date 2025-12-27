extends CharacterBody2D

signal died
signal health_changed(current_health, max_health)

# Movement parameters
@export var move_speed: float = 300.0
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# Combat parameters
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_range: float = 80.0
@export var attack_angle: float = 90.0
@export var attack_cooldown: float = 0.3

# State
var current_health: int
var is_dashing: bool = false
var can_dash: bool = true
var can_attack: bool = true
var is_dead: bool = false
var dash_direction: Vector2 = Vector2.ZERO

# Touch input
var touch_move_direction: Vector2 = Vector2.ZERO
var touch_attack_pressed: bool = false
var touch_dash_pressed: bool = false
var last_move_direction: Vector2 = Vector2.RIGHT

# Node references
@onready var sprite: Polygon2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	attack_area.monitoring = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		# Get input direction (keyboard + touch)
		var input_dir = get_movement_input()

		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()

		velocity = input_dir * move_speed

		# Update facing direction
		if input_dir.length() > 0.1:
			last_move_direction = input_dir.normalized()
			rotation = input_dir.angle()

	move_and_slide()
	handle_input()

func get_movement_input() -> Vector2:
	# Keyboard input
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	# Add touch joystick input
	if touch_move_direction.length() > 0.1:
		input_dir = touch_move_direction

	return input_dir

func handle_input() -> void:
	# Dash (keyboard or touch)
	var dash_input = Input.is_action_just_pressed("dash") or touch_dash_pressed
	if dash_input and can_dash and not is_dashing:
		start_dash()
		touch_dash_pressed = false

	# Attack (keyboard or touch)
	var attack_input = Input.is_action_just_pressed("attack") or touch_attack_pressed
	if attack_input and can_attack and not is_dashing:
		perform_attack()
		touch_attack_pressed = false

# Touch input setters (called from UI)
func set_touch_move(direction: Vector2) -> void:
	touch_move_direction = direction

func trigger_touch_attack() -> void:
	touch_attack_pressed = true

func trigger_touch_dash() -> void:
	touch_dash_pressed = true

func start_dash() -> void:
	var input_dir = get_movement_input()

	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = last_move_direction

	is_dashing = true
	can_dash = false
	set_invincible(true)
	dash_timer.start(dash_duration)

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	set_invincible(false)
	dash_cooldown_timer.start(dash_cooldown)

func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func perform_attack() -> void:
	can_attack = false
	attack_area.monitoring = true

	var enemies_in_range = attack_area.get_overlapping_bodies()
	for enemy in enemies_in_range:
		if enemy.is_in_group("enemies"):
			var to_enemy = (enemy.global_position - global_position).normalized()
			var facing = Vector2.RIGHT.rotated(rotation)
			var angle_to_enemy = rad_to_deg(facing.angle_to(to_enemy))

			if abs(angle_to_enemy) <= attack_angle / 2:
				enemy.take_damage(attack_damage)

	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false
	attack_cooldown_timer.start(attack_cooldown)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func take_damage(amount: int) -> void:
	if is_dead or invincibility_timer.time_left > 0:
		return

	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)

	set_invincible(true)
	invincibility_timer.start(0.5)
	flash_damage()

	if current_health <= 0:
		die()

func _on_invincibility_timer_timeout() -> void:
	set_invincible(false)
	sprite.modulate = Color.WHITE

func set_invincible(value: bool) -> void:
	if value:
		sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		sprite.modulate = Color.WHITE

func flash_damage() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if invincibility_timer.time_left > 0:
		sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		sprite.modulate = Color.WHITE

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color.DARK_RED
	died.emit()

func reset() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
	sprite.modulate = Color.WHITE
	can_dash = true
	can_attack = true
	is_dashing = false
	touch_move_direction = Vector2.ZERO
	last_move_direction = Vector2.RIGHT
