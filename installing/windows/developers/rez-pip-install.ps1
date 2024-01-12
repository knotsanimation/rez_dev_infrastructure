$rez_install = (Get-Command rez).Path
$venv_dir = Split-Path(Split-Path $rez_install -Parent) -Parent
# activate rez virtual environment
. "$venv_dir\Activate.ps1"

python -m pip install rez-pip==0.3.2

# exit the venv
deactivate