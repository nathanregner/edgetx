{
  clangStdenv,
  pkgs,
  fetchFromGitHub,

  qtbase,
  qtserialport,
  qttools,
  qtmultimedia,
  SDL2,
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
    # llvmPackages.clang
    # llvmPackages.bintools
    clang-tools
    (python3.withPackages (
      packages: with packages; [
        asciitree
        jinja2
        pillow
        libclang
        # aqtinstall
        clang
        lz4
        pyelftools
      ]
    ))
  ];

  # libsForQt5.callPackage
  buildInputs =
    [

      qtbase
      qtserialport
      qtmultimedia
      SDL2
    ]
    ++ (with pkgs; [
      # libssl1
      pkg-config
      openssl
      libusb1
      # libssl
      dfu-util
    ]);

  dontWrapQtApps = true;

  buildPhase = ''
    cmake -DPCB=X7 -DPCBREV=MT12 .
    cmake --build . -j"${JOBS}" --target native-configure
    cmake --build native -j"${JOBS}" --target libsimulator
  '';

  installPhase = ''
    #
  '';
  # BUILD_OPTIONS+="-DPCB=X7 -DPCBREV=MT12"

}
