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
@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	velocity = Vector2.ZERO

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

func flap() -> void:
	if is_alive and can_flap:
		velocity.y = flap_strength

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	can_flap = false
	died.emit()

func add_score() -> void:
	scored.emit()
