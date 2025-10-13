# Project Mythos — Scaffold

This is a starter scaffold to build a new game on top of RTDink/Proton.
It includes:
- Build configs (CMake + Android Gradle)
- Core gameplay class skeletons
- Asset directory layout
- Theme Bible
- Codex Prompt Pack (for codegen in stages)

## Getting Started

1) Add the RTDink engine as a submodule (or reference path) and Proton SDK:
```
git submodule add https://github.com/SethRobinson/RTDink engine_core/RTDink
git submodule add https://github.com/SethRobinson/proton engine_core/proton
```
2) Adjust include/link paths in `build/cmake/CMakeLists.txt` as needed (see comments).
3) Build (desktop example):
```
mkdir -p build/out && cd build/out
cmake ../cmake && cmake --build .
```
4) Android: open `build/android` in Android Studio or use Gradle CLI.

## Licensing
- Ensure you comply with RTDink/Proton licenses.
- Replace any non-OSS assets before publishing.
