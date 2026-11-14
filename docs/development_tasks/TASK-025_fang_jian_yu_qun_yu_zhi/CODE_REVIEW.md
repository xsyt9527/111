# 代码评审 — TASK-025 房间预置鱼群

评审日期：2026-11-14
范围：`scripts/yu_qun.gd`、`scripts/yu_npc.gd`、`scripts/xiao_di_tu.gd`、`scripts/main.gd`、`tests/ce_panding.gd`
基线：`bcc1f3dfe25267e4c4017946ee076bc7c5640899` + 工作区既有 TASK-022/023/024 未提交改动

## 一、结论

未发现阻断交付的缺陷。实现期间发现并修复了 2 个真实逻辑问题（`node == null` 记录被误删、树外夹具被「假玩家」推挤），另有 1 个测试引用数组对象的坑写进了回归用例注释。剩余风险集中在手机雷达帧率与实机手感，已列入验证报告等待 F5。

## 二、已修复问题

### 1. 停刷期换房会把未加载记录当死鱼删掉（真实缺陷）

- 位置：`scripts/yu_qun.gd:288-293`（`_bao_cun_dang_qian_fang_jian`）、`scripts/yu_qun.gd:401-403`（`_tong_bu_dang_qian_fang_jian`）
- 原逻辑：回写循环里 `node == null` 被当作死鱼直接 `remove_at`。
- 触发路径：`shua_xin_ting_zhi = true` 时换房只更新房号不加载；目标房记录全是 `node=null`，下一帧 `_tong_bu` 会把整房记录清空，雷达点全灭、之后加载无鱼。
- 修复：`node == null` 时 `continue` 原样保留；只有非 null 且 `not is_instance_valid` 或 `si_le` 才删除。
- 回归：`tests/ce_panding.gd:478-482`「停刷期换房：只保存/释放旧房，不加载目标房；未加载记录不能被同步逻辑当死鱼删掉」。

### 2. 树外测试夹具被「假玩家」推得满屋跑（测试可靠性）

- 位置：`scripts/yu_qun.gd:270-277`（`_zhao_wan_jia_wei`）、`scripts/yu_qun.gd:341-342`（`_an_quan_jia_zai_dian`）
- 原逻辑：取不到玩家时用房间中心兜底，`_an_quan` 会把每条记录推到离中心 240px 外；树外夹具没有真实玩家，断言位置/数量会漂移。
- 修复：无玩家返回 `Vector2(INF, INF)` 哨兵，`_an_quan` 用 `is_finite` 检查后跳过推挤；真实场景仍按玩家位置做 240px 贴脸保护（Main 已先把玩家夹进新房再调用）。
- 覆盖：贴脸保护用例与按记录位置加载用例。

### 3. 测试抓旧数组引用导致假失败（测试坑，已写注释）

- 位置：`tests/ce_panding.gd:463-464`
- `_dang_ti_tao_tai_he_bu_di()` 会替换 `_fang_jian_yu_qun[pian]` 的数组对象；测试若继续读调用前的 `ji_lu_1` 会看到旧数据。
- 处理：调用后重新 `ji_lu_1 = qun_an.fang_jian_ji_lu(1)`，并在用例里写明「档位刷新会换数组对象：按接口重新取，别抓旧引用」。

### 4. 临时探针把 CanvasLayer 当 Control（工具问题，非产品代码）

- 位置：`tests/_tmp_fang_jian_probe.gd`（已验证后删除）
- `NengLiDanChuang` / `JinHuaDanChuang` 根节点是 `CanvasLayer`；`as Control` 得到 `null`，机器人永远点不到三选一，游戏在 T≈18 秒暂停死锁。
- 修复：改为 `as CanvasLayer`；复跑后拿到完整胜利结果。此问题不影响仓库内任何正式脚本。

## 三、重点代码审阅

### 记录唯一权威（`_bao_cun` / `_tong_bu` / `_jia_zai`）

- 换房与每帧都把实体 `position / tixing / deng_ji_nei / jing_yan_nei / sudu / fangxiang` 回写记录；实体只是记录的可视化副本。
- `_jia_zai` 在 `add_child` 前写 `zai_ru_ti_xing`，`YuNpc._ready` 末尾应用，避免默认鱼种体型覆盖成长状态；树外夹具也成立。
- 位置夹回房内 40px，记录不会落在房外导致下次加载贴边/出屏。

### 清理边界

- `_bao_cun` 对账只遍历 `YuQun` 直接子节点且跳过 `shi_boss`；Main 下的鲸鲨 Boss、教学脚本预排布鱼不会被换房误杀。
- 相机出屏回收由 `you_yu_qun_guan_li` 关闭，改由 `_jia_zhu` 夹在 `fang_jian_qu.grow(60)` 内；教学鱼保持原回收行为。

### 未加载房模拟

- 0.25 秒一拍、最多补 8 拍，避免长时间卡顿后一次补太多；只改 Dictionary，不建节点。
- 互吃与当前房实体共用 `TUN_CHI_BEI_LV`、`NPC_HU_CHI_BAN_JING`、`NPC_HU_CHI_GAI_LV` 与 `ShengJiBiao` 同一张曲线，不出现两套数值。
- 档位淘汰 `maxi(1, floor(size*0.2))`，保底 `maxi(8, int(上限*0.6))`，空房会在档位节拍补回，不会灭绝。

### 测试真实性

- 旧欢迎鱼/安全入口断言是整体删除，不是注释掉或改宽；新用例逐条断言记录数、位置、节点、成长、互吃、档位、停刷。
- 雷达既有图例断言未动；`_hu_npc` 的记录优先 + 未托管鱼补扫两条路径都有覆盖。
- 门禁 1236 条 `ce_panding` 全绿，任务校验 VALID，范围检查 0 violation。

## 四、残余风险（不阻断）

| 风险 | 说明 | 建议 |
|---|---|---|
| 手机雷达帧率 | 每帧约 315~405 个点（压力 +2 时 9×45=405） | F5 真机观察；掉帧则把 `XiaoDiTu._process` 降为 30Hz |
| 未加载房减员观感 | 20 秒 35% 互吃 + 每档淘汰 20%，保底 60% | 只调 `WEI_JIA_ZAI_BAO_DI_BI_LI` / `DANG_WEI_TAO_TAI_BI_LI`，不动玩家平衡 |
| 贴脸保护落点 | 玩家贴房角时可能退到最远象限中心 | F5 看换房落点是否突兀；必要时加「优先沿房内长轴推开」 |
| 停刷期目标房无实体 | 保留旧行为，雷达仍画记录点 | 若用户要决战期也有实体，另开任务 |
| 机器人参考值 | 3 倍速、上限操作、全图目标 | 仅作下限参考，最终以用户 F5 拍板 |

## 五、结论

- 实现与用户确认口径一致：不整批刷新、九房预置、雷达九格、未加载房互吃、当前房保留定时补鱼。
- 无需改玩家/普通鱼数值、无需改存档或主场景结构。
- 建议交付状态：`review`（自动门禁全绿，F5 人工验收待用户）。
