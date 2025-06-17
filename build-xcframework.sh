#!/bin/bash
set -eo pipefail

# This script combines each arch/platform into its own libspatialite.a
# under merged/<slice>/ and then builds a single .xcframework.

# 1) copy headers from the first build tuple into include/
FIRST_BUILD_TUPLE=$(ls build | head -n1)
rm -rf include && mkdir -p include
cp -r build/$FIRST_BUILD_TUPLE/include/ include/

# 2) prepare directories
BUILD_DIR="./build"
OUT_DIR="./merged"
XCFRAMEWORK_OUTPUT="libspatialite.xcframework"

rm -rf "$OUT_DIR" "$XCFRAMEWORK_OUTPUT"
mkdir -p "$OUT_DIR"

yellow(){ echo -e "\033[33m$1\033[0m"; }

#------------------------------------------------------------------------------
# Device (iOS arm64)
yellow "Merging iOS device (arm64)…"
mkdir -p "$OUT_DIR/ios-arm64"
libtool -static -o "$OUT_DIR/ios-arm64/libspatialite.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libgeos.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libproj.a"

#------------------------------------------------------------------------------
# Simulator (iOS arm64 simulator)
yellow "Merging iOS simulator (arm64)…"
mkdir -p "$OUT_DIR/ios-arm64-simulator"
libtool -static -o "$OUT_DIR/ios-arm64-simulator/libspatialite.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libgeos.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libproj.a"

#------------------------------------------------------------------------------
# macOS (arm64)
yellow "Merging macOS (arm64)…"
mkdir -p "$OUT_DIR/macos-arm64"
libtool -static -o "$OUT_DIR/macos-arm64/libspatialite.a" \
  "$BUILD_DIR/arm64-MacOSX/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-MacOSX/lib/libgeos.a" \
  "$BUILD_DIR/arm64-MacOSX/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-MacOSX/lib/libproj.a"

#------------------------------------------------------------------------------
# watchOS Device (armv7k + arm64_32 + arm64)
yellow "Merging watchOS device (armv7k, arm64_32, arm64)…"
mkdir -p "$OUT_DIR/watchos-device"
# first create per-arch static libs
libtool -static -o "$OUT_DIR/watchos-device/armv7k.a" \
  "$BUILD_DIR/armv7k-AppleWatchOS/lib/libspatialite.a" \
  "$BUILD_DIR/armv7k-AppleWatchOS/lib/libgeos.a" \
  "$BUILD_DIR/armv7k-AppleWatchOS/lib/libgeos_c.a" \
  "$BUILD_DIR/armv7k-AppleWatchOS/lib/libproj.a"
libtool -static -o "$OUT_DIR/watchos-device/arm64_32.a" \
  "$BUILD_DIR/arm64_32-AppleWatchOS/lib/libspatialite.a" \
  "$BUILD_DIR/arm64_32-AppleWatchOS/lib/libgeos.a" \
  "$BUILD_DIR/arm64_32-AppleWatchOS/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64_32-AppleWatchOS/lib/libproj.a"
libtool -static -o "$OUT_DIR/watchos-device/arm64.a" \
  "$BUILD_DIR/arm64-AppleWatchOS/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-AppleWatchOS/lib/libgeos.a" \
  "$BUILD_DIR/arm64-AppleWatchOS/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-AppleWatchOS/lib/libproj.a"
# then fat-combine
lipo -create \
  "$OUT_DIR/watchos-device/armv7k.a" \
  "$OUT_DIR/watchos-device/arm64_32.a" \
  "$OUT_DIR/watchos-device/arm64.a" \
  -output "$OUT_DIR/watchos-device/libspatialite.a"

#------------------------------------------------------------------------------
# watchOS Simulator (arm64)
yellow "Merging watchOS simulator (arm64)…"
mkdir -p "$OUT_DIR/watchos-simulator"
libtool -static -o "$OUT_DIR/watchos-simulator/libspatialite.a" \
  "$BUILD_DIR/arm64-AppleWatchSimulator/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-AppleWatchSimulator/lib/libgeos.a" \
  "$BUILD_DIR/arm64-AppleWatchSimulator/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-AppleWatchSimulator/lib/libproj.a"

#------------------------------------------------------------------------------
# Build the XCFramework
yellow "Creating XCFramework…"
xcodebuild -create-xcframework \
  -library "$OUT_DIR/ios-arm64/libspatialite.a"         -headers "$BUILD_DIR/arm64-iPhoneOS/include" \
  -library "$OUT_DIR/ios-arm64-simulator/libspatialite.a" -headers "$BUILD_DIR/arm64-iPhoneSimulator/include" \
  -library "$OUT_DIR/macos-arm64/libspatialite.a"        -headers "$BUILD_DIR/arm64-MacOSX/include" \
  -library "$OUT_DIR/watchos-device/libspatialite.a"     -headers "$BUILD_DIR/armv7k-AppleWatchOS/include" \
  -library "$OUT_DIR/watchos-simulator/libspatialite.a"  -headers "$BUILD_DIR/arm64-AppleWatchSimulator/include" \
  -output "$XCFRAMEWORK_OUTPUT"

echo
yellow "✅ XCFramework created at: $XCFRAMEWORK_OUTPUT"