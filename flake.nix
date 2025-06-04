{
  description = "test build NixOS Loongarch64 pkgs via Github Action";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://loongarch64-cross-test.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "loongarch64-cross-test.cachix.org-1:qiDlGssTkRx6m2MpYmUiA9DIWbsB2JyBiFUy47t67nQ="
    ];
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    {
      nixosConfigurations.loongarch64 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          (import ./modules/cross-config.nix)
          (import ./modules/extra-packages.nix)
        ];
      };

      inherit nixpkgs;
    };
}
