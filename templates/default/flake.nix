{
  description = "app";

  inputs = {
    cpp-toolchain.url = "github:mazunki/nix-cpp-toolchain";
  };

  outputs = { self, cpp-toolchain, ... }:
    let
      inherit (cpp-toolchain) forAllSystems;
      inherit (cpp-toolchain.lib) pkgsFor clangFlags;
      pname = "app";
    in {
      devShells = forAllSystems (system: {
        default = cpp-toolchain.lib.mkCppShell { pkgs = pkgsFor system; };
      });

      packages = forAllSystems (system: {
        default = cpp-toolchain.lib.mkCppPackage {
          pkgs = pkgsFor system;
          inherit pname;
          src = ./.;
        };
      });

      # `nix run .#recompile` - fast local rebuild with the exact same
      # flags mkCppPackage uses, no Nix sandbox. Not a substitute for
      # `nix build`, which is the real reproducible one.
      apps = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          recompile = {
            type = "app";
            program = "${pkgs.writeShellScript "recompile" ''
              exec ${cpp-toolchain.packages.${system}.clang}/bin/clang++ ${pkgs.lib.concatStringsSep " " clangFlags} src/*.cpp -o ${pname} "$@"
            ''}";
          };
        });
    };
}
