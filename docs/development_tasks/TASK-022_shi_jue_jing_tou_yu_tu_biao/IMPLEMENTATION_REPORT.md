# TASK-022 实现报告（2026-11-12）

## 交付状态

- 任务：TASK-022 v1「小地图黑底/首领换色、玩家面板永久被动、决战动态镜头、机械船 ×0.8、33 张被动图标、特效清单」
- 审批：用户 2026-11-12 提出 7 项反馈并批准执行；manifest `approved`
- 实现基线：`bcc1f3dfe25267e4c4017946ee076bc7c5640899`（工作区已有未提交改动原样保留，未覆盖、未回滚）
- 当前状态：`delivery_status=review`、`handoff_status=pending`、`learning_status=not_started`、`current_step=step-04`
- **本轮未 commit、未 push**；所有改动留在工作区，等待用户目检与提交指示
- 完整八步门禁：2026-11-12 全绿，7 个测试步合计 **3079 passed / 0 failed**，无 ERROR，脚本输出「全绿：可以交付」
- `validate_task.py`：`VALID: TASK-022 v1 (plan_driven)`；`check_task_scope.py check`：0 violation

## 一、7 项反馈的实现

### 1. 小地图黑底 + 首领换色并标注

- `scripts/xiao_di_tu.gd`
  - `YAN_SE_DI` 改为纯黑不透明 `Color(0.0, 0.0, 0.0, 1.0)`。
  - 删除 `YAN_SE_HEI_DIAN`，新增 `YAN_SE_SHOU_LING := Color(1.0, 0.78, 0.16, 1.0)`（金色）。
  - 首领/机械船标记改为白描边圆 5.8 + 金色内圆 4.5；玩家蓝、NPC 红、植物绿不变。
- `scenes/Main.tscn`
  - 删除 `XiaoDiTuUI/XiaoDiTu/BiaoTi`（「上帝视角（永久被动）」不再写在地图上）。
  - 小地图矩形 `DI_TU_QU` 上移到 `Rect2(0, 0, 240, 134)`，地图从面板顶部开始。
  - 图例改为「金 首领 · 蓝 玩家 · 红 鱼 · 绿 植物」。

### 2. 「上帝视角」移到玩家设置面板

- `scripts/she_zhi.gd`
  - 删除被动区为空就提前 `return` 的旧分支：主动区、被动区始终创建。
  - 被动区标题后固定先插入 `_zuo_shang_di_shi_jiao_ka()`，再列账本已有被动；账本为空也显示永久卡，并补「暂无其他被动能力」占位。
  - 永久卡 `ShangDiShiJiaoKa`：深青底 `Color(0.06, 0.16, 0.2, 0.95)`、金色描边、8px 圆角；左侧 96×96 `TuBiaoKuai`，右侧「上帝视角 / 永久被动 / 九宫格海图 · 实时标记首领/鱼/植物/自己」。
  - 该卡不读账本层数、不占被动层数；删除无引用的 `_zuo_kong_zhuang_tai()`。

### 3. 决战镜头随体型取景 + 机械船 ×0.8

- `scripts/main.gd`
  - 删除固定 `REN_LEI_QUAN_TU_OFFSET=(0,-260)`——这是「向上游看到灰区」的根因：Camera2D 的 `offset` 会绕过/错位 `limit`。
  - 决战分支改为 `_suo_quan_tu()` + `camera.offset=Vector2.ZERO` + 关闭平滑 + `_ying_yong_ren_lei_qu_zhuang()`；普通探索分支恢复当前房间 limit 与 `camera.zoom = ONE/_shi_jiao_bei()`。
  - 新增纯函数 `ren_lei_qu_zhuang(wan_jia_wei, chuan_wei, wan_jia_ti_chang, chuan_ban_jing, shi_kou_chi_cun, di_tu_qu) -> Dictionary`：
    - 中心取玩家与船的中点；
    - `req_w = max(体长 ×1.15, 船半径×2+160, |dx|+体长×0.5)`；`req_h = |dy|+体长×0.6+船半径×2+240`；
    - `fit_zoom = min(vw/req_w, vh/req_h, 0.85)`；`xia_zoom = max(vw/地图宽, vh/地图高)+0.01`；
    - `zoom = clamp(fit_zoom, max(0.36, xia_zoom), 0.85)`；
    - 再按半宽/半高把可见矩形中心夹进 `QUAN_TU_LIMIT`，保证四边不越界。
  - 新增 `_ying_yong_ren_lei_qu_zhuang()`：读 `yu.ti_chang()`（回退 160）、`ji_qi_chuan.chuan_ti_ban_jing()`、视口尺寸（回退 1280×720），写相机位置与 zoom。
  - `_on_ren_lei_yan_chu_jie_shu()` 同样改为 offset=0、关闭平滑、全图 limit、动态取景并 `reset_smoothing()`。
  - 机器船生成悬停高度 `Vector2(0,-600)` 改为 `Vector2(0.0, -JiQiChuan.XUAN_FU_GAO_DU)`，与缩小后的构图同步。
- `scripts/yu.gd`
  - `_xian_zhi_zai_di_tu_nei()` 边距由固定 30px 改为 `maxf(30.0, ti_chang() * 0.5)`：后期大体型贴地图上下边时整条鱼仍在地图内，镜头贴边不会切掉半个鱼身。
- `scripts/ji_qi_chuan.gd`
  - `CHUAN_TI_BEI_LV 3.0 → 2.4`、`ZHAO_TI_BEI_LV 3.8 → 3.04`（整体视觉 ×0.8），`XUAN_FU_GAO_DU 600 → 480`。
  - 新增 `chuan_ti_ban_jing() -> float`：`150.0 * CHUAN_TI_BEI_LV`，当前 360，供决战取景按船体大小算。
  - 弱点圆随倍率变为 144、船体圆 360；**所有攻击范围常量一个未改**（`GONG_JI_FAN_WEI_BEI_LV=2.0`、`ZHA_DAN_BAN_JING=240`、`MAO_NEI_BAN_JING=100`、`MAO_WAI_BAN_JING=480`、`MAO_TUI_KAI=440`、`TAN_ZHAO_CHANG=1120`、`YU_CHA_SHE_CHENG=1300` 等）。

### 4. 决战灰区与「鱼到底/视角卡上面」

- 根因同第 3 条：固定上移 offset 让相机可见矩形上缘越过地图顶；同时玩家被固定 30px 边距夹在地图内，视觉上「鱼到底、镜头还在上面」。
- 修复后实测：上/下/左/右/中五个位置，可见矩形均严格落在地图 `Rect2(0,0,4128,2304)` 内，截图背景完整、无灰色区域。

### 5. 33 张进化专属被动图标接入

- 源目录：`美术资源/P0_进化专属被动技能图标_33张_1024与128真透明PNG/tubiao/`；只取 128×128 真透明版，排除 `ji_ci_kou_nei_AI版.png`。
- 复制 33 张 PNG 到 `assets/sucai/tubiao/` 与 `assets/sucai_classic/tubiao/`，两套目录 PNG 由 68 张增至 101 张。
- 修改 33 个 `data/nengli/<id>.tres`：`load_steps=3`，新增 `[ext_resource type="Texture2D" path="res://assets/sucai/tubiao/<id>.png" id="2_tu_biao"]` 与 `tu_biao = ExtResource("2_tu_biao")`。
- 处理后 52 个被动全部有 `tu_biao`，33 个进化专属无缺失；未引用 AI 版/1024 目录；`.tres` 保持 UTF-8 无 BOM、LF。
- `headless --import` 成功，66 个新 PNG 完成 reimport，生成 `.png.import`，无 ERROR。

### 6. 特效需求清单

- `docs/特效需求清单_2026-11-12.md`（新建）：
  - 统一规格：真透明 PNG、无背景、单主体、朝右、4 帧（f1 静止/起始 → f2 发展 → f3 峰值 → f4 收束）、每帧同尺寸、snake_case、锚点/混合模式/游戏内缩放；一次只生成一个素材，先确认第 1 帧再做 2~4 帧。
  - P0：33 组进化专属被动触发特效（11 个鱼系 ×3），共 132 帧。
  - P1：39 组未完成主动特效（6 基础 + 33 进化），156 帧；14 条已有特效标「已有/沿用勿重画」。
  - P1.5：机器船 7 组 + 升级体型脉冲 1 组；4 组整船动画已有勿重画，新做 4 组 / 16 帧。
  - P2：22 套状态（22 图标 + 22 条 4 帧循环 = 44 个交付物 / 110 帧）。
  - 合计新做 **120 个交付物 / 414 帧**；附可直接粘贴的 AI 提示词模板、负面提示、验收清单、33 个被动 id 核对表。
- `docs/技能图标与特效需求_Gemini_2026-11-10.md` 更新到 v1.3：
  - 顶部新增「2026-11-12 增量：33 张被动图标已接入，禁止重画」；
  - §5.2 的 33 个 P20–P52 条目由「图标缺」改为「图标已完成（2026-11-12，禁止重画）」；
  - 资产总账改为被动图标 52/52、缺 0；新增 §13 增量记录，保留旧清单只作追溯。

### 7. 子代理并行

本轮同时启动 4 个 general-purpose 子代理，分别负责小地图/玩家面板、决战镜头/机械船、33 图标、特效文档；主代理负责集成、边界夹取、测试断言、import、视觉探针、门禁与收尾。

## 二、测试与门禁

- `tests/ce_panding.gd` 新增/更新断言：
  - 小地图：`DI_TU_QU == Rect2(0,0,240,134)`、纯黑底、金色首领、映射 `(0,0)→(0,0)`、`(4128,2304)→(240,134)`、中心 y=67。
  - 33 个进化专属被动图标：`lei_xing=1` 且 `suoshu_xing_tai != ""` 的 33 个资源全部有 `tu_biao`，两套目录文件存在，总数恰 33。
  - 决战取景纯函数：中部中心 y=912、zoom 0.36~0.85、可见矩形在地图内；向上/向下/靠左/超大玩家体长 1200 均不越界。
  - 船体：`_chuan_ti.scale.x == 2.4`、弱点半径 144、船体半径 360、`CHUAN_TI_BEI_LV==2.4`、`ZHAO_TI_BEI_LV==3.04`、`XUAN_FU_GAO_DU==480`、`GONG_JI_FAN_WEI_BEI_LV==2.0`。
  - Main.tscn：无 `XiaoDiTuUI/XiaoDiTu/BiaoTi`，图例文字正确。
  - 角色面板：`NeiLie/ShangDiShiJiaoKa` 存在，名称/类型/描述正确，空账本下仍显示。
- 完整八步门禁（2026-11-12，`tests/pao_pi.bat`）：
  - `[1/8] --import`：通过，无 ERROR；
  - `[2/8] ce_zhang_ben`：232 passed, 0 failed；
  - `[3/8] ce_bian_jie`：25 passed, 0 failed；
  - `[4/8] ce_shu_ju`：1422 passed, 0 failed；
  - `[5/8] ce_yao_gan`：8 passed, 0 failed；
  - `[6/8] ce_zhan_dou`：20 passed, 0 failed；
  - `[7/8] ce_jie_suo`：144 passed, 0 failed；
  - `[8/8] ce_panding`：1228 passed, 0 failed；仅预期性 `WARNING: YinXiang: 未知音效名 mei_you_zhe_ge_yin`；
  - 合计 **3079 passed / 0 failed**，输出「全绿：可以交付」。

## 三、视觉实测（临时探针，已清理）

- 用临时 Godot 场景加载 Main，生成机械船，把玩家依次放到地图上/下/左/右/中五个位置，关闭平滑后逐张截图并打印可见矩形：
  - up：相机 `(2064, 547.44)`、zoom 0.658、可见矩形 y 0.0–1094.88；
  - down：相机 `(2064, 1551.56)`、zoom 0.478、可见矩形 y 799.12–2304.0；
  - left：相机 `(1337.67, 912)`、zoom 0.478、可见矩形 x 0.0–2675.34；
  - right：相机 `(2790.33, 912)`、zoom 0.478、可见矩形 x 1452.67–4128.0；
  - mid：相机 `(2064, 912)`、zoom 0.478、可见矩形 x 726.33–2675.34、y 159.56–1664.44。
- 截图目检：四边均显示完整海底背景，无灰色区域；小地图为黑底、首领金色；机械船明显变小。
- 临时探针 `camera_probe.gd/.tscn`、`probe_*.png`、任务包生成脚本与本轮 `build/_web_test/` 调试产物已清理。

## 四、范围与未提交说明

- `git HEAD` 保持 `bcc1f3dfe25267e4c4017946ee076bc7c5640899`。
- 工作区改动：33 个 `data/nengli/*.tres`、`scenes/Main.tscn`、`scripts/ji_qi_chuan.gd`、`scripts/main.gd`、`scripts/she_zhi.gd`、`scripts/xiao_di_tu.gd`、`scripts/yu.gd`、`tests/ce_panding.gd`、`docs/技能图标与特效需求_Gemini_2026-11-10.md`；新增 66 个图标 PNG + 66 个 `.import`、TASK-022 任务包、`docs/特效需求清单_2026-11-12.md`。
- `project.godot` 已恢复为 HEAD 状态（含 `renderer/rendering_method.web="gl_compatibility"`），不在本任务 diff 中。
- **未执行 `git add` / `git commit` / `git push`**；是否提交、提交哪些文件，等待用户指示。
- 仍需用户目检：F5 实机决战镜头与上下边缘、设置面板永久卡、小地图、33 图标在升级三选一/技能栏的实际显示；红测按项目流程另行执行。
</content>
</Write>
