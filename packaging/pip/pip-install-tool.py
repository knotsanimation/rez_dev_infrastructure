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
import dataclasses
import distutils.dist
import logging
import shutil
import sys
import tempfile
import uuid
from pathlib import Path
import runpy
from typing import Callable
from typing import Optional

import rez.package_maker
import rez.version
import rez_pip.main
import rez_pip.pip
import rez_pip.rez

LOGGER = logging.getLogger(__name__)

THISDIR = Path(__file__).parent
PACKAGESDIR = THISDIR / "packages"
PATCHED_ATTR = "rez_pip_patched"


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


def find_package_config_path(package_name: str) -> Path:
    """
    Return the python configuration file for given package name.

    Args:
        package_name: must be the name of a file in the ``packages/`` directory.

    Returns:
        filesystem path to an existing file
    """
    package = [
        package for package in PACKAGESDIR.glob("*.py") if package.stem == package_name
    ]
    if not package:
        raise FileNotFoundError(
            f"Did not found package {package_name} in {PACKAGESDIR}"
        )

    return package[0]


@dataclasses.dataclass(frozen=True)
class PackageInstallVersion:
    """
    All the necessary information to install a pip package with rez_pip.

    Usually serialized on disk as python files.
    """

    pip_name: str
    """
    Name of the package on pip
    """

    pip_version: str
    """
    Version of the package on pip.
    
    Might be an empty string which implies "latest".
    """

    python_versions: tuple[str]
    """
    List of exact python versions it must be installed for.
    
    Exact imply major+minor+patch.
    """

    callback: Optional[
        Callable[
            [
                rez.package_maker.PackageMaker,
                distutils.dist.Distribution,
                rez.version.Version,
            ],
            bool,
        ]
    ] = None
    """
    Optional object called during the creation of each rez packages for the pip package
    and its dependencies.
    """

    @property
    def pip_query(self) -> str:
        return f"{self.pip_name}{self.pip_version}"

    @classmethod
    def from_dict(cls, src_dict: dict) -> "PackageInstallVersion":
        return cls(
            pip_name=src_dict["name"],
            pip_version=src_dict["version"],
            python_versions=tuple(src_dict["pythons"]),
            callback=src_dict.get("callback", None),
        )

    @classmethod
    def read_from_file(cls, file_path: Path) -> list["PackageInstallVersion"]:
        script_dict = runpy.run_path(str(file_path), run_name="__main__")
        raw_config = script_dict["CONFIG"]
        package_name = raw_config["name"]

        instances = []

        for version_config in raw_config["versions"]:
            version_config["name"] = package_name
            instances.append(cls.from_dict(version_config))

        return instances

    def get_python_executables(self) -> dict[str, Path]:
        """
        Find the python executable to use for the specified python versions using rez.
        """
        return {
            version: get_python_executable(version) for version in self.python_versions
        }


def install_package_version(
    package_version: PackageInstallVersion,
    release: bool = False,
) -> dict[str, list[rez.package_maker.PackageMaker]]:
    """
    Call rez_pip for the given install configuration.

    Args:
        package_version: object describing the installation to perform
        release: True to deploy the packages instead of just building them locally

    Returns:
        package processed per python version
    """
    installed: dict[str, list[rez.package_maker.PackageMaker]] = {}

    tmp_dir = Path(
        tempfile.mkdtemp(suffix=Path(__file__).name, prefix=package_version.pip_name)
    )

    try:
        for (
            python_version,
            python_exe,
        ) in package_version.get_python_executables().items():
            prefix = f"{package_version.pip_name}{package_version.pip_version}:{python_version}"

            def _callback(package, *args):
                if package_version.callback:
                    _patched = package_version.callback(package, *args)
                    if _patched:
                        setattr(package, PATCHED_ATTR, True)

            LOGGER.info(f"[{prefix}] calling rez_pip ...")
            packages = rez_pip.main.run_installation_for_python(
                pipPackageNames=[package_version.pip_query],
                pythonVersion=python_version,
                pythonExecutable=python_exe,
                pipPath=Path(rez_pip.pip.getBundledPip()),
                pipWorkArea=tmp_dir,
                rezPackageCreationCallback=_callback,
                rezRelease=release,
            )
            installed_packages = [
                package for package in packages if package.installed_variants
            ]
            LOGGER.info(
                f"[{prefix}] installed "
                f"{len(installed_packages)} packages, skipped "
                f"{len(packages) - len(installed_packages)}, patched "
                f"{len([package for package in packages if hasattr(package, PATCHED_ATTR)])}."
            )
            installed[python_version] = packages

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


def generate_report_str(
    processed_packages: dict[
        PackageInstallVersion, dict[str, list[rez.package_maker.PackageMaker]]
    ],
) -> list[str]:
    """
    Args:
        processed_packages: list of PackageMaker that have been "closed", i.e. processed.

    Returns:
        a human-readable string
    """
    out_str: list[str] = []
    indent = " " * 4

    for package_install, package_installed in processed_packages.items():
        for python_version, packages in package_installed.items():
            out_str += [
                f"[{package_install.pip_query}][python-{python_version}] {len(packages)} processed:"
            ]

            msg = []
            msg += ["installed:"]
            msg += [
                f"  - {[f'{variant.name}-{variant.version}' for variant in package.installed_variants]}"
                for package in packages
                if package.installed_variants
            ]
            msg += ["skipped:"]
            msg += [
                f"  - {[f'{variant.name}-{variant.version}' for variant in package.skipped_variants]}"
                for package in packages
                if package.skipped_variants
            ]
            msg += ["patched:"]
            msg += [
                f"  - {package.name}"
                for package in packages
                if hasattr(package, PATCHED_ATTR)
            ]
            msg = [indent + line for line in msg]
            out_str += msg

    return out_str


def main():
    LOGGER.info("started")

    cli = get_cli()

    if cli.debug:
        LOGGER.setLevel(logging.DEBUG)

    all_packages = {}

    for user_package_id in cli.package_names:
        LOGGER.info(f"processing {user_package_id} ...")

        _user_package_id = user_package_id.split(":", 1)
        if len(_user_package_id) == 2:
            user_package_name, user_package_version = user_package_id
        else:
            user_package_name = _user_package_id[0]
            user_package_version = None

        config_path = find_package_config_path(user_package_name)
        package_versions = PackageInstallVersion.read_from_file(config_path)

        for package_version in package_versions:
            if (
                user_package_version
                and package_version.pip_version != user_package_version
            ):
                continue

            processed_packages = install_package_version(
                package_version=package_version,
                release=cli.release,
            )
            all_packages[package_version] = processed_packages

    msg = generate_report_str(all_packages)
    msg = "\n".join(msg)
    LOGGER.info(f"processed {len(all_packages)} versions:\n{msg}")

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
