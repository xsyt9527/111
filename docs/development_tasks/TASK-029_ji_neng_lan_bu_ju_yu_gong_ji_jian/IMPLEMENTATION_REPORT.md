# TASK-029 实现报告

- 任务：主动技能栏自适应布局 + 右下角手动攻击键（共用冷却）
- 实现日期：2026-11-15
- 基线：`f27ae56893aed50db99ca6572659966bbca09b27`（`check_task_scope.py capture` 已记录）
- 结论：功能实现完成，测试断言已加入 `tests/ce_panding.gd`；门禁数字见 `VERIFICATION_REPORT.md`

## 一、改动文件

| 文件 | 改动 | 说明 |
|---|---|---|
| `scripts/neng_li_ui.gd` | +217 行 | 自适应布局纯函数、按钮组重建、手动攻击键创建/皮肤/状态刷新、镜像换边 |
| `scripts/yu.gd` | 复核（+75 行中含 026/TASK-029 入口） | `yao_ji_shou_dong()` 入口由 TASK-026 收尾一并落实，签名/语义符合本包规格，本包不再重复改 |
| `tests/ce_panding.gd` | 新增用例 6zg / 6zh | 布局纯函数断言 + 手动攻击键与统一冷却断言 |
| `docs/development_tasks/TASK-029_.../` | 任务包 + 三份报告 | 本文件及验证/审查报告、`TASK_STATE.json` 收尾 |

未改 `Main.tscn` / `project.godot`；未新增音效键；未动 026/027/028 的源码域。

## 二、技能栏自适应布局（step-01）

### 常量（`scripts/neng_li_ui.gd:7-21`）

```gdscript
const AN_NIU_KUAN := 210.0   # 1~2 列时按钮宽
const AN_NIU_GAO := 64.0     # 1 行 1 个时按钮高
const AN_NIU_JIAN_JU := 8.0  # 按钮间距
const DI_BU_Y := 680.0       # 最底一个按钮下缘
const MEI_LIE_ZUI_DUO := 5   # 每列最多 5 个
const ZUI_DUO_LIE := 4       # 最多 4 列
const YOU_YUAN := 1250.0     # 默认按钮组右缘
const ZUO_YUAN := 30.0       # 换右手摇杆后的镜像左缘
const GONG_JI_AN_NIU_CAI := 96.0
const GONG_JI_AN_NIU_JIAN_JU := 8.0
const BEI_DONG_LABEL_X := 900.0
```

### 纯函数 `ji_neng_bu_ju(shu, shi_kou, you_yuan=1146.0, yao_gan_ce="zuo", zuo_yuan=134.0)`

- 列数：`lie_shu = clampi(ceili(shu / 5), 1, 4)`；每列行数：`mei_lie = ceili(shu / lie_shu)`。
- 行距/按钮高：`mei_lie >= 4` → 52/44；`>= 2` → 60/52；否则 72/64。
- 按钮宽：`lie_shu <= 2` → 210；`3` → 168；`>= 4` → 132。
- 第 0 个在右下，同列自下而上；排满一列向左开新列（列距 = 按钮宽 + 8）。
- 摇杆在右手侧时按「距右缘的距离换成距左缘的距离」整体镜像。
- 结果再做一次 `clampf` 兜底，极端数量/小视口也不出屏。
- 不读节点、不依赖 `self` 状态，测试可直接 `load(...).new()` 后调用。

### 按钮组重建 `_tong_bu_an_niu(shu)`

- 数量或摇杆侧变化才重建（`_shang_ci_shu` / `_shang_ci_ce` 缓存）。
- 技能组右缘让出攻击键位：`you_yuan = 1250 - 96 - 8 = 1146`；换边后左缘 `zuo_yuan = 30 + 96 + 8 = 134`。
- 每个按钮 `focus_mode = FOCUS_NONE`（代码生成按钮默认 `FOCUS_ALL`，否则空格/回车误触发）。
- 字号按按钮高 22/18/15；图标上限 44/32/24，`expand_icon = true` 才让 `icon_max_width` 生效。
- 重建时清空长按状态与范围显示，避免旧下标指到新按钮。
- 被动标签跟随换边：默认贴右缘 900 右对齐；换边后贴左缘 30 左对齐。

## 三、手动攻击键（step-02）

### 生成与皮肤

- `_bao_zheng_gong_ji_an_niu(ce)` 懒创建一次，后续只更新位置；节点名 `GongJiAnNiu`，不写进场景文件。
- 96×96，默认位置 `(1154, 584)`（右缘 1250、下缘 680）；换右手侧镜像到左缘 30。
- `StyleBoxFlat` 圆形皮肤：圆角半径 48、暗红底 + 金色描边；按下态更深、悬停更亮。
- `pressed` → `_on_gong_ji_an_niu_pressed()`：按组找 `player`，有 `yao_ji_shou_dong()` 就调用；没有入口时忽略点击，不报错。

### 状态刷新 `_geng_xin_gong_ji_an_niu(wan)`

- 入口未接入（`has_method("yao_ji_shou_dong")` 为假）：禁用并显示「咬 / 待接入」。
- 冷却中：显示「咬 %.1fs」并按剩余秒数变暗（`Color(0.62,0.62,0.62,0.85)`）。
- 就绪：显示「咬 / 就绪」，`modulate = Color.WHITE`。

### 统一冷却（`scripts/yu.gd:1971-1998`）

```gdscript
func yao_ji_shou_dong() -> bool:
	if _yao_ji_leng_que > 0.0 or _chong_zhuang_sheng_yu > 0.0 \
			or ZhangBen.zai_kong_zhi() or yan_chu_kong_zhi:
		return false
	return _chang_shi_yao_ji()
```

- 与自动咬共用同一把 `_yao_ji_leng_que`。
- 空挥由 `_chang_shi_yao_ji()` 返回 `false` 且不进入冷却。
- 咬中/鲸鲨咬不动等既有结算路径保持原语义；按钮只读返回值，不重复结算伤害。

## 四、测试（step-03）

- `tests/ce_panding.gd` 用例 6zg：`ji_neng_bu_ju` 在 1/5/10/11/20 个下的列数、行数、尺寸、屏内、互不重叠、换边镜像与攻击键位置。
- `tests/ce_panding.gd` 用例 6zh：空挥/冷却/冲撞/失控/九图演出锁拒绝，咬中返回 true、进入与自动咬相同冷却、伤害结算一致。
- 断言边界显式重置 `_yao_ji_leng_que`、`_chong_zhuang_sheng_yu`、`ZhangBen.yun_xuan_ji_shi`，避免跨用例串味。

## 五、偏差与说明

1. `ji_neng_bu_ju` 实际签名比 `DEVELOPMENT_PROMPT.md` 多了带默认值的 `you_yuan` / `yao_gan_ce` / `zuo_yuan`，为让攻击键占位与镜像逻辑可测；旧两参数调用仍兼容。
2. `yao_ji_shou_dong()` 由 TASK-026 收尾一并写入 `yu.gd`，登录点与规格一致；本包复核后不再重复实现，避免双入口。
3. 观察（未改）：手动按钮按下时 `_zuan_tu_sheng_yu > 0` 未进拒绝条件（自动咬在钻突期不可达，手动按钮可触发）。属行为边界，留 F5 评估；若判定要做，另开小任务统一。

未 commit、未 push。
