# AI 2D Rig Builder (`addons/ai_rig_2d`) — Claude 专用操作与自然 K 帧指南 (v1.1)

本插件专为 **Claude (AI Agent)** 与 **Godot 4.x (含 4.7.2)** 协同开发 2D 骨骼动画设计。采用**纯文件读写 (`.json` -> `.tscn` / `.tres`) + Headless CLI 校验 + 相对 Rest 增量 K 帧 (`dp` / `drot_deg` / `dscale`)** 架构，彻底解决 AI 盲猜坐标导致肢体脱节、旋转撕裂像素、动作机械同步的问题。

## 1. 为什么 AI 直接 K 帧容易很奇怪？（四大根因与 v1.1 解决方案）

| 常见怪异现象 | 根本原因 | v1.1 插件与工作流解决方案 |
| ----- | ----- | ----- |
| **头/四肢突然飞到胸口或脱节** | Claude 把子骨骼关键帧写成了绝对坐标 `"v": [0, 0]`（误以为 `[0,0]` 是不动，实际覆盖了子骨骼原本相对于父骨骼的 `[0, -14]` Rest 偏移） | **全面使用相对增量关键帧**：位移写 `"dp": [dx, dy]`，旋转写 `"drot_deg": d_angle`，缩放写 `"dscale": [mx, my]`，构建器自动叠加到骨骼 Rest 姿态上 |
| **旋转时部件绕左上角大甩动、静息姿态错位** | `rigid_parts` 模式下 Claude 算错了 `Sprite2D.offset` 与骨骼全局坐标的差值 | **自动对齐 Offset**：在 `parts` 中**省略 `offset` 字段**，`rig_builder.gd` 会自动计算 `offset = region_rect.position - bone_global_rest_pos`，保证切片严丝合缝留在原图位置并绕骨骼关节旋转 |
| **64×64 像素小人边缘断裂、描边闪烁糊边** | Claude 给低分辨率像素图加了 `3°~8°` 的微小旋转或过大位移（64×64 下移动 5px 相当于全身剧烈抽搐） | **像素风黄金法则**：64×64 像素图 `idle` 呼吸位移限制在 `1~2px` 整数 `dp`，禁用微小角度旋转，强制 `"interpolation": "nearest"` |
| **所有部位同起同落像提线木偶** | 躯干、头、围巾、武器的关键帧峰值全写在同一个时间点 `t=0.4` | **相位滞后 (Phase Lag)**：子骨骼（头、头发、围巾、武器）比父骨骼（躯干）延后 `0.1s ~ 0.15s` 到达波峰，形成自然跟随感 |

## 2. Claude 标准四步闭环工作流

### 第一步：先用测量脚本读取图片真实像素边界（严禁盲猜坐标）

在写任何 JSON 前，先运行内置的图像解剖测量工具：

```bash
python3 addons/ai_rig_2d/tools/inspect_sprite.py assets/sprites/<character>.png
```

脚本会输出非透明像素包围盒 `non_transparent_bbox`、重心坐标 `center_of_mass`、推荐骨骼初始坐标 `suggested_bones_rest` 和推荐部件裁切框 `suggested_rigid_parts_slices`。

### 第二步：选择正确的渲染与变形模式

| 模式名称 | 适用资产 | `render_settings` 推荐配置 | 关键规则 |
| ----- | ----- | ----- | ----- |
| **像素防糊部件模式 (`rigid_parts`)** | 64×64 等低分辨率像素整图 | `"pixel_art_mode": true, "integer_pixel_snap": true, "nearest_neighbor": true, "deform_mode": "rigid_parts"` | `parts` 中只填 `name`、`bone`、`region_rect`、`z_index`，**不填 `offset`**（由插件自动对齐关节）；动画用 `"interpolation": "nearest"`，仅用 `1~3px` 的 `"dp"` 位移 |
| **自动网格权重模式 (`mesh_weights`)** | 高分辨率整身立绘 (256×256+) | `"pixel_art_mode": false, "integer_pixel_snap": false, "nearest_neighbor": false, "deform_mode": "mesh_weights"` | `provider.grid_size` 设为 `[12, 16]`，`weights.mode` 设为 `"auto_envelope"`；动画用 `"interpolation": "cubic"`，可结合 `"dp"`、`"drot_deg"` 与 `"dscale"` |

### 第三步：使用相对增量 (`dp` / `drot_deg` / `dscale`) 与标准动作配方 K 帧

* **位移轨道 (`position`)**：写 `{ "t": 0.4, "dp": [0, 1] }`（代表在 Rest 位置基础上 `Y + 1` 像素），静止帧永远是 `{ "t": 0.0, "dp": [0, 0] }`。
* **旋转轨道 (`rotation_deg`)**：写 `{ "t": 0.5, "drot_deg": -3.5 }`（代表在 Rest 角度基础上旋转 `-3.5°`），静止帧永远是 `{ "t": 0.0, "drot_deg": 0.0 }`。
* **缩放轨道 (`scale`)**：写 `{ "t": 0.5, "dscale": [1.02, 0.98] }`（代表在 Rest 缩放基础上乘以该系数），静止帧永远是 `{ "t": 0.0, "dscale": [1.0, 1.0] }`。
* **循环闭合与相位差**：当 `"loop": true` 时，`t = 0.0` 与 `t = length` 的值必须完全一致；子骨骼峰值时间比父骨骼推迟 `0.1s ~ 0.15s`。

### 第四步：运行 Headless CLI 校验并检查物理防崩坏警告

```bash
godot --headless --path . -s addons/ai_rig_2d/validate_rig.gd -- res://rigs/<character>.json --build
```

v1.1 校验器会自动检测并输出三类 AI 专属警告，Claude 必须将警告清零：

* `SANITY_WARN`：检测到骨骼位移超出骨骼长度 2 倍，或误用 `"v": [0, 0]` 导致子骨骼塌缩到父骨骼原点。
* `PIXEL_ART_WARN`：检测到在 `pixel_art_mode: true` 下使用了非 90° 倍数的微小旋转（会导致像素锯齿断裂）。
* `LOOP_WARN`：检测到循环动画首尾关键帧数值不一致（会导致循环跳帧）。
