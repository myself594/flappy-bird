extends CharacterBody2D

signal died
signal health_changed(current_health, max_health)

# 移动参数
@export var move_speed: float = 300.0
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

# 战斗参数
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_range: float = 80.0
@export var attack_angle: float = 90.0  # 攻击扇形角度
@export var attack_cooldown: float = 0.3

# 状态
var current_health: int
var is_dashing: bool = false
var can_dash: bool = true
var can_attack: bool = true
var is_dead: bool = false
var dash_direction: Vector2 = Vector2.ZERO

# 节点引用
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
		# 获取输入方向
		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()

		velocity = input_dir * move_speed

		# 面向鼠标方向
		look_at(get_global_mouse_position())

	move_and_slide()

	# 处理输入
	handle_input()

func handle_input() -> void:
	# 冲刺
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	# 攻击
	if Input.is_action_just_pressed("attack") and can_attack and not is_dashing:
		perform_attack()

func start_dash() -> void:
	# 获取冲刺方向（移动方向或面向方向）
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = Vector2.RIGHT.rotated(rotation)

	is_dashing = true
	can_dash = false

	# 冲刺期间无敌
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

	# 显示攻击范围（视觉反馈）
	attack_area.monitoring = true

	# 检测攻击范围内的敌人
	var enemies_in_range = attack_area.get_overlapping_bodies()
	for enemy in enemies_in_range:
		if enemy.is_in_group("enemies"):
			# 检查是否在攻击扇形范围内
			var to_enemy = (enemy.global_position - global_position).normalized()
			var facing = Vector2.RIGHT.rotated(rotation)
			var angle_to_enemy = rad_to_deg(facing.angle_to(to_enemy))

			if abs(angle_to_enemy) <= attack_angle / 2:
				enemy.take_damage(attack_damage)

	# 短暂显示攻击效果后关闭
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

	# 受伤后短暂无敌
	set_invincible(true)
	invincibility_timer.start(0.5)

	# 受伤闪烁效果
	flash_damage()

	if current_health <= 0:
		die()

func _on_invincibility_timer_timeout() -> void:
	set_invincible(false)
	sprite.modulate = Color.WHITE

func set_invincible(value: bool) -> void:
	# 冲刺时也设置无敌，通过改变碰撞层实现
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
