XCODE_DEVELOPER = $(shell xcode-select --print-path)
IOS_PLATFORM ?= iPhoneOS

# BUILD_PARALLELISM ?= $(shell sysctl -n hw.ncpu)
BUILD_PARALLELISM = 1

# Pick latest SDK in the directory
IOS_PLATFORM_DEVELOPER = ${XCODE_DEVELOPER}/Platforms/${IOS_PLATFORM}.platform/Developer
IOS_SDK = ${IOS_PLATFORM_DEVELOPER}/SDKs/$(shell ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1)

BUILD_DIRS = ${CURDIR}/build/armv7 ${CURDIR}/build/armv7s ${CURDIR}/build/arm64 ${CURDIR}/build/i386 ${CURDIR}/build/x86_64

all: lib/libspatialite.a
lib/libspatialite.a: build_arches
	mkdir -p lib
	mkdir -p include

	# Copy includes
	cp -R build/arm64/include/geos include
	cp -R build/arm64/include/spatialite include
	cp -R build/arm64/include/*.h include

	# Make fat libraries for all architectures
	for file in build/arm64/lib/*.a; \
		do name=`basename $$file .a`; \
		lipo -create \
			-arch armv7 build/armv7/lib/$$name.a \
			-arch armv7s build/armv7s/lib/$$name.a \
			-arch arm64 build/arm64/lib/$$name.a \
			-output lib/$$name.a \
		; \
		done;

# Build separate architectures
build_arches: $(BUILD_DIRS)
	${MAKE} $(MAKEFLAGS) arch ARCH=armv7 IOS_PLATFORM=iPhoneOS HOST=arm-apple-darwin
	${MAKE} $(MAKEFLAGS) arch ARCH=armv7s IOS_PLATFORM=iPhoneOS HOST=arm-apple-darwin
	${MAKE} $(MAKEFLAGS) arch ARCH=arm64 IOS_PLATFORM=iPhoneOS HOST=arm-apple-darwin

# make sure the build directories are made
${CURDIR}/build/%:
	mkdir -p $@

PREFIX = ${CURDIR}/build/${ARCH}
LIBDIR = ${PREFIX}/lib
BINDIR = ${PREFIX}/bin
INCLUDEDIR = ${PREFIX}/include

CXX = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
# CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -miphoneos-version-min=7.0 -O3 
# CXXFLAGS = -stdlib=libc++ -std=c++14 -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -miphoneos-version-min=7.0 -O3
CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -mios-simulator-version-min=7.0 -O3 
CXXFLAGS = -stdlib=libc++ -std=c++14 -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -mios-simulator-version-min=7.0 -O3
LDFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -L${LIBDIR} -L${IOS_SDK}/usr/lib -arch ${ARCH} -mios-simulator-version-min=7.0

arch: ${LIBDIR}/libspatialite.a

${LIBDIR}/libspatialite.a: ${LIBDIR}/libproj.a ${LIBDIR}/libgeos.a ${CURDIR}/spatialite | ${CURDIR}/build/${ARCH}
	cd spatialite && env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS} -Wno-error=implicit-function-declaration -Wno-error=int-conversion" \
	CXXFLAGS="${CXXFLAGS} -Wno-error=implicit-function-declaration -Wno-error=int-conversion" \
	LDFLAGS="${LDFLAGS} -lc++ -liconv -lgeos -lgeos_c  -lproj" ./configure --host=${HOST} --enable-freexl=no --enable-libxml2=no --enable-rttopo=no --disable-rttopo --disable-gcp --enable-minizip=no --prefix=${PREFIX} --with-geosconfig=${BINDIR}/geos-config --disable-shared --disable-loadable-extension && make clean && make -j $(BUILD_PARALLELISM) $(MAKEFLAGS) install-strip

${CURDIR}/spatialite:
	curl http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-5.1.0.tar.gz > spatialite.tar.gz
	tar -xzf spatialite.tar.gz
	rm spatialite.tar.gz
	mv libspatialite-5.1.0 spatialite
	./update-spatialite

# TODO: determine if we need libcurl and libtiff in the future
${LIBDIR}/libproj.a: ${CURDIR}/proj
	cd proj && mkdir -p build && cd build && cmake .. \
		-DCMAKE_OSX_SYSROOT=$$(xcrun --sdk iphoneos --show-sdk-path) \
	 	-DCMAKE_OSX_ARCHITECTURES=${ARCH} \
		-DCMAKE_TOOLCHAIN_FILE=${CURDIR}/ios.toolchain.cmake \
		-DCMAKE_INSTALL_PREFIX=${PREFIX} \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_C_FLAGS="${CFLAGS}" \
		-DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
		-DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
		-DENABLE_CURL=OFF \
		-DENABLE_TIFF=OFF \
		-DBUILD_PROJSYNC=OFF \
		-DBUILD_TESTING=OFF \
		-DBUILD_APPS=OFF \
		&& \
	make -j $(BUILD_PARALLELISM) $(MAKEFLAGS) && make install

${CURDIR}/proj:
	curl -L http://download.osgeo.org/proj/proj-9.5.1.tar.gz > proj.tar.gz
	tar -xzf proj.tar.gz
	rm proj.tar.gz
	mv proj-9.5.1 proj

${LIBDIR}/libgeos.a: ${CURDIR}/geos
	cd geos && mkdir -p build && cd build && cmake .. \
		-DCMAKE_OSX_SYSROOT=$$(xcrun --sdk iphoneos --show-sdk-path) \
		-DCMAKE_OSX_ARCHITECTURES=${ARCH} \
		-DCMAKE_TOOLCHAIN_FILE=${CURDIR}/ios.toolchain.cmake \
		-DCMAKE_INSTALL_PREFIX=${PREFIX} \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DBUILD_DOCUMENTATION=OFF \
		-DCMAKE_C_FLAGS="${CFLAGS}" \
		-DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
		-DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" && \
	make -j $(BUILD_PARALLELISM) $(MAKEFLAGS) && make install

${CURDIR}/geos:
	curl http://download.osgeo.org/geos/geos-3.13.0.tar.bz2 > geos.tar.bz2
	tar -xzf geos.tar.bz2
	rm geos.tar.bz2
	mv geos-3.13.0 geos

${LIBDIR}/libsqlite3.a: ${CURDIR}/sqlite3
	cd sqlite3 && env LIBTOOL=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS} -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	CXXFLAGS="${CXXFLAGS} -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	LDFLAGS="-Wl,-arch -Wl,${ARCH} -arch_only ${ARCH} ${LDFLAGS}" \
	./configure --host=${HOST} --prefix=${PREFIX} --disable-shared \
	   --enable-static && make $(MAKEFLAGS) clean install-headers install-lib

${CURDIR}/sqlite3:
	curl https://www.sqlite.org/2025/sqlite-autoconf-3490000.tar.gz > sqlite3.tar.gz
	tar xzvf sqlite3.tar.gz
	rm sqlite3.tar.gz
	mv sqlite-autoconf-3490000 sqlite3
	touch sqlite3

clean:
	rm -rf build geos proj spatialite include lib
