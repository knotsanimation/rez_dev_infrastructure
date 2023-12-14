# global config
$ErrorActionPreference = "Stop"

$rez_local_packages_path = rez-config local_packages_path
$python_version_src = "3.9.13.2"
$python_version_dst = "3.9.13"

"copying python-$python_version_src to $rez_local_packages_path ..."
rez cp "python-$python_version_src" --reversion $python_version_dst --dest-path $rez_local_packages_path
"calling rez-pip ..."
rez python -m rez_pip pytest --python-version ==$python_version_dst --release