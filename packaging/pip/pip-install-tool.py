"""
CLI allowing to installed pre-defined pip package as rez packages, using rez_pip.

The packages must be pre-defined in the ``./packages/`` relative directory.

Prerequisites
=============

* python 3
* rez_pip is installed in rez own venv
* currently using an experimental rez_pip version
  (see https://github.com/JeanChristopheMorinPerso/rez-pip/pull/89)
  .. TODO: update when official
* a ``packages/`` directory next to this script which contains a python file per package

Launching
=========

.. code-block:: shell

    rez-python pip-install-tool.py --help

**Example**

Install all versions of ``sphinx`` configured, and only ``pytest-7.4.3``.

.. code-block:: shell

    rez-python pip-install-tool.py sphinx pytest:==7.4.3
"""
import argparse
import logging
import shutil
import sys
import tempfile
from pathlib import Path
import runpy
from typing import Callable
from typing import Optional

import rez.package_maker
import rez.resolved_context
import rez_pip.main
import rez_pip.pip
import rez_pip.rez

LOGGER = logging.getLogger(__name__)

THISDIR = Path(__file__).parent
PACKAGESDIR = THISDIR / "packages"


def get_python_executable(version: str) -> Path:
    """
    Get the path to the python executable of the given rez python package version.

    Args:
        version: rez syntax

    Returns:
        filesystem path to an existing file
    """
    python_package = rez_pip.rez.findPythonPackages(version)[0]
    return rez_pip.rez.getPythonExecutable(python_package)


def get_package_config(package_name: str) -> dict:
    """
    Return the pip installation configuration for given package.

    Args:
        package_name: must be the name of a file in the packages directory.

    Returns:
        configuration extracted form the ``CONFIG`` global variable.
    """
    package = [
        package for package in PACKAGESDIR.glob("*.py") if package.stem == package_name
    ]
    if not package:
        raise FileNotFoundError(
            f"Did not found package {package_name} in {PACKAGESDIR}"
        )

    path = package[0]

    script_dict = runpy.run_path(str(path), run_name="__main__")
    config = script_dict["CONFIG"]
    return config


def install_package_config(
    package_config: dict,
    specific_version: Optional[str] = None,
    release: bool = False,
) -> list[rez.package_maker.PackageMaker]:
    """
    Call rez_pip for the given config.

    Args:
        package_config: dict in a specific structure
        specific_version: the version specified in the config to install
        release: True to deploy the packages instead of just building them locally
    """
    pip_name: str = package_config["name"]
    version_configs: list[dict] = package_config["versions"]

    tmp_dir = Path(tempfile.mkdtemp(suffix=Path(__file__).name))
    installed = []

    try:
        tmp_dir = tmp_dir / pip_name
        tmp_dir.mkdir()

        for version_config in version_configs:
            # might be an empty string which means latest
            pip_version: str = version_config["version"]
            python_versions: list[str] = version_config["pythons"]
            callback: Optional[Callable] = version_config.get("callback", None)

            if specific_version and pip_version != specific_version:
                continue

            for python_version in python_versions:
                python_exe = get_python_executable(python_version)

                LOGGER.debug(
                    f"{pip_name=}, {pip_version=}, {python_version=}, {python_exe=}, {callback=}"
                )
                LOGGER.info(f"[{pip_version}:{python_version}] calling rez_pip ...")
                packages = rez_pip.main.run_installation_for_python(
                    pipPackageNames=[f"{pip_name}{pip_version}"],
                    pythonVersion=python_version,
                    pythonExecutable=python_exe,
                    pipPath=Path(rez_pip.pip.getBundledPip()),
                    pipWorkArea=tmp_dir,
                    rezPackageCreationCallback=callback,
                    rezRelease=release,
                )
                LOGGER.info(
                    f"[{pip_version}:{python_version}] installed {len(packages)} packages"
                )
                installed += packages

    finally:
        LOGGER.debug(f"removing {tmp_dir}")
        shutil.rmtree(tmp_dir)

    return installed


def get_cli():
    """
    Return the parsed result of the command line interface.
    """
    argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        Path(__file__).stem,
        description="CLI allowing to installed pre-defined pip package as rez packages, using rez_pip.",
    )
    parser.add_argument(
        "package_names",
        type=str,
        nargs="+",
        help='The name of a package to install. You can optionally append the specific version to install after a colon ":"',
    )
    parser.add_argument(
        "--debug", action="store_true", help="set logging to DEBUG level"
    )
    parser.add_argument(
        "--release",
        action="store_true",
        help="deploy the package instead of just building them locally",
    )
    parsed = parser.parse_args(argv)
    return parsed


def main():
    LOGGER.info("started")

    cli = get_cli()

    if cli.debug:
        LOGGER.setLevel(logging.DEBUG)

    for package_id in cli.package_names:
        package_id = package_id.split(":", 1)
        if len(package_id) == 2:
            package_name, package_version = package_id
        else:
            package_name = package_id[0]
            package_version = None

        LOGGER.info(f"installing {package_id} ...")
        config = get_package_config(package_name)
        installed = install_package_config(
            config,
            specific_version=package_version,
            release=cli.release,
        )
        LOGGER.info(f"installed {len(installed)} packages")

    LOGGER.info("finished")


if __name__ == "__main__":
    # XXX rez_pip will go crazy if we override its logger
    _root_logger = logging.root
    logging.root = LOGGER
    logging.basicConfig(
        level=logging.INFO,
        format="{levelname: <7} | {asctime} [{name}] {message}",
        style="{",
        stream=sys.stdout,
    )
    logging.root = _root_logger
    main()
