{
  description = "test build NixOS Loongarch64 pkgs via Github Action";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    haskellNix.url = "github:fzdslr/haskell.nix/loong";
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://loongarch64-cross-test.cachix.org"
      "https://cache.iog.io"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "loongarch64-cross-test.cachix.org-1:qiDlGssTkRx6m2MpYmUiA9DIWbsB2JyBiFUy47t67nQ="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      haskellNix,
      ...
    }:
    {
      nixosConfigurations.loongarch64 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit rust-overlay haskellNix; };
        modules = [
          (import ./modules/cross-config.nix)
          (import ./modules/extra-packages.nix)
        ];
      };

      inherit nixpkgs;
    };
}
