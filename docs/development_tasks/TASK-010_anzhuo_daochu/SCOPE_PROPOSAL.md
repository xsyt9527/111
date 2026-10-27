# TASK-010 范围提案（SCOPE_PROPOSAL）

## 范围内

- **工具链安装**：Godot 4.7.2 对应 Android 导出模板、JDK 17、Android SDK（platform-tools / build-tools / platforms）、adb——全程国内镜像优先，全部装到纯英文路径
- **工具链自查门禁**（tools/jian_cha_android.bat）：四项逐项 ✓/✗，缺任一退出码 1——"装好了"看产物不看安装器退出码
- **Android 导出预设**（export_presets.cfg）：包名 `com.shenhaishi.youxi`、应用名、图标、横屏、ABI 仅 arm64-v8a、最小权限
- **debug APK**：命令行导出 + 产物校验（存在 / 体积 > 20 MB / 解包含 AndroidManifest.xml、classes.dex、libgodot_android.so）
- **release keystore + 签名 APK**：keytool 生成、仓库外保存、apksigner verify 验签
- **真机验收**：adb install → 试玩四项（触摸跟随 / 升级三选一 / 死亡结算重开 / 帧率）
- **回归**：导出前后各跑一次 tests/pao_pi.bat（第 9 课门禁）
- **TapTap 提审材料清单**：只列清单与办理途径，不注册账号

## 范围外（移交后续任务）

- TapTap 开发者账号注册、实名认证、软著申请、正式提审（另立任务）
- 广告 / 统计 / 支付等第三方 SDK
- 玩法、数值、数据表、美术资源任何改动
- AAB 打包与 Google Play 上架
- 性能剖析与帧率优化（真机发现卡顿再另议）

## 零触碰清单

- scripts/**（全部产品脚本）/ scenes/**（全部产品场景）/ data/**（卡池鱼种阈值表）
- tests/**（第 9 课测试资产——只跑不改）
- .agents/skills/**（只读）
- **keystore 与口令：只存仓库外，永不提交**

## 白名单要点

- 新增：tools/jian_cha_android.bat、export_presets.cfg + 三份报告
- 可能修改：project.godot（补横屏方向/图标路径）、.gitignore（补 *.jks）
- 构建产物（build/*.apk）已被 .gitignore 挡住，不入库
