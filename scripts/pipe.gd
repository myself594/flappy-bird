extends Node2D

signal score_triggered

# 移动速度
@export var speed: float = 200.0

# 管道间隙大小
@export var gap_size: float = 200.0

# 是否正在移动
var is_moving: bool = true

# 是否已经计分
var score_counted: bool = false

# 节点引用
@onready var top_pipe: StaticBody2D = $TopPipe
@onready var bottom_pipe: StaticBody2D = $BottomPipe
@onready var top_rect: ColorRect = $TopPipe/ColorRect
@onready var bottom_rect: ColorRect = $BottomPipe/ColorRect
@onready var top_cap: ColorRect = $TopPipe/Cap
@onready var bottom_cap: ColorRect = $BottomPipe/Cap
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

	# 上管道：从屏幕顶部到间隙上沿
	var top_height = gap_center_y - half_gap
	top_pipe.position = Vector2(0, 0)
	top_rect.offset_left = -40
	top_rect.offset_top = 0
	top_rect.offset_right = 40
	top_rect.offset_bottom = top_height
	top_cap.offset_left = -45
	top_cap.offset_top = top_height - 30
	top_cap.offset_right = 45
	top_cap.offset_bottom = top_height
	top_collision.position = Vector2(0, top_height / 2.0)
	top_collision.shape.size = Vector2(80, top_height)

	# 下管道：从间隙下沿到屏幕底部
	var bottom_y = gap_center_y + half_gap
	var bottom_height = 720 - bottom_y
	bottom_pipe.position = Vector2(0, bottom_y)
	bottom_rect.offset_left = -40
	bottom_rect.offset_top = 0
	bottom_rect.offset_right = 40
	bottom_rect.offset_bottom = bottom_height
	bottom_cap.offset_left = -45
	bottom_cap.offset_top = -30
	bottom_cap.offset_right = 45
	bottom_cap.offset_bottom = 0
	bottom_collision.position = Vector2(0, bottom_height / 2.0)
	bottom_collision.shape.size = Vector2(80, bottom_height)

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
