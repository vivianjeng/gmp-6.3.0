#!/bin/bash
build_for_ios() {
    generate_32bit_headers
    build_for_architecture iphoneos armv7 arm-apple-darwin
    build_for_architecture iphonesimulator i386 i386-apple-darwin
    clean
    generate_64bit_headers
    build_for_architecture iphoneos arm64 arm-apple-darwin
    build_for_architecture iphoneos arm64e arm-apple-darwin
    build_for_architecture iphonesimulator x86_64 x86_64-apple-darwin
    create_universal_library
}

generate_32bit_headers() {
    generate_headers i386
}

generate_64bit_headers() {
    generate_headers x86_64
}

generate_headers() {
    ARCH=$1
    ./configure \
    CPPFLAGS="-arch ${ARCH}" \
    LDFLAGS="-arch ${ARCH}" \
    --disable-assembly \
    --quiet \
    --enable-silent-rules
    make -j 16
}

build_for_architecture() {
    PLATFORM=$1
    ARCH=$2
    HOST=$3
    SDKPATH=`xcrun -sdk $PLATFORM --show-sdk-path`
    PREFIX=$(pwd)/build/$ARCH
    ./configure \
    CC=`xcrun -sdk $PLATFORM -find cc` \
    CXX=`xcrun -sdk $PLATFORM -find c++` \
    CPP=`xcrun -sdk $PLATFORM -find cc`" -E" \
    LD=`xcrun -sdk $PLATFORM -find ld` \
    AR=`xcrun -sdk $PLATFORM -find ar` \
    NM=`xcrun -sdk $PLATFORM -find nm` \
    NMEDIT=`xcrun -sdk $PLATFORM -find nmedit` \
    LIBTOOL=`xcrun -sdk $PLATFORM -find libtool` \
    LIPO=`xcrun -sdk $PLATFORM -find lipo` \
    OTOOL=`xcrun -sdk $PLATFORM -find otool` \
    RANLIB=`xcrun -sdk $PLATFORM -find ranlib` \
    STRIP=`xcrun -sdk $PLATFORM -find strip` \
    CPPFLAGS="-arch $ARCH -isysroot $SDKPATH" \
    LDFLAGS="-arch $ARCH -headerpad_max_install_names" \
    --host=$HOST \
    --disable-assembly \
    --enable-cxx \
    --prefix=$PREFIX \
    --quiet --enable-silent-rules
    xcrun -sdk $PLATFORM make mostlyclean
    xcrun -sdk $PLATFORM make -j 16 install
}

create_universal_library() {
    lipo -create -output libgmp.dylib \
    build/{armv7,arm64,i386,x86_64}/lib/libgmp.dylib
    lipo -create -output libgmpxx.dylib \
    build/{armv7,arm64,i386,x86_64}/lib/libgmpxx.dylib
    update_dylib_names
    update_dylib_references
}

update_dylib_names() {
    install_name_tool -id "@rpath/libgmp.dylib" libgmp.dylib
    install_name_tool -id "@rpath/libgmpxx.dylib" libgmpxx.dylib
}

update_dylib_references() {
    update_dylib_reference_for_architecture armv7
    update_dylib_reference_for_architecture arm64
    update_dylib_reference_for_architecture i386
    update_dylib_reference_for_architecture x86_64
}

update_dylib_reference_for_architecture() {
    ARCH=$1
    install_name_tool -change \
    "$(pwd)/build/$ARCH/lib/libgmp.10.dylib" \
    "@rpath/libgmp.dylib" \
    libgmpxx.dylib
}

clean() {
    make distclean
}

build_for_ios