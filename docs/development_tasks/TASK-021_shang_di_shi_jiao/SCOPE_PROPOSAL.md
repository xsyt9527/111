# TASK-021 范围提案（SCOPE_PROPOSAL）

## 范围内

- **上帝视角小地图**：新增 `scripts/xiao_di_tu.gd`（Control），用 `beijing_3x3.webp` 整图缩放到 240×134，同时在 `Main.tscn` 新增独立 `XiaoDiTuUI` CanvasLayer；标题「上帝视角（永久被动）」；黑点=首领/机械船、蓝点=玩家、红点=NPC 鱼、绿点=珊瑚海草。
- **受击闪白**：`YuNpc._shan_hong()` 与 `JiQiChuan._shan_guang()` 改为明显过曝白闪光；玩家保持原受伤红闪。
- **换房安全入场**：`YuQun.qie_huan_fang_jian()` 先放一批玩家可吃的小鱼，常规鱼从远离玩家的一侧进入；大鱼入口与玩家保持安全距离；`Main` 换房后给 0.9 秒免伤。
- **测试与文档**：追加 `ce_panding` 小地图映射/安全距离用例；更新引擎词表、任务索引、学习路线、docx、实现报告。

## 范围外（碰了即越界）

- 改 TASK-019 体型/伤害/范围数值、TASK-020 房间尺寸与相机 limit。
- 改 Boss 出生点/巡逻、人类战流程、九图拼合演出。
- 改存档 schema、Autoload、`project.godot`。
- 删除或重写 `tests/` 既有断言。
- commit / push（发布走用户单独授权流程）。

## 允许改动文件

- 已存在：`scripts/main.gd`、`scripts/yu_qun.gd`、`scripts/yu_npc.gd`、`scripts/ji_qi_chuan.gd`、`scenes/Main.tscn`、`tests/ce_panding.gd`、`docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`。
- 新增：`scripts/xiao_di_tu.gd`、本任务包目录；TASK-019/TASK-020 目录只做跨任务识别，不改内容。

## 设计确认点

1. 小地图只读组与 Main 引用，不复制游戏状态、不写存档。
2. 九宫格用同一张整图缩放 + 网格线，不新增九张贴图。
3. 受击闪白只改 `modulate`，不改伤害/血量/体型。
4. 换房保留原等级分布和同屏上限，只改生成位置、补屏顺序与入场保护。
5. 小地图在九图演出时随 HUD 隐藏。
6. 所有新代码拼音命名 + 中文注释。
