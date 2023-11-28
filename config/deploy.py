import getpass
import logging
import os
import shutil
import stat
import datetime
import sys
from pathlib import Path

LOGGER = logging.getLogger(__name__)

THISDIR = Path(__file__).parent

CONFIGS_SRC_PATHS = [
    THISDIR / "rezconfig-main.yml",
]

KNOTS_SKYNET_PATH = Path(os.environ["KNOTS_SKYNET_PATH"]).resolve()
assert KNOTS_SKYNET_PATH.exists()

CONFIGS_DST_PATH = KNOTS_SKYNET_PATH / "apps" / "rez" / "config"
assert CONFIGS_DST_PATH.exists()


def set_read_only(path: Path):
    """
    Remove write permissions for everyone on the given file.
    """
    NO_USER_WRITING = ~stat.S_IWUSR
    NO_GROUP_WRITING = ~stat.S_IWGRP
    NO_OTHER_WRITING = ~stat.S_IWOTH
    NO_WRITING = NO_USER_WRITING & NO_GROUP_WRITING & NO_OTHER_WRITING

    current_permissions = stat.S_IMODE(os.lstat(path).st_mode)
    os.chmod(path, current_permissions & NO_WRITING)


def deploy_config(config_path: Path, target_dir: Path):
    config_dst_path = target_dir / config_path.name
    LOGGER.debug(f"copying {config_path} to {config_dst_path}")
    # overwrite if exists
    shutil.copy2(config_path, config_dst_path, follow_symlinks=False)

    config_content = config_dst_path.read_text()
    header = (
        f"# deployed on {datetime.datetime.utcnow()} by {getpass.getuser()}\n"
        f"# DO NOT EDIT THIS FILE DIRECTLY\n\n"
    )
    new_config_content = header + config_content
    LOGGER.debug(f"adding header to dst config.")
    config_dst_path.write_text(new_config_content)

    LOGGER.debug(f"setting dst config to read-only")
    set_read_only(config_dst_path)


def main():
    for config_src_path in CONFIGS_SRC_PATHS:
        LOGGER.info(f"deploying <{config_src_path}>")
        deploy_config(config_src_path, CONFIGS_DST_PATH)

    LOGGER.info("finished")


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.DEBUG,
        format="{levelname: <7} | {asctime} [{name}] {message}",
        style="{",
        stream=sys.stdout,
    )
    main()
