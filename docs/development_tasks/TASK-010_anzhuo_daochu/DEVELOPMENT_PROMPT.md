# TASK-010: 安卓导出与 TapTap 准备（工具链 + APK + 真机）

> 引擎：Godot 4.7
> 开发策略：plan_driven
> 参与模式：guided_co_development
> 执行模式：teaching
> 任务规格版本：v1
> 审批状态：awaiting
> 交付状态：proposed
> Git 基线：5d7f8325627fbe2a34f041cf0ca472c78ed1357c

## 一、任务目标

九课下来，游戏只活在 F5 里。本课把它**装进手机**：装齐安卓工具链 → 配导出预设 → debug APK 打通链路 → keystore 签名导出 release APK → adb 装进真机试玩。

真机已确认有，TapTap 开发者账号还没有——所以本课终点是"手机上能装能玩"，另附一份《提审材料清单》，注册与提审留到下一任务。

承接第 9 课的检查哲学：**"导出成功"要看产物，不看退出码。**

### 完成后可观察结果

- `tools/jian_cha_android.bat` 一条命令：JDK / SDK / adb / 导出模板四项全 ✓，退出码 0
- `build/shenhaishi-debug.apk` 能被 adb 装进手机
- `build/shenhaishi-release.apk` 通过 apksigner 验签
- 真机上能完整玩一局：触摸跟随 → 吃鱼升级 → 三选一 → 死亡结算 → 重开

## 二、四步实现

### step-01 工具链安装 + 自查门禁

按序装：Android 导出模板（必须 4.7.2）→ JDK 17 → Android SDK（platform-tools / build-tools / platforms）→ adb。新建 `tools/jian_cha_android.bat` 逐项检查，缺任一退出码 1。

### step-02 Android 导出预设 + debug APK

编辑器 项目→导出→Android：包名 / 图标 / 横屏 / arm64-v8a / 最小权限。命令行 `--export-debug` 导出，然后查产物：存在、体积、解包内容三件套。

### step-03 release keystore + 签名 APK

keytool 生成 keystore（仓库外保存，.gitignore 补 *.jks）→ `--export-release` → apksigner verify 验签。**丢了 keystore = 永远无法覆盖更新。**

### step-04 真机安装 + 回归 + 提审材料清单

adb install → 试玩四项 → 导出前后各跑一次 pao_pi.bat → 整理提审材料清单。

## 三、零触碰红线

keystore 与口令永不进仓库；玩法/数值/美术零改动；无插件无第三方 SDK；TapTap 账号相关操作不代办。

## 四、学习契约

| # | 目标 | 验证时机 |
|---|---|---|
| 1 | debug 与 release 构建的区别 | orientation / step-03 |
| 2 | keystore 是什么、丢了会怎样 | step-03 亲手验证签名 |
| 3 | 导出预设四项（包名/图标/权限/架构） | step-02 编辑器核对 |
| 4 | TapTap 提审材料清单 | step-04 |
| 5 | 导出成功为什么查产物不查退出码 | step-01/02 门禁设计 |
| 6 | push_warning vs error（第 9 课遗留观察项清账） | orientation 开场 |
