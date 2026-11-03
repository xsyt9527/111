# -*- coding: utf-8 -*-
"""《深海食纪》新素材流水线：黑底 JPG -> 带 alpha 的 PNG + SpriteFrames .tres。

用法（在工程根目录）：
    python -I tools/chuli_sucai.py              # 安全模式：目标已存在则报错，绝不覆盖
    python -I tools/chuli_sucai.py --chongxie   # 重跑模式：允许重写本脚本自己的产物

处理约定见 docs/美术资源首装记录.md 第十章：
- 近黑背景按连通域从四边泛洪清除，边缘按亮度做软边；
- 按 alpha 包围盒裁切；
- 4 帧用「对称质心格子」统一大小，质心落在每格中心；
- 装饰气泡用「四帧最大包围盒 + 单边 8% 呼吸边」统一缩放，逐格居中（避免播放时忽大忽小）；
- 帧高 256，四帧等宽；图标 128×128。

只新增下列产物，不修改任何现有文件；目标已存在时直接报错，避免覆盖。
"""

from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# 让 Windows 控制台的定向输出也按 UTF-8 打印中文路径
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

GEN = Path(__file__).resolve().parents[1]
MEI_SHU = GEN / "美术资源"

ICON_SRC = MEI_SHU / "深海抓鱼游戏_十大被动技能图标_10张纯黑底单图包"
FX1_SRC = MEI_SHU / "深海抓鱼游戏_四大主动技能特效_16张纯黑底单图包"
FX2_SRC = MEI_SHU / "深海抓鱼游戏_狂暴撕咬等四大技能特效_16张纯黑底单图包"
ACT_SRC = MEI_SHU / "深海抓鱼游戏_五鱼专属攻击动作_20张纯黑底单图包"
QIPAO_SRC = MEI_SHU / "深海抓鱼游戏_海底气泡动画_4张纯黑底单图包" / "海底气泡_4帧"

TUBIAO_DIR = GEN / "assets" / "sucai" / "tubiao"
TEXIAO_DIR = GEN / "assets" / "sucai" / "texiao"
DONGZUO_DIR = GEN / "assets" / "sucai" / "dongzuo"
QIPAO_DIR = GEN / "assets" / "sucai" / "qipao"
DONGHUA_DIR = GEN / "data" / "donghua"

# 去背阈值：纯黑 JPG 边框噪点实测 max(R,G,B) ≤ 9，取 20 留余量；
# 软边亮度从 20 过渡到 80，只作用于紧贴背景的 2 像素带，内部深色纹理保持不透明。
BG_T = 20
BG_HI = 80
ALPHA_BBOX = 8       # 统计包围盒/质心时忽略 alpha ≤ 8 的近乎全透明像素
OUT_H = 256
ICON_SIZE = 128
SAFE_PAD = 8         # 质心格四周额外留的透明像素，防止 LANCZOS 缩放时内容贴格边
QIPAO_CELL = 256     # 装饰气泡单格边长（横条 1024×256）
QIPAO_HUXI = 0.08    # 气泡最大包围盒四周的呼吸边比例（单边 8%）

ICONS = [
    ("01_软鳞_图标.jpg", "ruan_lin"),
    ("02_灵敏尾鳍_图标.jpg", "ling_min_wei_qi"),
    ("03_肾上腺_图标.jpg", "shen_shang_xian"),
    ("04_大胃王_图标.jpg", "da_wei_wang"),
    ("05_饥饿耐受_图标.jpg", "ji_e_nai_shou"),
    ("06_隐匿气息_图标.jpg", "yin_ni_qi_xi"),
    ("07_撕裂齿_图标.jpg", "si_lie_chi"),
    ("08_猎手直觉_图标.jpg", "lie_shou_zhi_jue"),
    ("09_暴食连锁_图标.jpg", "bao_shi_lian_suo"),
    ("10_贪食回复_图标.jpg", "tan_shi_hui_fu"),
]

# 技能特效：目录名 -> 产物拼音名；动画名 bao，12 fps
TEXIAO_SETS = [
    (FX1_SRC / "01_漩涡_螺旋水流圈_4帧", "xuan_wo", "bao", 12.0),
    (FX1_SRC / "02_淤泥弹_泥雾云团_4帧", "yu_ni_dan", "bao", 12.0),
    (FX1_SRC / "03_声呐脉冲_扩散圆环_4帧", "sheng_na_mai_chong", "bao", 12.0),
    (FX1_SRC / "04_鱼雷冲刺_速度拖尾_4帧", "yu_lei_chong_ci", "bao", 12.0),
    (FX2_SRC / "01_狂暴撕咬_4帧", "kuang_bao_si_yao", "bao", 12.0),
    (FX2_SRC / "02_硬鳞反击_4帧", "ying_lin_fan_ji", "bao", 12.0),
    (FX2_SRC / "03_逆流闪避_4帧", "ni_liu_shan_bi", "bao", 12.0),
    (FX2_SRC / "04_电感受器_4帧", "dian_gan_shou_qi", "bao", 12.0),
]

# 五鱼攻击动作：源图逐帧目视检查，5 套全部朝左；逐帧水平镜像成朝右，帧序不变。
DONGZUO_SETS = [
    (ACT_SRC / "01_剑鱼突刺动作_4帧", "jian_yu_gong", "gong", 10.0),
    (ACT_SRC / "02_旗鱼突刺动作_4帧", "qi_yu_gong", "gong", 10.0),
    (ACT_SRC / "03_狮子鱼喷毒动作_4帧", "shi_zi_yu_gong", "gong", 10.0),
    (ACT_SRC / "04_电鳐放电动作_4帧", "dian_yao_gong", "gong", 10.0),
    (ACT_SRC / "05_巨口鱼张大嘴撕咬动作_4帧", "ju_kou_yu_gong", "gong", 10.0),
]

# 装饰气泡：纯装饰生成器用；动画名 bao，6 fps（播完即消散，不循环）
QIPAO_SETS = [
    (QIPAO_SRC, "hai_di_qi_pao", "bao", 6.0),
]

TRACE = []       # 验收清单
ANOMALIES = []   # 源图贴边/内容异常记录


def _bg_edges(mx: np.ndarray, t: int = BG_T) -> np.ndarray:
    """从四条边泛洪的近黑背景连通域（8 连通，纯 numpy 行游程 + 并查集）。

    只清除与画布边缘连通的近黑像素；被主体包住的深色纹理不受影响。
    """
    h, w = mx.shape
    cand = mx <= t
    run_y, run_s, run_e, counts = [], [], [], []
    for y in range(h):
        row = cand[y]
        d = np.diff(np.concatenate(([np.int8(0)], row.view(np.int8), [np.int8(0)])))
        st = np.where(d == 1)[0]
        en = np.where(d == -1)[0] - 1
        counts.append(len(st))
        run_y.extend([y] * len(st))
        run_s.extend(st.tolist())
        run_e.extend(en.tolist())

    n = len(run_y)
    parent = list(range(n))
    rank = [0] * n

    def find(a: int) -> int:
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a: int, b: int) -> None:
        ra, rb = find(a), find(b)
        if ra == rb:
            return
        if rank[ra] < rank[rb]:
            ra, rb = rb, ra
        parent[rb] = ra
        if rank[ra] == rank[rb]:
            rank[ra] += 1

    offs = np.concatenate(([0], np.cumsum(counts)))
    for y in range(h - 1):
        i0, i1 = int(offs[y]), int(offs[y + 1])
        j0, j1 = int(offs[y + 1]), int(offs[y + 2])
        j = j0
        for i in range(i0, i1):
            s, e = run_s[i], run_e[i]
            while j < j1 and run_e[j] < s - 1:
                j += 1
            k = j
            while k < j1 and run_s[k] <= e + 1:
                union(i, k)
                k += 1

    border = set()
    for i in range(n):
        if run_y[i] == 0 or run_y[i] == h - 1 or run_s[i] == 0 or run_e[i] == w - 1:
            border.add(find(i))

    bg = np.zeros((h, w), dtype=bool)
    for i in range(n):
        if find(i) in border:
            bg[run_y[i], run_s[i]:run_e[i] + 1] = True
    return bg


def _dilate(mask: np.ndarray) -> np.ndarray:
    out = mask.copy()
    out[1:, :] |= mask[:-1, :]
    out[:-1, :] |= mask[1:, :]
    out[:, 1:] |= mask[:, :-1]
    out[:, :-1] |= mask[:, 1:]
    return out


def qubei(rgb: np.ndarray) -> np.ndarray:
    """去背 + 软边，返回 RGBA uint8。

    - 背景：与边缘连通的 max(R,G,B)≤20 像素，alpha=0；
    - 软边：紧贴背景的 2 像素带按亮度 20→80 做 smoothstep；
    - 半透明像素按黑底预乘关系反解颜色（C=aF），避免缩放/换背景时出现黑边；
    - 主体内部（含深色纹理）alpha 保持 255。
    """
    mx = rgb.max(axis=2).astype(np.int16)
    bg = _bg_edges(mx)
    fg = ~bg

    band = _dilate(_dilate(bg)) & fg
    t = np.clip((mx.astype(np.float32) - BG_T) / float(BG_HI - BG_T), 0.0, 1.0)
    t = t * t * (3.0 - 2.0 * t)  # smoothstep

    alpha = fg.astype(np.float32)
    alpha[band] = t[band]

    out = rgb.astype(np.float32)
    part = (alpha > 0.02) & (alpha < 0.999)
    if part.any():
        a = alpha[part][:, None]
        out[part] = np.clip(rgb[part].astype(np.float32) / np.maximum(a, 0.12), 0.0, 255.0)

    return np.dstack([out, alpha * 255.0]).round().clip(0, 255).astype(np.uint8)


def alpha_stats(rgba: np.ndarray):
    """返回 (x0,y0,x1,y1,cx,cy,覆盖率)，坐标均为像素下标。"""
    a = rgba[..., 3].astype(np.float64)
    mask = a > ALPHA_BBOX
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    wsum = np.where(mask, a, 0.0)
    total = wsum.sum()
    cx = float((wsum.sum(axis=0) * np.arange(rgba.shape[1])).sum() / total)
    cy = float((wsum.sum(axis=1) * np.arange(rgba.shape[0])).sum() / total)
    return (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()), cx, cy, float(mask.mean()))


def resize_rgba(rgba: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    """预乘 alpha 的 LANCZOS 缩放，避免透明黑像素把边缘拖暗。"""
    f = rgba.astype(np.float32)
    a = f[..., 3:4] / 255.0
    pre = f.copy()
    pre[..., :3] *= a
    im = Image.fromarray(pre.round().clip(0, 255).astype(np.uint8), "RGBA")
    im = im.resize(size, Image.LANCZOS)
    arr = np.asarray(im).astype(np.float32)
    a2 = arr[..., 3:4] / 255.0
    rgb = np.clip(arr[..., :3] / np.maximum(a2, 1.0 / 255.0), 0.0, 255.0)
    return np.dstack([rgb, arr[..., 3]]).round().clip(0, 255).astype(np.uint8)


def _crop_pad(rgba: np.ndarray, x0: int, y0: int, w: int, h: int) -> np.ndarray:
    """按给定左上角裁切；越界部分填透明。"""
    out = np.zeros((h, w, 4), dtype=np.uint8)
    sx0, sy0 = max(0, x0), max(0, y0)
    sx1, sy1 = min(rgba.shape[1], x0 + w), min(rgba.shape[0], y0 + h)
    if sx1 > sx0 and sy1 > sy0:
        dx0, dy0 = sx0 - x0, sy0 - y0
        out[dy0:dy0 + (sy1 - sy0), dx0:dx0 + (sx1 - sx0)] = rgba[sy0:sy1, sx0:sx1]
    return out


def build_strip(frames: list[np.ndarray], out_h: int = OUT_H) -> tuple[np.ndarray, list[dict]]:
    """按对称质心格子拼四帧横条；返回图像和逐帧对齐信息。"""
    infos = []
    for idx, f in enumerate(frames):
        st = alpha_stats(f)
        if st is None:
            raise ValueError(f"第 {idx + 1} 帧去背后没有内容")
        x0, y0, x1, y1, cx, cy, cover = st
        infos.append({
            "idx": idx, "bbox": (x0, y0, x1, y1), "cx": cx, "cy": cy, "cover": cover,
            "left": cx - x0, "right": x1 - cx, "top": cy - y0, "bottom": y1 - cy,
        })

    # 公式：half = ceil(max(左,右)) / ceil(max(上,下))，四帧共用同一格；
    # 四周再加 SAFE_PAD 透明余量，保证缩放后内容包围盒不贴格边。
    half_w = math.ceil(max(max(it["left"], it["right"]) for it in infos))
    half_h = math.ceil(max(max(it["top"], it["bottom"]) for it in infos))
    cell_w, cell_h = 2 * half_w + 2 * SAFE_PAD, 2 * half_h + 2 * SAFE_PAD
    frame_w = max(1, round(cell_w * out_h / cell_h))

    strip = np.zeros((out_h, frame_w * 4, 4), dtype=np.uint8)
    for i, f in enumerate(frames):
        it = infos[i]
        # floor 保证格子完整包住 bbox；质心最多偏移 <1 原图像素
        x0c = math.floor(it["cx"] - half_w) - SAFE_PAD
        y0c = math.floor(it["cy"] - half_h) - SAFE_PAD
        cell = _crop_pad(f, x0c, y0c, cell_w, cell_h)
        cell = resize_rgba(cell, (frame_w, out_h))
        strip[:, i * frame_w:(i + 1) * frame_w] = cell
    return strip, infos


def build_qipao_strip(
    frames: list[np.ndarray], cell: int = QIPAO_CELL, huxi: float = QIPAO_HUXI
) -> tuple[np.ndarray, list[dict]]:
    """装饰气泡：四帧共用同一缩放比例，按最大包围盒留呼吸边后逐格居中。

    与 build_strip 的「对称质心格子」不同：气泡团会逐帧长大/扩散，
    这里以四帧中最大 alpha 包围盒的边长为准统一缩放，保证播放时不会忽大忽小；
    每帧再按自身包围盒居中放进 cell×cell 格子里。
    """
    stats = []
    max_bian = 1
    for idx, f in enumerate(frames):
        st = alpha_stats(f)
        if st is None:
            raise ValueError(f"气泡第 {idx + 1} 帧去背后没有内容")
        x0, y0, x1, y1 = st[:4]
        bw, bh = x1 - x0 + 1, y1 - y0 + 1
        max_bian = max(max_bian, bw, bh)
        stats.append({"idx": idx, "bbox": (x0, y0, x1, y1), "w": bw, "h": bh})

    # 最大包围盒占格子的 (1 - 2×呼吸边)，四周留白一致；四帧同一比例。
    scale = cell * (1.0 - 2.0 * huxi) / float(max_bian)
    strip = np.zeros((cell, cell * len(frames), 4), dtype=np.uint8)
    for i, f in enumerate(frames):
        it = stats[i]
        x0, y0, x1, y1 = it["bbox"]
        crop = f[y0:y1 + 1, x0:x1 + 1]
        nw = max(1, round(it["w"] * scale))
        nh = max(1, round(it["h"] * scale))
        small = resize_rgba(crop, (nw, nh))
        ox, oy = (cell - nw) // 2, (cell - nh) // 2
        strip[oy:oy + nh, i * cell + ox:i * cell + ox + nw] = small
        it["scale"] = scale
        it["nw"], it["nh"] = nw, nh
    return strip, stats


def save_png(rgba: np.ndarray, path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(path, format="PNG", optimize=True, compress_level=9)
    return path.stat().st_size


def jpg_list(folder: Path) -> list[Path]:
    files = sorted(folder.glob("*.jpg"))
    if len(files) != 4:
        raise FileNotFoundError(f"{folder} 应有 4 张 jpg，实际 {len(files)} 张")
    return files


def png_list(folder: Path) -> list[Path]:
    # 只取源图 *.png；Godot 的 *.png.import 后缀是 .import，不会被 glob("*.png") 命中
    files = sorted(folder.glob("*.png"))
    if len(files) != 4:
        raise FileNotFoundError(f"{folder} 应有 4 张 png，实际 {len(files)} 张")
    return files


def load_rgb(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"))


def icon_from_rgba(rgba: np.ndarray) -> np.ndarray:
    """按 alpha 包围盒裁切后等比放进 128×128 透明画布。"""
    st = alpha_stats(rgba)
    if st is None:
        raise ValueError("图标去背后没有内容")
    x0, y0, x1, y1 = st[:4]
    crop = rgba[y0:y1 + 1, x0:x1 + 1]
    ch, cw = crop.shape[:2]
    scale = min(ICON_SIZE / cw, ICON_SIZE / ch)
    nw, nh = max(1, round(cw * scale)), max(1, round(ch * scale))
    small = resize_rgba(crop, (nw, nh))
    out = np.zeros((ICON_SIZE, ICON_SIZE, 4), dtype=np.uint8)
    ox, oy = (ICON_SIZE - nw) // 2, (ICON_SIZE - nh) // 2
    out[oy:oy + nh, ox:ox + nw] = small
    return out


def icon_from_effect(rgba: np.ndarray) -> np.ndarray:
    """特效图标：以 alpha 质心为中心，取内容最大边的正方形，缩放 128。"""
    st = alpha_stats(rgba)
    if st is None:
        raise ValueError("特效图标去背后没有内容")
    x0, y0, x1, y1, cx, cy, _ = st
    side = max(x1 - x0 + 1, y1 - y0 + 1)
    left = round(cx - side / 2)
    top = round(cy - side / 2)
    sq = _crop_pad(rgba, left, top, side, side)
    return resize_rgba(sq, (ICON_SIZE, ICON_SIZE))


def write_tres(path: Path, png_rel: str, anim: str, speed: float, frame_w: int) -> int:
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
            f"region = Rect2({i * frame_w}, 0, {frame_w}, {OUT_H})",
            "",
        ]
    lines += [
        "[resource]",
        'animations = [{',
        '"frames": [{',
        '"duration": 1.0,',
        '"texture": SubResource("AtlasTexture_0")',
        '}, {',
        '"duration": 1.0,',
        '"texture": SubResource("AtlasTexture_1")',
        '}, {',
        '"duration": 1.0,',
        '"texture": SubResource("AtlasTexture_2")',
        '}, {',
        '"duration": 1.0,',
        '"texture": SubResource("AtlasTexture_3")',
        '}],',
        '"loop": 0,',
        f'"name": &"{anim}",',
        f'"speed": {speed}',
        "}]",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return path.stat().st_size


def ensure_new(path: Path) -> None:
    if path.exists() and "--chongxie" not in sys.argv[1:]:
        raise FileExistsError(f"目标已存在，拒绝覆盖：{path}（确需重跑请加 --chongxie）")


def note_frame_edges(tag: str, rgba: np.ndarray) -> None:
    st = alpha_stats(rgba)
    if st is None:
        ANOMALIES.append(f"{tag}: 去背后为空")
        return
    x0, y0, x1, y1 = st[:4]
    h, w = rgba.shape[:2]
    touch = []
    if x0 == 0:
        touch.append("左")
    if x1 == w - 1:
        touch.append("右")
    if y0 == 0:
        touch.append("上")
    if y1 == h - 1:
        touch.append("下")
    if touch:
        ANOMALIES.append(
            f"{tag}: 内容贴源图{'/'.join(touch)}边（bbox={x1 - x0 + 1}×{y1 - y0 + 1}），已透明补边"
        )


def chuli_qipao() -> list[tuple]:
    """装饰气泡 4 帧横条 + SpriteFrames；独立成函数，便于只重跑这一条。"""
    expected = []
    for folder, name, anim, speed in QIPAO_SETS:
        png = QIPAO_DIR / f"{name}_4zhen.png"
        tres = DONGHUA_DIR / f"{name}_4zhen.tres"
        ensure_new(png)
        ensure_new(tres)
        frames = []
        for i, src in enumerate(png_list(folder)):
            rgba = qubei(load_rgb(src))
            note_frame_edges(f"气泡 {name} 第{i + 1}帧", rgba)
            frames.append(rgba)
        strip, infos = build_qipao_strip(frames)
        size = save_png(strip, png)
        tsize = write_tres(tres, f"res://assets/sucai/{QIPAO_DIR.name}/{png.name}",
                           anim, speed, QIPAO_CELL)
        expected.append((png, (QIPAO_CELL * 4, QIPAO_CELL), size, "气泡横条"))
        expected.append((tres, None, tsize, "SpriteFrames"))
        for it in infos:
            print(f"  {name} 第{it['idx'] + 1}帧: 源包围盒 {it['w']}×{it['h']} "
                  f"→ {it['nw']}×{it['nh']}（统一缩放 {it['scale']:.4f}）")
    return expected


def main() -> None:
    expected = []

    # A. 10 个被动技能图标
    for src_name, dst_name in ICONS:
        src = ICON_SRC / src_name
        if not src.exists():
            raise FileNotFoundError(src)
        dst = TUBIAO_DIR / f"{dst_name}.png"
        ensure_new(dst)
        icon = icon_from_rgba(qubei(load_rgb(src)))
        size = save_png(icon, dst)
        expected.append((dst, (ICON_SIZE, ICON_SIZE), size, "图标"))
        note_frame_edges(f"图标 {dst_name}", qubei(load_rgb(src)))

    # B/C. 特效与攻击动作 4 帧横条 + .tres
    jobs = [(d, n, a, s, "特效", False) for d, n, a, s in TEXIAO_SETS]
    jobs += [(d, n, a, s, "动作", True) for d, n, a, s in DONGZUO_SETS]
    for folder, name, anim, speed, kind, mirror in jobs:
        out_dir = TEXIAO_DIR if kind == "特效" else DONGZUO_DIR
        png = out_dir / f"{name}_4zhen.png"
        tres = DONGHUA_DIR / f"{name}_4zhen.tres"
        ensure_new(png)
        ensure_new(tres)
        frames = []
        for i, src in enumerate(jpg_list(folder)):
            rgba = qubei(load_rgb(src))
            note_frame_edges(f"{kind} {name} 第{i + 1}帧", rgba)
            if mirror:
                rgba = rgba[:, ::-1].copy()
            frames.append(rgba)
        strip, infos = build_strip(frames)
        size = save_png(strip, png)
        fw = strip.shape[1] // 4
        tsize = write_tres(tres, f"res://assets/sucai/{out_dir.name}/{png.name}", anim, speed, fw)
        expected.append((png, (strip.shape[1], strip.shape[0]), size, f"{kind}横条"))
        expected.append((tres, None, tsize, "SpriteFrames"))

    # D. 从特效首帧补两个被动图标
    dian_src = jpg_list(FX2_SRC / "04_电感受器_4帧")[2]  # 第 3 帧：电信号精准锁定
    ying_src = jpg_list(FX2_SRC / "02_硬鳞反击_4帧")[0]  # 第 1 帧：硬鳞护盾展开
    for src, dst_name in [(dian_src, "dian_gan_shou_qi"), (ying_src, "ying_lin_fan_ji")]:
        dst = TUBIAO_DIR / f"{dst_name}.png"
        ensure_new(dst)
        icon = icon_from_effect(qubei(load_rgb(src)))
        size = save_png(icon, dst)
        expected.append((dst, (ICON_SIZE, ICON_SIZE), size, "特效图标"))

    # E. 装饰气泡 4 帧横条 + SpriteFrames（纯装饰生成器用，6 fps 不循环）
    expected += chuli_qipao()

    # 验收：逐张检查 alpha / 尺寸 / 4 帧切割 / 质心
    print("=" * 96)
    print("产物清单")
    print("=" * 96)
    total = 0
    failures = []
    for path, dims, size, kind in expected:
        total += size
        if kind == "SpriteFrames":
            text = path.read_text(encoding="utf-8")
            if "SpriteFrames" not in text or '"loop": 0' not in text or "AtlasTexture_3" not in text:
                failures.append(f"{path}: .tres 结构不完整")
            print(f"{path.relative_to(GEN)}  -  {size:,} B  [{kind}]")
            continue
        with Image.open(path) as im:
            mode_ok = im.mode == "RGBA"
            w, h = im.size
            arr = np.asarray(im.convert("RGBA"))
        a = arr[..., 3]
        alpha_ok = bool(a.min() == 0 and a.max() == 255 and (a > 0).any())
        dim_ok = (dims is None) or (w, h) == dims
        print(f"{path.relative_to(GEN)}  {w}×{h}  {size:,} B  [{kind}]")
        if not (mode_ok and alpha_ok and dim_ok):
            failures.append(f"{path}: mode=RGBA?{mode_ok} alpha[{a.min()},{a.max()}] size={w}x{h}")

        if kind == "气泡横条":
            # 气泡按「包围盒中心」居中（不是 alpha 质心）：气泡团天然不对称，
            # 四帧统一缩放后只需保证包围盒完整、不贴边、中心落在格子中心。
            if w != QIPAO_CELL * 4 or h != QIPAO_CELL:
                failures.append(f"{path}: 气泡横条应为 {QIPAO_CELL * 4}×{QIPAO_CELL}")
                continue
            for i in range(4):
                qa = a[:, i * QIPAO_CELL:(i + 1) * QIPAO_CELL]
                ys, xs = np.where(qa > ALPHA_BBOX)
                if len(xs) == 0:
                    failures.append(f"{path}: 气泡第 {i + 1} 帧为空")
                    continue
                if xs.min() == 0 or xs.max() == QIPAO_CELL - 1 or ys.min() == 0 or ys.max() == QIPAO_CELL - 1:
                    failures.append(f"{path}: 气泡第 {i + 1} 帧包围盒贴格边")
                bx = (xs.min() + xs.max()) / 2.0
                by = (ys.min() + ys.max()) / 2.0
                if abs(bx - (QIPAO_CELL - 1) / 2.0) > 2.0 or abs(by - (QIPAO_CELL - 1) / 2.0) > 2.0:
                    failures.append(
                        f"{path}: 气泡第 {i + 1} 帧包围盒中心 ({bx:.1f},{by:.1f}) 未居中"
                    )
            continue

        if kind.endswith("横条"):
            if w % 4 != 0 or h != OUT_H:
                failures.append(f"{path}: 横条尺寸不符合 4 帧/高 256")
                continue
            fw = w // 4
            for i in range(4):
                qa = a[:, i * fw:(i + 1) * fw]
                ys, xs = np.where(qa > ALPHA_BBOX)
                if len(xs) == 0:
                    failures.append(f"{path}: 第 {i + 1} 帧为空")
                    continue
                if xs.min() == 0 or xs.max() == fw - 1 or ys.min() == 0 or ys.max() == h - 1:
                    failures.append(f"{path}: 第 {i + 1} 帧包围盒触格边")
                ww = np.where(qa > ALPHA_BBOX, qa, 0).astype(np.float64)
                tot = ww.sum()
                cx = (ww.sum(axis=0) * np.arange(fw)).sum() / tot
                cy = (ww.sum(axis=1) * np.arange(h)).sum() / tot
                if abs(cx - (fw - 1) / 2) > 2.5 or abs(cy - (h - 1) / 2) > 2.5:
                    failures.append(
                        f"{path}: 第 {i + 1} 帧质心偏移 ({cx:.1f},{cy:.1f}) / 格中心 ({(fw - 1) / 2:.1f},{(h - 1) / 2:.1f})"
                    )

    print("-" * 96)
    print(f"产物 {len(expected)} 个，合计 {total:,} B（{total / 1024:.1f} KiB）")
    if ANOMALIES:
        print("\n源图贴边/内容记录：")
        for s in ANOMALIES:
            print("  -", s)
    if failures:
        print("\n验收失败：")
        for s in failures:
            print("  -", s)
        raise SystemExit(1)
    print("\n验收通过：PNG 均为 RGBA、非全透明；横条宽被 4 整除、帧高 256、四帧包围盒不越界、质心居中。")


if __name__ == "__main__":
    main()
