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
              linux-kernel = {
                name = "loong64";
                baseConfig = "defconfig";
                target = "uImage";
                DTB = true;
              };
            };
          }
          (import ./overlays/default.nix)
        ];
      };
    };
}
