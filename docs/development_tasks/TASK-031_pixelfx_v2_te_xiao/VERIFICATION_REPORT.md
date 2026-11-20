# TASK-031 验证报告

- 任务：pixelfx v2 特效全量落地 + 图鉴特效预览
- 验证日期：2026-11-18
- 环境：Godot 4.7.2 headless，Windows 11（Git Bash 复刻 `tests/pao_pi.bat` 八步）
- 结论：自动化门禁全绿（4032 断言）；F5 观感与性能待用户实玩判定

## 一、八步门禁

| 步骤 | 脚本 / 内容 | 断言 |
|---|---|---:|
| 1/8 | `--import` 资源导入 | 0 ERROR |
| 2/8 | `ce_zhang_ben` 账本纯逻辑 | 232 passed, 0 failed |
| 3/8 | `ce_bian_jie` 边界 | 25 passed, 0 failed |
| 4/8 | `ce_shu_ju` 资源数据校验 | 2037 passed, 0 failed |
| 5/8 | `ce_yao_gan` 摇杆纯逻辑 | 8 passed, 0 failed |
| 6/8 | `ce_zhan_dou` 咬击纯逻辑 | 20 passed, 0 failed |
| 7/8 | `ce_jie_suo` 局外解锁 | 141 passed, 0 failed |
| 8/8 | `ce_panding` 判定集成（场景模式） | 1569 passed, 0 failed |
| 合计 | 七份测试 | **4032 passed, 0 failed** |

每步退出码 rc=0、输出 0 `ERROR`、`Results:` 行齐全；脚本输出「全绿：可以交付」。

对比 TASK-030 基线（3155 断言）：

- `ce_shu_ju` 1278 → 2037（**+759**，用例 11 v2 资源完整性；含 84 套 × 每套约 9 条断言 ≈ 756 条 + 注册表/主动覆盖 3 条）；
- `ce_panding` 1451 → 1569（**+118**，图鉴特效预览与 v2 接入相关用例）。

## 二、新增资源完整性用例（`ce_shu_ju` 用例 11）

遍历 `TeXiaoKuZiYuan.ZI_YUAN` 84 条，逐套断言：

| 检查 | 结果 |
|---|---|
| PNG + JSON 文件存在 | 84/84 |
| JSON `frames` 非空 | 84/84 |
| 首帧尺寸 = JSON `frameSize` | 84/84 |
| `pivot` 在帧内 | 84/84 |
| `fps > 0`、`columns > 0` | 84/84 |
| `visible` 宽高非零 | 84/84 |
| `XiangSuTeXiao.qu_lu(lu)` 可解析（frames 非空） | 84/84 |
| 注册表引用键全覆盖（`JI_NENG_KU` / `FAN_KUI` / `ZHUANG_TAI_KU` / `JIE_MIAN_KU` / `CHUAN_KU`） | 全部通过 |
| `NengLiKu.ZHU_DONG` 42 个主动 id 都在 `JI_NENG_KU` | 42/42 |
| 资源套数下限 | `zi_yuan_shu >= 84` 通过 |

## 三、PCK 导出实测（JSON 可读性）

风险点：pixelfx JSON 靠 `FileAccess` 读，`export_filter="all_resources"` 是否会把 `.json` 打进包。

实测方法：临时导出 `--export-pack "Windows PC"`，用 `--main-pack <pck> --script` 运行包内探针脚本读取。

| 项 | 结果 |
|---|---|
| PCK 内 `texiao_fb_ming_zhong.json` 可 `FileAccess.file_exists` | `true` |
| `XiangSuTeXiao.qu_lu` 解析 | `true`，frames=9 |
| 待用 JSON（`assets/待用/`）也在包内 | 是 |

**结论**：`export_presets.cfg` 无需加 `include_filter="*.json"`，现有导出配置即可用。探针脚本与测试 pck 已删除。

## 四、尺寸口径验证（实现层）

节点缩放统一为 `目标像素宽 ÷ JSON visible 宽`（alpha 并集宽度）；各类型目标宽：

- 范围型 = `Yu.ji_neng_ban_jing(neng, dang) × 2 × 系数`（走判定唯一入口，含身位/固定像素/体长下限修正）；
- 贴身/命中 = `ti_chang()` 或 `TeXiaoKu.ti_kuan(目标)` × 系数；
- 全屏 = 视口最长边 × 1.2~1.4；
- 光环 = 目标 `ti_kuan()` × 1.2。

取值范围集中在注册表与各调用点的系数常量，改动一处即全局生效；图鉴滑杆（80~560px）可视化验证缩放行为。

## 五、F5 实机清单（待用户）

1. **体型跟随**：Lv.1 与 Lv.10+（电鳗/鲨鱼等）放同一技能，特效应明显随体型放大；对比图鉴滑杆两端。
2. **全屏技固定**：深渊漩涡（利维坦）、吞星（星空吞兽）、唤风（风暴领主）、鲸鲨登场，任意体型都不应满屏溢出或过小。
3. **命中反馈**：手动咬命中火花 / 致命区金色暴击 + 跳字 / 受击红闪 / 吞鱼白闪 / 咬死暗红爆散 / 升级金环 / 消化 / 吃肉。
4. **状态光环**：石化灰白、魅惑粉、电麻电黄、毒晕绿、恐惧黑紫——头顶挂载、结束自动消失、六色可区分；船上同一套。
5. **船四招**：深水炸弹、船锚横扫、探照灯、鱼叉齐射的落点/弹道特效。
6. **系统位**：三选一红蓝绿光柱、成就、选角达成、章节转场、头顶血条受击、边界警告（3 秒节流）。
7. **图鉴预览**：五分类逐卡点「预览特效 ＞」，确认播放/循环/重播/滑杆缩放/Esc 关闭；无资源卡不应出现按钮。
8. **性能**：手机/Web 上连续放技能 5 分钟，观察帧率与内存（LRU 24 套上限）。
9. **回退**：可选把 `TeXiaoKu.SHI_YONG_V2` 改 false，确认全量回退旧 4 帧特效、无报错。

## 六、清理

- 已删除：`tests/ce_pck_texiao.gd`（+ `.uid`）、`build/texiao_pck_test.pck`。
- 无调试截图/临时脚本残留；工作区仅保留正式产物。
