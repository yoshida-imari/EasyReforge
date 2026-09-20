@echo off
chcp 65001 > NUL
set EASY_TOOLS=%~dp0..\..\EasyTools
set GITHUB_CLONE_OR_PULL=%EASY_TOOLS%\Git\GitHub_CloneOrPull.bat
set CURL_CMD=C:\Windows\System32\curl.exe -kL

pushd %~dp0..\..\stable-diffusion-webui-reForge\extensions

if not exist ..\extensions-backup\ (
	mkdir ..\extensions-backup
)

@REM https://github.com/DominikDoom/a1111-sd-webui-tagcomplete
call %GITHUB_CLONE_OR_PULL% DominikDoom a1111-sd-webui-tagcomplete main c341ccccb6e10ec0b84403f4c95803532f6fd0aa
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/Bing-su/adetailer
call %GITHUB_CLONE_OR_PULL% Bing-su adetailer main 36189cbea735b85fd01e98ac42002b8ce6f0e41d
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM reForge pins protobuf 3.20.0; keep MediaPipe on the compatible 0.10.11 line.
echo copy /Y "%~dp0src\adetailer_install.py" "adetailer\install.py"
copy /Y "%~dp0src\adetailer_install.py" "adetailer\install.py"
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/Panchovix/reForge-Sigmas_merge
call %GITHUB_CLONE_OR_PULL% Panchovix reForge-Sigmas_merge main 027b89f07d0d44fae12a1fab4a73f4f770a066cd
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/adieyal/sd-dynamic-prompts
call %GITHUB_CLONE_OR_PULL% adieyal sd-dynamic-prompts main de056ff8d80e4ad120e13a90cf200f3383f427c6
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/Haoming02/sd-forge-couple
call %GITHUB_CLONE_OR_PULL% Haoming02 sd-forge-couple main 707f72c1f8d4401e96eaeffbff5755fad9299b12
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/blue-pen5805/sdweb-easy-generate-forever
call %GITHUB_CLONE_OR_PULL% blue-pen5805 sdweb-easy-generate-forever master 2f507a03be3dd918765de114dd35c4f703805548
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/alemelis/sd-webui-ar
@REM call %GITHUB_CLONE_OR_PULL% alemelis sd-webui-ar main
@REM if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )
call :MOVE_TO_BACKUP sd-webui-ar

@REM https://github.com/altoiddealer/--sd-webui-ar-plusplus
call %GITHUB_CLONE_OR_PULL% altoiddealer --sd-webui-ar-plusplus main 8b900cd2748f95bce455db62ba0cb08093a3ca59
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

if not exist --sd-webui-ar-plusplus\resolutions.txt (
	echo copy %~dp0src\resolutions.txt --sd-webui-ar-plusplus\
	copy %~dp0src\resolutions.txt --sd-webui-ar-plusplus\
)

if not exist --sd-webui-ar-plusplus\aspect_ratios.txt (
	echo copy %~dp0src\aspect_ratios.txt --sd-webui-ar-plusplus\
	copy %~dp0src\aspect_ratios.txt --sd-webui-ar-plusplus\
)

@REM チェック状態の保存ができない
@REM https://github.com/hako-mikan/sd-webui-cd-tuner 99baedb599da874f9ee389aa44383bdda448a340
@REM f03cc2fef48e9564ece6338ecca8a9df71fae5cd
call %GITHUB_CLONE_OR_PULL% hako-mikan sd-webui-cd-tuner main 99baedb599da874f9ee389aa44383bdda448a340
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/hako-mikan/sd-webui-lora-block-weight
call %GITHUB_CLONE_OR_PULL% hako-mikan sd-webui-lora-block-weight main 34d2e0ce46a798f0b145d915470851623530bb85
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/Panchovix/sd-webui-lora-block-weight-reforge
@REM call %GITHUB_CLONE_OR_PULL% Panchovix sd-webui-lora-block-weight-reforge main
@REM if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )
call :MOVE_TO_BACKUP sd-webui-lora-block-weight-reforge

@REM チェック状態の保存ができない
@REM https://github.com/hako-mikan/sd-webui-negpip 6ad0365f5a0ae8f66bc785f828a27720b8e6c3c2
@REM b054b92b0fec3b6a65c172aeae3adf45ce87949c
call %GITHUB_CLONE_OR_PULL% hako-mikan sd-webui-negpip main 6ad0365f5a0ae8f66bc785f828a27720b8e6c3c2
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/bluelovers/sd-webui-pnginfo-beautify
call %GITHUB_CLONE_OR_PULL% bluelovers sd-webui-pnginfo-beautify master be63fa2d568cd135548a8eacb27a184776473c16
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/nihedon/sd-webui-weight-helper
call %GITHUB_CLONE_OR_PULL% nihedon sd-webui-weight-helper main a4cc2f4d91ca75fc5e457d6d9fa113de622f803c
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/zixaphir/Stable-Diffusion-Webui-Civitai-Helper
call %GITHUB_CLONE_OR_PULL% zixaphir Stable-Diffusion-Webui-Civitai-Helper master c2b9aa804ed5206ab5eaa111464643dbae6660c6
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/Bocchi-Chan2023/stable-diffusion-webui-wd14-tagger
call %GITHUB_CLONE_OR_PULL% Bocchi-Chan2023 stable-diffusion-webui-wd14-tagger master 2d313188ae9176906e9d6c5138d4b1638ff19a09
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

echo %CURL_CMD% -o stable-diffusion-webui-wd14-tagger\tagger\utils.py https://gist.githubusercontent.com/Zuntan03/ec9010bef0f8fce5b752facd3f8053f0/raw
%CURL_CMD% -o stable-diffusion-webui-wd14-tagger\tagger\utils.py https://gist.githubusercontent.com/Zuntan03/ec9010bef0f8fce5b752facd3f8053f0/raw
if %ERRORLEVEL% neq 0 ( pause & popd & exit /b 1 )

@REM TensorFlow/DeepDanbooru conflict with reForge's protobuf pin; WD14 ONNX stays available.
echo copy /Y "%~dp0src\wd14_requirements.txt" "stable-diffusion-webui-wd14-tagger\requirements.txt"
copy /Y "%~dp0src\wd14_requirements.txt" "stable-diffusion-webui-wd14-tagger\requirements.txt"
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/KohakuBlueleaf/z-tipo-extension
call %GITHUB_CLONE_OR_PULL% KohakuBlueleaf z-tipo-extension main 32d61cf213f6346b05e69fc57fe830ecd9fbfca8
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

@REM https://github.com/L4Ph/stable-diffusion-webui-localization-ja_JP
call %GITHUB_CLONE_OR_PULL% L4Ph stable-diffusion-webui-localization-ja_JP main d639f8ca6d635686806bebfc8fb6efbe9a71e636
if %ERRORLEVEL% neq 0 ( popd & exit /b 1 )

popd rem %~dp0..\..\stable-diffusion-webui-reForge\extensions
exit /b 0

:MOVE_TO_BACKUP
set "SRC_DIR=%1"
if not exist %SRC_DIR% ( exit /b 0 )

if not exist ..\extensions-backup\ (
	echo mkdir ..\extensions-backup
	mkdir ..\extensions-backup
)

set "DST_DIR=..\extensions-backup\%~nx1"
if exist %DST_DIR%\ (
	echo rmdir /S /Q %DST_DIR%
    rmdir /S /Q %DST_DIR%
)

echo move /Y %SRC_DIR% %DST_DIR%
move /Y %SRC_DIR% %DST_DIR%

exit /b 0
