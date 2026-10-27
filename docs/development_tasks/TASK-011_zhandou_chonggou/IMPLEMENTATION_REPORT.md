# TASK-011 实现报告（IMPLEMENTATION_REPORT）

## 交付概览

零期 A 四步全部完成：**点击移动 → 虚拟摇杆 + 转向模型**；**严格大于 → ×1.1 吞噬门槛**；**独立血条 → 体型即血量**；测试同步扩到 **六步 68 条断言**。同时退役两条旧链路（`mubiao_dian` 点击移动、血条三件套），并应学生要求补了仅 debug 生效的 WASD 调试输入。

| 指标 | 结果 |
|---|---|
| 门禁 | `tests/pao_pi.bat` 六步全绿，68 条断言（9 + 11 + 27 + 8 + 13） |
| 主场景无头运行 | 180 帧，0 error / 0 not found |
| 产品文件 | 新增 2（摇杆场景 + 脚本）、修改 6、删除 3（血条场景/脚本/uid） |
| 范围检查 | `check_task_scope.py check`：0 violation |
| 学生验证 | F5、编辑器检查、检查器数值、WASD 全部通过 |

## 分步明细

### step-01 虚拟摇杆 + 转向模型

| 文件 | 内容 |
|---|---|
| `scenes/YaoGan.tscn` + `scripts/yao_gan.gd` | `Control` 全屏铺底、`mouse_filter=IGNORE`；`_draw()` 画底板（半径 120）与摇杆头（半径 50）；`_unhandled_input` 处理 `ScreenTouch` / `ScreenDrag`，按下范围 1.6×半径；偏移限幅、死区 15、归一化 `fang_xiang`；松手归零；记录手指编号，多点触控不串手 |
| `scripts/main.gd` | 删除 `_unhandled_input` / `_gengxin_mubiao`；每帧 `yu.fang_xiang = _du_qu_fang_xiang()` |
| `scripts/yu.gd` | 删除 `mubiao_dian` / `TINGZHI_JULI`；新增 `dang_qian_jiao`、`dang_qian_su_du`、`zhuanxiang_ji_su`、`jia_su_du`；`_process` 分三层：速度趋近 → 朝向限步长 → 沿朝向前进；`_zhuan_xiang()` 用 `wrapf` 取最短差角、`clampf` 限步长；`_xian_zhi_zai_ping_mu_nei()` 留 30px 边距 |
| `scenes/Main.tscn` | 新增 `UI` CanvasLayer 与 `UI/YaoGan` 实例 |

转向速率：`(zhuanxiang_ji_su / maxf(tixing, 0.2)) * delta`。体型 1.0 → 4 rad/s；体型 2.0 → 2 rad/s；体型越大越笨重。

### step-02 吞噬门槛 ×1.1

| 判定 | 条件 |
|---|---|
| 整吞 | `我的 tixing ≥ 对方 tixing × 1.1` |
| 受伤 | `对方 tixing ≥ 我的 tixing × 1.1` |
| 中间带 | 其余情况：不吃、不伤（咬击留给 TASK-012） |

同步把 `tests/ce_panding.gd` 的「同体型掉血」断言改为「同体型落在中间带」。

**红了一次**：首版伤区写成「对方 ×1.1 > 我」，同体型 `1.0×1.1=1.1 > 1.0` 被误判受伤。门禁抓住，改为「对方 ≥ 我 ×1.1」后转绿。

### step-03 体型即血量 + 体型显示 + 死亡判定

| 项 | 变化 |
|---|---|
| 受伤 | `tixing *= 0.85`（`SHANG_HAI_BEI_LV`），0.25 秒缩小 tween |
| 死亡 | `tixing < 0.5`（`TI_XING_SI_WANG`）→ `JieSuan.tscn` |
| 删除字段 | `zuida_xue`、`xue_liang` |
| 删除信号 | `xue_liang_bian_hua` |
| 删除场景/脚本 | `scenes/XueLiangTiao.tscn`、`scripts/xue_liang_ui.gd`、`.uid` |
| Main UI | 移除血条实例；新增 `TiXingUI/TiXingLabel`，每帧显示「体型 %.2f」 |

删除血条场景/脚本是执行中追加的范围变更：只删字段会导致 `xue_liang_ui.gd` 强类型引用失配，成为无法解析的死代码；必须三层一起退役。已记录在 `SCOPE_PROPOSAL.md`「执行中范围变更」。

### step-04 测试更新与全量回归

| 文件 | 内容 |
|---|---|
| `tests/ce_yao_gan.gd`（新） | 8 条断言：超半径限幅、方向归一化、死区、松手归零、多点触控不串手 |
| `tests/ce_panding.gd` | 13 条断言：吃小鱼、大鱼掉体型、无敌不重复、中间带、1.09 边界、死亡线；死亡用例放最后并先抓住 SceneTree 引用 |
| `tests/pao_pi.bat` | 扩为六步，步骤编号 1/6 ~ 6/6 |
| `scripts/main.gd` | 学生验收追加 WASD/方向键（仅 `OS.is_debug_build()`；键盘按下覆盖摇杆） |

## 关键设计决策

1. **输入层与运动层分离**：摇杆只输出单位方向，速度与转向由玩家按体型计算。以后换手柄/键鼠/自动寻路，只改输入层。
2. **点 → 方向**：坐标点可以瞬间改，朝向只能按步长拧，这是「大鱼笨重」的实现基础。
3. **门槛对称**：吃与伤用同一个 ×1.1，只是比较方向相反，中间带自然留白。
4. **体型三合一**：体积、吞噬资格、生命值共用一个数，受伤即变小、变小即更危险，不需要独立血条。
5. **退役三层**：字段 → 信号 → 场景/脚本，少删一层就留死代码。

## 遗留

- NPC 仍是整鱼单碰撞体，撞任意部位都会伤到玩家——TASK-012 拆嘴/身部位并改为咬击。
- 中间带目前无事发生——TASK-012 补咬击后才有「咬小再吃」。
- 地图包仍在 Downloads——TASK-016 导入。
- 安卓导出 TASK-010 在本课完成后恢复。
