# global config
$ErrorActionPreference = "Stop"
$SCRIPTNAME = "knots-rez-uninstall"

# import configuration
. "$PSScriptRoot\config.ps1"

$LOG_ROOT_PATH = $KnotsInstallConfig.knots_install_path
$LOG_PATH = $KnotsInstallConfig.uninstall_log_path

# we need it to create log files
if (-not(Test-Path -Path $LOG_ROOT_PATH)) {
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

    # ensure that we are not uninstalling stuff that have never been installed ...
    $installed_version = [System.Environment]::GetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', $KnotsInstallConfig.env_var_scope)
    if (-not ($installed_version -eq $INSTALLER_VERSION)){
        throw "Uninstaller version mismatch: expected $installed_version got $INSTALLER_VERSION"
    }

    Write-Output $( "="*80 )
    Write-Output "[$SCRIPTNAME v$INSTALLER_VERSION] uninstall Rez package manager.`n"

    $python_install = $KnotsInstallConfig.python_install
    $rez_install_path = $KnotsInstallConfig.rez_full_install_path
    $rez_scripts_path = $KnotsInstallConfig.rez_scripts
    $rez_cache_path = $KnotsInstallConfig.rez_cache_path
    $env_var_scope = $KnotsInstallConfig.env_var_scope

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

    # unset PATH environment variable if needed
    # there is a probability to fucked up the user PATH variable so we recommend
    # to backup the PATH variable that is echoed.
    $current_path = [System.Environment]::GetEnvironmentVariable('PATH', $env_var_scope)
    $new_path = ($current_path.Split(';') | Where-Object { $_ -ne $rez_scripts_path }) -join ';'
    if ((-not($current_path -eq $new_path)) -and ($new_path)) {
        LogDebug "current PATH environment variable: $current_path"
        LogDebug "setting new PATH environment variable: $new_path"
        [System.Environment]::SetEnvironmentVariable('PATH', $new_path, $env_var_scope)
        LogInfo "in case of issue, previous PATH variable can be retrieved in $LOG_PATH"
    }

    LogInfo "removing REZ_CONFIG_FILE environment variable"
    [Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', "", $env_var_scope)

    LogInfo "removing KNOTS_REZ_INSTALLER_VERSION environment variable"
    [Environment]::SetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', "", $env_var_scope)

    Write-Host $( "_"*80 ) -ForegroundColor "green"
    LogSucess "finished uninstalling rez"
    Write-Output $( "="*80 )
}

Uninstall-All