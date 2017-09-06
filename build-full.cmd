@echo off
setlocal
set TFX_TRACE=1

call:exec npm install || exit /b 1
call:exec node make.js bump || exit /b 1
call:exec npm run build || exit /b 1
call:exec npm test || exit /b 1
call:exec node make.js package || exit /b 1

if /i ["%~1"] == ["--upload"] (
    for /D %%i in ("%~dp0_build\Tasks\*") do (
        call:exec tfx build tasks upload --task.path "%%~i" || exit /b 1
    )
)

exit /b 0

:exec
    echo.======================================================================
    echo.    %*
    echo.======================================================================
    %* || exit /b 1
    goto:EOF