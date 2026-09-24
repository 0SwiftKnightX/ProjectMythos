#!/usr/bin/env python3
"""Generate a v2 Blueprint fixture and prove Python canonicalization parity."""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path
from typing import Any


CURRENT_VERSION = 2
REQUIRED_ROOT_FIELDS = {"id", "name", "version", "parts"}
REQUIRED_RECORD_FIELDS = {
    "order",
    "part_id",
    "construction_id",
    "position",
    "rotation",
    "scale",
    "properties",
}


def canonical_encode(value: Any) -> str:
    if value is None:
        return "n"
    if isinstance(value, bool):
        return "b:true" if value else "b:false"
    if isinstance(value, int):
        return f"i:{value}"
    if isinstance(value, float):
        if not value.is_integer() and not (float("-inf") < value < float("inf")):
            raise ValueError("non-finite float cannot be canonicalized")
        if not (float("-inf") < value < float("inf")):
            raise ValueError("non-finite float cannot be canonicalized")
        return "f:" + struct.pack("<d", value).hex()
    if isinstance(value, str):
        raw = value.encode("utf-8")
        return f"s:{len(raw)}:{raw.hex()}"
    if isinstance(value, list):
        encoded = [canonical_encode(item) for item in value]
        return f"a:{len(encoded)}:" + ";".join(encoded)
    if isinstance(value, dict):
        entries: list[tuple[str, str]] = []
        for key, item in value.items():
            if not isinstance(key, str):
                raise ValueError("canonical dictionaries require string keys")
            entries.append((canonical_encode(key), canonical_encode(item)))
        entries.sort(key=lambda pair: pair[0])
        body = ";".join(f"{key}={item}" for key, item in entries)
        return f"d:{len(entries)}:{body}"
    raise TypeError(f"unsupported Blueprint metadata type: {type(value).__name__}")


def migrate_v1(value: dict[str, Any]) -> dict[str, Any]:
    migrated = json.loads(json.dumps(value))
    migrated["version"] = CURRENT_VERSION
    for record in migrated["parts"]:
        if "attachments" not in record:
            record["attachments"] = []
    return migrated


def validate_normalized(value: dict[str, Any]) -> None:
    missing = REQUIRED_ROOT_FIELDS - value.keys()
    if missing:
        raise ValueError(f"normalized Blueprint missing fields: {sorted(missing)}")
    if value["version"] != CURRENT_VERSION:
        raise ValueError("normalized Blueprint is not v2")
    if not isinstance(value.get("id"), str) or not value["id"]:
        raise ValueError("Blueprint id must be a non-empty string")
    if not isinstance(value.get("name"), str):
        raise ValueError("Blueprint name must be a string")
    if not isinstance(value.get("is_prebuilt", False), bool):
        raise ValueError("Blueprint is_prebuilt must be boolean")
    if not isinstance(value["parts"], list):
        raise ValueError("Blueprint parts must be a list")

    orders: set[int] = set()
    construction_ids: set[str] = set()
    for record in value["parts"]:
        if not isinstance(record, dict) or not REQUIRED_RECORD_FIELDS <= record.keys():
            raise ValueError(f"invalid construction record: {record!r}")
        if not isinstance(record["order"], int) or isinstance(record["order"], bool) or record["order"] <= 0:
            raise ValueError("construction order must be a positive integer")
        if record["order"] in orders:
            raise ValueError("construction order must be unique")
        orders.add(record["order"])
        for field in ("part_id", "construction_id"):
            if not isinstance(record[field], str) or not record[field]:
                raise ValueError(f"{field} must be a non-empty string")
        if record["construction_id"] in construction_ids:
            raise ValueError("construction_id must be unique")
        construction_ids.add(record["construction_id"])
        if not isinstance(record["position"], list) or len(record["position"]) != 3 or not all(
            isinstance(axis, int) and not isinstance(axis, bool) for axis in record["position"]
        ):
            raise ValueError("position must contain three integers")
        for field in ("rotation", "scale"):
            if not isinstance(record[field], list) or len(record[field]) != 3:
                raise ValueError(f"{field} must contain three numbers")
            if not all(isinstance(axis, (int, float)) and not isinstance(axis, bool) for axis in record[field]):
                raise ValueError(f"{field} contains a non-numeric value")
            if not all(float(axis) == float(axis) and abs(float(axis)) != float("inf") for axis in record[field]):
                raise ValueError(f"{field} contains a non-finite number")
        for field in ("attachments", "properties"):
            if field in record:
                validate_metadata(record[field])


def validate_metadata(value: Any) -> None:
    if value is None or isinstance(value, (bool, int, float, str)):
        if isinstance(value, float) and not (float("-inf") < value < float("inf")):
            raise ValueError("non-finite float")
        return
    if isinstance(value, list):
        for item in value:
            validate_metadata(item)
        return
    if isinstance(value, dict):
        for key, item in value.items():
            if not isinstance(key, str):
                raise ValueError("canonical dictionaries require string keys")
            validate_metadata(item)
        return
    raise TypeError(f"unsupported Blueprint metadata type: {type(value).__name__}")


def canonical_payload(value: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": value["id"],
        "name": value["name"],
        "version": value["version"],
        "is_prebuilt": value.get("is_prebuilt", False),
        "parts": value["parts"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="data/blueprints/starter_flyer.json")
    parser.add_argument("--output-dir", default="build/blueprint-validation")
    args = parser.parse_args()

    source = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    value = json.loads(source.read_text(encoding="utf-8"))
    if not isinstance(value, dict) or value.get("version") != 1:
        raise ValueError("parity generator requires a v1 source Blueprint")
    migrated = migrate_v1(value)
    validate_normalized(migrated)

    canonical = canonical_encode(canonical_payload(migrated))
    digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    migrated["integrity_hash"] = digest

    (output_dir / "migrated_blueprint.json").write_text(
        json.dumps(migrated, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (output_dir / "canonical.txt").write_text(canonical, encoding="utf-8")
    (output_dir / "sha256.txt").write_text(digest + "\n", encoding="utf-8")
    print(f"Python Blueprint parity SHA-256: {digest}")


if __name__ == "__main__":
    main()
