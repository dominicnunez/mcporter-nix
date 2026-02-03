{
  description = "Nix flake for MCPorter - TypeScript runtime and CLI for the Model Context Protocol";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      overlay = final: prev: {
        mcporter = final.callPackage ./package.nix { };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.mcporter;
          mcporter = pkgs.mcporter;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.mcporter}/bin/mcporter";
            meta.description = "TypeScript runtime and CLI for the Model Context Protocol";
          };
          mcporter = {
            type = "app";
            program = "${pkgs.mcporter}/bin/mcporter";
            meta.description = "TypeScript runtime and CLI for the Model Context Protocol";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            nix-prefetch
            prefetch-npm-deps
            gh
            jq
            nodejs
          ];
        };

        formatter = pkgs.nixpkgs-fmt;

        checks = {
          build = pkgs.mcporter;

          version = pkgs.runCommand "mcporter-version-check" { } ''
            ${pkgs.mcporter}/bin/mcporter --version
            touch $out
          '';
        };
      }
    )
    // {
      overlays.default = overlay;
    };
}
