# TASK-018 学习记录：局外形态解锁

> 状态：**实现完成，学习未开始（`not_started`）**。本文件不替用户填写掌握证据；F5 手测与检查点参与后再回填。

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 复述局外存档与局内账本的分工 | 待回填（`not_started`） |
| 2 | 解释形态为什么必须在切 Main 之前应用 | 待回填（`not_started`） |
| 3 | 说出胜利解锁的完整时序 | 待回填（`not_started`） |
| 4 | 解释 JSON 损坏时为何只回退不覆盖 | 待回填（`not_started`） |
| 5 | 指出选择页、结算页、Main 三个入口各自负责什么 | 待回填（`not_started`） |
| 6 | 亲手完成一次门禁红绿并解释 ERROR 筛查 | 待回填（`not_started`） |

## 本课新概念

- 自定义 `Resource` 引用 `SpriteFrames` / `NengLi`
- 第二个 Autoload 与注册顺序
- `FileAccess` + JSON 存档与版本回退
- 持久进度与瞬时提示分离
- 子节点 `_ready` 顺序与开局装配
- 动态 `Control` 卡片与 `Button.disabled`
- 显式 `preload` 注册表 vs `DirAccess` 导出风险

## 实现期已完成的证据（非学习证据）

- 八步门禁 540 断言全绿，输出无 `ERROR`。
- Boss 死亡切场景的离树回归通过。
- 三个场景无头冒烟通过。
- 负速度红测变红并复原复绿。
- 坏 JSON / 版本不符 / 未知形态 / 未解锁形态回退测试通过。
- 上述均为自动测试证据，**不能替代学生复述与亲手操作**。

## 检查点与证据

### orientation（实现前）

待回填：学生需复述「局外进度为什么不能塞进 `ZhangBen.chong_zhi()`」「形态在切 Main 前应用的原因」。

### godot-inspection

待回填：建议在编辑器检查
- `XingTai` 三个 `.tres` 的字段与资源引用；
- `project.godot` 的 Autoload 顺序与主场景；
- `XingTaiXuanZe` 场景树与动态卡片；
- `JieSuan` 的 `HuanXingTai` / `JieSuoTiShi`。

### verification-handoff

待回填：建议 F5 验收
- 0 胜锁定状态；
- 三形态开局差异（等级/体型/速度/嘴巴/初始主动）；
- 胜利解锁提示与重启保持；
- 坏档回退无 `ERROR`；
- 再来一次 / 换形态。

## 遗留与移交

- 用户 F5 手测与学习验收未执行，`LEARNING_STATE.json` 保持 `not_started`。
- 待用户确认形态手感；数值调参入口见 `INTEGRATION_HANDOFF.md`。
- TASK-014 遗留旧场景 `scenes/QiangHuaDanChuang.tscn` 引用已退役资源，本任务范围外，建议后续清理。

## 课后题

（待学习验收时由用户作答后回填）
