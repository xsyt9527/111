# TASK-031 实现报告

- 任务：pixelfx v2 特效全量落地（单档高清 + 体型缩放）+ 图鉴特效预览
- 源表：`C:\Users\苏\Downloads\GameDesign\bigfish-project\特效分配_2026-11-17_pixelfx.md`（v2，2026-11-17）
- 实现日期：2026-11-18
- 基线：`f27ae56893aed50db99ca6572659966bbca09b27`（工作区另含 TASK-026~030 未提交改动）
- 策划案基线：`01-游戏策划案.md` v0.27（mtime 2026-11-09 22:09:23，md5 `2db7aa25b6a1424eb9cb38d20255c8f7`，本轮复核未变）
- 结论：全量落地完成，八步门禁全绿（4032 断言）；F5 观感待用户实玩判定

## 一、拍板口径（用户 2026-11-18 AskUserQuestion + 追加硬口径）

| 项 | 决定 |
|---|---|
| 落地范围 | **全量**：通用战斗反馈 13 + 系统位 6 + 现存通用主动 5（文档）+ 补全 7 + 机械船 4 招 + 30 个专属技 + 状态光环 |
| 烘焙方式 | **单档高清**：每套 1 张 128~160px（全屏 192~256px），运行时缩放；不按文档 4 档（包体/内存优先） |
| 未分配技能 | **补全新分配**：参照 pixelfx 库给 7 个通用主动与有表现层的被动补 id/颜色/形状 |
| 技能特效尺寸 | **随体型增大**（用户追加硬口径）：范围型按判定直径、贴身/命中按 `ti_chang()`、光环按目标 `ti_kuan()`；全屏技固定 |
| 文档冲突项 | 跳过不重做：H10 桶眼鱼整组、淤泥弹、声呐脉冲、渔网/机械臂/船炮；`feng_kuang`（疯狂）无活来源仍烘资源备用 |

## 二、烘焙管线与资源

新增：

- `tools/texiao/manifest_v2.json`（1153 行）：84 条清单，每条 `key / pixelfx_id / palette / opts / fps / max_shi_chang / loop / blend / kuan_lei`。
- `tools/texiao/hong_bei_texiao_v2.py`（323 行）：调用 pixelfx `tools/render.mjs --sheet --no-actor` 出临时 sheet → Pillow 后处理（按 `max_shi_chang × fps` 截帧、NEAREST 规范画布、重排横向 sheet、alpha bbox 记可见内容宽高）→ 写 `assets/texiao_pixel/v2/<键>/texiao_<键>.png + .json` → 生成 `scripts/te_xiao_ku_zi_yuan.gd` 常量表。
- 资源：**84 套**，PNG 84 张 + JSON 84 份 + `.import`，合计 6.6MB。

JSON 在 v1 格式上扩展（加载器兼容旧文件）：

- `meta.pixelfx.fit = "native"`（不再做 274 对齐）、`visible = [w, h]`（alpha 并集宽高）、`anchorMode = "center"|"pivot"`；
- 顶层 `blend`（normal/add）、`zIndex`、`lifetime`。

## 三、运行时架构

### 加载器 `scripts/xiang_su_te_xiao.gd`

- 新增 `qu_lu(json_lu: String) -> Dictionary`：按精确路径加载，返回 `{kuang, yuan_dian, chi_cun, xun_huan, fps, ke_jian_x, ke_jian_gao, fit, blend, z_index, lifetime, anchor_mode}`。
- 缓存键改路径；**LRU 上限 24 套**（单套约 0.8MB，长会话不无限涨显存）。
- 旧 `qu(name)` 保留：先查 v2 名、再查 v1 正式、再查 `assets/待用/`。

### 注册表 `scripts/te_xiao_ku.gd`（`class_name TeXiaoKu`，418 行）

- `FAN_KUI`：19 条语义反馈（命中/致命区/受击/反伤/被吞/咬死/死亡/升级/消化/吃肉/连锁/边界等）。
- `ZHUANG_TAI_KU`：6 色状态光环（石化/疯狂/恐惧/魅惑/电麻/毒晕）。
- `JIE_MIAN_KU`：8 项界面特效（三选一/鲸鲨登场/章节转场/成就/选角/进化/血条/图鉴预览走通用入口）。
- `JI_NENG_KU`：42 个主动 id 全覆盖（12 通用 + 30 专属）。
- `CHUAN_KU`：机械船现存 4 招。
- 统一入口：
  - `bo_ming(key, gen, wei, kuan_px, can_shu) -> AnimatedSprite2D`：支持 `fan / chi_xu / bei / tint`；`gen` 无效或资源缺失返回 null，调用方回退旧 `TE_XIAO`。**不含 rotation 参数**（射线类取返回值后自设 `fx.rotation`）。
  - `gua_zhuang_tai(ming, mu, bei := 1.2, can_shu)`：挂目标局部坐标 `(0, -ti_gao(mu) * 0.75)`，同名先清；`xia_zhuang_tai` / `qing_zhuang_tai`。
  - `ji_neng_key(bian_hao)` / `zi_yuan(key)` / `you(key)` / `ti_kuan(node)` / `ti_gao(node)` / `ban_jing_kuan(...)`。
- 主开关 `SHI_YONG_V2 := true`；关闭后所有 `bo_*` 返回 null，全量回退旧 `te_xiao.gd` 4 帧特效。

### 生命周期

- 一次性：播完自毁。
- 循环 + `chi_xu > 0`：定时淡出后自毁。
- 循环 + `chi_xu = 0`：调用方负责释放（图鉴预览用重播定时器接管）。

## 四、接入点

### 4.1 通用战斗反馈（14 处）

| 语义 | 资源 | 位置 |
|---|---|---|
| 手动命中 | fb_ming_zhong | `yu.gd:_yao_ji_ming_zhong` |
| 致命区命中 + 跳字 | fb_zhi_ming / fb_zhi_ming_shu | `yu.gd` 命中结算 |
| 受击红闪 | fb_shou_ji | `yu.gd`、`yu_npc.gd:shou_dao_yao_ji` |
| 爆裂体质 | fb_bao_lie | `ye_deng_long_yu.gd` |
| 通用/凝胶反伤 | fb_fan_shang / fb_fan_shang_fen | `yu.gd` 反伤结算 |
| 被吞 | fb_tun_shui + fb_tun_yan | `yu_npc.gd:bei_chi`、`yu.gd:_chi_diao` |
| 咬死/败退 | fb_bei_yao_si | `yu_npc.gd` |
| 玩家死亡 | fb_si_wang | `yu.gd:_si_wang`；船固定 220px |
| 升级 | fb_sheng_ji | `yu.gd:_on_sheng_ji` |
| 消化 | fb_xiao_hua | `yu.gd:_zou_xiao_hua` |
| 吃肉 | fb_chi_rou | `yu.gd:_chi_rou`、`ke_chi_wu.gd`（sys_shi_rou） |
| 暴食连锁 | fb_lian_suo | `yu.gd` |
| 边界警告 | fb_bian_jie | `yu.gd:_xian_zhi_zai_di_tu_nei`（3 秒节流） |

### 4.2 系统位（7 处）

`fb_san_xuan`（三选一，红/蓝/绿 tint）`neng_li_dan_chuang.gd`；`fb_jing_sha`（鲸鲨登场全屏）`main.gd`；`sys_zhuan_chang`（章节转场）`di_tu_pin_jie_yan_chu.gd` + `yu.gd`；`sys_cheng_jiu` `cheng_jiu.gd`；`sys_xuan_jiao` `xing_tai_xuan_ze.gd`；`sys_jin_hua` `yu.gd`（进化演出）；`sys_xue_tiao` `tou_ding_xue_tiao.gd`。

### 4.3 通用主动 12（`JI_NENG_KU`）

放电麻痹、极速突进、鱼雷冲刺、长矛穿刺、弱点洞察、潜伏突袭、逆流闪避、漩涡、狂暴撕咬、硬壳护体、诱饵气泡、血腥狂热——全部在 `yu.gd` 各 `_shi_fang_*` 释放/落点段接入。

### 4.4 机械船 4 招（`CHUAN_KU`）

`ji_qi_chuan.gd`：深水炸弹 732（直径 480）、船锚横扫 779（960 宽）、探照灯扫描 813（光锥长）、鱼叉齐射 864。

### 4.5 进化专属 30（五个专属技模块迁移）

| 模块 | 迁移内容 |
|---|---|
| `zong_yu.gd` | 流星跃/神驹冲锋/千眼齐射/骨质重甲 → `liu_xing`×2、`shen_ju`×2、`qian_yan`、`fb_fan_shang` |
| `ye_deng_long_yu.gd` | 鬼火引路（图集首帧外观 + 抵达爆开）、星座余晖、磷光爆闪、爆裂体质；补齐 `_gui_huo_tu()` 辅助函数 |
| `lan_yu.gd` | 萤聚成龙、光点啃咬、诅咒孢子、星传播散（孢子云）、等离子齐射（带旋转）、极光轨迹（带旋转） |
| `ju_kou_yu.gd` | 饕餮巨窗（meta 存节点、每帧跟随玩家）、裂口陷阱、摄魂 |
| `fen_yu.gd` | 鲲吞天地（蓄力+吸水窗口两段）、深渊漩涡、吞星、深渊装甲弹开 |
| `yu.gd` 公共段 | 太岁割肉、强酸喷吐、超压水刀、雷暴召唤、落雷、九头电网、磁场护壁、螺旋钻突×2、剧毒突刺、空间裂缝、唤风、幽灵齐射、破空俯冲×2、孔雀幻影、石化之瞳×2、机关反甲×2、裂空步光环×2 |

所有迁移均保留旧特效回退：`if TeXiaoKu.bo_ming(...) == null: TE_XIAO.bo(旧) / _bo_te_xiao(...)`。

### 4.6 状态头顶光环（6 色）

- `yu_npc.gd`：`jia_zhuang_tai` 成功挂、状态结束/死亡卸（统一两处）。
- `ji_qi_chuan.gd`：`jia_zhuang_tai` 340 挂 / `_geng_xin_zhuang_tai` 430 过期卸；电麻 288、毒晕 299 满条挂 1 轮；`_chen_mo` 513 清场（船无 `ti_chang`/`ti_gao`，按默认 100/80 尺度挂）。

### 4.7 图鉴特效预览（`tu_jian.gd`）

- 五分类卡新增「预览特效 ＞」按钮：主动走 `TeXiaoKu.ji_neng_key`，被动走 `BEI_DONG_YU_LAN` 显式映射，船走 `CHUAN_YU_LAN`；只给有 v2 资源的卡挂按钮。
- 懒建全屏预览遮罩：中央舞台 + 椭圆参照环（宽 = 目标像素宽）+ 80~560px 滑杆（所见即所得演示体型缩放）+ 重播/关闭 + Esc 关闭。
- 自动循环：单次播完停 0.5 秒重播；循环播两轮重播；令牌（`_yu_lan_ci`）防叠播。
- 映射修正：`xing_chuan_bo_san → zu_zhou`、`shen_yuan_zhuang_jia → fb_fan_shang`。

## 五、文件清单

新增：

- `scripts/te_xiao_ku.gd`、`scripts/te_xiao_ku_zi_yuan.gd`（生成）
- `tools/texiao/hong_bei_texiao_v2.py`、`tools/texiao/manifest_v2.json`
- `assets/texiao_pixel/v2/**`（84 套 PNG+JSON）
- `docs/特效落地清单_PixelfxV2_2026-11-18.md`
- `docs/development_tasks/TASK-031_pixelfx_v2_te_xiao/`（本包三份报告）

修改：

- `scripts/xiang_su_te_xiao.gd`（`qu_lu` + LRU + fit/anchor 解析）
- `scripts/yu.gd`、`scripts/yu_npc.gd`、`scripts/ji_qi_chuan.gd`
- `scripts/zhuan_shu_ku/{zong_yu,ye_deng_long_yu,lan_yu,ju_kou_yu,fen_yu}.gd`
- `scripts/{neng_li_dan_chuang,jin_hua_yan_chu,cheng_jiu,xing_tai_xuan_ze,tou_ding_xue_tiao,ke_chi_wu,di_tu_pin_jie_yan_chu,main,tu_jian,you_er_qi_pao}.gd`
- `tests/ce_shu_ju.gd`（用例 11：资源完整性 + 注册表引用 + 42 主动覆盖）

不动：`project.godot` Web renderer、`data/nengli/*.tres` 数值、`data/donghua/*` 旧 4 帧、`assets/待用/**`（保留备查）。

## 六、未提交说明

本轮全部改动未 commit、未 push（未获授权）；工作区另含 TASK-026~030 未提交改动，保持不动。
