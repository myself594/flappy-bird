extends CharacterBody2D

signal died
signal health_changed(current_health, max_health)

# Movement parameters
@export var move_speed: float = 250.0
@export var jump_force: float = -420.0
@export var gravity: float = 1100.0
@export var max_fall_speed: float = 600.0

# Double jump
@export var max_jumps: int = 2
var jumps_remaining: int = 2

# Dash parameters
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# Combat parameters
@export var max_health: int = 100
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.3
@export var pogo_force: float = -350.0  # Bounce force when down-attacking enemy

# State
var current_health: int
var is_dashing: bool = false
var can_dash: bool = true
var can_attack: bool = true
var is_dead: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var facing_right: bool = true

# Attack direction
enum AttackDir { LEFT, RIGHT, UP, DOWN }
var current_attack_dir: AttackDir = AttackDir.RIGHT

# Jump state
var coyote_time: float = 0.1
var coyote_timer: float = 0.0
var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0

# Touch input
var touch_move_direction: Vector2 = Vector2.ZERO
var touch_attack_pressed: bool = false
var touch_dash_pressed: bool = false
var touch_jump_pressed: bool = false

# Node references
@onready var sprite: Polygon2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/AttackShape
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

	# Apply gravity
	if not is_dashing:
		if not is_on_floor():
			velocity.y += gravity * delta
			velocity.y = min(velocity.y, max_fall_speed)
			coyote_timer -= delta
		else:
			coyote_timer = coyote_time
			jumps_remaining = max_jumps  # Reset jumps when on ground

	# Handle jump buffer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		# Horizontal movement
		var input_dir = get_horizontal_input()
		velocity.x = input_dir * move_speed

		# Update facing direction
		if input_dir > 0:
			facing_right = true
			sprite.scale.x = 1
		elif input_dir < 0:
			facing_right = false
			sprite.scale.x = -1

	move_and_slide()
	handle_input()
	update_attack_direction()

func get_horizontal_input() -> float:
	var input_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	if abs(touch_move_direction.x) > 0.1:
		input_dir = touch_move_direction.x

	return input_dir

func get_vertical_input() -> float:
	var input_dir = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if abs(touch_move_direction.y) > 0.1:
		input_dir = touch_move_direction.y

	return input_dir

func update_attack_direction() -> void:
	var h_input = get_horizontal_input()
	var v_input = get_vertical_input()

	# Priority: Up/Down > Left/Right
	if v_input < -0.5:
		current_attack_dir = AttackDir.UP
		attack_area.position = Vector2(0, -50)
		attack_area.rotation = 0
	elif v_input > 0.5 and not is_on_floor():
		current_attack_dir = AttackDir.DOWN
		attack_area.position = Vector2(0, 50)
		attack_area.rotation = 0
	elif facing_right:
		current_attack_dir = AttackDir.RIGHT
		attack_area.position = Vector2(50, 0)
		attack_area.rotation = 0
	else:
		current_attack_dir = AttackDir.LEFT
		attack_area.position = Vector2(-50, 0)
		attack_area.rotation = 0

func handle_input() -> void:
	# Jump (keyboard or touch)
	var jump_input = Input.is_action_just_pressed("jump") or touch_jump_pressed
	if jump_input:
		jump_buffer_timer = jump_buffer_time
		touch_jump_pressed = false

	# Execute jump - ground jump with coyote time
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		perform_jump()
		jump_buffer_timer = 0
		coyote_timer = 0
	# Double jump in air
	elif jump_buffer_timer > 0 and jumps_remaining > 0 and not is_on_floor():
		perform_jump()
		jump_buffer_timer = 0

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

func perform_jump() -> void:
	velocity.y = jump_force
	jumps_remaining -= 1

# Touch input setters
func set_touch_move(direction: Vector2) -> void:
	touch_move_direction = direction

func trigger_touch_attack() -> void:
	touch_attack_pressed = true

func trigger_touch_dash() -> void:
	touch_dash_pressed = true

func trigger_touch_jump() -> void:
	touch_jump_pressed = true

func start_dash() -> void:
	var input_dir = get_horizontal_input()

	if input_dir != 0:
		dash_direction = Vector2(input_dir, 0).normalized()
	else:
		dash_direction = Vector2(1 if facing_right else -1, 0)

	is_dashing = true
	can_dash = false
	set_invincible(true)
	velocity.y = 0
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

	var hit_enemy = false
	var enemies_in_range = attack_area.get_overlapping_bodies()
	for enemy in enemies_in_range:
		if enemy.is_in_group("enemies"):
			enemy.take_damage(attack_damage)
			hit_enemy = true

	# Pogo bounce - if down attacking and hit enemy
	if current_attack_dir == AttackDir.DOWN and hit_enemy:
		velocity.y = pogo_force
		jumps_remaining = max_jumps  # Reset double jump after pogo

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

	# Knockback
	velocity.y = -200
	velocity.x = 200 if not facing_right else -200

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
	facing_right = true
	velocity = Vector2.ZERO
	jumps_remaining = max_jumps
