#!/usr/bin/env python3
"""Portable checks for the persisted Blueprint contract and v1/v2 compatibility."""
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {
    "order",
    "part_id",
    "construction_id",
    "position",
    "rotation",
    "scale",
    "properties",
}
ALLOWED_VERSIONS = {1, 2}


def validate_metadata(value) -> None:
    if value is None or isinstance(value, (bool, int, float, str)):
        if isinstance(value, float) and not (float("-inf") < value < float("inf")):
            raise AssertionError("non-finite float metadata is unsupported")
        return
    if isinstance(value, list):
        for item in value:
            validate_metadata(item)
        return
    if isinstance(value, dict):
        for key, item in value.items():
            assert isinstance(key, str), "metadata dictionary keys must be strings"
            validate_metadata(item)
        return
    raise AssertionError(f"unsupported metadata type: {type(value).__name__}")


def main() -> None:
    files = sorted((ROOT / "data" / "blueprints").glob("*.json"))
    assert files, "at least one prebuilt Blueprint is required"
    for path in files:
        blueprint = json.loads(path.read_text(encoding="utf-8"))
        assert {"id", "name", "version", "parts"} <= blueprint.keys(), path
        assert blueprint["version"] in ALLOWED_VERSIONS, path
        if blueprint["version"] == 2:
            assert isinstance(blueprint.get("integrity_hash"), str), path
            assert len(blueprint["integrity_hash"]) == 64, path
        orders = []
        construction_ids = set()
        for record in blueprint["parts"]:
            assert REQUIRED <= record.keys(), (path, record)
            if "attachments" in record:
                validate_metadata(record["attachments"])
            validate_metadata(record["properties"])
            assert len(record["position"]) == 3
            assert all(isinstance(axis, int) and not isinstance(axis, bool) for axis in record["position"]), (
                "positions must be integer 0.1m grid coordinates"
            )
            assert record["construction_id"] not in construction_ids, "construction IDs must be stable and unique"
            construction_ids.add(record["construction_id"])
            orders.append(record["order"])
        assert orders == sorted(orders), "construction order must be retained"
        assert len(orders) == len(set(orders)), "construction order must be unique"
    required_paths = [
        "project.godot",
        "scenes/worlds/HomeWorld.tscn",
        "scenes/worlds/BuildArea.tscn",
        "scenes/worlds/Lobby.tscn",
        "scripts/blueprint/blueprint_manager.gd",
        "scripts/vehicles/summon_system.gd",
        "tools/generation/blueprint_parity.py",
        "tests/blueprint_validation.gd",
        "tests/fixtures/missing_part_scene.json",
    ]
    for relative_path in required_paths:
        assert (ROOT / relative_path).is_file(), relative_path
    print(f"Blueprint contract passed for {len(files)} persisted Blueprint file(s).")


if __name__ == "__main__":
    main()
