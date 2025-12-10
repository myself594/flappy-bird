# 我的第一个 Godot 游戏

这是一个入门级的 Godot 4 项目，帮助你理解 Godot 的基础概念。

## 如何运行

1. 打开 Godot 4.3
2. 点击「导入」按钮
3. 选择这个文件夹中的 `project.godot` 文件
4. 点击「导入并编辑」
5. 按 F5 或点击右上角的「运行」按钮

## 操作方式

- **WASD** 或 **方向键**：移动蓝色方块
- **Shift**：按住加速

## 项目结构

```
godot-first-game/
├── project.godot    # 项目配置文件
├── main.tscn        # 主场景（纯文本格式）
├── player.gd        # 玩家控制脚本
└── README.md        # 本说明文件
```

## 学习要点

### 1. 场景文件 (.tscn)
- Godot 的场景是纯文本格式
- 可以用代码生成和修改
- 包含节点树结构和属性

### 2. 脚本文件 (.gd)
- 使用 GDScript 语言（类似 Python）
- `_physics_process()` 每帧调用，处理物理逻辑
- `Input.is_action_pressed()` 检测按键输入

### 3. 节点系统
- `CharacterBody2D`：2D 角色控制器
- `ColorRect`：彩色矩形（用作临时图形）
- `Label`：文本标签

## 下一步

试着修改 `player.gd` 中的参数：
- `speed`：调整移动速度
- `sprint_speed`：调整冲刺速度
- 修改 `main.tscn` 中的 `color` 改变方块颜色

## 导出到网页

在 Godot 编辑器中：
1. 项目 → 导出
2. 添加 Web 导出预设
3. 导出项目
4. 上传到 itch.io
