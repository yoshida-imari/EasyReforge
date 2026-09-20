@echo off
chcp 65001 > NUL

call %~dp0EasyTools\Git\Git_SetPath.bat
if %ERRORLEVEL% neq 0 ( exit /b 1 )

pushd %~dp0EasyTools
echo.
echo https://github.com/Zuntan03/EasyTools
echo git -C EasyTools fetch origin
git fetch origin
echo git -C EasyTools reset --hard origin/main
git reset --hard origin/main
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )
popd

pushd %~dp0
echo.
echo https://github.com/yoshida-imari/EasyReforge
set "EASY_REFORGE_BRANCH="
for /f "delims=" %%B in ('git branch --show-current') do set "EASY_REFORGE_BRANCH=%%B"
if not defined EASY_REFORGE_BRANCH (
	echo Detached HEAD; keeping the current EasyReforge revision.
	goto :EASY_REFORGE_NO_REMOTE_BRANCH
)
echo git fetch origin
git fetch origin
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )
git show-ref --verify --quiet refs/remotes/origin/%EASY_REFORGE_BRANCH%
if %ERRORLEVEL% neq 0 (
	echo No origin/%EASY_REFORGE_BRANCH% branch; keeping the current local branch.
	goto :EASY_REFORGE_NO_REMOTE_BRANCH
)
echo git reset --hard origin/%EASY_REFORGE_BRANCH%
git reset --hard origin/%EASY_REFORGE_BRANCH%
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )
:EASY_REFORGE_NO_REMOTE_BRANCH
popd

call %~dp0EasyReforge\Setup.bat
if %ERRORLEVEL% neq 0 ( exit /b 1 )
