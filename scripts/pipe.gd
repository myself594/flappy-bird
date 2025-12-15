extends Node2D

signal score_triggered

# 移动速度
@export var speed: float = 200.0

# 管道间隙大小
@export var gap_size: float = 200.0

# 管道图片尺寸（缩放后）
const PIPE_WIDTH = 100
const PIPE_HEIGHT = 390  # 130 * 3 (scale = 3)

# 是否正在移动
var is_moving: bool = true

# 是否已经计分
var score_counted: bool = false

# 节点引用
@onready var top_pipe: StaticBody2D = $TopPipe
@onready var bottom_pipe: StaticBody2D = $BottomPipe
@onready var top_sprite: Sprite2D = $TopPipe/Sprite
@onready var bottom_sprite: Sprite2D = $BottomPipe/Sprite
@onready var top_collision: CollisionShape2D = $TopPipe/CollisionShape2D
@onready var bottom_collision: CollisionShape2D = $BottomPipe/CollisionShape2D
@onready var score_area: Area2D = $ScoreArea

func _ready() -> void:
	# 连接计分区域信号
	score_area.body_entered.connect(_on_score_area_body_entered)

func _process(delta: float) -> void:
	if not is_moving:
		return

	# 向左移动
	position.x -= speed * delta

	# 超出屏幕左侧则销毁
	if position.x < -100:
		queue_free()

func setup(gap_center_y: float) -> void:
	# 设置管道位置
	# gap_center_y 是间隙中心的 Y 坐标

	var half_gap = gap_size / 2.0

	# 上管道：底部在间隙上方
	var top_bottom_y = gap_center_y - half_gap
	top_pipe.position = Vector2(0, top_bottom_y)
	# 精灵翻转180度，向上偏移使管道帽在底部
	top_sprite.position = Vector2(0, -PIPE_HEIGHT / 2.0)

	# 设置上管道碰撞体
	var top_shape = RectangleShape2D.new()
	top_shape.size = Vector2(PIPE_WIDTH, top_bottom_y)
	top_collision.shape = top_shape
	top_collision.position = Vector2(0, -top_bottom_y / 2.0)

	# 下管道：顶部在间隙下方
	var bottom_top_y = gap_center_y + half_gap
	var bottom_height = 720 - bottom_top_y
	bottom_pipe.position = Vector2(0, bottom_top_y)
	# 向下偏移使管道帽在顶部
	bottom_sprite.position = Vector2(0, PIPE_HEIGHT / 2.0)

	# 设置下管道碰撞体
	var bottom_shape = RectangleShape2D.new()
	bottom_shape.size = Vector2(PIPE_WIDTH, bottom_height)
	bottom_collision.shape = bottom_shape
	bottom_collision.position = Vector2(0, bottom_height / 2.0)

	# 计分区域放在间隙中间
	score_area.position = Vector2(0, gap_center_y)

func stop() -> void:
	is_moving = false

func _on_score_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not score_counted:
		score_counted = true
		score_triggered.emit()
		if body.has_method("add_score"):
			body.add_score()
