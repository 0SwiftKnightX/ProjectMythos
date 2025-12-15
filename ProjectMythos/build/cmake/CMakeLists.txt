cmake_minimum_required(VERSION 3.20)
project(ProjectMythos LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

get_filename_component(PROJECTMYTHOS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)

function(pm_define_path_cache variable default_value docstring)
    if(NOT DEFINED ${variable} OR "${${variable}}" STREQUAL "")
        set(${variable} "${default_value}" CACHE PATH "${docstring}")
    else()
        set(${variable} "${${variable}}" CACHE PATH "${docstring}")
    endif()
endfunction()

pm_define_path_cache("ENGINE_CORE_ROOT" "${PROJECTMYTHOS_ROOT}/engine_core" "Root directory that contains the RTDink and Proton submodules")
pm_define_path_cache("RTDINK_ROOT" "${ENGINE_CORE_ROOT}/RTDink" "Location of the RTDink engine source tree")
pm_define_path_cache("PROTON_ROOT" "${ENGINE_CORE_ROOT}/proton" "Location of the Proton SDK source tree")

set(RTDINK_ADDITIONAL_INCLUDE_DIRS "" CACHE STRING "Optional, semicolon-separated list of extra RTDink include directories")
set(PROTON_ADDITIONAL_INCLUDE_DIRS "" CACHE STRING "Optional, semicolon-separated list of extra Proton include directories")
set(RTDINK_LIBRARIES "" CACHE STRING "Optional, semicolon-separated list of prebuilt RTDink libraries to link")
set(PROTON_LIBRARIES "" CACHE STRING "Optional, semicolon-separated list of prebuilt Proton libraries to link")

function(pm_collect_dependency name root include_subdirs library_names out_includes out_libraries)
    if(NOT IS_DIRECTORY "${root}")
        set(${out_includes} "" PARENT_SCOPE)
        set(${out_libraries} "" PARENT_SCOPE)
        return()
    endif()

    set(collected_includes "")
    foreach(subdir IN LISTS include_subdirs)
        if(subdir STREQUAL "")
            set(candidate "${root}")
        else()
            set(candidate "${root}/${subdir}")
        endif()

        if(IS_DIRECTORY "${candidate}")
            list(APPEND collected_includes "${candidate}")
        endif()
    endforeach()

    set(collected_libraries "")
    foreach(library_name IN LISTS library_names)
        if(library_name STREQUAL "")
            continue()
        endif()

        string(MAKE_C_IDENTIFIER "${name}_${library_name}_LIB" cache_var)

        if(NOT DEFINED ${cache_var} OR NOT ${cache_var})
            find_library(${cache_var}
                NAMES ${library_name}
                HINTS
                    "${root}"
                    "${root}/lib"
                    "${root}/libs"
                    "${root}/build"
                    "${root}/build/lib"
                    "${CMAKE_BINARY_DIR}/${name}"
                    "${CMAKE_BINARY_DIR}/engine_core/${name}"
                PATH_SUFFIXES
                    lib
                    libs
                    build
                    build/Release
                    build/Debug
                    build/lib
                NO_DEFAULT_PATH
            )
        endif()

        if(${cache_var})
            list(APPEND collected_libraries "${${cache_var}}")
        endif()
    endforeach()

    list(REMOVE_DUPLICATES collected_includes)
    list(REMOVE_DUPLICATES collected_libraries)

    set(${out_includes} "${collected_includes}" PARENT_SCOPE)
    set(${out_libraries} "${collected_libraries}" PARENT_SCOPE)
endfunction()

file(GLOB GAME_SRC "${PROJECTMYTHOS_ROOT}/game/*.cpp")
add_executable(ProjectMythos ${GAME_SRC})

target_include_directories(ProjectMythos PRIVATE
    ${PROJECTMYTHOS_ROOT}/game/include
)

set(engine_include_dirs "")
set(engine_libraries "")

set(rtdink_include_dirs "")

set(rtdink_include_candidates
    ""
    include
    src
    shared
    shared/include
    shared/src
)

set(rtdink_library_candidates
    RTDink
    RTDinkLib
    rtdink
    rtdink_static
)

pm_collect_dependency("RTDink" "${RTDINK_ROOT}" rtdink_include_candidates rtdink_library_candidates RTDINK_DETECTED_INCLUDES RTDINK_DETECTED_LIBS)

if(RTDINK_DETECTED_INCLUDES)
    list(APPEND rtdink_include_dirs ${RTDINK_DETECTED_INCLUDES})
    message(STATUS "RTDink include directories: ${RTDINK_DETECTED_INCLUDES}")
elseif(IS_DIRECTORY "${RTDINK_ROOT}")
    message(STATUS "RTDink root found at ${RTDINK_ROOT} but no standard include directories detected. Use RTDINK_ADDITIONAL_INCLUDE_DIRS to specify them explicitly.")
else()
    message(STATUS "RTDink root not present at ${RTDINK_ROOT}; skipping automatic include wiring.")
endif()

if(RTDINK_LIBRARIES)
    separate_arguments(_rtdink_manual_libs UNIX_COMMAND "${RTDINK_LIBRARIES}")
    list(APPEND engine_libraries ${_rtdink_manual_libs})
elseif(RTDINK_DETECTED_LIBS)
    list(APPEND engine_libraries ${RTDINK_DETECTED_LIBS})
else()
    if(IS_DIRECTORY "${RTDINK_ROOT}")
        message(STATUS "RTDink libraries were not located automatically. Set RTDINK_LIBRARIES to the built libraries once available.")
    endif()
endif()

set(proton_include_candidates
    ""
    shared
    shared/include
    shared/api
    shared/gamecode
    shared/network
)

set(proton_library_candidates
    Proton
    proton
    ProtonSDK
    proton_static
)

pm_collect_dependency("proton" "${PROTON_ROOT}" proton_include_candidates proton_library_candidates PROTON_DETECTED_INCLUDES PROTON_DETECTED_LIBS)

if(PROTON_DETECTED_INCLUDES)
    list(APPEND engine_include_dirs ${PROTON_DETECTED_INCLUDES})
    message(STATUS "Proton include directories: ${PROTON_DETECTED_INCLUDES}")
elseif(IS_DIRECTORY "${PROTON_ROOT}")
    message(STATUS "Proton root found at ${PROTON_ROOT} but no standard include directories detected. Use PROTON_ADDITIONAL_INCLUDE_DIRS to specify them explicitly.")
else()
    message(STATUS "Proton root not present at ${PROTON_ROOT}; skipping automatic include wiring.")
endif()

if(PROTON_LIBRARIES)
    separate_arguments(_proton_manual_libs UNIX_COMMAND "${PROTON_LIBRARIES}")
    list(APPEND engine_libraries ${_proton_manual_libs})
elseif(PROTON_DETECTED_LIBS)
    list(APPEND engine_libraries ${PROTON_DETECTED_LIBS})
else()
    if(IS_DIRECTORY "${PROTON_ROOT}")
        message(STATUS "Proton libraries were not located automatically. Set PROTON_LIBRARIES to the built libraries once available.")
    endif()
endif()

if(RTDINK_ADDITIONAL_INCLUDE_DIRS)
    separate_arguments(_rtdink_extra_includes UNIX_COMMAND "${RTDINK_ADDITIONAL_INCLUDE_DIRS}")
    list(APPEND rtdink_include_dirs ${_rtdink_extra_includes})
endif()

if(rtdink_include_dirs)
    list(REMOVE_DUPLICATES rtdink_include_dirs)
    list(APPEND engine_include_dirs ${rtdink_include_dirs})
endif()

if(PROTON_ADDITIONAL_INCLUDE_DIRS)
    separate_arguments(_proton_extra_includes UNIX_COMMAND "${PROTON_ADDITIONAL_INCLUDE_DIRS}")
    list(APPEND engine_include_dirs ${_proton_extra_includes})
endif()

if(engine_include_dirs)
    list(REMOVE_DUPLICATES engine_include_dirs)
    target_include_directories(ProjectMythos PRIVATE ${engine_include_dirs})
endif()

if(engine_libraries)
    list(REMOVE_DUPLICATES engine_libraries)
    target_link_libraries(ProjectMythos PRIVATE ${engine_libraries})
endif()

if(rtdink_include_dirs)
    target_compile_definitions(ProjectMythos PRIVATE PROJECTMYTHOS_HAS_ENGINE=1)
else()
    target_compile_definitions(ProjectMythos PRIVATE PROJECTMYTHOS_HAS_ENGINE=0)
    message(STATUS "Building without RTDink/Proton engine integration; GameCore stubs will be used.")
endif()

if(ANDROID)
    message(STATUS "Building for Android")
else()
    message(STATUS "Building for Desktop")
endif()
