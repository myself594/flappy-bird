# Flappy Bird 图片处理工具

用于处理游戏美术资源的 Python 工具，支持**去除背景**和**调整尺寸**。

## 安装依赖

```bash
cd tools
pip install -r requirements.txt
```

或单独安装：

```bash
pip install Pillow rembg
```

## 快速开始

```bash
# 基本用法：去除背景 + 调整为 64x64
python image_processor.py input.png -s 64

# 指定输出文件
python image_processor.py input.png -o output.png -s 64
```

## 命令参数

| 参数 | 说明 | 示例 |
|-----|------|------|
| `input` | 输入图片路径（必填） | `bird.png` |
| `-o, --output` | 输出图片路径 | `-o bird_out.png` |
| `-s, --size` | 目标尺寸 | `-s 64` 或 `-s 80x400` |
| `--no-remove-bg` | 不去除背景 | `--no-remove-bg` |
| `--simple` | 使用简单白色背景去除 | `--simple` |
| `--threshold` | 白色背景阈值 (0-255) | `--threshold 230` |

## 使用示例

### 处理小鸟素材

```bash
# 使用 AI 智能背景去除（效果最好，但较慢）
python image_processor.py bird_raw.png -o ../assets/images/bird.png -s 64

# 使用简单白色背景去除（速度快，适合纯白背景）
python image_processor.py bird_raw.png -o ../assets/images/bird.png -s 64 --simple
```

### 处理管道素材

```bash
# 管道主体（宽 80，高 400）
python image_processor.py pipe_raw.png -o ../assets/images/pipe.png -s 80x400

# 管道帽（宽 90，高 30）
python image_processor.py pipe_cap_raw.png -o ../assets/images/pipe_cap.png -s 90x30
```

### 处理背景图

```bash
# 背景图不需要去除背景
python image_processor.py bg_raw.png -o ../assets/images/background.png -s 480x720 --no-remove-bg
```

### 处理地面素材

```bash
python image_processor.py ground_raw.png -o ../assets/images/ground.png -s 480x60
```

## 两种背景去除模式

### 1. AI 智能去除（默认）

使用 `rembg` 库，基于 AI 模型识别前景和背景。

**优点**：
- 效果好，能处理复杂背景
- 边缘平滑自然

**缺点**：
- 首次运行需要下载模型（约 170MB）
- 处理速度较慢

```bash
python image_processor.py input.png -s 64
```

### 2. 简单白色背景去除

将接近白色的像素变为透明。

**优点**：
- 速度快
- 不需要额外下载

**缺点**：
- 只适合纯白或接近白色的背景
- 如果图片本身有白色部分可能被误删

```bash
# 使用简单模式
python image_processor.py input.png -s 64 --simple

# 调整阈值（越高越严格，默认 240）
python image_processor.py input.png -s 64 --simple --threshold 250
```

## Flappy Bird 素材规格参考

| 素材 | 建议尺寸 | 说明 |
|-----|---------|------|
| 小鸟 | 64x64 | 正方形，保持比例 |
| 管道主体 | 80x400 | 可拉伸的管道身体 |
| 管道帽 | 90x30 | 管道顶部装饰 |
| 背景 | 480x720 | 游戏背景图 |
| 地面 | 480x60 | 可平铺的地面 |

## 批量处理

如果有多个文件需要处理，可以使用 shell 循环：

```bash
# 批量处理所有 PNG 文件
for f in raw/*.png; do
    python image_processor.py "$f" -o "processed/$(basename $f)" -s 64 --simple
done
```

## 常见问题

### Q: rembg 下载模型很慢怎么办？

使用 `--simple` 参数跳过 AI 模型，改用简单白色背景去除。

### Q: 图片边缘有白边怎么办？

尝试降低阈值：

```bash
python image_processor.py input.png -s 64 --simple --threshold 220
```

### Q: 只想调整尺寸，不去背景？

使用 `--no-remove-bg` 参数：

```bash
python image_processor.py input.png -s 64 --no-remove-bg
```

### Q: 输出的图片模糊怎么办？

工具使用高质量的 LANCZOS 重采样算法。如果觉得模糊：
1. 尝试使用更大的尺寸（如 128x128）
2. 确保原图分辨率足够高

## 输出格式

所有输出文件都是 **PNG 格式**，支持透明背景（RGBA 模式）。
