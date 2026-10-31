# TASK-014 学习记录（LEARNING_RECORD）

## 状态

本任务以「实现 + 自动化验证」方式完成，**尚未进行教学对话与学生学习验收**。本文件先登记本课要掌握的概念、验收问题与待补证据；用户 F5 手测后可在此补记录。

## 学习目标

| # | 目标 | 验证方式 | 状态 |
|---|---|---|---|
| 1 | 解释 `NengLi` 为什么用 Resource + `.tres`，而不是给每种能力写一个类 | 口头复述 / 编辑器检查 | 待验收 |
| 2 | 解释「一份定义两处消费」：玩家与 NPC 如何共用同一份能力数据 | 说出 `shu_zhi` 与 `npc_shu_zhi` 的分叉 | 待验收 |
| 3 | 说出主动与被动在账本里的区别（唯一槽 vs 叠层） | 口头复述 | 待验收 |
| 4 | 解释三选一为什么用注入 RNG + Fisher-Yates，而不是 `Array.shuffle()` | 说出测试可复现 | 待验收 |
| 5 | 解释弹窗为什么要 `process_mode=WHEN_PAUSED` + `layer=100` + 成对解冻 | 指出暂停/恢复路径 | 待验收 |
| 6 | 说出切换主动时为什么要清极速/冲撞/潜伏状态 | 举一个旧效果残留的失败场景 | 待验收 |
| 7 | 解释潜伏为什么只改索敌，不改碰撞/咬击 | 说出三种破隐时机 | 待验收 |
| 8 | 解释 `is_instance_valid` 防 freed instance 的必要性 | 复述 Main 冒烟抓到的错误 | 待验收 |
| 9 | 说出旧卡退役涉及的五层：脚本/场景/数据/账本/测试 | 指出至少三处删除 | 待验收 |

## 本课新概念

- **数据驱动能力**：`NengLi extends Resource`，能力是数据，不是类；加能力只加 `.tres` 和鱼种引用。
- **一份定义两处消费**：玩家读 `shu_zhi`，NPC 读 `npc_shu_zhi`；`npc_zhi()` 是唯一分叉点。
- **唯一主动槽 + 被动叠层**：`zhu_dong_neng_li` 是单个引用；`bei_dong_ceng` 是 `StringName -> int` 字典。
- **食谱计数**：只有消化完成才 `ji_chi_yu`；平局保留先到者；最常吃 id 驱动 50% 强制候选。
- **注入 RNG**：`NengLiChou` 只接受外部 `RandomNumberGenerator`，测试固定种子可复现。
- **Fisher-Yates**：从后往前交换，不用 `Array.shuffle()` 的全局随机。
- **暂停弹窗**：`process_mode = WHEN_PAUSED`（3）+ `layer = 100`；0 候选也必须解冻。
- **瞬时状态清理**：切换主动 → `_qu_xiao_shi_fang()`，清倍率/冲撞/潜伏，冷却归零。
- **潜伏感知**：`yin_shen` 只让 NPC 索敌跳过，不改变碰撞与咬击；咬中/受伤/到期破隐。
- **鸭子类型兼容**：`shou_dao_yao_ji` 的来源/部位参数有默认值，机器船单参调用不破。
- **运行时引用安全**：`is_instance_valid()` 先于 `is Yu` / 属性读取，防 freed instance。
- **旧卡五层退役**：脚本、场景、数据、账本、测试断言一起删。

## 检查点与证据

### orientation（未执行）

- 待用户开始学习时补：先复述旧卡系统链路（`QiangHuaKa` → `ka_yi_xuan` → `_on_ka_yi_xuan` match），再对比新能力链路。

### godot-inspection（未执行）

建议用户打开：

1. `data/nengli/fang_dian_ma_bi.tres`：确认 `shu_zhi=100`、`npc_shu_zhi=55`、`ban_jing=90`。
2. `data/yuzhong/lv_yu.tres`：确认 `neng_li` 指向放电。
3. `scenes/NengLiDanChuang.tscn`：确认 `layer=100`、`process_mode=3`、`neng_li_zu` 有 5 个。
4. `scenes/Main.tscn`：确认 `NengLiUI` 四个子节点与 `NengLiDanChuang` 实例。
5. `scripts/neng_li_chou.gd`：确认 `QIANG_ZHI_GAI_LV=0.5`。

### verification-handoff（未执行）

- 待用户跑 `tests\pao_pi.bat` 见七步全绿（382），并 F5 手测 5 个能力与 NPC 行为。
- 观察点：放电是否一次满条、毒棘是否两条入口都反毒、冲撞是否不整吞、潜伏是否让鱼不追、旧卡是否彻底消失。

## 待用户回答的验收问题

1. 为什么能力数值放在 `.tres`，而不是写死在 `yu.gd` 的 `match` 里？
2. 玩家放电 100、电鳐放电 55，这两个数分别从哪个字段读？为什么不能合并？
3. 主动能力和被动能力在 `ZhangBen` 里分别存在哪两个容器？再次选择时发生什么？
4. 为什么三选一测试要给 `RandomNumberGenerator` 固定种子？`Array.shuffle()` 为什么不适合？
5. 弹窗显示时游戏为什么暂停？如果候选为 0，代码如何避免永久暂停？
6. 切换主动时不清极速/冲撞/潜伏，会出现什么具体 bug？
7. 潜伏中的玩家为什么仍能被碰撞、被咬？破隐有哪三种时机？
8. Main 无头冒烟抓到的 `Left operand of 'is' is a previously freed instance` 是什么原因？为什么单测没抓到？
9. 旧卡退役删了哪五层？只删脚本会留下什么？

## 遗留

- 学生未参与本窗口，学习状态 `not_started`。
- F5 手测未执行；执行后把结果补进本文件与 `LEARNING_STATE.json`。
- 若用户只想验收功能、不做教学，可把本文件保留为「概念清单」，不必强行走复述。
