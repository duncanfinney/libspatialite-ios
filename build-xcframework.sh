#!/bin/bash
set -eo pipefail

# This script combines everything into two static libs (iPhoneSimulator and iPhoneOS) and puts both into an xcframework file

# ex: arm64-iPhoneOS
FIRST_BUILD_TUPLE=$(ls build | head -n 1)
mkdir -p lib include
cp -r build/$FIRST_BUILD_TUPLE/include/ include/

#!/bin/bash
set -e

# Directories (adjust if needed)
BUILD_DIR="./build"
OUT_DIR="./merged"
XCFRAMEWORK_OUTPUT="libspatialite.xcframework"

mkdir -p "$OUT_DIR"

#------------------------------------------------------------------------------
# Merge the four libraries for each platform variant.
# For device, merge arm64, armv7 and armv7s:
echo "Merging device libraries..."
libtool -static -o "$OUT_DIR/merged-arm64-iPhoneOS.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libgeos.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-iPhoneOS/lib/libproj.a" \
#   "$BUILD_DIR/arm64-iPhoneOS/lib/libsqlite3.a"

libtool -static -o "$OUT_DIR/merged-armv7-iPhoneOS.a" \
  "$BUILD_DIR/armv7-iPhoneOS/lib/libspatialite.a" \
  "$BUILD_DIR/armv7-iPhoneOS/lib/libgeos.a" \
  "$BUILD_DIR/armv7-iPhoneOS/lib/libgeos_c.a" \
  "$BUILD_DIR/armv7-iPhoneOS/lib/libproj.a" \
#   "$BUILD_DIR/armv7-iPhoneOS/lib/libsqlite3.a"

libtool -static -o "$OUT_DIR/merged-armv7s-iPhoneOS.a" \
  "$BUILD_DIR/armv7s-iPhoneOS/lib/libspatialite.a" \
  "$BUILD_DIR/armv7s-iPhoneOS/lib/libgeos.a" \
  "$BUILD_DIR/armv7s-iPhoneOS/lib/libgeos_c.a" \
  "$BUILD_DIR/armv7s-iPhoneOS/lib/libproj.a" \
#   "$BUILD_DIR/armv7s-iPhoneOS/lib/libsqlite3.a"

# Create a fat device library from the device builds:
lipo -create \
  "$OUT_DIR/merged-arm64-iPhoneOS.a" \
  "$OUT_DIR/merged-armv7-iPhoneOS.a" \
  "$OUT_DIR/merged-armv7s-iPhoneOS.a" \
  -output "$OUT_DIR/merged-device.a"

# For simulator, merge the simulator libraries (here we have just arm64):
echo "Merging simulator libraries..."
libtool -static -o "$OUT_DIR/merged-arm64-iPhoneSimulator.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libspatialite.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libgeos.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libgeos_c.a" \
  "$BUILD_DIR/arm64-iPhoneSimulator/lib/libproj.a" \
#   "$BUILD_DIR/arm64-iPhoneSimulator/lib/libsqlite3.a"

# (If you have more simulator slices, use lipo to create a fat simulator lib.)
cp "$OUT_DIR/merged-arm64-iPhoneSimulator.a" "$OUT_DIR/merged-simulator.a"

#------------------------------------------------------------------------------
# Create the XCFramework.
# We assume the public headers are identical; here we use the device headers.
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
  -library "$OUT_DIR/merged-device.a" -headers "$BUILD_DIR/arm64-iPhoneOS/include" \
  -library "$OUT_DIR/merged-simulator.a" -headers "$BUILD_DIR/arm64-iPhoneSimulator/include" \
  -output "$XCFRAMEWORK_OUTPUT"

echo "XCFramework created at: $XCFRAMEWORK_OUTPUT"
