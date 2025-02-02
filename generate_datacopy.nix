{
  lib,
  substituteAll,
  python3,
  makeWrapper,
  runCommand,
  llvmPackages,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "generate_datacopy";
  version = "0.0.0";
  src = ./radio/util;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [

    (python3.withPackages (
      packages: with packages; [
        jinja2
        libclang
        lz4
        pillow
      ]
    ))
  ];

  installPhase = ''
    mkdir -p $out/bin $out/lib
    cp {generate_datacopy.py,find_clang.py} $out/lib
    patchShebangs $out/lib/generate_datacopy.py

    source ${
      substituteAll {
        src = ./wrap-libclang.sh;
        env = { inherit (llvmPackages) clang; };
      }
    }

    makeWrapper $out/lib/generate_datacopy.py $out/bin/generate_datacopy \
      --suffix CPATH : $CPATH \
      --suffix CPLUS_INCLUDE_PATH : $CPLUS_INCLUDE_PATH
  '';
  #       --suffix PYTHONPATH         : $out/lib                                                \
  #       --suffix CPATH              : "$(<${llvmPackages.clang}/nix-support/libc-cflags)"     \
  #       --suffix CPATH              : "${llvmPackages.clang}/resource-root/include"           \
  #       --suffix CPLUS_INCLUDE_PATH : "$(<${llvmPackages.clang}/nix-support/libcxx-cxxflags)" \
  #       --suffix CPLUS_INCLUDE_PATH : "$(<${llvmPackages.clang}/nix-support/libc-cflags)"     \
  #       --suffix CPLUS_INCLUDE_PATH : "${llvmPackages.clang}/resource-root/include"
}
