{
  description = "test build NixOS Loongarch64 pkgs via Github Action";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
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
          {
            nixpkgs.crossSystem = {
              system = "loongarch64-linux";
              config = "loongarch64-unknown-linux-gnu";
              gcc.arch = "loongarch64";
              gcc.tune = "loongarch64";
            };
          }
          (import ./overlays/default.nix)
          (import ./modules/extra-packages.nix)
        ];
      };

      inherit nixpkgs;
    };
}
