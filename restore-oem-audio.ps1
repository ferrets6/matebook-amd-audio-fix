#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Re-binds the OEM (Huawei) AMD ACP audio drivers after AMD Adrenalin replaced them.
.EXAMPLE
  .\restore-oem-audio.ps1 -ListOnly    # show current and available versions, change nothing
  .\restore-oem-audio.ps1              # force the OEM drivers, then reboot
#>
param(
    [string]$BusVersion = '6.0.0.14',   # amdacpbus.inf  (AMD Audio CoProcessor)
    [string]$AfdVersion = '6.0.0.10',   # amdacpafd.inf  (AMD Audio Device)
    [switch]$ListOnly
)
$ErrorActionPreference = 'Stop'

function Get-DriverVer($inf) {
    ((Select-String -LiteralPath $inf -Pattern '^\s*DriverVer' | Select-Object -First 1).Line -split ',')[-1].Trim()
}

function Find-Package($name) {
    Get-ChildItem "$env:windir\System32\DriverStore\FileRepository" -Directory -Filter "$name*" |
        ForEach-Object { Get-ChildItem $_.FullName -Filter $name } |
        ForEach-Object { [pscustomobject]@{ Version = Get-DriverVer $_.FullName; Inf = $_.FullName } }
}

function Get-AcpDevice($pattern) {
    $dev = Get-PnpDevice -PresentOnly | Where-Object InstanceId -like $pattern | Select-Object -First 1
    if (-not $dev) { throw "No device matching $pattern. This machine does not have an AMD ACP (DEV_15E2) audio device." }
    [pscustomobject]@{
        Name    = $dev.FriendlyName
        HwIds   = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName DEVPKEY_Device_HardwareIds).Data
        Version = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName DEVPKEY_Device_DriverVersion).Data
    }
}

$targets = @(
    @{ Pattern = 'PCI\VEN_1022&DEV_15E2*'; Inf = 'amdacpbus.inf'; Want = $BusVersion },   # parent first
    @{ Pattern = 'ACP\VEN_1022&DEV_15E2*'; Inf = 'amdacpafd.inf'; Want = $AfdVersion }
)

Add-Type -Namespace Native -Name NewDev -MemberDefinition @'
[DllImport("newdev.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool UpdateDriverForPlugAndPlayDevicesW(IntPtr hwnd, string hardwareId, string infPath, uint flags, out bool reboot);
'@

$needReboot = $false
foreach ($t in $targets) {
    $dev  = Get-AcpDevice $t.Pattern
    $pkgs = @(Find-Package $t.Inf)
    Write-Host "`n$($dev.Name)  [$($dev.HwIds[0])]"
    Write-Host "  in use:    $($dev.Version)"
    Write-Host "  available: $(($pkgs.Version | Sort-Object -Unique) -join ', ')"
    if ($ListOnly) { continue }

    if ($dev.Version -eq $t.Want) { Write-Host '  already OEM version, skipping'; continue }
    $pkg = $pkgs | Where-Object Version -eq $t.Want | Select-Object -First 1
    if (-not $pkg) { throw "$($t.Inf) $($t.Want) is not in the driver store. Reinstall it from Huawei PC Manager first." }

    $reboot = $false
    # flag 1 = INSTALLFLAG_FORCE: install even though a newer driver is ranked higher
    if (-not [Native.NewDev]::UpdateDriverForPlugAndPlayDevicesW([IntPtr]::Zero, $dev.HwIds[0], $pkg.Inf, 1, [ref]$reboot)) {
        throw "Install failed: Win32 error 0x{0:X}" -f [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    }
    Write-Host "  installed $($t.Want)" -ForegroundColor Green
    $needReboot = $needReboot -or $reboot
}

if ($needReboot) { Write-Host "`nReboot required." -ForegroundColor Yellow }
