{
  description = "A collection of utilities for ripping, dumping, analysing, and modifying disk images.";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    ipflib-src.url = "http://www.softpres.org/_media/files:ipflib42_linux-x86_64.tar.gz?id=download&cache=cache";
    ipflib-src.flake = false;
    disk-utilities-src.url = "github:keirf/disk-utilities";
    disk-utilities-src.flake = false;
  };

  outputs = { self, nix, nixpkgs, flake-utils, ipflib-src, disk-utilities-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = flake-utils.lib.flattenTree rec {
          ipflib = pkgs.stdenv.mkDerivation rec {
            pname = "ipflib";
            version = "4.2";
            src = ipflib-src;
            installPhase = ''
              mkdir -p $out $out/lib
              cp -vr include $out
              cp -v libcapsimage.so.4.2 $out/lib
              ln -s libcapsimage.so.4.2 $out/lib/libcapsimage.so.4
            '';
            postFixup = ''
              patchelf --set-rpath ${pkgs.stdenv.cc.cc.lib}/lib $out/lib/libcapsimage.so.4.2
            '';
          };

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
              ipflib
            ];
          };
        };
        defaultPackage = packages.disk-utilities;
      }
    );
}
