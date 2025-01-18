{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            cmake
            gnumake
            stdenv.cc
            (python3.withPackages (
              packages: with packages; [
                asciitree
                jinja2
                pillow
                # aqtinstall
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
        };
      }
    );
}
