# TASK-002 学习记录：鱼群生成与屏幕外回收

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 定位 YuNpc.tscn / yu_npc.gd / yu_qun.gd 与 Main 的 YuQun 子树，说出职责 | orientation 导航 ✅ |
| 2 | 解释「生成器管何时/从哪/多快；NPC 管长相/移动/回收」的分工 | orientation 设计决策 ✅ |
| 3 | 解释随机数、Timer.timeout、get_viewport_rect、queue_free | 概念随代码讲解，口头复述待巩固 |
| 4 | 调参数并 F5 验证，用 Remote 面板解释节点增减 | verification 亲测 ✅ |

## 本课新概念

1. **随机数**：`randf_range(a, b)` 取小数区间，`Array.pick_random()` 随机元素；Godot 4 启动自动播种，无需 `randomize()`
2. **Timer 节点 + timeout 信号**：定时器到点发信号；`one_shot=true` 每次手动 `start()`，配合随机重排实现"密度起伏"
3. **get_viewport_rect()**：运行时视口尺寸，不把 1280×720 写死在代码里
4. **queue_free() 与生命周期**：动态节点用完后必须释放，否则节点越积越多

## 检查点与证据

### orientation（实现前，2026-10-21）

- [x] 学生能指出三个新文件与 Main 中的 YuQun 子树（AI 讲解后随设计决策确认理解）
- [x] 学生说明分工理由（重启场景只改生成器、换外形只改 NPC）
- [x] 设计决策 1：**随机间隔生成**（学生选定推荐项）
- [x] 设计决策 2：**NPC 在 _ready 自行决定随机外观**（学生选定推荐项）

### godot-inspection（实现后，2026-10-22）

- [x] 打开 Main.tscn 确认 YuQun → Dingshi 子树（one_shot）
- [x] 检查器操作实证：把 `Zuida Shuliang` 改为 2 做实验（留痕 Main.tscn，收尾已还原）
- [x] YuNpc 贴图数组与体型范围确认

### verification-handoff（2026-10-22）

- [x] F5 亲测：**"从两侧游入，数量稳定"**（学生原话）
- [x] 上限实验生效（同屏最多 2 条）
- [ ] 口头说出一处排查位置——未做，记入待巩固

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| 2026-10-21 | orientation | 两个设计决策均选推荐方案并理解理由 | — |
| 2026-10-22 | inspection + verification | 亲测两侧游入、数量稳定；检查器调参实证 | ~~口头复述排查思路、queue_free~~ **两项已于课后口头作答完成**：排查顺序答对（Output 优先）；queue_free 后果两猜全中（卡 + 上限卡死不再生成），已记 explained 级证据 |
