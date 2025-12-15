cmake_minimum_required(VERSION 3.20)
project(ProjectMythos)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(CTest)

get_filename_component(MYTHOS_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../.. ABSOLUTE)

# Example: add RTDink / Proton as subdirectories if present
# add_subdirectory(${MYTHOS_ROOT}/engine_core/RTDink)
# add_subdirectory(${MYTHOS_ROOT}/engine_core/proton)

set(MYTHOS_CORE_SRC
    ${MYTHOS_ROOT}/game/CombatSystem.cpp
    ${MYTHOS_ROOT}/game/CraftingSystem.cpp
    ${MYTHOS_ROOT}/game/GameCore.cpp
    ${MYTHOS_ROOT}/game/MonsterTamer.cpp
    ${MYTHOS_ROOT}/game/PlayerController.cpp
    ${MYTHOS_ROOT}/game/QuestManager.cpp
    ${MYTHOS_ROOT}/game/WorldGen.cpp
)

add_library(MythosCore STATIC ${MYTHOS_CORE_SRC})
target_include_directories(MythosCore PUBLIC
    ${MYTHOS_ROOT}/game/include
    # ${MYTHOS_ROOT}/engine_core/RTDink/include
    # ${MYTHOS_ROOT}/engine_core/proton/shared
)

add_executable(ProjectMythos ${MYTHOS_ROOT}/game/main.cpp)
target_link_libraries(ProjectMythos PRIVATE MythosCore)

# Link with engine libs when available
# target_link_libraries(MythosCore PUBLIC RTDinkLib ProtonLib)
# target_link_libraries(ProjectMythos PRIVATE ProtonLib)

if(BUILD_TESTING)
    file(GLOB TEST_SOURCES "${MYTHOS_ROOT}/tests/*.cpp")
    if(TEST_SOURCES)
        add_executable(ProjectMythosTests ${TEST_SOURCES})
        target_link_libraries(ProjectMythosTests PRIVATE MythosCore)
        add_test(NAME ProjectMythosTests COMMAND ProjectMythosTests)
    endif()
endif()

if(ANDROID)
    message(STATUS "Building for Android")
else()
    message(STATUS "Building for Desktop")
endif()
