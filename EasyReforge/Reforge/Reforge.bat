@echo off
chcp 65001 > NUL
set CURL_CMD=C:\Windows\System32\curl.exe -kL
set EASY_TOOLS=%~dp0..\..\EasyTools
set GITHUB_CLONE_OR_PULL=%EASY_TOOLS%\Git\GitHub_CloneOrPull.bat

pushd %~dp0..\..

@REM echo https://github.com/Panchovix/stable-diffusion-webui-reForge
@REM reForge main, pinned so Update.bat and repeat installs are reproducible.
call %GITHUB_CLONE_OR_PULL% Panchovix stable-diffusion-webui-reForge main 739b2e1d9ab63160eaff9c8f73172c8da68424e1
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

popd
pushd %~dp0..\..\stable-diffusion-webui-reForge

call %EASY_TOOLS%\Python\Python_Activate.bat
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

echo python -m pip install -qq -U pip setuptools wheel
python -m pip install -qq -U pip setuptools wheel
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

@REM https://github.com/woct0rdho/SageAttention/releases
@REM https://github.com/woct0rdho/triton-windows/releases
echo pip install -qq torch==2.9.0+cu128 torchaudio==2.9.0+cu128 torchvision==0.24.0+cu128 --index-url https://download.pytorch.org/whl/cu128
pip install -qq torch==2.9.0+cu128 torchaudio==2.9.0+cu128 torchvision==0.24.0+cu128 --index-url https://download.pytorch.org/whl/cu128
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

echo pip install -qq triton-windows==3.5.1.post24
pip install -qq triton-windows==3.5.1.post24
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

set "TRITON_CACHE=C:\Users\%USERNAME%\.triton\cache"
set "TORCH_INDUCTOR_TEMP=C:\Users\%USERNAME%\AppData\Local\Temp\torchinductor_%USERNAME%"

if not exist "%TRITON_CACHE%" ( goto :EASY_TRITON_CACHE_NOT_FOUND )
echo rmdir /S /Q "%TRITON_CACHE%"
rmdir /S /Q "%TRITON_CACHE%"
@REM if %ERRORLEVEL% neq 0 ( pause & exit /b 1 )
:EASY_TRITON_CACHE_NOT_FOUND

if not exist "%TORCH_INDUCTOR_TEMP%" ( goto :EASY_TORCH_INDUCTOR_TEMP_NOT_FOUND )
echo rmdir /S /Q "%TORCH_INDUCTOR_TEMP%"
rmdir /S /Q "%TORCH_INDUCTOR_TEMP%"
@REM if %ERRORLEVEL% neq 0 ( pause & exit /b 1 )
:EASY_TORCH_INDUCTOR_TEMP_NOT_FOUND

echo pip install -qq https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu128torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl
pip install -qq https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu128torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

set LLAMA_CPP_WHL=llama_cpp_python-0.3.4-cp310-cp310-win_amd64.whl
if exist %LLAMA_CPP_WHL% ( goto :LLAMA_CPP_INSTALLED )

echo %CURL_CMD% -O https://github.com/abetlen/llama-cpp-python/releases/download/v0.3.4-cu124/%LLAMA_CPP_WHL%
%CURL_CMD% -O https://github.com/abetlen/llama-cpp-python/releases/download/v0.3.4-cu124/%LLAMA_CPP_WHL%
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

echo pip install -qq %LLAMA_CPP_WHL%
pip install -qq %LLAMA_CPP_WHL%
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

:LLAMA_CPP_INSTALLED

echo pip install -qq -r "%~dp0src\requirements.txt"
pip install -qq -r "%~dp0src\requirements.txt"
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

echo xcopy /SQY "%~dp0src\stable-diffusion-webui-reForge\*.*" ".\"
xcopy /SQY "%~dp0src\stable-diffusion-webui-reForge\*.*" ".\"

popd
