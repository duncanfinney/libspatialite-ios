XCODE_DEVELOPER = $(shell xcode-select --print-path)
IOS_PLATFORM ?= iPhoneOS
BUILD_PARALLELISM ?= 10

# Set SDK name, minimum version flag, and platform directory based on IOS_PLATFORM
ifeq ($(IOS_PLATFORM), iPhoneSimulator)
    IOS_SDK_NAME = iphonesimulator
    MIN_VERSION_FLAG = -mios-simulator-version-min=7.0
    PLATFORM_DIR = iPhoneSimulator
else ifeq ($(IOS_PLATFORM), iPhoneOS)
    IOS_SDK_NAME = iphoneos
    MIN_VERSION_FLAG = -miphoneos-version-min=7.0
    PLATFORM_DIR = iPhoneOS
else ifeq ($(IOS_PLATFORM), AppleWatchSimulator)
    IOS_SDK_NAME = watchsimulator
    MIN_VERSION_FLAG = -mwatchos-version-min=2.0
    PLATFORM_DIR = WatchSimulator
else ifeq ($(IOS_PLATFORM), AppleWatchOS)
    IOS_SDK_NAME = watchos
    MIN_VERSION_FLAG = -mwatchos-version-min=2.0
    PLATFORM_DIR = WatchOS
else ifeq ($(IOS_PLATFORM), MacOSX)
    IOS_SDK_NAME = macosx
    MIN_VERSION_FLAG = -mmacosx-version-min=10.12
    PLATFORM_DIR = MacOSX
endif

# Set SDK path
ifeq ($(IOS_PLATFORM), MacOSX)
    IOS_SDK = $(shell xcrun --sdk macosx --show-sdk-path)
    IOS_PLATFORM_DEVELOPER =
else
    IOS_PLATFORM_DEVELOPER = $(XCODE_DEVELOPER)/Platforms/$(PLATFORM_DIR).platform/Developer
    IOS_SDK = $(IOS_PLATFORM_DEVELOPER)/SDKs/$(shell ls $(IOS_PLATFORM_DEVELOPER)/SDKs | sort -r | head -n1)
endif

# Choose toolchain: use watchos toolchain for watch builds.
ifeq ($(IOS_PLATFORM), MacOSX)
    TOOLCHAIN =
else ifeq ($(IOS_PLATFORM), AppleWatchOS)
    TOOLCHAIN = -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/watchos.toolchain.cmake
else ifeq ($(IOS_PLATFORM), AppleWatchSimulator)
    TOOLCHAIN = -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/watchos.toolchain.cmake
else
    TOOLCHAIN = -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/ios.toolchain.cmake
endif

# Extra flags for MacOSX: do not force a system name.
ifeq ($(IOS_PLATFORM),MacOSX)
    EXTRA_CMAKE_FLAGS =
else
    EXTRA_CMAKE_FLAGS =
endif

ifeq ($(IOS_PLATFORM), AppleWatchSimulator)
    TARGET_FLAGS = -target arm64-apple-watchos-simulator
else
    TARGET_FLAGS =
endif

# Build directories for various arches/platforms, including Apple Watch
BUILD_DIRS = $(CURDIR)/build/armv7-iPhoneOS \
             $(CURDIR)/build/armv7s-iPhoneOS \
             $(CURDIR)/build/arm64-iPhoneOS \
             $(CURDIR)/build/arm64-iPhoneSimulator \
             $(CURDIR)/build/arm64-MacOSX \
             $(CURDIR)/build/armv7k-AppleWatchOS \
             $(CURDIR)/build/arm64_32-AppleWatchOS \
			 $(CURDIR)/build/arm64_32-AppleWatchSimulator

all: lib/libspatialite.a

lib/libspatialite.a: build_arches
	@./build-xcframework.sh

# Build architectures; note HOST for watch builds is set to arm-apple-watchos.
build_arches: $(BUILD_DIRS)
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=armv7    IOS_PLATFORM=iPhoneOS        HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=armv7s   IOS_PLATFORM=iPhoneOS        HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=arm64    IOS_PLATFORM=iPhoneOS        HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=arm64    IOS_PLATFORM=iPhoneSimulator HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=armv7k   IOS_PLATFORM=AppleWatchOS  	HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=arm64_32 IOS_PLATFORM=AppleWatchOS 	HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=arm64 IOS_PLATFORM=AppleWatchSimulator HOST=arm-apple-darwin
	$(MAKE) --no-print-directory MAKEFLAGS= arch ARCH=arm64    IOS_PLATFORM=MacOSX

# Create build directory for given ARCH and IOS_PLATFORM
$(CURDIR)/build/%:
	@mkdir -p $@

# Define installation prefixes
PREFIX     = $(CURDIR)/build/$(ARCH)-$(IOS_PLATFORM)
LIBDIR     = $(PREFIX)/lib
BINDIR     = $(PREFIX)/bin
INCLUDEDIR = $(PREFIX)/include

CXX      = $(XCODE_DEVELOPER)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC       = $(XCODE_DEVELOPER)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CFLAGS   = -isysroot $(IOS_SDK) -I$(IOS_SDK)/usr/include -arch $(ARCH) $(TARGET_FLAGS) -I$(INCLUDEDIR) $(MIN_VERSION_FLAG) -O3
CXXFLAGS = -stdlib=libc++ -std=c++14 -isysroot $(IOS_SDK) -I$(IOS_SDK)/usr/include -arch $(ARCH) $(TARGET_FLAGS) -I$(INCLUDEDIR) $(MIN_VERSION_FLAG) -O3
LDFLAGS  = -stdlib=libc++ -isysroot $(IOS_SDK) -L$(LIBDIR) -L$(IOS_SDK)/usr/lib -arch $(ARCH) $(TARGET_FLAGS) $(MIN_VERSION_FLAG)

# Build spatialite library for given arch/platform.
arch: $(LIBDIR)/libspatialite.a

$(LIBDIR)/libspatialite.a: $(LIBDIR)/libproj.a $(LIBDIR)/libgeos.a $(CURDIR)/spatialite | $(CURDIR)/build/$(ARCH)-$(IOS_PLATFORM)
	cd spatialite && env \
	  CXX=$(CXX) \
	  CC=$(CC) \
	  CFLAGS="$(CFLAGS) -Wno-error=implicit-function-declaration -Wno-error=int-conversion" \
	  CXXFLAGS="$(CXXFLAGS) -Wno-error=implicit-function-declaration -Wno-error=int-conversion" \
	  LDFLAGS="$(LDFLAGS) -lc++ -liconv -lgeos -lgeos_c -lproj" \
	  ./configure --host=$(HOST) --enable-freexl=no --enable-libxml2=no --enable-rttopo=no --disable-rttopo --disable-gcp --enable-minizip=no --prefix=$(PREFIX) --with-geosconfig=$(BINDIR)/geos-config --disable-shared --disable-loadable-extension && \
	  make clean && make -j $(BUILD_PARALLELISM) install-strip

$(CURDIR)/spatialite:
	curl http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-5.1.0.tar.gz > spatialite.tar.gz
	tar -xzf spatialite.tar.gz
	rm spatialite.tar.gz
	mv libspatialite-5.1.0 spatialite
	./update-spatialite

# Build proj with explicit compiler paths
$(LIBDIR)/libproj.a: $(CURDIR)/proj
	cd proj && rm -rf build && mkdir -p build && cd build && cmake .. \
	  -DCMAKE_OSX_SYSROOT=$(IOS_SDK) \
	  -DCMAKE_OSX_ARCHITECTURES=$(ARCH) \
	  $(TOOLCHAIN) \
	  $(EXTRA_CMAKE_FLAGS) \
	  -DCMAKE_INSTALL_PREFIX=$(PREFIX) \
	  -DCMAKE_C_COMPILER=$(CC) \
	  -DCMAKE_CXX_COMPILER=$(CXX) \
	  -DBUILD_SHARED_LIBS=OFF \
	  -DCMAKE_C_FLAGS="$(CFLAGS)" \
	  -DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
	  -DCMAKE_EXE_LINKER_FLAGS="$(LDFLAGS)" \
	  -DENABLE_CURL=OFF \
	  -DENABLE_TIFF=OFF \
	  -DBUILD_PROJSYNC=OFF \
	  -DBUILD_CCT=OFF \
	  -DBUILD_CS2CS=OFF \
	  -DBUILD_GEOD=OFF \
	  -DBUILD_GIE=OFF \
	  -DBUILD_PROJ=OFF \
	  -DBUILD_PROJINFO=OFF \
	  -DBUILD_PROJSYNC=OFF \
	  -DBUILD_TESTING=OFF && \
	make -j $(BUILD_PARALLELISM) && make install

$(CURDIR)/proj:
	curl -L http://download.osgeo.org/proj/proj-9.5.1.tar.gz > proj.tar.gz
	tar -xzf proj.tar.gz
	rm proj.tar.gz
	mv proj-9.5.1 proj

# Build geos with explicit compiler paths
$(LIBDIR)/libgeos.a: $(CURDIR)/geos
	cd geos && rm -rf build && mkdir -p build && cd build && cmake .. \
	  -DCMAKE_OSX_SYSROOT=$(IOS_SDK) \
	  -DCMAKE_OSX_ARCHITECTURES=$(ARCH) \
	  $(TOOLCHAIN) \
	  $(EXTRA_CMAKE_FLAGS) \
	  -DCMAKE_INSTALL_PREFIX=$(PREFIX) \
	  -DCMAKE_C_COMPILER=$(CC) \
	  -DCMAKE_CXX_COMPILER=$(CXX) \
	  -DBUILD_SHARED_LIBS=OFF \
	  -DBUILD_TESTING=OFF \
	  -DBUILD_DOCUMENTATION=OFF \
	  -DBUILD_BENCHMARKS=OFF \
	  -DBUILD_GEOSOP=OFF \
	  -DCMAKE_C_FLAGS="$(CFLAGS)" \
	  -DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
	  -DCMAKE_EXE_LINKER_FLAGS="$(LDFLAGS)" && \
	make -j $(BUILD_PARALLELISM) && make install

$(CURDIR)/geos:
	curl http://download.osgeo.org/geos/geos-3.13.0.tar.bz2 > geos.tar.bz2
	tar -xjf geos.tar.bz2
	rm geos.tar.bz2
	mv geos-3.13.0 geos

$(LIBDIR)/libsqlite3.a: $(CURDIR)/sqlite3
	cd sqlite3 && env LIBTOOL=$(XCODE_DEVELOPER)/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool \
	  CXX=$(CXX) \
	  CC=$(CC) \
	  CFLAGS="$(CFLAGS) -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	  CXXFLAGS="$(CXXFLAGS) -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	  LDFLAGS="-Wl,-arch -Wl,$(ARCH) -arch_only $(ARCH) $(LDFLAGS)" \
	  ./configure --host=$(HOST) --prefix=$(PREFIX) --disable-shared --enable-static && \
	  make clean install-headers install-lib

$(CURDIR)/sqlite3:
	curl https://www.sqlite.org/2025/sqlite-autoconf-3490000.tar.gz > sqlite3.tar.gz
	tar xzvf sqlite3.tar.gz
	rm sqlite3.tar.gz
	mv sqlite-autoconf-3490000 sqlite3
	touch sqlite3

clean:
	rm -rf build geos proj spatialite include lib sqlite3
	rm -rf libspatialite.xcframework merged
