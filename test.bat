
@echo off
echo Deleting all files in C:\ROX...
del /q "C:\ROX\*.*"

echo Deleting all subfolders in C:\ROX...
for /d %%i in ("C:\ROX\*") do rmdir /s /q "%%i"

echo Cleanup complete.


@REM D:\Work\Installer\prebuilt\binarycreator.exe -c config\config.xml -p packages -r resources/master.qrc SDKInstaller.exe

D:\Work\Installer\installer-framework\build\bin\binarycreator.exe -c config\config.xml -p packages -r resources/master.qrc SDKInstaller.exe
.\SDKInstaller.exe --verbose --debug



