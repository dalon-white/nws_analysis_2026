from pathlib import Path

import yaml


def load_parameters(path: str = "config/parameters.yml") -> dict:
    with Path(path).open("r", encoding="utf-8") as file_handle:
        return yaml.safe_load(file_handle)
