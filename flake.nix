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
        packages.default = pkgs.libsForQt5.callPackage ./package.nix { };
        devShell = pkgs.mkShell {
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
        };
      }
    );
}
