{
  llvmPackages,
  makeWrapper,
  python3,
  stdenv,
  substituteAll,
  ...
}:
stdenv.mkDerivation {
  pname = "generate_datacopy";
  version = "0.0.0";
  src = ./radio/util;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    (python3.withPackages (
      packages: with packages; [
        libclang
      ]
    ))
  ];

  dontBuild = true;

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
}
