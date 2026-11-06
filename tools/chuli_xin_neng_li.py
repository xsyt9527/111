# -*- coding: utf-8 -*-
"""《深海食纪》新增 4 主动 + 4 被动素材流水线。

输入：
  美术资源/深海抓鱼游戏_新增4主动特效16帧与4被动图标_20张纯黑底单图包/
输出：
  assets/sucai/texiao/<id>_4zhen.png      四帧横条（每帧 256 高）
  data/donghua/<id>_4zhen.tres            SpriteFrames（动画名 bao）
  assets/sucai/tubiao/<id>.png            128×128 图标

复用 tools/chuli_sucai.py 的去背、预乘缩放、质心格子与 .tres 写入函数；
只新增本批产物，不覆盖已有文件（确需重跑加 --chongxie）。

用法（在工程根目录）：
    python -I tools/chuli_xin_neng_li.py
    python -I tools/chuli_xin_neng_li.py --chongxie
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

# 让 Windows 控制台的定向输出也按 UTF-8 打印中文路径
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

# -I 隔离模式不保证脚本目录在 sys.path：显式加入后再复用旧流水线
sys.path.insert(0, str(Path(__file__).resolve().parent))
import chuli_sucai as cs  # noqa: E402

GEN = Path(__file__).resolve().parents[1]
MEI_SHU = GEN / "美术资源"
SRC = MEI_SHU / "深海抓鱼游戏_新增4主动特效16帧与4被动图标_20张纯黑底单图包"

ICON_DIR = SRC / "05_新增被动技能图标"
TEXIAO_DIR = GEN / "assets" / "sucai" / "texiao"
TUBIAO_DIR = GEN / "assets" / "sucai" / "tubiao"
DONGHUA_DIR = GEN / "data" / "donghua"

# 特效：目录名 -> (产物 id, 帧率)。四组都是 4 帧、播完即销毁。
# 帧率按素材节奏定：电脉冲最急 12 fps；硬壳/气泡 10 fps；血腥狂热首两帧近似，放慢到 8 fps。
TEXIAO_SETS = [
    (SRC / "01_硬壳护体_特效", "ying_ke_hu_ti", 10.0),
    (SRC / "02_电脉冲_特效", "dian_mai_chong", 12.0),
    (SRC / "03_诱饵气泡_特效", "you_er_qi_pao", 10.0),
    (SRC / "04_血腥狂热_特效", "xue_xing_kuang_re", 8.0),
]

# 被动图标：源文件名 -> 产物 id
BEI_DONG_ICONS = [
    ("01_被动图标_背刺直觉_鱼尾匕首.png", "bei_ci_zhi_jue"),
    ("02_被动图标_绝境反咬_小鱼反咬大鱼.png", "jue_jing_fan_yao"),
    ("03_被动图标_锈鳞_锈色鳞片电火花.png", "xiu_lin"),
    ("04_被动图标_腐肉诱饵_发光肉块漩涡.png", "fu_rou_you_er"),
]

# 主动图标：本批没有单独给，先用特效首帧生成 128×128 占位（与现有透明贴纸风格一致）
ZHU_DONG_ICONS = [
    ("ying_ke_hu_ti", "ying_ke_hu_ti"),
    ("dian_mai_chong", "dian_mai_chong"),
    ("you_er_qi_pao", "you_er_qi_pao"),
    ("xue_xing_kuang_re", "xue_xing_kuang_re"),
]


def _qu_bai_jiao(rgba: np.ndarray) -> None:
    """去掉锈鳞图标底部两角的白色源图残角。

    该图黑底四周有白色硬边，去黑底抓不到（白色不是近黑）；
    只处理画面下方 22% 且左右各 16% 的外圈，避免误伤徽章内部的白色高光。
    """
    h, w = rgba.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    bai = (rgba[..., 0] > 220) & (rgba[..., 1] > 220) & (rgba[..., 2] > 220)
    wai_quan = ((xs < w * 0.16) | (xs > w * 0.84)) & (ys > h * 0.78)
    rgba[bai & wai_quan, 3] = 0


def chuli_texiao() -> None:
    for folder, bian_hao, fps in TEXIAO_SETS:
        png = TEXIAO_DIR / f"{bian_hao}_4zhen.png"
        tres = DONGHUA_DIR / f"{bian_hao}_4zhen.tres"
        cs.ensure_new(png)
        cs.ensure_new(tres)
        files = sorted(folder.glob("*.png"))
        if len(files) != 4:
            raise FileNotFoundError(f"{folder} 应有 4 张 png，实际 {len(files)} 张")
        frames = []
        for i, src in enumerate(files):
            rgba = cs.qubei(cs.load_rgb(src))
            cs.note_frame_edges(f"特效 {bian_hao} 第{i + 1}帧", rgba)
            frames.append(rgba)
        strip, infos = cs.build_strip(frames, cs.OUT_H)
        size = cs.save_png(strip, png)
        tsize = cs.write_tres(
            tres,
            f"res://assets/sucai/texiao/{png.name}",
            "bao",
            fps,
            strip.shape[1] // 4,
        )
        print(f"  特效 {bian_hao}: {strip.shape[1]}×{strip.shape[0]}，{fps:g} fps，"
              f"png {size} B，tres {tsize} B")
        for it in infos:
            print(f"    第{it['idx'] + 1}帧 bbox={it['bbox']} 质心=({it['cx']:.1f},{it['cy']:.1f})")


def chuli_tubiao() -> None:
    for src_name, bian_hao in BEI_DONG_ICONS:
        dst = TUBIAO_DIR / f"{bian_hao}.png"
        cs.ensure_new(dst)
        rgba = cs.qubei(cs.load_rgb(ICON_DIR / src_name))
        if bian_hao == "xiu_lin":
            _qu_bai_jiao(rgba)
        icon = cs.icon_from_rgba(rgba)
        size = cs.save_png(icon, dst)
        print(f"  图标 {bian_hao}: 128×128，{size} B（被动原图）")

    for folder, bian_hao, _fps in TEXIAO_SETS:
        dst = TUBIAO_DIR / f"{bian_hao}.png"
        cs.ensure_new(dst)
        files = sorted(folder.glob("*.png"))
        rgba = cs.qubei(cs.load_rgb(files[0]))
        icon = cs.icon_from_effect(rgba)
        size = cs.save_png(icon, dst)
        print(f"  图标 {bian_hao}: 128×128，{size} B（特效首帧占位）")


def main() -> int:
    print("== 新增 4 主动特效 ==")
    chuli_texiao()
    print("== 新增 8 个能力图标 ==")
    chuli_tubiao()
    if cs.ANOMALIES:
        print("== 源图贴边记录（已透明补边）==")
        for line in cs.ANOMALIES:
            print("  " + line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
