# TASK-008 交接说明（INTEGRATION_HANDOFF）

## 交付物

| 类型 | 路径 | 说明 |
|---|---|---|
| 修改 | `scripts/yu.gd` | +血量（zuida_xue/xue_liang/信号）+ `_shoushang` 扣血 + `_si_wang` 切结算 + 判定入口拆分（ZuiQu 吃/ShangQu 伤）+ 贪食指向 ZuiQu |
| 修改 | `scripts/zhang_ben.gd` | +`jia_jing_yan` 满级封顶分支 + `chong_zhi()` 归零唯一入口 |
| 修改 | `scenes/Main.tscn` | +XueLiangTiao 实例 |
| 修改 | `scenes/Yu.tscn` | +ZuiQu 嘴圈（v2） |
| 新建 | `scripts/xue_liang_ui.gd` / `scenes/XueLiangTiao.tscn` | 血条 UI（信号驱动，学生亲手配红填充） |
| 新建 | `scripts/jie_suan.gd` / `scenes/JieSuan.tscn` | 结算页（读账本展示等级+build；重开按钮闭环） |

零新增资源文件；零 data/ 改动。

## 提供给后续任务的接口

| 接口 | 形态 | 使用者 |
|---|---|---|
| `ZhangBen.chong_zhi()` | 局内状态归零唯一入口 | 第 9 课测试断言（弄脏→chong_zhi→断言归零） |
| 满级封顶行为 | jia_jing_yan 表尾钉满格 | 第 9 课测试断言（灌经验→deng_ji 停 7） |
| `Yu.xue_liang_bian_hua(dangqian, zuigao)` | 玩家血量信号 | 后续回血卡/血量扩展照抄信号模式 |
| 死亡-重开闭环 | Main↔JieSuan 双向切换 | 第 9 课 headless 端到端用例素材；后续死因/时长统计挂 JieSuan |
| Yu 三圈结构 | ZuiQu 吃 / ShangQu 伤 / ChiQu 吸 | 后续范围类 buff 照抄分职（收益/代价/标记三入口） |
| 结算 build 展示 | yi_xuan_ka 动态卡名列表 | 后续结算扩展的挂载点 |

## 场景树（交付后）

```
root
├─ ZhangBen (zhang_ben.gd, Autoload)  ← +满级封顶 +chong_zhi（TASK-008）
├─ [运行中] Main (main.gd)
│  ├─ Haodi / YuQun / JingYanTiao / QiangHuaDanChuang   ← 零改动
│  ├─ Yu (Yu.tscn)
│  │  ├─ Sprite2D / WudiDingshi
│  │  ├─ ZuiQu (Area2D, mask=2)   ← v2 嘴圈：吃（贪食只放大它）
│  │  ├─ ShangQu (Area2D, mask=2) ← 伤区：掉血（含同体型）
│  │  └─ ChiQu (Area2D, mask=2)   ← 吸附标记
│  └─ XueLiangTiao (CanvasLayer, 新) → XueLiangTiaoBg (ProgressBar 红填充)
└─ [死亡后替换为] JieSuan (CanvasLayer, 新)
   ├─ BanDi / BiaoTi("本局终了") / DengJi(Lv.X 读账本)
   ├─ KaLieBiao (VBoxContainer 动态卡名)
   └─ ChongKai ("再来一次" → chong_zhi + 切回 Main)
```

## 已知限制 / 后续任务注意

1. **Resource 三分工**第 5 次挂账——第 9 课写测试 .tres 时验收（CODE_REVIEW P3-1）
2. **xiao_guo 全键校验断言**——遍历卡池逐张触发零 push_warning（P3-2）
3. **chong_zhi/封顶回归断言**——探针脚本可改造为第 9 课测试（P3-3）
4. **升级/吞吃 tween 同帧抖动**——终态不漂移；测试加终态断言（P3-4）
5. **push_warning vs error**——学生课后题纠正过一次（"报黄色，效果不生效"），第 9 课前再验
6. 学生产品提案挂账：**关卡制等级上限 + 无上限关卡**（封顶值读阈值表=换表即得）——后续迭代候选

## 集成检查清单

- [x] 任务包通过 validate_task.py（v1 生成/审批；v2 待审批/审批/进行中，共 5 次 VALID）
- [x] headless 导入 0 错误（输出筛查，每步）
- [x] headless 360 帧 0 错误（输出筛查，每步）
- [x] check_task_scope.py check 零违例（v1/v2 两轮基线）
- [x] 学生全量回归七课 + 本课闭环确认
- [x] 探针清理、无临时文件残留
- [x] LEARNING_ROADMAP / TASK_INDEX / 引擎词总表（md + docx）已更新
