from __future__ import annotations

import importlib.util
import subprocess
import sys
from importlib.metadata import version

from packaging.version import parse


def is_installed(package: str, minimum: str | None = None, maximum: str | None = None):
    try:
        spec = importlib.util.find_spec(package)
    except ModuleNotFoundError:
        return False
    if spec is None:
        return False
    if minimum is None and maximum is None:
        return True

    installed = parse(version(package))
    lower = parse(minimum or "0")
    upper = parse(maximum or "99999999")
    return lower <= installed <= upper


def install():
    # MediaPipe 0.10.13+ requires protobuf 4.25.3+, while reForge pins 3.20.0.
    dependencies = [
        ("ultralytics", "8.3.75", None),
        ("mediapipe", "0.10.11", "0.10.11"),
        ("rich", "13.0.0", None),
    ]
    packages = []
    for package, minimum, maximum in dependencies:
        if is_installed(package, minimum, maximum):
            continue
        if minimum and maximum:
            packages.append(f"{package}>={minimum},<={maximum}")
        elif minimum:
            packages.append(f"{package}>={minimum}")
        elif maximum:
            packages.append(f"{package}<={maximum}")
        else:
            packages.append(package)

    if packages:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", *packages], check=True
        )


try:
    import launch

    skip_install = launch.args.skip_install
except Exception:
    skip_install = False

if not skip_install:
    install()
