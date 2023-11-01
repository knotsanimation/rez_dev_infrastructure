$rez_version = "2.113.0"
$rez_url = "https://github.com/AcademySoftwareFoundation/rez/archive/refs/tags/$rez_version.zip"
$python_install = "N:\skynet\apps\rez\python\platform-windows\arch-AMD64"
$knots_install_path = "C:\Program Files\knots"
$rez_full_install_path = Join-Path $knots_install_path "rez"
$rez_scripts = Join-Path $rez_full_install_path "Scripts" "rez"
$rez_config_file = "N:\skynet\apps\rez\config\.rezconfig"

if (-not (Test-Path -Path $python_install)) {
    throw "Python directory does not exists, check your properly mapped the nas drives."
}
$env:PATH += ";$python_install"
# safety that will throw if there was an issue with the above
python -V

# create temporary directory for download
$temp_directory = Join-Path $Env:Temp "rezinstall-$(New-Guid)"
echo "creating temporary directory $temp_directory ..."
New-Item -Type Directory -Path $temp_directory | Out-Null

$rez_src = Join-Path $temp_directory "rez.zip"
echo "downloading $rez_url to $rez_src ..."
Invoke-WebRequest -Uri $rez_url -OutFile $rez_src

echo "unzipping $rez_src ..."
Expand-Archive $rez_src -DestinationPath $temp_directory
# path of the directory that was extracted from the zip
$rez_src = Join-Path $temp_directory "rez-$rez_version"

if (-not (Test-Path -Path $knots_install_path)) {
    echo "creating $knots_install_path"
    New-Item $knots_install_path -ItemType Directory
}

if (-not (Test-Path -Path $rez_full_install_path)) {
    echo "creating $rez_full_install_path"
    New-Item $rez_full_install_path -ItemType Directory
}
else {
    Remove-Item $temp_directory -Recurse -Force
    throw "rez seems to be already installed at $rez_full_install_path"
}

echo "creating $rez_full_install_path"
New-Item $rez_full_install_path -ItemType Directory

cd $rez_src
python install.py --help

# query from global system as we already modified PATH for this session
$new_path_var = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$new_path_var = $new_path_var + ";$rez_scripts"
echo "setting environment variable PATH with $new_path_var"
[Environment]::SetEnvironmentVariable('PATH', $new_path_var, 'Machine')
echo "setting environment variable REZ_CONFIG_FILE with $rez_config_file"
[Environment]::SetEnvironmentVariable('REZ_CONFIG_FILE', $rez_config_file, 'Machine')

Remove-Item $temp_directory -Recurse -Force
echo "installation finished; you can test it by typing:"
echo "  rez -V"