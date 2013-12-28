ml /c /coff /nologo nyserv.asm
if errorlevel==1 goto err
rem rc nyserv.rc
rem if errorlevel==1 goto err
link /subsystem:windows /nologo nyserv.obj nyserv.res
if errorlevel==1 goto err
goto end
:err
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
:end