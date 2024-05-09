# global config
$ErrorActionPreference = "Stop"
$SCRIPTNAME = "knots-rez-install"
$INSTALLER_VERSION = "2.0.0"

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
    Start-Process python -Wait -NoNewWindow -ArgumentList "install.py `"$target_dir`""
    Set-Location $previous_cwd

    LogDebug "removing temporary directory $temp_directory"
    Remove-Item $temp_directory -Force -Recurse
    return $true
}


function Install-All {

    # we retrieve parameters from the environment
    $knots_install_path = "$Env:KNOTS_LOCAL_INSTALL_PATH"
    $python_version = "$Env:REZ_PYTHON_VERSION"
    $python_install = "$Env:KNOTS_LOCAL_PYTHON_INSTALL_PATH"
    $rez_version = "$Env:REZ_VERSION"
    $rez_full_install_path = "$Env:KNOTS_LOCAL_REZ_INSTALL_PATH"
    $rez_cache_dir = "$Env:REZ_CACHE_PACKAGES_PATH"
    $env_scope = "User"

    # ensure user has uninstalled before installing
    $installed_version = [System.Environment]::GetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', $env_scope)
    if ($installed_version){
        throw "Please use the uninstaller v$installed_version first before installing."
    }

    Write-Output $( "="*80 )
    Write-Output "[$SCRIPTNAME v$INSTALLER_VERSION] install Rez package manager.`n"
    LogInfo "starting rez installation to $knots_install_path"

    if (-not(Test-Path -Path $knots_install_path)) {
        LogInfo "creating $( $knots_install_path )"
        New-Item -Type Directory -Path $knots_install_path | Out-Null
    }

    $installed = Install-Python -python_version $python_version -target_dir $python_install
    if ($installed) {
        LogSucess "installed python $python_version to $python_install"
    }

    $env:PATH += ";$( $python_install )"

    $check_python_path = (Get-Command python).Path
    if (-not($check_python_path -eq "$( $python_install )\python.exe")) {
        throw "Issue with python installation, unexpected path $check_python_path"
    }

    $installed = Install-Rez -rez_version $rez_version -target_dir $rez_full_install_path
    if ($installed) {
        LogSucess "installed rez $rez_version to $rez_full_install_path"
    }

    LogInfo "setting environment variable KNOTS_REZ_INSTALLER_VERSION with $INSTALLER_VERSION"
    [Environment]::SetEnvironmentVariable('KNOTS_REZ_INSTALLER_VERSION', $INSTALLER_VERSION, $env_scope)

    # rez doesn't create its cache directory automatically :/
    if (-not(Test-Path -Path $rez_cache_dir)) {
        LogInfo "creating $( $rez_cache_dir )"
        New-Item -Type Directory -Path $rez_cache_dir -ea 0 | Out-Null
    }

    if (Test-Path -Path "$HOME\.rezconfig") {
        LogWarning "found local rezconfig at $HOME\.rezconfig; please remove until you know what you do."
    }

    Write-Host $( "_"*80 ) -ForegroundColor "green"
    LogSucess "installation finished !"
    Write-Output $( "="*80 )
}

Install-All