{ lib, pkgs, ... }:
{
  nixpkgs.crossSystem = {
    system = "loongarch64-linux";
    config = "loongarch64-unknown-linux-gnu";
    gcc.arch = "loongarch64";
    linux-kernel = {
      name = "loong64";
      target = "uImage";
    };
    rustc.config = "loongarch64-unknown-linux-gnu-nosimd";
    rustc.platform = builtins.fromJSON (builtins.readFile ./rust-loongarch64-gnu-nosimd.json);
  };
  nixpkgs.overlays = [(import ../overlays/default.nix)];
}
