# ios.toolchain.cmake

cmake_minimum_required(VERSION 3.0)

# Tell CMake we're cross-compiling for iOS.
set(CMAKE_SYSTEM_NAME iOS)

# Get the iOS SDK path using xcrun.
if(NOT DEFINED CMAKE_OSX_SYSROOT)
  execute_process(
    COMMAND xcrun --sdk iphoneos --show-sdk-path
    OUTPUT_VARIABLE SDKROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  set(CMAKE_OSX_SYSROOT ${SDKROOT})
endif()

# Set the minimum iOS deployment target.
set(CMAKE_OSX_DEPLOYMENT_TARGET "7.0")

# Specify the architecture (adjust as needed, e.g., "arm64").
set(CMAKE_OSX_ARCHITECTURES "arm64")

# Set the compilers (adjust paths if needed).
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Ensure that find_* commands look only in the SDK.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

