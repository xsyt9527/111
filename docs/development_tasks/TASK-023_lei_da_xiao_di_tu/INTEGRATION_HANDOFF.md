# TASK-023 集成交接

## 主线
- 小地图从左上移到右上「设置」按钮下方。
- 小地图改为无海图背景的雷达式绘制：半透明深色面板、淡化九宫格、四类亮点不变。
- 设置面板新增地图透明度滑条，持久化到游玩设置 JSON。

## 对外接口
- `XiaoDiTu.she_tou_ming_du(zhi)`：接收 0.3~1.0，内部夹取并 `queue_redraw()`。
- `CunDang.xiao_di_tu_tou_ming`：默认 0.85；对应 `user://shenhaishiji_shezhi.json` 的 `xiao_di_tu_tou_ming` 键；`SHE_ZHI_BAN_BEN` 不变。
- `SheZhi.DiTuTouMingHua`：设置主面板中的滑条行（HSlider），运行时创建。

## 依赖
- 复用 TASK-021 的九宫格房间数据与 `Main.dang_qian_fang_jian`。
- 复用 TASK-022 的小地图黑底/金色首领标记与玩家面板结构。
- 不新增信号、不新增 Autoload、不改局内存档 schema。

## 验证
- `headless --import` 退出码 0。
- `tests/pao_pi.bat` 八步全绿。
- `validate_task.py` 输出 `VALID: TASK-023 v1 (plan_driven)`。
- `check_task_scope.py check` 零违规。
- F5：小地图位置/雷达观感/透明度即时生效/重启保持。

## 2026-11-13 实测结果
- 八步门禁：232 / 25 / 1422 / 8 / 20 / 144 / 1287 passed，合计 3138 断言，0 failed，无 ERROR，脚本输出「全绿：可以交付」。
- `validate_task.py`：`VALID: TASK-023 v1 (plan_driven)`；`check_task_scope.py check`：0 violation。
- 实现报告：`IMPLEMENTATION_REPORT.md`。
- F5 目检与红测仍待用户；未 commit、未 push。
