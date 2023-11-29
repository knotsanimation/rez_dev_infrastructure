import logging
import os
import sys
from pathlib import Path

import rezbuild_utils

LOGGER = logging.getLogger(__name__)


def build():
    if not os.getenv("REZ_BUILD_INSTALL") == "1":
        LOGGER.info(f"skipped")
        return

    rezbuild_utils.copy_build_files(
        [
            Path("windows") / "config.ps1",
            Path("windows") / "rez-install.ps1",
            Path("windows") / "rez-uninstall.ps1",
            Path("windows") / "README.md",
        ]
    )
    rezbuild_utils.set_installed_path_read_only()
    LOGGER.info("finished")


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="{levelname: <7} | {asctime} [{name}] {message}",
        style="{",
        stream=sys.stdout,
    )
    build()
