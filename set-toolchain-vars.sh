#!/bin/bash
# set -euo pipefail
set -u

# Just sets the shell variables similar to the makefile
# TO USE: copy and paste it into the terminal honestly

export CURDIR="/Users/duncanfinney/SwiftPlay/spatialite-play/libspatialite-ios"

export XCODE_DEVELOPER="$(xcode-select --print-path)"
export ARCH=arm64
export IOS_PLATFORM=iPhoneOS

export PREFIX=${CURDIR}/build/${ARCH}
export LIBDIR=${PREFIX}/lib
export BINDIR=${PREFIX}/bin
export INCLUDEDIR=${PREFIX}/include

# Pick latest SDK in the directory
export IOS_PLATFORM_DEVELOPER=${XCODE_DEVELOPER}/Platforms/${IOS_PLATFORM}.platform/Developer
export IOS_SDK=${IOS_PLATFORM_DEVELOPER}/SDKs/$(ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1)

export CXX=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
export CC=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
export CFLAGS="-isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -miphoneos-version-min=7.0 -O3"
export CXXFLAGS="-stdlib=libc++ -std=c++11 -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -miphoneos-version-min=7.0 -O3"
export LDFLAGS="-stdlib=libc++ -isysroot ${IOS_SDK} -L${LIBDIR} -L${IOS_SDK}/usr/lib -arch ${ARCH} -miphoneos-version-min=7.0"
