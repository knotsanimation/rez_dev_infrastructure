# global config
$ErrorActionPreference = "Stop"

# // Utility code

function Log {
    param ($message, $level, $color)
    Write-Host "$level | $((Get-Date).ToString() ) [knots-install] $message" -ForegroundColor $color
}
function LogDebug { Log @args "DEBUG" "DarkGray" }
function LogInfo { Log @args "INFO" "White" }
function LogSucess { Log @args "SUCCESS" "Green" }
function LogWarning { Log @args "WARNING" "Yellow" }
function LogError { Log @args "ERROR" "Red" }

function Create-TmpDir {
    param([string]$prefix)
    $tmp_root = [System.IO.Path]::GetTempPath()
    $tmp_directory = "$tmp_root\$prefix$( New-Guid )"
    LogDebug "Creating temporary directory $tmp_directory"
    New-Item -Type Directory -Path $tmp_directory | Out-Null
    return $tmp_directory
}

# // Installation Code

function Install-Python {
    param([string]$python_version, [string]$target_dir)

    if (Test-Path -Path $python_install) {
        LogWarning "python already installed at $python_install"
        return
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
}

function Install-Rez {
    param([string]$rez_version, [string]$target_dir)

    if (Test-Path -Path $target_dir) {
        LogWarning "rez already installed at $target_dir"
        return
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
}

function Install-System {
    param([string]$rez_config_file, [string]$rez_scripts, [string]$env_scope)

    # query from global system as we already modified PATH for this session
    $new_path_var = [Environment]::GetEnvironmentVariable("Path", $env_scope)
    $new_path_var = $new_path_var + ";$rez_scripts"

    LogInfo "setting environment variable PATH with $new_path_var"
    [Environment]::SetEnvironmentVariable('PATH', $new_path_var, $env_scope)

    LogInfo "setting environment variable REZ_CONFIG_FILE with $rez_config_file"
    [Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', $rez_config_file, $env_scope)

}

function Install-All {

    # configuration
    $rez_version = "2.113.0"
    $python_version = "3.10.11"
    $knots_install_path = "C:\Program Files\knots"
    $python_install = "$knots_install_path\python-rez"
    $rez_full_install_path = "$knots_install_path\rez"
    $rez_scripts = "$rez_full_install_path\Scripts\rez"
    # TODO update when definitive
    $rez_config_file = "N:\skynet\apps\rez\config\.rezconfig"

    LogInfo "starting rez installation to $knots_install_path"

    # TODO uncomment
    #if (-not (Test-Path -Path $rez_config_file)) {
    #    throw "Rez config file does not exists, check your properly mapped the NAS drives."
    #}
    if (-not(Test-Path -Path $knots_install_path)) {
        LogInfo "creating $knots_install_path"
        New-Item -Type Directory -Path $knots_install_path | Out-Null
    }

    Install-Python -python_version $python_version -target_dir $python_install
    LogSucess "installed python $python_version to $python_install"

    $env:PATH += ";$python_install"

    $check_python_path = (Get-Command python).Path
    if (-not ($check_python_path -eq "$python_install\python.exe")) {
        throw "Issue with python installation, unexpected path $check_python_path"
    }

    Install-Rez -rez_version $rez_version -target_dir $rez_full_install_path -env_scope "Machine"
    LogSucess "installed rez $rez_version to $rez_full_install_path"

    # TODO uncomment
    # Install-System -rez_config_file $rez_config_file -rez_scripts $rez_scripts

    LogSucess "installation finished; you can test it by opening a new shell and typing:"
    LogSucess "  rez -V"
}

Install-All