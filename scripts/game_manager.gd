extends Node2D

enum GameState { READY, PLAYING, VICTORY, GAME_OVER }

# 波次配置
@export var waves: Array[int] = [3, 4, 5]  # 每波敌人数量
@export var spawn_delay: float = 0.5  # 每个敌人生成间隔
@export var wave_delay: float = 2.0  # 波次之间间隔

# 场景引用
var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

# 状态
var current_state: GameState = GameState.READY
var current_wave: int = 0
var enemies_alive: int = 0
var total_kills: int = 0

# 节点引用
@onready var player: CharacterBody2D = $Player
@onready var enemies_container: Node2D = $Enemies
@onready var arena: Node2D = $Arena
@onready var ui: CanvasLayer = $UI
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var health_label: Label = $UI/HealthLabel
@onready var wave_label: Label = $UI/WaveLabel
@onready var kills_label: Label = $UI/KillsLabel
@onready var title_label: Label = $UI/TitleLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var result_label: Label = $UI/ResultLabel

# 房间边界
var arena_bounds: Rect2 = Rect2(100, 100, 1080, 520)

func _ready() -> void:
	player.add_to_group("player")
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

	# 初始化UI
	update_ui()
	show_start_screen()

func _process(_delta: float) -> void:
	match current_state:
		GameState.READY:
			if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("dash"):
				start_game()
		GameState.GAME_OVER, GameState.VICTORY:
			if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("dash"):
				restart_game()

func show_start_screen() -> void:
	title_label.visible = true
	hint_label.visible = true
	hint_label.text = "点击开始游戏\nWASD移动 | Shift/空格冲刺 | 鼠标攻击"
	result_label.visible = false

func start_game() -> void:
	current_state = GameState.PLAYING
	current_wave = 0
	total_kills = 0
	enemies_alive = 0

	title_label.visible = false
	hint_label.visible = false
	result_label.visible = false

	# 重置玩家
	player.reset()
	player.global_position = Vector2(640, 360)  # 房间中心

	# 清理敌人
	for enemy in enemies_container.get_children():
		enemy.queue_free()

	update_ui()

	# 开始第一波
	start_next_wave()

func start_next_wave() -> void:
	if current_wave >= waves.size():
		victory()
		return

	wave_label.text = "第 %d / %d 波" % [current_wave + 1, waves.size()]

	# 生成敌人
	var enemy_count = waves[current_wave]
	spawn_wave(enemy_count)

	current_wave += 1

func spawn_wave(count: int) -> void:
	for i in range(count):
		await get_tree().create_timer(spawn_delay).timeout
		if current_state != GameState.PLAYING:
			return
		spawn_enemy()

func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()

	# 在房间边缘随机位置生成
	var spawn_pos = get_random_spawn_position()
	enemy.global_position = spawn_pos

	enemy.died.connect(_on_enemy_died)
	enemies_container.add_child(enemy)
	enemies_alive += 1

func get_random_spawn_position() -> Vector2:
	# 在房间边缘生成，远离玩家
	var side = randi() % 4
	var pos = Vector2.ZERO
	var margin = 50

	match side:
		0:  # 上边
			pos = Vector2(randf_range(arena_bounds.position.x, arena_bounds.end.x), arena_bounds.position.y + margin)
		1:  # 下边
			pos = Vector2(randf_range(arena_bounds.position.x, arena_bounds.end.x), arena_bounds.end.y - margin)
		2:  # 左边
			pos = Vector2(arena_bounds.position.x + margin, randf_range(arena_bounds.position.y, arena_bounds.end.y))
		3:  # 右边
			pos = Vector2(arena_bounds.end.x - margin, randf_range(arena_bounds.position.y, arena_bounds.end.y))

	return pos

func _on_enemy_died() -> void:
	enemies_alive -= 1
	total_kills += 1
	kills_label.text = "击杀: %d" % total_kills

	# 检查是否清完这一波
	if enemies_alive <= 0 and current_state == GameState.PLAYING:
		await get_tree().create_timer(wave_delay).timeout
		if current_state == GameState.PLAYING:
			start_next_wave()

func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]

func _on_player_died() -> void:
	game_over()

func game_over() -> void:
	current_state = GameState.GAME_OVER
	result_label.visible = true
	result_label.text = "游戏结束"
	result_label.modulate = Color(0.9, 0.2, 0.2)
	hint_label.visible = true
	hint_label.text = "点击重新开始"

func victory() -> void:
	current_state = GameState.VICTORY
	result_label.visible = true
	result_label.text = "胜利!"
	result_label.modulate = Color(0.2, 0.9, 0.3)
	hint_label.visible = true
	hint_label.text = "点击重新开始\n总击杀: %d" % total_kills

func restart_game() -> void:
	# 清理敌人
	for enemy in enemies_container.get_children():
		enemy.queue_free()

	current_state = GameState.READY
	show_start_screen()

	# 重置玩家
	player.reset()
	player.global_position = Vector2(640, 360)
	update_ui()

func update_ui() -> void:
	wave_label.text = "第 0 / %d 波" % waves.size()
	kills_label.text = "击杀: 0"
