# global config
$ErrorActionPreference = "Stop"

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
    Write-Host $final_message -ForegroundColor $color
    Out-File -FilePath $LOG_PATH -Append -InputObject "$final_message"
}
function LogDebug { Log @args "DEBUG" "DarkGray" }
function LogInfo { Log @args "INFO" "White" }
function LogSucess { Log @args "SUCCESS" "Green" }

function Uninstall-All {

    $python_install = $KnotsInstallConfig.python_install
    $rez_install_path = $KnotsInstallConfig.rez_full_install_path
    $rez_scripts_path = $KnotsInstallConfig.rez_scripts

    if (Test-Path -Path $rez_install_path) {
        LogInfo "removing $rez_install_path ..."
        Remove-Item $rez_install_path -Recurse -Force
    }
    if (Test-Path -Path $python_install) {
        LogInfo "removing $python_install ..."
        Remove-Item $python_install -Recurse -Force
    }

    # unset PATH environment variable if needed
    # there is a probability to fucked up the user PATH variable so we recommend
    # to backup the PATH variable that is echoed.
    $current_path = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $new_path = ($current_path.Split(';') | Where-Object { $_ -ne $rez_scripts_path }) -join ';'
    if ((-not($current_path -eq $new_path)) -and ($new_path)) {
        LogDebug "current PATH environment variable: $current_path"
        LogDebug "setting new PATH environment variable: $new_path"
        [System.Environment]::SetEnvironmentVariable('PATH', $new_path, 'Machine')
        LogInfo "history of the PATH variable, in case of issue, can be found at $LOG_PATH"
    }

    LogInfo "removing REZ_CONFIG_FILE environment variable"
    [Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', "", 'Machine')
    LogSucess "finished uninstalling Knots's rez"
}

Uninstall-All