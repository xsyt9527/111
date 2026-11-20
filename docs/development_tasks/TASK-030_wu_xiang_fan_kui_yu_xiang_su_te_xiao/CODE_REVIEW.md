# TASK-030 代码审查

- 审查日期：2026-11-17
- 范围：本轮五项修复的全部改动（A~F）
- 结论：无阻塞问题；4 项取舍已记录，1 项待用户实玩判定

## 一、删除完整性

| 检查 | 结果 |
|---|---|
| 已删鱼种/进化/技能是否还有引用 | `rg hong_yu\|an_ying_jian_yu\|bi_yan_guan_xing\|guan_xing\|feng_kuang_guang_xian\|ji_guang_ju_zhen` 在 `scripts/`、`data/`、`scenes/` 无残留（文档中仅保留「已删除」说明） |
| 9 头电网仍需要的电特效 | `te_xiao.gd` 的 `dian_mai_chong` 包装与 `data/donghua/dian_mai_chong_4zhen.tres` 保留；`ce_shu_ju` 特效契约 12 含它 |
| 旧存档读档 | 未知形态回退默认；未知鱼种 id 保留但不生成；未知技能忽略；不抛错（既有忽略路径） |
| 教程追猎鱼 | `shou_ju_jiao_ben.gd` 显式设 `gong_ji_yu_wang`，避免换 `lan_yu` 后默认 false 导致 1:00 追猎鱼不动 |

**遗留（低）**：`docs/引擎词总表.md` 与 `Godot引擎词总表.docx` 仍含已删鱼/技能词条（学习文档，不影响运行），未在本轮改动。

## 二、体型归一化

- **取舍 1（已知）**：K=152 让个别原本「看起来大」的形态视觉略缩，这是「同体型等宽」的必然代价；若手机端看不清，可整体调大 K 并同步 `ce_panding:2657` 附近断言。
- **顺序正确**：`yu_npc._ready()` 先设 `sprite_frames` 再算基准，避免读到默认帧宽；进化/攻击换 frames 后重算，`_ying_yong_jin_hua` 先 kill 旧 `_ti_xing_tui` 再应用新 scale，防止 Tween 把鱼拉回错误大小。
- **判定圈同步**：`ti_chang`/`ti_gao`/`_yao_ji_ju_li` 都改为读 `scale.x`，`RouQu`/`YaoQu`/`ShangQu` 由 `Yu` 现有节点缩放跟随根 scale，视觉与判定不脱节。
- **缓存**：`TiXingGuiYi` 按 texture 实例缓存 `get_used_rect()`，NPC 批量出生不会反复解码。

## 三、地图边界

- **取舍 2（已知）**：`shi_wu_shang_xian` 上限保证四角植物可达；极端大体型时鱼身可能被相机裁掉最外缘一部分。计划阶段已把「食物吃得到」定为优先，回滚方案（只用 `ti_gao`、不加食物上限）在计划文件中有记录。
- 极端 scale（如 50）先夹到 `DI_TU_DA_XIAO/2 - 1`，clamp 上下界不会反序；`ce_panding` 6v2 有对应用例。
- 未夹当前房间 Rect2，`main.gd:_process` 的 `qu_yu_pian` 仍能随位置变化，换房逻辑不受影响。

## 四、手动攻击

- **CD 分离**：手动只写 `_shou_dong_leng_que`，自动只写 `_yao_ji_leng_que`；`_process` 各自递减。按钮只读手动值。
- **伤害倍率位置**：1.5× 在所有特殊倍率之后、`shou_dao_yao_ji` 之前乘，不会重复乘到整吞/致命区分支；机械船走同一出口也吃 1.5×（与计划一致）。
- **空挥不进 CD**：`yao_ji_shou_dong()` 的冷却只在命中分支设置；`ce_panding` 6zh 有断言。
- **测试基线**：6zh 开头重置 `zui_ba=1.0`、`jing_yan=0`、等级/当前体型，避免前序用例的「每次进化 ×1.5 累乘嘴巴」与咬伤经验临界升级污染伤害对照；靶鱼统一 8.0 体型防自动整吞。属于测试隔离，不改变产品逻辑。
- **按钮显隐**：每帧查组，船 `si_le` 当帧隐藏；船 `queue_free` 后 `is_instance_valid` 保护，无报错。

## 五、像素特效

- 选项 1 与选项 2 物理分离：正式目录 `assets/texiao_pixel/` 不依赖开关；`assets/待用/` 由 `SHI_YONG_DAI_YONG_XIANG_SU` 控制，关掉即回旧 4 帧。
- 加载失败返回空帧时 `te_xiao.gd` 回退旧版，缺资源不会让特效消失。
- 中文 `res://` 路径已通过 headless `--import` 与场景集成验证，Godot 未报路径错误。
- **取舍 3（待判定）**：循环类像素特效（漩涡/气泡/毒雾/血雾）与旧 4 帧观感差异最大，需用户实玩拍板；截断时长集中在 0.55~1.0 秒，README 写明可调。
- 像素资源全部 `load()`/`preload()` 引用，未写死进 `.tres` 的 `path` 之外。

## 六、文档与计数

- MD/CSV 已用 `python -I` 双向比对，四类 id 集合完全一致；计数与代码侧 `ce_shu_ju` 断言互相印证（鱼 9/形态 12/注册 10/进化 30/总能力 91/图标 91/特效 12）。
- 版本头、分批数、目录注释、§14.7 接入顺序、§16 版本表与结尾总数全部同步，无 170/101/33/14 旧数残留（历史对照行除外）。

## 七、结论

无阻塞问题。建议按 `VERIFICATION_REPORT.md` 第四节做 F5 实机确认；像素特效采用/回退只需改一个常量。
