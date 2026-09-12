# Project Mythos — Blueprint Sandbox Prototype

This Godot 4.3 project is a mobile-first vertical slice for the data-driven
Blueprint/Summon vehicle workflow. A Blueprint is the persistent source of
truth; a runtime vehicle is reconstructed from its ordered construction records.

## Run locally

1. Install Godot 4.3 or newer.
2. Import the repository root (`project.godot`) into the Godot Project Manager.
3. Run `scenes/Game.tscn`. Tap **Build Area**, select **Block** or
   **Propeller**, and tap the build plane to place it. Tap existing parts to
   select them; drag a selected part to move it.
4. Use **Save**, **Play**, or return to **Home World** and use **Summon**.
   Blueprints are stored as inspectable JSON under `user://blueprints`.

For Android, install the Godot Android export templates and configure an Android
SDK/JDK in Godot's Editor Settings, then export using the Android preset. The
project uses the mobile compatibility renderer to keep the initial prototype
lightweight.

## Architecture

* `scenes/worlds/` contains separate Home World, Build Area, and Lobby contexts.
* `scripts/blueprint/` owns versioned, ordered JSON recipes and persistence.
* `scripts/build/` contains deterministic one-third-meter snapping, part
  registration, touch placement, and reconstruction.
* `scripts/vehicles/` builds `RigidBody3D` runtime vehicles and applies each
  propeller's local-axis thrust at its placement position.
* `data/blueprints/` contains prebuilt recipes that use exactly the same format
  as player-created Blueprints.

## Checks

```sh
python3 tests/test_blueprint_contract.py
cmake -S ProjectMythos/build/cmake -B /tmp/projectmythos-cmake-build -DBUILD_TESTING=ON
cmake --build /tmp/projectmythos-cmake-build --parallel
ctest --test-dir /tmp/projectmythos-cmake-build --output-on-failure
```
