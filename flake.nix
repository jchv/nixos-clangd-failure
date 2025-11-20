{
  description = "clangd-test";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/de21549a840be528ef4763dd7dca2006caf9c11f";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.clang-tools
            pkgs.cmake
          ];
        };
      }
    );
}
