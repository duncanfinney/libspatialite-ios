# ios.toolchain.cmake

cmake_minimum_required(VERSION 3.5)

# Tell CMake we're cross-compiling for iOS.
set(CMAKE_SYSTEM_NAME iOS)

# Get the iOS SDK path using xcrun.
if(NOT DEFINED CMAKE_OSX_SYSROOT)
  message(FATAL_ERROR "CMAKE_OSX_SYSROOT must be specified. Please pass -DCMAKE_OSX_SYSROOT=(xcrun --sdk <iphoneos or iphonesimulator> --show-sdk-path) on the command line.")
endif()

# Set the minimum iOS deployment target.
set(CMAKE_OSX_DEPLOYMENT_TARGET "7.0")

# Specify the architecture (adjust as needed, e.g., "arm64").
# Ensure that CMAKE_OSX_ARCHITECTURES is provided by the user.
if(NOT DEFINED CMAKE_OSX_ARCHITECTURES)
  message(FATAL_ERROR "CMAKE_OSX_ARCHITECTURES must be specified. Please pass -DCMAKE_OSX_ARCHITECTURES=<architecture> on the command line.")
endif()


# Set the compilers (adjust paths if needed).
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Ensure that find_* commands look only in the SDK.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

