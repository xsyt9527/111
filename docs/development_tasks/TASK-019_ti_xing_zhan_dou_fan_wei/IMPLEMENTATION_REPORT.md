# TASK-019 实现报告（2026-11-10）

## 交付状态

- 任务：TASK-019 v1「体型战斗手感、技能范围统一与人类船伤害修正」
- 审批：用户确认「两个都确认（推荐）」；manifest `approved` / `delivery_status=approved`
- 实现基线：`8363e533f9195228621466b45b58fdfb808b4d7b`
- 当前状态：`delivery_status=review`、`handoff_status=pending`、`last_verified_commit=null`
- 未 commit、未 push。

## 一、生产改动

### 1. 体型与首领咬伤

- `scripts/zhang_ben.gd`
  - `ti_xing_dao_chi_du()` 改为 `0.32 * pow(body, 0.7) * pow(1.06, floor(body / 5))`。
  - 体型 5/10/15 各出现一次 ×1.06 里程碑；Lv.1 仍恰好 0.32；曲线指数仍 0.7。
  - `MEI_CI_SHANG_HAI` 保持 1.0，不通过降低普通接触伤害来“变简单”。
- `scripts/yu_npc.gd`
  - `boos_yao_shang_hai(shou_ti, zui_ba, gong_ti := -1.0)` 新增攻击者体型参数；有效目标体型 = `min(目标, 攻击者)`（`gong_ti <= 0` 时退回旧口径）。
  - Boss 咬玩家调用点传入首领当前 `tixing`。
  - 两参旧调用保持 0.9（同体型 1.0 vs 1.0）。
  - 示例：目标 10、攻击者 2 → 1.8（不再是 9.0）；目标 2、攻击者 10 → 1.8；双方 10 → 9.0。
  - 同时给 `_tui_kai_zhou_wei()` 加 `Area2D.monitoring` 守卫：测试先 `add_child` 再设 `shi_boss` 时不再每帧查询已关闭的推挤层，消除 `Can't find overlapping areas when monitoring is off` ERROR。
- `scripts/yu.gd`
  - 连接 `ZhangBen.sheng_ji`：升级瞬间 `jin_ru_wudi(0.6)`，子节点 `AnimatedSprite2D` 做 1→1.16→1 的 0.45 秒脉冲；只动子精灵 scale，不抢根节点体型补间。
  - 重复升级先 `kill()` 旧 Tween。
- 红光
  - `YuNpc.HONG_GUANG_FANG_DA = 2.1`（原 1.5）。
  - `KeChiWu.HONG_GUANG_BEICHENG = 1.8`（原 1.55）。
  - 判定圈未改。

### 2. 技能范围统一入口

- `scripts/yu.gd` 新增：
  - `ti_chang()`：当前帧纹理宽 × `scale.x`，兜底 208×scale。
  - `fan_wei_xiu_zheng(shijie_ban_jing, zui_xiao_bei)`：世界半径不小于 `体长 × 下限倍率`。
  - `ji_neng_ban_jing(neng, dang, zui_xiao_bei)`：`ban_jing_shen_wei=true` 走 `* _shen_wei()`；固定像素走 `* maxf(1.0, scale.x)`；最后统一过体长下限。
- 基础主动统一走 helper：放电、弱点洞察、逆流、漩涡、淤泥弹、声呐、硬壳、电脉冲、诱饵等。
- 六份进化模块主动半径接入 `fan_wei_xiu_zheng`：`fen_yu`、`hong_yu`、`lan_yu`、`ju_kou_yu`、`ye_deng_long_yu`、`zong_yu`。
- `scripts/ji_neng_fan_wei.gd`：`xian_shi(..., wan_jia: Yu = null)`；`_qu_ban_jing` 优先调用 `wan_jia.ji_neng_ban_jing`，未传玩家时从父节点查找名为 `Yu` 的兄弟节点；冲刺类下限 1.5 体长，其它 0.5 体长。
- 修正两处双乘：雷暴落雷圈 `100 * maxf(1, scale.x) * _dian_xi_fan_bei()`；九头电网 `40 * maxf(1, scale.x)`；scale=1 时仍 100/40px。
- `scripts/neng_li.gd` 只补单位注释，未改数据结构或资源 schema。

### 3. 人类机器船双向伤害

- `scripts/zhan_dou.gd`：`JIU_SHANG_HAI_XI_SHU 0.15 → 0.24`，`JIU_SHANG_HAI_JI_CHU 0.05 → 0.08`。
  - 体型 9、嘴 1：2.24（旧 1.4）；体型 10：2.48。
- `scripts/ji_qi_chuan.gd`：新增 `WAN_JIA_TI_XING_SHANG_HAI_BI = 0.04`；深水炸弹、船锚、鱼叉伤害 = `(基础值 + 玩家当前体型 × 0.04) × 船伤倍率`。
  - 体型 10：炸弹 1.4、船锚 1.1、鱼叉 1.0。

### 4. 探索镜头

- `scripts/main.gd`：`SHI_JIAO_MEI_JI = 0.0`，`_shi_jiao_bei()` 恒 1.0；`_process` 仍按原方式 `zoom = 1.0 / _shi_jiao_bei()`，无除零。
- 房间逻辑、`Main.tscn`、`yu_qun.gd`、九图演出未触碰（留给 TASK-020）。

## 二、测试与门禁

- `ce_zhang_ben`：232 passed, 0 failed。
- `ce_zhan_dou`：20 passed, 0 failed。
- `ce_panding`：932 passed, 0 failed。
- 六份进化模块场景：`fen_yu 246`、`hong_yu 215`、`lan_yu 295`、`ju_kou_yu 208`、`ye_deng_long_yu 272`、`zong_yu 228`，均 0 failed。
  - 说明：`ce_zhuanshu_*` 不在八步门禁内；`fen_yu`/`ye_deng_long_yu` 偶发 Godot 退出时 “resources still in use at exit” 警告，为测试立刻 `quit()` 时 pending 节点/资源释放顺序导致，不是断言失败；推挤层 ERROR 已修复。
- `tests/pao_pi.bat` 连续两轮八步全绿：
  - 第一轮：232 / 25 / 1422 / 8 / 20 / 144 / 932 passed，0 failed；`--import` 无 ERROR。
  - 第二轮：断言数同上，仍全绿。
- `validate_task.py`：VALID，退出码 0。
- `check_task_scope.py check`：0 violation。并行 BGM/特效文档路径已登记在白名单，并记录在 `SCOPE_PROPOSAL.md` 的“执行中范围变更”。

## 三、未完成/需用户参与

1. **F5 手测未由 AI 执行**：
   - 同体型 Boss / 小体型 Boss / 升级瞬间三种咬伤；
   - Lv.1 vs Lv.10 屏幕体型占比；
   - 6 身位技能范围圈与固定 90px 技能在高体型下的下限；
   - 可吃红光大小、船战伤害手感。
2. **红测未执行**：把 Boss 第三参传 0 或去掉范围下限，确认测试能抓住；建议用户在学习检查点中做一次。
3. 学习检查点（orientation / inspection / verification-handoff）仍为 `not_started`；本报告不把 AI 实现当学习证据。

## 四、并行交付（不属 TASK-019 gameplay）

- 鲸鲨首领战 BGM 试听：`build/音乐试听/bgm_jing_sha.wav`（68.571429 秒、44.1kHz/16bit/单声道、峰值 -1.501 dBFS）；源工程 `tools/yinyue/bgm_jing_sha.mmp`；说明 `docs/音乐试听_鲸鲨首领战_2026-11-10.md`。未接 `BGM_QU_MU`、未进 `assets/`。
- Gemini 特效需求 v1.2：`docs/技能图标与特效需求_Gemini_2026-11-10.md`。

## 五、回退

- 删除 `pow(1.06, floor(body/5))` 里程碑，恢复 `0.32 * pow(body, 0.7)`。
- 删除 Boss 第三参调用，恢复两参旧口径（会回到“小 Boss 一口 90%”Bug）。
- 删除 `sheng_ji` 连接与 `_on_sheng_ji`，恢复升级无免伤/脉冲。
- 删除 helper 调用，恢复各技能原半径；恢复相机 `SHI_JIAO_MEI_JI = 0.10`。
- 恢复 `0.15/0.05` 与船招固定值。
- 不 commit / 不 push；回退不得覆盖上一轮 33 张主动图标改动。

## 六、TASK-020 合并后的最终复核（2026-11-10）

- TASK-020 房间化在 TASK-019 之后合并，`ce_panding` 由 932 增至 **960 passed, 0 failed**。
- 合并后 `tests/pao_pi.bat` 连续两轮八步全绿：232 / 25 / 1422 / 8 / 20 / 144 / 960，0 failed，无 ERROR；两轮合计 **2811 断言**。
- 两包 `validate_task.py` 均 VALID；`check_task_scope.py` 均 0 violation（TASK-020 并行任务包已登记在 TASK-019 白名单，只作跨任务识别）。
- 文档已更新：`docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`（docx 追加后 1077 段、260 表）。
- APK 已重导：`build/shenhaishiji-debug.apk`，88,604,643 字节（85M）；导出日志仅保留既有「未配置项目图标」ERROR，APK 签名与校验完成。
- F5 手测、红测、学习检查点仍未执行；未 commit / 未 push。
