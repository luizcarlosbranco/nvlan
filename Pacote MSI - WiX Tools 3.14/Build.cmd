@echo off
goto inicio

:erro
echo.
echo Erro
goto fim

:inicio

set WIX=C:\Program Files (x86)\WiX Toolset v3.14\bin

if not exist obj mkdir obj
if not exist bin mkdir bin

echo.
echo ======================================
echo Limpando arquivos antigos
echo ======================================
del /Q obj\*.wixobj >nul 2>&1

echo.
echo ======================================
echo Compilando arquivos WiX
echo ======================================
REM "%WIX%\candle.exe" -ext WixUIExtension Product.wxs CNTUI.wxs LicenseDlg.wxs WelcomeEulaDlg.wxs -out obj\
"%WIX%\candle.exe" -ext WixUIExtension *.wxs -out obj\

if errorlevel 1 goto erro

echo.
echo ======================================
echo Gerando MSI
echo ======================================
REM "%WIX%\light.exe" obj\Product.wixobj obj\CNTUI.wixobj obj\LicenseDlg.wixobj obj\WelcomeEulaDlg.wixobj -ext WixUIExtension -out bin\CNTClient.msi
"%WIX%\light.exe" obj\*.wixobj -ext WixUIExtension -out bin\CNTClient.msi

if errorlevel 1 goto erro


echo.
echo MSI criado com sucesso
goto fim


:fim
pause