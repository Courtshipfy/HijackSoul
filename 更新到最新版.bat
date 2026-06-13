@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

echo 当前目录: %cd%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo 错误: 没有找到 Git，请先安装 Git for Windows。
    echo.
    pause
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo 错误: 当前目录不是 Git 仓库。
    echo.
    pause
    exit /b 1
)

for /f "delims=" %%b in ('git branch --show-current') do set "BRANCH=%%b"
if "%BRANCH%"=="" (
    echo 错误: 当前不在普通分支上，无法自动拉取。
    echo.
    pause
    exit /b 1
)

echo 正在更新分支: %BRANCH%
echo.

git fetch --prune
if errorlevel 1 (
    echo.
    echo 拉取远程信息失败，请检查网络或仓库权限。
    echo.
    pause
    exit /b 1
)

set "UPSTREAM="
for /f "delims=" %%u in ('git rev-parse --abbrev-ref --symbolic-full-name @{u} 2^>nul') do set "UPSTREAM=%%u"
if "%UPSTREAM%"=="" set "UPSTREAM=origin/%BRANCH%"

for /f "tokens=1* delims=/" %%r in ("%UPSTREAM%") do (
    set "REMOTE=%%r"
    set "REMOTE_BRANCH=%%s"
)

git pull --rebase --autostash "%REMOTE%" "%REMOTE_BRANCH%"
if errorlevel 1 (
    echo.
    echo 更新失败。请查看上面的错误信息。
    echo.
    pause
    exit /b 1
)

echo.
echo 更新完成。当前最新提交:
git --no-pager log -1 --oneline
echo.
pause
