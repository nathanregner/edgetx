{
  lib,
  SDL2,
  clang-tools,
  cmake,
  dfu-util,
  fetchFromGitHub,
  generate_datacopy,
  gnumake,
  libusb1,
  llvmPackages,
  miniz,
  openssl,
  pkg-config,
  python3,
  qtbase,
  qtmultimedia,
  qtserialport,
  qttools,
  stdenv,
  wrapQtAppsHook,
  yaml-cpp,
  ...
}:
stdenv.mkDerivation rec {
  # clangStdenv.mkDerivation rec {
  pname = "edgetx";
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
    wrapQtAppsHook
    clang-tools
    cmake
    generate_datacopy
    gnumake
    llvmPackages.libclang
    pkg-config
    qttools
    # TODO remov
    (python3.withPackages (
      packages: with packages; [
        # # clang
        # # libclang
        # asciitree
        jinja2
        lz4
        pillow
        # pyelftools
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

  # dontWrapQtApps = true;

  postPatch = ''
    patchShebangs .
    patchShebangs companion/util
    head companion/util/generate_hwdefs_qrc.py
  '';

  env.LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";
  # env.CLANG_INCLUDE = "${llvmPackages.clang}/resource-root/include";

  buildPhase = ''
    mkdir $out
    ../tools/build-companion.sh -j$NIX_BUILD_CORES .. $out
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
      # "-DGTEST_ROOT=${gtest.src}/googletest"
      "-DDFU_UTIL_PATH=${dfu-util}/bin/dfu-util"
      # file RPATH_CHANGE could not write new RPATH
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
    ];

  installPhase = ''
    mkdir -p $out
    mv native/_CPack_Packages/Linux/External/AppImage/usr/* $out
  '';
  # BUILD_OPTIONS+="-DPCB=X7 -DPCBREV=MT12"

}
