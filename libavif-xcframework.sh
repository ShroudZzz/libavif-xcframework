#!/bin/bash

# Clone libavif repository
git clone https://github.com/AOMediaCodec/libavif.git
cd libavif

# Clone dav1d repository
git clone https://code.videolan.org/videolan/dav1d.git ext/dav1d

mkdir -p ext/dav1d/build && cd ext/dav1d/build
meson setup --default-library=static  ..
ninja
cd ../../../

curl -LO https://raw.githubusercontent.com/leetal/ios-cmake/master/ios.toolchain.cmake

# 设置 CMake 参数
CMAKE_OPTIONS="-DBUILD_SHARED_LIBS=OFF -DAVIF_CODEC_DAV1D=ON -DAVIF_CODEC_AOM_DECODE=OFF -DAVIF_CODEC_AOM_ENCODE=OFF -DAVIF_LOCAL_DAV1D=ON"

# 构建 iOS arm64
mkdir build_ios_arm64 && cd build_ios_arm64
cmake -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=OS64 $CMAKE_OPTIONS ..
make
cd ..

# 构建 simulator arm64
mkdir build_simulator_arm64 && cd build_simulator_arm64
cmake -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=SIMULATORARM64 $CMAKE_OPTIONS ..
make
cd ..

# 构建 simulator x86_64
mkdir build_simulator_x86_64 && cd build_simulator_x86_64
cmake -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=SIMULATOR64 $CMAKE_OPTIONS ..
make
cd ..

mkdir -p build_simulator_arm64_x86_64
lipo -create build_simulator_x86_64/libavif.a build_simulator_arm64/libavif.a -output build_simulator_arm64_x86_64/libavif.a
rm -rf build_simulator_arm64 build_simulator_x86_64


# 构建 maccatalyst arm64
mkdir build_maccatalyst_arm64 && cd build_maccatalyst_arm64
cmake -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=MAC_CATALYST_ARM64 $CMAKE_OPTIONS ..
make
cd ..

# 构建 maccatalyst x86_64
mkdir build_maccatalyst_x86_64 && cd build_maccatalyst_x86_64
cmake -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DPLATFORM=MAC_CATALYST $CMAKE_OPTIONS ..
make
cd ..

mkdir -p build_maccatalyst_arm64_x86_64
lipo -create build_maccatalyst_arm64/libavif.a build_maccatalyst_x86_64/libavif.a -output build_maccatalyst_arm64_x86_64/libavif.a
rm -rf build_maccatalyst_arm64 build_maccatalyst_x86_64

xcodebuild -create-xcframework \
    -library build_ios_arm64/libavif.a -headers include/avif \
    -library build_maccatalyst_arm64_x86_64/libavif.a -headers include/avif \
    -library build_simulator_arm64_x86_64/libavif.a -headers include/avif \
    -output libavif.xcframework

rm -rf build_*
rm ios.toolchain.cmake
