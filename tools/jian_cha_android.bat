@echo off
chcp 65001 >nul
rem TASK-010 step-01: android toolchain self-check gate, run before APK export
rem rule: exit 1 if any of the six items is missing, exit 0 when all present
rem checklist: JDK 17 / adb / sdkmanager / build-tools(apksigner+zipalign) / platforms / templates 4.7.2
rem NOTE rem lines are ASCII-only on purpose: cmd misparses consecutive
rem   multibyte rem lines (pointer desync), Chinese belongs in echo lines only
rem NOTE calling another .bat from a .bat REQUIRES call, otherwise control
rem   transfers away and this script silently ends

set JAVA_HOME=D:\Android\jdk-17.0.20.1+1
set ANDROID_HOME=D:\Android\sdk
set RI_ZHI=%TEMP%\jian_cha_android.log

echo === [1/6] JDK 17（java + keytool）===
if not exist "%JAVA_HOME%\bin\java.exe" goto hong_jdk
if not exist "%JAVA_HOME%\bin\keytool.exe" goto hong_jdk
"%JAVA_HOME%\bin\java.exe" -version > "%RI_ZHI%" 2>&1
findstr /c:"17.0" "%RI_ZHI%" >nul || goto hong_jdk
type "%RI_ZHI%"
echo OK

echo === [2/6] adb（platform-tools）===
if not exist "%ANDROID_HOME%\platform-tools\adb.exe" goto hong_adb
"%ANDROID_HOME%\platform-tools\adb.exe" version > "%RI_ZHI%" 2>&1
findstr /c:"Android Debug Bridge" "%RI_ZHI%" >nul || goto hong_adb
type "%RI_ZHI%"
echo OK

echo === [3/6] sdkmanager（cmdline-tools）===
if not exist "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" goto hong_sdkmanager
call "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="%ANDROID_HOME%" --version > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto hong_sdkmanager
echo OK

echo === [4/6] build-tools 34（apksigner + zipalign）===
if not exist "%ANDROID_HOME%\build-tools\34.0.0\apksigner.bat" goto hong_buildtools
if not exist "%ANDROID_HOME%\build-tools\34.0.0\zipalign.exe" goto hong_buildtools
call "%ANDROID_HOME%\build-tools\34.0.0\apksigner.bat" --version > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto hong_buildtools
type "%RI_ZHI%"
echo OK

echo === [5/6] platforms android-34 ===
if not exist "%ANDROID_HOME%\platforms\android-34\android.jar" goto hong_platforms
echo OK

echo === [6/6] 导出模板 4.7.2（android_debug/release.apk）===
set MU_BAN=%APPDATA%\Godot\export_templates\4.7.2.stable
if not exist "%MU_BAN%\android_debug.apk" goto hong_muban
if not exist "%MU_BAN%\android_release.apk" goto hong_muban
findstr /c:"4.7.2" "%MU_BAN%\version.txt" >nul || goto hong_muban
type "%MU_BAN%\version.txt"
echo OK

del "%RI_ZHI%" >nul 2>&1
echo.
echo ========== 全绿：安卓工具链就绪 ==========
exit /b 0

:hong_jdk
echo 红：JDK 17 缺失或版本不对（期望 D:\Android\jdk-17.0.20.1+1，含 bin\java.exe 与 bin\keytool.exe）
exit /b 1

:hong_adb
echo 红：adb 缺失（期望 %ANDROID_HOME%\platform-tools\adb.exe）
exit /b 1

:hong_sdkmanager
echo 红：sdkmanager 缺失或跑不起来（期望 %ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat）
exit /b 1

:hong_buildtools
echo 红：build-tools 34 缺件（期望 apksigner.bat 与 zipalign.exe 在 %ANDROID_HOME%\build-tools\34.0.0\）
exit /b 1

:hong_platforms
echo 红：platforms android-34 缺失（期望 %ANDROID_HOME%\platforms\android-34\android.jar）
exit /b 1

:hong_muban
echo 红：Godot 4.7.2 导出模板缺失（期望 %APPDATA%\Godot\export_templates\4.7.2.stable\ 下有 android_debug.apk、android_release.apk 且 version.txt 为 4.7.2）
exit /b 1
