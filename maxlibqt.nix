{
  lib,
  qtbase,
  cmake,
  fetchFromGitHub,
  nix-update,
  stdenv,
  ...
}:

stdenv.mkDerivation rec {
  pname = "maxLibQt";
  version = "3.0.2";

  src = fetchFromGitHub {
    owner = "mpaperno";
    repo = pname;
    rev = "b903e7a755b241313b7acdea0258ee17cbd8fc04";
    hash = "sha256-xKgUIuh6ANsKrih1lK1mKPCzh52RnDJVT4XwQvI97mk=";
  };

  strictDeps = true;

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${PROJECT_BINARY_DIR}/lib)' "" \
      --replace-fail 'set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ''${PROJECT_BINARY_DIR}/lib)' ""
  '';

  dontWrapQtApps = true;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    qtbase
  ];

  env.PROJECT_BINARY_DIR = "$out";

  passthru.updateScript = nix-update { };

  meta = with lib; {
    description = "A collection of C++ classes and QtQuick QML components for use with the Qt framework";
    homepage = "https://github.com/mpaperno/maxLibQt";
    license = with licenses; [ gpl3 ];
    platforms = platforms.all;
    maintainers = with maintainers; [ nathanregner ];
  };
}
