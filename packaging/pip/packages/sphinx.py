import logging
import rez.package_maker

LOGGER = logging.getLogger(__name__)


def patch_cyclic_dependency(
    rez_package: rez.package_maker.PackageMaker,
    *args,
):
    """
    Fix issue on some sphinx dependency that are required by ``sphinx`` but also require
    ``sphinx`` creating a cyclic dependency.

    We simply set a weak reference on all their ``requires`` to fix the issue.
    """
    if not rez_package.name.startswith("sphinx") or rez_package.name == "sphinx":
        return

    LOGGER.info(f"patching {rez_package.name}")
    rez_package.requires = ["~" + require for require in rez_package.requires]


CONFIG = {
    "name": "sphinx",
    "versions": [
        {
            "version": "==7.2.6",
            "pythons": ["3.10.11"],
            "callback": patch_cyclic_dependency,
        },
    ],
}
