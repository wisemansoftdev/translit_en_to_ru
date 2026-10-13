# Installs Translit RU for the current user:
#   - makes sure AutoHotkey v2 is installed (offers to install it with winget)
#   - copies the script + icons to %LOCALAPPDATA%\TranslitRU
#   - adds a shortcut to your Startup folder so it starts at login
#   - starts it now
# Run via install.cmd (double-click), or:
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest    = Join-Path $env:LOCALAPPDATA 'TranslitRU'
$files   = 'TranslitRU.ahk', 'translit-on.ico', 'translit-off.ico'
$startup = [Environment]::GetFolderPath('Startup')
$link    = Join-Path $startup 'Translit RU.lnk'

function Find-AutoHotkeyV2 {
    $candidates = @()
    foreach ($key in 'HKCU:\SOFTWARE\AutoHotkey', 'HKLM:\SOFTWARE\AutoHotkey') {
        $dir = (Get-ItemProperty -Path $key -Name InstallDir -ErrorAction SilentlyContinue).InstallDir
        if ($dir) { $candidates += (Join-Path $dir 'v2\AutoHotkey64.exe'), (Join-Path $dir 'v2\AutoHotkey32.exe') }
    }
    $candidates += "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
                   "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
    return $null
}

foreach ($f in $files) {
    if (-not (Test-Path (Join-Path $here $f))) { throw "Can't find '$f' next to this installer ($here)." }
}

$ahk = Find-AutoHotkeyV2
if (-not $ahk) {
    Write-Host "AutoHotkey v2 is not installed. Translit RU needs it (free, https://www.autohotkey.com)."
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget isn't available. Install AutoHotkey v2 from https://www.autohotkey.com, then run this installer again."
    }
    $answer = Read-Host "Install AutoHotkey v2 now with winget? This accepts its package agreements. [Y/n]"
    if ($answer -and $answer -notmatch '^[Yy]') { throw "Cancelled. Install AutoHotkey v2, then run this installer again." }
    winget install -e --id AutoHotkey.AutoHotkey --accept-package-agreements --accept-source-agreements
    $ahk = Find-AutoHotkeyV2
    if (-not $ahk) { throw "AutoHotkey v2 still not found after installing. Install it from https://www.autohotkey.com and run this again." }
}
Write-Host "Using AutoHotkey: $ahk"

# Stop a running copy (so the files can be replaced)
Get-CimInstance Win32_Process -Filter "Name LIKE 'AutoHotkey%'" |
    Where-Object { $_.CommandLine -like '*TranslitRU.ahk*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force -Path $dest | Out-Null
foreach ($f in $files) {
    Copy-Item -Force (Join-Path $here $f) (Join-Path $dest $f)
    Unblock-File (Join-Path $dest $f)
}
$script = Join-Path $dest 'TranslitRU.ahk'

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($link)
$lnk.TargetPath       = $ahk
$lnk.Arguments        = "`"$script`""
$lnk.WorkingDirectory = $dest
$lnk.IconLocation     = (Join-Path $dest 'translit-on.ico')
$lnk.Description      = 'Translit RU'
$lnk.Save()

Start-Process -FilePath $ahk -ArgumentList "`"$script`"" -WorkingDirectory $dest

Write-Host ""
Write-Host "Installed to $dest and started. It will also start automatically when you log in."
Write-Host "Look for the blue 'RU' icon in the taskbar tray (it may be hidden under the ^ arrow)."
Write-Host "  Ctrl+Alt+T or a left-click on the icon turns it on/off (grey icon = off)."
Write-Host "  Right-click the icon for the rules, 'Run as administrator', and Exit."
