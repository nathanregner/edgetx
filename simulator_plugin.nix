{
  pkgs,
  lib,
  SDL2,
  clang-tools,
  cmake,
  dfu-util,
  fetchFromGitHub,
  generate_datacopy,
  gnumake,
  gtest,
  libusb1,
  llvmPackages,
  lvgl,
  miniz,
  openssl,
  pkg-config,
  python3,
  qtbase,
  qtmultimedia,
  qtserialport,
  qttools,
  stdenv,
  yaml-cpp,
  ...
}:

{
  target,
}:

let
  JOBS = "12";
in
stdenv.mkDerivation rec {
  # clangStdenv.mkDerivation rec {
  pname = "edgetx-libsimulator-${target}";
  version = "2.10.5";
  # src = fetchFromGitHub {
  #   owner = "EdgeTX";
  #   repo = pname;
  #   rev = "v${version}";
  #   fetchSubmodules = false;
  #   hash = "sha256-Ph5xcoMp5KZmf1A9ylo0bt6GyyXADR3masoSo/mx4PQ=";
  # };
  src = ./.;

  nativeBuildInputs = [
    clang-tools
    cmake
    generate_datacopy
    gnumake
    llvmPackages.libclang
    pkg-config
    qttools
    (python3.withPackages (
      packages: with packages; [
        jinja2
        libclang
        lz4
        pillow
      ]
    ))
  ];

  # libsForQt5.callPackage
  buildInputs = [
    SDL2
    dfu-util
    libusb1
    miniz
    openssl
    qtbase
    qtmultimedia
    qtserialport
    yaml-cpp
  ];

  dontWrapQtApps = true;

  postPatch = ''
    patchShebangs .
  '';

  env.TARGET = target;
  env.LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";
  # env.CLANG_INCLUDE = "${llvmPackages.clang}/resource-root/include";

  buildPhase = ''
    COMMON_OPTIONS="-DGVARS=YES -DHELI=YES -DLUA=YES -Wno-dev -DCMAKE_BUILD_TYPE=Release $cmakeFlags"
    if [ "$(uname)" = "Darwin" ]; then
      COMMON_OPTIONS="$COMMON_OPTIONS -DCMAKE_OSX_DEPLOYMENT_TARGET='10.15'"
    fi

    source ../tools/build-common.sh

    BUILD_OPTIONS="$COMMON_OPTIONS "
    if ! get_target_build_options "$TARGET"; then
        echo "Error: Failed to find a match for target '$target_name'"
        exit 1
    fi

    cmake $BUILD_OPTIONS .
    cmake --build . -j$NIX_BUILD_CORES --target native-configure
    cmake --build native -j$NIX_BUILD_CORES --target libsimulator
  '';

  enableParallelBuilding = true;

  cmakeFlags =
    let
      maxLibQt = fetchFromGitHub {
        owner = "mpaperno";
        repo = "maxLibQt";
        rev = "b903e7a755b241313b7acdea0258ee17cbd8fc04";
        hash = "sha256-xKgUIuh6ANsKrih1lK1mKPCzh52RnDJVT4XwQvI97mk=";
      };
    in
    [
      "-DFETCHCONTENT_SOURCE_DIR_MAXLIBQT=${maxLibQt}"
      "-DGTEST_ROOT=${gtest.src}/googletest"
      "-DDFU_UTIL_PATH=${dfu-util}/bin/dfu-util"
      "-DLVGL_SRC_DIR=${lvgl.src}/src"
      # file RPATH_CHANGE could not write new RPATH
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
      "-DFETCHCONTENT_SOURCE_DIR_MAXLIBQT=${maxLibQt}"
    ];

  installPhase = ''
    mv ./native/libedgetx-${target}-simulator.so $out
  '';
}
