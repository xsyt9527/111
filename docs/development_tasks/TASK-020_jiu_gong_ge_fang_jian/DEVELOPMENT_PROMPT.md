# TASK-020: 九宫格房间化（相机边界、换房过渡、刷怪归属与 Boss 房）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：approved（用户确认：两个都确认（推荐））
> 交付状态：approved
> Git 基线：8363e533f9195228621466b45b58fdfb808b4d7b
> 前提：TASK-019 v1 已合并并验证（相机固定 1.0、范围/伤害收口）
> 依据：用户 2026-11-10 九项反馈中的第 7 项；策划案 v0.27

## 一、任务目标

把现有 4128×2304 九宫格背景的 9 个 1376×768 区域切成九个可玩房间，不新增美术、不改存档：

1. 普通探索时 `Camera2D` 的 limit 锁在当前房间，不再一屏看到整张地图。
2. 玩家越过格边界时，用 0.12 秒淡出 + 0.12 秒淡入遮住一屏跳变；黑场中切换房间、相机 limit、玩家位置和鱼群。
3. `YuQun` 按当前房间刷怪/回收；换房清掉旧房普通鱼，新房重新铺鱼。
4. 鲸鲨首领收进东南房间 8，不再跨九格巡逻。
5. 人类战前九图拼合演出与机器船战保留原流程；演出/船战期间临时恢复全图相机。
6. 房间名沿用现有 `_xian_shi_xiao_xi()` 横幅，不新增 HUD 层。

### 完成后可观察结果

- 开局在正中房间 4；相机看不到相邻房间，四个方向走到边界才换房。
- 换房时全屏黑场约 0.24 秒，黑场结束后人在新房 6px 内，横幅显示“进入 <房间名>”。
- 换房后旧房普通鱼消失，新房鱼从房间两侧游入；Boss 始终在东南房间 8。
- 每格都能走到，无黑边、无 ERROR；人类战前九图动画与船战相机不被房间 limit 裁切。

## 二、房间模型（直接复用现有切片）

- 整图：`4128×2304`；单格：`1376×768`；行优先 0..8。
- 房间 4（正中）矩形：`Rect2(1376, 768, 1376, 768)`。
- 房间 8（东南）矩形：`Rect2(2752, 1536, 1376, 768)`。
- 视口 `1280×720`、zoom 1.0 时，一格只比屏幕大 96×48 像素；相机几乎静止，玩家走到房间边缘刚好在屏幕边缘。这正是“一格一屏”的设计，不要额外拉远。
- 房间矩形与 `Main.DI_TU_MEI_GE`、`DiTuPinJieYanChu.MEI_GE_CHI_CUN` 同源；不要新造第二套尺寸。

## 三、实现步骤

### step-01 房间数据与相机边界

文件：`scripts/main.gd`、`tests/ce_panding.gd`

`main.gd` 新增常量与状态：

```gdscript
const DI_TU_CHI_CUN := Vector2(4128.0, 2304.0)  # 整图尺寸：只用于全图相机，不重切美术
const FANG_JIAN_JIN_BIAO_LIU := 6.0  # 换房后夹到新房内 6px：避免站在边界反复触发
const FANG_JIAN_HUAN_CHU_SHI_JIAN := 0.12  # 单程淡入/淡出时长：黑场总计约 0.24 秒
const REN_LEI_QUAN_TU_OFFSET := Vector2(0.0, -260.0)  # 人类战相机上移：机器船在玩家上方 600px
const REN_LEI_QUAN_TU_ZOOM := 0.85  # 人类战取景放宽：能看到船与预警圈
const QUAN_TU_LIMIT := Rect2(0.0, 0.0, 4128.0, 2304.0)  # 人类战/九图演出的全图 limit

var dang_qian_fang_jian := 4  # 当前房间：0..8，行优先；开局正中
var _qie_huan_zhong := false  # 换房过渡中：锁移动，禁止再次触发
var _zhe_hei: ColorRect = null  # 全屏黑幕：运行时建在独立 CanvasLayer，不改 Main.tscn 层级
```

纯函数（不读节点，测试可直接 `load("res://scripts/main.gd").new()` 调用）：

```gdscript
func fang_jian_qu(pian: int) -> Rect2:
    # 九宫格第 pian 格的矩形：行优先，越界夹到 0..8
    var p := clampi(pian, 0, 8)
    var ge_x := p % 3
    var ge_y := int(floor(float(p) / 3.0))
    return Rect2(Vector2(ge_x * DI_TU_MEI_GE.x, ge_y * DI_TU_MEI_GE.y), DI_TU_MEI_GE)

func qu_yu_pian(shijie_wei: Vector2) -> int:
    # 世界坐标落在哪一格：与 DiTuPinJieYanChu.wan_jia_pian 同规则（格边界归右下格）
    var ge_x := clampi(int(floor(shijie_wei.x / DI_TU_MEI_GE.x)), 0, 2)
    var ge_y := clampi(int(floor(shijie_wei.y / DI_TU_MEI_GE.y)), 0, 2)
    return ge_y * 3 + ge_x
```

相机 limit：

```gdscript
func _suo_fang_jian(pian: int) -> void:
    # 只锁 limit，不改 zoom：TASK-019 已把探索 zoom 固定 1.0
    var qu := fang_jian_qu(pian)
    camera.limit_left = int(qu.position.x)
    camera.limit_top = int(qu.position.y)
    camera.limit_right = int(qu.end.x)
    camera.limit_bottom = int(qu.end.y)

func _suo_quan_tu() -> void:
    # 人类战/九图演出专用：恢复整图 limit；不要在这里改 zoom/offset
    camera.limit_left = int(QUAN_TU_LIMIT.position.x)
    camera.limit_top = int(QUAN_TU_LIMIT.position.y)
    camera.limit_right = int(QUAN_TU_LIMIT.end.x)
    camera.limit_bottom = int(QUAN_TU_LIMIT.end.y)
```

`_ready()` 末尾（`_sheng_cheng_jing_sha()` 前后均可，但必须在首帧前）：

```gdscript
dang_qian_fang_jian = qu_yu_pian(yu.global_position)
_suo_fang_jian(dang_qian_fang_jian)
camera.global_position = yu.global_position
camera.reset_smoothing()
_chuang_jian_hei_mu()
yu_qun.qie_huan_fang_jian(fang_jian_qu(dang_qian_fang_jian))
```

黑幕运行时创建（不改 `Main.tscn` 顶层结构）：

```gdscript
func _chuang_jian_hei_mu() -> void:
    # 黑幕放独立 CanvasLayer（layer=100）：盖住 HUD 与所有 CanvasLayer
    var ceng := CanvasLayer.new()
    ceng.name = "FangJianHeiMu"
    ceng.layer = 100
    add_child(ceng)
    _zhe_hei = ColorRect.new()
    _zhe_hei.color = Color(0.0, 0.0, 0.0, 0.0)
    _zhe_hei.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ceng.add_child(_zhe_hei)
    _zhe_hei.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

测试（追加到 `ce_panding.gd` 九图区块后，不覆盖既有断言）：

```gdscript
assert_eq(zhu.fang_jian_qu(4), Rect2(1376, 768, 1376, 768), "正中房间矩形")
assert_eq(zhu.fang_jian_qu(8), Rect2(2752, 1536, 1376, 768), "东南 Boss 房矩形")
assert_eq(zhu.fang_jian_qu(-3), Rect2(0, 0, 1376, 768), "越界房间号夹到 0")
assert_eq(zhu.fang_jian_qu(99), Rect2(2752, 1536, 1376, 768), "越界房间号夹到 8")
assert_eq(zhu.qu_yu_pian(Vector2(2752, 1536)), 8, "格边界归右下格")
assert_eq(zhu.qu_yu_pian(Vector2(1375.9, 767.9)), 0, "左上格右下角仍在 0")
assert_eq(zhu.qu_yu_pian(Vector2(4127, 2303)), 8, "右下角归 8")
assert_eq(zhu.qu_yu_pian(Vector2(-10, -10)), 0, "越界坐标夹到 0")
```

### step-02 换房过渡与玩家夹回

文件：`scripts/main.gd`、`tests/ce_panding.gd`

`_process()` 中把输入与换房判定改成一处置：

```gdscript
yu.fang_xiang = Vector2.ZERO if (yan_chu_zhong or _qie_huan_zhong) else _du_qu_fang_xiang()
...
if not yan_chu_zhong:
    camera.global_position = yu.global_position
    if _zai_ren_lei_zhan():
        camera.offset = REN_LEI_QUAN_TU_OFFSET
        camera.zoom = Vector2.ONE * REN_LEI_QUAN_TU_ZOOM
    else:
        camera.offset = Vector2.ZERO
        camera.zoom = Vector2.ONE / _shi_jiao_bei()
    if not _qie_huan_zhong and not _zai_ren_lei_zhan():
        var pian := qu_yu_pian(yu.global_position)
        if pian != dang_qian_fang_jian:
            _qie_huan_fang_jian(pian)
```

换房协程：

```gdscript
func _qie_huan_fang_jian(pian: int) -> void:
    # 0.12 秒淡出 → 黑场中换房 → 0.12 秒淡入；过渡只锁移动，不取消技能
    if _qie_huan_zhong or yan_chu_zhong or _zai_ren_lei_zhan():
        return
    if pian == dang_qian_fang_jian:
        return
    _qie_huan_zhong = true
    yu.fang_xiang = Vector2.ZERO
    if _zhe_hei != null:
        var an := create_tween()
        an.tween_property(_zhe_hei, "color:a", 1.0, FANG_JIAN_HUAN_CHU_SHI_JIAN)
        await an.finished
    if not is_inside_tree():
        return
    dang_qian_fang_jian = clampi(pian, 0, 8)
    _suo_fang_jian(dang_qian_fang_jian)
    var qu := fang_jian_qu(dang_qian_fang_jian)
    yu.global_position = Vector2(
        clampf(yu.global_position.x, qu.position.x + FANG_JIAN_JIN_BIAO_LIU, qu.end.x - FANG_JIAN_JIN_BIAO_LIU),
        clampf(yu.global_position.y, qu.position.y + FANG_JIAN_JIN_BIAO_LIU, qu.end.y - FANG_JIAN_JIN_BIAO_LIU))
    camera.global_position = yu.global_position
    camera.reset_smoothing()
    yu_qun.qie_huan_fang_jian(qu)
    _xian_shi_xiao_xi("进入 " + DI_TU_MING[dang_qian_fang_jian])
    if _zhe_hei != null:
        var chu := create_tween()
        chu.tween_property(_zhe_hei, "color:a", 0.0, FANG_JIAN_HUAN_CHU_SHI_JIAN)
        await chu.finished
    _qie_huan_zhong = false
```

`_zai_ren_lei_zhan()`：

```gdscript
func _zai_ren_lei_zhan() -> bool:
    # 船已生成且未沉：人类战相机特例；结算前 1.2 秒船已沉，会回到普通取景
    return is_instance_valid(ji_qi_chuan) and not ji_qi_chuan.si_le
```

测试（纯函数部分；过渡协程靠 F5 手测，不做帧级单测）：

```gdscript
# 换房目标：玩家进入哪格就该切到哪格
assert_eq(zhu.qu_yu_pian(Vector2(1376 + 68, 768 + 68)), 4, "从房间 3 跨到 4：落在房间 4 内部")
assert_eq(zhu.qu_yu_pian(Vector2(1375, 1152)), 3, "向左跨一格到 3")
assert_eq(zhu.qu_yu_pian(Vector2(2753, 1152)), 5, "向右跨一格到 5")
assert_eq(zhu.qu_yu_pian(Vector2(2064, 1537)), 7, "向下跨一格到 7")
```

（第一条是边界语义示例；若实现后实际语义不同，以 `wan_jia_pian` 规则为准，不改旧规则。）

### step-03 按房间刷怪、Boss 房与人类战特例

文件：`scripts/main.gd`、`scripts/yu_qun.gd`

`yu_qun.gd` 新增：

```gdscript
var fang_jian_qu := Rect2(0.0, 0.0, 4128.0, 2304.0)  # 当前房间矩形：默认整图，Main 会收窄

func qie_huan_fang_jian(qu: Rect2) -> void:
    # 换房：更新房间、清掉旧房普通鱼、重置计时；Boss 不是 YuQun 子节点，不受影响
    fang_jian_qu = qu
    for zi in get_children():
        if zi is YuNpc and not zi.shi_boss:
            zi.queue_free()
    _da_yu_ji_shi = 0.0
    _hu_chi_ji_shi = 0.0
    if shua_xin_ting_zhi:
        return
    _chong_tian_yu_qun.call_deferred()  # 新房立刻铺一屏，避免黑场后空房
    _kai_xia_yi_lun()  # Timer.start 会重排当前等待，不会叠出第二个刷新循环
```

`_sheng_yu()` 的生成位置改用当前房间边界（y 仍留 60px 边距；x 从房间左右两侧外 0~160px 排队进入）：

```gdscript
var qu := fang_jian_qu
var gao := randf_range(qu.position.y + 60.0, qu.end.y - 60.0)
var tui := randf_range(0.0, 160.0)
if randf() < 0.5:
    xin_yu.fangxiang = 1.0
    xin_yu.position = Vector2(qu.position.x - xin_yu.bianju - tui, gao)
else:
    xin_yu.fangxiang = -1.0
    xin_yu.position = Vector2(qu.end.x + xin_yu.bianju + tui, gao)
```

说明：`Qu` 默认整图时与旧行为一致（旧行为按屏幕两侧生成；整图房间覆盖整图，F5/旧测试不炸）。Main 收窄后鱼从当前房间两侧进入；相机 limit 会把房间外部分裁掉，所以画面上仍是“从屏幕边缘游入”。NPC 游出镜头 240px 自行回收，换房清鱼只是加速。

`main.gd`：

```gdscript
const BOOS_XUN_LUO_DIAN := [
    Vector2(3000.0, 1750.0),  # 东南房间 8 内：左上
    Vector2(3850.0, 1750.0),  # 右上
    Vector2(3850.0, 2100.0),  # 右下
    Vector2(3000.0, 2100.0),  # 左下
]  # 首领只在东南祭坛房间内巡逻，不再跨九格
```

`BOOS_CHU_SHENG_DIAN` 保持 `(3440, 1920)`（已在房间 8 内）。

6 分钟提示改为“盘踞”（Boss 不再全图游荡）：

```gdscript
_xian_shi_xiao_xi("巨影盘踞在 %s" % qu_yu_ming(_jing_sha.global_position))
```

人类战入口/收尾：

```gdscript
func _bo_fang_ren_lei_yan_chu() -> void:
    ...
    _suo_quan_tu()  # 九图演出要 zoom 到全图：必须先解除房间 limit
    yan_chu.bo_fang(...)

func _on_ren_lei_yan_chu_jie_shu() -> void:
    ...
    _suo_quan_tu()  # 船在玩家上方 600px：保持全图 limit，交给 _process 的船战取景
    camera.offset = REN_LEI_QUAN_TU_OFFSET
    camera.zoom = Vector2.ONE * REN_LEI_QUAN_TU_ZOOM
    camera.global_position = yu.global_position
    camera.reset_smoothing()
    _sheng_cheng_ji_qi_chuan()
```

注意：`_bo_fang_ren_lei_yan_chu()` 在隐藏 `Haodi/YuQun` 前设置全图 limit；`DiTuPinJieYanChu` 不动 limit，只动 zoom/offset。

测试（追加）：

```gdscript
assert_eq(_xiang_deng(zhu.fang_jian_qu(8).position.x, 2752.0), 1, "Boss 房左边界 2752")
assert_eq(_xiang_deng(zhu.fang_jian_qu(8).end.y, 2304.0), 1, "Boss 房下边界 2304")
```

Boss 巡逻点常量不在纯函数测试里逐个断言（数组可运行时注入）；F5 确认 Boss 不离开房间 8。

### step-04 全量验证、文档与清理

- `tests/ce_panding.gd` 追加上述房间用例；**不覆盖** TASK-019 已改的相机/船战/Boss 断言。
- 跑 `tests/pao_pi.bat` 连续两轮八步全绿（仍八步，不新增第九步）。
- F5 手测九格换房、房间名、刷怪、Boss 房、人类战前动画与船战相机。
- 更新 `docs/TASK_INDEX.md`、`docs/引擎词总表.md`、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx` 的房间章节。
- 清理临时文件；不 commit / 不 push。

## 四、文件边界

允许修改：

- `scripts/main.gd`（全部房间逻辑、人类战相机特例、Boss 巡逻点）
- `scripts/yu_qun.gd`（房间刷怪/回收）
- `tests/ce_panding.gd`（只追加房间用例）
- `scenes/Main.tscn`（仅在确有必要时改 Camera2D 初始 limit；运行时设置优先，尽量不改）
- 文档三份 + docx

禁止修改：

- TASK-019 所有文件（`zhang_ben.gd`、`yu_npc.gd`、`ji_qi_chuan.gd`、`zhan_dou.gd`、`ji_neng_fan_wei.gd`、`neng_li.gd`、进化模块）
- `scripts/di_tu_pin_jie_yan_chu.gd`（九图演出流程）
- `scripts/zhi_wu_qun.gd`（植物仍全图预生成，相机只显示当前房）
- `scripts/yu.gd`（玩家仍夹整图，允许越界触发换房）
- `project.godot`、Autoload、存档 schema、主场景顶层节点类型
- `.agents/skills/**`（只读）

## 五、风险与回退

1. **相机几乎静止**：房间 1376×768 只比 1280×720 视口大 96×48；这是“一格一屏”的预期。若觉得太死板，下一轮再做相机微跟随/房间内小范围平移，不在本轮。
2. **人类战相机**：全图 limit + offset `(0,-260)` + zoom 0.85 必须覆盖玩家上方 600px 的船。F5 若仍裁切，调 `REN_LEI_QUAN_TU_ZOOM` 到 0.8 或 offset 到 -300，不改九图演出。
3. **换房清鱼**：只清 `YuNpc` 且 `not shi_boss`；不得用 `get_children().clear()` 或 `queue_free()` 清整个 YuQun（Timer 也在里面）。
4. **反复越界**：夹回 6px 是硬要求；没有它，玩家站在边界会每帧触发换房。
5. **Boss 房平衡**：Boss 固定在房间 8 后，玩家可在房间外成长再进；F5 确认 6 分钟提示和提前开战仍成立。
6. **回退**：所有改动集中在 `main.gd`/`yu_qun.gd`/`ce_panding` 追加块；删除新增常量与函数、恢复 Boss 巡逻点即可回到旧行为；不得回滚 TASK-019。

## 六、交付口径

- 完成后 `delivery_status=review`、`handoff_status=pending`、`last_verified_commit=null`。
- 在 `TASK_STATE.json` 记录每步 changed_files/check_results；在任务包内补实现报告。
- 不 commit / 不 push；不把房间状态写存档。
