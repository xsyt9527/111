# 深海食纪 — 项目协作规范（AGENTS.md）

肉鸽类大鱼吃小鱼游戏。目标平台：TapTap（Android）。引擎：Godot 4.7.2。

## 硬性要求

- 引擎版本锁 4.7：所有 Godot 验证须由 `Godot_v4.7.2-stable_win64.exe --version` 输出 4.7.x 认证。
  本机路径：`D:\001\Godot_v4.7.2-stable_win64.exe`（优先读环境变量 `GODOT_4_7_BIN`）。
- 本仓库是 Git 仓库：每个功能任务（TASK-NNN）实现前必须捕获实现基线，实现后做范围检查。
- 技能包位于 `.agents/skills/`，任务流程按 `godot-guided-feature-workflow` 执行：
  - 改 gameplay 代码前必须生成并审批任务包（`docs/development_tasks/TASK-NNN_*/`）。
  - 任务包脚本：`python .agents/skills/godot-guided-feature-workflow/scripts/validate_task.py <task-dir>`。

## 代码风格

- 自定义名（脚本文件、变量、函数、场景、节点）一律用**拼音**，代码注释一律用**中文**。
  例：`yu.gd`（玩家鱼）、`shengji()`（升级 upgrade level）、`YuQun`（鱼群 fish school）。
- Godot 内置 API、关键字、引擎概念保持英文原名。
- 每课新代码附「当课引擎词表」，统一收进 `docs/引擎词总表.md`（按文件分类）。

## 目录约定

```
project.godot          # 引擎配置
icon.svg
scenes/                # .tscn 场景
scripts/               # .gd 脚本
data/                  # .tres 数据资源（鱼种、buff 表）
assets/sucai/          # CC0 素材（Kenney Fish Pack 等）
docs/
  引擎词总表.md
  development_tasks/   # TASK-NNN 任务包
  PROJECT_STATUS_AUDIT.md
tests/                 # 无头测试（第 9 课起）
.agents/skills/        # 技能源（勿改）
```

## 教学约定

- 学生：已完成捡金币 7 课 + zwz 对照学习，正在 PVZ 解剖课阶段。
- 参与模式 guided_co_development：AI 主导实现，学生负责导航、有限设计选择（≤2 选 1）、
  编辑器检查、验证参与、解释与交接。
- 三个必需检查点：orientation / inspection / verification_handoff。
- 任务暂停时把恢复信息写全到 TASK_STATE.json，恢复只看状态文件不翻聊天记录。
