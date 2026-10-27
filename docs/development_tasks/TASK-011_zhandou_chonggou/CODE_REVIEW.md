# TASK-011 代码评审（CODE_REVIEW）

评审范围：`scripts/yao_gan.gd`、`scripts/main.gd`、`scripts/yu.gd`、`scenes/YaoGan.tscn`、`scenes/Main.tscn`、`tests/ce_yao_gan.gd`、`tests/ce_panding.gd`、`tests/pao_pi.bat`，以及血条三件套的删除。**无 P1 / P2 问题**；P3 备忘 9 条，其中 2 条建议并入 TASK-012。

## P3 备忘

### 1. 三处 Tween 同时写 `scale`，后写者覆盖先写者

`_on_sheng_ji()`（0.8s 长大）、`_tun_chi_maichong()`（0.08s + 0.12s 脉冲）、`_shou_shang_tween()`（0.25s 缩小）各自 `create_tween()` 改同一个 `scale`。**失败场景**：吞吃脉冲 0.2 秒内被大鱼撞到，受伤 tween 与脉冲 tween 同时运行，最终缩到哪个值取决于处理顺序；脉冲第二段还会用受伤前捕获的旧 `tixing` 收尾，鱼会先弹回旧大小再缩。**建议**：保存 `var _da_xiao_tween: Tween`，新建前 `kill()`；或统一走 `_she_zhi_ti_xing()` 一个入口。移交 TASK-012（咬击会带来更多体型变化）。

### 2. 吸附圈仍用旧判定，中间带鱼会被吸却吃不到

`_on_chi_qu_entered` 条件是 `tixing > yu_npc.tixing`，而吃需要 `tixing ≥ 对方 ×1.1`。**失败场景**：玩家 1.0，0.95 倍鱼进入吸附圈被拉向玩家，进嘴后却吞不掉，玩家感觉「磁铁失效」。**建议**：与吞噬门槛统一为 `tixing >= yu_npc.tixing * TUN_CHI_BEI_LV`。移交 TASK-012 一并调。

### 3. 摇杆中心只在 `_ready` 计算一次

`YaoGan._ready()` 用 `get_viewport_rect().size` 定左下角。**失败场景**：Android 旋转、桌面窗口缩放、分屏后，摇杆仍画在旧位置，触摸判定也跟着偏。**建议**：连接 `get_viewport().size_changed` 重算中心并 `queue_redraw()`。TASK-010 真机验证时优先处理。

### 4. Main 每帧刷新 Label 字符串

`ti_xing_label.text = "体型 %.2f" % yu.tixing` 每帧分配一次字符串。开销很小，但属无谓分配；可缓存上次值，变化时才刷新。

### 5. 屏幕边距固定 30px，未随体型缩放

`_xian_zhi_zai_ping_mu_nei()` 用 30px 边距。体型 3.0 时鱼身半径约 66px，中心贴边会有一半出屏。**建议**：`bian_ju = 30.0 * tixing`。等 TASK-016 镜头缩放上线后再统一处理。

### 6. 死亡用例直接调私有入口，且跳过切场景断言

`ce_panding` 用例 6 直接 `yu._shoushang()` 并立即收卷，只验证「跌破 0.5」，没有验证 `JieSuan.tscn` 真的加载。**失败场景**：将来 `_si_wang()` 路径写错（比如场景路径改名），测试仍绿。**建议**：给 `_si_wang()` 加一个 `si_wang` 信号供测试观察，或拆出独立死亡测试场景。移交 TASK-012。

### 7. `maxf(tixing, 0.2)` 的魔法数重复两次

`_process` 摆尾与 `_zhuan_xiang` 各写一次 0.2。若将来死亡阈值调低到 0.2 以下，这个保护会掩盖真实的除零风险。**建议**：抽 `const ZUI_XIAO_TI_XING := 0.2` 并注释「仅防除零，不是玩法下限」。

### 8. 死亡当帧仍创建缩小 Tween

`_shoushang()` 先 `_shou_shang_tween()` 再判断死亡；死亡时 Tween 创建后场景立即销毁，白做一次。可把死亡判断提前，或在 `_si_wang()` 后 `return`。

### 9. 键盘调试输入的构建期判断

`OS.is_debug_build()` 在编辑器与 debug 导出为 true；如果将来出「内测 release 包」想留键盘调试，需要改成显式开关。当前符合「正式版只认摇杆」的预期，记录备查。

## 历史 P3 兑现

- **push_warning vs error 复述**（第 9 课遗留）→ orientation 开场复考通过，清账。
- **UI/Tween 无自动化断言**（TASK-009 P3-1）→ 仍未覆盖，本课新增三处 Tween 叠加风险（见 P3-1），优先级上升。

## 过程教训（本课自纠错）

| # | 事故 | 教训 |
|---|---|---|
| 1 | 伤区门槛乘法方向写反（`对方×1.1 > 我`） | 对称规则要写成「A ≥ B × 系数」同一方向，别两边各乘一次；门禁当场抓住 |
| 2 | 摇杆测试按下点超出判定范围 | 测输入先算清「判定半径 × 容错倍数」，别凭感觉给坐标 |
| 3 | 死亡测试 `get_tree()` 为 null | 会切场景的测试，先抓 `SceneTree` 引用；`Results` 全绿不等于无错，ERROR 筛查是第二只眼 |
| 4 | 删字段后血条脚本变成死代码 | 退役要三层一起：字段 → 信号 → 场景/脚本；只删一层会留解析地雷 |

## 好的部分（记录强化）

- **输入层与运动层彻底分开**：摇杆只回答方向，鱼自己算转速与速度；WASD、手柄、自动寻路都能插进来。
- **门槛对称**：吃与伤共用 `TUN_CHI_BEI_LV`，规则只有一个数，调参不会两边打架。
- **体型三合一**：一个 `tixing` 同时驱动体积、吞噬资格、生命值，危机可视化，代码也少一套血量状态。
- **退役干净**：`mubiao_dian` 链路与血条三件套全删，`grep` 无残留引用，Main 场景树同步清理。
- **测试同步**：产品行为一改，断言当步就跟；68 条断言覆盖摇杆纯逻辑 + 判定集成 + 死亡线。
- **学生参与落到代码**：WASD 调试键来自学生验收需求，且用 `OS.is_debug_build()` 隔离，不进正式包。
