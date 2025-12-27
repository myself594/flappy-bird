extends CharacterBody2D

signal died
signal scored

# 物理参数
@export var gravity: float = 1200.0
@export var flap_strength: float = -400.0
@export var max_fall_speed: float = 600.0

# 状态
var is_alive: bool = true
var can_flap: bool = false

# 节点引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var flap_sound: AudioStreamPlayer = $FlapSound

func _ready() -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if not can_flap:
		return

	# 应用重力
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)

	# 检测输入
	if Input.is_action_just_pressed("flap"):
		flap()

	# 移动
	move_and_slide()

	# 检测与管道/地面的碰撞
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider is StaticBody2D:
			die()
			return

	# 旋转效果：根据垂直速度旋转小鸟
	var target_rotation = clamp(velocity.y / 500.0, -0.5, 1.2)
	rotation = lerp(rotation, target_rotation, 10.0 * delta)

	# 检测是否飞出屏幕
	if position.y < -50 or position.y > 770:
		die()

func start_game() -> void:
	can_flap = true
	is_alive = true
	velocity = Vector2.ZERO
	animated_sprite.play("fly")

func flap() -> void:
	if is_alive and can_flap:
		velocity.y = flap_strength
		# 播放扇翅膀音效
		if flap_sound:
			flap_sound.play()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	can_flap = false
	animated_sprite.stop()
	died.emit()

func reset() -> void:
	is_alive = true
	can_flap = false
	velocity = Vector2.ZERO
	rotation = 0
	animated_sprite.play("idle")

func add_score() -> void:
	scored.emit()
