extends CharacterBody2D

# 移动速度
@export var speed: float = 300.0
@export var sprint_speed: float = 500.0

func _physics_process(delta: float) -> void:
	# 获取输入方向
	var direction := Vector2.ZERO
	
	# 检测按键输入
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	
	# 标准化方向向量（斜向移动速度一致）
	if direction.length() > 0:
		direction = direction.normalized()
	
	# 检测是否按住 Shift 加速
	var current_speed := speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = sprint_speed
	
	# 设置速度
	velocity = direction * current_speed
	
	# 移动并处理碰撞
	move_and_slide()
	
	# 限制在屏幕范围内
	var viewport_size := get_viewport_rect().size
	position.x = clamp(position.x, 25, viewport_size.x - 25)
	position.y = clamp(position.y, 25, viewport_size.y - 25)
