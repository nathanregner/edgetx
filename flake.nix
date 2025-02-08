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
        inherit (pkgs) lib;
      in
      rec {
        packages = rec {
          # miniz = pkgs.callPackage ./miniz.nix { };
          maxLibQt = pkgs.libsForQt5.callPackage ./maxlibqt.nix { };
          default = pkgs.libsForQt5.callPackage ./package.nix {
            # inherit (pkgs) miniz;
            inherit
              generate_datacopy
              ;

          };
          buildPlugin = pkgs.libsForQt5.callPackage ./simulator_plugin.nix {
            inherit
              generate_datacopy
              ;
          };
          plugins = builtins.listToAttrs (
            builtins.map
              (target: {
                name = target;
                value = buildPlugin {
                  inherit target;
                };
              })
              # ["BETAFPV LiteRadio 3 Pro", "lr3pro-"] => "lr3pro"
              (
                builtins.map (target: lib.removeSuffix "-" (builtins.elemAt target 1))
                  (builtins.fromJSON (builtins.readFile ./fw.json)).targets
              )
          );
          allPlugins = pkgs.linkFarm "all-plugins" (
            lib.mapAttrsToList (name: path: { inherit name path; }) plugins
          );
          generate_datacopy = pkgs.libsForQt5.callPackage ./generate_datacopy.nix { };
        };
        devShell = pkgs.mkShell (
          let
            llvmPackages = pkgs.llvmPackages_14;
          in
          {
            env = {
              LIBCLANG_PATH = "${lib.getLib llvmPackages.clang-unwrapped.lib}/lib";
              # CLANG_INCLUDE = " ${llvmPackages.clang}/resource-root/include";
              # CPATH = "${llvmPackages.clang}/nix-support/libc-cflags ${llvmPackages.clang}/resource-root/include";
              # CPLUS_INCLUDE_PATH = "${llvmPackages.clang}/nix-support/libcxx-cxxflags ${llvmPackages.clang}/nix-support/libc-cflags ${llvmPackages.clang}/resource-root/include";
            };

            # shellHook = ''
            #   source ${
            #     pkgs.substituteAll {
            #       src = ./wrap-libclang.sh;
            #       env = { inherit (llvmPackages) clang; };
            #     }
            #   }
            # '';

            nativeBuildInputs = with pkgs; [
              cmake
              gnumake
              # llvmPackages.clang
              # llvmPackages.bintools
              packages.generate_datacopy # clang-tools
              clang
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
          }
        );
      }
    );
}
