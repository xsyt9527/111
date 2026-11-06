# -*- coding: utf-8 -*-
"""《深海食纪》机器船 4 帧游动动画流水线（2026-11-05 新素材）。

输入：美术资源/船4/4帧叠在一起了.jpg
      1024×765 的 2×2 宫格：左上→右下依次 FRAME 01~04，纯黑底 + 白色帧号。
输出：
  assets/sucai/ji_qi_chuan/ji_qi_chuan_4zhen.png  （4 帧横排，单帧高 272）
  data/donghua/ji_qi_chuan_4zhen.tres             （dong 动画循环播放，6 fps）

源图的帧号是画在船体下方的白色文字，不能靠去背保留——按宫格切成四块后，
统一裁掉下方文字带；四块再按「对称质心格」对齐、缩放，播放时不抖。

用法（工程根目录）：
    python -I tools/chuli_chuan_4zhen.py [--chongxie]
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from chuli_sucai import (  # noqa: E402
    ALPHA_BBOX, alpha_stats, build_strip, qubei, save_png,
)

GEN = Path(__file__).resolve().parents[1]
SRC = GEN / "美术资源" / "船4" / "4帧叠在一起了.jpg"
OUT_PNG = GEN / "assets" / "sucai" / "ji_qi_chuan" / "ji_qi_chuan_4zhen.png"
OUT_TRES = GEN / "data" / "donghua" / "ji_qi_chuan_4zhen.tres"

SRC_SIZE = (1024, 765)
OUT_H = 272
ANIM_SPEED = 6.0

# 四宫格裁切窗（x0, y0, x1, y1，右/下开区间）：
# - 横向避开 510~512 的分隔线，左格取到 509、右格从 513 起；
# - 上排取 0~339（FRAME 文字在 348~366）；
# - 下排从 384 起（分隔线在 381~383），到 719 止（文字在 732~749）。
QUADRANTS = [
    (0, 0, 510, 340),
    (513, 0, 1024, 340),
    (0, 384, 510, 720),
    (513, 384, 1024, 720),
]


def _write_tres(path: Path, frame_w: int) -> None:
    kuai = ['[gd_resource type="SpriteFrames" load_steps=6 format=3]', ""]
    kuai += ['[ext_resource type="Texture2D" path="res://assets/sucai/ji_qi_chuan/ji_qi_chuan_4zhen.png" id="1_tiao"]']
    for i in range(4):
        kuai += [
            "",
            '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]' % i,
            'atlas = ExtResource("1_tiao")',
            "region = Rect2(%d, 0, %d, %d)" % (i * frame_w, frame_w, OUT_H),
        ]
    kuai += ["", "[resource]", "animations = [{", '"frames": [']
    for i in range(4):
        kuai += ["{", '"duration": 1.0,',
                 '"texture": SubResource("AtlasTexture_%d")' % i,
                 "}" + ("," if i < 3 else "")]
    kuai += [
        "],",
        '"loop": 1,',
        '"name": &"dong",',
        '"speed": %.1f' % ANIM_SPEED,
        "}]",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(kuai), encoding="utf-8", newline="\n")


def main() -> int:
    chongxie = "--chongxie" in sys.argv
    if not SRC.exists():
        raise FileNotFoundError(SRC)
    if OUT_PNG.exists() and not chongxie:
        print("产物已存在，不覆盖：%s（重跑加 --chongxie）" % OUT_PNG)
        return 1

    rgb = np.asarray(Image.open(SRC).convert("RGB"))
    if (rgb.shape[1], rgb.shape[0]) != SRC_SIZE:
        raise RuntimeError("源图应为 %d×%d，实际 %d×%d" % (*SRC_SIZE, rgb.shape[1], rgb.shape[0]))

    frames = []
    for i, (x0, y0, x1, y1) in enumerate(QUADRANTS):
        rgba = qubei(rgb[y0:y1, x0:x1])
        st = alpha_stats(rgba)
        if st is None:
            raise RuntimeError("第 %d 帧去背后为空" % (i + 1))
        frames.append(rgba)
        print("第 %d 帧：源窗 %d×%d，内容包围盒 %d×%d"
              % (i + 1, x1 - x0, y1 - y0, st[2] - st[0] + 1, st[3] - st[1] + 1))

    strip, infos = build_strip(frames, OUT_H)
    frame_w = strip.shape[1] // 4

    # 验收：四帧非空、不贴格边、质心居中（build_strip 的对称质心格保证）
    failures = []
    for i, it in enumerate(infos):
        cell = strip[:, i * frame_w:(i + 1) * frame_w, 3]
        ys, xs = np.where(cell > ALPHA_BBOX)
        if len(xs) == 0:
            failures.append("第 %d 帧为空" % (i + 1))
            continue
        if xs.min() == 0 or xs.max() == frame_w - 1 or ys.min() == 0 or ys.max() == OUT_H - 1:
            failures.append("第 %d 帧包围盒贴格边" % (i + 1))
    if failures:
        raise SystemExit("验收失败：" + "；".join(failures))

    save_png(strip, OUT_PNG)
    _write_tres(OUT_TRES, frame_w)
    print("写出 %s（%d×%d，单帧 %d×%d）" % (OUT_PNG, strip.shape[1], strip.shape[0], frame_w, OUT_H))
    print("写出 %s" % OUT_TRES)
    print("验收通过：4 帧非空、不贴格边；动画 dong 循环 %d fps。" % ANIM_SPEED)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
