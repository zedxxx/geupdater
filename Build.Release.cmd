@echo off

set app=GEUpdateChecker

call rsvars.bat

for %%p in (Win32 Win64) do (
  msbuild %app%.dproj "/p:config=Release" "/p:platform=%%p" "/t:rebuild" "/p:VerInfo_AutoIncVersion=false"
  amResourceModuleBuilder %app%.xlat -b -s:.\.bin\%%p\%app%.exe -y:.\.bin\%%p\%app%.drc -o:.\.bin\%%p\res\ -i -v -n:1
)

pause