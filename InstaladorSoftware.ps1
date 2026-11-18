#requires -Version 5.1
<#
 Instalador de software para Windows 11 (PowerShell + Windows Forms)
 Ejecutar con Windows PowerShell 5.1, en modo administrador y STA:
 powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\InstaladorSoftware.ps1

 El catalogo es editable en $Catalogo. Requiere winget para los paquetes externos.
 No elude UAC ni sustituye las credenciales de administrador.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Comprueba privilegios antes de continuar.
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show(
        'Ejecuta este archivo con Windows PowerShell como administrador. La instalacion no puede elevar privilegios por si sola.',
        'Se requieren permisos de administrador',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    return
}

# Catalogo. Id debe coincidir con el ID de Winget, salvo las funciones opcionales de Windows.
$Catalogo = @(
    [pscustomobject]@{ Nombre='Google Chrome'; Categoria='Ofimatica'; Id='Google.Chrome'; Perfil=@('Basico'); Especial='' ; Patron='Google Chrome' }
    [pscustomobject]@{ Nombre='AutoFirma'; Categoria='Ofimatica'; Id='SpanishGovernment.Autofirma'; Perfil=@('Basico'); Especial='' ; Patron='AutoFirma' }
    [pscustomobject]@{ Nombre='WinRAR'; Categoria='Utilidades'; Id='RARLab.WinRAR'; Perfil=@('Basico'); Especial='' ; Patron='WinRAR' }
    [pscustomobject]@{ Nombre='Adobe Acrobat Reader 64-bit'; Categoria='Ofimatica'; Id='Adobe.Acrobat.Reader.64-bit'; Perfil=@('Basico'); Especial='' ; Patron='Adobe Acrobat|Acrobat Reader' }
    [pscustomobject]@{ Nombre='LibreOffice'; Categoria='Ofimatica'; Id='TheDocumentFoundation.LibreOffice'; Perfil=@('Basico'); Especial='' ; Patron='LibreOffice' }
    [pscustomobject]@{ Nombre='PDF24 Creator'; Categoria='Ofimatica'; Id='geeksoftwareGmbH.PDF24Creator'; Perfil=@('Basico'); Especial='' ; Patron='PDF24 Creator' }
    [pscustomobject]@{ Nombre='GIMP'; Categoria='Multimedia'; Id='GIMP.GIMP'; Perfil=@('Basico'); Especial='' ; Patron='GIMP' }
    [pscustomobject]@{ Nombre='VLC'; Categoria='Multimedia'; Id='VideoLAN.VLC'; Perfil=@('Basico'); Especial='' ; Patron='VLC media player' }
    [pscustomobject]@{ Nombre='7-Zip'; Categoria='Utilidades'; Id='7zip.7zip'; Perfil=@('Basico'); Especial='' ; Patron='7-Zip' }
    [pscustomobject]@{ Nombre='Notepad++'; Categoria='Utilidades'; Id='Notepad++.Notepad++'; Perfil=@('Basico','Administracion','Desarrollo'); Especial='' ; Patron='Notepad\+\+' }
    [pscustomobject]@{ Nombre='PowerToys'; Categoria='Utilidades'; Id='Microsoft.PowerToys'; Perfil=@('Basico'); Especial='' ; Patron='PowerToys' }
    [pscustomobject]@{ Nombre='Everything'; Categoria='Utilidades'; Id='voidtools.Everything'; Perfil=@('Basico'); Especial='' ; Patron='Everything' }
    [pscustomobject]@{ Nombre='Windows Terminal'; Categoria='Utilidades'; Id='Microsoft.WindowsTerminal'; Perfil=@('Administracion','Desarrollo'); Especial='' ; Patron='Windows Terminal' }
    [pscustomobject]@{ Nombre='PowerShell 7'; Categoria='Administracion'; Id='Microsoft.PowerShell'; Perfil=@('Administracion','Desarrollo'); Especial='' ; Patron='PowerShell 7' }
    [pscustomobject]@{ Nombre='Sysinternals Suite'; Categoria='Administracion'; Id='Microsoft.Sysinternals.Suite'; Perfil=@('Administracion'); Especial='' ; Patron='Sysinternals' }
    [pscustomobject]@{ Nombre='OpenSSH Server'; Categoria='Administracion'; Id='WINDOWS_OPENSSH'; Perfil=@('Administracion'); Especial='OpenSSH'; Patron='' }
    [pscustomobject]@{ Nombre='PuTTY'; Categoria='Administracion'; Id='PuTTY.PuTTY'; Perfil=@('Administracion'); Especial='' ; Patron='PuTTY' }
    [pscustomobject]@{ Nombre='WinSCP'; Categoria='Administracion'; Id='WinSCP.WinSCP'; Perfil=@('Administracion'); Especial='' ; Patron='WinSCP' }
    [pscustomobject]@{ Nombre='Wireshark'; Categoria='Administracion'; Id='WiresharkFoundation.Wireshark'; Perfil=@('Administracion'); Especial='' ; Patron='Wireshark' }
    [pscustomobject]@{ Nombre='RustDesk'; Categoria='Administracion'; Id='RustDesk.RustDesk'; Perfil=@('Administracion'); Especial='' ; Patron='RustDesk' }
    [pscustomobject]@{ Nombre='Rufus'; Categoria='Administracion'; Id='Rufus.Rufus'; Perfil=@('Administracion'); Especial='' ; Patron='Rufus' }
    [pscustomobject]@{ Nombre='Visual Studio Code'; Categoria='Desarrollo'; Id='Microsoft.VisualStudioCode'; Perfil=@('Desarrollo'); Especial='' ; Patron='Visual Studio Code|Microsoft Visual Studio Code' }
    [pscustomobject]@{ Nombre='Git'; Categoria='Desarrollo'; Id='Git.Git'; Perfil=@('Desarrollo'); Especial='' ; Patron='^Git($|\s)' }
    [pscustomobject]@{ Nombre='.NET SDK 10'; Categoria='Desarrollo'; Id='Microsoft.DotNet.SDK.10'; Perfil=@('Desarrollo'); Especial='' ; Patron='Microsoft \.NET SDK 10|Microsoft \.NET SDK - 10' }
    [pscustomobject]@{ Nombre='DBeaver Community'; Categoria='Desarrollo'; Id='DBeaver.DBeaver.Community'; Perfil=@('Desarrollo'); Especial='' ; Patron='DBeaver' }
    [pscustomobject]@{ Nombre='Postman'; Categoria='Desarrollo'; Id='Postman.Postman'; Perfil=@('Desarrollo'); Especial='' ; Patron='Postman' }
    [pscustomobject]@{ Nombre='Microsoft Visual C++ Redistributable 2015-2022 x64'; Categoria='Frameworks'; Id='Microsoft.VCRedist.2015+.x64'; Perfil=@(); Especial='' ; Patron='Microsoft Visual C\+\+.*2015.*2022.*(x64|64-bit)' }
    [pscustomobject]@{ Nombre='Microsoft Visual C++ Redistributable 2015-2022 x86'; Categoria='Frameworks'; Id='Microsoft.VCRedist.2015+.x86'; Perfil=@(); Especial='' ; Patron='Microsoft Visual C\+\+.*2015.*2022.*(x86|32-bit)' }
    [pscustomobject]@{ Nombre='.NET Desktop Runtime 10'; Categoria='Frameworks'; Id='Microsoft.DotNet.DesktopRuntime.10'; Perfil=@(); Especial='' ; Patron='Microsoft (Windows|\.NET) Desktop Runtime -? 10' }
    [pscustomobject]@{ Nombre='.NET Desktop Runtime 8'; Categoria='Frameworks'; Id='Microsoft.DotNet.DesktopRuntime.8'; Perfil=@(); Especial='' ; Patron='Microsoft (Windows|\.NET) Desktop Runtime -? 8' }
    [pscustomobject]@{ Nombre='.NET Framework 3.5 (NetFx3)'; Categoria='Frameworks'; Id='WINDOWS_NETFX3'; Perfil=@(); Especial='NetFx35'; Patron='' }
)

$RutaLogs = Join-Path $env:ProgramData 'InstaladorSoftware\Logs'
New-Item -Path $RutaLogs -ItemType Directory -Force | Out-Null
$Sello = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogGeneral = Join-Path $RutaLogs "Instalacion_$Sello.log"
$WingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
$WingetExe = if ($WingetCmd) { $WingetCmd.Source } else { $null }

function Escribir-Log([string]$Mensaje) {
    $linea = ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Mensaje)
    Add-Content -LiteralPath $LogGeneral -Value $linea -Encoding UTF8
}

function Actualizar-Winget {
    $comando = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $comando) {
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
        } catch {
            Escribir-Log "No se pudo registrar App Installer: $($_.Exception.Message)"
        }
        $comando = Get-Command winget.exe -ErrorAction SilentlyContinue
    }

    $script:WingetExe = if ($comando) { $comando.Source } else { $null }
    return [bool]$script:WingetExe
}

Actualizar-Winget | Out-Null

function Obtener-Instalados {
    $ids = @{}
    $nombres = @()

    # Una sola consulta de Winget para todas las aplicaciones (sin invocar Winget por programa).
    if ($WingetExe) {
        try {
            $salida = (& $WingetExe list --source winget --accept-source-agreements 2>&1 | Out-String)
            foreach ($app in $Catalogo) {
                if ($app.Especial) { continue }
                $patronId = '(?<!\S)' + [regex]::Escape($app.Id) + '(?!\S)'
                if ($salida -match $patronId) { $ids[$app.Id] = $true }
            }
        } catch {
            Escribir-Log "ADVERTENCIA al consultar winget list: $($_.Exception.Message)"
        }
    }

    # Complementa la deteccion de instalaciones no reconocidas por Winget.
    foreach ($rama in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )) {
        try {
            $nombres += @(Get-ItemProperty -Path $rama -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } | ForEach-Object { [string]$_.DisplayName })
        } catch { }
    }

    foreach ($app in $Catalogo) {
        $app | Add-Member -NotePropertyName Instalado -NotePropertyValue $false -Force
        if ($app.Especial -eq 'OpenSSH') {
            try {
                $cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' -ErrorAction Stop
                $app.Instalado = ($cap.State -eq 'Installed')
            } catch { Escribir-Log "ADVERTENCIA al detectar OpenSSH: $($_.Exception.Message)" }
        } elseif ($app.Especial -eq 'NetFx35') {
            try {
                $feature = Get-WindowsOptionalFeature -Online -FeatureName NetFx3 -ErrorAction Stop
                $app.Instalado = ($feature.State -eq 'Enabled')
            } catch { Escribir-Log "ADVERTENCIA al detectar .NET Framework 3.5: $($_.Exception.Message)" }
        } elseif ($ids.ContainsKey($app.Id)) {
            $app.Instalado = $true
        } elseif ($app.Patron) {
            foreach ($nombre in $nombres) {
                if ($nombre -match $app.Patron) { $app.Instalado = $true; break }
            }
        }
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Instalador de software - Windows 11'
$form.ClientSize = New-Object System.Drawing.Size(850, 665)
$form.MinimumSize = New-Object System.Drawing.Size(760, 600)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = 'Selecciona las aplicaciones que deseas instalar'
$lblTitulo.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
$lblTitulo.SetBounds(18, 12, 790, 30)
$form.Controls.Add($lblTitulo)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = 'Los programas ya instalados apareceran marcados como [INSTALADO].'
$lblInfo.SetBounds(20, 48, 800, 25)
$form.Controls.Add($lblInfo)

$panelSuperior = New-Object System.Windows.Forms.FlowLayoutPanel
$panelSuperior.SetBounds(16, 80, 810, 37)
$panelSuperior.Anchor = 'Top,Left,Right'
$form.Controls.Add($panelSuperior)

$btnTodos = New-Object System.Windows.Forms.Button
$btnTodos.Text = 'Seleccionar todo'
$btnTodos.Size = New-Object System.Drawing.Size(120, 30)
$panelSuperior.Controls.Add($btnTodos)

$btnNinguno = New-Object System.Windows.Forms.Button
$btnNinguno.Text = 'Limpiar seleccion'
$btnNinguno.Size = New-Object System.Drawing.Size(120, 30)
$panelSuperior.Controls.Add($btnNinguno)

$btnWinget = New-Object System.Windows.Forms.Button
$btnWinget.Text = 'Instalar winget'
$btnWinget.Size = New-Object System.Drawing.Size(130, 30)
$btnWinget.Visible = -not $WingetExe
$panelSuperior.Controls.Add($btnWinget)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.SetBounds(18, 125, 813, 337)
$tabs.Anchor = 'Top,Bottom,Left,Right'
$form.Controls.Add($tabs)

$Listas = @{}
$Categorias = @('Ofimatica','Multimedia','Utilidades','Administracion','Desarrollo','Frameworks')
foreach ($categoria in $Categorias) {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = $categoria
    $tabs.TabPages.Add($tab)

    $lista = New-Object System.Windows.Forms.CheckedListBox
    $lista.Dock = 'Fill'
    $lista.CheckOnClick = $true
    $lista.IntegralHeight = $false
    $lista.HorizontalScrollbar = $true
    $lista.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $tab.Controls.Add($lista)
    $Listas[$categoria] = $lista
}

$lblSeleccion = New-Object System.Windows.Forms.Label
$lblSeleccion.SetBounds(20, 468, 700, 22)
$lblSeleccion.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($lblSeleccion)

$progreso = New-Object System.Windows.Forms.ProgressBar
$progreso.SetBounds(20, 497, 808, 24)
$progreso.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($progreso)

$lblEstado = New-Object System.Windows.Forms.Label
$lblEstado.Text = 'Preparado.'
$lblEstado.SetBounds(20, 530, 805, 40)
$lblEstado.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($lblEstado)

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text = 'Instalar seleccionados'
$btnInstalar.SetBounds(20, 587, 205, 36)
$btnInstalar.Anchor = 'Bottom,Left'
$form.Controls.Add($btnInstalar)

$btnActualizar = New-Object System.Windows.Forms.Button
$btnActualizar.Text = 'Actualizar deteccion'
$btnActualizar.SetBounds(235, 587, 165, 36)
$btnActualizar.Anchor = 'Bottom,Left'
$form.Controls.Add($btnActualizar)

$btnLogs = New-Object System.Windows.Forms.Button
$btnLogs.Text = 'Abrir carpeta de logs'
$btnLogs.SetBounds(410, 587, 165, 36)
$btnLogs.Anchor = 'Bottom,Left'
$form.Controls.Add($btnLogs)

$btnCerrar = New-Object System.Windows.Forms.Button
$btnCerrar.Text = 'Cerrar'
$btnCerrar.SetBounds(690, 587, 135, 36)
$btnCerrar.Anchor = 'Bottom,Right'
$form.Controls.Add($btnCerrar)

# Las listas contienen objetos (no texto), lo que preserva el identificador al marcar.
function Repintar-Listas {
    foreach ($categoria in $Categorias) {
        $lista = $Listas[$categoria]
        $seleccionados = @{}
        foreach ($item in $lista.CheckedItems) { $seleccionados[$item.Id] = $true }
        $lista.Items.Clear()
        foreach ($app in ($Catalogo | Where-Object Categoria -eq $categoria)) {
            $etiqueta = if ($app.Instalado) { "$($app.Nombre)    [INSTALADO]" } else { $app.Nombre }
            $elemento = [pscustomobject]@{ Nombre=$etiqueta; Id=$app.Id; App=$app }
            $indice = $lista.Items.Add($elemento)
            if ($seleccionados.ContainsKey($app.Id)) { $lista.SetItemChecked($indice, $true) }
        }
        $lista.DisplayMember = 'Nombre'
    }
    Actualizar-Contador
}

function Obtener-Seleccionados {
    $eleccion = @()
    foreach ($categoria in $Categorias) {
        foreach ($item in $Listas[$categoria].CheckedItems) { $eleccion += $item.App }
    }
    return $eleccion
}

function Actualizar-Contador {
    $seleccionados = @(Obtener-Seleccionados)
    $pendientes = @($seleccionados | Where-Object { -not $_.Instalado })
    $lblSeleccion.Text = "Seleccionados: $($seleccionados.Count) | Sin instalar: $($pendientes.Count) | Total catalogo: $($Catalogo.Count)"
}

function Marcar-Todos([bool]$Seleccionar) {
    foreach ($categoria in $Categorias) {
        $lista = $Listas[$categoria]
        for ($i = 0; $i -lt $lista.Items.Count; $i++) {
            $lista.SetItemChecked($i, ($Seleccionar -and -not $lista.Items[$i].App.Instalado))
        }
    }
    Actualizar-Contador
}

$script:Cola = New-Object 'System.Collections.Generic.Queue[object]'
$script:EnCurso = $false
$script:ProcesoActual = $null
$script:AppActual = $null
$script:IndiceActual = 0
$script:TotalTrabajos = 0
$script:Fallos = New-Object 'System.Collections.Generic.List[string]'
$script:SalidaActual = ''
$script:ErrorActual = ''

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 550

function Habilitar-Controles([bool]$Habilitar) {
    foreach ($btn in @($btnTodos,$btnNinguno,$btnWinget,$btnInstalar,$btnActualizar,$btnCerrar)) {
        $btn.Enabled = $Habilitar
    }
    $tabs.Enabled = $Habilitar
}

function Lanzar-Siguiente {
    if ($script:Cola.Count -eq 0) {
        $timer.Stop()
        $script:EnCurso = $false
        Habilitar-Controles $true
        $lblEstado.Text = "Finalizado. Correctos: $($script:TotalTrabajos - $script:Fallos.Count). Errores: $($script:Fallos.Count)."
        Escribir-Log $lblEstado.Text
        [System.Windows.Forms.MessageBox]::Show(
            "Instalacion terminada.`r`nErrores: $($script:Fallos.Count)`r`nLog: $LogGeneral",
            'Resultado', 'OK',
            $(if ($script:Fallos.Count -eq 0) { 'Information' } else { 'Warning' })
        ) | Out-Null
        return
    }

    $script:AppActual = $script:Cola.Dequeue()
    $script:IndiceActual++
    $lblEstado.Text = "[$($script:IndiceActual)/$($script:TotalTrabajos)] Instalando $($script:AppActual.Nombre)..."
    Escribir-Log "INICIO: $($script:AppActual.Nombre) [$($script:AppActual.Id)]"

    $nombreFichero = ($script:AppActual.Id -replace '[^a-zA-Z0-9_.-]', '_')
    $prefijo = Join-Path $RutaLogs "${Sello}_${script:IndiceActual}_${nombreFichero}"
    $script:SalidaActual = "${prefijo}.stdout.log"
    $script:ErrorActual = "${prefijo}.stderr.log"

    try {
        if ($script:AppActual.Especial -eq 'OpenSSH') {
            $comando = @'
$ErrorActionPreference = 'Stop'
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
if ($cap.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Host
}
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd
$rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if ($rule) {
    Enable-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
} else {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (TCP 22)' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow | Out-Null
}
'@
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($comando)
            $encoded = [Convert]::ToBase64String($bytes)
            $ejecutable = (Join-Path $PSHOME 'powershell.exe')
            $argumentos = "-NoProfile -NonInteractive -EncodedCommand $encoded"
        } elseif ($script:AppActual.Especial -eq 'NetFx35') {
            $comando = @'
$ErrorActionPreference = 'Stop'
$feature = Get-WindowsOptionalFeature -Online -FeatureName NetFx3
if ($feature.State -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart | Out-Host
}
'@
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($comando)
            $encoded = [Convert]::ToBase64String($bytes)
            $ejecutable = (Join-Path $PSHOME 'powershell.exe')
            $argumentos = "-NoProfile -NonInteractive -EncodedCommand $encoded"
        }
        else {
            if (-not $WingetExe) { throw 'Winget no esta disponible en esta sesion.' }
            $ejecutable = $WingetExe
            $argumentos = "install --id $($script:AppActual.Id) --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
        }

        $script:ProcesoActual = Start-Process -FilePath $ejecutable -ArgumentList $argumentos `
            -RedirectStandardOutput $script:SalidaActual -RedirectStandardError $script:ErrorActual `
            -WindowStyle Hidden -PassThru -ErrorAction Stop
    }
    catch {
        $mensaje = "$($script:AppActual.Nombre): $($_.Exception.Message)"
        $script:Fallos.Add($mensaje)
        Escribir-Log "ERROR: $mensaje"
        $progreso.Value = $script:IndiceActual
        Lanzar-Siguiente
    }
}

$timer.Add_Tick({
    if (-not $script:EnCurso -or $null -eq $script:ProcesoActual) { return }
    try {
        $script:ProcesoActual.Refresh()
        if (-not $script:ProcesoActual.HasExited) { return }
        $codigo = $script:ProcesoActual.ExitCode
        if ($codigo -eq 0) {
            Escribir-Log "OK: $($script:AppActual.Nombre)"
            $script:AppActual.Instalado = $true
        } else {
            $detalle = ''
            if (Test-Path -LiteralPath $script:ErrorActual) {
                $detalle = ((Get-Content -LiteralPath $script:ErrorActual -Tail 4 -ErrorAction SilentlyContinue) -join ' ')
            }
            $mensaje = "$($script:AppActual.Nombre): codigo $codigo. $detalle"
            $script:Fallos.Add($mensaje)
            Escribir-Log "ERROR: $mensaje"
        }
        $script:ProcesoActual.Dispose()
        $script:ProcesoActual = $null
        $progreso.Value = $script:IndiceActual
        Repintar-Listas
        Lanzar-Siguiente
    } catch {
        Escribir-Log "ERROR seguimiento: $($_.Exception.Message)"
        if ($script:ProcesoActual) { $script:ProcesoActual.Dispose(); $script:ProcesoActual = $null }
        $script:Fallos.Add("$($script:AppActual.Nombre): error de seguimiento")
        $progreso.Value = $script:IndiceActual
        Lanzar-Siguiente
    }
})

foreach ($categoria in $Categorias) {
    $Listas[$categoria].Add_ItemCheck({
        $form.BeginInvoke([Action]{ Actualizar-Contador }) | Out-Null
    })
}

$btnTodos.Add_Click({ Marcar-Todos $true })
$btnNinguno.Add_Click({ Marcar-Todos $false })
$btnWinget.Add_Click({
    try {
        Start-Process 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1' -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show(
            'Se ha abierto la ficha oficial de App Installer en Microsoft Store. Instala o actualiza la aplicacion y despues pulsa "Actualizar deteccion".',
            'Instalar winget'
        ) | Out-Null
    } catch {
        Escribir-Log "ERROR al abrir Microsoft Store para instalar App Installer: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo abrir Microsoft Store. Instala App Installer desde https://apps.microsoft.com/detail/9nblggh4nns1.`r`n$($_.Exception.Message)",
            'No se pudo abrir Microsoft Store',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})
$btnActualizar.Add_Click({
    $lblEstado.Text = 'Comprobando aplicaciones instaladas...'
    $form.Refresh()
    $wingetDisponible = Actualizar-Winget
    $btnWinget.Visible = -not $wingetDisponible
    Obtener-Instalados
    Repintar-Listas
    $lblEstado.Text = if ($wingetDisponible) { 'Deteccion actualizada. winget esta disponible.' } else { 'Deteccion actualizada. Instala App Installer para usar winget.' }
})
$btnLogs.Add_Click({ Start-Process explorer.exe -ArgumentList ('"' + $RutaLogs + '"') })
$btnCerrar.Add_Click({ $form.Close() })

$btnInstalar.Add_Click({
    if ($script:EnCurso) { return }
    $seleccionados = @(Obtener-Seleccionados)
    $pendientes = @($seleccionados | Where-Object { -not $_.Instalado })
    if ($pendientes.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('No hay programas pendientes de instalar.', 'Informacion') | Out-Null
        return
    }
    if (-not $WingetExe -and @($pendientes | Where-Object { -not $_.Especial }).Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show('No se encuentra winget.exe. Comprueba que App Installer esta instalado.', 'Winget no disponible') | Out-Null
        return
    }
    $confirmar = [System.Windows.Forms.MessageBox]::Show(
        "Se instalaran $($pendientes.Count) programas. Algunos pueden requerir reinicio o interaccion adicional. ¿Continuar?",
        'Confirmar instalacion', 'YesNo', 'Question'
    )
    if ($confirmar -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $script:Cola.Clear()
    foreach ($app in $pendientes) { $script:Cola.Enqueue($app) }
    $script:Fallos.Clear()
    $script:IndiceActual = 0
    $script:TotalTrabajos = $pendientes.Count
    $script:EnCurso = $true
    $progreso.Minimum = 0
    $progreso.Maximum = $script:TotalTrabajos
    $progreso.Value = 0
    Habilitar-Controles $false
    Escribir-Log "Comienzo de instalacion: $($pendientes.Count) aplicaciones."
    Lanzar-Siguiente
    $timer.Start()
})

$form.Add_FormClosing({
    if ($script:EnCurso) {
        $_.Cancel = $true
        [System.Windows.Forms.MessageBox]::Show('Hay una instalacion en curso. Espera a que termine para cerrar.', 'Instalacion activa') | Out-Null
    }
})

Escribir-Log 'Aplicacion iniciada.'
Obtener-Instalados
Repintar-Listas
if (-not $WingetExe) { $lblEstado.Text = 'AVISO: instala App Installer con el boton "Instalar winget" para usar winget.' }
[void]$form.ShowDialog()
$timer.Dispose()
$form.Dispose()
