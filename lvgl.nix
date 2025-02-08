{
  lib,
  cmake,
  fetchFromGitHub,
  nix-update,
  stdenv,
  ...
}:

stdenv.mkDerivation rec {
  pname = "lvgl";
  version = "v9.2.2";

  src = fetchFromGitHub {
    owner = "lvgl";
    repo = pname;
    rev = "7f07a129e8d77f4984fff8e623fd5be18ff42e74";
    hash = "sha256-a/UWO12xuNNJSVYHUxkav/raVNotCBX3cTjvBTEH87U=";
  };

  strictDeps = true;

  # postPatch = ''
  #   substituteInPlace CMakeLists.txt \
  #     --replace-fail 'set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${PROJECT_BINARY_DIR}/lib)' "" \
  #     --replace-fail 'set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ''${PROJECT_BINARY_DIR}/lib)' ""
  # '';

  preBuild = ''
    ls
    mv ../lv_conf_template.h lv_conf.h
  '';

  # dontWrapQtApps = true;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    # qtbase
  ];

  env.PROJECT_BINARY_DIR = "$out";

  passthru.updateScript = nix-update { };

  meta = with lib; {
    description = "Embedded graphics library to create beautiful UIs for any MCU, MPU and display type";
    homepage = "https://lvgl.io/";
    license = with licenses; [ mit ];
    platforms = platforms.all;
    maintainers = with maintainers; [ nathanregner ];
  };
}
