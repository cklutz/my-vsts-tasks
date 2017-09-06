@echo off
setlocal

call:exec npm install || exit /b 1
call:exec node make.js bump || exit /b 1
call:exec npm run build || exit /b 1
call:exec npm test || exit /b 1
call:exec node make.js package || exit /b 1
exit /b 0

:exec
    echo.======================================================================
    echo.    %*
    echo.======================================================================
    %* || exit /b 1
    goto:EOF