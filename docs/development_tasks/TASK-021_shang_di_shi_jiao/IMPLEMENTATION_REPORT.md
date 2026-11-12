# TASK-021 实现报告（2026-11-11，2026-11-12 增补浏览器实测与首领房修复）

## 交付状态

- 任务：TASK-021 v1「上帝视角小地图、受击闪白与换房安全入场」
- 审批：用户确认小地图四色标记、受击闪白、换房刷新改进；manifest `approved` / `delivery_status=approved`
- 实现基线：`8363e533f9195228621466b45b58fdfb808b4d7b`
- 当前状态：`delivery_status=review`、`handoff_status=pending`、`learning_status=not_started`、`current_step=step-04`、`current_checkpoint=orientation`
- `last_verified_commit=42df5f1114b95e8bc29cd622c0a9b99e1839fd60`；已 commit 并 push 到 `main`（未强制推送）。
- 2026-11-12：首领房追击修复完成，Chrome/Playwright 浏览器实测通过；随后发布 Web（commit `42df5f1`），Pages workflow 成功，线上空缓存复测通过。
- `TASK_STATE.json` 的 `implementation_baseline.preexisting_changes` 保持 285 项原样；另补 `implementation_notes` / `verification` 两个附加记录字段（`validate_task.py` 只做必需键检查，未禁止附加字段）。

## 一、生产改动

### 1. 上帝视角小地图

- `scripts/xiao_di_tu.gd`（新增，`class_name XiaoDiTu`，`extends Control`）
  - `preload` 整图 `res://assets/sucai/shenhai_beijing/beijing_3x3.webp`，不重切九张贴图。
  - 常量：`SHI_JIE_CHI_CUN = Vector2(4128, 2304)`、`DI_TU_QU = Rect2(0, 20, 240, 134)`、`GE_SHU = 3`、`MO_REN_FANG_JIAN = 4`。
  - `_draw()` 依次画半透明面板底、整图缩放、3×3 网格线、当前房间亮青边框、植物/NPC/首领与机械船/玩家标记、面板细边框。
  - `_dao_di_tu(shijie)` 把世界坐标等比映射到 240×134 地图矩形；`_zai_shi_jie_nei()` 过滤地图外坐标，避免船在玩家上方 600px 时黑点跑到标题/图例区。
  - 颜色：黑点=首领/机械船（白描边）、蓝点=玩家、红点=NPC 鱼、绿点=可吃植物；`_hu_zhi_wu()` 只画 `ke_chi == true` 且 `dong_hua.visible` 的植物。
  - `_hu_shou_ling_he_chuan()` 只读 `Main.ji_qi_chuan`，用 `is_instance_valid()` 判空、`si_le` 判沉没，不缓存副本。
  - `mouse_filter = Control.MOUSE_FILTER_IGNORE`，整块小地图不吃点击/摇杆；`_process()` 每帧 `queue_redraw()`，只读组状态。
- `scenes/Main.tscn`
  - 新增 `XiaoDiTuUI`（`CanvasLayer`）→ `XiaoDiTu`（`Control`，24,210–264,386），标题「上帝视角（永久被动）」、图例「黑 首领 · 蓝 玩家 · 红 鱼 · 绿 植物」。
- `scripts/main.gd`
  - `HUD_CENG_MING` 追加 `"XiaoDiTuUI"`：人类战九图演出时随 HUD 一起隐藏。

### 2. 受击闪白

- `scripts/yu_npc.gd` 的 `_shan_hong()`
  - 根节点 `modulate` 起手 `Color(2.8, 2.8, 2.8, 1.0)` 过曝白，`create_tween()` 在 0.14 秒回到 `Color.WHITE`。
  - 连续受击先 `kill()` 旧 `_yan_se_tween`，不叠成多份补间。
  - 只染根节点；石化/声呐/潜伏等状态色仍在子精灵 `$AnimatedSprite2D.modulate`，两层乘法染色互不覆盖。
- `scripts/ji_qi_chuan.gd` 的 `_shan_guang()`
  - 新增 `_shan_guang_tween`；对 `_chuan_ti.modulate` 起手 `Color(2.8, 2.8, 2.8, 1.0)`，0.13 秒回到 `Color.WHITE`；高频受击先 `kill()` 旧补间。

### 3. 换房安全入场

- `scripts/yu_qun.gd`
  - 常量：`HUAN_FANG_HUAN_YING_XIAO_YU = 10`、`HUAN_FANG_AN_QUAN_JIAN_JU = 240.0`、`HUAN_FANG_NEI_BIAN_JU = 40.0`、`HUAN_FANG_WAI_BIAN_JU = 60.0`、`HUAN_FANG_PAI_DUI_RONG_YU = 5`、`HUAN_FANG_PIAN_YI` 四偏移。
  - `qie_huan_fang_jian(qu)`：更新房间、先 `remove_child()` 再 `queue_free()` 清掉旧房普通鱼（Boss 不在 YuQun 子节点，不受影响），记录玩家位置后 `_chong_tian_an_quan.call_deferred(wan_jia_wei)`。
  - `_chong_tian_an_quan(wan_jia_wei)`：先放 10 条欢迎小鱼；`_dangqian_yu_shu() >= max(1, 上限 - 5)` 时直接返回，防止与开局 `_chong_tian_yu_qun` 的 deferred 补屏叠加超上限；其余鱼走 `_shengcheng_yi_tiao(true)` 补到同屏上限。
  - 纯函数 `ru_chang_xiao_yu_deng_ji(wan_jia_ti, zui_da = 3)`：`clamp(floor(体型 / 1.1), 1, 3)`，保证玩家可整吞且默认封顶 3 级。
  - 纯函数 `an_quan_fang_nei_dian(qu, wan_jia_wei)`：四象限中心夹进房内 40px 边距，取离玩家最远者；1376×768 房间、玩家在房心时距离约 394px。
  - 欢迎鱼落点再按 `HUAN_FANG_PIAN_YI` 分散；若离玩家 <240px，沿远离玩家方向推到 240px，再夹回房内 40px 边距。
  - 纯函数 `an_quan_chu_kou(qu, wan_jia_wei, bianju = 80.0)`：从玩家所在半场的对侧房外进入，`x` 在房外，`y = 玩家 y + 180` 并夹到房内 60px 边距；1376 房宽下水平距离 ≥ 半房宽约 688px。
  - `_sheng_yu(zhong, an_quan)`：换房补屏时对 `dengji >= floor(玩家体型)` 的鱼使用 `an_quan_chu_kou`，避免大鱼贴脸。
  - `_chou_xiao_yu_zhong(zui_gao_deng_ji)`：只在 1..最高可吃等级中抽最高级（同级多条随机），无候选返回 `null`。

### 4. 换房入场免伤

- `scripts/main.gd` 的 `_qie_huan_fang_jian(pian)`：相机 `reset_smoothing()` 后、`yu_qun.qie_huan_fang_jian(qu)` 前调用 `yu.jin_ru_wudi(0.9)`，淡入瞬间 0.9 秒免伤。

## 二、测试与门禁

- `tests/ce_panding.gd` 新增「用例 0b3」TASK-021 断言：
  - 小地图几何：`DI_TU_QU == Rect2(0,20,240,134)`、`GE_SHU == 3`、默认房 4；
  - 世界→地图坐标：左上 `(0,0)→(0,20)`、右下 `(4128,2304)→(240,154)`、中心 `(2064,1152)→(120,87)`；
  - `HUD_CENG_MING` 包含 `XiaoDiTuUI`；
  - NPC 受击 `modulate` RGB 同时 >2，连续受击仍停在 2.8 附近不叠加；
  - 欢迎鱼等级（体型 0.5/1.0/2.2/3.4/4.4/8.0 + 显式上限）、房内最远象限落点、≥240px、40px 边距；
  - 对侧安全入口左右半场、y 上下边距、x 必在房外、水平距离 ≥688px；
  - `_chou_xiao_yu_zhong` 只抽 1..上限中的最高级、无候选返回 `null`；
  - `_chong_tian_an_quan` 补满同屏、10 条欢迎鱼、其余房外入口、重复补屏不叠加；
  - `qie_huan_fang_jian` 清掉旧房普通鱼并更新房间矩形。
- 目标测试：`ce_panding` **1101 passed, 0 failed**，退出码 0，无 ERROR（2026-11-12 首领房修复后；本次新增 10 条首领房限制断言）。
- 2026-11-12 首领房修复后完整八步门禁：232 / 25 / 1422 / 8 / 20 / 144 / 1101 passed，0 failed，无 ERROR；单轮合计 **2952 断言**；脚本输出「全绿：可以交付」。
- 2026-11-11 初版实现时曾连续两轮八步全绿；该结果已被 2026-11-12 修复后门禁取代，本报告不再沿用旧计数。
- `validate_task.py`：**VALID: TASK-021 v1 (plan_driven)**，退出码 0。

## 三、范围检查

- 实现完成时 `check_task_scope.py check`：**10 allowed, 278 unchanged pre-existing, 0 violation(s)**。
- 文档收尾后复跑（2026-11-11 15:41）：**14 allowed, 275 unchanged pre-existing, 1 violation(s)**；唯一违规为 `project.godot`（工作树 diff 删除 `renderer/rendering_method.web="gl_compatibility"`，mtime 2026-11-11 13:52:58）。该改动早于本次文档编辑，非本代理产生，疑似主会话/Web 实测准备造成；未擅自回退，需主会话确认处理。实现完成时的 10/278/0 为当时门禁结果，不代表当前工作区无外部漂移。
- `scripts/xiao_di_tu.gd.uid` 已登记进 `allowed_new_files`；`scripts/xiao_di_tu.gd` 与 TASK-021 任务包为允许新增。
- 只改允许文件：`scripts/xiao_di_tu.gd`、`scenes/Main.tscn`、`scripts/main.gd`、`scripts/yu_npc.gd`、`scripts/ji_qi_chuan.gd`、`scripts/yu_qun.gd`、`tests/ce_panding.gd` 及文档。
- 未改 TASK-019/020 体型、伤害、范围、房间尺寸、相机 limit、Boss 巡逻与人类战流程；未改 Autoload、存档 schema、`project.godot`（当前 `project.godot` 的外部改动见上条，未由本任务产生）。

## 四、2026-11-12 浏览器实测与首领房修复

### 1. 首领跨房追击：现象与修法

- 实测现象：Lv.1 玩家右移约 20 秒，鲸鲨从东南房 8 追进房间 4/5，贴脸击杀；根因是首领索敌/追击没有房间边界约束。
- 修法（代码已由主代理完成，本报告只记录）：
  - `scripts/main.gd` 给鲸鲨注入房间 8 矩形：`fang_jian_qu(8)`，即 `Rect2(2752,1536,1376,768)`。
  - `scripts/yu_npc.gd` 新增 `xian_ding_qu` 与 `zai_xian_ding_qu()`：空矩形兼容普通鱼与旧夹具；非空时只有玩家在房内才允许索敌/追击。
  - 追击位移每帧夹在首领房内（四周留 8px）；玩家跑出房立即断追击并进入冷却、回巡游。
- 测试：`tests/ce_panding.gd` 新增 10 条首领房限制断言（房间矩形注入、房内祭坛点允许、房间 4 开局点禁止、玩家不在房内不追击、跑出房断追、断追进冷却、回巡游等），`ce_panding` 达到 **1101 passed, 0 failed**。

### 2. 浏览器实测（Chrome/Playwright，1280×720）

- 环境：Chrome/Playwright，1280×720，本地 `http://127.0.0.1:8765` 新包。
- 已验证：
  1. 主菜单 → 选择角色 → 局内成功；点击「当前形态 · 出发」后约 2 秒进入局内。此前失败是测试会话坐标/阈值问题，不是游戏缺陷。
  2. 局内小地图「上帝视角（永久被动）」正常：3×3 九格、当前房亮青框、玩家蓝点、NPC 红点、植物绿点、首领黑点；换房后当前房框与玩家点同步移动。
  3. 左移换房捕捉到黑场帧（亮度 26/255），随后新房间淡入；房间内有鱼，玩家落点附近无大鱼贴脸，鱼群持续动画。
  4. 音频实测：`AudioContext` state=`running`、48kHz；局内 RMS 0.019–0.058、peak 0.05–0.16；`AudioBufferSource` 播放计数从 2 增至 9，BGM/音效确有输出。
  5. 控制台只有 Godot 的 UID 回退 WARNING（被打印为 console error），无 `pageerror`、无真正运行错误。

### 3. 门禁结果

- 2026-11-12 首领房修复后完整八步门禁：`ce_zhang_ben` 232、`ce_bian_jie` 25、`ce_shu_ju` 1422、`ce_yao_gan` 8、`ce_zhan_dou` 20、`ce_jie_suo` 144、`ce_panding` 1101，总 **2952**，0 failed，脚本输出「全绿：可以交付」。
- `ce_panding` 1101 中包含本次首领房修复新增的 10 条首领房限制断言。

### 4. 仍未验证

- 受击白闪的浏览器逐帧视觉捕获未单独截到；`ce_panding` 已断言船根节点 `modulate` RGB>2，鱼/Boss 闪白逻辑同路径。
- 发布 commit/push、GitHub Pages 部署、线上空缓存复测已完成（详见第七节）；线上包已确认含本任务脚本。

## 五、未完成/需用户参与

1. **浏览器白闪逐帧视觉捕获未完成**：本轮浏览器实测未单独截到受击白闪闪白帧；`ce_panding` 已断言船根节点 `modulate` RGB>2，鱼/Boss 闪白逻辑同路径，仍需肉眼/F5 确认。
2. **F5 补充手测未由 AI 执行**：
   - 小地图同时显示 9 宫格、四类标记颜色/位置与当前房亮青框（浏览器已基本确认，F5 再目检一次）；
   - 咬 NPC/首领/机械船时肉眼可见白色闪光，状态染色与死亡淡出不被破坏；
   - 连续换房 9 格：淡入即有小鱼可吃、无大鱼贴脸、无 ERROR（浏览器已走查单次换房）；
   - 人类战九图演出时 `XiaoDiTuUI` 随 HUD 隐藏（浏览器未覆盖此演出项）。
3. **红测未执行**：可临时把 `DI_TU_QU` 改错、把 `HUAN_FANG_AN_QUAN_JIAN_JU` 改成 0、或删掉闪白 `kill()`，确认用例 0b3 会变红；复原后再跑门禁。建议用户在学习检查点做一次。
4. **学习检查点仍未开始**：`orientation` / `godot-inspection` / `verification-handoff` 均为 `not_started`；本报告不把 AI 实现当学习证据。
5. **发布已完成**：commit `42df5f1` 已推送 `main`；Pages workflow run `43160662448` 成功；线上空缓存复测通过（详见第七节）。

## 六、回退方法

- 删除 `scripts/xiao_di_tu.gd` 与 `scripts/xiao_di_tu.gd.uid`；从 `Main.tscn` 删除 `XiaoDiTuUI`/`XiaoDiTu` 节点；从 `main.gd` 的 `HUD_CENG_MING` 删除 `"XiaoDiTuUI"`。
- `yu_npc.gd` 的 `_shan_hong()` 恢复原来的受伤红闪实现；`ji_qi_chuan.gd` 删除 `_shan_guang_tween` 与 `_shan_guang()` 的过曝白逻辑。
- `yu_qun.gd` 删除 TASK-021 常量、`ru_chang_xiao_yu_deng_ji`、`an_quan_fang_nei_dian`、`an_quan_chu_kou`、`_chong_tian_an_quan`、`_fang_huan_ying_xiao_yu`、`_chou_xiao_yu_zhong` 及 `_sheng_yu` 的安全入口分支；`qie_huan_fang_jian` 恢复 TASK-020 的同步补屏逻辑。
- `main.gd` 删除 `_qie_huan_fang_jian` 中的 `yu.jin_ru_wudi(0.9)`。
- 首领房限制回退：`main.gd` 删除 `_jing_sha.xian_ding_qu = fang_jian_qu(8)`；`yu_npc.gd` 删除 `xian_ding_qu` / `zai_xian_ding_qu()` 及 `_boos_xing_dong()` / `_boos_zhui_ji()` 中的房限制分支；`tests/ce_panding.gd` 删除首领房限制 10 条断言。
- 删除 `tests/ce_panding.gd` 用例 0b3；不要覆盖 TASK-019/020 的既有断言与改动。
- 回退后重跑 `tests/pao_pi.bat`、`validate_task.py`、`check_task_scope.py`；不 commit / 不 push。

## 七、Web 发布与线上复测（已完成）

- `.github/workflows/deploy-web.yml` 在 push 到 `main` 后自动构建并部署 GitHub Pages。
- 发布提交：`42df5f1114b95e8bc29cd622c0a9b99e1839fd60`（`main`，普通 push，未强制）；GitHub Actions run `43160662448` 结论 `success`。
- 线上 PCK：`https://xsyt9527.github.io/111/index.pck`，59,555,260 B，目录 2559 项；已确认含 `scripts/xiao_di_tu.gdc`（3996 B）、`scripts/yu_npc.gdc`（28381 B，含首领房限制）、`scripts/main.gdc`（12253 B）。
- 线上空缓存复测（Chrome/Playwright 1280×720、全新 context、禁用缓存）：加载 28.15 秒到主菜单；29.99 秒进入选择页；33.80 秒进入局内（选择页→局内 diff 46.02）；右移 8 秒换房 diff 44.91、亮度 86.9（存活）；小地图九格/四色/当前房框在换房前后同步；控制台 0 个错误。
- APK 重导（含首领房修复）：`build/shenhaishiji-debug.apk` 87,563,926 B，md5 `858a5f73473dcb43129866c5789ae786`；APK 内 `assets/scripts/yu_npc.gdc` 28381 B、`xiao_di_tu.gdc` 3996 B。
- 仍待用户 F5 目检（白闪逐帧截图）与红测；人类战九图演出时小地图隐藏项未在浏览器覆盖。
