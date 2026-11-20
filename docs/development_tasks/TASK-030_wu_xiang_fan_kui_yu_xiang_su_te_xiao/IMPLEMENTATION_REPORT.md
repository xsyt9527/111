# TASK-030 实现报告

- 任务：五项实机反馈修复（删鱼删技 / 体型=等级 / 地图上下边界 / 攻击键与手动攻击）+ pixelfx 像素特效试用 + 美术文档同步
- 实现日期：2026-11-17
- 基线：`f27ae56893aed50db99ca6572659966bbca09b27`（工作区另含 TASK-026~029 未提交改动）
- 策划案基线：`01-游戏策划案.md` v0.27（mtime 2026-11-09 22:09:23，md5 `2db7aa25b6a1424eb9cb38d20255c8f7`，本轮复核未变）
- 结论：五项全部实现，八步门禁全绿；像素特效采用与否待用户实玩判定

## 一、拍板口径（用户 2026-11-17 AskUserQuestion）

| 项 | 决定 |
|---|---|
| 鱼种 | 真删铜眼鱼 `hong_yu`、暗影剑鱼 `an_ying_jian_yu`（含铜眼 3 条进化分支、6 个专属技能） |
| 基础主动 | 删 `man_li_chong_zhuang`、`dian_mai_chong`、`sheng_na_mai_chong`、`yu_ni_dan` |
| 手动攻击 | 独立 2 秒 CD；自动仍 0.5 秒；命中伤害 ×1.5；空挥不进 CD |
| 像素特效 | 选项 1（手动命中火花）永久接入；选项 2（12 套旧特效像素版）放 `assets/待用/`，临时开关试玩后判定 |
| 体型 | 视觉内容宽 = `152 × ZhangBen.ti_xing_dao_chi_du(tixing)`，同体型所有形态等宽；不改数值账本 |

## 二、A. 删除鱼种与主动技能

真删资源：

- `data/yuzhong/{hong_yu,an_ying_jian_yu}.tres`、`data/xingtai/{hong_yu,an_ying_jian_yu}.tres`
- 铜眼进化 `data/jinhua/{bi_yan_guan_xing_shou,shen_yuan_quan_shi_zhi_yan,ji_guang_ju_zhen_yu}.tres` 及对应 6 帧动画 `.tres`
- 能力 `data/nengli/{man_li_chong_zhuang,dian_mai_chong,sheng_na_mai_chong,yu_ni_dan,guan_xing,feng_kuang_guang_xian,ji_guang_ju_zhen,xian_jian_zhi_ming,xie_shen_zhu_shi,chong_neng_yan}.tres`
- `data/donghua/{yu_ni_dan_4zhen,sheng_na_mai_chong_4zhen}.tres`、`scripts/zhuan_shu_ku/hong_yu.gd(+.uid)`、`tests/ce_zhuanshu_hong_yu*`

连带改动：

- `scenes/Main.tscn` 删 2 个 `ext_resource` 与 `yu_zhong_zu` 2 项；`scenes/NengLiDanChuang.tscn` 删 4 个主动卡。
- `scripts/yu_qun.gd` 删退池常量与跳过分支；`scripts/cun_dang.gd` 形态表 14→12；`scripts/tu_jian.gd` 鱼卡 11→9；`scripts/jin_hua_ku.gd` 33→30；`scripts/neng_li_ku.gd` 主动 49→42 / 被动 52→49；`scripts/neng_li_chou.gd`、`scripts/ji_neng_fan_wei.gd`、`scripts/zhuan_shu_ku.gd` 同步。
- `scripts/yu.gd` 删 4 个主动 `match` 分支与 `_shi_fang_dian_mai`；保留 `_shi_fang_chong_zhuang` 共享 handler（`yu_lei_chong_ci` 仍用）。
- `scripts/yu_npc.gd` 删 `man_li_chong_zhuang` AI 分支。
- `scripts/shou_ju_jiao_ben.gd` 追猎鱼改 `lan_yu`，并显式 `xin_yu.gong_ji_yu_wang = not wu_shi`（避免 1:00 追猎鱼变木桩）。
- `scripts/te_xiao.gd` 删 `yu_ni` / `sheng_na` 包装；`dian_mai_chong` 包装保留（九头电网仍调用）。

旧存档兼容：未知形态回退默认、未知鱼种 id 保留但不生成、未知永久技能忽略；成就点不返还（沿用既有忽略逻辑）。

## 三、B. 体型 = 等级（视觉归一化）

- 新增 `scripts/ti_xing_gui_yi.gd`（`class_name TiXingGuiYi`，RefCounted）：
  - `nei_rong_kuan_gao()` 取图片 `get_used_rect()`（含 `AtlasTexture` 裁 region），读不到回退原图尺寸。
  - `xing_xiang_bi(frames, "you", 152.0)` = `152 / 内容宽`；`zui_da_nei_rong(frames)` 取全部帧最大内容宽/高。
  - 按 texture 实例缓存，出生时只算一次。
- `scripts/yu.gd`：`xing_xiang_bi`、`_ti_xing_nei_rong` 字段；`_chong_suan_ti_xing_ji_zhun()`；`_ti_xing_vector()` = `curve(tixing) * xing_xiang_bi`；`ti_chang()`/新增 `ti_gao()` 改为内容尺寸 × `scale.x`。
- `scripts/yu_npc.gd`：先设 `sprite_frames` 再算基准（原顺序反了会读旧帧）；`_ying_she_ti_xing()` 同步乘因子；`_yao_ji_ju_li()` 改用 `55 × scale.x`；攻击动画换帧时重算。
- 不改数值账本：`tixing`、吞噬门槛、咬伤公式、等级牌全部不动。基准 K=152 取默认玩家形态 `ao_tu_wo_niu_yu` 内容宽，因子=1，保住既有精确断言。

## 四、C. 地图上下边界卡死

根因：`_xian_zhi_zai_di_tu_nei()` 用「贴图宽一半」同时限制 X/Y；上排房半高 384px，大体型时 Y 边距被顶到 300px 以上，于是停在中间。

修复：

```gdscript
var ban_kuan := maxf(30.0, ti_chang() * 0.5)
var ban_gao  := maxf(30.0, ti_gao() * 0.5)
# 植物株位距房间四边至少 120px，碰撞半径最大约 40px，RouQu=55×scale
var shi_wu_shang_xian := 120.0 + maxf(0.0,
        (55.0 * maxf(scale.x, 0.01) + 40.0 - 6.0) / sqrt(2.0))
ban_kuan = minf(ban_kuan, minf(shi_wu_shang_xian, DI_TU_DA_XIAO.x * 0.5 - 1.0))
ban_gao  = minf(ban_gao,  minf(shi_wu_shang_xian, DI_TU_DA_XIAO.y * 0.5 - 1.0))
```

- Y 用 `ti_gao()`（视觉高）不再用体长；新增常量 `SHI_WU_ZUI_DA_BIAN_JU=120`、`SHI_WU_ZUI_DA_BAN_JING=40`、`SHI_WU_AN_QUAN=6`。
- 上限保证四角食物可达；极大体型时边距被食物上限压住，鱼身可能在地图最外缘被相机裁一部分（优先「吃得到」，已记录为已知取舍）。
- 不夹当前房间 Rect2（否则 `_process` 的 `qu_yu_pian` 永不变化、换房失效）；机器船相机 limit、换房 6px、NPC 边界均未动。

## 五、D. 攻击键与手动攻击

`scripts/yu.gd`：

```gdscript
const SHOU_DONG_YAO_JI_JIAN_GE := 2.0   # 手动键独立冷却（秒）
const SHOU_DONG_YAO_SHANG_BEI := 1.5    # 手动命中伤害倍率
var _shou_dong_leng_que := 0.0
```

- `yao_ji_shou_dong()` 只查 `_shou_dong_leng_que` / 冲撞 / 失控 / 演出锁；`_chang_shi_yao_ji(true)` 命中后设独立 2 秒；自动咬仍走 `jia_n` 间隔（0.5 秒、狂暴/消化修正）。
- 普通命中在全部倍率之后乘 `SHOU_DONG_YAO_SHANG_BEI`；整吞在吞下前也播一次命中特效；致命区判定/吞噬门槛不乘 1.5。
- 空挥不进任何 CD。

`scripts/neng_li_ui.gd`：

- `_chuan_zhan_zhong()`：查组 `ji_qi_chuan` 且 `not si_le`；无船 `visible=false` 且 `disabled=true`，船被击沉当帧隐藏。
- 按钮读 `wan._shou_dong_leng_que`；tooltip「手动咬击：独立 2 秒冷却，伤害 ×1.5」。

`scripts/te_xiao.gd` + `assets/texiao_pixel/shou_dong_ming_zhong/`（选项 1，永久）：

- `shou_dong_yao_zhong(gen, wei, bi)`：pixelfx `impacts/hit-spark` 金白 16 帧；`bi = clampf(0.9 + 目标tixing * 0.06, 0.9, 2.2)`；`wei` 优先 `qu_dian(bu)`；nearest、ADD、z_index 5、WeakRef 淡出。
- 仅手动命中触发（含整吞），自动咬/空挥/失败不播。

## 六、E. pixelfx 像素特效试用包

- 选项 1：`assets/texiao_pixel/shou_dong_ming_zhong/`（16 帧，136×80，pivot (44,64)，截断 0.55s）。
- 选项 2：`assets/待用/` 放 12 套旧特效像素版（每套 `<名>.png` + `.json`，动画名 `bao`，30 fps）：
  `dian_texiao`、`du_texiao`、`xuan_wo`、`yu_lei`、`kuang_bao`、`ni_liu`、`ying_lin`、`dian_gan`、`ying_ke`、`dian_mai`、`you_er`、`xue_xing`。`dian_mai` 因九头电网仍用必须保留；`yu_ni`/`sheng_na` 随技能删除不生成。
- 加载器 `scripts/xiang_su_te_xiao.gd`（`XiangSuTeXiao`）：先 `assets/texiao_pixel/<名>/<名>.json`，再 `assets/待用/<名>.json`；横向 sheet 切 `AtlasTexture`，fps/loop/pivot 读 JSON，`JIU_ZHEN_KUAN=274` 与旧帧宽对齐，按套 `shi_chang` 截断。
- 开关 `scripts/te_xiao.gd` 的 `SHI_YONG_DAI_YONG_XIANG_SU := true`（试玩期默认开）；`false` 即回旧 4 帧。12 个语义函数先像素后旧，旧资源全部保留可回滚。
- `assets/待用/README.md`：映射表（pixelfx id、调色板、帧数/尺寸/pivot、截断、混合）、接入位置、试玩判定与回退流程。

## 七、F. 美术文档与 CSV 同步

- `docs/美术全量替换需求_Gemini_Rig版_2026-11-16.md` 升 v2.2（2026-11-17）：
  - 基础鱼 11→10、进化 33→30、图标 101→91（删铜眼 6 + 4 个基础主动）、专属特效 14→12（删 `yu_ni`/`sheng_na`，保留 `dian_mai`）、总数 170→154（选项 2 采用后 142）。
  - 删除铜眼鱼章节与 6 个专属技能、暗影剑鱼说明；剑鱼章节去掉「兼暗影剑鱼」；§9.6 重编号并删 3 个铜眼被动；§9.7 分批 15/32/32→11/29/29；§11 目录与交付数、§14.7 接入顺序、§15「不为暗影剑鱼出图」、§16 版本表、结尾一句话全部同步。
- `docs/美术全量替换清单_Rig版_2026-11-16.csv`：删 16 行（铜眼基础鱼 1 + 铜眼进化 3 + 铜眼技能 6 + 4 个基础主动图标 + `yu_ni`/`sheng_na` 特效 2），数据行 170→154；保持 UTF-8 BOM + CRLF。
- 一致性校验（`python -I`）：CSV 154 行；基础鱼 10 / 进化 30 / 图标 91 / 特效 12 / 场景装饰 2 / 船 6 / 气泡 1 / 肉块 1 / 背景 1；MD 与 CSV 四个 id 集合完全一致、无已删 id 残留（`dian_mai_chong` 仅在「技能特效」保留）。临时校验脚本已删除。

## 八、改动/新增文件

- 新增：`scripts/ti_xing_gui_yi.gd`、`scripts/xiang_su_te_xiao.gd`、`assets/texiao_pixel/shou_dong_ming_zhong/`、`assets/待用/`（12 套 + README）、本任务的三份报告。
- 改动：`scripts/{yu,yu_npc,yu_qun,cun_dang,tu_jian,jin_hua_ku,neng_li_ku,neng_li_chou,ji_neng_fan_wei,zhuan_shu_ku,shou_ju_jiao_ben,te_xiao,neng_li_ui,xiao_di_tu,main,di_tu_pin_jie_yan_chu,zhang_ben,yin_xiang}.gd`、`scripts/zhuan_shu_ku/fen_yu.gd`、`tests/{ce_shu_ju,ce_jie_suo,ce_panding,ce_zhang_ben}.gd`、`scenes/{Main,NengLiDanChuang}.tscn`、两份美术文档。
- 删除：见第二节资源清单与 `tests/ce_zhuanshu_hong_yu*`。
- 未动：`project.godot` 的 `renderer/rendering_method.web="gl_compatibility"`；机器船相机 limit/换房 6px；NPC 地图边界；鲸鲨 `bei_ji_bai` 流程。

## 九、状态

- 除「像素特效好用与否」外全部完成；F5 实机项（六图上下边缘、船战按钮显隐、手动 1.5× 手感、像素特效观感）待用户试玩。
- **本轮未 commit、未 push**，等用户授权收尾。
