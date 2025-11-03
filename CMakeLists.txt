cmake_minimum_required(VERSION 3.21)
project(godot-ink-native VERSION 0.1.0 LANGUAGES CXX)

# ==============================================================================
# Project Configuration
# ==============================================================================

# Set C++17 standard (required by inkcpp)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Godot version to build for (4.4 or 4.5)
set(GODOT_VERSION "4.4" CACHE STRING "Godot version to build for (4.4 or 4.5)")
set_property(CACHE GODOT_VERSION PROPERTY STRINGS "4.4" "4.5")

# Validate GODOT_VERSION
if(NOT GODOT_VERSION MATCHES "^(4\\.4|4\\.5)$")
    message(FATAL_ERROR "Unsupported GODOT_VERSION: ${GODOT_VERSION}. Supported versions: 4.4, 4.5")
endif()

# ==============================================================================
# Platform Detection
# ==============================================================================

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(GODOT_PLATFORM "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(GODOT_PLATFORM "windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(GODOT_PLATFORM "macos")
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

# Determine architecture
set(GODOT_ARCH "x86_64")
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(BITS 64)
else()
    set(BITS 32)
endif()

# Determine build type suffix
if(CMAKE_BUILD_TYPE MATCHES Debug)
    set(GODOT_BUILD_TYPE "template_debug")
else()
    set(GODOT_BUILD_TYPE "template_release")
endif()

# ==============================================================================
# Inklecate Binary Download
# ==============================================================================

# Configuration options
set(INKLECATE_VERSION "v.1.2.0" CACHE STRING "Inklecate version to download (e.g., v.1.2.0)")
option(INKLECATE_AUTO_DOWNLOAD "Automatically download inklecate binary" ON)

if(INKLECATE_AUTO_DOWNLOAD)
    # Determine platform-specific download name
    if(GODOT_PLATFORM STREQUAL "linux")
        set(INKLECATE_PLATFORM "linux")
        set(INKLECATE_EXECUTABLE "inklecate")
    elseif(GODOT_PLATFORM STREQUAL "windows")
        set(INKLECATE_PLATFORM "windows")
        set(INKLECATE_EXECUTABLE "inklecate.exe")
    elseif(GODOT_PLATFORM STREQUAL "macos")
        set(INKLECATE_PLATFORM "mac")
        set(INKLECATE_EXECUTABLE "inklecate")
    endif()

    # Set paths
    set(INKLECATE_DIR "${CMAKE_SOURCE_DIR}/bin")
    set(INKLECATE_ZIP "${INKLECATE_DIR}/inklecate_${INKLECATE_PLATFORM}.zip")
    set(INKLECATE_PATH "${INKLECATE_DIR}/${INKLECATE_EXECUTABLE}")

    # Download URL
    set(INKLECATE_URL "https://github.com/inkle/ink/releases/download/${INKLECATE_VERSION}/inklecate_${INKLECATE_PLATFORM}.zip")

    # Check if inklecate already exists
    if(NOT EXISTS "${INKLECATE_PATH}")
        message(STATUS "Downloading inklecate ${INKLECATE_VERSION} for ${INKLECATE_PLATFORM}...")

        # Create bin directory
        file(MAKE_DIRECTORY "${INKLECATE_DIR}")

        # Download the zip file
        file(DOWNLOAD
            "${INKLECATE_URL}"
            "${INKLECATE_ZIP}"
            SHOW_PROGRESS
            STATUS DOWNLOAD_STATUS
        )

        # Check download status
        list(GET DOWNLOAD_STATUS 0 STATUS_CODE)
        list(GET DOWNLOAD_STATUS 1 STATUS_MESSAGE)

        if(NOT STATUS_CODE EQUAL 0)
            message(WARNING "Failed to download inklecate: ${STATUS_MESSAGE}")
            message(WARNING "URL: ${INKLECATE_URL}")
            message(WARNING "You can manually download and extract it to: ${INKLECATE_DIR}")
        else()
            message(STATUS "Download complete. Extracting...")

            # Extract the zip file
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E tar xf "${INKLECATE_ZIP}"
                WORKING_DIRECTORY "${INKLECATE_DIR}"
                RESULT_VARIABLE EXTRACT_RESULT
            )

            if(NOT EXTRACT_RESULT EQUAL 0)
                message(WARNING "Failed to extract inklecate archive")
            else()
                # Set executable permissions on Unix platforms
                if(NOT GODOT_PLATFORM STREQUAL "windows")
                    execute_process(
                        COMMAND chmod +x "${INKLECATE_PATH}"
                        RESULT_VARIABLE CHMOD_RESULT
                    )
                    if(NOT CHMOD_RESULT EQUAL 0)
                        message(WARNING "Failed to set executable permissions on inklecate")
                    endif()
                endif()

                # Clean up zip file
                file(REMOVE "${INKLECATE_ZIP}")

                message(STATUS "✅ Inklecate ${INKLECATE_VERSION} installed to: ${INKLECATE_PATH}")
            endif()
        endif()
    else()
        message(STATUS "Using existing inklecate binary: ${INKLECATE_PATH}")
    endif()

    # Store the path for use in future build steps
    set(INKLECATE_BINARY "${INKLECATE_PATH}" CACHE FILEPATH "Path to inklecate binary" FORCE)
endif()

# ==============================================================================
# Build InkCPP Library
# ==============================================================================

message(STATUS "Building inkcpp library...")

# Disable inkcpp optional components
set(INKCPP_PY OFF CACHE BOOL "Disable Python bindings" FORCE)
set(INKCPP_C OFF CACHE BOOL "Disable C bindings" FORCE)
set(INKCPP_TEST OFF CACHE BOOL "Disable tests" FORCE)

# Add inkcpp subdirectory
add_subdirectory(libs/inkcpp EXCLUDE_FROM_ALL)

# ==============================================================================
# Build Godot-CPP Bindings
# ==============================================================================

message(STATUS "Building godot-cpp for Godot ${GODOT_VERSION}...")

# Determine which godot-cpp subdirectory to use
set(GODOT_CPP_DIR "libs/godot/godot-cpp-${GODOT_VERSION}")

# Verify the directory exists
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${GODOT_CPP_DIR}")
    message(FATAL_ERROR "godot-cpp directory not found: ${GODOT_CPP_DIR}. Please initialize submodules.")
endif()

# Enable exceptions for godot-cpp (required by inkcpp)
# This must be set before adding the subdirectory
if(GODOT_VERSION STREQUAL "4.4")
    set(GODOTCPP_DISABLE_EXCEPTIONS OFF CACHE BOOL "Enable exceptions for inkcpp compatibility" FORCE)
endif()

# Add godot-cpp subdirectory
add_subdirectory(${GODOT_CPP_DIR} EXCLUDE_FROM_ALL)

# ==============================================================================
# Build Godot-Ink Extension
# ==============================================================================

message(STATUS "Building godot-ink extension...")

# Collect source files
file(GLOB_RECURSE SOURCES
    "src/*.cpp"
    "src/*.c"
)

file(GLOB_RECURSE HEADERS
    "src/*.h"
    "src/*.hpp"
)

# Create shared library
add_library(${PROJECT_NAME} SHARED
    ${SOURCES}
    ${HEADERS}
)

# Set library name without 'lib' prefix on non-Windows platforms
set_target_properties(${PROJECT_NAME} PROPERTIES
    PREFIX ""
    OUTPUT_NAME "libgodot_ink.${GODOT_VERSION}.${GODOT_PLATFORM}.${GODOT_BUILD_TYPE}.${GODOT_ARCH}"
)

# macOS framework bundle handling
if(GODOT_PLATFORM STREQUAL "macos")
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "libgodot_ink.${GODOT_VERSION}.${GODOT_PLATFORM}.${GODOT_BUILD_TYPE}"
        FRAMEWORK TRUE
        MACOSX_FRAMEWORK_IDENTIFIER "com.godot.ink"
        MACOSX_FRAMEWORK_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING "${PROJECT_VERSION}"
    )
endif()

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/libs/inkcpp/inkcpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/libs/inkcpp/inkcpp_compiler/include
    ${CMAKE_CURRENT_SOURCE_DIR}/libs/inkcpp/shared/public
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    godot-cpp
    inkcpp
    inkcpp_compiler
)

# ==============================================================================
# Release Target - Package Addon
# ==============================================================================

# Configure ink.gdextension with the correct GODOT_VERSION
configure_file(
    "${CMAKE_SOURCE_DIR}/addon/ink.gdextension.in"
    "${CMAKE_BINARY_DIR}/ink.gdextension"
    @ONLY
)

# Custom target: release
# Creates a distributable addon package in release/
add_custom_target(release
    # Create directories
    COMMAND ${CMAKE_COMMAND} -E echo "Creating release package for Godot ${GODOT_VERSION}..."
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/release"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/package"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/package/bin"

    # Copy addon source files (excluding .in template)
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_SOURCE_DIR}/addon"
        "${CMAKE_BINARY_DIR}/package"

    # Copy the configured ink.gdextension file (overwriting the .in template)
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_BINARY_DIR}/ink.gdextension"
        "${CMAKE_BINARY_DIR}/package/ink.gdextension"

    # Remove the .in template file from the package
    COMMAND ${CMAKE_COMMAND} -E remove
        "${CMAKE_BINARY_DIR}/package/ink.gdextension.in"

    # Copy binary
    COMMAND ${CMAKE_COMMAND} -E echo "Copying binary: $<TARGET_FILE_NAME:${PROJECT_NAME}>"

    # For macOS frameworks, copy the entire framework bundle; for libraries, copy the file
    COMMAND ${CMAKE_COMMAND} -E
        $<IF:$<STREQUAL:${GODOT_PLATFORM},macos>,copy_directory,copy>
        "$<IF:$<STREQUAL:${GODOT_PLATFORM},macos>,$<TARGET_BUNDLE_DIR:${PROJECT_NAME}>,$<TARGET_FILE:${PROJECT_NAME}>>"
        "${CMAKE_BINARY_DIR}/package/bin/$<TARGET_FILE_NAME:${PROJECT_NAME}>"

    # Copy inklecate binary if available (for GDInkCompiler tool)
    COMMAND ${CMAKE_COMMAND} -E echo "Checking for inklecate binary..."
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/bin/${INKLECATE_EXECUTABLE}"
        "${CMAKE_BINARY_DIR}/package/bin/${INKLECATE_EXECUTABLE}"

    # Copy DLLs if they exist (Windows and macOS)
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/bin/ink_compiler.dll"
        "${CMAKE_BINARY_DIR}/package/bin/ink_compiler.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/bin/ink-engine-runtime.dll"
        "${CMAKE_BINARY_DIR}/package/bin/ink-engine-runtime.dll"

    # Create zip archive with platform-specific naming
    # Archive contents of package directory, not the directory itself
    COMMAND ${CMAKE_COMMAND} -E chdir "${CMAKE_BINARY_DIR}/package"
        ${CMAKE_COMMAND} -E tar "cfv"
        "${CMAKE_SOURCE_DIR}/release/godot-ink-${PROJECT_VERSION}-godot${GODOT_VERSION}-${GODOT_PLATFORM}$<$<NOT:$<STREQUAL:${GODOT_PLATFORM},macos>>:-${GODOT_ARCH}>.zip"
        --format=zip
        .

    COMMAND ${CMAKE_COMMAND} -E echo "✅ Package created: release/godot-ink-${PROJECT_VERSION}-godot${GODOT_VERSION}-${GODOT_PLATFORM}.zip"

    DEPENDS ${PROJECT_NAME}
    COMMENT "Packaging addon for distribution"
    VERBATIM
)

# ==============================================================================
# Compiler Flags
# ==============================================================================

# Platform-specific compiler flags
if(MSVC)
    # Visual Studio
    target_compile_options(${PROJECT_NAME} PRIVATE
        /W4          # Warning level 4
        /EHsc        # Exception handling
    )
else()
    # GCC/Clang
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -Wno-unused-parameter
        -fexceptions        # Enable exception handling (required by inkcpp)
    )
endif()

# Enable exceptions for inkcpp (required for error handling)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    INKCPP_EXCEPTIONS_ENABLED
)

# ==============================================================================
# Summary
# ==============================================================================

message(STATUS "")
message(STATUS "=== Godot Ink Native Configuration ===")
message(STATUS "Godot Version:  ${GODOT_VERSION}")
message(STATUS "Platform:       ${GODOT_PLATFORM}")
message(STATUS "Architecture:   ${GODOT_ARCH}")
message(STATUS "Build Type:     ${CMAKE_BUILD_TYPE} (${GODOT_BUILD_TYPE})")
if(GODOT_PLATFORM STREQUAL "macos")
    message(STATUS "Output Library: libgodot_ink.${GODOT_VERSION}.${GODOT_PLATFORM}.${GODOT_BUILD_TYPE}.framework")
else()
    message(STATUS "Output Library: libgodot_ink.${GODOT_VERSION}.${GODOT_PLATFORM}.${GODOT_BUILD_TYPE}.${GODOT_ARCH}")
endif()
message(STATUS "Output Dir:     ${CMAKE_BINARY_DIR}")
message(STATUS "===================================")
message(STATUS "")
