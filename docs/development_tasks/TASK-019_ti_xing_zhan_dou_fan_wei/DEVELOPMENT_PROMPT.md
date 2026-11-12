# TASK-019: 体型战斗手感、技能范围统一与人类船伤害修正

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：approved（用户确认：两个都确认（推荐））
> 交付状态：approved
> Git 基线：8363e533f9195228621466b45b58fdfb808b4d7b
> 依据：用户 2026-11-10 九项反馈中的 1/2/3/6/8；策划案 v0.27

## 一、任务目标

把“体型”重新变成看得见、打得出、范围算得准的核心变量：

1. 首领变小时，不能仍按玩家升级后的新体型咬出 90% 伤害。
2. 升级瞬间给玩家 0.6 秒无敌和视觉脉冲，避免刚升级就被同一口咬残。
3. 体型显示缩放每满 5 点额外 ×1.06，让 Lv.5/Lv.10/Lv.15 有可见跳变。
4. 技能范围指示与实际命中统一按体型换算，修复“6 身位技能画成 6px”的显示 bug。
5. 固定探索镜头 1.0×，让体型增长不被镜头拉远抵消。
6. 可吃红光放大；人类机器船战双向伤害提高。

### 完成后可观察结果

- 同体型 Boss 咬玩家仍约 90%；小体型 Boss 对 10 体型玩家约 18%，不再一口 90%。
- 玩家升级瞬间 0.6 秒无敌，精灵有 1→1.16→1 脉冲。
- Lv.1 与 Lv.10 的屏幕体型占比明显变大，无黑边。
- 长按 6 身位技能，范围圈约为 6×100×scale，不再只有 6px。
- 固定 90px 的技能在高体型下不小于 0.5 条鱼。
- 可吃小鱼红光比本体大约 2.1 倍，食物约 1.8 倍。
- Lv.8 咬船弱点约 6.72/口、船体约 1.568/口；船招伤害随玩家体型上升。
- `tests/pao_pi.bat` 八步全绿，无 `ERROR`。

## 二、五步实现

### step-01 体型曲线、Boss 咬伤与升级反馈

**A. 体型里程碑**（`scripts/zhang_ben.gd`）

保持 `TI_XING_QU_XIAN=0.7`，在 `ti_xing_dao_chi_du()` 里加：

```gdscript
var li_cheng_bei := pow(1.06, floor(maxf(ti_xing_zhi, 0.0) / 5.0))
return TI_XING_XI_SHU * pow(maxf(ti_xing_zhi, 0.0), TI_XING_QU_XIAN) * li_cheng_bei
```

要求：`ti_xing_dao_chi_du(0.0)==0.0`、`ti_xing_dao_chi_du(1.0)==0.32` 保持不变；体型 5/10/15 各有一次新跳变；仍低于线性。

**B. Boss 咬伤**（`scripts/yu_npc.gd`）

保留 `BOOS_YAO_SHANG_HAI_BEI=15.0`，把：

```gdscript
static func boos_yao_shang_hai(shou_ti: float, zui_ba: float) -> float:
    return ZhanDou.yao_ji_shang_hai(0.0, shou_ti, zui_ba) * BOOS_YAO_SHANG_HAI_BEI
```

改为：

```gdscript
static func boos_yao_shang_hai(shou_ti: float, zui_ba: float, gong_ti := -1.0) -> float:
    var you_xiao_ti_xing := shou_ti
    if gong_ti > 0.0:
        you_xiao_ti_xing = minf(shou_ti, gong_ti)
    return ZhanDou.yao_ji_shang_hai(0.0, you_xiao_ti_xing, zui_ba) * BOOS_YAO_SHANG_HAI_BEI
```

调用点（约 `yu_npc.gd:718`）传 `tixing`：

```gdscript
shang_hai = boos_yao_shang_hai(shou_ti, zui_ba, tixing)
```

要求：`boos_yao_shang_hai(1.0, 2.0)` 仍为 0.9；`boos_yao_shang_hai(10.0, 2.0, 2.0)` 为 1.8；同体型 10/10/2.0 仍为 9.0。

**C. 升级免伤/脉冲**（`scripts/yu.gd`）

在玩家 `_ready()` 连接 `ZhangBen.sheng_ji`（只连玩家实例；`YuNpc` 不连）：

```gdscript
ZhangBen.sheng_ji.connect(_on_sheng_ji)

func _on_sheng_ji(_deng_ji: int) -> void:
    jin_ru_wudi(0.6)
    var jing_ling := get_node_or_null("AnimatedSprite2D")
    if jing_ling == null:
        return
    jing_ling.scale = Vector2.ONE
    var tui := create_tween()
    tui.tween_property(jing_ling, "scale", Vector2.ONE * 1.16, 0.18) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tui.tween_property(jing_ling, "scale", Vector2.ONE, 0.27) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

要求：只动 `AnimatedSprite2D.scale`，不动根节点 `scale`（根节点归体型补间）；重复升级时杀掉旧 tween（`if _sheng_ji_tui != null: _sheng_ji_tui.kill()`）。

**D. 红光**

- `scripts/yu_npc.gd`：`HONG_GUANG_FANG_DA 1.5 -> 2.1`
- `scripts/ke_chi_wu.gd`：`HONG_GUANG_BEICHENG 1.55 -> 1.8`

只改表现层，不改可吃判定/碰撞圈。

**E. 测试**

- `tests/ce_zhang_ben.gd`：体型 5/10/15 里程碑；体型 10 的显示缩放比旧公式约多 12%；`ti_xing_dao_chi_du(0.0)`/`(1.0)` 边界；仍低于线性；不修改 `MEI_CI_SHANG_HAI`。
- `tests/ce_panding.gd`：Boss 两参兼容 0.9；三参 1.8；同体型 9.0；升级后 `wudi` 为真（实例化玩家或直接驱动 `ZhangBen.jia_jing_yan`）。

### step-02 人类机器船双向伤害

**A. 玩家咬船**（`scripts/zhan_dou.gd`）

```gdscript
const JIU_SHANG_HAI_XI_SHU := 0.24
const JIU_SHANG_HAI_JI_CHU := 0.08
```

保留 `jiu_yao_ji_shang_hai(gong_ji_ti_xing, zui_ba)` 签名。Lv.8 体型 9、嘴 1.0：`0.24*9+0.08=2.24`；船体 -30% = 1.568；玻璃舱 ×3 = 6.72。

**B. 船招对玩家**（`scripts/ji_qi_chuan.gd`）

新增：

```gdscript
const WAN_JIA_TI_XING_SHANG_HAI_BI := 0.04
```

炸弹/猫/鱼叉三处伤害改为：

```gdscript
ZHA_DAN_SHANG_HAI + yu.tixing * WAN_JIA_TI_XING_SHANG_HAI_BI
MAO_SHANG_HAI + yu.tixing * WAN_JIA_TI_XING_SHANG_HAI_BI
YU_CHA_SHANG_HAI + yu.tixing * WAN_JIA_TI_XING_SHANG_HAI_BI
```

其中 `yu` 是玩家引用；若船脚本没有稳定玩家引用，从现有 `mu`/`wan` 字段取，不要新增 Autoload。避免重复扣血：只改伤害计算，不改命中时序。

**C. 测试**

- `tests/ce_zhan_dou.gd`：旧公式系数 0.24/0.08；9 体型 → 2.24。
- `tests/ce_panding.gd`：船体 1.568、弱点 6.72、360 血约 54 口；船招在体型 10 时炸弹 1.4、猫 1.1、鱼叉 1.0（按实际常量命名断言）。

### step-03 技能范围统一入口与指示修复

**A. `Yu` 新函数**（`scripts/yu.gd`）

```gdscript
const TI_CHANG_HUI_TUI := 208.0

func ti_chang() -> float:
    var jing_ling := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
    if jing_ling != null and jing_ling.sprite_frames != null \
            and jing_ling.sprite_frames.has_animation(jing_ling.animation):
        var zhen := jing_ling.sprite_frames.get_frame_texture(
                jing_ling.animation, jing_ling.frame)
        if zhen != null:
            return zhen.get_width() * maxf(scale.x, 0.01)
    return TI_CHANG_HUI_TUI * maxf(scale.x, 0.01)

func fan_wei_xiu_zheng(shijie_ban_jing: float, zui_xiao_bei := 0.5) -> float:
    return maxf(shijie_ban_jing, ti_chang() * maxf(zui_xiao_bei, 0.0))

func ji_neng_ban_jing(neng: NengLi, dang: int, zui_xiao_bei := 0.5) -> float:
    var ban := neng.dang_zhi(&"ban_jing", maxi(dang, 1))
    if ban <= 0.0:
        ban = neng.ban_jing
    var shijie := ban
    if neng.ban_jing_shen_wei:
        shijie = ban * _shen_wei()
    else:
        shijie = ban * maxf(1.0, scale.x)
    return fan_wei_xiu_zheng(shijie, zui_xiao_bei)
```

口径：范围圆/自身圆 `0.5 体长`；突进长度 `1.5 体长`。只作用于主动，被动保持原口径。

**B. 基础主动 8 处**（`scripts/yu.gd`）

现有直接 `neng.ban_jing` / `neng.dang_zhi(&"ban_jing", dang)` 的固定像素主动，改为：

```gdscript
var ban := ji_neng_ban_jing(neng, dang, 0.5)
```

突进类用 `1.5`。不要把已经带 `_shen_wei()` 的专属主动再乘一次身位。

**C. 进化模块**（`scripts/zhuan_shu_ku/*.gd`）

把主动半径最终值包上：

```gdscript
ban = fan_wei_xiu_zheng(ban, 0.5)   # 范围
ban = fan_wei_xiu_zheng(ban, 1.5)   # 突进长度
```

保留各模块自己的基因/状态/档位乘数；只加最后一道视觉下限。重点排查 `LEI_BAO_LUO_LEI_BAN_JING=100` 注释“像素≈1身位”却在调用处又 `*_shen_wei()` 的二次乘法；改成身位值 1.0 或去掉二次乘。

**D. 范围指示**（`scripts/ji_neng_fan_wei.gd`）

`xian_shi(neng, zhong_xin, fang_xiang, wan_jia: Yu = null)`；`_qu_ban_jing` 优先：

```gdscript
if wan_jia != null:
    return wan_jia.ji_neng_ban_jing(neng, dang, zui_xiao_bei)
```

无玩家时保持旧逻辑（兼容纯函数测试）。调用方 `scripts/neng_li_ui.gd:221` 传玩家实例。突进/直线指示按 1.5 体长下限；圆形按 0.5。

**E. 测试**

- `tests/ce_panding.gd`：`JiNengFanWei` 显示 6 身位技能时半径约 600（scale 1）；固定 90px 技能在高体型下不小于 0.5 体长；范围指示和命中入口一致。
- 六份 `ce_zhuanshu_*.gd`：只更新因下限/单位修正变化的期望，不删除既有断言。

### step-04 固定 1.0 倍探索镜头

`scripts/main.gd`：

```gdscript
const SHI_JIAO_MEI_JI := 0.0
```

`_shi_jiao_bei()` 保持 `minf(1.0 + SHI_JIAO_MEI_JI * mini(...), SHI_JIAO_FENG_DING)`，结果恒 1.0。`camera.zoom = 1.0/_shi_jiao_bei()` 仍成立。

`tests/ce_panding.gd`：Lv0/Lv5/Lv10/Lv20 全部断言 1.0；保留“Lv20 不继续放大”语义（现在恒 1.0）。

不碰 TASK-020 的 Camera2D limit、房间状态、刷怪；只改相机常量/函数。

### step-05 全量验证、文档与清理

- 连续两轮 `tests/pao_pi.bat` 八步全绿，记录 Results 断言数；任何 `ERROR` 判红。
- `check_task_scope.py check` 无违例。
- 更新 `docs/TASK_INDEX.md`、`docs/引擎词总表.md`（体型/范围/船战/镜头章）、`LEARNING_ROADMAP.md`、`Godot引擎词总表.docx`。
- 清理临时脚本、调试截图、渲染中间文件；不 commit / 不 push。
- 回填 `IMPLEMENTATION_REPORT.md`、`VERIFICATION_REPORT.md`、`CODE_REVIEW.md`、`INTEGRATION_HANDOFF.md`、`TASK_STATE.json`。

## 三、零触碰红线

- `.agents/skills/**` 只读。
- `tests/` 既有文件不得删除（可改断言）。
- 不碰 `main.gd` 的房间逻辑、`yu_qun.gd`、`di_tu_pin_jie_yan_chu.gd`、`zhi_wu_qun.gd`（TASK-020）。
- 不新增 Autoload、不改存档 schema、不改主场景顶层结构。
- 不覆盖/不回滚上一轮 33 张主动图标及其 `data/nengli` 改动。
- 不 commit / 不 push。

## 四、学习契约

| # | 目标 | 验证时机 |
|---|---|---|
| 1 | 解释 Boss 咬伤为何要同时受攻击者/目标体型限制 | orientation / step-01 |
| 2 | 指出当前体型、显示缩放、技能半径各在哪个函数换算 | step-01 / step-03 |
| 3 | 区分 `ban_jing_shen_wei` 两种单位，并说明显示与命中同源 | step-03 |
| 4 | 解释固定 1.0 镜头对体型可见性的作用 | step-04 |
| 5 | 说出人类船战两个方向各自读取什么 | step-02 |
| 6 | 亲手跑一次门禁红绿（Boss 第三参/范围下限）并解释 ERROR 筛查 | step-05 |
