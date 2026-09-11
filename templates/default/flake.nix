{
  description = "app";

  inputs = {
    cpp-toolchain.url = "github:mazunki/nix-cpp-toolchain";
  };

  outputs = { self, cpp-toolchain, ... }:
    let
      inherit (cpp-toolchain) forAllSystems;
      inherit (cpp-toolchain.lib) pkgsFor;
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
    };
}
