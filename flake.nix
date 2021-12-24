{
  description = "A collection of utilities for ripping, dumping, analysing, and modifying disk images.";

  inputs = rec {
    nixpkgs.url = "github:nixos/nixpkgs";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nix, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = flake-utils.lib.flattenTree rec {
          ipflib = pkgs.stdenv.mkDerivation rec {
            pname = "ipflib";
            version = "4.2";
            src = fetchTarball {
              url = "http://www.softpres.org/_media/files:ipflib42_linux-x86_64.tar.gz?id=download&cache=cache";
              sha256 = "sha256:0adwjxqzm2ix80rdsvyn0g6rzi3bw1my666ikq6xfkvriqi5sccw";
            };
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
            src = pkgs.fetchgit {
              url = "https://github.com/keirf/disk-utilities.git";
              rev = "8d74b1ad6b772014ddb492baa16c719e44e4b4bf";
              sha256 = "sha256-R6Tg1MFXAvLOpowxjI5gHzmNobQNN3G1RslU4cEuvo0=";
            };
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
