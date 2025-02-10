#!/bin/bash
set -e

# Paths
UNIVERSAL_LIB="lib/libspatialiteall.a"
HEADERS_DIR="include"
THIN_LIB_DIR="thin_libs"
XCFRAMEWORK_OUTPUT="libspatialite.xcframework"

rm -rf "$THIN_LIB_DIR" "$XCFRAMEWORK_OUTPUT"
mkdir -p "$THIN_LIB_DIR"

# Extract slices
for ARCH in armv7 arm64 i386 x86_64; do
  echo "Extracting ${ARCH}..."
  lipo "$UNIVERSAL_LIB" -thin "$ARCH" -output "${THIN_LIB_DIR}/libspatialite_${ARCH}.a"
done

# Create fat libraries for device and simulator
echo "Creating device library (armv7 & arm64)..."
lipo -create "${THIN_LIB_DIR}/libspatialite_armv7.a" "${THIN_LIB_DIR}/libspatialite_arm64.a" -output "${THIN_LIB_DIR}/libspatialite_device.a"

echo "Creating simulator library (i386 & x86_64)..."
lipo -create "${THIN_LIB_DIR}/libspatialite_i386.a" "${THIN_LIB_DIR}/libspatialite_x86_64.a" -output "${THIN_LIB_DIR}/libspatialite_simulator.a"

# Build the xcframework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
  -library "${THIN_LIB_DIR}/libspatialite_device.a" -headers "$HEADERS_DIR" \
  -library "${THIN_LIB_DIR}/libspatialite_simulator.a" -headers "$HEADERS_DIR" \
  -output "$XCFRAMEWORK_OUTPUT"

echo "XCFramework created at $XCFRAMEWORK_OUTPUT"
