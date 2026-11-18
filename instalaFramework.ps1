#requires -version 5.1
<#
.SYNOPSIS
    Instala los runtimes habituales para un puesto Windows 11 empresarial.

.DESCRIPTION
    Instala:
      - Microsoft Visual C++ Redistributable 2015-2022 x64
      - Microsoft Visual C++ Redistributable 2015-2022 x86
      - .NET Desktop Runtime 10
      - .NET Desktop Runtime 8

    Opcionalmente puede habilitar .NET Framework 3.5 con:
      .\instalar-runtimes-windows11.ps1 -IncludeNetFx35

    Notas:
      - .NET Framework 4.8.1 ya forma parte de Windows 11 moderno.
      - El runtime base de Visual Basic 6 sigue incluido/soportado por Windows;
        no se instala un paquete VB6 independiente.
      - El script no instala SDKs ni Visual Studio.
#>

param(
    [switch]$IncludeNetFx35
)

$ErrorActionPreference = "Stop"

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id,

        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan

    # Si ya está instalado, winget intentará actualizarlo si procede.
    $args = @(
        "install",
        "--id", $Id,
        "--exact",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    $process = Start-Process -FilePath "winget.exe" `
        -ArgumentList $args `
        -Wait `
        -PassThru `
        -NoNewWindow

    # 0 = correcto.
    # Winget puede devolver códigos distintos cuando el paquete ya está instalado
    # o no necesita cambios; en ese caso comprobamos posteriormente con winget list.
    if ($process.ExitCode -ne 0) {
        Write-Warning "winget devolvió el código $($process.ExitCode) para $Name. Comprobando instalación..."
    }

    $installed = & winget list --id $Id --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $installed -match [regex]::Escape($Id)) {
        Write-Host "OK: $Name instalado." -ForegroundColor Green
    }
    else {
        throw "No se ha podido confirmar la instalación de $Name ($Id)."
    }
}

Write-Host "===================================================" -ForegroundColor DarkCyan
Write-Host " Instalación de runtimes para Windows 11" -ForegroundColor White
Write-Host "===================================================" -ForegroundColor DarkCyan

if (-not (Test-Administrator)) {
    Write-Host ""
    Write-Host "Este script debe ejecutarse como Administrador." -ForegroundColor Yellow
    Write-Host "Abre PowerShell como Administrador y ejecútalo de nuevo."
    exit 1
}

if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ERROR: winget no está disponible." -ForegroundColor Red
    Write-Host "Instala/actualiza 'App Installer' de Microsoft y vuelve a ejecutar el script."
    exit 1
}

Write-Host ""
Write-Host "Actualizando fuentes de winget..."
& winget source update | Out-Host

$packages = @(
    @{
        Id   = "Microsoft.VCRedist.2015+.x64"
        Name = "Microsoft Visual C++ Redistributable 2015-2022 x64"
    },
    @{
        Id   = "Microsoft.VCRedist.2015+.x86"
        Name = "Microsoft Visual C++ Redistributable 2015-2022 x86"
    },
    @{
        Id   = "Microsoft.DotNet.DesktopRuntime.10"
        Name = ".NET Desktop Runtime 10"
    },
    @{
        Id   = "Microsoft.DotNet.DesktopRuntime.8"
        Name = ".NET Desktop Runtime 8"
    }
)

foreach ($package in $packages) {
    Install-WingetPackage -Id $package.Id -Name $package.Name
}

if ($IncludeNetFx35) {
    Write-Host ""
    Write-Host "==> Habilitando .NET Framework 3.5 (NetFx3)" -ForegroundColor Cyan

    $feature = Get-WindowsOptionalFeature -Online -FeatureName NetFx3

    if ($feature.State -eq "Enabled") {
        Write-Host "OK: .NET Framework 3.5 ya estaba habilitado." -ForegroundColor Green
    }
    else {
        Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName NetFx3 `
            -All `
            -NoRestart | Out-Host

        Write-Host "OK: .NET Framework 3.5 habilitado." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor DarkCyan
Write-Host " Instalación terminada" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "Instalado/comprobado:"
Write-Host "  - Visual C++ 2015-2022 x64"
Write-Host "  - Visual C++ 2015-2022 x86"
Write-Host "  - .NET Desktop Runtime 10"
Write-Host "  - .NET Desktop Runtime 8"

if ($IncludeNetFx35) {
    Write-Host "  - .NET Framework 3.5"
}
else {
    Write-Host ""
    Write-Host ".NET Framework 3.5 NO se ha habilitado."
    Write-Host "Si una aplicación antigua lo necesita, ejecuta:"
    Write-Host "  .\instalar-runtimes-windows11.ps1 -IncludeNetFx35" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "No es necesario instalar un runtime VB6 separado para las aplicaciones VB6 normales."
Write-Host "Recomiendo reiniciar Windows después de terminar."
