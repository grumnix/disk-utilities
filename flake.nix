{
  description = "A collection of utilities for ripping, dumping, analysing, and modifying disk images.";

  inputs = rec {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";

    ipflib.url = "github:grumnix/ipflib";
    ipflib.inputs.nixpkgs.follows = "nixpkgs";
    ipflib.inputs.flake-utils.follows = "flake-utils";

    disk-utilities-src.url = "github:keirf/disk-utilities";
    disk-utilities-src.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, ipflib, disk-utilities-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          default = disk-utilities;

          disk-utilities = pkgs.stdenv.mkDerivation rec {
            pname = "disk-utilities";
            version = "0.0.0";

            src = disk-utilities-src;

            patchPhase = ''
              sed -i "s#libcapsimage.so#${ipflib}/lib/libcapsimage.so#" libdisk/stream/caps.c
            '';

            buildPhase = "caps=y make PREFIX=$out";

            installPhase = "caps=y make install PREFIX=$out";

            buildInputs = [
              ipflib.packages.${system}.default
            ];
          };
        };
      }
    );
}
