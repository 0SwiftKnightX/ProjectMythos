#!/usr/bin/env python3
"""Portable contract checks for the inspectable Blueprint recipe format."""
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED = {"order", "part_id", "construction_id", "position", "rotation", "scale", "properties"}


def main() -> None:
    files = sorted((ROOT / "data" / "blueprints").glob("*.json"))
    assert files, "at least one prebuilt Blueprint is required"
    for path in files:
        blueprint = json.loads(path.read_text(encoding="utf-8"))
        assert {"id", "name", "version", "parts"} <= blueprint.keys(), path
        assert blueprint["version"] == 1, path
        orders = []
        construction_ids = set()
        for record in blueprint["parts"]:
            assert REQUIRED <= record.keys(), (path, record)
            assert len(record["position"]) == 3
            assert all(isinstance(axis, int) for axis in record["position"]), "positions must be integer 1/3m grid coordinates"
            assert record["construction_id"] not in construction_ids, "part IDs must be stable and unique"
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
    ]
    for relative_path in required_paths:
        assert (ROOT / relative_path).is_file(), relative_path
    print(f"Blueprint contract passed for {len(files)} prebuilt blueprint(s).")


if __name__ == "__main__":
    main()
