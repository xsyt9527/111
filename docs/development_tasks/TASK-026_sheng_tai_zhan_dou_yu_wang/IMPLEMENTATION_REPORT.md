# TASK-026 实现报告

- 任务：生态精简、毒鱼耐受、咬伤经验、NPC 鱼王成长与雷达红点对账
- 规格：v1；基线提交 `f27ae56`；实现日期 2026-11-15
- 状态：代码与测试完成，八步门禁全绿；等待用户 F5 验收与学习检查点
- 约束：本轮未 commit、未 push

## 一、实现总览

| Step | 内容 | 结果 |
|---|---|---|
| 01 | 野外鱼池精简、狮子鱼延后、低等级全期可刷 | 完成 |
| 02 | 毒鱼连吃递减耐受 | 完成 |
| 03 | 咬大鱼按实际掉肉给经验 + 同目标接触减免 | 完成 |
| 04 | NPC 隐藏等级晋升鱼王与每房名额 | 完成 |
| 05 | 鱼王战斗规则、败退奖励、雷达金点 | 完成 |
| 06 | 雷达红点残留对账与人类战清房 | 完成 |
| 07 | 测试改写、机器人探针、门禁与文档 | 完成 |

## 二、分步实现

### Step 01：鱼池精简（`scripts/yu_qun.gd`）

- 新增 `TUI_CHU_PAI_CHI`：`hong_yu`、`an_ying_jian_yu` 退出现野刷新池，鱼种注册表、图鉴、选角与进化引用保持原样。
- 新增 `DU_YU_ZUI_DI_DANG = 2`：狮子鱼 `cheng_yu` 只在 `_dang >= 2`（约 40 秒后）进入抽样池。
- `shua_xin_zui_di(_dang)` 恒返回 1：后期仍可刷到 1 级小鱼，解决“后期只剩高等级鱼、新手没口饭吃”的反馈。
- `_zai_chou_yu_pai()` 统一过滤退池鱼种与档位门槛，普通刷新和大体型专刷共用同一条规则。

### Step 02：毒鱼递减耐受（`scripts/zhang_ben.gd`）

- 新增常量：`DU_KANG_BEI_LV = [1.0, 0.7, 0.4, 0.3]`、`DU_KANG_CHUANG_KOU = 8.0`、`DU_KANG_TUI_CENG_SHI_JIAN = 2.0`。
- 新入口 `jia_du_yun_chi_du_yu(liang)`：只有“吃毒鱼”走连吃耐受；原 `jia_du_yun()` 数值 45 不动，非进食毒源不受影响。
- 连吃结果：45 / 31.5 / 18 / 13.5；第 5 条及以后仍封底 13.5。
- 8 秒窗口内继续吃维持层数；停吃满 8 秒后每 2 秒退一层。
- 关键修正：跨过 8 秒窗口的那一帧只把“窗口外的部分”记进退层计时。`_geng_xin_du_kang(8.5)` 只积 0.5 秒，不会在 8.5 秒时瞬间退光 4 层。
- `chong_zhi()` 清零 `du_kang`、`_du_kang_ceng`、窗口与退层计时，新一局第一口仍按满额。

### Step 03：咬伤经验与接触减免（`scripts/yu.gd`）

- 新增 `YAO_SHANG_JING_YAN_MEI_TI = 5.0`、`YAO_JI_MIAN_SHANG_SHI_JIAN = 0.6`、`YAO_JI_MIAN_SHANG_BEI = 0.2`。
- `_ji_suan_yao_shang_jing_yan(mu, mu_ti_xing)`：经验按“咬击前体型 − 全部联动结算后的最终体型”×5；撕裂齿、毒腺等额外掉肉也算；零掉肉不给。
- 小数经验进 `_yao_shang_jing_yan` 池，满 1 点才入账；避免每口 0.15 被 `int` 截没。
- 首领/鱼王不重复给普通咬伤经验（各走专项奖励）。
- 同一目标 0.6 秒内接触伤害 ×0.2；换目标或窗口过期恢复满额；只护被咬中的那一条鱼。

### Step 04：晋升鱼王与名额（`scripts/yu_npc.gd`、`scripts/yu_qun.gd`）

- 常量：`YU_WANG_DENG_JI = 10`、`YU_WANG_MEI_FANG_SHANG_XIAN = 2`、`YU_WANG_TI_XING_JIA = 2.0`、`YU_WANG_BAI_TUI_TI_XING = 2.0`、`YU_WANG_DA_ROU_TI_XING = 1.0`。
- 隐藏等级 `deng_ji_nei` 达 10 且本房名额未满 → `_jin_sheng_yu_wang()`：置 `yu_wang`、加入 `yu_wang` 组、升 10 级 +1、再额外 +2 体型。
- 第 3 条满经验鱼停 9 级、经验保留；名额腾出后继续晋升，不是永久锁死。
- `yu_wang_shu(pian)`：父节点是 `YuQun` 时以九房记录为权威；裸夹具退回 `yu_wang` 组统计。
- `hui_xie_ji_lu(yu)`：晋升同帧回写 `ti/nei_deng/nei_jing_yan`，名额统计立刻可见。
- 换房载荷恢复 `_zai_ru_deng_ji` 后调用 `_geng_xin_yu_wang_zhuang_tai()`；记录的 `ti` 已含 +2，恢复时不重复加。
- 直接摆出的 10 级鱼先恢复身份但不加 +2；只有“从 9 升 10”的那一次加。

### Step 05：鱼王战斗、败退与雷达金点（`yu_npc.gd`、`yu.gd`、`xiao_di_tu.gd`、`fen_yu.gd`）

- 鱼王不可整吞：玩家 `_chi_diao` 与鲸鲨专属技 `fen_yu._ke_chi` 双重过滤。
- 鱼王不逃跑：被咬后直接锁仇追击，`_tao_pao_ji_shi` 不会启动。
- 残血败退：体型 ≤2.0 时先 `diao_rou(3, 1.0)` 掉 3 块大肉、再给 `int(fenzhi) * 2` 经验，最后立 `si_le`。
- 鱼王败退绝不 emit `bei_ji_bai`；该信号仍是鲸鲨专属。测试用接收器计数恒为 0。
- 雷达：当前房与九房记录中 `nei_deng >= 10` 的画金点；死鱼记录不画。

### Step 06：雷达红点对账（`scripts/xiao_di_tu.gd`、`scripts/yu_qun.gd`）

- 抽出纯函数 `ji_lu_ke_hua(rec)`：
  - `node == null`：未加载房记录，照常画；
  - 有效节点且 `si_le != true`：画；
  - 无效节点或死鱼：不画。
- `_hu_npc()` 记录循环统一走该函数，删除原内联死鱼判断。
- `qing_chu_qi_ta_fang_ji_lu()` 在人类战停刷时清掉非当前房记录，避免机械船降临后地图无鱼仍残留红点。
- 因为判定抽成纯函数，测试无需拦截 `draw_circle` 就能断言死/空/活三种记录。

### Step 06 补丁：用户反馈“吃完鱼仍有残留红点”（2026-11-15）

- 根因：Godot 4 里已 `queue_free` 的节点留在字典中时 `node == null` 为真，但 `typeof(node)` 仍是 `TYPE_OBJECT`。
  `_tong_bu_dang_qian_fang_jian()` 用 `if yu == null: continue` 把这种“已释放对象”误判成“未加载房记录”，于是被吃鱼的记录永远删不掉，雷达按它最后的位置一直画红点。
- `_tong_bu_dang_qian_fang_jian()`、`_bao_cun_dang_qian_fang_jian()` 改为先看 `typeof(node) == TYPE_NIL`（真正的未加载记录）再走有效性判断；已释放节点直接删记录，换房保存也不会把它洗成 `node=null` 的永久虚拟鱼。
- `yu_wang_shu()` 同步排除已释放节点，避免死鱼王短时占名额。
- `ji_lu_ke_hua(rec)` 对 `TYPE_NIL` 照画（未加载房虚拟鱼），对 `TYPE_OBJECT` 但 `not is_instance_valid()` 的已释放节点返回 false，从绘制层再兜一层。
- 新增 5 条断言：已释放节点语义前提、当前房同步删记录、换房保存删记录、雷达纯函数不画已释放节点；`ce_panding` 1422 → 1427。

### Step 07：测试、探针与文档

- `tests/ce_panding.gd` 新增/改写用例：0b2 鱼王记录与清雷达、0c 等级复位、6k2 毒抗递减、6k3 咬伤经验 + 接触减免、6zc 鱼王晋升/名额/拒吞/不逃/败退/雷达纯函数。
- 单文件运行 1313 passed, 0 failed。
- 临时机器人探针 `tests/_tmp_yu_wang_probe.gd/.tscn/.uid` 真实实例化 `Main.tscn`，3 倍速，只走公开接口；跑完已删除。
- 更新任务索引、引擎词总表、`Godot引擎词总表.docx`、学习路线图与交接文档。

## 三、改动文件

产品代码：

- `scripts/yu_qun.gd`
- `scripts/yu_npc.gd`
- `scripts/zhang_ben.gd`
- `scripts/yu.gd`
- `scripts/xiao_di_tu.gd`
- `scripts/zhuan_shu_ku/fen_yu.gd`
- `tests/ce_panding.gd`

文档：

- `docs/TASK_INDEX.md`
- `docs/引擎词总表.md`
- `Godot引擎词总表.docx`
- `LEARNING_ROADMAP.md`
- TASK-026 包内 `TASK_STATE.json`、`LEARNING_STATE.json`、`LEARNING_RECORD.md`、`INTEGRATION_HANDOFF.md` 与本报告等三份报告

## 四、验证结果

- 八步门禁：232 / 25 / 1422 / 8 / 20 / 144 / 1313 passed，0 failed；合计 3164 断言，脚本输出「全绿：可以交付」。
- 单文件 `ce_panding`：1313 passed, 0 failed。
- `validate_task.py`：`VALID: TASK-026 v1 (plan_driven)`。
- 机器人探针两次连续胜利：
  - 532.0 秒，Lv.16，体型峰值 25.5，船 487.3 秒出现（960 HP），44.6 秒击沉；
  - 541.5 秒，Lv.16，体型峰值 25.5，船 487.3 秒出现（960 HP），54.2 秒击沉。
- 与 TASK-025 基线（576.9 秒、Lv.19、峰值 30.0、换房 34 次、船 517.4 秒 1140 HP）相比，两次均低于 650 秒并稳定胜利，未触发包内回滚口径。
- 探针全程鱼王数量 0：487 秒前没有任何普通鱼攒到隐藏 10 级。代码规则成立，但“鱼王在常规一局是否足够常见”属于节奏观感，需用户 F5 拍板。

## 五、兼容与回滚

- 旧存档 / 测试夹具仍可走裸 `yu_wang` 组统计路径。
- 退池鱼种仍保留注册表，选角、图鉴、进化引用不断链。
- 原 `jia_du_yun()` 数值 45 不变，毒腺等非进食毒源不受耐受影响。
- 鱼王阈值、每房上限、败退体型均为常量，若 F5 觉得压制过强，可只调这些常量或 `YU_WANG_QI_YONG` 总闸，不动记录结构。

## 六、待用户确认

1. F5 检查毒抗条：连吃 4 条毒鱼的递减与停吃退层是否符合预期。
2. F5 观察鱼王出现频率与压迫感；探针 487 秒内为 0，若实机也几乎见不到，需要另开节奏调参任务。
3. F5 检查机械船降临后雷达是否还有残留红点，以及换房回来雷达点是否恢复。
4. 咬伤经验系数 5 对升级速度的影响需真人手感确认。

## 七、过程清理

- 临时探针脚本、场景、`.uid` 与本地日志已删除，仓库只保留正式产物；本轮未 commit、未 push。
