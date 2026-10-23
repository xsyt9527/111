# 项目状态审计 — 深海食纪

> 第五次审计（第 5 课前），生成于 2026-10-23。

## 审计新鲜度

```yaml
audited_commit: 4ca0582   # TASK-004 状态关闭提交，工作区干净
environment_checked_at: 2026-10-23T00:30:00Z
engine_executable_source: common_path   # D:\001\Godot_v4.7.2-stable_win64.exe
engine_version_detected: 4.7.2          # 4.7.2.stable.official.ed1daf0bf
audit_invalidation_triggers:
  - project.godot 结构性修改（Autoload/主场景/输入映射/插件）——本课将注册 Autoload，属已审批的结构变更
  - 引擎版本变化
  - 新增或变更共享配置、存档结构、事件总线、数据资源
  - 任何 TASK 基线 commit 变化后未重新审计受影响区域
```

## 工程状态清单

| 系统 | 状态 | 证据 |
|---|---|---|
| Git 仓库 | ✅ 干净，HEAD `4ca0582` | `git status --porcelain` 为空 |
| project.godot | ✅ 主场景 Main.tscn；**无 Autoload**——本课首次引入（已列入任务包 registered_shared_changes） | TASK-004 后未动 |
| 场景 scenes/ | ✅ Main（Haodi + Yu + YuQun 注册表 + Dingshi）、Yu（判定/无敌）、YuNpc（检测区） | TASK-004 交付 |
| 脚本 scripts/ | ✅ main.gd、yu.gd、yu_npc.gd（yu_zhong 注入）、yu_qun.gd、yu_zhong.gd | TASK-004 交付 |
| 数据 data/ | ✅ 6 个鱼种 .tres（含 fenzhi/dengji 字段，**暂无消费者**） | TASK-004 交付 |
| UI | **Missing**（本课引入首个 UI：经验条；模态 UI 属第 6 课） | — |
| 测试 tests/ | **Missing**（第 9 课启用） | — |
| 任务流程 | ✅ TASK-001~004 全关闭 | `last_verified_commit=93e7b08` |

### 运行行为现状（实测基线）

- F5：鱼群 6 种外观成套生成；玩家吃小鱼（鱼消失）、撞大鱼闪红 1 秒无敌
- **被吃的鱼只是消失——无经验、无成长**（`bei_chi()` 入口预留挂钩点，本课启用）
- `Yu.tixing` 恒为 1.0（第 3 课埋的接口，只读未写）

## 已知遗留（本课消费/延续）

- `YuZhong.fenzhi`/`dengji`：TASK-004 存好数据无消费者——本课 `bei_chi()` 读取记账
- `Yu.tixing`：本课首次写入（升级长大），判定圈随根节点 scale 自动变大（第 3 课已验证的机制）
- stash 中有一份 TASK-004 重复手写版备份（已确认等价），不影响开发

无行为对照工程（development_strategy=plan_driven）。

## 推荐的接下来三个有界任务（按依赖和学习价值排序）

1. **TASK-005 经验与成长**（本审计选定）：Autoload 游戏账本（经验/等级/升级阈值）+
   `bei_chi()` 记账（消费 fenzhi）+ 升级信号驱动 `Yu.tixing` 长大 + 经验条 UI（CanvasLayer/ProgressBar）。
2. **TASK-006 升级三选一**：升级暂停 → 3 张随机强化卡（复用第 4 课注册表模式做卡表）。
3. **TASK-007 强化生效与动画**：buff 落地（含学生自己发明的磁吸双 Area2D）+ Tween。

## 结论

三个挂钩点（`bei_chi()` / `Yu.tixing` / `fenzhi`）在第 3、4 课全部挖好，本课让它们会师：吃鱼→记账→升级→长大→能吃的鱼变多——肉鸽成长循环的第一环正式转动。
