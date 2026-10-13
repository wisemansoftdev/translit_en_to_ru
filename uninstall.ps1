# Removes Translit RU: stops it, removes the Startup shortcut and the
# %LOCALAPPDATA%\TranslitRU folder. AutoHotkey itself is left installed
# (remove it from Settings > Apps if you don't need it for anything else).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:LOCALAPPDATA 'TranslitRU'
$link = Join-Path ([Environment]::GetFolderPath('Startup')) 'Translit RU.lnk'

$running = Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" |
    Where-Object { $_.CommandLine -like '*TranslitRU.ahk*' }
foreach ($p in $running) {
    try { Stop-Process -Id $p.ProcessId -Force }
    catch { Write-Warning "Couldn't stop Translit RU (process $($p.ProcessId)) - if you used 'Run as administrator', right-click its tray icon > Exit." }
}
Start-Sleep -Milliseconds 500

if (Test-Path $link) { Remove-Item -Force $link; Write-Host "Removed $link" }
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest; Write-Host "Removed $dest" }
Write-Host "Translit RU is uninstalled."
