# -*- coding: utf-8 -*-
"""《深海食纪》抓鱼船四大攻击整船动画流水线。

输入：美术资源/深海抓鱼游戏_抓鱼船四大攻击招式_16张纯黑底单图包（4 招 × 4 帧）
输出：
  assets/sucai/ji_qi_chuan/chuan_zhao_4zhen.png   （4 招横向排开，每招 4 格 × 512）
  data/donghua/chuan_zhao_4zhen.tres              （4 条 4 帧动画，播放一次不循环）

四帧不是同一构图：AI 单图里船的位置/大小会漂。这里按实测的「船体缩放 + 船心」
做仿射归一化——把每帧的船缩放并平移到同一位置，特效跟着船一起动，播放时不抖。

用法（工程根目录）：
    python -I tools/chuli_chuan_zhao.py [--chongxie]
"""
from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from chuli_sucai import qubei  # noqa: E402  四边泛洪去背，与新素材同一套口径

GEN = Path(__file__).resolve().parents[1]
SRC = GEN / "美术资源" / "深海抓鱼游戏_抓鱼船四大攻击招式_16张纯黑底单图包"
TEX_DIR = GEN / "assets" / "sucai" / "ji_qi_chuan"
DONGHUA_DIR = GEN / "data" / "donghua"
OUT_PNG = TEX_DIR / "chuan_zhao_4zhen.png"
OUT_TRES = DONGHUA_DIR / "chuan_zhao_4zhen.tres"

CELL = 512          # 单帧输出边长
S_REF = 2.2         # 归一化基准：模板船在 1024 源图里的缩放（所有帧向它看齐）
CANON = 512.0       # 归一化后船心落在 1024 画布的什么位置（再 ×0.5 得到 CELL 坐标）
GLOBAL_SHIFT = (73.0, 9.0)  # 模板匹配的“船心”系统性偏左：整批补正，让船心落在格中心

# 目录名 -> (动画名, 每帧持续时间, 四帧的 (模板匹配缩放, 船心源坐标, 额外像素补正))
# 探照灯/炸弹等帧由带 alpha mask 的多尺度模板匹配测得；船锚第 4 帧、鱼叉第 2~4 帧
# 被特效遮住，按同套素材目视复核后覆写，保证四帧船体对齐。
SETS = [
    ("01_一阶段_探照灯扫描_4帧", "tan_zhao", 0.225, [
        (2.75, (618, 565), (8, 9)), (2.75, (618, 565), (14, -16)),
        (2.75, (618, 565), (39, -18)), (2.75, (618, 565), (0, 0)),
    ]),
    ("02_一阶段_船锚横扫_4帧", "chuan_mao", 0.225, [
        (1.85, (752, 498), (0, 0)), (1.60, (782, 689), (0, 0)),
        (1.80, (760, 515), (8, 12)), (1.85, (752, 498), (0, 0)),
    ]),
    ("03_二阶段_深水炸弹_4帧", "shen_zha_dan", 0.250, [
        (2.65, (629, 391), (0, 0)), (2.15, (629, 323), (0, 0)),
        (1.95, (622, 312), (0, 0)), (1.95, (622, 312), (0, 0)),
    ]),
    ("04_二阶段_鱼叉齐射_4帧", "yu_cha", 0.150, [
        (2.75, (618, 565), (2, 6)), (2.18, (640, 305), (-50, -30)),
        (1.65, (720, 310), (-50, -30)), (1.72, (710, 305), (-50, -30)),
    ]),
]


def _load_rgba(path: Path) -> np.ndarray:
    wen = np.fromfile(str(path), dtype=np.uint8)
    bgr = cv2.imdecode(wen, cv2.IMREAD_COLOR)
    if bgr is None:
        raise RuntimeError("读不了图片: %s" % path)
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    return qubei(rgb)


def _gui_yi_hua(rgba: np.ndarray, s: float, c: tuple[int, int],
        bu_zheng: tuple[float, float]) -> np.ndarray:
    """把船心 c / 船体缩放 s 归一化到 512 输出格的 (256,256) / S_REF。"""
    k = 0.5 * S_REF / s
    ju_zhen = np.array([
        [k, 0.0, CELL * 0.5 - k * c[0] + GLOBAL_SHIFT[0] + bu_zheng[0]],
        [0.0, k, CELL * 0.5 - k * c[1] + GLOBAL_SHIFT[1] + bu_zheng[1]],
    ], dtype=np.float32)
    return cv2.warpAffine(
        rgba, ju_zhen, (CELL, CELL),
        flags=cv2.INTER_LANCZOS4,
        borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0),
    )


def main() -> int:
    chongxie = "--chongxie" in sys.argv
    if OUT_PNG.exists() and not chongxie:
        print("产物已存在，不覆盖：%s（重跑加 --chongxie）" % OUT_PNG)
        return 1
    TEX_DIR.mkdir(parents=True, exist_ok=True)
    DONGHUA_DIR.mkdir(parents=True, exist_ok=True)

    atlas = np.zeros((CELL, CELL * 4 * len(SETS), 4), dtype=np.uint8)
    for hang, (mu_lu, _dong_hua, _shi_chang, bian_huan) in enumerate(SETS):
        tu_pian = sorted((SRC / mu_lu).glob("*.png"))
        if len(tu_pian) != 4:
            raise RuntimeError("%s 应有 4 帧，实际 %d" % (mu_lu, len(tu_pian)))
        for lie, (wen_jian, (s, c, bu_zheng)) in enumerate(zip(tu_pian, bian_huan)):
            rgba = _gui_yi_hua(_load_rgba(wen_jian), s, c, bu_zheng)
            x = (hang * 4 + lie) * CELL
            atlas[:, x:x + CELL] = rgba
        print("已处理 %s：4 帧" % mu_lu)

    ok, bian_ma = cv2.imencode(".png", cv2.cvtColor(atlas, cv2.COLOR_RGBA2BGRA))
    if not ok:
        raise RuntimeError("PNG 编码失败")
    bian_ma.tofile(str(OUT_PNG))
    print("写出 %s" % OUT_PNG)

    # SpriteFrames：每格 512×512，动画名按招式；loop=0 播完即停
    kuai = ["", ""]
    kuai += ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (1 + 4 * len(SETS))]
    kuai += ["", '[ext_resource type="Texture2D" path="res://assets/sucai/ji_qi_chuan/chuan_zhao_4zhen.png" id="1_zhao"]']
    for i in range(4 * len(SETS)):
        hang, lie = divmod(i, 4)
        kuai += ["", '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]' % i,
                 'atlas = ExtResource("1_zhao")',
                 "region = Rect2(%d, 0, %d, %d)" % (i * CELL, CELL, CELL)]
    kuai += ["", "[resource]", "animations = ["]
    for hang, (_mu_lu, dong_hua, shi_chang, _bh) in enumerate(SETS):
        kuai += ["{"]
        kuai += ['"frames": [']
        for lie in range(4):
            i = hang * 4 + lie
            kuai += ["{", '"duration": 1.0,', '"texture": SubResource("AtlasTexture_%d")' % i,
                     "}" + ("," if lie < 3 else "")]
        kuai += ["],", '"loop": 0,', '"name": &"%s",' % dong_hua,
                 '"speed": %.4f' % (1.0 / shi_chang), "}" + ("," if hang < len(SETS) - 1 else "")]
    kuai += ["]"]
    OUT_TRES.write_text("\n".join(kuai) + "\n", encoding="utf-8")
    print("写出 %s" % OUT_TRES)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
