# INTEGRATION_HANDOFF · TASK-025

> 状态：`handoff_status = pending`（交接文档内容已就绪；因未 commit、F5 人工验收待用户，按契约暂不声明 `ready`）。

## 1. 功能目的与归属

- 目的：取消换房时清空旧房并整批补满的行为；九宫格每房预置固定数量鱼群记录，进房按记录位置与成长状态加载；雷达显示九房 NPC 点；未加载房后台轻量模拟游动与互吃。
- 归属：`student-01`，owned scripts 为 `scripts/yu_qun.gd`、`scripts/yu_npc.gd`、`scripts/xiao_di_tu.gd`、`scripts/main.gd`。

## 2. 运行入口

- 主场景 `res://scenes/Main.tscn`。
- `Main._ready` 调 `yu_qun.qie_huan_fang_jian(fang_jian_qu(dang_qian_fang_jian), dang_qian_fang_jian)`。
- `Main._qie_huan_fang_jian` 换房时调 `yu_qun.qie_huan_fang_jian(qu, dang_qian_fang_jian)`。
- `YuQun._ready` 只启动 `Dingshi`；九房在首次 `qie_huan_fang_jian` 时惰性初始化。

## 3. 输入与消费接口

- `Main.dang_qian_fang_jian`、`Main.fang_jian_qu(pian)`、`Main.qu_yu_pian(wei)`。
- `YuQun._chou_yu_zhong()`、`dang_qian_shang_xian()`、`Dingshi`、`_hu_chi_ju_ding()`。
- `YuNpc` 字段：`tixing`、`sudu`、`fangxiang`、`deng_ji_nei`、`jing_yan_nei`、`si_le`、`shi_boss`、`_ying_she_ti_xing()`。
- `ShengJiBiao` 隐藏经验升级阈值。
- 雷达：`XiaoDiTu._qu_zhu_jie_mian`、`_dao_di_tu`、`_hua_dian`。

## 4. 输出与提供接口

- `YuQun.qie_huan_fang_jian(qu: Rect2, pian: int = -1)`：单参调用兼容，房号缺省自动推算。
- `YuQun.fang_jian_ji_lu(pian: int) -> Array`：返回该房内部记录数组，调用方只读、不修改、不保存引用。
- `YuQun.qu_pian(qu: Rect2) -> int`：房间矩形 → 房号 0..8。
- `YuQun._chu_shi_hua_jiu_fang()`：测试可显式初始化九房。
- `YuNpc.you_yu_qun_guan_li: bool`：`true` 表示由鱼群托管、关闭相机出屏回收。
- `YuNpc.zai_ru_ti_xing(ti: float, nei_deng: int, nei_jing_yan: int)`：`add_child` 前写入恢复载荷，`_ready` 末尾应用。
- 无新增全局信号。

## 5. 状态归属与持久化

- 九房鱼群记录只存在 `YuQun` 单局内，不写存档、不新增 Autoload、不跨进程保留。
- 记录是唯一权威：当前房实体每帧回写记录；换房时保存并释放实体，再按目标房记录加载。
- Main 下的鲸鲨 Boss、机械船与教学脚本预排布鱼不属于记录，不得被换房清理误杀。

## 6. 关键场景、脚本、配置与测试

- `scripts/yu_qun.gd`：记录层、初始化、保存/加载、虚拟游动/互吃/档位保底、`fang_jian_ji_lu()`。
- `scripts/yu_npc.gd`：`you_yu_qun_guan_li`、恢复载荷、出屏回收开关。
- `scripts/xiao_di_tu.gd`：`_hu_npc()` 读九房记录，当前房/其他房大小亮度区分，补画未托管普通鱼。
- `scripts/main.gd`：两处换房调用传房号。
- `tests/ce_panding.gd`：九房初始化、保存加载、成长恢复、全局节拍、贴脸保护、虚拟互吃、档位保底、雷达、停刷冻结。
  - 九房用例从原 303–402 行旧欢迎鱼/安全入口断言改写而来，约 170 行。
  - 单独运行：`1236 passed, 0 failed`；完整门禁同为 1236 passed。
- 配置：无新增；`project.godot` 不改。
- 报告：`IMPLEMENTATION_REPORT.md`、`VERIFICATION_REPORT.md`、`CODE_REVIEW.md`。

## 7. 集成流程

1. 确认 `TASK-025` 的 `check_task_scope.py check` 零违规。
2. 合入 `scripts/` 四个文件与 `tests/ce_panding.gd`，同一提交保持接口一致。
3. 运行 `MSYS_NO_PATHCONV=1 cmd.exe /c "tests\\pao_pi.bat"`，八步全绿。
4. F5 检查：九格红点、换房位置延续、未加载房红点变化、当前房补鱼节奏、图例文本。
5. 更新 `TASK_STATE.json` 的 `last_verified_commit` 与 `handoff_status`。

## 8. 禁止直接访问与冲突热点

- 禁止按 `yu_npc` 组全表清理；只能遍历 `YuQun` 直接子节点对账。
- 禁止绕过 `_sheng_yu` 直接 instantiate 普通 NPC，否则记录会漏登记。
- 禁止在 `_ready` 默认值之后才应用恢复载荷，否则体型/隐藏成长被覆盖。
- 禁止换房时重置 `_hu_chi_ji_shi`，全局 20 秒互吃节拍必须跨房连续。
- 冲突热点：`yu_qun.gd` 与 TASK-020 换房逻辑、`yu_npc.gd` 与 TASK-019/024 AI 改动、`xiao_di_tu.gd` 与 TASK-023 雷达绘制、`ce_panding.gd` 旧换房断言。

## 9. 必需集成检查与最新验证基线

- `validate_task.py`：`VALID: TASK-025 v1 (plan_driven)`。
- headless `--import`：退出码 0，0 ERROR。
- `tests/pao_pi.bat`：八步全绿，232 / 25 / 1422 / 8 / 20 / 144 / 1236，合计 3087 断言，0 failed，脚本输出「全绿：可以交付」。
- `check_task_scope.py check`：0 violation（8 allowed / 214 unchanged pre-existing）。
- 机器人自动通关探针（临时，已删除）：`RESULT=SHENG_LI`，576.9 秒，Lv.19，体型峰值 30.0，九房全部访问，34 次换房；船 517.4 秒出现（1140 HP），59.5 秒击沉。
- 最新基线：提交仍为 `bcc1f3dfe25267e4c4017946ee076bc7c5640899`；本任务改动未 commit、未 push，`last_verified_commit` 保持 null。

## 10. 已知限制与待参与事项

- 未加载房保底比例 60%、虚拟互吃 35% 的手感需要 F5 与真机观察。
- 雷达每帧约 315~405 个点（压力 +2 时 9×45=405），手机帧率需真机确认；必要时降为 30Hz 重绘。
- 未加载房不参与玩家技能判定（`di_ren_lie()` 只扫实体），这是设计口径。
- 停刷期换房只换房号、不加载目标房实体；雷达仍画记录点。若需要决战期也有实体鱼，另开任务。
- 学生参与检查点 `orientation`、`godot-inspection`、`verification-handoff` 尚未发生；`learning_status = not_started`。
- **未 commit、未 push**；F5 人工验收与红测由用户执行。
