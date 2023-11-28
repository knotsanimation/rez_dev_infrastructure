# global config
$ErrorActionPreference = "Stop"
$SCRIPTNAME = "knots-rez-install"

# import configuration
. "$PSScriptRoot\config.ps1"

# // Utility code

function Log {
    param ($message, $level, $color)
    Write-Host "$($level.PadRight(8, ' ') ) | $((Get-Date).ToString() ) [$SCRIPTNAME] $message" -ForegroundColor $color
}
function LogDebug { Log @args "DEBUG" "DarkGray" }
function LogInfo { Log @args "INFO" "White" }
function LogSucess { Log @args "SUCCESS" "Green" }
function LogWarning { Log @args "WARNING" "Yellow" }
function LogError { Log @args "ERROR" "Red" }

function Create-TmpDir {
    <#
    .SYNOPSIS
        Create a directory in the standard temporary location. User is respondible of removing it.

    .PARAMETER prefix
        prefix for the directory name

    .OUTPUTS
        Filesystem path of the directory created.
    #>
    param([string]$prefix)
    $tmp_root = [System.IO.Path]::GetTempPath()
    $tmp_directory = "$tmp_root\$prefix$( New-Guid )"
    LogDebug "Creating temporary directory $tmp_directory"
    New-Item -Type Directory -Path $tmp_directory | Out-Null
    return $tmp_directory
}

# // Installation Code

function Install-Python {
    <#
    .SYNOPSIS
        Install a working python version at the given path.

    .PARAMETER python_version
        Full python version to install, must be available on Nuget.

    .PARAMETER target_dir
        Filesystem path to a directory to install python to.
    #>
    param([string]$python_version, [string]$target_dir)

    if (Test-Path -Path $target_dir) {
        LogWarning "python already installed at $target_dir"
        return $false
    }

    $tmp_directory = Create-TmpDir -prefix "knots-python-install-"
    $python_tmp_dir = "$tmp_directory\python"

    $nuget_url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $nuget_path = "$tmp_directory\nuget.exe"

    LogInfo "downloading nuget to $nuget_path"
    Invoke-WebRequest $nuget_url -OutFile $nuget_path

    LogInfo "downloading python $python_version to $python_tmp_dir"
    Start-Process -NoNewWindow -Wait -FilePath $nuget_path -ArgumentList "install python -OutputDirectory $python_tmp_dir -Version $python_version"
    $python_tmp_install_dir = "$python_tmp_dir\python.$python_version\tools"

    LogInfo "installing python to $target_dir"
    Copy-Item -Path $python_tmp_install_dir -Destination $target_dir -Recurse

    LogDebug "removing temporary directory $tmp_directory"
    Remove-Item $tmp_directory -Force -Recurse
    return $true
}

function Install-Rez {
    <#
    .SYNOPSIS
        Install a working rez version at the given path. Assume that python is installed on the system.

    .PARAMETER rez_version
        Full rez version to install, must be available on GitHub.

    .PARAMETER target_dir
        Filesystem path to a directory to install rez to.
    #>
    param([string]$rez_version, [string]$target_dir)

    if (Test-Path -Path $target_dir) {
        LogWarning "rez already installed at $target_dir"
        return $false
    }

    $rez_url = "https://github.com/AcademySoftwareFoundation/rez/archive/refs/tags/$rez_version.zip"

    # create temporary directory for download
    $temp_directory = Create-TmpDir -prefix "knots-rezinstall"

    $rez_src = "$temp_directory\rez.zip"
    LogInfo "downloading $rez_url to $rez_src ..."
    Invoke-WebRequest -Uri $rez_url -OutFile $rez_src

    LogInfo "unzipping $rez_src ..."
    Expand-Archive $rez_src -DestinationPath $temp_directory
    # path of the directory that was extracted from the zip
    $rez_src = "$temp_directory\rez-$rez_version"

    LogInfo "creating $target_dir"
    New-Item $target_dir -ItemType Directory | Out-Null

    $previous_cwd = (Get-Item .).FullName
    Set-Location $rez_src
    Start-Process python -Wait -NoNewWindow -ArgumentList "install.py --help"
    Set-Location $previous_cwd

    LogDebug "removing temporary directory $temp_directory"
    Remove-Item $temp_directory -Force -Recurse
    return $true
}

function Install-System {
    <#
    .SYNOPSIS
        Configure the system so rez can be used.

    .PARAMETER rez_config_file
        Filesystem path to the rez config file to use for rez.

    .PARAMETER rez_scripts
        Filesystem path to the location of the rez /Scripts directory.

    .PARAMETER env_scope
        Name of the scope for environment variable. Ex: "Machine"
    #>
    param([string]$rez_config_file, [string]$rez_scripts, [string]$env_scope)

    # query from global system as we already modified PATH for this session
    $current_var = [Environment]::GetEnvironmentVariable("PATH", $env_scope)

    if (-not($current_var.Split(';').contains($rez_scripts))) {
        LogDebug "got environment variable PATH=$current_var"

        $path_delimiter = ";"
        if ( $current_var.EndsWith(";")) {
            $path_delimiter = ""
        }
        $new_path_var = $current_var + "$path_delimiter$rez_scripts"

        LogInfo "setting environment variable PATH with $new_path_var"
        [Environment]::SetEnvironmentVariable('PATH', $new_path_var, $env_scope)
    }
    else {
        LogDebug "environment variable PATH is already set as expected"
    }

    $current_var = [Environment]::GetEnvironmentVariable("REZ_CONFIG_FILE", $env_scope)
    LogDebug "got environment variable REZ_CONFIG_FILE=$current_var"
    LogInfo "setting environment variable REZ_CONFIG_FILE with $rez_config_file"
    [Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', $rez_config_file, $env_scope)

    LogInfo "setting environment variable KNOTS_REZ_INSTALLER_VERSION with $INSTALLER_VERSION"
    [Environment]::SetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', $INSTALLER_VERSION, $env_scope)

}

function Install-All {

    $sys_current_role = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (
    !($sys_current_role).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    ) {
        throw "Please restart the script in a shell with Administrator permissions."
    }

    $config = $KnotsInstallConfig

    Write-Output $( "="*80 )
    Write-Output "[$SCRIPTNAME v$INSTALLER_VERSION] install Rez package manager.`n"
    LogInfo "starting rez installation to $( $config.knots_install_path )"

    # TODO uncomment
    #if (-not (Test-Path -Path $rez_config_file)) {
    #    throw "Rez config file does not exists, check your properly mapped the NAS drives."
    #}
    if (-not(Test-Path -Path $config.knots_install_path)) {
        LogInfo "creating $( $config.knots_install_path )"
        New-Item -Type Directory -Path $config.knots_install_path | Out-Null
    }

    $installed = Install-Python -python_version $config.python_version -target_dir $config.python_install
    if ($installed) {
        LogSucess "installed python $( $config.python_version ) to $( $config.python_install )"
    }

    $env:PATH += ";$( $config.python_install )"

    $check_python_path = (Get-Command python).Path
    if (-not($check_python_path -eq "$( $config.python_install )\python.exe")) {
        throw "Issue with python installation, unexpected path $check_python_path"
    }

    $installed = Install-Rez -rez_version $config.rez_version -target_dir $config.rez_full_install_path
    if ($installed) {
        LogSucess "installed rez $( $config.rez_version ) to $( $config.rez_full_install_path )"
    }

    Install-System -rez_config_file $config.rez_config_file -rez_scripts $config.rez_scripts -env_scope $config.env_var_scope

    if (Test-Path -Path "$HOME\.rezconfig") {
        LogWarning "found local rezconfig at $HOME\.rezconfig; please remove to avoid issues."
    }

    Write-Host $( "_"*80 ) -ForegroundColor "green"
    LogSucess "installation finished ! You can test it by opening a new shell and typing:"
    LogSucess "  rez -V"
    Write-Output $( "="*80 )
}

Install-All