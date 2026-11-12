# TASK-020 实现报告（2026-11-10）

## 交付状态

- 任务：TASK-020 v1「九宫格房间化：相机边界、换房过渡、按房刷怪与 Boss 房」
- 审批：用户确认「两个都确认（推荐）」；manifest `approved` / `delivery_status=approved`
- 实现基线：`8363e533f9195228621466b45b58fdfb808b4d7b`（TASK-019 完成后捕获）
- 当前状态：`delivery_status=review`、`handoff_status=pending`、`last_verified_commit=null`
- 未 commit、未 push。

## 一、生产改动

### 1. 房间数据与相机边界

- `scripts/main.gd`
  - 新增常量：`DI_TU_CHI_CUN=(4128,2304)`、`FANG_JIAN_JIN_BIAO_LIU=6.0`、`FANG_JIAN_HUAN_CHU_SHI_JIAN=0.12`、`REN_LEI_QUAN_TU_OFFSET=(0,-260)`、`REN_LEI_QUAN_TU_ZOOM=0.85`、`QUAN_TU_LIMIT=Rect2(0,0,4128,2304)`。
  - 新增状态：`dang_qian_fang_jian=4`、`_qie_huan_zhong`、`_zhe_hei`。
  - 纯函数 `fang_jian_qu(pian)`：行优先 0..8，越界夹 0/8；房间 4=`Rect2(1376,768,1376,768)`，房间 8=`Rect2(2752,1536,1376,768)`。
  - 纯函数 `qu_yu_pian(shijie_wei)`：与 `DiTuPinJieYanChu.wan_jia_pian` 同规则，格边界归右下格。
  - `_suo_fang_jian(pian)` / `_suo_quan_tu()` 只写 `Camera2D.limit_left/top/right/bottom`，不改 zoom/offset。
  - `_ready()` 末尾在首帧前根据玩家位置设当前房间、锁 limit、对准相机、创建黑幕、初始化鱼群。
  - `_process()` 普通探索每帧恢复当前房间 limit，人类战由 `_zai_ren_lei_zhan()` 短路；跨格才触发换房。

### 2. 换房过渡

- `main.gd` 的 `_qie_huan_fang_jian(pian)`：
  - 0.12 秒淡出 → 黑场中更新房间/limit → 玩家夹到新房内 6px → `camera.reset_smoothing()` → `yu_qun.qie_huan_fang_jian(rect)` → 「进入 <房间名>」横幅 → 0.12 秒淡入。
  - `_qie_huan_zhong` 防重复触发；过渡期间 `yu.fang_xiang = Vector2.ZERO`，只锁移动，不取消技能。
  - 黑幕运行时建在独立 `CanvasLayer("FangJianHeiMu", layer=100)` + 全屏 `ColorRect`，`mouse_filter=IGNORE`，不改 `Main.tscn` 顶层结构。
  - `_zhe_hei == null`（测试/异常初始化）时跳过淡入淡出但仍完成换房。

### 3. 按房间刷怪与 Boss 房

- `scripts/yu_qun.gd`
  - 新增 `fang_jian_qu := Rect2(0,0,4128,2304)`，默认整图，Main 启动后收窄。
  - 新增 `qie_huan_fang_jian(qu)`：更新房间 → 只清 `YuNpc and not shi_boss` → 重置大体型/互吃计时 → `shua_xin_ting_zhi` 时直接返回，否则 deferred 补一屏并重启 Timer。
  - 清鱼采用 `remove_child(zi)` + `zi.queue_free()`：`queue_free` 当帧仍算在 `get_children()` 里，纯 `queue_free` 会让 deferred 补屏落空。
  - `_sheng_yu()` 改用房间矩形：y 在房间内留 60px，x 从房间左右两侧外 `鱼半径 + 0~160px` 排队进入；相机 limit 裁掉房外部分。
- `main.gd`
  - `BOOS_CHU_SHENG_DIAN` 保持 `(3440,1920)`；巡逻点改为 `(3000,1750)/(3850,1750)/(3850,2100)/(3000,2100)`，全部在房间 8。
  - 6 分钟提示改为「巨影盘踞在 %s」。
  - 人类战入口 `_bo_fang_ren_lei_yan_chu()` 先 `_suo_quan_tu()`；结束 `_on_ren_lei_yan_chu_jie_shu()` 保持全图 limit，offset/zoom 取景后再生成船。
  - 船沉后 `_process` 的普通探索分支每帧写回当前房间 limit，把人类战借用的全图取景归还。

## 二、测试与门禁

- `tests/ce_panding.gd` 追加：
  - 房间矩形/越界/格边界/四方向换房目标/Boss 房边界；
  - 6px 夹回与 0.12 秒常量；
  - 给游离 `main.gd` 实例塞假 `Camera2D`，断言房间 4/8 与全图 limit 的写入值；
  - 未把 Main 拉进测试树，不影响启动整局。
- 目标测试：`ce_panding` **960 passed, 0 failed**，退出码 0，无 ERROR（仅有既有 `YinXiang` 未知音效名 WARNING）。
- `tests/pao_pi.bat` 连续两轮八步全绿：
  - 第一轮：232 / 25 / 1422 / 8 / 20 / 144 / 960 passed，0 failed，无 ERROR。
  - 第二轮：断言数同上，仍全绿；合计 2811 断言。
- `validate_task.py`：VALID。
- `check_task_scope.py check`：0 violation。

## 三、执行中偏差（均在允许文件内）

1. `qie_huan_fang_jian` 清鱼先 `remove_child` 再 `queue_free`：为让 deferred 补屏看到空房，避免新房为空。
2. `_process` 普通探索每帧写回房间 limit：为在船沉后归还人类战的全图 limit。
3. `tests/ce_panding.gd` 修正上轮未提交的九图断言常量笔误 `WAN_JIA_JIAO` → `WAN_JIA_JU_JIAO`（脚本无前者，会导致测试脚本无法加载）；TASK-019 断言未动。

## 四、未完成/需用户参与

1. **F5 手测未由 AI 执行**：
   - 四方向换房黑场 0.24 秒手感、对角越界只触发一次、房间名横幅；
   - 换房后鱼密度（房间比屏幕仅宽 96px，部分房外排队鱼可能被 240px 回收线吃掉）；
   - Boss 巡逻不出房间 8；
   - 人类战全图相机 offset/zoom 是否完整覆盖上方 600px 的船。
2. **红测未执行**：把 `fang_jian_qu` 房间尺寸改成整图或删掉 6px 夹回，确认测试能抓住；建议用户在学习检查点做一次。
3. 学习检查点（orientation / inspection / verification-handoff）仍为 `not_started`；本报告不把 AI 实现当学习证据。

## 五、已知边界

- 换房是全屏淡入淡出，不是无缝滚动；不做门锁/钥匙/顺序封印。
- Boss 固定在房间 8：若玩家把它引出房间，追击逻辑没有额外房间夹取；本轮只保证出生/巡逻点在房内。
- 船沉后若玩家在船战期间跨房，结算前 1.2 秒会按当前位置恢复房间取景；未做额外跨房补切。
- `yu_qun._shi_jiao_fan_wei()` 现保留未用（`yu_npc.gd` 仍有同名独立实现），无警告。

## 六、回退

- 删除 `main.gd` 房间常量/状态/`fang_jian_qu`/`qu_yu_pian`/`_suo_fang_jian`/`_suo_quan_tu`/`_chuang_jian_hei_mu`/`_qie_huan_fang_jian` 及 `_ready`/`_process` 中的房间调用，恢复 Boss 四巡逻点到旧值。
- 删除 `yu_qun.gd` 的 `fang_jian_qu`/`qie_huan_fang_jian`，把 `_sheng_yu` 的生成位置改回 `_shi_jiao_fan_wei()`。
- 删除 `ce_panding` 房间用例；恢复九图常量笔误没有必要（那是坏引用）。
- 不 commit / 不 push；回退不得覆盖 TASK-019 的体型/范围/船战改动。
