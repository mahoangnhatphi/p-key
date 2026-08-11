@echo off
setlocal
cd /d "%~dp0"

if not defined LAZARUS_DIR set "LAZARUS_DIR=C:\lazarus"

where lazbuild >nul 2>nul
if errorlevel 1 (
  set "LAZBUILD=%LAZARUS_DIR%\lazbuild.exe"
) else (
  set "LAZBUILD=lazbuild"
)

where windres >nul 2>nul
if errorlevel 1 (
  for /d %%D in ("%LAZARUS_DIR%\fpc\*") do (
    if exist "%%~fD\bin\x86_64-win64\windres.exe" set "WINDRES=%%~fD\bin\x86_64-win64\windres.exe"
  )
) else (
  set "WINDRES=windres"
)

if not exist "%LAZBUILD%" if not "%LAZBUILD%"=="lazbuild" (
  echo Lazarus was not found. Set LAZARUS_DIR to its installation folder.
  exit /b 1
)
if not defined WINDRES (
  echo windres was not found. Add Free Pascal to PATH or set LAZARUS_DIR.
  exit /b 1
)

echo === Build standalone Windows app ===
"%WINDRES%" -i src\app.rc -o src\app.res
if errorlevel 1 exit /b 1
"%LAZBUILD%" src\p_key.lpi
