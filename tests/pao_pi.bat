@echo off
rem 跑批门禁（第 9 课 step-04）：一条命令跑全部测试——以后每次交付前必跑
rem 门禁语义（三重把关，防假绿）：退出码 0=全绿可交付；1=有红
rem   ① 任一步退出码非 0 → 红（测试有 failed）
rem   ② 输出含 ERROR（含 SCRIPT ERROR——断言内部报错不计入计数的那种假绿）→ 红
rem   ③ 测试步没打印 Results 收卷行（场景没跑起来/空跑）→ 红
chcp 65001 >nul

set GODOT=D:\001\Godot_v4.7.2-stable_win64.exe
set XIANG_MU=D:\新游戏001
set RI_ZHI=%TEMP%\pao_pi.log

echo === [1/6] 导入 --import ===
"%GODOT%" --headless --path "%XIANG_MU%" --import > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
type "%RI_ZHI%"

echo === [2/6] 账本纯逻辑 ce_zhang_ben ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_zhang_ben.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [3/6] 边界 ce_bian_jie ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_bian_jie.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [4/6] 数据校验 ce_shu_ju ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_shu_ju.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [5/6] 摇杆纯逻辑 ce_yao_gan ===
"%GODOT%" --headless --path "%XIANG_MU%" --script tests/ce_yao_gan.gd --quit-after 360 > "%RI_ZHI%" 2>&1
if %errorlevel% neq 0 goto shibai
findstr /i /c:"ERROR" "%RI_ZHI%" >nul && goto shibai
findstr /c:"Results:" "%RI_ZHI%" >nul || goto shibai
type "%RI_ZHI%"

echo === [6/6] 判定集成 ce_panding（场景模式）===
"%GODOT%" --headless --path "%XIANG_MU%" res://tests/ce_panding_chang_jing.tscn --quit-after 360 > "%RI_ZHI%" 2>&1
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
