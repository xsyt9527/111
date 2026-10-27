# TASK-011 交接说明（INTEGRATION_HANDOFF）

> 状态：ready（交付完成）

## 交付物

| 文件 | 作用 |
|---|---|
| `scenes/YaoGan.tscn` + `scripts/yao_gan.gd` | 左下角虚拟摇杆：半径 120 / 头 50 / 死区 15 / 多点触控；只输出归一化 `fang_xiang` |
| `scripts/main.gd` | 每帧转发方向；体型数字刷新；debug 构建的 WASD/方向键（键盘按下覆盖摇杆） |
| `scripts/yu.gd` | 朝向角 + 转向速率（`zhuanxiang_ji_su / tixing`）；速度趋近平滑；×1.1 吞噬门槛；体型即血量（×0.85，<0.5 死亡）；屏幕边界 |
| `scenes/Main.tscn` | 新增 `UI/YaoGan`、`TiXingUI/TiXingLabel`；移除 `XueLiangTiao` |
| `tests/ce_yao_gan.gd` | 摇杆纯逻辑 8 断言 |
| `tests/ce_panding.gd` | 判定集成 13 断言（吃/伤/中间带/1.09 边界/死亡） |
| `tests/pao_pi.bat` | 六步门禁，68 条断言 |
| 已删除 | `scenes/XueLiangTiao.tscn`、`scripts/xue_liang_ui.gd`、`scripts/xue_liang_ui.gd.uid` |

## 提供给后续任务的接口

- **完整方向出口**：`YaoGan.fang_xiang`（单位向量 / 零向量），TASK-012 的咬击瞄准可直接复用同一输入。
- **调参唯一入口**：`Yu.TUN_CHI_BEI_LV`（1.1）、`Yu.SHANG_HAI_BEI_LV`（0.85）、`Yu.TI_XING_SI_WANG`（0.5）、`zhuanxiang_ji_su`（4.0）、`jia_su_du`（900）。
- **体型显示锚点**：`Main/TiXingUI/TiXingLabel`，TASK-013 的饥饿条/控制条可挂在同一 CanvasLayer 或新建同层节点。
- **已退役清单**：`mubiao_dian` / `TINGZHI_JULI` 点击移动链路；`zuida_xue` / `xue_liang` / `xue_liang_bian_hua` / `XueLiangTiao` 血条链路。后续不要复活。
- **死亡入口**：`Yu._si_wang()` → `res://scenes/JieSuan.tscn`，TASK-017 终局扩展从这里接。

## 场景树（交付后）

```text
Main (Node2D, main.gd)
├── Haodi (Sprite2D)
├── Yu (Yu.tscn, yu.gd)
│   ├── Sprite2D
│   ├── ZuiQu (Area2D) → 吃
│   ├── ShangQu (Area2D) → 掉体型
│   ├── ChiQu (Area2D) → 磁吸标记
│   └── WudiDingshi (Timer)
├── YuQun (Node2D, yu_qun.gd)
│   └── Dingshi (Timer)
├── JingYanTiao (CanvasLayer) → 经验条 + 等级
├── TiXingUI (CanvasLayer)
│   └── TiXingLabel (Label) → 「体型 1.00」
├── UI (CanvasLayer)
│   └── YaoGan (Control, yao_gan.gd)
└── QiangHuaDanChuang (CanvasLayer) → 三选一（TASK-014 退役）
```

## 已知限制 / 后续任务注意

- **中间带无事发生**：0.9~1.1 区间本课不吃不伤，TASK-012 补咬击后才完整。
- **NPC 仍是整鱼单碰撞体**：撞任意部位都伤到玩家，这是临时替身；TASK-012 拆嘴/身部位。
- **体型 / 升级并存**：短期「升级长大」与「受伤缩小」都改 `tixing`，TASK-014 统一成长体系。
- **Tween 叠加**：三处 Tween 同时写 `scale`，见 CODE_REVIEW P3-1，TASK-012 处理。
- **摇杆中心不随窗口变化**：见 P3-3，TASK-010 真机验证优先修。
- **吸附圈判定未随门槛更新**：见 P3-2，TASK-012 一并改。
- **真机触控未验证**：本轮只有桌面鼠标模拟触摸，TASK-010 负责。
- **地图包未导入**：`q2d_twilight_zone_9tiles_3x3_seamless_maps.zip` 仍在 Downloads，TASK-016 导入。

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1 生成/审批）
- [x] headless 导入零错误
- [x] ce_yao_gan / ce_panding 退出码 0，pao_pi.bat 六步全绿（68 断言）
- [x] F5 全量回归（移动 / 摇杆 / 吞噬 / 受伤 / 死亡 / 升级 / 三选一 / 结算重开）
- [x] 学生 godot-inspection 完成
- [x] 学生 verification-handoff 完成
- [x] 三份报告（IMPLEMENTATION / VERIFICATION / CODE_REVIEW）完成
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
- [ ] TASK-010（安卓导出）恢复并排期（下一课）
