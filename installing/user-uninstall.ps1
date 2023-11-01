$rez_install_path = "C:\Program Files\knots\rez"
$rez_scripts_path = "C:\Program Files\knots\rez\Scripts\rez"

# remove rez local installation
echo "removing $rez_install_path ..."
Remove-Item $rez_install_path -Recurse -Force

# unset PATH environment variable
$current_path = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
echo "current PATH environment variable is $current_path"
$new_path = ($current_path.Split(';') | Where-Object { $_ -ne $rez_scripts_path }) -join ';'
echo "new PATH environment variable is $new_path"
[System.Environment]::SetEnvironmentVariable('PATH', $path, 'Machine')

echo "removing REZ_CONFIG_FILE environment variable"
[Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', "", 'Machine')

echo "finished uninstalling rez"