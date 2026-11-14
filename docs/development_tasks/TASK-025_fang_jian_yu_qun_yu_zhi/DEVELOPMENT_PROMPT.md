# DEVELOPMENT_PROMPT · TASK-025

## 目标

把换房时的「清空旧房 + 补满新房」改成「九宫格每房预置鱼群记录，进房按记录加载」。未加载房只保留 Dictionary 记录，雷达可读，后台轻量模拟游动与互吃。

## 当前代码事实（实现前必读）

### scripts/yu_qun.gd

- 常量在 9–29 行；`fang_jian_qu := Rect2(0, 0, 4128, 2304)` 在 31–40 行附近。
- `_ready()` 连接 `Dingshi.timeout`、`_chong_tian_yu_qun.call_deferred()`、`_kai_xia_yi_lun()`。
- `qie_huan_fang_jian(qu)` 在 160–173 行：遍历子节点，把所有非 Boss `YuNpc` 摘除并 `queue_free`，清零 `_da_yu_ji_shi`、`_hu_chi_ji_shi`，再 `_chong_tian_an_quan` + `_kai_xia_yi_lun()`。
- `_chong_tian_an_quan`、`_fang_huan_ying_xiao_yu`、`ru_chang_xiao_yu_deng_ji`、`_chou_xiao_yu_zhong`、`an_quan_fang_nei_dian`、`an_quan_chu_kou`、`huan_chong_hui_shou_xian`、`_zhao_wan_jia_wei`、`_wan_jia_ti_xing` 全部删除。
- `_sheng_yu` 在 371–403 行：注入 `yu_zhong/sudu`，`an_quan` 大鱼走对侧入口，否则从房外左右边缘 ±160px 进入，最后 `add_child` 触发 `_ready`。
- `_hu_chi_ju_ding` 在 430–459 行：每 20 秒全局节拍，同房 140px 内、体型 ≥ 对方 ×1.1、35% 概率，猎物按最近选择。

### scripts/yu_npc.gd

- `_process` 在 164–241 行；出屏回收在 237–239 行，相机可视矩形 ±240px 外 `queue_free()`，Boss 例外。
- `_ready` 在 115–152 行用 `yu_zhong.dengji` 覆盖 `tixing` / `tixing_chu_shi` / `deng_ji_nei`，并设置 `gan_zhi`、`scale`、`shi_boss`、`_neng_li`；不覆盖 `sudu` / `fangxiang`。
- `jia_jing_yan_nei` 在 794–806 行；`_sheng_ji_yu_zhi` 在 809–812 行。

### scripts/xiao_di_tu.gd

- `_hu_npc()` 在 184–203 行：只扫 `yu_npc` 组，普通鱼红点 2.0px，Boss 金点第二遍画。
- 图例文本固定 `"金 首领 · 蓝 玩家 · 红 鱼 · 绿 植物"`，测试精确匹配。
- `_dao_di_tu` 在 144–148 行：世界 4128×2304 → 地图 240×134。

### scripts/main.gd

- `_ready` 101 行附近调 `yu_qun.qie_huan_fang_jian(fang_jian_qu(dang_qian_fang_jian))`。
- `_qie_huan_fang_jian` 502 行附近调 `yu_qun.qie_huan_fang_jian(qu)`。
- `fang_jian_qu(pian)` 367–372 行：行优先 `ge_y*3+ge_x`，单格 1376×768。

## 实现顺序

### step-01 九房记录数据层

1. 新增 `const FANG_JIAN_CHI_CUN := Vector2(1376.0, 768.0)`、`const JIU_FANG_SHU := 9`。
2. 新增 `var _fang_jian_yu_qun: Array = []`（9 项，每项 `Array[Dictionary]`）、`var _dang_qian_fang_jian := -1`。
3. 记录字段：`{"zhong": YuZhong, "wei": Vector2, "fang": float, "su": float, "ti": float, "nei_deng": int, "nei_jing_yan": int, "node": YuNpc 或 null}`。
4. `qu_pian(qu: Rect2) -> int`：按 `FANG_JIAN_CHI_CUN` 与 3×3 推算，clamp 0..8。
5. `_chu_shi_hua_jiu_fang()`：若已初始化直接返回；否则 9 个房间各用 `_chou_yu_zhong()` 生成 `dang_qian_shang_xian()` 条记录，位置夹在对应房间 40px 边距内。
6. `qie_huan_fang_jian(qu: Rect2, pian: int = -1)`：`pian < 0` 时用 `qu_pian(qu)`；首次调用先 `_chu_shi_hua_jiu_fang()`。
7. `fang_jian_ji_lu(pian: int) -> Array`：返回对应房记录数组（只读约定，不复制）。
8. `_ready()` 删除 deferred 铺屏，只启动 `Dingshi` 与首轮排程。

### step-02 保存 / 加载与实体管理

1. `_bao_cun_dang_qian_fang_jian()`：
   - 遍历当前房记录，`record.node` 有效且未 `si_le` 时回写 `wei/ti/nei_deng/nei_jing_yan/su/fang`；
   - `si_le` 或节点失效则从记录数组删除；
   - 只遍历 YuQun 直接子节点释放；没有记录引用的普通 `YuNpc` 一并释放；
   - 保存位置夹回房间 40px 边距；`node = null`。
2. `_jia_zai_fang_jian(pian: int, wan_jia_wei: Vector2)`：
   - 逐条 instantiate `YuNpc`，`add_child` 前写 `yu_zhong/sudu/fangxiang/position` 并调 `zai_ru_ti_xing(ti, nei_deng, nei_jing_yan)`；
   - 离玩家 <240px 时沿远离方向推到 240px，再夹回房内 40px；
   - 写回 `record.node`。
3. 当前房每帧同步：`_process` 第一件事把实体状态回写记录，`si_le` 删除；`shua_xin_ting_zhi` 也要先同步再冻结。
4. `YuNpc`：新增 `var you_yu_qun_guan_li := false`、恢复载荷字段与 `zai_ru_ti_xing()`；`_ready` 末尾应用载荷并重算 `gan_zhi` / `scale` / `_ying_she_ti_xing()`；出屏回收条件加 `not you_yu_qun_guan_li`。
5. `_sheng_yu` 生成后登记到当前房记录；出生点夹在房边 ±60px 带内；所有生成路径必须经 `_sheng_yu`。
6. 当前房实体每帧夹在 `fang_jian_qu.grow(60)` 内，越界夹回并翻转 `fangxiang`。
7. 换房不重置 `_hu_chi_ji_shi`；`_da_yu_ji_shi` 与 `Dingshi` 照旧在本房重新起算；停刷时保存释放但不加载目标房。

### step-03 未加载房模拟

1. `_xu_ni_you_dong(delta)`：0.25 秒一拍；未加载房逐条记录找感知范围内更小的鱼靠近，否则直线游，碰房边反弹。
2. 每 20 秒 `_hu_chi_ji_shi` 节拍：当前房 `_hu_chi_ju_ding()`，同一拍调 `_xu_ni_hu_chi(35%)` 处理 8 个未加载房。
3. 虚拟互吃：同房、140px、体型 ≥ 对方 ×1.1、35% 概率；优先选最小猎物；吃方按 `fenzhi` 加隐藏经验并按阈值升级；被吃记录删除。
4. 当前房 `_hu_chi_ju_ding` 猎物选择改为「体型最小优先、距离次之」。
5. `_dang` 上升时未加载房淘汰最小约 20%，补同数量当前档新鱼；数量低于 `maxi(8, int(dang_qian_shang_xian() * 0.6))` 补到保底。
6. 停刷时虚拟游动/互吃/档位刷新全部冻结。

### step-04 雷达与测试

1. `XiaoDiTu._hu_npc()` 优先读 `Main.yu_qun.fang_jian_ji_lu(pian)`：
   - 当前房半径 1.8~2.6，正常红；
   - 其他房半径 1.3~1.9，alpha 更低；
   - 记录画完补扫 `yu_npc` 组，只画 `you_yu_qun_guan_li != true` 的普通鱼；
   - 找不到 YuQun 时回退旧全组扫描。
2. `tests/ce_panding.gd` 303–402 行旧换房段逐条删除/改写：
   - 删除欢迎鱼等级、`huan_chong_hui_shou_xian`、安全落点/入口、选种、补屏与两次补屏断言；
   - 保留并改写「换房释放旧房实体、更新 `fang_jian_qu`」为「实体释放、记录保留、目标房按记录加载」；
   - 403–454 行裸 `YuQun._process` 调用必须有九房未初始化 guard。
3. 新增用例见 VERIFICATION 清单（九房初始化、同步、成长恢复、全局节拍、贴脸保护、虚拟互吃、档位保底、雷达、停刷冻结）。
4. 跑 `tests/pao_pi.bat` 八步全绿；`validate_task.py` VALID；`check_task_scope.py check` 0 violation。
5. 跑临时机器人自动通关探针评估难度，跑完删除脚本与日志。

## 禁止

- 不按 `yu_npc` 组全表清理（Main 下鲸鲨 Boss 与教学鱼会被误杀）。
- 不让 `YuNpc._ready` 的默认值覆盖恢复载荷。
- 不在换房时重置全局 20 秒互吃计时。
- 不改雷达图例文本，不删既有图例断言。
- 不新增 Autoload、不改存档 schema、不改主场景顶层结构。
