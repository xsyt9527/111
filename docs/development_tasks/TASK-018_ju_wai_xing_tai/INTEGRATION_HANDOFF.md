# TASK-018 交接说明（INTEGRATION_HANDOFF）

> 状态：实现与自动化验证完成，交付 `review` / 交接 `pending` / 学习 `not_started`。**未 commit / 未 push**，`last_verified_commit = null`。本文件说明已交付接口、场景树、已知限制与 F5 验收清单。

## 交付物

| 文件 | 作用 |
|---|---|
| `scripts/xing_tai.gd` | 形态 Resource 模具（`class_name XingTai`） |
| `data/xingtai/deng_long_yu.tres` | 灯笼鱼：阈值 0、Lv.0、速度 300、嘴巴 1.0、转向 7.0、无初始主动 |
| `data/xingtai/dian_yao.tres` | 电鳐：阈值 1、Lv.1、速度 260、嘴巴 1.0、转向 6.0、放电麻痹 |
| `data/xingtai/qi_yu.tres` | 旗鱼：阈值 2、Lv.0、速度 360、嘴巴 0.85、转向 7.5、极速突进 |
| `data/donghua/dian_yao_1zhen.tres` | 电鳐单帧 `SpriteFrames`，动画名 `"you"` |
| `data/donghua/qi_yu_1zhen.tres` | 旗鱼单帧 `SpriteFrames`，动画名 `"you"` |
| `scripts/cun_dang.gd` | 局外 JSON 存档、胜场解锁、当前形态、胜利写档、调试入口 |
| `scenes/XingTaiXuanZe.tscn` + `scripts/xing_tai_xuan_ze.gd` | 启动形态选择页（动态三卡、锁定禁用、调试按钮） |
| `scripts/zhang_ben.gd` | `dang_qian_xing_tai` / `kai_ju_xing_tai()` / `chong_zhi_bao_liu_xing_tai()` |
| `scripts/yu.gd` | `ying_yong_xing_tai()`，`_ready()` 首帧应用形态 |
| `scripts/main.gd` | 首帧 `camera.zoom` 按开局等级取景 |
| `scripts/jie_suan.gd` + `scenes/JieSuan.tscn` | 「换形态」按钮、解锁提示、保留形态重开 |
| `scripts/yu_npc.gd` | 离树保护：死亡切场景时旧鱼不再读视口 |
| `project.godot` | `CunDang` Autoload（在 `ZhangBen` 后）、`run/main_scene = XingTaiXuanZe.tscn` |
| `tests/ce_jie_suo.gd` | 局外存档纯逻辑测试（58 断言） |
| `tests/huai_xing_tai.tres` | 负速度坏形态红测夹具 |
| `tests/pao_pi.bat` | 八步门禁 |

## 提供给后续任务的接口

### `XingTai`（Resource）

```gdscript
bian_hao: StringName
ming_zi: String
miao_shu: String
dong_hua: SpriteFrames      # 必须含 "you"
kai_ju_deng_ji: int
yi_dong_su_du: float
zui_ba: float
zhuan_xiang_ji_su: float
kai_ju_neng_li: NengLi      # null = 无
jie_suo_sheng_li_ci_shu: int
```

加形态的步骤：新建 `.tres` → 在 `scripts/cun_dang.gd` 的 `XING_TAI_ZU` 登记 → `ce_shu_ju` 的形态数量/数值断言同步。

### `CunDang`（Autoload）

| 成员 | 说明 |
|---|---|
| `sheng_li_ci_shu` | 累计胜场（解锁唯一依据） |
| `dang_qian_bian_hao` | 当前形态 id |
| `XING_TAI_ZU` | 显式 `preload` 注册表 |
| `zai_ru()` / `bao_cun()` | 读/写 `user://shenhaishiji_jin_du.json` |
| `ji_lu_sheng_li() -> Array[XingTai]` | 胜场 +1，返回跨阈值新解锁形态并写档 |
| `qu_xin_jie_suo() -> Array[XingTai]` | 取走瞬时解锁提示（只消费一次） |
| `shi_fou_jie_suo()` / `ke_xuan_xing_tai()` / `suo_you_xing_tai()` / `dang_qian_xing_tai()` / `xuan_ze()` | 查询与选择 |
| `tiao_shi_jie_suo_quan_bu()` / `tiao_shi_qing_chu_jin_du()` | 编辑器调试，会写档 |

存档 schema v1：

```json
{
  "ban_ben": 1,
  "sheng_li_ci_shu": 0,
  "dang_qian_xing_tai": "deng_long_yu"
}
```

### `ZhangBen`

- `dang_qian_xing_tai: XingTai`：本局形态引用。
- `kai_ju_xing_tai(xing_tai) -> bool`：开局装配；幂等；不走 `jia_jing_yan`，不触发三选一。
- `chong_zhi_bao_liu_xing_tai()`：复位局内账本并装回当前形态。
- `chong_zhi()`：纯复位，末尾清 `dang_qian_xing_tai` 与 `xing_tai_yi_ying_yong`。

### `Yu`

- `ying_yong_xing_tai(xing_tai: XingTai)`：应用速度/嘴巴/转向 + `SpriteFrames`，清 `flip_h`/`rotation`。
- `_ready()` 顶部自动读取 `ZhangBen.dang_qian_xing_tai`。

## 场景树（交付后）

```text
Autoload: ZhangBen → CunDang

启动 run/main_scene
└── XingTaiXuanZe (CanvasLayer, xing_tai_xuan_ze.gd)
    ├── BanDi (ColorRect 1280×720)
    ├── BiaoTi / FuBiaoTi
    ├── KaPianZu (HBoxContainer) → 动态 3 张 PanelContainer
    ├── TiShi
    └── DiaoShiZu（仅编辑器：解锁全部 / 清空进度）

选卡成功 → Main.tscn
Main → 胜利/失败/死亡 → JieSuan.tscn
JieSuan:
├── ChongKai（再来一次，保留形态）→ Main.tscn
├── HuanXingTai（换形态）→ XingTaiXuanZe.tscn
└── JieSuoTiShi（胜利且新解锁时显示）
```

## 已知限制 / 后续任务注意

1. **未 commit / 未 push**：`last_verified_commit = null`，任务包只能记 `review` / `pending`。合并前需按项目流程审阅工作区。
2. **F5 手测与学习验收未执行**：`LEARNING_STATE.json` 为 `not_started`；学习记录与检查点待用户参与后回填。
3. **TASK-014 遗留旧场景已清理**：`scenes/QiangHuaDanChuang.tscn` 已删除。它曾引用已删除的 `qiang_hua_dan_chuang.gd` / `qiang_hua_ka.gd` / `data/qianghua/*.tres`，导致 `--import` 报 12 条 `ERROR`；删除并清理 `.godot/editor` 后为 0 `ERROR`。
4. **导出包未验证**：`preload` 注册表与 `user://` 存档在 PCK/安卓导出后的行为未实测（TASK-010）。
5. **直接 F6 跑 Main 会跳过选择页**：使用 `ZhangBen.dang_qian_xing_tai == null`，即默认灯笼鱼；这是调试路径，正式入口是 `run/main_scene`。
6. **调试按钮只在编辑器构建可见**：`OS.has_feature("editor")`；导出 debug 包也不会出现。
7. **存档失败不阻断开局**：`bao_cun()` 失败只 `push_warning`；`xuan_ze()` 仍返回 true。若产品需要「存档失败提示」，后续再上抛。
8. **形态平衡待手感确认**：电鳐 Lv.1 开局体型 2.0、速度 260；旗鱼 360 速度 + 0.85 嘴巴。数值集中在 `data/xingtai/*.tres`，可直接调。
9. **碰 Boss 死亡报错已修复**：`YuNpc._process()` / `_shi_jiao_fan_wei()` 在离树后直接返回，不再读视口。回归断言在 `tests/ce_panding.gd`；若后续新增节点在切场景后仍被手动 `_process()`，需同样加 `is_inside_tree()` guard。

## 集成检查清单

- [x] headless 导入零错误
- [x] 八步门禁全绿、无 ERROR（540 断言）
- [x] Main / 选择页 / 结算页无头冒烟
- [ ] F5 全流程手测（待用户）
- [ ] 学生 godot-inspection / verification-handoff（待用户）
- [x] 报告与文档同步（本文件、实现/验证/评审、TASK_INDEX、LEARNING_ROADMAP、CHONG_GOU_LU_XIAN、引擎词总表）
- [x] `validate_task.py` / `check_task_scope.py check` 最终复跑（VALID / 0 violation）
- [x] 不 commit / 不 push（任务包记 review/pending）

## 调参入口

| 想改什么 | 去哪里 |
|---|---|
| 形态数值/解锁胜场/初始能力 | `data/xingtai/*.tres` |
| 加形态 | 新建 `.tres` → 登记 `scripts/cun_dang.gd` 的 `XING_TAI_ZU` |
| 存档路径/版本 | `scripts/cun_dang.gd` 的 `MO_REN_LU_JING` / `BAN_BEN` |
| 选择页布局/卡片尺寸 | `scenes/XingTaiXuanZe.tscn` + `scripts/xing_tai_xuan_ze.gd` |
| 结算按钮/解锁提示位置 | `scenes/JieSuan.tscn` 的 `HuanXingTai` / `JieSuoTiShi` |
| 开局镜头 | `scripts/main.gd` 的 `_shi_jiao_bei()` 调用处 |
