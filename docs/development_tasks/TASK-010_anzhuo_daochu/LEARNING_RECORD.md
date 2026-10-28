# TASK-010 学习记录：安卓导出与 TapTap 准备

## 学习目标

| # | 目标 | 掌握证据 |
|---|---|---|
| 1 | 说出 debug 与 release 构建的区别 | 待验证（step-03 亲手验签） |
| 2 | 解释 keystore 是什么、丢失后果 | 待验证（step-03） |
| 3 | 复述导出预设四项（包名/图标/权限/架构） | 待验证（step-02 编辑器核对） |
| 4 | 说出 TapTap 提审材料清单 | 待验证（step-04） |
| 5 | 解释导出成功为什么查产物不查退出码 | 待验证（step-01/02） |
| 6 | 复述 push_warning vs error（第 9 课遗留观察项） | 待验证（orientation 开场） |

## 本课新概念

- 待实现后填写

## 检查点与证据

### orientation（实现前，2026-10-28）

- 已完成，四问收卷：
  - **问 1：导出成功为什么查产物不查退出码？** 学生答：「退出码 0 只能证明代码没错，apk 导出要看有没有导出来文件」——✅ 方向全对。补讲：导出可能**安静失败**（退出码 0 但产物缺失/体积异常/解包缺件），所以三件套 = 文件在、体积合理、解包见 `AndroidManifest.xml` 与 `classes.dex`。
  - **问 2：debug 与 release APK 区别？** 学生答：「一个可以方便改代码，一个上锁了」——◐ 方向对，补讲三点：debug 含调试符号、不优化、方便连调试器；release 做优化（体积小、性能好）且必须签名。冷知识：Android 所有 APK 都要签名，debug 用自动生成的调试密钥，release 必须用自己的 keystore。
  - **问 3：keystore 是什么，为什么丢了就无法更新？** 学生答：「这个是身份证，身份证没了系统以为你是新的人」——✅ 类比非常好。签名一致 Android 才允许覆盖更新；丢了 = 同包名永远无法再发更新，只能当新应用重新上架。
  - **问 4：真机回归要覆盖哪些玩法？** 学生答：「触摸，吃鱼，升级，3选1，死亡，受伤等等」——◐ **列的是第 9 课前的旧循环**，已纠正为 TASK-011 后的新玩法：①左下摇杆转向（真机无 WASD——debug 键盘只在电脑）、②松手减速、③×1.1 门槛（同体型不吃不伤）、④体型即血量（受伤变小、左上数字变化）、⑤结算重开闭环。
  - 开场清账：push_warning vs error 已在第 10 课 orientation 通过，本课不再复考。

### godot-inspection（step-02 后）

- 待进行

## step-01 实现证据（2026-10-28）

- 环境盘点确认四件全缺（JDK / Android SDK / adb / 导出模板），按任务包顺序补齐：
  1. **导出模板 4.7.2.stable**：GitHub 直连被墙（exit 7），改走 `gh-proxy.com` 代理下载 1.28 GB `.tpz`，解包安装到 `%APPDATA%\Godot\export_templates\4.7.2.stable\`，`version.txt` 核对 `4.7.2.stable`。
  2. **JDK 17**：清华 Adoptium 镜像 Temurin `17.0.20.1+1` zip 版，解压到 `D:\Android\jdk-17.0.20.1+1`（纯英文路径）。
  3. **Android SDK**：腾讯镜像下 cmdline-tools，`sdkmanager --licenses` 全收后装 `platform-tools`、`build-tools;34.0.0`、`platforms;android-34`。
  4. **adb 37.0.1** 随 platform-tools 落位；`apksigner 0.9`、`zipalign`、`keytool`（JDK 自带）逐个点验。
- 新建 `tools/jian_cha_android.bat` 自查门禁：六件套逐项核对（存在性 + 版本号 + 可执行），缺任一退出码 1。实测：全绿退出码 0；负向自证（故意指错 JDK 路径）第 1 步即红退出码 1——门禁红绿双向确认。
- 门禁门禁本身也是产品：写它时踩了两个 bat 经典坑（见下「教学现场」）。
- 环境变量持久化：`JAVA_HOME`、`ANDROID_HOME`、用户 PATH 追加三目录。

### 教学现场：bat 的两个经典坑（2026-10-28）

1. **bat 调用另一个 bat 不加 `call`** → 控制权链式转移，外层脚本在被调 bat 结束时直接散场。症状：跑到第 3 步（sdkmanager）就没有下文、退出码还是 0。修法：`call "....bat"`。
2. **cmd 对多字节 `rem` 行的解析错位**：连续的中文 rem 行（chcp 65001 前后都可能）会让 cmd 把下一行从字节中间切开执行，报 `'全在' is not recognized` 一类碎片命令。用最小复现实验钉死规律：中文 rem 紧跟中文 rem 会踩中（ce_b 红），前面垫 ASCII 行则安全（ce_c 绿）；`echo` 中文行无论怎么排都安全（pao_pi.bat 六步头部实证）。工程决策：**bat 的 rem 一律 ASCII，中文只放 echo 输出**。
3. 附带发现：Write 工具产出 LF 行尾，bat 必须 CRLF（`sed -i 's/$/\r/'` 归一化），否则 cmd 按错行切割整份脚本。

### verification-handoff（收尾前）

- 待进行

## 课后题

- 待结课时出
