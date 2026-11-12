# TASK-020 范围提案（SCOPE_PROPOSAL）

## 范围内

- **房间数据与相机边界**：`main.gd` 新增 `dang_qian_fang_jian := 4`、`fang_jian_qu(pian) -> Rect2`、`qu_yu_pian(shijie_wei) -> int`；普通探索期把 `Camera2D` 的 `limit_left/top/right/bottom` 锁到当前 1376×768 房间。
- **换房过渡**：玩家越过格边界时 0.12 秒淡出 → 黑场中更新房间、相机 limit、`reset_smoothing()`、把玩家夹回新房 6px 内、调用 `YuQun.qie_huan_fang_jian(rect)` → 0.12 秒淡入；过渡期间锁输入；用现有 `_xian_shi_xiao_xi()` 显示房间名。
- **刷怪归属**：`yu_qun.gd` 新增 `fang_jian_qu` 与 `qie_huan_fang_jian(rect)`；刷怪/回收改用当前房间矩形；换房清掉旧房普通鱼并重置刷怪计时；不触碰 `Boss`/植物/经验球。
- **Boss 房**：鲸鲨出生点与巡逻点全部收进东南房间 8（2752–4128 / 1536–2304），不再跨九格巡逻。
- **人类战特例**：`yan_chu_zhong` 或 `ji_qi_chuan` 有效时恢复全图 limit，并设置 `offset=(0,-260)`、`zoom=0.85`，确保上方机器船与预警可见；九图拼合演出与现有流程保持不动。
- **测试与文档**：`ce_panding` 追加房间纯函数用例（房间矩形、越界判定、切房目标、相机 limit）；八步门禁、范围检查、引擎词总表、学习路线、docx、任务包报告。

## 范围外（移交后续任务）

- 门锁、钥匙、顺序封印、房间小地图 → 新任务
- 无缝滚动、相邻房间预加载 → 新任务
- 重切背景美术、新增房间图层/资源 → 新任务
- 房间进度写入存档、Boss 破房规则 → 新任务
- 技能范围/体型/船战伤害/红光/相机 1.0 常量 → TASK-019 已拥有

## 零触碰清单

- `.agents/skills/**`（只读）
- `tests/` 既有文件不得删除（只能向 `ce_panding.gd` 追加房间用例）
- `scripts/zhang_ben.gd`、`scripts/yu_npc.gd`、`scripts/ji_qi_chuan.gd`、`scripts/zhan_dou.gd`、`scripts/ji_neng_fan_wei.gd`（TASK-019 所有）
- `scripts/di_tu_pin_jie_yan_chu.gd` 的九图切片与演出流程
- `project.godot`、Autoload、存档 schema、主场景顶层节点类型
- 上一轮 33 张主动图标及其 `data/nengli/*.tres` 既有改动（不覆盖、不回滚）

## 白名单要点

- 修改（已跟踪）：`scripts/main.gd`、`scenes/Main.tscn`、`scripts/yu_qun.gd`、`tests/ce_panding.gd`、`docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`。
- 新增：本任务包与实现报告。
- 生成物：`.godot/**` 导入缓存。

## 设计约束（审批时一并确认）

1. **只切逻辑房间**：九个房间是同一张 4128×2304 背景上的 9 个 Rect2，不新增美术、不改存档。
2. **换房必须有黑场**：0.12 秒淡出 + 0.12 秒淡入；黑场中才更新房间/limit/夹玩家，避免一帧跳变与反复越界。
3. **先切房再夹回**：玩家越界后夹到新房 6px 内，否则会在边界反复触发换房。
4. **Boss 独立于 YuQun**：换房清普通鱼不得清 Boss；Boss 固定东南房间 8。
5. **人类战是全图例外**：九图演出/机器船战期间恢复全图 limit 与 offset/zoom，结束后可保持全图直到切场景。
6. **暂不做门锁/无缝滚动**：本轮只验证“地图一个一个”的最小可玩版。
7. **交付不 commit**：最终记 `delivery_status=review`、`handoff_status=pending`、`last_verified_commit=null`。

## 执行中范围变更

（暂无）

## 执行中范围变更

### 2026-11-10 · TASK-019 并行任务包白名单登记（只登记，不并入 TASK-020）

TASK-019 与 TASK-020 是同一轮批准的两个独立任务，各有任务包与基线。TASK-020 的任务包创建/收口晚于 TASK-019，`git status` 会把 TASK-019 的四个任务包文件视为 untracked；为保证 scope check 能区分「已批准的并行任务包」与「越界文件」，把 `docs/development_tasks/TASK-019_ti_xing_zhan_dou_fan_wei/**` 加入 `allowed_new_files`。

只作跨任务识别：TASK-020 的实现与验收仍只包含九宫格房间/相机/换房/刷怪，不包含 TASK-019 的体型、范围、船战或红光改动。
