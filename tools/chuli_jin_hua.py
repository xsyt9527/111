# -*- coding: utf-8 -*-
"""《深海食纪》进化形态素材流水线：黑底单图 -> 透明 PNG + JinHua 数据 .tres。

用法（在工程根目录）：
    python -I tools/chuli_jin_hua.py              # 安全模式：目标已存在则报错，绝不覆盖
    python -I tools/chuli_jin_hua.py --chongxie   # 重跑模式：允许重写本脚本自己的产物

输入：D:\\新游戏001\\美术资源\\进化 下的 33 张黑底单图（jpg/png），命名「鱼种_形态名_第N帧.ext」。
输出：
- assets/sucai/jinhua/<bian_hao>.png   透明底、内容高统一 108 像素（与现有鱼贴图同基准）
- data/jinhua/<bian_hao>.tres          JinHua 资源（名称/分支/描述/玩家专属标记/专属能力槽位）

为什么高统一 108：现有鱼种贴图（如 ao_tu_wo_niu_yu.png）都是 108 高，
玩家进化后换的是同一套 AnimatedSprite2D，贴图基准一致才不会突然变大变小。

去背复用 tools/chuli_sucai.py：近黑背景按连通域从四边泛洪清除 + 软边 + 预乘反解。
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import chuli_sucai as cs  # noqa: E402  复用去背/统计/缩放入口

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

GEN = Path(__file__).resolve().parents[1]
JIN_HUA_SRC = GEN / "美术资源" / "进化"
PNG_DIR = GEN / "assets" / "sucai" / "jinhua"
TRES_DIR = GEN / "data" / "jinhua"

BASE_H = 108  # 产物内容高度：与现有鱼贴图同基准
PAD = 2       # 裁切时四周留的透明像素：防 LANCZOS 缩放把边缘贴死

FEN_ZHI = {"东方神话": 0, "西方神话": 1, "能力异化": 2}

# (源图鱼种名, 形态名, bian_hao, 基础鱼种 id, 基础鱼种显示名, 分支, 描述, 玩家专属)
BIAO = [
    # 1 大眼金枪鱼（zong_yu）
    ("大眼金枪鱼", "文鳐战鲔", "wen_yao_zhan_wei", "zong_yu", "大眼金枪鱼", "东方神话",
     "生出银色双翼，游动如流星破海；能掀起狂风巨浪，跃出水面即可滑翔。", False),
    ("大眼金枪鱼", "海神巡洋驹", "hai_shen_xun_yang_ju", "zong_yu", "大眼金枪鱼", "西方神话",
     "鱼鳍化金色半透明鬃毛，鱼尾变海马卷尾，身披骨质重甲；海神波塞冬的冲锋坐骑。", False),
    ("大眼金枪鱼", "千眼雷破鱼", "qian_yan_lei_po_yu", "zong_yu", "大眼金枪鱼", "能力异化",
     "巨大眼睛异变出多颗复眼；不再依靠游速，双眼发射高压电击（类电鳗能力觉醒）。", False),
    # 2 灯笼鱼（ye_deng_long_yu）
    ("灯笼鱼", "幽冥引路灯", "you_ming_yin_lu_deng", "ye_deng_long_yu", "灯笼鱼", "东方神话",
     "半透明幽灵鱼，发光器脱离身体化作悬浮鬼火；引诱迷失的船只触礁。", False),
    ("灯笼鱼", "星落游魂", "xing_luo_you_hun", "ye_deng_long_yu", "灯笼鱼", "西方神话",
     "全身发光点连成星座图谱，如一条星辰光带；折射光线实现完全隐身。", False),
    ("灯笼鱼", "爆裂磷光兽", "bao_lie_lin_guang_shou", "ye_deng_long_yu", "灯笼鱼", "能力异化",
     "温和发光器变成暴躁爆炸器官；遇险全身高亮后引发闪光爆炸，致盲敌人。", False),
    # 3 电鳐（lv_yu；素材包写作「电鳗」，游戏内鱼种叫电鳐）
    ("电鳗", "雷渊鸣蛇", "lei_yuan_ming_she", "lv_yu", "电鳐", "东方神话",
     "《山海经》其状如蛇而四翼：长出虚幻四翼，放电伴雷鸣，能召唤小范围雷暴。", False),
    ("电鳗", "雷霆海德拉", "lei_ting_hai_de_la", "lv_yu", "电鳐", "西方神话",
     "多头颈各自独立放高压电，布满导电发光鳞片，如盘绕海底的霓虹电线。", False),
    ("电鳗", "磁暴深渊虫", "ci_bao_shen_yuan_chong", "lv_yu", "电鳐", "能力异化",
     "放弃放电，转为磁场控制——令周围金属武器失效，甚至扭曲光线与空间。", False),
    # 4 剑鱼（jian_yu）
    ("剑鱼", "破浪独角蛟", "po_lang_du_jiao_jiao", "jian_yu", "剑鱼", "东方神话",
     "吻部螺旋化为钻头（类独角鲸），生龙鳞与须；冲刺如鱼雷穿透极厚海冰或甲板。", False),
    ("剑鱼", "深渊穿刺者", "shen_yuan_chuan_ci_zhe", "jian_yu", "剑鱼", "西方神话",
     "身体极度骨化的白色亡灵巨鱼，剑吻淬深海剧毒；如游荡的骑士长枪，刺穿巨型海怪硬壳。", False),
    ("剑鱼", "空间裂刃鱼", "kong_jian_lie_ren_yu", "jian_yu", "剑鱼", "能力异化",
     "剑吻如镜面反光，极速游动划出空间裂缝（真空刃）；既切肉体，也切断水流。", False),
    # 5 鲸鲨（fen_yu）
    ("鲸鲨", "北冥巨鲲", "bei_ming_ju_kun", "fen_yu", "鲸鲨", "东方神话",
     "体型膨胀数百倍，背部岛屿化生青苔古树，通体青黑；能驮起一整座仙山。", False),
    ("鲸鲨", "原初利维坦", "yuan_chu_li_wei_tan", "fen_yu", "鲸鲨", "西方神话",
     "暗金色装甲鳞片，巨口变黑洞般的深渊；吞吐海水引发大漩涡，纯粹深海霸主。", False),
    ("鲸鲨", "星空吞星兽", "xing_kong_tun_xing_shou", "fen_yu", "鲸鲨", "能力异化",
     "白色斑点化作真正发光星系，游动如移动的宇宙夜空；吸收光能与热能维持庞大身躯。", False),
    # 6 巨口鱼（ju_kou_yu）
    ("巨口鱼", "饕餮吞海兽", "tao_tie_tun_hai_shou", "ju_kou_yu", "巨口鱼", "东方神话",
     "嘴巴占满全身，下巴可脱臼裂开，牙齿化钢铁；一口吞下比自身大两倍的猎物。", False),
    ("巨口鱼", "深渊裂口怪", "shen_yuan_lie_kou_guai", "ju_kou_yu", "巨口鱼", "西方神话",
     "透明头骨完全裂开如长满尖刺的深海捕蝇草，内部生发光诱饵触手；入内猎物无法逃脱。", False),
    ("巨口鱼", "灵魂吸食者", "ling_hun_xi_shi_zhe", "ju_kou_yu", "巨口鱼", "能力异化",
     "放弃物理咬合，成半透明幽冥鱼；巨口吞噬目标灵魂（能量槽），被咬中陷入恐惧与虚弱。", False),
    # 7 旗鱼（qi_yu）
    ("旗鱼", "风帆巡海夜叉", "feng_fan_xun_hai_ye_cha", "qi_yu", "旗鱼", "东方神话",
     "背鳍变画有上古符文的巨大骨帆，操控风向；水面滑翔带起巨大龙卷风。", False),
    ("旗鱼", "幽灵海盗帆", "you_ling_hai_dao_fan", "qi_yu", "旗鱼", "西方神话",
     "背鳍变破烂幽灵船帆，身体白骨化；自身极速，并召唤幽灵水手与幻影炮弹。", False),
    ("旗鱼", "裂空飞鱼", "lie_kong_fei_yu", "qi_yu", "旗鱼", "能力异化",
     "背鳍进化为羽翼；保有剑鱼级速度，还能真正脱离水面高空俯冲轰炸。", False),
    # 8 蓑鲉（cheng_yu）
    ("蓑鲉", "九尾毒羽妖", "jiu_wei_du_yu_yao", "cheng_yu", "狮子鱼（蓑鲉）", "东方神话",
     "毒鳍刺变九条华丽孔雀尾羽（或狐尾），带幻术；极美，靠近即被麻痹。", False),
    ("蓑鲉", "美杜莎毒冠", "mei_du_sha_du_guan", "cheng_yu", "狮子鱼（蓑鲉）", "西方神话",
     "毒刺变成条条蠕动小毒蛇（类美杜莎头发），游动时喷吐毒液；石化或麻痹猎物。", False),
    ("蓑鲉", "珊瑚棘冠兽", "shan_hu_ji_guan_shou", "cheng_yu", "狮子鱼（蓑鲉）", "能力异化",
     "柔软毒刺变珊瑚般坚硬毒棘装甲，背部可共生小型剧毒海葵。", False),
    # 9 桶眼鱼（hong_yu；游戏内鱼种叫铜眼鱼）
    ("桶眼鱼", "碧眼观星兽", "bi_yan_guan_xing_shou", "hong_yu", "铜眼鱼（桶眼鱼）", "东方神话",
     "透明脑袋里长出第三、第四只眼，翡翠般发光；看破虚妄，识破一切伪装。", False),
    ("桶眼鱼", "深渊全视之眼", "shen_yuan_quan_shi_zhi_yan", "hong_yu", "铜眼鱼（桶眼鱼）", "西方神话",
     "克苏鲁风邪神眷属，透明脑袋成巨大悬浮眼球；发射精神污染光线使敌人疯狂。", False),
    ("桶眼鱼", "激光矩阵鱼", "ji_guang_ju_zhen_yu", "hong_yu", "铜眼鱼（桶眼鱼）", "能力异化",
     "管状眼变高能激光发射器，可独立旋转瞄准；黑暗中绿色致命光束穿透猎物。", False),
    # 10 钻光鱼（lan_yu）
    ("钻光鱼", "噬星萤火虫", "shi_xing_ying_huo_chong", "lan_yu", "钻光鱼", "东方神话",
     "身体如萤火虫化作光团；成千上万聚集为巨大光龙，啃食大型海怪。", False),
    ("钻光鱼", "诅咒星辰虫", "zu_zhou_xing_chen_chong", "lan_yu", "钻光鱼", "西方神话",
     "光点变诅咒孢子，附着敌人不断吸取生命力，并在其身上长出新钻光鱼。", False),
    ("钻光鱼", "等离子穿甲鱼", "deng_li_zi_chuan_jia_yu", "lan_yu", "钻光鱼", "能力异化",
     "针状齿发射微型等离子射线，如无数海底极光；穿透厚重装甲。", False),
    # 11 凹凸蜗牛鱼（玩家；试玩版只实装本鱼种 3 分支）
    ("凹凸蜗牛鱼", "太岁肉灵芝兽", "tai_sui_rou_ling_zhi_shou", "ao_tu_wo_niu_yu", "凹凸蜗牛鱼", "东方神话",
     "身体化巨大果冻，切块即速再生，凝胶反弹一切物理攻击。", True),
    ("凹凸蜗牛鱼", "深海史莱姆女王", "shen_hai_shi_lai_mu_nv_wang", "ao_tu_wo_niu_yu", "凹凸蜗牛鱼", "西方神话",
     "吸收周遭有机物巨大化，器官发光；喷吐强酸或吸收其他鱼基因改变外形。", True),
    ("凹凸蜗牛鱼", "超压凝胶炮", "chao_ya_ning_jiao_pao", "ao_tu_wo_niu_yu", "凹凸蜗牛鱼", "能力异化",
     "身体如高压锅，瞬间吸收极深水压能量，从口中喷射高压水刀切割一切。", True),
]

FAILURES = []  # 验收失败清单


def suo_yin_yuan_tu() -> dict:
    """扫描源目录：按「鱼种_形态名」建索引，帧号后缀不参与匹配（第几帧都可能）。"""
    jian = {}
    for p in sorted(JIN_HUA_SRC.iterdir()):
        if p.suffix.lower() not in (".jpg", ".png", ".jpeg", ".webp"):
            continue
        ming = p.stem
        if "_第" in ming:
            ming = ming.split("_第")[0]  # 去掉「_第3帧」
        jian[ming] = p
    return jian


def jian_cha_yuan_tu(jian: dict) -> None:
    # 契约检查：33 条表项都能在源目录找到唯一一张、且没有多余素材
    yong_dao = set()
    for yu_zhong, xing_tai, *_ in BIAO:
        jian_ming = f"{yu_zhong}_{xing_tai}"
        if jian_ming not in jian:
            FAILURES.append(f"源图缺失：{jian_ming}")
            continue
        yong_dao.add(jian_ming)
    for jian_ming in jian:
        if jian_ming not in yong_dao:
            FAILURES.append(f"源图未被登记（表里没有）：{jian_ming}")


def qubei_cai_qie(src: Path) -> np.ndarray:
    """去背 → 按 alpha 包围盒裁切（留 2 像素透明边）→ 内容高等比缩到 BASE_H → 水平镜像。

    33 张源图逐张目视检查全部朝左；游戏里鱼贴图默认朝右（Yu 的 flip_h 以朝右为基准），
    所以与五鱼攻击动作同一处理：水平镜像成朝右，帧序不变。
    """
    rgba = cs.qubei(cs.load_rgb(src))
    st = cs.alpha_stats(rgba)
    if st is None:
        FAILURES.append(f"{src.name}: 去背后没有内容")
        return np.zeros((BASE_H, BASE_H, 4), dtype=np.uint8)
    x0, y0, x1, y1 = st[:4]
    x0, y0 = max(0, x0 - PAD), max(0, y0 - PAD)
    x1, y1 = min(rgba.shape[1] - 1, x1 + PAD), min(rgba.shape[0] - 1, y1 + PAD)
    crop = rgba[y0:y1 + 1, x0:x1 + 1]
    ch, cw = crop.shape[:2]
    nw = max(1, round(cw * BASE_H / ch))
    small = cs.resize_rgba(crop, (nw, BASE_H))
    return small[:, ::-1].copy()


def bao_cun_png(arr: np.ndarray, path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr, "RGBA").save(path, format="PNG", optimize=True, compress_level=9)
    return path.stat().st_size


def xie_tres(path: Path, bian_hao: str, ming_zi: str, ji_yu_bian_hao: str, ji_yu_ming: str,
             fen_zhi: int, miao: str, wan_jia: bool) -> int:
    # 手写 .tres：字段全是简单标量，格式稳定；专属能力槽位留空 = null（内容待填）
    lines = [
        '[gd_resource type="Resource" script_class="JinHua" load_steps=3 format=3]',
        "",
        '[ext_resource type="Script" path="res://scripts/jin_hua.gd" id="1_jin_hua"]',
        f'[ext_resource type="Texture2D" path="res://assets/sucai/jinhua/{bian_hao}.png" id="2_tie_tu"]',
        "",
        "[resource]",
        'script = ExtResource("1_jin_hua")',
        f'bian_hao = &"{bian_hao}"',
        f'ming_zi = "{ming_zi}"',
        f'ji_yu_bian_hao = &"{ji_yu_bian_hao}"',
        f'ji_yu_ming = "{ji_yu_ming}"',
        f"fen_zhi = {fen_zhi}",
        f'miao_shu = "{miao}"',
        'tie_tu = ExtResource("2_tie_tu")',
        f"wan_jia_ke_yong = {'true' if wan_jia else 'false'}",
        "shu_zhi_bei = 1.5",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return path.stat().st_size


def main() -> None:
    jian = suo_yin_yuan_tu()
    jian_cha_yuan_tu(jian)
    if FAILURES:
        for s in FAILURES:
            print("  -", s)
        raise SystemExit(1)

    chan_wu = []
    for yu_zhong, xing_tai, bian_hao, ji_yu_bian_hao, ji_yu_ming, fen_zhi_ming, miao, wan_jia in BIAO:
        png = PNG_DIR / f"{bian_hao}.png"
        tres = TRES_DIR / f"{bian_hao}.tres"
        cs.ensure_new(png)
        cs.ensure_new(tres)
        src = jian[f"{yu_zhong}_{xing_tai}"]
        arr = qubei_cai_qie(src)
        png_size = bao_cun_png(arr, png)
        tres_size = xie_tres(tres, bian_hao, xing_tai, ji_yu_bian_hao, ji_yu_ming,
                             FEN_ZHI[fen_zhi_ming], miao, wan_jia)
        chan_wu.append((png, arr.shape[1], arr.shape[0], png_size, "PNG"))
        chan_wu.append((tres, 0, 0, tres_size, "TRES"))
        print(f"  {bian_hao:32s} ← {src.name}  {arr.shape[1]}×{arr.shape[0]}")

    # 验收：格式 / alpha / 高度 / .tres 结构
    print("=" * 96)
    print(f"产物 {len(chan_wu)} 个（33 PNG + 33 TRES）")
    print("=" * 96)
    zong = 0
    for path, w, h, size, kind in chan_wu:
        zong += size
        if kind == "TRES":
            text = path.read_text(encoding="utf-8")
            ok = ('script_class="JinHua"' in text and 'tie_tu = ExtResource("2_tie_tu")' in text
                  and "shu_zhi_bei = 1.5" in text)
            if not ok:
                FAILURES.append(f"{path.name}: .tres 结构不完整")
            continue
        with Image.open(path) as im:
            mode_ok = im.mode == "RGBA"
            ww, hh = im.size
            a = np.asarray(im.convert("RGBA"))[..., 3]
        alpha_ok = bool(a.min() == 0 and a.max() == 255 and (a > 8).any())
        dim_ok = (hh == BASE_H and ww > 0)
        print(f"{path.relative_to(GEN)}  {ww}×{hh}  {size:,} B")
        if not (mode_ok and alpha_ok and dim_ok):
            FAILURES.append(f"{path.name}: mode=RGBA?{mode_ok} alpha[{a.min()},{a.max()}] size={ww}x{hh}")

    print("-" * 96)
    print(f"合计 {zong:,} B（{zong / 1024:.1f} KiB）")
    if FAILURES:
        print("\n验收失败：")
        for s in FAILURES:
            print("  -", s)
        raise SystemExit(1)
    print("\n验收通过：33 张 RGBA 透明底、内容高统一 %d、.tres 字段齐、玩家 3 分支专属标记已写。" % BASE_H)


if __name__ == "__main__":
    main()
