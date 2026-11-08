# -*- coding: utf-8 -*-
"""《深海食纪》进化形态 6 帧游动动画流水线：透明底 6 帧序列图 -> 横排图集 + SpriteFrames。

用法（在工程根目录）：
    python -I tools/chuli_jinhua_6zhen.py              # 安全模式：目标已存在则报错，绝不覆盖
    python -I tools/chuli_jinhua_6zhen.py --chongxie   # 重跑模式：允许重写本脚本自己的产物

输入：D:\\新游戏001\\美术资源\\全部33种鱼_6帧自然水平游动单张帧动画全集\\2_单张序列帧_透明底PNG
      下 33 个「鱼种_形态名」目录，每组 6 张 1024×1024 透明 PNG（鱼朝左）。
输出：
- assets/sucai/jinhua/<bian_hao>_6zhen.png    6 帧横排图集（内容高 108、外圈 2px 透明边、朝右、帧宽一致）
- assets/sucai_classic/jinhua/<bian_hao>_6zhen.png  同名同内容（经典画风，PC 默认；两套必须同步）
- data/donghua/jinhua_<bian_hao>_6zhen.tres   SpriteFrames（动画名 you，6 帧，speed 10）
- 给 data/jinhua/<bian_hao>.tres 补 dong_hua 字段，并把 33 条 wan_jia_ke_yong 置 true

为什么用 6 帧 bbox 并集裁切：逐帧按自身包围盒裁切会让鱼在动画里“原地抖动”；
取并集 + 同一个缩放系数，帧间位移原样保留，游动才有起伏。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import chuli_sucai as cs  # noqa: E402  复用 alpha_stats / resize_rgba / save_png
import chuli_jin_hua as cj  # noqa: E402  复用 BIAO 的 33 条「源鱼种_形态名 -> bian_hao」映射

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

GEN = Path(__file__).resolve().parents[1]
SRC_ROOT = GEN / "美术资源" / "全部33种鱼_6帧自然水平游动单张帧动画全集" / "2_单张序列帧_透明底PNG"
PNG_DIR = GEN / "assets" / "sucai" / "jinhua"
JING_DIAN_PNG_DIR = GEN / "assets" / "sucai_classic" / "jinhua"
DONGHUA_DIR = GEN / "data" / "donghua"
TRES_DIR = GEN / "data" / "jinhua"

BASE_H = 108      # 与现有鱼贴图/进化静态图同基准（鱼体内容高）
PAD = 2           # 并集裁切四周留白，防缩放贴边
CHU_PAD = 2       # 每格输出透明边：防止 AtlasTexture 线性过滤吸到相邻帧
CELL_H = BASE_H + CHU_PAD * 2
ZHEN_SHU = 6      # 源素材固定 6 帧
DONG_HUA_SU = 10.0  # 6 帧 × 10 帧/秒 ≈ 0.6 秒一循环（4 帧素材是 8.0）

FAILURES = []


def jian_cha_yuan_tu() -> dict:
    """契约检查：33 组齐全、每组恰好 6 张、帧号 1..6 无缺漏；返回组名 -> 6 个路径。"""
    if not SRC_ROOT.is_dir():
        FAILURES.append(f"源目录不存在：{SRC_ROOT}")
        return {}

    jian = {}
    for zu in sorted(SRC_ROOT.iterdir()):
        if not zu.is_dir():
            FAILURES.append(f"源目录下有多余文件：{zu.name}")
            continue
        zhen = sorted(zu.glob(f"*_第*帧.png"))
        if len(zhen) != ZHEN_SHU:
            FAILURES.append(f"{zu.name}: 应有 {ZHEN_SHU} 帧，实际 {len(zhen)} 帧")
            continue
        hao = []
        for p in zhen:
            m = re.search(r"_第(\d+)帧\.png$", p.name)
            if m is None:
                FAILURES.append(f"{zu.name}: 文件名不合契约：{p.name}")
                continue
            hao.append(int(m.group(1)))
        if sorted(hao) != list(range(1, ZHEN_SHU + 1)):
            FAILURES.append(f"{zu.name}: 帧号应为 1..{ZHEN_SHU}，实际 {sorted(hao)}")
            continue
        zhen.sort(key=lambda p: int(re.search(r"_第(\d+)帧\.png$", p.name).group(1)))
        jian[zu.name] = zhen

    # BIAO 的 33 条必须与磁盘 33 组一一对应
    xu_yao = {f"{y}_{x}" for y, x, *_ in cj.BIAO}
    for ming in sorted(xu_yao - set(jian)):
        FAILURES.append(f"源目录缺组：{ming}")
    for ming in sorted(set(jian) - xu_yao):
        FAILURES.append(f"源目录多出未登记组：{ming}")
    if len(jian) != len(cj.BIAO):
        FAILURES.append(f"组数不符：磁盘 {len(jian)} / 表 {len(cj.BIAO)}")
    return jian


def he_bing_bao_wei(zhen: list[np.ndarray]) -> tuple[int, int, int, int]:
    """6 帧 alpha 包围盒并集（含 2px 留白）：所有帧共用同一个裁切窗口。"""
    x0 = y0 = 10 ** 9
    x1 = y1 = -1
    h, w = zhen[0].shape[:2]
    for arr in zhen:
        st = cs.alpha_stats(arr)
        if st is None:
            FAILURES.append("某帧没有可见内容")
            continue
        x0 = min(x0, st[0])
        y0 = min(y0, st[1])
        x1 = max(x1, st[2])
        y1 = max(y1, st[3])
    x0, y0 = max(0, x0 - PAD), max(0, y0 - PAD)
    x1, y1 = min(w - 1, x1 + PAD), min(h - 1, y1 + PAD)
    return x0, y0, x1, y1


def fan_yu_cheng(rgba: np.ndarray) -> np.ndarray:
    """把源 PNG 的“预乘 alpha”反解成直通 alpha（颜色 ÷ alpha），alpha 原样保留。

    为什么要这一步：这批 6 帧源图的半透明像素是「颜色 × alpha」的预乘关系
    （黑底软边导出常见），RGB 本身已经是乘过 alpha 的暗色。Godot 按直通 alpha 采样，
    若直接缩放，半透明鳍/边缘会发黑发灰，进化后整条鱼像开了隐身。
    只反解颜色、不动 alpha：轮廓与透明区域完全沿用源图的 alpha。
    """
    f = rgba.astype(np.float32)
    a = f[..., 3:4] / 255.0
    rgb = np.clip(f[..., :3] / np.maximum(a, 1.0 / 255.0), 0.0, 255.0)
    return np.dstack([rgb, f[..., 3]]).round().clip(0, 255).astype(np.uint8)


def ning_shi_alpha(rgba: np.ndarray, di: int = 12, gao: int = 48) -> np.ndarray:
    """把鱼体 alpha 收实：≥48 直接不透明，12~48 平滑过渡，≤12 视为透明。

    源图是“软边线稿”，鳍膜大量 30~180 的半透明像素；缩到 108px 后这些像素占比更高，
    在明亮海底背景上会透出背景，看起来像隐身。这里保留轮廓的 1~2px 软边，
    但把鱼体内部收成不透明，找回调色板原本的扎实观感。
    """
    f = rgba.astype(np.float32)
    a = f[..., 3]
    t = np.clip((a - di) / float(gao - di), 0.0, 1.0)
    t = t * t * (3.0 - 2.0 * t)  # smoothstep
    f[..., 3] = np.where(a <= 0, 0.0, 255.0 * t)
    return f.round().clip(0, 255).astype(np.uint8)


def jia_shen_yan_se(rgba: np.ndarray, jiang_an: float = 0.22, bao_he: float = 1.08,
                    di: int = 90, gao: int = 235) -> np.ndarray:
    """把偏亮/偏淡的鱼体压深一点，暗色线稿和黑边保持原样。

    用户反馈部分进化图（青白、浅粉这类亮色鱼）在亮海底背景上像半透明。
    实测源图到输出并没有被提亮，问题在原画本身亮部多、饱和度低。
    这里按像素亮度做自适应：亮度 ≤ 90 不动，越接近 235/255 压得越多（最多 -22%），
    同时围绕亮度把通道差拉开 8%（轻微提饱和），让颜色更实、不再和背景糊在一起。
    只改 RGB，不动 alpha；暗线、黑边、透明区都不受影响。
    """
    f = rgba.astype(np.float32)
    rgb = f[..., :3]
    lum = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    rgb = lum[..., None] + (rgb - lum[..., None]) * bao_he
    t = np.clip((lum - di) / float(gao - di), 0.0, 1.0)
    t = t * t * (3.0 - 2.0 * t)  # smoothstep：暗部 0，亮部 1
    f[..., :3] = np.clip(rgb, 0.0, 255.0) * (1.0 - jiang_an * t)[..., None]
    return f.round().clip(0, 255).astype(np.uint8)


def jia_gong_zu(zhen: list[np.ndarray]) -> np.ndarray:
    """并集裁切 -> 同一缩放系数内容高 108 -> 水平镜像（源朝左，游戏朝右）-> 横排 6 格。"""
    # 先反预乘还原颜色，再把鱼体 alpha 收实，最后压深亮部：三步都不改轮廓位置
    zhen = [jia_shen_yan_se(ning_shi_alpha(fan_yu_cheng(arr))) for arr in zhen]
    x0, y0, x1, y1 = he_bing_bao_wei(zhen)
    ch, cw = y1 - y0 + 1, x1 - x0 + 1
    mu_biao_kuan = max(1, round(cw * BASE_H / ch))
    kuai = []
    for arr in zhen:
        crop = arr[y0:y1 + 1, x0:x1 + 1]
        small = cs.resize_rgba(crop, (mu_biao_kuan, BASE_H))
        # 缩放会重新造出大量半透明像素（实测占可见像素四到六成）：鱼体内部的透明缝隙、
        # 鳍膜软边被 LANCZOS 平均成 128~246 的半透明，在海底背景上身体会透出背景，
        # 像条玻璃鱼。这里在输出尺寸上再收一次 alpha：≥112 全不透明、16~112 平滑过渡、
        # ≤16 视为透明——保住 1~2px 软边，鱼体内部实心。必须在缩放之后做：缩放前
        # 收得再实，插值也会重新造出半透明。
        small = ning_shi_alpha(small, di=16, gao=112)
        small = small[:, ::-1]  # 镜像成朝右；帧序不变
        # 每格四周各留 CHU_PAD 透明边：相邻帧之间就有 2×CHU_PAD 像素间隔，
        # 线性过滤取样不会吸到隔壁帧的鱼体
        cell = np.zeros((CELL_H, small.shape[1] + CHU_PAD * 2, 4), dtype=np.uint8)
        cell[CHU_PAD:CHU_PAD + BASE_H, CHU_PAD:CHU_PAD + small.shape[1]] = small
        kuai.append(cell)
    return np.concatenate(kuai, axis=1)


def xie_dong_hua_tres(path: Path, bian_hao: str, zhen_kuan: int) -> int:
    """手写 SpriteFrames：1 张横排图 + 6 个 AtlasTexture，动画名固定 you。"""
    ids = [f"AtlasTexture_{i}" for i in range(ZHEN_SHU)]
    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={ZHEN_SHU + 2} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="res://assets/sucai/jinhua/{bian_hao}_6zhen.png" id="1_tiao"]',
    ]
    for i, sid in enumerate(ids):
        lines += [
            "",
            f'[sub_resource type="AtlasTexture" id="{sid}"]',
            'atlas = ExtResource("1_tiao")',
            f'region = Rect2({i * zhen_kuan}, 0, {zhen_kuan}, {CELL_H})',
        ]
    frames = "{\n" + "\n}, {\n".join(
        ['"duration": 1.0,\n"texture": SubResource("%s")' % sid for sid in ids]
    ) + "\n}"
    lines += [
        "",
        "[resource]",
        "animations = [{",
        f'"frames": [{frames}],',
        '"loop": 1,',
        '"name": &"you",',
        f'"speed": {DONG_HUA_SU}',
        "}]",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return path.stat().st_size


def qian_gua_dong_hua(jin_hua_tres: Path, bian_hao: str) -> None:
    """给 JinHua .tres 注入 dong_hua 字段（可重跑：先清旧行再插入）。"""
    text = jin_hua_tres.read_text(encoding="utf-8")
    text = re.sub(r'^\[ext_resource type="SpriteFrames" path="[^"]*" id="3_dong_hua"\]\n', "",
                  text, flags=re.M)
    text = re.sub(r"^dong_hua = ExtResource\(\"3_dong_hua\"\)\n", "", text, flags=re.M)
    text = re.sub(r'^\[gd_resource type="Resource" script_class="JinHua" load_steps=\d+',
                  '[gd_resource type="Resource" script_class="JinHua" load_steps=4', text, flags=re.M)

    ext_line = (f'[ext_resource type="SpriteFrames" '
                f'path="res://data/donghua/jinhua_{bian_hao}_6zhen.tres" id="3_dong_hua"]')
    tie_marker = 'tie_tu = ExtResource("2_tie_tu")'
    if tie_marker not in text:
        FAILURES.append(f"{jin_hua_tres.name}: 找不到 tie_tu 行，无法挂动画")
        return
    # ext_resource 紧跟贴图那一行之后（Godot 习惯把 ext_resource 归在一起）
    text = text.replace('tie_tu = ExtResource("2_tie_tu")',
                        f'dong_hua = ExtResource("3_dong_hua")\n{tie_marker}', 1)
    ext_anchor = re.search(r'^\[ext_resource type="Texture2D" path="[^"]+" id="2_tie_tu"\]$',
                           text, flags=re.M)
    if ext_anchor is None:
        FAILURES.append(f"{jin_hua_tres.name}: 找不到 2_tie_tu ext_resource")
        return
    text = text[:ext_anchor.end()] + "\n" + ext_line + text[ext_anchor.end():]
    jin_hua_tres.write_text(text, encoding="utf-8", newline="\n")


def da_kai_quan_bu_jin_hua() -> None:
    """全部鱼种现在都可被玩家选中，33 条进化分支统一开放。"""
    for _, _, bian_hao, *_ in cj.BIAO:
        p = TRES_DIR / f"{bian_hao}.tres"
        text = p.read_text(encoding="utf-8")
        if "wan_jia_ke_yong = false" in text:
            text = text.replace("wan_jia_ke_yong = false", "wan_jia_ke_yong = true")
            p.write_text(text, encoding="utf-8", newline="\n")


def main() -> None:
    chong_xie = "--chongxie" in sys.argv[1:]
    jian = jian_cha_yuan_tu()
    if FAILURES:
        for s in FAILURES:
            print("  -", s)
        raise SystemExit(1)

    chan_wu = []
    for yu_zhong, xing_tai, bian_hao, *_ in cj.BIAO:
        png = PNG_DIR / f"{bian_hao}_6zhen.png"
        dh = DONGHUA_DIR / f"jinhua_{bian_hao}_6zhen.tres"
        jh = TRES_DIR / f"{bian_hao}.tres"
        for p in (png, dh):
            if p.exists() and not chong_xie:
                FAILURES.append(f"产物已存在（加 --chongxie 才覆盖）：{p.relative_to(GEN)}")
        if not jh.exists():
            FAILURES.append(f"JinHua 数据缺失：{jh.relative_to(GEN)}")
        if FAILURES:
            continue

        zhen = []
        for p in jian[f"{yu_zhong}_{xing_tai}"]:
            with Image.open(p) as im:
                zhen.append(np.asarray(im.convert("RGBA")))
        tu = jia_gong_zu(zhen)
        zhen_kuan = tu.shape[1] // ZHEN_SHU
        png_size = cs.save_png(tu, png)
        # 经典画风同名同内容：PC 默认走 sucai_classic，不同步的话 PC 上还是旧图
        jd_png = JING_DIAN_PNG_DIR / f"{bian_hao}_6zhen.png"
        jd_size = cs.save_png(tu, jd_png)
        dh_size = xie_dong_hua_tres(dh, bian_hao, zhen_kuan)
        qian_gua_dong_hua(jh, bian_hao)
        chan_wu.append((png, dh, tu.shape[1], zhen_kuan, png_size, dh_size, jd_png, jd_size))
        print(f"  {bian_hao:32s} ← {yu_zhong}_{xing_tai}  "
              f"{tu.shape[1]}×{tu.shape[0]}（帧宽 {zhen_kuan}）")

    da_kai_quan_bu_jin_hua()

    # 验收：尺寸/透明/帧宽/字段
    print("=" * 96)
    zong = 0
    for png, dh, w, zhen_kuan, png_size, dh_size, jd_png, jd_size in chan_wu:
        zong += png_size + dh_size + jd_size
        with Image.open(png) as im:
            mode_ok = im.mode == "RGBA"
            ww, hh = im.size
            a = np.asarray(im.convert("RGBA"))[..., 3]
        alpha_ok = bool(a.min() == 0 and a.max() == 255 and (a > 8).any())
        # 四边必须全透明：图集边缘不串色，也不让 AtlasTexture 采到相邻帧
        bian_ok = bool(a[0].max() == 0 and a[-1].max() == 0
                       and a[:, 0].max() == 0 and a[:, -1].max() == 0)
        dim_ok = (hh == CELL_H and ww == zhen_kuan * ZHEN_SHU)
        # 经典版必须与像素版逐字节一致：HuaZhi 在 PC 上默认经典画风，漏同步就白改
        jd_ok = bool(jd_png.exists() and jd_png.read_bytes() == png.read_bytes())
        text = dh.read_text(encoding="utf-8")
        tres_ok = (text.count('[sub_resource type="AtlasTexture"') == ZHEN_SHU
                   and text.count("SubResource(") >= ZHEN_SHU
                   and '"name": &"you"' in text)
        if not (mode_ok and alpha_ok and dim_ok and tres_ok and bian_ok and jd_ok):
            FAILURES.append(f"{png.name}: RGBA?{mode_ok} alpha[{a.min()},{a.max()}] "
                            f"size={ww}x{hh} 四边透明?{bian_ok} tres?{tres_ok} 经典同步?{jd_ok}")
        print(f"{png.relative_to(GEN)}  {ww}×{hh}  {png_size:,} B + tres {dh_size:,} B"
              f" + 经典 {jd_size:,} B")

    print("-" * 96)
    print(f"产物 {len(chan_wu)} 组（像素 + 经典双画风 PNG + SpriteFrames），合计 {zong:,} B（{zong / 1024:.1f} KiB）")
    if FAILURES:
        print("\n验收失败：")
        for s in FAILURES:
            print("  -", s)
        raise SystemExit(1)
    print(f"\n验收通过：33 组 × {ZHEN_SHU} 帧、内容高 {BASE_H}（图集高 {CELL_H}）、"
          f"四边透明、朝右横排、alpha 已收实、dong_hua 已挂、像素/经典双画风已同步、全部分支已开放。")


if __name__ == "__main__":
    main()
