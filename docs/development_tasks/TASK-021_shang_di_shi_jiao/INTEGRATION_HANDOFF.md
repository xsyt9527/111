# TASK-021 集成交接

## 提供

- `XiaoDiTu`：只读 `player` / `yu_npc` / `zhi_wu` 组与 `Main.ji_qi_chuan`，绘制全图小地图。
- `YuQun.qie_huan_fang_jian(qu)`：换房安全补屏。
- `YuNpc._shan_hong()` / `JiQiChuan._shan_guang()`：白色受击闪光。
- `Main._qie_huan_fang_jian()`：入场 0.9 秒免伤。

## 约束

- 不改存档/数值/房间尺寸；小地图不写状态。
- `XiaoDiTuUI` 已加入 HUD 演出隐藏名单。
