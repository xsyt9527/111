# TASK-029 学习记录

状态：`not_started`（等待用户批准 v1）

## 学习目标

1. 能解释为什么布局用「纯函数算位置，再让节点照结果摆放」，而不是在 `_process` 里边跑边试。
2. 能说明手动咬击与自动咬击为什么必须共用同一把冷却尺。
3. 能定位攻击键在「冷却中 / 冲撞中 / 失控 / 演出中」被拒绝的原因分别来自哪段代码。
4. 能说明代码生成按钮为什么不改 `Main.tscn`。

## 参与式检查点

### 1. orientation（开工前项目导航）

- 证据类型: `project_navigation` + `concept_explanation`
- 证据槽: 待填写
- 提示问题: 「主动技能按钮现在是在哪个脚本、哪个函数里摆放的？数量从哪来？」

### 2. godot-inspection（编辑器/场景树检查）

- 证据类型: `editor_operation` + `scene_tree_inspection`
- 证据槽: 待填写
- 提示问题: 「`Main.tscn` 的 `NengLiUI` 下有哪些节点？运行后代码生成了哪些子节点？」

### 3. verification-handoff（验证与交接）

- 证据类型: `test_execution` + `result_interpretation`
- 证据槽: 待填写
- 提示问题: 「布局用例里哪个断言能证明 20 个主动也不溢出屏幕？」

## 学习词表

| 拼音 | 引擎词 | 含义 |
|---|---|---|
| `ji_neng_bu_ju` | layout function | 数量 + 视口 → 位置/尺寸 |
| `jing_xiang` | mirror | 左右翻转坐标 |
| `yao_ji_shou_dong` | manual attack | 手动咬击入口 |
| `tong_yi_leng_que` | shared cooldown | 单一冷却来源 |
| `dai_ma_sheng_cheng` | code-generated UI | 脚本创建节点 |
| `StyleBoxFlat` | StyleBoxFlat | 圆角绘制按钮皮肤 |

## 结果摘要

（实现期填写：用户实际看到了什么、学到了什么、有哪些还没吃透的点。）
