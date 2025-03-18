cmake_minimum_required(VERSION 3.15)
# Target watchOS
set(CMAKE_SYSTEM_NAME watchos)
set(CMAKE_SYSTEM_VERSION "2.0")
set(CMAKE_OSX_DEPLOYMENT_TARGET "2.0")

# Locate the watchOS SDK
execute_process(
  COMMAND xcrun --sdk watchos --show-sdk-path
  OUTPUT_VARIABLE SDK_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(CMAKE_OSX_SYSROOT ${SDK_PATH})

# Default architecture (override if needed)
if(NOT DEFINED CMAKE_OSX_ARCHITECTURES)
  set(CMAKE_OSX_ARCHITECTURES "armv7k" CACHE STRING "WatchOS architecture" FORCE)
endif()

# Set compilers via xcrun
execute_process(
  COMMAND xcrun --find clang
  OUTPUT_VARIABLE CMAKE_C_COMPILER
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND xcrun --find clang++
  OUTPUT_VARIABLE CMAKE_CXX_COMPILER
  OUTPUT_STRIP_TRAILING_WHITESPACE
)