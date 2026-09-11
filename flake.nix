{
  description = "cpp toolchain (clang + clangd)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
  let
    llvmVersion = "20";
    cxxStandard = "26";

    systems = builtins.attrNames nixpkgs.legacyPackages;
    forAllSystems = f: builtins.listToAttrs (map (system: {
      name = system;
      value = f system;
    }) systems);

    pkgsFor = system: import nixpkgs { inherit system; };

    llvmFor = system: (pkgsFor system).${"llvmPackages_" + llvmVersion};
    clangFor = system: (llvmFor system).clang;
    clangToolsFor = system: (llvmFor system).clang-tools;
    stdenvFor = system: (llvmFor system).stdenv;

    # https://github.com/cpp-best-practices/cppbestpractices/blob/master/02-Use_the_Tools_Available.md
    warningFlags = [
      "-Wall" "-Wextra" "-Wpedantic" "-Wshadow" "-Wnon-virtual-dtor"
      "-Wold-style-cast" "-Wcast-align" "-Woverloaded-virtual"
      "-Wconversion" "-Wsign-conversion" "-Wnull-dereference"
      "-Wdouble-promotion" "-Wformat=2" "-Wimplicit-fallthrough"
    ];

    clangFlags = [ "-std=c++${cxxStandard}" ] ++ warningFlags;

    mkCppPackage = { pkgs, pname, src, srcDir ? "src", extraFlags ? [] }:
      let stdenv = stdenvFor pkgs.system;
      in stdenv.mkDerivation {
        name = pname;
        inherit src;
        dontConfigure = true;
        buildPhase = ''
          runHook preBuild
          $CXX ${pkgs.lib.concatStringsSep " " (clangFlags ++ extraFlags)} ${srcDir}/*.cpp -o ${pname}
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          install -Dm755 ${pname} $out/bin/${pname}
          runHook postInstall
        '';
      };

    mkCppShell = { pkgs, extraPackages ? [] }:
      let llvm = llvmFor pkgs.system;
      in (pkgs.mkShell.override { stdenv = llvm.stdenv; }) {
        packages = [ llvm.clang-tools ] ++ extraPackages;
        CXXFLAGS = pkgs.lib.concatStringsSep " " clangFlags;
      };
  in
  {
    inherit forAllSystems;

    packages = forAllSystems (system: {
      clang = clangFor system;
      clang-tools = clangToolsFor system;
    });

    lib = {
      inherit pkgsFor mkCppPackage mkCppShell warningFlags clangFlags cxxStandard;
    };

    devShells = forAllSystems (system: {
      default = mkCppShell { pkgs = pkgsFor system; };
    });

    templates.default = {
      path = ./templates/default;
      description = "c++${cxxStandard} project scaffold using this toolchain's devShell";
    };
  };
}
