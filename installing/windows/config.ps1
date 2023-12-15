$INSTALLER_VERSION = "1.0.0"

$KnotsInstallConfig = @{
    rez_version = ''
    python_version = ''
    knots_install_path = ''
    python_install = ''
    rez_full_install_path = ''
    rez_scripts = ''
    rez_config_file = ''
    uninstall_log_path = ''
    env_var_scope = ''
}

# TODO update when definitive
$_knots_skynet_path = $env:KNOTS_SKYNET_PATH
if (-not($_knots_skynet_path)) {
    throw "missing KNOTS_SKYNET_PATH environment variable"
}

$KnotsInstallConfig.rez_version = "2.113.0"
$KnotsInstallConfig.python_version = "3.10.11"
$KnotsInstallConfig.knots_install_path = "$env:LOCALAPPDATA\knots"
$KnotsInstallConfig.python_install = "$($KnotsInstallConfig.knots_install_path)\python-rez"
$KnotsInstallConfig.rez_full_install_path = "$($KnotsInstallConfig.knots_install_path)\rez"
$KnotsInstallConfig.rez_scripts = "$($KnotsInstallConfig.rez_full_install_path)\Scripts\rez"
$KnotsInstallConfig.rez_config_file = "$_knots_skynet_path\apps\rez\config\rezconfig-main.yml"
$KnotsInstallConfig.rez_cache_path = "$HOME\rez\.cache"
$KnotsInstallConfig.uninstall_log_path = "$($KnotsInstallConfig.knots_install_path)\user-uninstall.log"
# warning: anything else might require admin permissions
$KnotsInstallConfig.env_var_scope = "User"
