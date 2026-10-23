# 项目状态审计 — 深海食纪

> 第六次审计（第 6 课前），生成于 2026-10-23。

## 审计新鲜度

```yaml
audited_commit: 26b6a84   # TASK-005 课后题补记提交，工作区干净
environment_checked_at: 2026-10-23T02:40:00Z
engine_executable_source: common_path   # D:\001\Godot_v4.7.2-stable_win64.exe
engine_version_detected: 4.7.2          # 4.7.2.stable.official.ed1daf0bf（本审计实测）
audit_invalidation_triggers:
  - project.godot 结构性修改（Autoload/主场景/输入映射/插件）——本课零触碰
  - 引擎版本变化
  - 新增或变更共享配置、存档结构、事件总线、数据资源——本课新增强化卡/阈值表 .tres，属已审批登记
  - 任何 TASK 基线 commit 变化后未重新审计受影响区域
```

## 工程状态清单

| 区域 | 状态 | 来源 |
|---|---|---|
| 引擎与导入 | ✅ headless --import 退出码 0（本审计实测）；360 帧运行退出码 0 | 2026-10-23 复测 |
| 脚本 scripts/ | ✅ main.gd、yu.gd（听 sheng_ji 长大）、yu_npc.gd（bei_chi 记账）、yu_qun.gd、yu_zhong.gd、zhang_ben.gd（**首个 Autoload**）、jing_yan_ui.gd | TASK-005 交付 |
| 数据 data/ | ✅ 6 个鱼种 .tres（fenzhi 已有消费者：bei_chi 记账） | TASK-004/005 |
| UI | ✅ 经验条（CanvasLayer + ProgressBar）；**模态弹窗 Missing**（本课引入：三选一） | TASK-005 |
| 测试 tests/ | **Missing**（第 9 课启用） | — |
| 任务流程 | ✅ TASK-001~005 全关闭（005 last_verified_commit=1fb3c89） | `26b6a84` |

### 运行行为现状（实测基线）

- F5：鱼群 6 种成套生成；吃鱼涨经验（蓝 +1、棕 +5）；攒满升级——玩家瞬间变大、判定圈变大、条清零重计、Lv 跳变
- 升级只长大**不暂停**——无三选一、无 buff（本课引入暂停 + 弹窗 + 选卡入账）
- `SHENG_JI_YUZHI` 仍是 zhang_ben.gd 常量（本课数据化为 .tres，等值切换）

## 已知遗留（本课消费/延续）

- `sheng_ji` 信号已有两家听众（yu.gd/jing_yan_ui.gd）——弹窗做第三家，验证信号解耦
- `SHENG_JI_YUZHI` 常量（TASK-005 P3 备忘指名本课数据化）
- 强化效果系统整体 Missing（第 7 课：消费 xiao_guo/shu_zhi；磁吸 = 学生第 3 课提案）
- 满级处理（Lv.7+）待决策（P3 备忘）
- stash 中 TASK-004 重复备份（已确认等价），不影响开发

无行为对照工程（development_strategy=plan_driven）。

## 推荐的接下来三个有界任务（按依赖和学习价值排序）

1. **TASK-006 升级三选一**（本审计选定）：强化卡注册表（复用第 4 课模式）+ get_tree().paused + 不放回抽样 + 三选一弹窗 + 选卡入账（ka_yi_xuan 信号预埋）。
2. **TASK-007 强化生效与动画**：连接 ka_yi_xuan 消费 xiao_guo/shu_zhi（含磁吸双 Area2D）+ Tween 动效。
3. **TASK-008 血量、死亡与结算**：账本重置 chong_zhi() 配套（第 5 课 P3 备忘）。

## 结论

成长循环已转动（吃→账→级→大），缺的是肉鸽的灵魂——**选择的节拍**。本课把升级瞬间变成决策点：冻结、弹卡、点选、继续；卡池走注册表模式（加卡零代码），选卡入账走账本模式（第 7 课一行 connect 即生效）。两大已验证模式在本课会师。
