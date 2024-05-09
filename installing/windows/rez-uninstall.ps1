# global config
$ErrorActionPreference = "Stop"
$SCRIPTNAME = "knots-rez-uninstall"
$INSTALLER_VERSION = "2.0.0"

$LOG_ROOT_PATH = $Env:KNOTS_LOCAL_INSTALL_PATH
$LOG_PATH = $Env:UNINSTALL_LOG_PATH

# we need it to create log files
if (-not (Test-Path -Path $LOG_ROOT_PATH)) {
    Write-Output "creating $LOG_ROOT_PATH"
    New-Item -Type Directory -Path $LOG_ROOT_PATH | Out-Null
}

function Log {
    param ($message, $level, $color)
    $final_message = "$level | $((Get-Date).ToString() ) [knots-install] $message"
    Write-Host "$($level.PadRight(8, ' ') ) | $((Get-Date).ToString() ) [$SCRIPTNAME] $message" -ForegroundColor $color
    Out-File -FilePath $LOG_PATH -Append -InputObject "$final_message"
}
function LogDebug { Log @args "DEBUG" "DarkGray" }
function LogInfo { Log @args "INFO" "White" }
function LogSucess { Log @args "SUCCESS" "Green" }

function Uninstall-All {

    $python_install = "$Env:KNOTS_LOCAL_PYTHON_INSTALL_PATH"
    $rez_install_path = "$Env:KNOTS_LOCAL_REZ_INSTALL_PATH"
    $rez_cache_path = "$Env:REZ_CACHE_PACKAGES_PATH"
    $env_scope = "User"

    # ensure that we are not uninstalling stuff that have never been installed ...
    $installed_version = [System.Environment]::GetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', $env_scope)
    if (-not ($installed_version -eq $INSTALLER_VERSION)) {
        throw "Uninstaller version mismatch: expected $installed_version got $INSTALLER_VERSION"
    }

    Write-Output $( "="*80 )
    Write-Output "[$SCRIPTNAME v$INSTALLER_VERSION] uninstall Rez package manager.`n"

    if (Test-Path -Path $rez_install_path) {
        LogInfo "removing $rez_install_path ..."
        Remove-Item $rez_install_path -Recurse -Force
    }
    if (Test-Path -Path $python_install) {
        LogInfo "removing $python_install ..."
        Remove-Item $python_install -Recurse -Force
    }
    if (Test-Path -Path $rez_cache_path) {
        LogInfo "removing $rez_cache_path ..."
        Remove-Item $rez_cache_path -Recurse -Force
    }

    LogInfo "removing KNOTS_REZ_INSTALLER_VERSION environment variable"
    [Environment]::SetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', "", $env_var_scope)

    Write-Host $( "_"*80 ) -ForegroundColor "green"
    LogSucess "finished uninstalling rez"
    Write-Output $( "="*80 )
}

Uninstall-All