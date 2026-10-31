# TASK-014 交接说明（INTEGRATION_HANDOFF）

> 状态：ready（代码与自动化验证完成；F5 人工验收待用户）

## 交付物

| 文件 | 作用 |
|---|---|
| `scripts/neng_li.gd` | `NengLi` Resource 模具：能力 id、类型、冷却、持续、半径、主值、NPC 覆写、副值、NPC 冷却、每层增量 |
| `data/nengli/*.tres`（5） | 放电麻痹、毒棘护体、极速突进、蛮力冲撞、潜伏突袭 |
| `scripts/neng_li_chou.gd` | 三选一纯函数：排除当前主动、50% 强制最常吃、Fisher-Yates、注入 RNG |
| `scripts/neng_li_dan_chuang.gd` + `scenes/NengLiDanChuang.tscn` | 暂停弹窗：3 张能力卡、连续升级排队、0 候选解冻 |
| `scripts/neng_li_ui.gd` | 右下技能按钮、冷却条、就绪文字、被动层数列表 |
| `scripts/zhang_ben.gd` | 能力账本：主动槽、被动层数、获得历史、食谱、`neng_li_zhuang_bei` 广播、复位 |
| `scripts/yu.gd` | 玩家 5 个能力；`shi_fang_zhu_dong()` 唯一释放入口；切主动清状态 |
| `scripts/yu_npc.gd` | 电鳐/蓑鲉改读能力；旗鱼突进、金枪鱼冲撞、巨口鱼潜伏；潜伏感知 |
| `scripts/yu_zhong.gd` + `data/yuzhong/*.tres` | 鱼种挂 `neng_li`；删除旧 `dian_ma` / `du_xing` |
| `scripts/jie_suan.gd` | 结算页显示主动与被动层数 |
| `tests/ce_panding.gd` | 6p~6u 能力集成用例；总数 193 |
| `tests/ce_zhang_ben.gd` / `ce_bian_jie.gd` / `ce_shu_ju.gd` | 能力账本/复位/数据/三选一校验 |
| `tests/huai_neng_li.tres` | 负值坏能力红测夹具 |
| `tests/pao_pi.bat` | 七步门禁；第 7 步 720 帧 |
| 已删除 | 旧卡脚本 2、场景 1、数据 6、夹具 1；`ZhangBen` 旧卡账本；`Yu` 旧卡 match；`JieSuan` 旧卡读取；`Main.tscn` 旧弹窗 |

## 提供给后续任务的接口

### 数据

- `NengLi.bian_hao: StringName` 是所有能力分派的唯一键。
- `NengLi.shi_zhu_dong()`：主动/被动。
- `NengLi.npc_zhi()`：NPC 数值覆写；`NengLi.ceng_shu_zhi(ceng)`：被动按层数值。
- 鱼种 → 能力只改 `data/yuzhong/*.tres` 的 `neng_li`，不改代码。

### 账本

```gdscript
ZhangBen.zhu_dong_neng_li       # 当前主动（唯一）
ZhangBen.bei_dong_ceng          # bian_hao(StringName) -> 层数
ZhangBen.yi_xuan_neng_li        # 本局获得历史（含被替换的主动）
ZhangBen.chi_yu_ji_lu          # 食谱：bian_hao -> 消化完成条数
ZhangBen.zui_duo_bian_hao       # 本局最常吃的能力 id
ZhangBen.xuan_neng_li(neng)     # 能力装备唯一入口
ZhangBen.dang_qian_bei_dong_ceng(id)
ZhangBen.ji_chi_yu(neng)        # 只由消化完成调用
```

### 玩家

```gdscript
Yu.shi_fang_zhu_dong() -> bool  # 无主动/冷却/失控/施放中都返回 false
Yu.zhu_dong_leng_que           # 冷却剩余
Yu.yin_shen                    # 潜伏中；NPC 索敌跳过
```

- `Yu.shou_dao_yao_ji(伤害, 来源 = null, 部位 = "shen")` 保持单参兼容（`JiQiChuan`）。
- 冲撞期间 `_chong_zhuang_sheng_yu > 0` 屏蔽嘴圈吞与自动咬。

### UI

- `Main/NengLiUI`（`CanvasLayer`，`process_mode=1`）：按钮、冷却条、被动 Label。
- `Main/NengLiDanChuang`（`CanvasLayer`，`layer=100`，`process_mode=3`）：暂停弹窗。
- 技能按钮不自己扣冷却；只调 `Yu.shi_fang_zhu_dong()`。

## 场景树（交付后）

```text
Main (Node2D, main.gd)
├── Haodi
├── Yu (Yu.tscn)
│   ├── AnimatedSprite2D
│   ├── ZuiQu / ShangQu / ChiQu / YaoQu / RouQu
│   └── WudiDingshi
├── YuQun
├── TiXingUI / JiEUI / XiaoHuaUI / KongZhiUI
├── DiTuUI / ShiJianUI / BossUI / XiaoXiUI
├── UI
│   └── YaoGan
├── NengLiUI (CanvasLayer)
│   ├── JiNengAnNiu (Button)
│   ├── LengQueTiao (ProgressBar)
│   ├── LengQueLabel (Label)
│   └── BeiDongLabel (Label)
└── NengLiDanChuang (CanvasLayer, layer=100)
    ├── BanDi
    ├── BiaoTi / TiShi
    └── KaPianZu (Ka1/Ka2/Ka3)
```

## 调参入口

| 想改什么 | 改哪里 |
|---|---|
| 能力冷却/持续/半径/主值/NPC 覆写/副值/NPC 冷却/每层 | `data/nengli/*.tres` |
| 鱼种给什么能力 | `data/yuzhong/*.tres` 的 `neng_li` |
| 三选一强制概率 | `scripts/neng_li_chou.gd` 的 `QIANG_ZHI_GAI_LV = 0.5` |
| 弹窗卡池 | `scenes/NengLiDanChuang.tscn` 的 `neng_li_zu` |
| 技能按钮位置/大小 | `scenes/Main.tscn` 的 `NengLiUI` 节点 |
| 放电玩家/电鳐差异 | `fang_dian_ma_bi.tres` 的 `shu_zhi=100` / `npc_shu_zhi=55` |

## 已退役，不要复活

- `QiangHuaKa`、`QiangHuaDanChuang`、`data/qianghua/`、`data/qianghua_tuiyi/cui_fei.tres`、`tests/huai_ka.tres`
- `ZhangBen.ka_yi_xuan` / `yi_xuan_ka` / `jing_yan_jia_cheng` / `she_jing_yan_jia_cheng` / `xuan_ka`
- `Yu._on_ka_yi_xuan`
- `YuZhong.dian_ma` / `du_xing`
- `Main.tscn` 旧弹窗实例

## 已知限制 / 后续任务注意

- **潜伏语义**：只对玩家索敌与首领追击生效，其他 NPC 仍能看见巨口鱼；若要全隐身需扩展 NPC 感知。
- **放电不打船**：`JiQiChuan` 不在 `yu_npc` 组，玩家放电不命中机器船；是否允许用电打船待平衡。
- **冲撞碰撞**：用 Area2D 重叠查询，极端掉帧可能穿透；见 CODE_REVIEW P3-3。
- **锁定提示**：最常吃能力恰好是当前主动时，弹窗可能显示「已锁定」但实际未锁定；见 P3-1。
- **视觉未人工验收**：放电闪蓝、潜伏 alpha、冲撞摆动、按钮布局待 F5。
- **真机触控**：仍归 TASK-010。
- **技能升级/图标/局外解锁**：未做，留给后续能力扩展任务。

## 集成检查清单

- [x] 能力数据 5 个，鱼种映射正确，旧字段删除
- [x] 账本能力槽/被动层数/食谱/复位与广播
- [x] 三选一算法与弹窗
- [x] 玩家 5 个能力与技能按钮
- [x] NPC 侧 5 种能力消费（4 主动 + 蓑鲉反毒）与潜伏感知
- [x] 旧卡系统整体退役，grep 无残留
- [x] `ce_zhang_ben` 102 / `ce_bian_jie` 21 / `ce_shu_ju` 47 / `ce_yao_gan` 8 / `ce_zhan_dou` 11 / `ce_panding` 193
- [x] `pao_pi.bat` 七步全绿 382
- [x] Main 无头 900 帧无 ERROR
- [x] 任务包 10 文件
- [x] TASK_INDEX / 重构路线 / 学习路线 / 引擎词总表（md + docx）
- [ ] 用户 F5 手测与手感确认
- [ ] 用户按需调 `data/nengli/*.tres` 数值
- [ ] TASK-010 安卓导出恢复（后续）
