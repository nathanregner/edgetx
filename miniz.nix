{
  lib,
  cmake,
  fetchFromGitHub,
  nix-update,
  stdenv,
  ...
}:

stdenv.mkDerivation rec {
  pname = "miniz";
  version = "3.0.2";

  src = fetchFromGitHub {
    owner = "richgel999";
    repo = pname;
    rev = version;
    hash = "sha256-3J0bkr2Yk+MJXilUqOCHsWzuykySv5B1nepmucvA4hg=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
  ];

  postPatch = ''
    substituteInPlace miniz.pc.in \
      --replace-fail 'libdir=''${exec_prefix}/@CMAKE_INSTALL_LIBDIR@' 'libdir=@CMAKE_INSTALL_FULL_LIBDIR@' \
      --replace-fail 'includedir=''${prefix}/@CMAKE_INSTALL_INCLUDEDIR@/@PROJECT_NAME@' 'includedir=@CMAKE_INSTALL_FULL_INCLUDEDIR@/@PROJECT_NAME@'
  '';

  # doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  passthru.updateScript = nix-update { };

  meta = with lib; {
    description = "YAML parser and emitter for C++";
    homepage = "https://github.com/jbeder/yaml-cpp";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ nathanregner ];
  };
}
