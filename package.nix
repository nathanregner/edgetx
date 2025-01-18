{
  clangStenv,
  pkgs,
  fetchFromGitHub,
  ...
}:
let
  JOBS = 12;
in
clangStenv.mkDerivation {
  pname = "edgetx";
  version = "???";
  src = fetchFromGitHub {
    owner = "EdgeTX";
    repo = pname;
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-bKMAyONy1Udd+2nDVEMrtIsnfqrNuBVMWU7nCqvZ+3E=";
  };

  nativeBuildInputs = with pkgs; [
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
    (with pkgs.libsForQt5; [
      qtbase
      qtmultimedia
      # qtlinguisttools
      qtserialport
      qttools
    ])
    ++ (with pkgs; [
      SDL2
      # libssl1
      pkg-config
      openssl
      libusb1
      # libssl
      dfu-util
    ]);

  buildPhase = ''
    cmake -DPCB=X7 -DPCBREV=MT12 .
    cmake --build . -j"${JOBS}" --target native-configure
    cmake --build native -j"${JOBS}" --target libsimulator
  '';
  # BUILD_OPTIONS+="-DPCB=X7 -DPCBREV=MT12"

}
