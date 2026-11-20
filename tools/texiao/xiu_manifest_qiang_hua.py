# 一次性：加强 11 套弱特效的 manifest 条目（提亮/换源）。用后可留作记录。
import json

LU = r"D:\新游戏001\tools\texiao\manifest_v2.json"
with open(LU, encoding="utf-8") as f:
    data = json.load(f)

GAI = {
    # 换更大的源 + 亮色
    "chuan_zha_dan": {
        "id": "explosions/big-explosion",
        "palette": ["#1a0d04", "#3d1c08", "#6b330c", "#a35610", "#d8841a", "#f8b83a", "#ffdd7a", "#fff6d8"],
        "blend": "add",
    },
    "qian_yan": {
        "id": "projectiles/laser-bolt",
        "palette": ["#0a0618", "#1c1040", "#331878", "#5424c0", "#7c3ff0", "#a86aff", "#d8b8ff", "#ffffff"],
    },
    "jn_yu_lei": {
        "id": "projectiles/rocket",
        "palette": ["#200804", "#481408", "#7c240c", "#b83c10", "#e86818", "#ff9c30", "#ffc878", "#fff0d0"],
    },
    # 同源 water-jet 双子拉开色系
    "jn_ji_su": {
        "palette": ["#2a1204", "#5c2608", "#8f4210", "#c96a14", "#f29a1e", "#ffc854", "#ffe9a8", "#ffffff"],
    },
    "shen_ju": {
        "palette": ["#101418", "#242c34", "#3e4a56", "#5f7080", "#8ba0b2", "#c0d4e4", "#eef6ff", "#ffffff"],
    },
    # 探照灯改暖黄光锥（与 shi_hua_tong 灰白 god-rays 拉开）
    "chuan_tan_zhao": {
        "palette": ["#241c08", "#4a3a10", "#756014", "#a08a1c", "#c8b024", "#ead83a", "#fff8a8", "#ffffff"],
    },
    # 紫系提一档
    "lie_kou": {
        "palette": ["#160826", "#32104a", "#54206e", "#7a3496", "#a44cc0", "#cc7ae4", "#eeb0ff", "#ffffff"],
    },
    # 魂系改青白（与 lie_kou 紫 / gui_huo 绿错开）
    "she_hun": {
        "palette": ["#061418", "#0c2e34", "#145058", "#1e7a82", "#2ea8ae", "#4ed4d8", "#8aeef0", "#d8ffff"],
    },
}

shu = 0
for e in data:
    if e["key"] in GAI:
        e.update(GAI[e["key"]])
        shu += 1

with open(LU, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f"gai_dong {shu} tiao")
