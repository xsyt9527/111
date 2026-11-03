# -*- coding: utf-8 -*-
"""海草 / 珊瑚 4 帧摆动动画：纯黑底单图 -> 透明横条 + 循环 SpriteFrames。

用法（在工程根目录）：
    python -I tools/chuli_hai_cao_shan_hu.py              # 安全模式：目标已存在则报错
    python -I tools/chuli_hai_cao_shan_hu.py --chongxie   # 重跑：允许覆盖本脚本产物

与鱼类横条的区别：
- 鱼用「alpha 质心」对齐，游动时整条鱼在格子里居中；
- 植物必须「根部锚定」：四帧都按底部 8% 像素带的 x 质心当作根，底边对齐、根左右不动，
  上半部分自行摆动。若照鱼那样按整体质心对齐，整株会每帧左右平移，像在漂而不是在摆。
- 四帧共用同一缩放比例，避免播放时忽大忽小；动画循环（loop=true）。

产物：
    assets/sucai/shenhai_zhuangshi/hai_cao_4zhen.png
    assets/sucai/shenhai_zhuangshi/shan_hu_4zhen.png
    data/donghua/hai_cao_4zhen.tres
    data/donghua/shan_hu_4zhen.tres
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import chuli_sucai as cs  # noqa: E402  # 复用去背/缩放/统计的同一套算法

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

GEN = Path(__file__).resolve().parents[1]
SRC = GEN / "美术资源" / "深海抓鱼游戏_海草与珊瑚_连贯重制4帧动画_8张纯黑底单图包"
OUT_PNG = GEN / "assets" / "sucai" / "shenhai_zhuangshi"
OUT_TRES = GEN / "data" / "donghua"

OUT_H = 192       # 与旧植物显示比例配合：海草 0.5 倍 ≈ 96px 高，和旧素材观感一致
PAD = 8           # 帧四周留透明边，LANCZOS 缩放时不碰格边
BASE_BAND = 0.08  # 底部 8% 像素带用于找根：海草/珊瑚的根都聚在底边
SPEED = 5.0       # 4 帧 5fps = 0.8 秒一轮，比鱼慢，像水草随流摆动
ANIM = "bai"      # 动画名：摆（海草摆动 / 珊瑚摇曳）

SETS = [
    ("01_发光海草_连贯4帧", "hai_cao"),
    ("02_发光珊瑚_连贯4帧", "shan_hu"),
]


def root_anchor(rgba: np.ndarray) -> tuple[float, int, tuple[int, int, int, int]]:
    """返回 (根部 x, 底边 y, alpha 包围盒)。根 = 底部像素带的 alpha 加权质心。"""
    st = cs.alpha_stats(rgba)
    if st is None:
        raise ValueError("去背后没有内容")
    x0, y0, x1, y1 = st[:4]
    alpha = rgba[..., 3].astype(np.float64)
    band = max(4, int((y1 - y0 + 1) * BASE_BAND))
    sub = alpha[y1 - band + 1:y1 + 1]
    ys, xs = np.where(sub > cs.ALPHA_BBOX)
    if len(xs) == 0:
        raise ValueError("底部像素带没有内容，找不到根")
    weights = sub[ys, xs]
    base_x = float((xs * weights).sum() / max(weights.sum(), 1.0))
    return base_x, y1, (x0, y0, x1, y1)


def build_plant_strip(frames: list[np.ndarray]) -> tuple[np.ndarray, list[dict]]:
    """四帧按根部锚定、底边对齐，拼成等宽横条。"""
    anchors = []
    max_left = max_right = 0
    max_h = 1
    for idx, rgba in enumerate(frames):
        base_x, bottom, (x0, y0, x1, y1) = root_anchor(rgba)
        left = max(0, math.ceil(base_x - x0))
        right = max(0, math.ceil(x1 - base_x))
        max_left = max(max_left, left)
        max_right = max(max_right, right)
        max_h = max(max_h, y1 - y0 + 1)
        anchors.append({
            "idx": idx, "base_x": base_x, "bottom": bottom,
            "bbox": (x0, y0, x1, y1), "left": left, "right": right,
        })

    cell_w = max_left + max_right + 2 * PAD
    cell_h = max_h + 2 * PAD
    frame_w = max(1, round(cell_w * OUT_H / cell_h))

    strip = np.zeros((OUT_H, frame_w * 4, 4), dtype=np.uint8)
    for i, rgba in enumerate(frames):
        it = anchors[i]
        # 让根部落在同一目标点：x = PAD + max_left，y = OUT_H-1-PAD
        sx = math.floor(it["base_x"] - max_left - PAD)
        sy = it["bottom"] + 1 + PAD - cell_h
        cell = cs._crop_pad(rgba, sx, sy, cell_w, cell_h)
        cell = cs.resize_rgba(cell, (frame_w, OUT_H))
        strip[:, i * frame_w:(i + 1) * frame_w] = cell
        it["cell_w"], it["cell_h"] = cell_w, cell_h
        it["frame_w"] = frame_w
    return strip, anchors


def write_loop_tres(path: Path, png_rel: str, frame_w: int, frame_h: int,
                    anim: str, speed: float) -> None:
    """写 4 帧循环 SpriteFrames（loop=true）。"""
    lines = [
        '[gd_resource type="SpriteFrames" load_steps=6 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{png_rel}" id="1_tiao"]',
        "",
    ]
    for i in range(4):
        lines += [
            f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]',
            'atlas = ExtResource("1_tiao")',
            f"region = Rect2({i * frame_w}, 0, {frame_w}, {frame_h})",
            "",
        ]
    frames = []
    for i in range(4):
        frames.append('"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")' % i)
    lines += [
        "[resource]",
        "animations = [{",
        '"frames": [{',
        "}, {".join(frames),
        "}],",
        '"loop": true,',
        f'"name": &"{anim}",',
        f'"speed": {speed}',
        "}]",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> None:
    for folder, name in SETS:
        src_dir = SRC / folder
        png = OUT_PNG / f"{name}_4zhen.png"
        tres = OUT_TRES / f"{name}_4zhen.tres"
        for out in (png, tres):
            if out.exists() and "--chongxie" not in sys.argv[1:]:
                raise FileExistsError(f"目标已存在，拒绝覆盖：{out}（确需重跑请加 --chongxie）")
        files = sorted(src_dir.glob("*.png"))
        if len(files) != 4:
            raise FileNotFoundError(f"{src_dir} 应有 4 张 png，实际 {len(files)} 张")
        frames = []
        for f in files:
            rgba = cs.qubei(np.asarray(Image.open(f).convert("RGB")))
            cs.note_frame_edges(f"{name} {f.name}", rgba)
            frames.append(rgba)
        strip, anchors = build_plant_strip(frames)
        cs.save_png(strip, png)
        fw = strip.shape[1] // 4
        write_loop_tres(tres, f"res://assets/sucai/shenhai_zhuangshi/{png.name}",
                        fw, OUT_H, ANIM, SPEED)
        print(f"{name}: {strip.shape[1]}×{strip.shape[0]}（单帧 {fw}×{OUT_H}），"
              f"4 帧 {SPEED}fps 循环")
        for it in anchors:
            print(f"  第{it['idx'] + 1}帧 根 x={it['base_x']:.1f} 底={it['bottom']} "
                  f"包围盒 {it['bbox'][2] - it['bbox'][0] + 1}×{it['bbox'][3] - it['bbox'][1] + 1}")
    if cs.ANOMALIES:
        print("\n源图贴边记录：")
        for a in cs.ANOMALIES:
            print("  " + a)


if __name__ == "__main__":
    main()
