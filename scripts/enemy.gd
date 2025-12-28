extends CharacterBody2D

signal died

# Movement parameters
@export var move_speed: float = 120.0
@export var chase_range: float = 400.0
@export var attack_range: float = 60.0
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 600.0
@export var jump_force: float = -350.0

# Combat parameters
@export var max_health: int = 30
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.2

# State
var current_health: int
var is_dead: bool = false
var can_attack: bool = true
var target: Node2D = null
var facing_right: bool = true

# AI state
var jump_cooldown: float = 0.0

# Node references
@onready var sprite: Polygon2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

	# Jump cooldown
	if jump_cooldown > 0:
		jump_cooldown -= delta

	if target == null or not is_instance_valid(target):
		find_target()
		velocity.x = 0
		move_and_slide()
		return

	var distance_to_target = global_position.distance_to(target.global_position)
	var horizontal_distance = abs(target.global_position.x - global_position.x)

	# If in chase range
	if distance_to_target <= chase_range:
		# Face toward target
		if target.global_position.x > global_position.x:
			facing_right = true
			sprite.scale.x = 1
		else:
			facing_right = false
			sprite.scale.x = -1

		# If in attack range
		if horizontal_distance <= attack_range:
			velocity.x = 0
			if can_attack:
				perform_attack()
		else:
			# Chase target horizontally
			var direction = sign(target.global_position.x - global_position.x)
			velocity.x = direction * move_speed

			# Jump if target is above and we're on ground
			if target.global_position.y < global_position.y - 50 and is_on_floor() and jump_cooldown <= 0:
				velocity.y = jump_force
				jump_cooldown = 1.5
	else:
		velocity.x = 0

	move_and_slide()

func find_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func perform_attack() -> void:
	can_attack = false

	# Attack animation (scale up then down)
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3 * sprite.scale.x, 1.3), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0 * sprite.scale.x, 1.0), 0.1)

	# Delay before damage
	await get_tree().create_timer(0.15).timeout

	if is_dead:
		return

	# Check if target is still in attack range
	if target and is_instance_valid(target):
		var h_distance = abs(global_position.x - target.global_position.x)
		var v_distance = abs(global_position.y - target.global_position.y)
		if h_distance <= attack_range + 20 and v_distance <= 60:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)

	attack_cooldown_timer.start(attack_cooldown)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	current_health = max(0, current_health)

	# Hit flash
	flash_hit()

	# Knockback
	if target and is_instance_valid(target):
		var knockback_dir = sign(global_position.x - target.global_position.x)
		velocity.x = knockback_dir * 150
		velocity.y = -100

	if current_health <= 0:
		die()

func flash_hit() -> void:
	sprite.modulate = Color.WHITE
	hit_flash_timer.start(0.1)

func _on_hit_flash_timer_timeout() -> void:
	if not is_dead:
		sprite.modulate = Color(0.9, 0.2, 0.2, 1)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	# Death animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.2)

	await tween.finished

	died.emit()
	queue_free()
