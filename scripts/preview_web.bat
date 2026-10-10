@echo off
title MeowTang Web Preview Server
echo ========================================================
echo   MeowTang (เหมียวตังค์) - Local Web Preview Server
echo ========================================================
echo กำลังเปิดหน้าเว็บตัวอย่างที่ http://localhost:8088 ...
start "" "http://localhost:8088"
cd /d "E:\ai_expense_tracker\build\web"
python -m http.server 8088
pause
