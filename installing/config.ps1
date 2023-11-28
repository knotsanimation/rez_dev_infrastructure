$KnotsInstallConfig = @{
    rez_version = ''
    python_version = ''
    knots_install_path = ''
    python_install = ''
    rez_full_install_path = ''
    rez_scripts = ''
    rez_config_file = ''
    uninstall_log_path = ''
}

$KnotsInstallConfig.rez_version = "2.113.0"
$KnotsInstallConfig.python_version = "3.10.11"
$KnotsInstallConfig.knots_install_path = "C:\Program Files\knots"
$KnotsInstallConfig.python_install = "$($KnotsInstallConfig.knots_install_path)\python-rez"
$KnotsInstallConfig.rez_full_install_path = "$($KnotsInstallConfig.knots_install_path)\rez"
$KnotsInstallConfig.rez_scripts = "$($KnotsInstallConfig.rez_full_install_path)\Scripts\rez"
# TODO update when definitive
$KnotsInstallConfig.rez_config_file = "N:\skynet\apps\rez\config\.rezconfig"
$KnotsInstallConfig.uninstall_log_path = "$($KnotsInstallConfig.knots_install_path)\user-uninstall.log"
