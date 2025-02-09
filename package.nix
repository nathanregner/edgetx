{
  SDL2,
  clang-tools,
  cmake,
  dfu-util,
  fetchFromGitHub,
  generate_datacopy,
  gnumake,
  jq,
  lib,
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

  simulatorPlugins ? [ ], # empty to build all; at least one seems to be required?
  ...
}:

let
  maxLibQt = fetchFromGitHub {
    owner = "mpaperno";
    repo = "maxLibQt";
    rev = "b903e7a755b241313b7acdea0258ee17cbd8fc04";
    hash = "sha256-xKgUIuh6ANsKrih1lK1mKPCzh52RnDJVT4XwQvI97mk=";
  };
in
stdenv.mkDerivation rec {
  pname = "edgetx";
  version = "nightly-2025-02-04";
  src = fetchFromGitHub {
    owner = "EdgeTX";
    repo = pname;
    rev = "0325bd776b2ac7cdef6c6270e978f349e4693a72";
    fetchSubmodules = true;
    hash = "sha256-9bQz+1M1S/cJzvrR5dD2KwT3mRDjDvf9yee9okAsSnY=";
  };

  nativeBuildInputs = [
    clang-tools
    cmake
    generate_datacopy
    gnumake
    jq
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

  # postPatch = ''
  #   patchShebangs .
  # '';

  env = {
    EDGETX_VERSION_TAG = "${version}";
    LIBCLANG_PATH = "${lib.getLib llvmPackages.libclang}/lib";
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

  # simplified re-implementation of tools/build-companion.sh
  buildPhase = ''
    source ../tools/build-common.sh

    simulator_plugins=($(jq -r '.[]' <<< '${builtins.toJSON simulatorPlugins}'))
    if [[ -z $simulator_plugins ]]; then
      # build everything by default
      readarray -t simulator_plugins < <(jq -c '.targets | map(.[1] | rtrimstr("-")) | sort | .[]' ../fw.json)
    fi

    for plugin in "''${simulator_plugins[@]}"; do
      echo "Building $plugin"

      BUILD_OPTIONS=""
      if ! get_target_build_options "$plugin"; then
        echo "Error: Failed to find a match for target '$plugin'"
        exit 1
      fi

      rm -f CMakeCache.txt native/CMakeCache.txt
      cmake $cmakeFlags $BUILD_OPTIONS ..
      cmake --build . --target native-configure
      cmake --build native -j"$NIX_BUILD_CORES" --target libsimulator
    done

    cmake --build . --target native-configure
    cmake --build native -j"$NIX_BUILD_CORES" --target package
  '';

  installPhase = ''
    mkdir -p $out
    mv native/_CPack_Packages/Linux/External/AppImage/usr/* $out
  '';

  passthru.updateScript = nix-update { };
}
