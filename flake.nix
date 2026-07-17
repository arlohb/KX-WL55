{
  description = "An attempt at reverse engineering the Panasonic KX-WL55 Word Processor";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Ghidra
            gradle
            gcc
            openjdk

            # eprom_reader
            platformio
          ];
        };
      }
    );
}
