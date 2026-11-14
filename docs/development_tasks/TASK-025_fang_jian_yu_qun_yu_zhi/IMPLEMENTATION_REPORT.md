# 实现报告 — TASK-025 房间预置鱼群：取消换房整批刷新

任务包：`docs/development_tasks/TASK-025_fang_jian_yu_qun_yu_zhi/`
审批：v1（2026-11-14 13:43:26 +08:00，用户原文见 `TASK_MANIFEST.json` / `TASK_STATE.json`）
基线提交：`bcc1f3dfe25267e4c4017946ee076bc7c5640899`（工作区含 TASK-022/023/024 的既有未提交改动）
策划案基线：v0.27，mtime 2026-11-09 22:09，md5 `2db7aa25b6a1424eb9cb38d20255c8f7`（本任务未改策划案）

## 一、用户目标

原换房流程是「世界重置」：`Main._qie_huan_fang_jian` 调 `YuQun.qie_huan_fang_jian(qu)` 后，旧房普通鱼全部释放，再从房边补满 35 条，玩家每次跨房看到一批全新鱼。用户要求：

1. 禁掉跨房整批刷新。
2. 九个房间开局各预置固定数量「未加载」的鱼记录。
3. 雷达小地图能看到其他房间的 NPC 鱼红点。
4. 跨房时按对应记录的位置加载鱼。
5. 未加载房也要模拟 NPC 互吃，雷达上能看到点移动、消失、变大。

已确认口径：

- 后台不按固定配额持续补鱼；当前房保留原有 `Dingshi` 每 0.6~1.8 秒一条的补鱼节奏。
- 未加载房每 20 秒档位提升时淘汰最小约 20%，从房边补同数量当前档新鱼；互吃优先锁最小鱼。
- 雷达当前房点稍大稍亮，其他房略小略暗。

## 二、实现

### 1. 九房记录数据层（`scripts/yu_qun.gd`）

新增字段与常量：

- `_fang_jian_yu_qun: Array`：9 项，每项一个 `Array[Dictionary]`，是九房鱼群的唯一权威数据。
- `_dang_qian_fang_jian := -1`：当前房号；首次换房时由 `Main` 传入。
- `FANG_JIAN_CHI_CUN := Vector2(1376, 768)`、`JIU_FANG_SHU := 9`、`FANG_JIAN_NEI_BIAN_JU := 40`、`FANG_JIAN_WAI_BIAN_JU := 60`、`JIA_ZAI_AN_QUAN_JIAN_JU := 240`、`XU_NI_YOU_DONG_JIAN_GE := 0.25`、`DANG_WEI_TAO_TAI_BI_LI := 0.2`、`WEI_JIA_ZAI_BAO_DI_BI_LI := 0.6`。

每条记录：

```gdscript
{
    "zhong": YuZhong,      # 鱼种资源
    "wei": Vector2,        # 世界坐标
    "fang": float,         # 朝向 ±1
    "su": float,           # 游速
    "ti": float,           # 当前体型（含被咬/成长后的值）
    "nei_deng": int,       # 隐藏等级（恢复成长用）
    "nei_jing_yan": int,   # 隐藏经验
    "node": YuNpc,         # 已加载实体；未加载为 null
}
```

- `_ready()` 不再 deferred 补满 35 条，只连接 `Dingshi` 并排第一轮。
- 首次 `qie_huan_fang_jian` 时 `_chu_shi_hua_jiu_fang()` 惰性初始化：9 房各按 `dang_qian_shang_xian()`（0 压力 35 条，±2 压力 25~45 条）生成记录，位置在各自房间 40px 边距内，未加载房不建节点。
- 新增只读接口 `qu_pian(qu)`、`fang_jian_qu_an(pian)`、`fang_jian_ji_lu(pian)`。`fang_jian_ji_lu` 直接返回内部数组，约定调用方不修改、不保存引用。

### 2. 换房保存/加载（替换清场 + 欢迎鱼）

`qie_huan_fang_jian(qu, pian = -1)` 固定顺序：

1. 解析/夹取房号 → 首次懒初始化九房。
2. `_bao_cun_dang_qian_fang_jian()`：实体状态回写记录（位置夹回房内 40px、体型、隐藏等级/经验、游速、朝向）；死亡/失效节点删除记录；`remove_child + queue_free` 后把记录 `node` 置空。只对账 `YuQun` 直接子节点，不按 `yu_npc` 组全表清理，避免误杀 Main 下的鲸鲨 Boss 和教学脚本预排布鱼。
3. 更新 `fang_jian_qu` 与 `_dang_qian_fang_jian`，`_da_yu_ji_shi` 归零；全局 `_hu_chi_ji_shi` 不归零（20 秒互吃节拍跨房连续）。
4. 停刷期（`shua_xin_ting_zhi`）到此 return：只换房号与房间矩形，不加载。
5. `_jia_zai_fang_jian(pian, 玩家位置)`：逐条实例化，先写鱼种/游速/朝向/位置/恢复载荷，再 `add_child`；离玩家 <240px 沿远离方向推开并夹回房内，仍不够远则退到最远象限中心；记录 `node` 指回实例。
6. `_kai_xia_yi_lun()` 重排 `Dingshi`。

删除旧换房欢迎鱼与安全入口逻辑：`_chong_tian_an_quan`、`_chong_tian_yu_qun`、`_fang_huan_ying_xiao_yu`、`ru_chang_xiao_yu_deng_ji`、`_chou_xiao_yu_zhong`、`an_quan_fang_nei_dian`、`an_quan_chu_kou`、`huan_chong_hui_shou_xian`、`_wan_jia_ti_xing` 及其专用常量。

### 3. 实体归鱼群管理（`scripts/yu_npc.gd`）

- 新增 `you_yu_qun_guan_li := false`；YuQun 生成/加载的鱼置 `true`，关闭 `_process` 的相机出屏回收，改为由 `_jia_zhu_dang_qian_fang_jian()` 每帧夹在 `fang_jian_qu.grow(60)` 内，越界翻转朝向。
- 新增恢复载荷 `zai_ru_ti_xing(ti, nei_deng, nei_jing_yan)`；`_ready` 末尾检测载荷并覆盖鱼种默认 `tixing / tixing_chu_shi / deng_ji_nei / jing_yan_nei`，重算 `gan_zhi` 并 `_ying_she_ti_xing()`。这样不依赖 `add_child` 时父节点是否在树里，树外测试夹具也不会被 `_ready` 默认值覆盖。

### 4. 未加载房模拟（`scripts/yu_qun.gd`）

- 虚拟游动：`_xu_ni_you_dong` 每 0.25 秒一拍，只改 Dictionary；感知到更小鱼就靠近，否则直线游，碰房边反弹，记录始终留在房内 40px 边距。
- 虚拟互吃：`_geng_xin_hu_chi` 每 20 秒同一拍先处理当前房实体 `_hu_chi_ju_ding()`，再 `_xu_ni_hu_chi()` 处理 8 个未加载房。规则：同房 140px、体型 ≥ 对方 ×1.1、35% 概率；**体型最小优先、距离次之**；吃方按猎物 `fenzhi` 加隐藏经验，按 `ShengJiBiao` 同表升级可能 +1 体型；被吃记录删除。当前房实体互吃的猎物选择同步改为最小优先，落实「留下来的小鱼先被锁敌」。
- 档位刷新：全局 20 秒档位上升时 `_dang_ti_tao_tai_he_bu_di()` 对 8 个未加载房各淘汰最小约 20%，从房边补同数量当前档新鱼；若数量低于保底 `maxi(8, int(上限×0.6))` 则补到保底。后台不做固定配额持续补鱼。
- 当前房 `Dingshi` 补鱼经 `_sheng_yu` 统一登记记录；`_dangqian_yu_shu()` 仍按 YuNpc 子节点数判断上限。

### 5. 雷达（`scripts/xiao_di_tu.gd`）

- `_hu_npc()` 优先读 `Main.yu_qun.fang_jian_ji_lu(pian)` 的九房记录：当前房半径 `clampf(1.8 + 0.15*ti, 1.8, 2.6)`、正常红；其他房 `clampf(1.3 + 0.1*ti, 1.3, 1.9)`、alpha 0.72。
- 记录画完后补扫 `yu_npc` 组，只画 `you_yu_qun_guan_li != true` 的非 Boss 鱼（教学鱼/临时鱼）。Boss 金点与图例文本不变。

### 6. Main 接线（`scripts/main.gd`）

- `_ready` 第 101 行：`yu_qun.qie_huan_fang_jian(fang_jian_qu(dang_qian_fang_jian), dang_qian_fang_jian)`。
- `_qie_huan_fang_jian` 第 502 行：`yu_qun.qie_huan_fang_jian(qu, dang_qian_fang_jian)`。
- 玩家在新房中的位置先行夹回，再调用鱼群加载，贴脸保护以玩家新位置为准。

## 三、测试（`tests/ce_panding.gd`）

- 删除旧欢迎鱼/安全落点/安全入口/选种/补屏/换房清场断言，改写为「实体释放、记录保留、目标房按记录加载」。
- 新增「用例 0b2：九房预置鱼群（TASK-025）」约 170 行，覆盖：
  - `qu_pian` 边界、`fang_jian_qu_an(4)`、未初始化 `fang_jian_ji_lu` 空数组；
  - 9 房各 35 条记录、40px 边距、无节点；`fang_jian_ji_lu(-1/99)` 夹取；
  - 旧单参换房兼容、按记录位置加载、`you_yu_qun_guan_li` 标记；
  - 4↔8 来回换房位置延续、记录保留、旧房 node 清空；
  - 成长载荷 3.0 / 2 / 7 恢复不被 `_ready` 覆盖；
  - `_hu_chi_ji_shi` 跨房连续、`_da_yu_ji_shi` 归零；
  - 贴脸保护 ≥240px 且仍在房内 40px 边距；
  - 虚拟互吃强制概率 1.0：最小鱼被优先吃、中等鱼保留、吃方经验 >0；
  - 档位淘汰最小 20% 并补到 21 条；空房补到保底；
  - 停刷期虚拟游动/互吃/档位刷新冻结、生成拒绝；停刷期换房只换房号不加载、记录不被清空。
- 沿用既有断言：`ce_panding` 165–201、2471–2474、2481–2491、2502–2507 的雷达/图例断言未改；图例仍为 `金 首领 · 蓝 玩家 · 红 鱼 · 绿 植物`。

## 四、门禁结果

2026-11-14 完整八步门禁 `tests/pao_pi.bat`：

```text
[1/8] import            pass（0 ERROR）
[2/8] ce_zhang_ben      232 passed, 0 failed
[3/8] ce_bian_jie       25 passed, 0 failed
[4/8] ce_shu_ju         1422 passed, 0 failed
[5/8] ce_yao_gan        8 passed, 0 failed
[6/8] ce_zhan_dou       20 passed, 0 failed
[7/8] ce_jie_suo        144 passed, 0 failed
[8/8] ce_panding        1236 passed, 0 failed
输出：全绿：可以交付
```

合计 3087 条断言。与 TASK-024 的 3138 条相比净减 51 条：删除换房欢迎鱼/安全入口旧断言，新增 TASK-025 九房用例；没有留下假绿。

`tests/ce_panding.gd` 单独运行也是 `1236 passed, 0 failed`（一次历史偶发「气泡吸引半径」补间一帧漂移，复跑归零，与本任务改动无关）。

## 五、机器人自动通关实测（临时探针，已删除）

探针文件 `tests/_tmp_fang_jian_probe.gd/.tscn/.uid` 真实实例化 `Main.tscn`，3 倍速；机器人只走公开接口：写 `fang_xiang` 当摇杆、调 `shi_fang_zhu_dong`、调三选一/进化弹窗同款按钮回调。不是作弊改数值，只作机器人上限参考。跑完一局：

```text
TONG_GUAN|RESULT=SHENG_LI;T=576.9;Lv=19;BodyMax=30.0;BodyMin=1.9;
Damage=56.4;HungerMin=96.1;Skills=215;Cards=18;Evolutions=1;
Rooms=34;RoomSet=476301582;ShipSpawn=517.4;ShipHP=1140.0;
ShipSink=576.9;ShipLeft=0.0;ShipBattle=59.5
```

- 经历 34 次换房，九个房号全部覆盖（`RoomSet=476301582`），验证跨房记录延续在真实场景中可用。
- 557~577 秒胜利，Lv.19、体型峰值 30，船 517.4 秒出现（1140 HP），约 59.5 秒击沉；与 TASK-024 探针（557.1 秒、Lv.15、体型 24、掉体型 43.9）相比难度没有因九房鱼群失控。
- 饥饿最低 96.1、累计掉体型 56.4，机器人靠高频植物与技能压制；真人手感与雷达可读性仍需 F5 确认。

探针退出时出现 `9 ObjectDB instances leaked / 4 resources still in use at exit`，是强制 `quit()` 时场景未完整拆除的退出清理提示，不是游戏内 ERROR；门禁无此问题。

## 六、待人工确认

- F5 开局雷达九格都有 NPC 红点；其他房红点会移动/消失/变大；当前房稍大稍亮。
- F5 换房黑场后目标房鱼在记录位置出现；来回换房位置延续；不再整批刷新。
- F5 当前房仍按 0.6~1.8 秒节奏补鱼，雷达图例不变。
- 手机端雷达每帧绘制约 315~405 个点（压力 +2 时 45×9=405），需真机确认帧率；必要时把雷达重绘降到 30Hz（本任务未改）。
- 用户拍板换房体验与难度。

## 七、边界与清理

- 未新增 Autoload，未改存档 schema；九房状态只在单局内有效。
- 未改玩家/普通鱼伤害、体型曲线与掉落；机械船、鲸鲨 Boss、教学鱼未纳入九房记录。
- 临时探针文件、日志与隔离存档目录已清理/不在仓库内；仓库只保留正式产物。
- **本轮未 commit、未 push。**
