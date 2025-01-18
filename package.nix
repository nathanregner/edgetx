{
  pkgs,
  SDL2,
  clangStdenv,
  dfu-util,
  fetchFromGitHub,
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
let
  JOBS = "12";
in
clangStdenv.mkDerivation rec {
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
        asciitree
        clang
        jinja2
        libclang
        lz4
        pillow
        pyelftools
      ]
    ))
  ];

  # libsForQt5.callPackage
  buildInputs = [
    yaml-cpp
    qtbase
    qtserialport
    qtmultimedia
    SDL2
    openssl
    miniz
    libusb1
    dfu-util
  ];

  dontWrapQtApps = true;

  buildPhase = ''

    COMMON_OPTIONS="-DGVARS=YES -DHELI=YES -DLUA=YES -Wno-dev -DCMAKE_BUILD_TYPE=Release"
        cmake -DPCB=X7 -DPCBREV=MT12 .
        cmake --build . -j"${JOBS}" --target native-configure
        # cmake --build native -j"${JOBS}" --target libsimulator
        cmake --build native -j"${JOBS}" --target package
  '';

  installPhase = ''
    #
  '';
  # BUILD_OPTIONS+="-DPCB=X7 -DPCBREV=MT12"

}
