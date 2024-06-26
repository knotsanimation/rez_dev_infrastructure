# rez/installing/windows

Scripts to install rez on Windows machines.

# Usage

## Installation

### Prerequisites

- Download the content of this folder anywhere on your machine.
- Ensure the expected environment variable are set (see below).
- You have allowed the execution of PowerShell scripts `.ps1`, if not :
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
  The above allow the execution of scripts at all time for the current user.
  Check [the documentation](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
  to find other options available. 

Environment variables:

- both script retrieve multiple arguments using environment variables. Ensure
  those have been set properly. Usually you don't have to do it manually and
  use the software launcher with a profile defining them for you.
- The environment variable can be foudn by looking for `$Env:` calls. 


### Steps

- Open a new powershell terminal session.
- Allow execution of powersheel scripts if not already :
    ```powershell
    > Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```
  _Note this command only set the permission for the current session. It will
  need to be performed again when closing a reopening a terminal session._
- Run the installation script by drag and dropping it (or copy/pasting the path):

    ```powershell
    > C:\Users\whatever\...\rez-install.ps1
    ```

The process might take a minute or two depending on your connection as some
downloads are required.

Once finished, rez is installed locally on the machine but need additional 
configuration steps to be usable.

### Notes

- You can't run succesive execution of the installation script.
- If the installation fail, it is recommended to run the uninstall script before
  installing again.


## Uninstall

With similar steps to the above installation process you can simpy run the
`rez-uninstall.ps1` script.

### Notes

- You can run succesive execution of the uninstallation script without issue (but not useful).

# Design

### `install` design

- Download python on the user system, at the `knots` dedicated location. 
  This is achieved using [Nuget](https://www.nuget.org/).
- Make it temporarly accesible for the session
- Download rez from GitHub on the user system, at the `knots` dedicated location, 
- Install rez using the peviously acquired python.
- Add the installer version in the environment variable for future uninstallation.

