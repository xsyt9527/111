# TASK-023 开发提示

按 `TASK_MANIFEST.json` 的三个 step 顺序实现；每个 step 完成后先自检再进入下一步。

## step-01 地图位置与雷达绘制
- `scenes/Main.tscn`：把 `XiaoDiTuUI/XiaoDiTu` 从左上 `(24,210)-(264,386)` 移到右上「设置」按钮 `(1168,12)-(1248,44)` 下方，目标矩形 `(1008,52)-(1248,212)`；图例 TuLi 保持在面板底部。
- `scripts/xiao_di_tu.gd`：删除 `DI_TU_WEN_LI` 海图 preload 与贴图绘制；保留 `DI_TU_QU` 九宫格映射和四类亮点绘制；面板底改半透明深色，网格线进一步淡化，当前房间亮框保留。**不要加旋转扫描线**。

## step-02 透明度设置与持久化
- `scripts/she_zhi.gd`：在 `SheZhiMianBan/MianBanLie` 中插入 `DiTuTouMingLie`（HBoxContainer：`DiTuTouMingLabel` + `DiTuTouMingHua` HSlider + `DiTuTouMingZhi` 百分比 Label），范围 0.3~1.0、步长 0.05、默认 0.85；`value_changed` 时写 `CunDang.xiao_di_tu_tou_ming`、调用 `XiaoDiTu.she_tou_ming_du(zhi)`；`drag_ended` 时调用 `CunDang.xie_she_zhi()` 落盘。
- `scripts/cun_dang.gd`：`xiao_di_tu_tou_ming` 已存在；补 `zai_ru_she_zhi` 读取可选键 `xiao_di_tu_tou_ming`（缺省 0.85、clamp 0.3~1.0）与 `xie_she_zhi` 写回该键；`SHE_ZHI_BAN_BEN` 保持 1，旧档缺键不算损坏。

## step-03 测试/门禁/文档
- `tests/ce_panding.gd` 只追加断言：地图矩形在设置按钮下方、不再 preload 海图、雷达常量、透明度范围/夹取/键名。
- 依次运行：
  - `headless --import`
  - `tests/pao_pi.bat`
  - `PYTHONUTF8=1 python .agents/skills/godot-guided-feature-workflow/scripts/validate_task.py docs/development_tasks/TASK-023_lei_da_xiao_di_tu`
  - `PYTHONUTF8=1 python .agents/skills/godot-guided-feature-workflow/scripts/check_task_scope.py check docs/development_tasks/TASK-023_lei_da_xiao_di_tu`
- 更新 `docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`，写实现报告，清理临时探针与截图。

## 全局约束
- 所有新增自定义名用拼音 + 中文注释。
- 不改攻击/掉落/体型数值，不改局内存档 schema，不新增 Autoload。
- 不 commit、不 push。
