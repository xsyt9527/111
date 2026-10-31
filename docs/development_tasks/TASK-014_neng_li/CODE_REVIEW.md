# TASK-014 代码评审（CODE_REVIEW）

评审范围：

- 新增：`scripts/neng_li.gd`、`scripts/neng_li_chou.gd`、`scripts/neng_li_dan_chuang.gd`、`scripts/neng_li_ui.gd`、`scenes/NengLiDanChuang.tscn`、`data/nengli/*.tres`、`tests/huai_neng_li.tres`
- 修改：`scripts/zhang_ben.gd`、`scripts/yu.gd`、`scripts/yu_npc.gd`、`scripts/yu_zhong.gd`、`scripts/jie_suan.gd`、`scenes/Main.tscn`、`data/yuzhong/*.tres`
- 删除：旧卡脚本/场景/数据/夹具整条链
- 测试：`tests/ce_zhang_ben.gd`、`ce_bian_jie.gd`、`ce_shu_ju.gd`、`ce_panding.gd`、`pao_pi.bat`

结论：**无 P1 / P2 阻塞问题**；P3 备忘 6 条，均不影响本版交付。

## P3 备忘

### 1. 「本次已锁定」提示与实际强制项可能不一致（P3，建议下次修）

`scripts/neng_li_dan_chuang.gd:100` 只判断 `qiang_zhi` 和 `zui_duo_bian_hao != &""` 就显示「本次已锁定」，但 `scripts/neng_li_chou.gd:36` 的强制项只在候选池里找得到时才生效。若本局最常吃的能力恰好是当前已装备的主动，`ke_xuan_chi` 已把它排除，候选池里没有它：

- 弹窗仍显示「本次已锁定」；
- 实际抽出的 3 张是别的能力。

**失败场景**：玩家装备放电后反复吃电鳐，放电成为最常吃；某次升级 50% 判定为真，界面说锁定放电，但放电根本不会出现。玩家会怀疑概率或代码坏了。

**建议**：`_xie_ti_shi` 先判断强制项是否在 `ke_xuan_chi` 结果里；不在时显示「已装备，不重复出现」，并把 `qiang_zhi` 当作 false 处理。或让 `chou_san_zhang` 返回「是否实际强制」供 UI 使用。

### 2. 玩家冲撞去重表到期不清空（P3）

`scripts/yu.gd:247` 在每次施放时清空 `_chong_zhuang_ming_zhong`，但 0.45 秒结束（`_geng_xin_zhu_dong`）时没有清。表里最多积累本局撞过的所有 instance_id，直到下一次施放才释放。

**影响**：单局上限约同屏 20 条鱼 + 船，内存可忽略；但若后续做「冲撞命中回血/计数」并复用这张表，会读到上一冲的旧 id。

**建议**：冲撞结束时 `clear()`，与本文件 `_qu_xiao_shi_fang` 的做法一致。

### 3. 冲撞命中依赖 Area2D 重叠查询，掉帧可能穿透（P3）

`scripts/yu.gd:270` 每帧读 `yao_qu.get_overlapping_areas()`。测试已经踩过一次「手动瞬移后同帧查询为空」，需要等物理帧。真实游戏在低帧率/高速度下，小鱼可能在一帧内从圈外到圈外，完全不进入重叠列表。

**失败场景**：设备卡顿，冲撞一帧位移超过鱼身直径，玩家从鱼身上穿过去但没有伤害。

**建议**：改用 `PhysicsDirectSpaceState2D.intersect_shape` 或 `ShapeCast2D` 做连续检测；至少把冲撞速度上限与物理帧率绑定。

### 4. 被动列表每帧重建字符串（P3）

`scripts/neng_li_ui.gd:48` 每帧遍历 `bei_dong_ceng`、反查 `yi_xuan_neng_li`、拼接字符串。被动最多 1 种（当前只有毒棘），开销很小；但和 TASK-011 的体型 Label 一样属于无谓分配。

**建议**：监听 `neng_li_zhuang_bei` 或缓存上次字符串，变化时才刷新。

### 5. NPC 潜伏只影响玩家索敌，不影响 NPC 互相看见（P3）

`scripts/yu_npc.gd:317` 的巨口鱼潜伏只把 `Sprite2D.modulate.a` 设为 0.45，并让玩家侧的 `_si_kao` / `_xing_dong` / 首领追击跳过；其他 NPC 的 `_zhou_wei_yu()` 仍能选中它、吃它。

**影响**：如果设计意图是「巨口鱼对所有人都隐身」，当前只实现了一半；如果只是「对玩家偷袭」，则表现（半透明）与机制（NPC 仍可见）不一致。

**建议**：明确设计语义；若要全隐身，把 `yin_shen` 状态抽成 NPC 通用字段，并在 NPC 索敌里同样过滤。

### 6. UI 直接调用玩家私有方法（P3）

`scripts/neng_li_ui.gd:38` 用 `wan._zheng_zai_shi_fang()` 判断按钮禁用。GDScript 没有真正私有，能跑；但 UI 依赖了玩家的下划线内部方法，后续重命名会静默断。

**建议**：在 `Yu` 暴露公开只读方法 `zheng_zai_shi_fang()`，或让 UI 只读 `zhu_dong_leng_que` / 控制状态，不直接问施放态。

## 好的部分（记录强化）

- **数据驱动彻底**：能力数值全在 `.tres`，代码只按 `bian_hao` 分派；NPC 与玩家共用一份定义，靠 `npc_shu_zhi` / `npc_jian_ge` 分叉。
- **账本单一所有权**：主动槽、被动层数、食谱、历史全在 `ZhangBen`；玩家、UI、结算页都读同一份，没有三处各存一份。
- **三选一是纯函数**：`NengLiChou` 不碰全局 RNG，测试用固定种子就能锁死 200 轮抽样与 50% 命中率；这是 TASK-009 测试纪律的直接延续。
- **暂停弹窗有防死锁**：0 候选、连续升级排队、选完继续弹三条路径都写了，且 `layer=100` 盖住技能按钮。
- **切换主动清状态**：`_on_neng_li_zhuang_bei` → `_qu_xiao_shi_fang()`，极速/冲撞/潜伏不会跨能力残留。
- **旧卡退役干净**：脚本、场景、数据、账本、玩家 match、结算读取、测试断言全部删除，grep 无残留；没有留「兼容旧卡」的半套代码。
- **运行时错误被冒烟抓住**：新增能力感知代码在单测里全绿，但 Main 无头 900 帧暴露 stale 引用；6 处 `is_instance_valid` 修复后复跑干净。这说明门禁的第二只眼（ERROR 文本）确实有价值。

## 过程教训

| # | 事故 | 教训 |
|---|---|---|
| 1 | 放电靶鱼被嘴圈吞掉 | 测范围技能时，靶鱼既要进技能半径，又要避开玩家嘴圈；两个圈的距离要算清 |
| 2 | 冲撞同帧查询重叠为空 | 手动改 `position` 后 Area2D 不会立刻刷新；先位移、等物理帧、再结算 |
| 3 | 巨口鱼伤害期望写死 4.0 | 伤害公式带嘴巴系数，期望值必须从 `ZhanDou` 动态算，不能凭等级口算 |
| 4 | 门禁 360 帧提前退出 | 新增异步用例会拉长收卷时间；`--quit-after` 要留足余量 |
| 5 | freed instance 只在 Main 冒烟出现 | 单测绿不等于运行时干净；场景冒烟是独立证据 |

## 后续建议优先级

1. 修 P3-1（锁定提示），成本低、玩家可见。
2. 修 P3-2（冲撞表清空），一行。
3. TASK-016/018 之前再评估 P3-3（连续碰撞）与 P3-5（NPC 潜伏语义）。
4. P3-4 / P3-6 属代码卫生，可随手做。
