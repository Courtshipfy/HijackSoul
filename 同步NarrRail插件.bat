@echo off
chcp 65001 >nul
setlocal

cd /d "%~dp0"

set "SUBMODULE_PATH=third_party\NarrRail-Godot-Plugin"
set "PLUGIN_SOURCE=%SUBMODULE_PATH%\narrrail"
set "PLUGIN_TARGET=hijacksoul\addons\narrrail"

echo 当前目录: %cd%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo 错误: 没有找到 Git，请先安装 Git for Windows。
    echo.
    pause
    exit /b 1
)

echo 正在初始化并更新 NarrRail submodule...
git submodule update --init --remote "%SUBMODULE_PATH%"
if errorlevel 1 (
    echo.
    echo 更新 NarrRail submodule 失败，请检查网络或仓库权限。
    echo.
    pause
    exit /b 1
)

if not exist "%PLUGIN_SOURCE%\plugin.cfg" (
    echo.
    echo 错误: 找不到插件源目录: %PLUGIN_SOURCE%
    echo 预期文件不存在: %PLUGIN_SOURCE%\plugin.cfg
    echo.
    pause
    exit /b 1
)

if not exist "hijacksoul\addons" mkdir "hijacksoul\addons"

echo.
echo 正在同步插件到 %PLUGIN_TARGET% ...
robocopy "%PLUGIN_SOURCE%" "%PLUGIN_TARGET%" /MIR /XD ".git" ".godot" /XF ".DS_Store" "Thumbs.db" "Desktop.ini"
set "ROBOCOPY_STATUS=%ERRORLEVEL%"

if %ROBOCOPY_STATUS% GEQ 8 (
    echo.
    echo 同步失败，robocopy 退出码: %ROBOCOPY_STATUS%
    echo.
    pause
    exit /b %ROBOCOPY_STATUS%
)

echo.
echo Normalizing plugin text files to LF line endings...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$extensions = '.gd','.uid','.cfg','.import','.tres','.tscn','.json','.md','.txt','.yaml','.yml'; $crlf = [string][char]13 + [string][char]10; $lf = [string][char]10; Get-ChildItem -LiteralPath '%PLUGIN_TARGET%' -Recurse -File | Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } | ForEach-Object { $text = [IO.File]::ReadAllText($_.FullName); if ($text.Contains($crlf)) { $text = $text.Replace($crlf, $lf); [IO.File]::WriteAllText($_.FullName, $text, [Text.UTF8Encoding]::new($false)) } }"
if errorlevel 1 (
    echo.
    echo Failed to normalize plugin line endings.
    echo.
    pause
    exit /b 1
)

echo.
echo NarrRail 插件同步完成。当前 submodule 提交:
git -C "%SUBMODULE_PATH%" --no-pager log -1 --oneline
echo.
echo 如果插件内容有变化，请提交 submodule 指针和 hijacksoul\addons\narrrail 下的文件变更。
echo.
pause
