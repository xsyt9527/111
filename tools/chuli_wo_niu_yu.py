# -*- coding: utf-8 -*-
"""把「凹凸蜗牛鱼」7 张纯黑底单图加工成游戏贴图。

用法（在工程根目录）：
    python -I tools/chuli_wo_niu_yu.py
    python -I tools/chuli_wo_niu_yu.py --chongxie   # 允许覆盖自己的产物

产物：
- assets/sucai/shenhai_yu/ao_tu_wo_niu_yu.png        3 视图里取侧视，朝右，高 100px + 4px 透明边
- assets/sucai/shenhai_yu/ao_tu_wo_niu_yu_4zhen.png  4 帧横条，对称质心格子，质心居中，朝右
- data/donghua/ao_tu_wo_niu_yu_4zhen.tres            与横条配套的 SpriteFrames（"you"，4 帧，8 fps）

处理规则与 tools/chuli_sucai.py 保持一致：
- 近黑背景按连通域从四边泛洪清除，边缘按亮度 20→80 做软边；
- 半透明像素按黑底预乘关系反解颜色，缩放用预乘 alpha 的 LANCZOS；
- 4 帧按「对称质心格子」统一格子，质心落在每格中心；内容最高帧缩放到 100px；
- 源图朝左，静态图与每一帧都水平镜像成游戏约定的朝右（整条翻会把帧序倒放，不能翻横条整体）。

本脚本只写上面 3 个产物，不修改 tools/chuli_sucai.py。
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

GEN = Path(__file__).resolve().parents[1]
YUAN_DIR = (
    GEN
    / "美术资源"
    / "深海抓鱼游戏_凹凸蜗牛鱼_3视图与4帧动画_7张纯黑底单图包"
    / "凹凸蜗牛鱼_3视图与4帧"
)
YU_DIR = GEN / "assets" / "sucai" / "shenhai_yu"
DONGHUA_DIR = GEN / "data" / "donghua"

WEN_JIAN_CE = "01_凹凸蜗牛鱼_侧视图.png"
WEN_JIAN_ZHENG = "02_凹凸蜗牛鱼_正视图.png"
WEN_JIAN_BEI = "03_凹凸蜗牛鱼_背视图.png"
WEN_JIAN_4ZHEN = [
    "04_凹凸蜗牛鱼_游动第1帧_上扬摆尾.png",
    "05_凹凸蜗牛鱼_游动第2帧_下压划水.png",
    "06_凹凸蜗牛鱼_游动第3帧_S型滑行.png",
    "07_凹凸蜗牛鱼_游动第4帧_回弹收尾.png",
]

CHAN_WU_PNG = YU_DIR / "ao_tu_wo_niu_yu.png"
CHAN_WU_TIAO = YU_DIR / "ao_tu_wo_niu_yu_4zhen.png"
CHAN_WU_TRES = DONGHUA_DIR / "ao_tu_wo_niu_yu_4zhen.tres"

BG_T = 20          # 近黑背景阈值：纯黑底实测 max(R,G,B) ≤ 9，取 20 留余量
BG_HI = 80         # 软边亮度上限：20→80 之间做 smoothstep
ALPHA_BBOX = 8     # 统计包围盒/质心时忽略近乎全透明的像素
NEI_RONG_GAO = 100  # 静态图与横条内容的目标高度（与现有鱼贴图一致）
JING_TAI_BIAN = 4   # 静态图四周透明边：现有鱼为 100 + 4×2 = 108 高
SAFE_PAD = 8       # 横条质心格四周透明余量，防止缩放后内容贴格边
ZHEN_SU = 8.0      # 游动动画帧率，与现有鱼一致


def _bg_edges(mx: np.ndarray, t: int = BG_T) -> np.ndarray:
    """从四条边泛洪近黑背景连通域（8 连通，行游程 + 并查集）。

    只清除与画布边缘连通的近黑像素，主体内部深色纹理（眼睛等）保留。
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
    """去背 + 软边，返回 RGBA uint8（黑底预乘反解，避免缩放出现黑边）。"""
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
    """返回 (x0,y0,x1,y1,cx,cy)，坐标均为像素下标。"""
    a = rgba[..., 3].astype(np.float64)
    mask = a > ALPHA_BBOX
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    wsum = np.where(mask, a, 0.0)
    total = wsum.sum()
    cx = float((wsum.sum(axis=0) * np.arange(rgba.shape[1])).sum() / total)
    cy = float((wsum.sum(axis=1) * np.arange(rgba.shape[0])).sum() / total)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()), cx, cy


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


def load_rgb(path: Path) -> np.ndarray:
    if not path.exists():
        raise FileNotFoundError(path)
    return np.asarray(Image.open(path).convert("RGB"))


def jing_xiang(rgba: np.ndarray) -> np.ndarray:
    """水平镜像：源图朝左，游戏约定朝右。"""
    return rgba[:, ::-1].copy()


def zhi_zuo_jing_tai(rgba: np.ndarray) -> np.ndarray:
    """侧视图：包围盒裁切 → 高 100 → 四周 4px 透明边。"""
    st = alpha_stats(rgba)
    if st is None:
        raise ValueError("侧视图去背后没有内容")
    x0, y0, x1, y1 = st[:4]
    crop = rgba[y0:y1 + 1, x0:x1 + 1]
    ch, cw = crop.shape[:2]
    nw = max(1, round(cw * NEI_RONG_GAO / ch))
    small = resize_rgba(crop, (nw, NEI_RONG_GAO))
    out = np.zeros((NEI_RONG_GAO + 2 * JING_TAI_BIAN,
                    nw + 2 * JING_TAI_BIAN, 4), dtype=np.uint8)
    out[JING_TAI_BIAN:JING_TAI_BIAN + NEI_RONG_GAO,
        JING_TAI_BIAN:JING_TAI_BIAN + nw] = small
    return out


def zhi_zuo_heng_tiao(frames: list[np.ndarray]) -> tuple[np.ndarray, int, int]:
    """4 帧横条：对称质心格子，最高内容缩放到 100px，四帧等宽。

    格子尺寸由「内容最高帧到 100px」的缩放比例反推：
    half_w/half_h = 四帧里质心到包围盒边的最远距离 × 比例；
    格子 = 2×half + 2×SAFE_PAD，保证四帧质心都落在格心且内容不贴边。
    返回 (横条, 单帧宽, 单帧高)。
    """
    infos = []
    for idx, f in enumerate(frames):
        st = alpha_stats(f)
        if st is None:
            raise ValueError(f"第 {idx + 1} 帧去背后没有内容")
        x0, y0, x1, y1, cx, cy = st
        infos.append({
            "idx": idx, "bbox": (x0, y0, x1, y1), "cx": cx, "cy": cy,
            "left": cx - x0, "right": x1 - cx, "top": cy - y0, "bottom": y1 - cy,
        })

    zui_gao = max(it["bbox"][3] - it["bbox"][1] + 1 for it in infos)
    bi_li = NEI_RONG_GAO / float(zui_gao)
    half_w = math.ceil(max(max(it["left"], it["right"]) for it in infos) * bi_li)
    half_h = math.ceil(max(max(it["top"], it["bottom"]) for it in infos) * bi_li)
    cell_w = 2 * half_w + 2 * SAFE_PAD
    cell_h = 2 * half_h + 2 * SAFE_PAD

    # 先按原图裁出「缩放后恰好是格子大小」的区域，再一次性缩放——
    # 这样四帧共用同一比例，帧间相对位移不会丢。
    crop_w = max(1, round(cell_w / bi_li))
    crop_h = max(1, round(cell_h / bi_li))
    strip = np.zeros((cell_h, cell_w * 4, 4), dtype=np.uint8)
    for i, f in enumerate(frames):
        it = infos[i]
        x0 = round(it["cx"] - crop_w / 2.0)
        y0 = round(it["cy"] - crop_h / 2.0)
        cell = _crop_pad(f, x0, y0, crop_w, crop_h)
        cell = resize_rgba(cell, (cell_w, cell_h))
        strip[:, i * cell_w:(i + 1) * cell_w] = cell
        it["final_bbox"] = _xin_wei_kuang(cell)
    return strip, cell_w, cell_h


def _xin_wei_kuang(rgba: np.ndarray) -> tuple[int, int, int, int]:
    a = rgba[..., 3]
    ys, xs = np.where(a > ALPHA_BBOX)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def xie_tres(path: Path, png_rel: str, zhen_kuan: int, zhen_gao: int) -> None:
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
            f"region = Rect2({i * zhen_kuan}, 0, {zhen_kuan}, {zhen_gao})",
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
        '"loop": 1,',
        '"name": &"you",',
        f'"speed": {ZHEN_SU}',
        "}]",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def save_png(rgba: np.ndarray, path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(path, format="PNG", optimize=True, compress_level=9)
    return path.stat().st_size


def ensure_new(path: Path) -> None:
    if path.exists() and "--chongxie" not in sys.argv[1:]:
        raise FileExistsError(f"目标已存在，拒绝覆盖：{path}（确需重跑请加 --chongxie）")


def yan_zheng_png(path: Path, qi_wang: tuple[int, int]) -> None:
    """产物自检：RGBA、有透明也有不透明、尺寸正确。"""
    with Image.open(path) as im:
        mo = im.mode
        da_xiao = im.size
        a = np.asarray(im.convert("RGBA"))[..., 3]
    assert mo == "RGBA", f"{path}: 应为 RGBA，实际 {mo}"
    assert da_xiao == qi_wang, f"{path}: 尺寸应为 {qi_wang}，实际 {da_xiao}"
    assert a.min() == 0 and a.max() == 255, f"{path}: alpha 应同时含 0 与 255"
    assert (a > 0).any(), f"{path}: 不应全透明"


def main() -> None:
    for name in [WEN_JIAN_CE, WEN_JIAN_ZHENG, WEN_JIAN_BEI, *WEN_JIAN_4ZHEN]:
        if not (YUAN_DIR / name).exists():
            raise FileNotFoundError(YUAN_DIR / name)
    for path in [CHAN_WU_PNG, CHAN_WU_TIAO, CHAN_WU_TRES]:
        ensure_new(path)

    print("源目录：", YUAN_DIR)
    # 静态图：3 视图取宽高比最大的侧视（01），朝左 → 镜像朝右
    ce_rgba = jing_xiang(qubei(load_rgb(YUAN_DIR / WEN_JIAN_CE)))
    jing_tai = zhi_zuo_jing_tai(ce_rgba)
    save_png(jing_tai, CHAN_WU_PNG)
    yan_zheng_png(CHAN_WU_PNG, (jing_tai.shape[1], jing_tai.shape[0]))
    print(f"静态侧视：{jing_tai.shape[1]}×{jing_tai.shape[0]}（内容高 {NEI_RONG_GAO} + "
          f"{JING_TAI_BIAN}px 透明边）")

    # 4 帧：逐帧去背 + 镜像，再按对称质心格子拼横条
    frames = []
    for i, name in enumerate(WEN_JIAN_4ZHEN):
        rgba = jing_xiang(qubei(load_rgb(YUAN_DIR / name)))
        st = alpha_stats(rgba)
        print(f"  第 {i + 1} 帧源包围盒：{st[2] - st[0] + 1}×{st[3] - st[1] + 1}，"
              f"质心 ({st[4]:.1f},{st[5]:.1f})")
        frames.append(rgba)
    strip, zhen_kuan, zhen_gao = zhi_zuo_heng_tiao(frames)
    save_png(strip, CHAN_WU_TIAO)
    yan_zheng_png(CHAN_WU_TIAO, (zhen_kuan * 4, zhen_gao))
    print(f"4 帧横条：{zhen_kuan * 4}×{zhen_gao}（单帧 {zhen_kuan}×{zhen_gao}）")

    # 逐格验收：四帧都不贴格边，质心距格心 ≤ 2.5px
    a = strip[..., 3]
    for i in range(4):
        qa = a[:, i * zhen_kuan:(i + 1) * zhen_kuan]
        ys, xs = np.where(qa > ALPHA_BBOX)
        if len(xs) == 0:
            raise AssertionError(f"横条第 {i + 1} 帧为空")
        if xs.min() == 0 or xs.max() == zhen_kuan - 1 or ys.min() == 0 or ys.max() == zhen_gao - 1:
            raise AssertionError(f"横条第 {i + 1} 帧内容贴格边")
        ww = np.where(qa > ALPHA_BBOX, qa, 0).astype(np.float64)
        zong = ww.sum()
        cx = (ww.sum(axis=0) * np.arange(zhen_kuan)).sum() / zong
        cy = (ww.sum(axis=1) * np.arange(zhen_gao)).sum() / zong
        if abs(cx - (zhen_kuan - 1) / 2.0) > 2.5 or abs(cy - (zhen_gao - 1) / 2.0) > 2.5:
            raise AssertionError(
                f"横条第 {i + 1} 帧质心偏移 ({cx:.1f},{cy:.1f}) / "
                f"格心 ({(zhen_kuan - 1) / 2.0:.1f},{(zhen_gao - 1) / 2.0:.1f})"
            )
        print(f"  第 {i + 1} 帧：包围盒 {xs.min()}..{xs.max()} × {ys.min()}..{ys.max()}，"
              f"质心 ({cx:.1f},{cy:.1f}) 居中")

    xie_tres(CHAN_WU_TRES, "res://assets/sucai/shenhai_yu/ao_tu_wo_niu_yu_4zhen.png",
             zhen_kuan, zhen_gao)
    print("SpriteFrames：", CHAN_WU_TRES.relative_to(GEN))
    print("\n验收通过：静态侧视与 4 帧横条均为 RGBA、朝右、内容高约 100px、质心居中。")


if __name__ == "__main__":
    main()
