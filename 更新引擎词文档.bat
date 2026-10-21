@echo off
chcp 65001 >nul
cd /d "%~dp0"
python "tools\shengcheng_cibiao_docx.py"
if errorlevel 1 (
  echo.
  echo 生成失败：请确认已安装 Python 与 python-docx。
  pause
) else (
  echo.
  echo 打开 Godot引擎词总表.docx 查看最新词表。
  timeout /t 3 >nul
)
