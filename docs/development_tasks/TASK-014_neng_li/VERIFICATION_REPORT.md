# TASK-014 验证报告（VERIFICATION_REPORT）

## 自动化验证

| 检查 | 结果 |
|---|---|
| 引擎 | Godot 4.7.2.stable（`D:\001\Godot_v4.7.2-stable_win64.exe`） |
| headless `--import` | 退出码 0，无 ERROR |
| 账本纯逻辑 `ce_zhang_ben` | `Results: 102 passed, 0 failed` |
| 边界 `ce_bian_jie` | `Results: 21 passed, 0 failed` |
| 数据校验 `ce_shu_ju` | `Results: 47 passed, 0 failed` |
| 摇杆纯逻辑 `ce_yao_gan` | `Results: 8 passed, 0 failed` |
| 咬击纯逻辑 `ce_zhan_dou` | `Results: 11 passed, 0 failed` |
| 判定集成 `ce_panding`（场景模式） | `Results: 193 passed, 0 failed` |
| `tests/pao_pi.bat` | 七步全绿，退出码 0，总计 **382** 条断言 |
| Main 无头 | 900 帧，无 `ERROR` / `SCRIPT ERROR` |
| 旧卡残留扫描 | `scripts/ scenes/ data/ tests/` 无 `QiangHuaKa` / `qiang_hua` / `ka_yi_xuan` / `yi_xuan_ka` / `jing_yan_jia_cheng` 引用；最终扫描发现 `scenes/QiangHuaDanChuang.tscn` 被编辑器重存后残留，已删除并复扫通过 |

断言分布：**102 / 21 / 47 / 8 / 11 / 193 = 382**，0 失败。

## 覆盖到的能力行为

### 玩家侧（ce_panding 6p~6t）

| 用例 | 覆盖 |
|---|---|
| 6p 放电 | 资源加载、装入主动槽、释放成功、半径 90 内满条失控 2 秒、半径 90 外无影响、冷却 6 秒、冷却中再按无效、冷却走完归零 |
| 6q 毒棘 | 1 层 45、2 层 60；`YaNpc._yao(yu)` 咬击入口；`_on_shang_qu_entered(PandingQu)` 接触入口 |
| 6r 极速 | 倍率 2.0、持续 0.8、冷却 8、施放中再按无效、到期回 1.0 |
| 6s 冲撞 | 持续 0.45、冷却 9、伤害 ×2、不整吞、同一目标只结算一次、施放中嘴圈吞被屏蔽、到期结束 |
| 6t 潜伏 | `yin_shen=true`、持续 2.0、下一口 ×2、`kan_yu._si_kao()` 不选玩家、已追目标放弃、咬中破隐、到期破隐、受伤破隐、alpha 0.45 |

### NPC 侧（ce_panding 6u）

| 鱼 | 覆盖 |
|---|---|
| 旗鱼 | 200px 启动突进、`_tu_jin_sheng_yu=0.8`、冷却 6、向左位移 |
| 大眼金枪鱼 | 150px 启动冲撞、`_chong_zhuang_sheng_yu=0.45`、冷却 7、玩家 5.0→4.0、同一目标只一次 |
| 巨口鱼 | 200px 潜伏 2 秒、冷却 8、下一口动态伤害 ×2、alpha 0.45 |
| 首领 | 玩家潜伏时清追击计时，不再追 |

### 数据与账本

- `ce_shu_ju`：5 个能力资源合法且 id 唯一；5 个鱼种映射正确、4 个 null；坏能力「负 shu_zhi」与「空 bian_hao」双红测；200 轮三选一每轮恰好 3 张且不重复；强制项必在；50% 命中率 1000 轮落在 40%~60%；空池/不足 3 个边界。
- `ce_zhang_ben`：主动替换、被动叠层、广播次数与层数、吃鱼计数、平局保留先到者、复位清空。
- `ce_bian_jie`：复位后主动/被动层数/获得历史/食谱/最常吃 id 全部清空。

## 红绿过程（由门禁抓住的真实问题）

| # | 现场 | 根因 | 修复 |
|---|---|---|---|
| 1 | 放电用例靶鱼 `si_le=true` | 靶鱼放在玩家右侧 70px，落入嘴圈（ZuiQu 55×玩家缩放 + NPC PandingQu），物理帧触发整吞 | 改 1 级靶鱼、放 80px（嘴圈外、放电 90 内），等待两个物理帧 |
| 2 | 冲撞伤害为 0 | `_chong_zhuang` 手动瞬移后同帧读 `get_overlapping_areas()`，物理服务器尚未刷新重叠列表 | 测试分两段：先位移、`await physics_frame`、再 `_chong_zhuang(0.001)` 结算 |
| 3 | 巨口鱼下一口期望 4.0 实际 3.5 | 巨口鱼 `zui_ba=1.5`，3 级伤害 `(0.15×3+0.05)×1.5=0.75`，×2=1.5 | 期望值改为 `ZhanDou.yao_ji_shang_hai(3.0, ju_kou.zui_ba)*2` |
| 4 | `pao_pi.bat` 第 7 步无 `Results:` | 新增用例等待物理帧变多，`--quit-after 360` 在收卷前退出 | 改为 `--quit-after 720` |
| 5 | Main 无头高频 `SCRIPT ERROR: Left operand of 'is' is a previously freed instance`（`yu_npc.gd:210`） | `_mu_biao` 已释放时直接 `_mu_biao is Yu` | 所有 `_mu_biao is Yu` / `wan.yin_shen` 前补 `is_instance_valid()`，共 6 处 |
| 6 | 旧卡场景 `scenes/QiangHuaDanChuang.tscn` 仍在盘上 | 删除旧卡后 Godot 编辑器重新保存场景（补 `uid` / `unique_id`），文件仍在且引用已删脚本/数据 | 交付前最终扫描发现并 `rm`；重新 `--import`、七步门禁 382 与 Main 900 帧复跑均无坏引用 |

第 5 条说明：**单测绿不等于运行时干净**。能力感知代码加入后，`ce_panding` 仍全绿，只有 Main 无头冒烟把 stale 引用错误暴露出来；因此本任务保留「主场景 900 帧 ERROR 扫描」作为第二道门禁。

## 未执行 / 未覆盖

| 项 | 说明 |
|---|---|
| F5 人工手测 | 本次会话未执行交互式 F5；下方清单交给用户验收 |
| 触屏真机 | 本轮只验证桌面无头与逻辑；Android 触控仍归 TASK-010 |
| 视觉手感 | 放电闪蓝、潜伏半透明、冲撞摆动、按钮位置只做代码/场景核对，未做像素级人工确认 |
| Tween 叠加 | 玩家受伤/升级/吞吃/冲撞同时发生时的视觉冲突无自动断言 |
| 极端帧率 | 冲撞靠 Area2D 重叠查询，掉帧时可能穿透小鱼；见 CODE_REVIEW P3 |

## F5 手测清单（待用户执行）

1. 升级弹窗出现 3 个能力；连续升级能继续弹；弹窗期间游戏暂停，选完恢复。
2. 吃过蓑鲉后多次升级，毒棘约 50% 概率出现；卡面显示「被动 · 当前 ×N → ×N+1」。
3. 选主动后右下按钮出现；施放后进入冷却；冷却条走完按钮恢复；冷却中按无效。
4. 放电：周围鱼抽蓝、失控约 2 秒；半径外无影响。
5. 毒棘：咬你的鱼毒晕条上涨；接触撞你的鱼也中毒。
6. 极速：0.8 秒明显加速；冲撞：直线冲出、撞到的鱼掉体型但没被吞；潜伏：鱼身半透明、普通鱼不追、下一口伤害翻倍。
7. NPC：电鳐放电、蓑鲉反毒、旗鱼突进、金枪鱼冲撞、巨口鱼半透明偷袭都能看到。
8. 旧卡弹窗/卡池不再出现；结算页显示主动与被动层数。
9. 用三个不同主动各开一局，确认切换主动后旧效果不残留、冷却归零。

## 结论

实现与自动化验证完成：**382 / 382 全绿，Main 900 帧无 ERROR**。人工 F5 与手感确认待用户执行；未发现 P1 / P2 阻塞问题，P3 备忘见 `CODE_REVIEW.md`。
