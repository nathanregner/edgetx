{
  SDL2,
  clangStdenv,
  dfu-util,
  fetchFromGitHub,
  gtest,
  libusb1,
  miniz,
  openssl,
  qtbase,
  qtmultimedia,
  qtserialport,
  qttools,
  yaml-cpp,
  ...
}:

{
  plugin_name,
}:

let
  JOBS = "12";
in
clangStdenv.mkDerivation rec {
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

  nativeBuildInputs = with pkgs; [
    qttools
    cmake
    gnumake
    pkg-config
    clang-tools
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

  dontWrapQtApps = true;

  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    cmake -DPCB=X7 -DPCBREV=MT12 .
    cmake --build . -j"${JOBS}" --target native-configure
    cmake --build native -j"${JOBS}" --target package
  '';

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
      # file RPATH_CHANGE could not write new RPATH
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
      "-DFETCHCONTENT_SOURCE_DIR_MAXLIBQT=${maxLibQt}"
    ];

  installPhase = ''
    #
  '';
  # BUILD_OPTIONS+="-DPCB=X7 -DPCBREV=MT12"

}
