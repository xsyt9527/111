@echo off
chcp 65001 >nul
rem Test gate (lesson 9 step-04): run every test before delivery
rem Exit 0 = all green; 1 = something failed
rem   (1) any step exit code != 0 -> red (failed assertions)
rem   (2) output contains ERROR (includes SCRIPT ERROR) -> red
rem   (3) a test step printed no "Results:" line -> red (scene did not run)
rem [8/8] quit-after 960: 收卷闭包链要等结算音开播再掐，掐完还有 0.3 秒墙钟释放等待

set GODOT=D:\001\Godot_v4.7.2-stable_win64.exe
set XIANG_MU=D:\新游戏001
set RI_ZHI=%TEMP%\pao_pi.log

echo === [1/8] 导入 --import ===
"%GODOT%" --headless --path "%XIANG_MU%" --import > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
type "%RI_ZHI%"

echo === [2/8] 账本纯逻辑 ce_zhang_ben ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_zhang_ben.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [3/8] 边界 ce_bian_jie ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_bian_jie.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [4/8] 数据校验 ce_shu_ju ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_shu_ju.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [5/8] 摇杆纯逻辑 ce_yao_gan ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_yao_gan.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [6/8] 咬击纯逻辑 ce_zhan_dou ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_zhan_dou.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [7/8] 局外解锁 ce_jie_suo ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_jie_suo.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [8/8] 判定集成 ce_panding（场景模式）===
"%GODOT%" --headless --path "%XIANG_MU%" res://tests/ce_panding_chang_jing.tscn --quit-after 960 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

del "%RI_ZHI%" >nul 2>&1
echo.
echo ========== 全绿：可以交付 ==========
exit /b 0

:shibai
echo.
echo ===== 这一步红了（退出码非 0 / 输出含 ERROR / 缺 Results），完整输出： =====
type "%RI_ZHI%"
echo.
echo ========== 有红：禁止交付 ==========
exit /b 1
