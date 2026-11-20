# TASK-029 集成交接

状态: 未开始（等待审批与前置任务 TASK-026/027/028 串行完成）

## 1. 交付物

| 产物 | 路径 |
|---|---|
| 技能栏布局纯函数与攻击按钮 | `scripts/neng_li_ui.gd` |
| 手动咬击入口 | `scripts/yu.gd` |
| 用例 | `tests/ce_panding.gd` |
| 报告 | 本目录 `IMPLEMENTATION_REPORT.md` / `VERIFICATION_REPORT.md` / `CODE_REVIEW.md` |

## 2. 新增/变更接口

```gdscript
# neng_li_ui.gd
func ji_neng_bu_ju(shu: int, shi_kou: Vector2, you_yuan: float = 1146.0, yao_gan_ce: String = "zuo") -> Array[Dictionary]
func gong_ji_an_niu_wei_zhi(shi_kou: Vector2, yao_gan_ce: String) -> Vector2

# yu.gd
func yao_ji_shou_dong() -> bool
func _chang_shi_yao_ji() -> bool   # 由 void 改为返回是否咬中，旧调用忽略返回值
```

- `ji_neng_bu_ju` 是纯函数：不读节点、不读 `self`，测试可直接实例化脚本调用。
- `yao_ji_shou_dong` 是**唯一**新增的手动入口；不复制 `_chang_shi_yao_ji` 的结算，只做外层资格判断。

## 3. 共享状态与约束

- 手动/自动咬共用 `_yao_ji_leng_que`，冷却由 `_chang_shi_yao_ji` 内部设置；空挥不进冷却。
- `zi_dong_yao_ji = true` 默认不变；攻击键不替换自动咬。
- 按钮全部由 `NengLiUI` 代码生成，`Main.tscn` 不改；演出隐藏 `NengLiUI` 层时按钮一并隐藏。
- 技能数或摇杆侧变化才重建按钮；`_process` 不重排。

## 4. 与其他任务的关系

- **依赖** TASK-014（`zhu_dong_zu` 账本）、TASK-024（船可咬契约）、TASK-026（咬击经验/鱼王守卫，`_chang_shi_yao_ji` 的结算规则以 026 落地版为准）。
- **被依赖** 无（纯 UI/入口层，后续任务可继续在 `_chang_shi_yao_ji` 内扩展）。
- 串行顺序：TASK-026 → 027 → 028 → 029。029 开工前需重新 `capture` scope 基线。

## 5. 验证清单（实现完成时填结果）

- [ ] `validate_task.py` VALID
- [ ] `check_task_scope.py check` 0 violation
- [ ] headless `--import` 0 ERROR
- [ ] `tests/pao_pi.bat` 八步全绿（记录测试总数变化）
- [ ] F5 20 个主动不溢出
- [ ] F5 攻击键咬鱼/咬船、冷却读秒
- [ ] F5 摇杆换右手侧镜像
- [ ] 用户确认手感

## 6. 回滚

布局常量集中在 `neng_li_ui.gd` 顶部（`MEI_LIE_ZUI_DUO` / `ZUI_DUO_LIE` / `YOU_YUAN` / `ZUO_YUAN` / `DI_BU_Y`）；攻击键位置由 `gong_ji_an_niu_wei_zhi` 单点决定。回滚只需调常量或删除 `_gong_ji_an_niu` 创建段，不影响 `yu.gd` 入口（入口无调用方时无害）。
