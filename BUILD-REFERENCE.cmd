@echo off
setlocal
py -3 "%~dp0tools\import_reference.py" "%~dp0examples\reference-input\manifest.json" --output "%~dp0output\MSMarketValueReference" --min-samples 1
if errorlevel 1 (
  echo.
  echo Build stopped. Check the message above and docs\WOWHEAD-DATASET.md.
  pause
  exit /b 1
)
echo.
echo Done. Copy output\MSMarketValueReference beside your MSMarketValue addon.
pause
