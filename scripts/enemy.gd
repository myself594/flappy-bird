extends CharacterBody2D

signal died

# 移动参数
@export var move_speed: float = 150.0
@export var chase_range: float = 500.0
@export var attack_range: float = 50.0

# 战斗参数
@export var max_health: int = 30
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.0

# 状态
var current_health: int
var is_dead: bool = false
var can_attack: bool = true
var target: Node2D = null

# 节点引用
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

	if target == null or not is_instance_valid(target):
		find_target()
		return

	var distance_to_target = global_position.distance_to(target.global_position)

	# 如果在追踪范围内
	if distance_to_target <= chase_range:
		# 面向目标
		look_at(target.global_position)

		# 如果在攻击范围内
		if distance_to_target <= attack_range:
			velocity = Vector2.ZERO
			if can_attack:
				perform_attack()
		else:
			# 追踪目标
			var direction = (target.global_position - global_position).normalized()
			velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func find_target() -> void:
	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func perform_attack() -> void:
	can_attack = false

	# 攻击动画提示（变大再变小）
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

	# 延迟后造成伤害
	await get_tree().create_timer(0.15).timeout

	if is_dead:
		return

	# 检查目标是否仍在攻击范围内
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range + 20:  # 给一点容错
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

	# 受击闪烁
	flash_hit()

	# 击退效果
	if target and is_instance_valid(target):
		var knockback_dir = (global_position - target.global_position).normalized()
		global_position += knockback_dir * 20

	if current_health <= 0:
		die()

func flash_hit() -> void:
	sprite.modulate = Color.WHITE
	hit_flash_timer.start(0.1)

func _on_hit_flash_timer_timeout() -> void:
	if not is_dead:
		sprite.modulate = Color(0.9, 0.2, 0.2, 1)  # 恢复红色

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	# 死亡动画
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.2)

	await tween.finished

	died.emit()
	queue_free()
