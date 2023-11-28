# rez/installing/windows

Scripts to install rez on Windows machines.

# Usage

## Installation

### Prerequisites

- Download the content of this folder anywhere on your machine.
- Ensure the environment variable `KNOTS_SKYNET_PATH` is set and correspond
  to the path of the `skynet` root folder (contains the `.skynet_root` file).
- You have allowed the execution of PowerShell scripts `.ps1`, if not :
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
  The above allow the execution of scripts at all time for the current user.
  Check [the documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
  to find other options available. 

### Steps

- Open a new powershell terminal session **with Administrator permissions**.
- Allow execution of powersheel scripts if not already :
    ```powershell
    > Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```
  _Note this command only set the permission for the current session. It will
  need to be performed again when closing a reopening a terminal session._
- Run the installation script by drag and dropping it (or copy/pasting the path):

    ```powershell
    > C:\Users\whatever\...\user-install.ps1
    ```

The process might take a minute or two depending on your connection as some
downloads are required.

Once finished, you can verify the installation by opening a new terminal session
and executing :

```powershell
rez -V
```
Which should display the current rez version installed.

### Notes

- You can run succesive execution of the installation script without issue (but not useful).
- If the installation fail, it is recommended to run the uninstall script before
  installing again.


## Uninstall

With similar steps to the above installation process you can simpy run the
`user-uninstall.ps1` script.

### Notes

- You can run succesive execution of the uninstallation script without issue (but not useful).

# Developer

## Design

- `config.ps1` is a common script shared for both installation and uninstallation
  that define constant variables.

### `install`

- Download python on the user system, at the `knots` dedicated location. 
  This is achieved using [Nuget](https://www.nuget.org/).
- Make it temporarly accesible for the session
- Download rez from GitHub on the user system, at the `knots` dedicated location, 
- Install rez using the peviously acquired python.
- Configure the system environment variable so rez can be used.

