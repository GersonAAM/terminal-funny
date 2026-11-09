@echo off
:: ============================================================
::  Colores de terminal para Windows Terminal
::  - Simbolo del sistema (CMD) -> "Lista 1 Lima"
::  - Windows PowerShell        -> "Lista 2 Bosque"
::
::  Uso: doble clic en este archivo y reabre Windows Terminal.
::  Se guarda una copia de seguridad: settings.json.bak
:: ============================================================
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-Content -LiteralPath $env:SELF -Raw -Encoding UTF8; Invoke-Expression ($c -split '#PS_START#')[-1]"
echo.
pause
exit /b

#PS_START#
$ErrorActionPreference = 'Stop'

$schemes = @(
    [ordered]@{
        name = 'Lista 1 Lima'
        background = '#82837E'; foreground = '#E0E0E0'; cursorColor = '#BFFA37'; selectionBackground = '#94B053'
        black = '#4A4B47'; red = '#E06C5A'; green = '#94B053'; yellow = '#BDEB07'
        blue = '#6E8FA8'; purple = '#A88BB0'; cyan = '#7FC8B0'; white = '#E0E0E0'
        brightBlack = '#5E5F5A'; brightRed = '#FF8A75'; brightGreen = '#BFFA37'; brightYellow = '#DFFF5A'
        brightBlue = '#8FB0C8'; brightPurple = '#C8A8D0'; brightCyan = '#A0E8D0'; brightWhite = '#FFFFFF'
    },
    [ordered]@{
        name = 'Lista 2 Bosque'
        background = '#091C1A'; foreground = '#F0DEBB'; cursorColor = '#59A87D'; selectionBackground = '#16453F'
        black = '#091C1A'; red = '#8E2A50'; green = '#59A87D'; yellow = '#D9B86C'
        blue = '#3E8A80'; purple = '#7A2E4D'; cyan = '#4FA39A'; white = '#F0DEBB'
        brightBlack = '#16453F'; brightRed = '#C24A6E'; brightGreen = '#7FCB9F'; brightYellow = '#F5E6C8'
        brightBlue = '#5FB0A5'; brightPurple = '#A04670'; brightCyan = '#7FD0C4'; brightWhite = '#FFF6E3'
    }
)

# Busca el settings.json de Windows Terminal (Store, Preview o instalacion sin Store)
$candidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$found = @($candidates | Where-Object { Test-Path -LiteralPath $_ })
if ($found.Count -eq 0) {
    Write-Host 'No se encontro Windows Terminal. Instalalo y abrelo una vez, luego vuelve a ejecutar este archivo.' -ForegroundColor Red
    return
}

foreach ($path in $found) {
    try {
        Copy-Item -LiteralPath $path "$path.bak" -Force

        # Quita comentarios de linea completa (settings.json admite // comentarios)
        $raw = (Get-Content -LiteralPath $path -Raw -Encoding UTF8) -replace '(?m)^\s*//.*$', ''
        $json = $raw | ConvertFrom-Json

        # Reemplaza los esquemas con el mismo nombre y agrega los nuevos
        $names = $schemes | ForEach-Object { $_.name }
        $kept = @()
        if ($json.PSObject.Properties['schemes']) { $kept = @($json.schemes | Where-Object { $names -notcontains $_.name }) }
        $json | Add-Member -NotePropertyName schemes -NotePropertyValue @($kept + ($schemes | ForEach-Object { [pscustomobject]$_ })) -Force

        # Asigna cada esquema a su perfil
        $profiles = if ($json.profiles -is [array]) { $json.profiles } else { $json.profiles.list }
        foreach ($p in $profiles) {
            $cmdline = "$($p.commandline)"
            if ($p.guid -eq '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}' -or $cmdline -match 'cmd\.exe') {
                $p | Add-Member -NotePropertyName colorScheme -NotePropertyValue 'Lista 1 Lima' -Force
                Write-Host "  $($p.name) -> Lista 1 Lima" -ForegroundColor Green
            }
            elseif ($p.guid -eq '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}' -or $cmdline -match 'WindowsPowerShell') {
                $p | Add-Member -NotePropertyName colorScheme -NotePropertyValue 'Lista 2 Bosque' -Force
                Write-Host "  $($p.name) -> Lista 2 Bosque" -ForegroundColor Green
            }
        }

        $out = $json | ConvertTo-Json -Depth 32
        [IO.File]::WriteAllText($path, $out, (New-Object Text.UTF8Encoding $false))
        Write-Host "Listo: $path" -ForegroundColor Cyan
        Write-Host "Copia de seguridad: $path.bak"
    }
    catch {
        Write-Host "Error con $path : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Tu configuracion no se modifico.'
    }
}
Write-Host ''
Write-Host 'Abre una pestana nueva de Windows Terminal para ver los colores.'
