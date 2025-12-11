extends Node2D

# 游戏状态
enum GameState { READY, PLAYING, GAME_OVER }
var current_state: GameState = GameState.READY

# 分数
var score: int = 0
var best_score: int = 0

# 管道生成设置
@export var pipe_spawn_interval: float = 1.8
@export var pipe_scene_path: String = "res://scenes/pipe.tscn"

# 管道间隙的 Y 坐标范围
var gap_min_y: float = 180.0
var gap_max_y: float = 540.0

# 计时器
var spawn_timer: float = 0.0

# 节点引用
@onready var bird: CharacterBody2D = $Bird
@onready var pipes_container: Node2D = $Pipes
@onready var score_label: Label = $UI/ScoreLabel
@onready var best_label: Label = $UI/BestLabel
@onready var title_label: Label = $UI/TitleLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var ground: StaticBody2D = $Ground

# 预加载管道场景
var pipe_scene: PackedScene

func _ready() -> void:
	pipe_scene = load(pipe_scene_path)
	
	# 连接小鸟信号
	bird.died.connect(_on_bird_died)
	bird.scored.connect(_on_bird_scored)
	
	# 初始化 UI
	update_ui()
	show_ready_screen()

func _process(delta: float) -> void:
	match current_state:
		GameState.READY:
			if Input.is_action_just_pressed("flap"):
				start_game()
		
		GameState.PLAYING:
			# 生成管道
			spawn_timer += delta
			if spawn_timer >= pipe_spawn_interval:
				spawn_timer = 0.0
				spawn_pipe()
		
		GameState.GAME_OVER:
			if Input.is_action_just_pressed("flap"):
				restart_game()

func start_game() -> void:
	current_state = GameState.PLAYING
	score = 0
	spawn_timer = 0.0
	
	bird.start_game()
	
	# 隐藏开始界面
	title_label.visible = false
	hint_label.text = ""
	game_over_label.visible = false
	
	update_ui()

func spawn_pipe() -> void:
	var pipe = pipe_scene.instantiate()
	pipes_container.add_child(pipe)
	
	# 设置位置：从屏幕右侧出现
	pipe.position.x = 550
	
	# 随机间隙位置
	var gap_y = randf_range(gap_min_y, gap_max_y)
	pipe.setup(gap_y)
	
	# 连接碰撞信号
	pipe.get_node("TopPipe").body_entered.connect(_on_pipe_hit)
	pipe.get_node("BottomPipe").body_entered.connect(_on_pipe_hit)

func _on_pipe_hit(body: Node2D) -> void:
	if body.is_in_group("player"):
		bird.die()

func _on_bird_died() -> void:
	current_state = GameState.GAME_OVER
	
	# 停止所有管道
	for pipe in pipes_container.get_children():
		pipe.stop()
	
	# 更新最高分
	if score > best_score:
		best_score = score
	
	show_game_over_screen()

func _on_bird_scored() -> void:
	score += 1
	update_ui()

func show_ready_screen() -> void:
	title_label.visible = true
	title_label.text = "Flappy Bird"
	hint_label.text = "点击屏幕或按空格开始"
	game_over_label.visible = false

func show_game_over_screen() -> void:
	game_over_label.visible = true
	game_over_label.text = "游戏结束!"
	hint_label.text = "点击重新开始"
	update_ui()

func update_ui() -> void:
	score_label.text = "分数: " + str(score)
	best_label.text = "最高: " + str(best_score)

func restart_game() -> void:
	# 清除所有管道
	for pipe in pipes_container.get_children():
		pipe.queue_free()
	
	# 重置小鸟位置
	bird.position = Vector2(120, 360)
	bird.rotation = 0
	bird.velocity = Vector2.ZERO
	bird.is_alive = true
	bird.can_flap = false
	
	# 重置状态
	current_state = GameState.READY
	score = 0
	spawn_timer = 0.0
	
	show_ready_screen()
	update_ui()
