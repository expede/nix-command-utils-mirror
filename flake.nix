{
  description = "nix-command-utils";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        core = import ./lib/core.nix { inherit pkgs; };
        inherit (core) asModule cmd command commands withHelp;

        pnpm = import ./lib/pnpm.nix { inherit cmd; };
        rust = import ./lib/rust.nix { inherit cmd lib; };
        wasm = import ./lib/wasm.nix { inherit cmd lib; };
      in
        { inherit asModule cmd command commands pnpm rust wasm withHelp; }
    );
}
