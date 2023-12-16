# -*- coding: utf-8 -*-

name = "rez_installer"

version = "1.1.0"

variants = [
    ["platform-windows"],
]

requires = []

description = "Install rez on a machine."

authors = ["Liam Collod"]

maintainers = []

uuid = "0f26f7210b3d4ab38713179a39609e10"

build_command = "python {root}/build.py"

private_build_requires = [
    "python-3+",
    "rezbuild_utils",
]


def commands():
    pass


with scope("config") as _config:
    _config.release_packages_path = "${KNOTS_SKYNET_PATH}/apps/rez"
