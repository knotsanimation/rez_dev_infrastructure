$ErrorActionPreference = "Stop"

$knots_install_path = "C:\Program Files\knots"
$uninstall_log_path = "$knots_install_path\user-uninstall.log"
# we need it to create log files
if (-not(Test-Path -Path $knots_install_path)) {
    Write-Output "creating $knots_install_path"
    New-Item -Type Directory -Path $knots_install_path | Out-Null
}

function Log {
    param ($message, $level, $color)
    $final_message = "$level | $((Get-Date).ToString() ) [knots-install] $message"
    Write-Host $final_message -ForegroundColor $color
    Out-File -FilePath $uninstall_log_path -Append -InputObject "$final_message"
}
function LogDebug { Log @args "DEBUG" "DarkGray" }
function LogInfo { Log @args "INFO" "White" }
function LogSucess { Log @args "SUCCESS" "Green" }

function Uninstall-All {

    $python_install = "$knots_install_path\python-rez"
    $rez_install_path = "$knots_install_path\rez"
    $rez_scripts_path = "$rez_full_install_path\Scripts\rez"

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
        # [System.Environment]::SetEnvironmentVariable('PATH', $new_path, 'Machine')
        LogInfo "history of the PATH variable, in case of issue, can be found at $uninstall_log_path"
    }

    LogInfo "removing REZ_CONFIG_FILE environment variable"
    [Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', "", 'Machine')
    LogSucess "finished uninstalling Knots's rez"
}

Uninstall-All