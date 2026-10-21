# TASK-002 学习记录：鱼群生成与屏幕外回收

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 定位 YuNpc.tscn / yu_npc.gd / yu_qun.gd 与 Main 的 YuQun 子树，说出职责 | orientation 导航 |
| 2 | 解释「生成器管何时/从哪/多快；NPC 管长相/移动/回收」的分工 | orientation 口头说明 |
| 3 | 解释随机数、Timer.timeout、get_viewport_rect、queue_free | 检查点问答 |
| 4 | 调参数并 F5 验证，用 Remote 面板解释节点增减 | verification 参与 |

## 本课新概念

1. **随机数**：`randf_range(a, b)` 取小数区间，`Array.pick_random()` 随机元素；Godot 4 启动自动播种，无需 `randomize()`
2. **Timer 节点 + timeout 信号**：定时器到点发信号，比每帧数秒更省更清晰；`one_shot=true` 每次手动 `start()`
3. **get_viewport_rect()**：运行时视口尺寸，不把 1280×720 写死在代码里
4. **queue_free() 与生命周期**：动态节点用完后必须释放，否则节点越积越多

## 检查点与证据

### orientation（实现前）

- [ ] 学生能指出三个新文件与 Main 中的 YuQun 子树
- [ ] 学生说明分工理由（重启场景只改生成器、换外形只改 NPC）
- [ ] 学生完成二选一设计决策：**随机间隔**（推荐，生态感）vs **固定间隔**
- 记录：待填写

### godot-inspection（实现后）

- [ ] 打开 Main.tscn，确认 YuQun → Dingshi 子树，Timer 为 one_shot
- [ ] 检查器看到 YuQun 的四个 @export、YuNpc 的贴图数组与体型范围
- [ ] Remote 面板运行中看到 YuNpc 节点在增删
- 记录：待填写

### verification-handoff（验证）

- [ ] F5 亲测：两侧游入、随机外观、出屏消失
- [ ] 调 `zuida_shuliang` / 间隔观察差异并还原
- [ ] 能说出至少一处排查位置（如"信号没连看 Output"）
- 记录：待填写

## 学习记录表

| 日期 | 检查点 | 表现 | 待巩固 |
|---|---|---|---|
| — | — | 待第 2 课实现后填写 | — |
