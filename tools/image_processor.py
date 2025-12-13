#!/usr/bin/env python3
"""
Flappy Bird 图片处理工具
功能：去除背景 + 调整尺寸

使用方法：
    python image_processor.py 输入图片.png -o 输出图片.png -s 64
    python image_processor.py bird.png -o bird_processed.png -s 64x64
    python image_processor.py bird.png --size 48 --no-remove-bg  # 只调整尺寸
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("错误：需要安装 Pillow 库")
    print("运行：pip install Pillow")
    sys.exit(1)

try:
    from rembg import remove
    REMBG_AVAILABLE = True
except ImportError:
    REMBG_AVAILABLE = False


def remove_background(image: Image.Image) -> Image.Image:
    """去除图片背景"""
    if not REMBG_AVAILABLE:
        print("警告：rembg 未安装，跳过背景去除")
        print("安装命令：pip install rembg")
        return image

    print("正在去除背景...")
    # 确保图片是 RGBA 模式
    if image.mode != 'RGBA':
        image = image.convert('RGBA')

    result = remove(image)
    print("背景去除完成！")
    return result


def remove_white_background(image: Image.Image, threshold: int = 240) -> Image.Image:
    """
    简单的白色背景去除（不需要 rembg）
    适用于纯白色或接近白色背景的图片
    """
    print("正在去除白色背景...")

    # 转换为 RGBA
    if image.mode != 'RGBA':
        image = image.convert('RGBA')

    # 获取像素数据
    data = image.getdata()
    new_data = []

    for item in data:
        # 如果像素接近白色（R, G, B 都大于阈值）
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            # 设为透明
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    image.putdata(new_data)
    print("白色背景去除完成！")
    return image


def resize_image(image: Image.Image, size: tuple) -> Image.Image:
    """调整图片尺寸，保持比例"""
    print(f"正在调整尺寸为 {size[0]}x{size[1]}...")

    # 使用高质量重采样
    resized = image.resize(size, Image.Resampling.LANCZOS)
    print("尺寸调整完成！")
    return resized


def resize_keep_aspect(image: Image.Image, max_size: int) -> Image.Image:
    """调整图片尺寸，保持宽高比"""
    width, height = image.size

    if width > height:
        new_width = max_size
        new_height = int(height * (max_size / width))
    else:
        new_height = max_size
        new_width = int(width * (max_size / height))

    return resize_image(image, (new_width, new_height))


def parse_size(size_str: str) -> tuple:
    """解析尺寸字符串，如 '64' 或 '64x48'"""
    if 'x' in size_str.lower():
        parts = size_str.lower().split('x')
        return (int(parts[0]), int(parts[1]))
    else:
        size = int(size_str)
        return (size, size)


def process_image(
    input_path: str,
    output_path: str = None,
    size: tuple = None,
    remove_bg: bool = True,
    simple_bg_remove: bool = False,
    bg_threshold: int = 240
) -> str:
    """
    处理图片的主函数

    参数:
        input_path: 输入图片路径
        output_path: 输出图片路径（默认在原文件名后加 _processed）
        size: 目标尺寸 (width, height)
        remove_bg: 是否去除背景
        simple_bg_remove: 使用简单的白色背景去除（不需要 rembg）
        bg_threshold: 白色背景阈值（0-255，越高越严格）
    """
    input_path = Path(input_path)

    if not input_path.exists():
        raise FileNotFoundError(f"找不到文件：{input_path}")

    # 设置输出路径
    if output_path is None:
        output_path = input_path.parent / f"{input_path.stem}_processed.png"
    else:
        output_path = Path(output_path)

    print(f"输入文件：{input_path}")
    print(f"输出文件：{output_path}")
    print("-" * 40)

    # 打开图片
    image = Image.open(input_path)
    print(f"原始尺寸：{image.size[0]}x{image.size[1]}")
    print(f"原始模式：{image.mode}")

    # 去除背景
    if remove_bg:
        if simple_bg_remove:
            image = remove_white_background(image, bg_threshold)
        else:
            image = remove_background(image)

    # 调整尺寸
    if size:
        image = resize_image(image, size)

    # 确保是 RGBA 模式以保留透明度
    if image.mode != 'RGBA':
        image = image.convert('RGBA')

    # 保存
    image.save(output_path, 'PNG')
    print("-" * 40)
    print(f"处理完成！已保存到：{output_path}")

    return str(output_path)


def main():
    parser = argparse.ArgumentParser(
        description='Flappy Bird 图片处理工具 - 去除背景 & 调整尺寸',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s bird.png -s 64                    # 去背景 + 调整为 64x64
  %(prog)s bird.png -o output.png -s 48x48   # 指定输出文件和尺寸
  %(prog)s bird.png --simple                 # 使用简单白色背景去除
  %(prog)s bird.png -s 64 --no-remove-bg     # 只调整尺寸，不去背景
  %(prog)s pipe.png -s 80x300                # 管道素材处理
        """
    )

    parser.add_argument('input', help='输入图片路径')
    parser.add_argument('-o', '--output', help='输出图片路径（默认: 原文件名_processed.png）')
    parser.add_argument('-s', '--size', help='目标尺寸，如 64 或 64x48')
    parser.add_argument('--no-remove-bg', action='store_true', help='不去除背景')
    parser.add_argument('--simple', action='store_true',
                        help='使用简单的白色背景去除（不需要安装 rembg）')
    parser.add_argument('--threshold', type=int, default=240,
                        help='白色背景阈值 0-255（默认: 240，越高越严格）')

    args = parser.parse_args()

    # 解析尺寸
    size = parse_size(args.size) if args.size else None

    try:
        process_image(
            input_path=args.input,
            output_path=args.output,
            size=size,
            remove_bg=not args.no_remove_bg,
            simple_bg_remove=args.simple,
            bg_threshold=args.threshold
        )
    except Exception as e:
        print(f"错误：{e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
