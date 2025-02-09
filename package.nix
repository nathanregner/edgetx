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
  nix-update,
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

  simulatorPlugins ? null,
  ...
}:

let
  src = ./.;

  maxLibQt = fetchFromGitHub {
    owner = "mpaperno";
    repo = "maxLibQt";
    rev = "b903e7a755b241313b7acdea0258ee17cbd8fc04";
    hash = "sha256-xKgUIuh6ANsKrih1lK1mKPCzh52RnDJVT4XwQvI97mk=";
  };

  defaultSimulatorPlugins =
    # ["RadioMaster TX16S", "tx16s-"] => "tx16s"
    builtins.map (target: lib.removeSuffix "-" (builtins.elemAt target 1)) (
      builtins.fromJSON (builtins.readFile "${src}/fw.json)").targets
    );
in
stdenv.mkDerivation rec {
  pname = "edgetx";
  version = "2.10.5";
  inherit src;
  # src = fetchFromGitHub {
  #   owner = "EdgeTX";
  #   repo = pname;
  #   rev = "v${version}";
  #   fetchSubmodules = false;
  #   hash = "sha256-Ph5xcoMp5KZmf1A9ylo0bt6GyyXADR3masoSo/mx4PQ=";
  # };

  nativeBuildInputs = [
    clang-tools
    cmake
    generate_datacopy
    gnumake
    pkg-config
    qttools
    wrapQtAppsHook
    (python3.withPackages (
      packages: with packages; [
        jinja2
        lz4
        pillow
      ]
    ))
  ];

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

  postPatch = ''
    patchShebangs .
    patchShebangs companion/util
  '';

  env = {
    EDGETX_VERSION_TAG = "${version}";
    LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";
    SIMULATOR_PLUGINS = simulatorPlugins ? defaultSimulatorPlugins;
  };

  cmakeFlags = [
    "-DFETCHCONTENT_SOURCE_DIR_MAXLIBQT=${maxLibQt}"
    "-DDFU_UTIL_PATH=${dfu-util}/bin/dfu-util"
    # file RPATH_CHANGE could not write new RPATH
    "-DCMAKE_SKIP_BUILD_RPATH=ON"

    # `COMMON_OPTIONS` from tools/build-companion.sh
    "-DGVARS=YES"
    "-DHELI=YES"
    "-DLUA=YES"
    "-Wno-dev"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  enableParallelBuilding = true;

  # simplified re-implementation of build-companion.sh
  buildPhase = ''
    pwd
    ls
    source ../tools/build-common.sh
    ../tools/build-companion.sh -j$NIX_BUILD_CORES .. .

    for plugin in "''${SIMULATOR_PLUGINS[@]}"; do
      echo "Building $plugin"

      BUILD_OPTIONS=""
      if ! get_target_build_options "$plugin"; then
        echo "Error: Failed to find a match for target '$plugin'"
        exit 1
      fi

      rm -f CMakeCache.txt native/CMakeCache.txt
      cmake $BUILD_OPTIONS ..
      cmake --build . --target native-configure
      cmake --build native -j"$NIX_BUILD_CORES" --target libsimulator
    done

    cmake --build . --target native-configure
    cmake --build native -j"NIX_BUILD_CORES" --target package
  '';

  installPhase = ''
    mkdir -p $out
    mv native/_CPack_Packages/Linux/External/AppImage/usr/* $out
  '';

  passthru.updateScript = nix-update { };
}
